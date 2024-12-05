defmodule BodydashboardWeb.AddBodyCompositionData do
  use BodydashboardWeb, :live_component

  import Bodydashboard.Helpers

  alias Bodydashboard.Records
  alias Bodydashboard.Records.BodyComposition

  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign(changeset: BodyComposition.changeset(%BodyComposition{}, %{}))

    {:ok, socket}
  end

  def handle_event("cancel_add_data", _params, socket) do
    send(self(), :cancel_add_data)
    {:noreply, socket}
  end

  def handle_event("save", %{"body_composition" => body_composition_params}, socket) do
    selected_date = socket.assigns.selected_date
    params_with_date = Map.put(body_composition_params, "record_date", selected_date)
    current_bc = socket.assigns.current_bc

    save_fn =
      if current_bc && current_bc.record_date == selected_date do
        fn -> Records.update_body_composition(current_bc.id, params_with_date) end
      else
        fn -> Records.create_body_composition(socket.assigns.current_user, params_with_date) end
      end

    case save_fn.() do
      {:ok, bc} ->
        send(self(), {:bc_saved, bc})
        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply,
         socket
         |> assign(:changeset, changeset)
         |> put_flash(:error, "Failed to save: #{get_error_messages(changeset)}")}
    end
  end

  def render(assigns) do
    ~H"""
    <section class="w-full flex flex-col gap-4">
      <.form :let={f} for={@changeset} phx-submit="save" phx-target={@myself} id="">
        <div class="flex flex-col gap-6">
          <.input
            type="text"
            class=""
            label="Weight"
            field={f[:weight_kg]}
            value={@current_bc && Map.get(@current_bc, :weight_kg)}
          />
          <.input
            type="text"
            label="Body Fat Percentage"
            field={f[:body_fat]}
            value={@current_bc && Map.get(@current_bc, :body_fat)}
          />
          <.input
            type="text"
            label="Muscle Mass"
            field={f[:muscle_mass]}
            value={@current_bc && Map.get(@current_bc, :muscle_mass)}
          />
          <.input
            type="text"
            label="Bone Density"
            field={f[:bone_density]}
            value={@current_bc && Map.get(@current_bc, :bone_density)}
          />
        </div>
        <div class="fixed bottom-0 left-0 right-0 flex justify-center">
          <button
            type="submit"
            class="cursor-pointer hover:scale-110 active:scale-90 transition-transform duration-150"
          >
            <.icon name="hero-check-circle-solid" class="bg-white size-20 mb-4" />
          </button>
          <button
            type="button"
            phx-click="cancel_add_data"
            phx-target={@myself}
            class="cursor-pointer hover:scale-110 active:scale-90 transition-transform duration-150"
          >
            <.icon name="hero-x-circle-solid" class="bg-white size-20 mb-4" />
          </button>
        </div>
      </.form>
    </section>
    """
  end
end

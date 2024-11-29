defmodule BodydashboardWeb.DashboardLive do
  use BodydashboardWeb, :live_view

  import BodydashboardWeb.Charts

  alias Bodydashboard.Records
  alias Bodydashboard.Records.BodyComposition

  @measurements [
    %{field: :weight_kg, title: "Weight"},
    %{field: :bone_density, title: "Bone Density"},
    %{field: :muscle_mass, title: "Muscle Mass"},
    %{field: :body_fat, title: "Body Fat"}
  ]

  defp load_body_composition(%{assigns: %{current_user: user, selected_date: date}} = socket) do
    records = Records.get_user_body_composition(user, date)
    assign(socket, :body_composition, records)
  end

  def get_error_messages(changeset) when is_struct(changeset, Ecto.Changeset) do
    changeset
    |> Ecto.Changeset.traverse_errors(fn {msg, _opts} -> msg end)
    |> Enum.map(fn {field, errors} -> "#{field} #{errors}" end)
    |> Enum.join(", ")
  end

  defp update_chart(%{assigns: %{current_user: user}} = socket) do
    {dataset, categories} =
      user
      |> Records.get_user_body_composition()
      |> map_bc_data()

    chart_data = %{dataset: dataset, categories: categories}

    socket
    |> assign(:chart_data, chart_data)
    |> push_event("update-dataset", chart_data)
  end

  defp get_data_postfix(field) do
    case field do
      :weight_kg -> "kg"
      :body_fat -> "%"
      _ -> ""
    end
  end

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign_new(:selected_date, fn -> Date.utc_today() end)
      |> assign(changeset: BodyComposition.changeset(%BodyComposition{}, %{}))
      |> assign(:measurements, @measurements)
      |> assign_new(:toggled_data, fn ->
        %{weight: true, bone: true, muscle: true, fat: true}
      end)
      |> load_body_composition()
      |> update_chart()

    {:ok, socket}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("save", %{"body_composition" => body_composition_params}, socket) do
    params_with_date =
      Map.put(body_composition_params, "record_date", socket.assigns.selected_date)

    body_composition = socket.assigns.body_composition
    selected_date = socket.assigns.selected_date

    if body_composition && body_composition.record_date == selected_date do
      case Records.update_body_composition(body_composition.id, params_with_date) do
        {:ok, bc} ->
          {:noreply,
           socket
           |> assign(:body_composition, bc)
           |> put_flash(:info, "Body composition saved successfully")
           |> update_chart()
           |> assign(:toggled_data, %{weight: true, bone: true, muscle: true, fat: true})
           |> push_patch(to: ~p"/dashboard")}

        {:error, %Ecto.Changeset{} = changeset} ->
          {:noreply,
           socket
           |> assign(:changeset, changeset)
           |> put_flash(:error, "Failed to save: #{get_error_messages(changeset)}")}
      end
    else
      case Records.create_body_composition(socket.assigns.current_user, params_with_date) do
        {:ok, bc} ->
          {:noreply,
           socket
           |> assign(:body_composition, bc)
           |> put_flash(:info, "Body composition saved successfully")
           |> update_chart()
           |> assign(:toggled_data, %{weight: true, bone: true, muscle: true, fat: true})
           |> push_patch(to: ~p"/dashboard")}

        {:error, %Ecto.Changeset{} = changeset} ->
          {:noreply,
           socket
           |> assign(:changeset, changeset)
           |> put_flash(:error, "Failed to save: #{get_error_messages(changeset)}")}
      end
    end
  end

  def handle_event("decrement_date", _params, socket) do
    socket =
      socket
      |> update(:selected_date, &Date.add(&1, -1))
      |> load_body_composition()

    {:noreply, socket}
  end

  def handle_event("increment_date", _params, socket) do
    case Date.compare(Date.add(socket.assigns.selected_date, 1), Date.utc_today()) do
      :gt ->
        {:noreply,
         socket
         |> put_flash(:error, "Can't select future date")}

      _ ->
        {:noreply,
         socket
         |> update(:selected_date, &Date.add(&1, 1))
         |> load_body_composition()}
    end
  end

  def handle_event("add_data", _params, socket) do
    {:noreply, push_patch(socket, to: ~p"/dashboard/add_data")}
  end

  def handle_event("go_to_dashboard", _params, socket) do
    {:noreply,
     socket
     |> assign(:toggled_data, %{weight: true, bone: true, muscle: true, fat: true})
     |> push_patch(to: ~p"/dashboard")}
  end

  def handle_event("toggle-" <> field, _params, socket) do
    field_atom = String.to_existing_atom(field)

    field_names = %{
      weight: "Weight",
      bone: "Bone Density",
      muscle: "Muscle Mass",
      fat: "Body Fat"
    }

    display_name = Map.get(field_names, field_atom)

    current_toggles = socket.assigns.toggled_data

    updated_toggles =
      Map.update!(current_toggles, field_atom, fn current_value ->
        !current_value
      end)

    {:noreply,
     socket
     |> assign(:toggled_data, updated_toggles)
     |> push_event("toggle-series", %{name: display_name})}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex h-full flex-col gap-6">
      <div class="flex justify-between max-w-sm">
        <button
          phx-click="decrement_date"
          class="cursor-pointer hover:scale-110 active:scale-90 transition-transform duration-150"
        >
          <.icon name="hero-arrow-left" />
        </button>
        <span class="text-xl">
          <%= if @selected_date == Date.utc_today() do %>
            Today
          <% else %>
            <%= Calendar.strftime(@selected_date, "%b %d") %>
          <% end %>
        </span>
        <button
          phx-click="increment_date"
          disabled={Date.add(@selected_date, 1) > Date.utc_today()}
          class={[
            "cursor-pointer hover:scale-110 active:scale-90 transition-transform duration-150",
            Date.add(@selected_date, 1) > Date.utc_today() &&
              "opacity-20 hover:scale-100 active:scale-100"
          ]}
        >
          <.icon name="hero-arrow-right" />
        </button>
      </div>
      <%= if @live_action == :index do %>
        <section class="w-full flex flex-col gap-4">
          <%= if @chart_data do %>
            <.line_graph
              id="line-chart-1"
              dataset={@chart_data.dataset}
              categories={@chart_data.categories}
              animated={true}
            />
          <% end %>
          <div class="flex flex-col gap-4">
            <div class="flex text-sm bg-zinc-900 rounded-lg">
              <button
                phx-click="toggle-weight"
                class={[
                  "p-4 flex-1 rounded-l-lg",
                  @toggled_data.weight && "bg-zinc-800"
                ]}
              >
                Weight
              </button>
              <button
                phx-click="toggle-bone"
                class={[
                  "p-4 flex-1",
                  @toggled_data.bone && "bg-zinc-800"
                ]}
              >
                Bone
              </button>
              <button
                phx-click="toggle-muscle"
                class={[
                  "p-4 flex-1",
                  @toggled_data.muscle && "bg-zinc-800"
                ]}
              >
                Muscle
              </button>
              <button
                phx-click="toggle-fat"
                class={[
                  "p-4 flex-1 rounded-r-lg",
                  @toggled_data.fat && "bg-zinc-800"
                ]}
              >
                Fat
              </button>
            </div>
            <%= for measurements <- Enum.chunk_every(@measurements, 2) do %>
              <div class="flex gap-4">
                <%= for %{field: field, title: title} <- measurements do %>
                  <.card title={title} class="w-full">
                    <div class="font-extrabold h-16 flex justify-center items-center text-3xl">
                      <div>
                        <%= if @body_composition && Map.get(@body_composition, field) do %>
                          <%= Map.get(@body_composition, field) %>
                        <% else %>
                          0.0
                        <% end %>
                        <span class="text-lg ">
                          <%= get_data_postfix(field) %>
                        </span>
                      </div>
                    </div>
                  </.card>
                <% end %>
              </div>
            <% end %>
          </div>
        </section>
        <div class="fixed bottom-0 left-0 right-0 flex justify-center">
          <button
            phx-click="add_data"
            class="cursor-pointer hover:scale-110 active:scale-90 transition-transform duration-150"
          >
            <.icon name="hero-plus-circle-solid" class="bg-white size-20 mb-4" />
          </button>
        </div>
      <% end %>
      <%= if @live_action == :add_data do %>
        <section class="w-full flex flex-col gap-4">
          <.form :let={f} for={@changeset} phx-submit="save" id="">
            <div class="flex flex-col gap-6">
              <.input
                type="text"
                class=""
                label="Weight"
                field={f[:weight_kg]}
                value={@body_composition && Map.get(@body_composition, :weight_kg)}
              />
              <.input
                type="text"
                label="Body Fat Percentage"
                field={f[:body_fat]}
                value={@body_composition && Map.get(@body_composition, :body_fat)}
              />
              <.input
                type="text"
                label="Muscle Mass"
                field={f[:muscle_mass]}
                value={@body_composition && Map.get(@body_composition, :muscle_mass)}
              />
              <.input
                type="text"
                label="Bone Density"
                field={f[:bone_density]}
                value={@body_composition && Map.get(@body_composition, :bone_density)}
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
                phx-click="go_to_dashboard"
                class="cursor-pointer hover:scale-110 active:scale-90 transition-transform duration-150"
              >
                <.icon name="hero-x-circle-solid" class="bg-white size-20 mb-4" />
              </button>
            </div>
          </.form>
        </section>
      <% end %>
    </div>
    """
  end
end

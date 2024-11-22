defmodule BodydashboardWeb.DashboardLive do
  use BodydashboardWeb, :live_view

  alias Bodydashboard.Records
  alias Bodydashboard.Records.BodyComposition

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

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign_new(:selected_date, fn -> Date.utc_today() end)
      |> assign(changeset: BodyComposition.changeset(%BodyComposition{}, %{}))
      |> load_body_composition()

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
           |> put_flash(:info, "Body composition saved successfully")}

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
           |> put_flash(:info, "Body composition saved successfully")}

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
    socket =
      socket
      |> update(:selected_date, &Date.add(&1, 1))
      |> load_body_composition()

    {:noreply, socket}
  end

  def handle_event("patch-" <> category, _params, socket) do
    case category do
      "all" -> {:noreply, push_patch(socket, to: ~p"/dashboard")}
      "body_composition" -> {:noreply, push_patch(socket, to: ~p"/dashboard/body_composition")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex h-full flex-col gap-6">
      <div class="flex justify-between w-40">
        <.clickable_icon name="hero-arrow-left" onclick="decrement_date" />
        <span>
          <%= if @selected_date == Date.utc_today() do %>
            Today
          <% else %>
            <%= Calendar.strftime(@selected_date, "%b %d") %>
          <% end %>
        </span>
        <.clickable_icon name="hero-arrow-right" onclick="increment_date" />
      </div>
      <div class="flex h-full gap-6">
        <aside class="flex flex-col gap-2">
          <.button phx-click="patch-all">
            All
          </.button>
          <.button phx-click="patch-body_composition">
            Body composition
          </.button>
        </aside>
        <div class="h-full w-px bg-primary-100"></div>
        <section class="w-full">
          <%= if @live_action == :index do %>
            Index
          <% end %>
          <%= if @live_action == :body_composition do %>
            <div>
              <h1>My Body Composition</h1>
              <.form :let={f} for={@changeset} phx-submit="save">
                <.input field={f[:weight_kg]} type="text" label="Weight" />
                <.button type="submit">
                  <%= if @body_composition && @body_composition.record_date == @selected_date do %>
                    Update record
                  <% else %>
                    Add record
                  <% end %>
                </.button>
              </.form>
              <div>
                <div>
                  <%= if @body_composition do %>
                    Weight: <%= @body_composition.weight_kg %>
                  <% end %>
                </div>
              </div>
            </div>
          <% end %>
        </section>
      </div>
    </div>
    """
  end
end

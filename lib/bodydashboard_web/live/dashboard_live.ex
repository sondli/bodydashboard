defmodule BodydashboardWeb.DashboardLive do
  use BodydashboardWeb, :live_view

  alias Bodydashboard.Records
  alias Bodydashboard.Records.BodyRecord

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign_new(:selected_date, fn -> Date.utc_today() end)
      |> assign(changeset: BodyRecord.changeset(%BodyRecord{}, %{}))
      |> load_body_records()

    {:ok, socket}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  defp load_body_records(%{assigns: %{current_user: user, selected_date: date}} = socket) do
    records = Records.get_user_records(user, date)
    assign(socket, :body_records, records)
  end

  @impl true
  def handle_event("save", %{"body_record" => body_record_params}, socket) do
    params_with_date = Map.put(body_record_params, "record_date", socket.assigns.selected_date)

    case Records.create_body_record(socket.assigns.current_user, params_with_date) do
      {:ok, record} ->
        {:noreply,
         socket
         |> update(:body_records, fn records -> [record | records] end)
         |> put_flash(:info, "Weight saved successfully")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  def handle_event("decrement_date", _params, socket) do
    new_date = Date.add(socket.assigns.selected_date, -1)

    socket =
      socket
      |> assign(selected_date: new_date)
      |> load_body_records()

    {:noreply, socket}
  end

  def handle_event("increment_date", _params, socket) do
    new_date = Date.add(socket.assigns.selected_date, 1)

    socket =
      socket
      |> assign(selected_date: new_date)
      |> load_body_records()

    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex h-full flex-col gap-6">
      <div>
        <.button phx-click="decrement_date">
          Prev
        </.button>
        <span><%= @selected_date %></span>
        <.button phx-click="increment_date">
          Next
        </.button>
      </div>
      <div class="flex h-full">
        <aside class="flex flex-col px-6">
          <.button>
            <.link patch={~p"/dashboard"}>All</.link>
          </.button>
          <.button>
            <.link patch={~p"/dashboard/body_composition"}>Body Composition</.link>
          </.button>
        </aside>
        <div class="h-full w-px bg-primary-100"></div>
        <section class="w-full px-6">
          <%= if @live_action == :index do %>
            Index
          <% end %>
          <%= if @live_action == :body_composition do %>
            <div>
              <h1>My Body Records</h1>
              <.form :let={f} for={@changeset} phx-submit="save">
                <.input field={f[:weight_kg]} type="text" label="Weight" />
                <.button type="submit">Add weight</.button>
              </.form>

              <div>
                <%= for record <- @body_records do %>
                  <div>
                    Weight: <%= record.weight_kg %>
                  </div>
                <% end %>
              </div>
            </div>
          <% end %>
        </section>
      </div>
    </div>
    """
  end
end

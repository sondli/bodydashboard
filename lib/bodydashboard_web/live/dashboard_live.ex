defmodule BodydashboardWeb.DashboardLive do
  use BodydashboardWeb, :live_view

  alias Bodydashboard.Records
  alias Bodydashboard.Records.BodyRecord

  defp load_body_records(%{assigns: %{current_user: user, selected_date: date}} = socket) do
    records = Records.get_user_records(user, date)
    assign(socket, :body_records, records)
  end

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
    socket =
      socket
      |> update(:selected_date, &Date.add(&1, -1))
      |> load_body_records()

    {:noreply, socket}
  end

  def handle_event("increment_date", _params, socket) do
    socket =
      socket
      |> update(:selected_date, &Date.add(&1, 1))
      |> load_body_records()

    {:noreply, socket}
  end

  def handle_event("patch-" <> category, _params, socket) do
    case category do
      "all" -> {:noreply, push_patch(socket, to: ~p"/dashboard")}
      "body_composition" -> {:noreply, push_patch(socket, to: ~p"/dashboard/body_composition")}
    end
  end

  def record_exists_for_date?(records, date) do
    Enum.any?(records, fn record ->
      Date.compare(record.record_date, date) == :eq
    end)
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
              <h1>My Body Records</h1>
              <.form :let={f} for={@changeset} phx-submit="save">
                <.input field={f[:weight_kg]} type="text" label="Weight" />
                <.button type="submit">
                  <%= if record_exists_for_date?(@body_records, @selected_date) do %>
                    Update record
                  <% else %>
                    Add record
                  <% end %>
                </.button>
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

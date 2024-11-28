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
           |> update_chart()}

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
           |> update_chart()}

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
    date_string = Date.to_string(socket.assigns.selected_date)
    {:noreply, push_patch(socket, to: ~p"/dashboard/add_data/#{date_string}")}
  end

  def handle_event("go_to_dashboard", _params, socket) do
    {:noreply, push_patch(socket, to: ~p"/dashboard")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex h-full flex-col gap-6">
      <%= if @live_action == :index do %>
        <div class="flex justify-between max-w-sm">
          <.clickable_icon name="hero-arrow-left" onclick="decrement_date" />
          <span class="text-xl">
            <%= if @selected_date == Date.utc_today() do %>
              Today
            <% else %>
              <%= Calendar.strftime(@selected_date, "%b %d") %>
            <% end %>
          </span>
          <.clickable_icon
            name="hero-arrow-right"
            onclick="increment_date"
            disabled={Date.add(@selected_date, 1) > Date.utc_today()}
          />
        </div>
        <section class="w-full flex flex-col gap-6">
          <%= if @chart_data do %>
            <.line_graph
              id="line-chart-1"
              dataset={@chart_data.dataset}
              categories={@chart_data.categories}
              animated={true}
            />
          <% end %>
          <div class="flex flex-col gap-4">
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
          <.clickable_icon
            name="hero-plus-circle-solid"
            class="bg-white size-20 mb-4"
            onclick="add_data"
          />
        </div>
      <% end %>
      <%= if @live_action == :add_data do %>
        <div class="flex justify-between max-w-sm">
          <.clickable_icon name="hero-arrow-left" onclick="go_to_dashboard" />
        </div>
      <% end %>
    </div>
    """
  end
end

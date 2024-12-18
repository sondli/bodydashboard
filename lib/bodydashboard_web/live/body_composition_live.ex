defmodule BodydashboardWeb.BodyCompositionLive do
  use BodydashboardWeb, :live_view

  import BodydashboardWeb.Charts

  alias Bodydashboard.Records

  @measurements [
    %{field: :weight_kg, title: "Weight"},
    %{field: :bone_density, title: "Bone Density"},
    %{field: :muscle_mass, title: "Muscle Mass"},
    %{field: :body_fat, title: "Body Fat"}
  ]

  defp load_current_bc(
         %{assigns: %{all_body_composition_data: data, selected_date: date}} = socket
       ) do
    current_bc = Enum.find(data, fn x -> Date.compare(x.record_date, date) == :eq end)
    assign(socket, :current_bc, current_bc)
  end

  defp insert_updated_bc(%{assigns: %{all_body_composition_data: all_bc}} = socket, new_bc)
       when is_list(all_bc) and is_struct(new_bc) do
    updated_list =
      case Enum.find_index(all_bc, &(&1.id == new_bc.id)) do
        nil ->
          [new_bc | all_bc]
          |> Enum.sort_by(& &1.record_date, Date)

        index ->
          all_bc
          |> List.replace_at(index, new_bc)
          |> Enum.sort_by(& &1.record_date, Date)
      end

    socket
    |> assign(:all_body_composition_data, updated_list)
  end

  defp get_all_body_composition_data(%{assigns: %{current_user: user}} = socket) do
    data = user |> Records.get_user_body_composition()

    socket
    |> assign(:all_body_composition_data, data)
  end

  defp load_chart_data(
         %{assigns: %{all_body_composition_data: data, toggled_data: toggled_data}} = socket
       ) do
    chart_data =
      data
      |> get_field_data(toggled_data)
      |> annotate_field_data(toggled_data)

    socket
    |> assign(:chart_data, chart_data)
  end

  defp get_data_postfix(field) do
    case field do
      :weight_kg -> "kg"
      :body_fat -> "%"
      _ -> ""
    end
  end

  defp get_date_spectrum(middle) when is_struct(middle, Date) do
    {
      Date.add(middle, -2),
      Date.add(middle, -1),
      middle,
      Date.add(middle, 1),
      Date.add(middle, 2)
    }
  end

  defp toggle_current_datapoint(
         %{assigns: %{chart_data: chart_data, selected_date: date}} = socket
       ) do
    index = get_series_index(chart_data.data, date)

    socket
    |> push_event("toggle-datapoint", %{index: index})
  end

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:selected_date, Date.utc_today())
      |> then(fn socket ->
        assign(socket, :date_spectrum, get_date_spectrum(socket.assigns.selected_date))
      end)
      |> assign(:measurements, @measurements)
      |> assign(:toggled_data, :weight_kg)
      |> get_all_body_composition_data()
      |> load_chart_data()
      |> load_current_bc()
      |> toggle_current_datapoint()

    {:ok, socket}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_info({:bc_saved, bc}, socket) do
    {:noreply,
     socket
     |> assign(:current_bc, bc)
     |> insert_updated_bc(bc)
     |> load_chart_data()
     |> push_patch(to: ~p"/dashboard/body_composition")}
  end

  @impl true
  def handle_info(:cancel_add_data, socket) do
    {:noreply, push_patch(socket, to: ~p"/dashboard/body_composition")}
  end

  def handle_event("add_data", _params, socket) do
    {:noreply, push_patch(socket, to: ~p"/dashboard/body_composition/add_data")}
  end

  def handle_event("back", _params, socket) do
    {:noreply, push_navigate(socket, to: ~p"/dashboard")}
  end

  @impl true
  def handle_event("decrement_date", _params, socket) do
    socket =
      socket
      |> update(:selected_date, &Date.add(&1, -1))
      |> then(fn socket ->
        socket
        |> assign(:date_spectrum, get_date_spectrum(socket.assigns.selected_date))
        |> toggle_current_datapoint()
      end)
      |> load_current_bc()

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
         |> then(fn socket ->
           socket
           |> assign(:date_spectrum, get_date_spectrum(socket.assigns.selected_date))
           |> toggle_current_datapoint()
         end)
         |> load_current_bc()}
    end
  end

  def handle_event("toggle-" <> field, _params, socket) do
    field_atom =
      case field do
        "weight" -> :weight_kg
        "bone" -> :bone_density
        "muscle" -> :muscle_mass
        "fat" -> :body_fat
        _ -> {:error, "Invalid series name"}
      end

    chart_data =
      socket.assigns.all_body_composition_data
      |> get_field_data(field_atom)
      |> annotate_field_data(field_atom)

    {:noreply,
     socket
     |> assign(:chart_data, chart_data)
     |> assign(:toggled_data, field_atom)
     |> push_event("update-dataset", %{series: [chart_data]})}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex h-full flex-col gap-6">
      <div class="relative w-full">
        <button
          phx-click="decrement_date"
          class="absolute left-0 top-0 cursor-pointer hover:scale-110 active:scale-90 transition-transform duration-150 z-100"
        >
          <.icon name="hero-arrow-left" />
        </button>
        <div class="overflow-hidden">
          <div class="flex justify-center items-center text-nowrap pointer-events-none
          [mask-image:linear-gradient(to_right,transparent,black_30%,black_70%,transparent_100%)]">
            <%= if @date_spectrum  do %>
              <span class="text-sm opacity-10 min-w-20 text-center">
                <%= if elem(@date_spectrum, 0) == Date.utc_today() do %>
                  Today
                <% else %>
                  <%= Calendar.strftime(elem(@date_spectrum, 0), "%b %d") %>
                <% end %>
              </span>
              <span class="text-lg opacity-20 min-w-20 text-center">
                <%= if elem(@date_spectrum, 1) == Date.utc_today() do %>
                  Today
                <% else %>
                  <%= Calendar.strftime(elem(@date_spectrum, 1), "%b %d") %>
                <% end %>
              </span>
              <span class="text-xl min-w-24 text-center">
                <%= if elem(@date_spectrum, 2) == Date.utc_today() do %>
                  Today
                <% else %>
                  <%= Calendar.strftime(elem(@date_spectrum, 2), "%b %d") %>
                <% end %>
              </span>
              <span class="text-lg opacity-20 min-w-20 text-center">
                <%= if Date.compare(elem(@date_spectrum, 3), Date.utc_today()) != :gt do %>
                  <%= if elem(@date_spectrum, 3) == Date.utc_today() do %>
                    Today
                  <% else %>
                    <%= Calendar.strftime(elem(@date_spectrum, 3), "%b %d") %>
                  <% end %>
                <% end %>
              </span>
              <span class="text-sm opacity-10 min-w-20 text-center">
                <%= if Date.compare(elem(@date_spectrum, 4), Date.utc_today()) != :gt do %>
                  <%= if elem(@date_spectrum, 4) == Date.utc_today() do %>
                    Today
                  <% else %>
                    <%= Calendar.strftime(elem(@date_spectrum, 4), "%b %d") %>
                  <% end %>
                <% end %>
              </span>
            <% end %>
          </div>
        </div>

        <button
          phx-click="increment_date"
          disabled={Date.compare(Date.add(@selected_date, 1), Date.utc_today()) == :gt}
          class={[
            "absolute right-0 top-0 cursor-pointer hover:scale-110 active:scale-90 transition-transform duration-150",
            Date.compare(Date.add(@selected_date, 1), Date.utc_today()) == :gt &&
              "opacity-20 hover:scale-100 active:scale-100"
          ]}
        >
          <.icon name="hero-arrow-right" />
        </button>
      </div>
      <%= if @live_action == :index do %>
        <section class="w-full flex flex-col gap-4">
          <div class="max-w-lg">
            <%= if @chart_data do %>
              <.time_series_graph id="line-chart-1" dataset={[@chart_data]} animated={true} />
            <% end %>
          </div>
          <div class="flex flex-col gap-4">
            <div class="flex text-sm bg-zinc-900 rounded-lg">
              <button
                phx-click="toggle-weight"
                class={[
                  "p-4 flex-1 rounded-l-lg",
                  @toggled_data == :weight_kg && "bg-zinc-800"
                ]}
              >
                Weight
              </button>
              <button
                phx-click="toggle-bone"
                class={[
                  "p-4 flex-1",
                  @toggled_data == :bone_density && "bg-zinc-800"
                ]}
              >
                Bone
              </button>
              <button
                phx-click="toggle-muscle"
                class={[
                  "p-4 flex-1",
                  @toggled_data == :muscle_mass && "bg-zinc-800"
                ]}
              >
                Muscle
              </button>
              <button
                phx-click="toggle-fat"
                class={[
                  "p-4 flex-1 rounded-r-lg",
                  @toggled_data == :body_fat && "bg-zinc-800"
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
                        <%= if @current_bc && Map.get(@current_bc, field) do %>
                          <%= Map.get(@current_bc, field) %>
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
            phx-click="back"
            class="cursor-pointer hover:scale-110 active:scale-90 transition-transform duration-150"
          >
            <.icon name="hero-arrow-left-circle-solid" class="bg-white size-20 mb-4" />
          </button>
          <button
            phx-click="add_data"
            class="cursor-pointer hover:scale-110 active:scale-90 transition-transform duration-150"
          >
            <.icon name="hero-plus-circle-solid" class="bg-white size-20 mb-4" />
          </button>
        </div>
      <% end %>
      <%= if @live_action == :add_data do %>
        <.live_component
          module={BodydashboardWeb.AddBodyCompositionData}
          id="add_data"
          current_bc={@current_bc}
          selected_date={@selected_date}
          current_user={@current_user}
        />
      <% end %>
    </div>
    """
  end
end

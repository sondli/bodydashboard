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
    all_compositions = Records.get_user_body_composition(user)

    with_dates = Enum.map(all_compositions, &{&1.weight_kg, &1.record_date})

    {result, _last} =
      Enum.map_reduce(with_dates, nil, fn
        {nil, date}, last -> {{last, date}, last}
        {weight, date}, _last -> {{weight, date}, weight}
      end)

    dataset = [
      %{
        name: "Weight",
        data: Enum.map(result, &elem(&1, 0))
      }
    ]

    categories = Enum.map(result, &Calendar.strftime(elem(&1, 1), "%b-%d"))

    chart_data = %{dataset: dataset, categories: categories}

    IO.inspect(chart_data)

    socket =
      socket
      |> assign(:chart_data, chart_data)
      |> push_event("update-dataset", chart_data)

    socket
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
          <.button phx-click="patch-body_composition">
            Body composition
          </.button>
        </aside>
        <div class="h-full w-px bg-primary-100"></div>
        <section class="w-full flex flex-col gap-6">
          <%= if @live_action == :body_composition do %>
            <h2>My Body Composition</h2>
            <div class="flex flex-row gap-6">
              <%= if @chart_data do %>
                <.line_graph
                  id="line-chart-1"
                  height={420}
                  width={640}
                  dataset={@chart_data.dataset}
                  categories={@chart_data.categories}
                />
              <% end %>
              <.form :let={f} for={@changeset} phx-submit="save">
                <div class="flex flex-col gap-6">
                  <%= for measurements <- Enum.chunk_every(@measurements, 2) do %>
                    <div class="flex gap-6">
                      <%= for %{field: field, title: title} <- measurements do %>
                        <.card title={title} class="max-w-96">
                          <div class="font-extrabold text-accent-500 h-16 flex justify-center items-center text-3xl">
                            <%= if @body_composition && Map.get(@body_composition, field) do %>
                              <%= Map.get(@body_composition, field) %>
                            <% else %>
                              0.0
                            <% end %>
                          </div>
                          <:footer>
                            <.input
                              field={f[field]}
                              value={@body_composition && Map.get(@body_composition, field)}
                              type="text"
                            />
                          </:footer>
                        </.card>
                      <% end %>
                    </div>
                  <% end %>
                </div>
                <.button type="submit">
                  Save
                </.button>
              </.form>
            </div>
          <% end %>
        </section>
      </div>
    </div>
    """
  end
end

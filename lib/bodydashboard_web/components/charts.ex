defmodule BodydashboardWeb.Charts do
  use Phoenix.Component

  defp trim(map) do
    Map.reject(map, fn {_key, val} -> is_nil(val) || val == "" end)
  end

  def get_field_data(data, field) when is_list(data) and is_atom(field) do
    data
    |> Enum.filter(&(!is_nil(Map.get(&1, field))))
    |> Enum.map(&%{x: Date.to_iso8601(&1.record_date), y: Map.get(&1, field)})
  end

  def annotate_field_data(data, field) when is_list(data) and is_atom(field) do
    case field do
      :weight_kg -> %{name: "Weight", data: data}
      :bone_density -> %{name: "Bone Density", data: data}
      :muscle_mass -> %{name: "Muscle Mass", data: data}
      :body_fat -> %{name: "Body Fat", data: data}
    end
  end

  def get_series_index(series, selected_date)
      when is_list(series) and is_struct(selected_date, Date) do
    Enum.find_index(series, fn series_item ->
      case Date.from_iso8601(series_item.x) do
        {:ok, date} ->
          Date.compare(date, selected_date) == :eq

        {:error, _} ->
          false
      end
    end)
  end

  attr :id, :string, required: true
  attr :type, :string, default: "line"
  attr :width, :integer, default: nil
  attr :height, :integer, default: nil
  attr :animated, :boolean, default: false
  attr :toolbar, :boolean, default: false
  attr :dataset, :list, default: []

  def time_series_graph(assigns) do
    ~H"""
    <div
      id={@id}
      phx-hook="time_series_graph"
      data-config={
        Jason.encode!(
          trim(%{
            height: @height,
            width: @width,
            type: @type,
            animations: %{
              enabled: @animated
            },
            toolbar: %{
              show: @toolbar
            }
          })
        )
      }
      data-series={Jason.encode!(@dataset)}
    >
    </div>
    """
  end
end

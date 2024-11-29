defmodule BodydashboardWeb.Charts do
  @moduledoc """
  Holds the charts components
  """
  alias Bodydashboard.Records.BodyComposition
  use Phoenix.Component

  defp interpolate_missing_bc_data(data) when is_list(data) do
    Enum.reduce(data, [], fn
      x, [] ->
        [
          %{
            record_date: x.record_date,
            body_fat: x.body_fat,
            weight: x.weight_kg,
            bone_density: x.bone_density,
            muscle_mass: x.muscle_mass
          }
        ]

      x, [prev | _] = acc ->
        [
          %{
            record_date: x.record_date,
            body_fat: x.body_fat || prev.body_fat,
            weight: x.weight_kg || prev.weight_kg,
            bone_density: x.bone_density || prev.bone_density,
            muscle_mass: x.muscle_mass || prev.muscle_mass
          }
          | acc
        ]
    end)
  end

  defp interpolate_missing_bc_data(_), do: {:error, :invalid_input}

  defp split_fields(data) when is_list(data) do
    {
      [
        %{
          name: "Weight",
          data: Enum.map(data, & &1.weight)
        },
        %{
          name: "Body Fat",
          data: Enum.map(data, & &1.body_fat)
        },
        %{
          name: "Muscle Mass",
          data: Enum.map(data, & &1.muscle_mass)
        },
        %{
          name: "Bone Density",
          data: Enum.map(data, & &1.bone_density)
        }
      ],
      Enum.map(data, &Calendar.strftime(&1.record_date, "%d-%b"))
    }
  end

  def map_bc_data(data) when is_list(data) do
    data
    |> interpolate_missing_bc_data()
    |> Enum.sort_by(&(&1.record_date), Date)
    |> split_fields()
  end

  def map_bc_data(data) when is_struct(data, BodyComposition) do
    map_bc_data([data])
  end

  def map_bc_data(_), do: {:error, :invalid_input}

  attr :id, :string, required: true
  attr :type, :string, default: "line"
  attr :width, :integer, default: nil
  attr :height, :integer, default: nil
  attr :animated, :boolean, default: false
  attr :toolbar, :boolean, default: false
  attr :dataset, :list, default: []
  attr :categories, :list, default: []

  def line_graph(assigns) do
    ~H"""
    <div
      id={@id}
      phx-hook="Chart"
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
      data-categories={Jason.encode!(@categories)}
    >
    </div>
    """
  end

  defp trim(map) do
    Map.reject(map, fn {_key, val} -> is_nil(val) || val == "" end)
  end
end

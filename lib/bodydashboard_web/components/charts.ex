defmodule BodydashboardWeb.Charts do
  @moduledoc """
  Holds the charts components
  """
  alias Bodydashboard.Records.BodyComposition
  use Phoenix.Component

  def map_body_composition_data(data) when is_list(data) do
    data =
      data
      |> Enum.reduce([], fn
        x, [] ->
          [%{record_date: x.record_date, body_fat: x.body_fat, weight: x.weight_kg}]

        x, [prev | _] = acc ->
          [
            %{
              record_date: x.record_date,
              body_fat: x.body_fat || prev.body_fat,
              weight: x.weight_kg || prev.weight_kg
            }
            | acc
          ]
      end)
      |> Enum.sort_by(& &1.record_date, :asc)

    IO.inspect(data, label: "test")
    data
  end

  def map_body_composition_data(data) when is_struct(data, BodyComposition) do
    map_body_composition_data([data])
  end

  def map_body_composition_data(_), do: {:error, :invalid_input}

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

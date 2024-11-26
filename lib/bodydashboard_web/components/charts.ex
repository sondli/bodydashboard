defmodule BodydashboardWeb.Charts do
  @moduledoc """
  Holds the charts components
  """
  use Phoenix.Component

  attr :id, :string, required: true

  def line_chart(assigns) do
    ~H"""
    <div id={@id}></div>
    """
  end
end

defmodule BodydashboardWeb.DashboardLive do
  use BodydashboardWeb, :live_view

  def render(assigns) do
    ~H"""
    <.link href={~p"/dashboard/body_composition"}>Body Composition</.link>
    """
  end
end

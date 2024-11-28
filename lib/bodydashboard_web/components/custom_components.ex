defmodule BodydashboardWeb.CustomComponents do
  use Phoenix.Component

  attr :title, :string, required: false
  attr :class, :string, required: false
  slot :inner_block, required: true
  slot :footer, required: false

  def card(assigns) do
    ~H"""
    <div class={["flex flex-col bg-zinc-900 rounded-lg shadow p-4", @class]}>
      <h3>
        <%= @title %>
      </h3>
      <div>
        <%= render_slot(@inner_block) %>
      </div>
      <%= if @footer do %>
        <div>
          <%= render_slot(@footer) %>
        </div>
      <% end %>
    </div>
    """
  end
end

defmodule BodydashboardWeb.DashboardBodyCompositionLive do
  use BodydashboardWeb, :live_view

  alias Bodydashboard.Records
  alias Bodydashboard.Records.BodyRecord

  def mount(_params, _session, socket) do
    user = socket.assigns.current_user
    body_records = Records.get_user_records(user)

    {:ok,
     assign(socket,
       body_records: body_records,
       changeset: BodyRecord.changeset(%BodyRecord{}, %{})
     )}
  end

  def handle_event("save", %{"body_record" => body_record_params}, socket) do
    case Records.create_body_record(socket.assigns.current_user, body_record_params) do
      {:ok, record} ->
        {:noreply,
         socket
         |> update(:body_records, fn records -> [record | records] end)
         |> put_flash(:info, "Weight saved successfully")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  def render(assigns) do
    ~H"""
    <div>
      <h1>My Body Records</h1>
      <.form :let={f} for={@changeset} phx-submit="save">
        <.input field={f[:weight_kg]} type="text" label="Weight" />
        <.button type="submit">Add weight</.button>
      </.form>

      <div>
        <%= for record <- @body_records do %>
          <div>
            Weight: <%= record.weight_kg %>
          </div>
        <% end %>
      </div>
    </div>
    """
  end
end

defmodule LukasWeb.TagLive.Show do
  use LukasWeb, :live_view

  alias Lukas.Learning

  @impl true
  def mount(_params, _session, socket) do
    Learning.watch_tags()
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:tag, Learning.get_tag!(id))}
  end

  defp page_title(:show), do: "Show Tag"
  defp page_title(:edit), do: "Edit Tag"

  @impl true
  def handle_info({:tag_updated, tag}, socket) when tag.id == socket.assigns.tag.id do
    {:noreply,
     socket
     |> assign(:tag, tag)}
  end

  def handle_info({:tag_updated, _}, socket), do: {:noreply, socket}

  def handle_info({:tag_created, _}, socket), do: {:noreply, socket}
end

defmodule LukasWeb.TagLive.FormComponent do
  use LukasWeb, :live_component

  alias Lukas.Categories

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <span class="text-primary"><%= @title %></span>
      </.header>

      <.simple_form
        for={@form}
        id="tag-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} type="text" label={gettext("Name")} />

        <div class="flex justify-end">
          <.button phx-disable-with="Saving..."><%= gettext("save") %></.button>
        </div>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{tag: tag} = assigns, socket) do
    changeset = Categories.change_tag(tag)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"tag" => tag_params}, socket) do
    changeset =
      socket.assigns.tag
      |> Categories.change_tag(tag_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"tag" => tag_params}, socket) do
    save_tag(socket, socket.assigns.action, tag_params)
  end

  defp save_tag(socket, :edit, tag_params) do
    case Categories.update_tag(socket.assigns.tag, tag_params) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("Tag updated successfully"))
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_tag(socket, :new, tag_params) do
    case Categories.create_tag(tag_params) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("Tag created successfully"))
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end
end

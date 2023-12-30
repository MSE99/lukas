defmodule LukasWeb.Operator.CourseSettingsLive do
  use LukasWeb, :live_view

  alias Lukas.Learning
  alias Lukas.Categories

  alias Phoenix.LiveView.AsyncResult
  alias LukasWeb.CommonComponents

  def mount(%{"id" => raw_id}, _, socket) do
    case Integer.parse(raw_id) do
      {id, _} ->
        next_socket =
          socket
          |> assign(:loading, AsyncResult.loading())
          |> start_async(:loading, fn ->
            {course, course_tags} = Learning.get_course_and_tags(id)
            tags = Categories.list_tags()
            %{course: course, course_tags: course_tags, tags: tags}
          end)
          |> allow_upload(:banner_image, accept: ~w(.jpg .jpeg .png .webp))

        {:ok, next_socket}

      _ ->
        {:ok, redirect(socket, to: ~p"/controls/courses")}
    end
  end

  def handle_async(:loading, {:ok, %{course: nil}}, socket) do
    {:noreply, redirect(socket, to: ~p"/controls/courses")}
  end

  def handle_async(:loading, {:ok, result}, socket) do
    %{course: course, course_tags: course_tags, tags: tags} = result

    course_tags_ids = Enum.map(course_tags, fn t -> t.id end)

    form =
      course
      |> Learning.update_course_changeset(%{})
      |> to_form()

    next_socket =
      socket
      |> assign(course: course)
      |> assign(form: form)
      |> assign(course_tags_ids: course_tags_ids)
      |> stream(:tags, tags)
      |> assign(:loading, AsyncResult.ok(socket.assigns.loading, nil))

    {:noreply, next_socket}
  end

  def handle_async(:loading, {:exit, reason}, socket) do
    {:noreply, assign(socket, :loading, AsyncResult.failed(socket.assigns.loading, reason))}
  end

  def render(assigns) do
    ~H"""
    <.async_result assign={@loading}>
      <:loading>
        <CommonComponents.navigate_breadcrumbs links={[
          {~p"/controls", "home"},
          {~p"/controls/courses", "courses"}
        ]} />

        <.loading_spinner />
      </:loading>
      <:failed>Failed to load</:failed>

      <CommonComponents.navigate_breadcrumbs links={[
        {~p"/controls", gettext("home")},
        {~p"/controls/courses", gettext("courses")},
        {~p"/controls/courses/#{@course.id}", @course.name},
        {~p"/controls/courses/#{@course.id}/settings", gettext("settings")}
      ]} />

      <h1 class="mb-5 font-bold text-lg text-primary">
        <%= gettext("Settings") %>
      </h1>

      <CommonComponents.course_banner image_src={~p"/images/#{@course.banner_image}"} />

      <.form for={@form} phx-change="validate" phx-submit="save">
        <.input field={@form[:name]} type="text" label="Name" />
        <.input field={@form[:description]} type="textarea" label="Description" />
        <.input field={@form[:price]} type="number" label="Price" />

        <p class="font-semibold mt-5">Tags</p>
        <ul id="tags" phx-update="stream" class="mt-3 flex flex-wrap gap-2">
          <li
            :for={{id, tag} <- @streams.tags}
            id={id}
            phx-click="toggle-tag"
            phx-value-id={tag.id}
            class={[
              "hover:bg-purple-800 hover:text-white transition-all hover:cursor-pointer font-bold text-sm px-4 py-1 rounded-full",
              if(
                tag.id in @course_tags_ids,
                do: "bg-primary text-white",
                else: "bg-gray-300 text-secondary"
              )
            ]}
          >
            <%= tag.name %>
          </li>
        </ul>

        <div class="my-5">
          <p class="font-bold mb-3">Banner image</p>
          <.live_file_input upload={@uploads.banner_image} />
        </div>

        <%= for entry <- @uploads.banner_image.entries do %>
          <progress value={entry.progress} max="100">
            <%= entry.progress %>%
          </progress>

          <%= for err <- upload_errors(@uploads.banner_image, entry) do %>
            <p class="alert alert-danger"><%= error_to_string(err) %></p>
          <% end %>
        <% end %>

        <div class="flex justify-end pb-5">
          <.button class="px-12">Save</.button>
        </div>
      </.form>
    </.async_result>
    """
  end

  defp error_to_string(:too_large), do: gettext("Too large")
  defp error_to_string(:not_accepted), do: gettext("You have selected an unacceptable file type")

  def handle_event("validate", %{"course" => params}, socket) do
    next_form =
      params
      |> Learning.validate_course()
      |> to_form()

    {:noreply, assign(socket, :form, next_form)}
  end

  def handle_event("save", %{"course" => params}, socket) do
    result =
      Learning.update_course(socket.assigns.course, params,
        tag_ids: socket.assigns.course_tags_ids,
        get_banner_image_path: fn -> consume_banner_image_upload(socket) end
      )

    case result do
      {:ok, course} ->
        {:noreply,
         socket
         |> assign(
           form: Learning.update_course_changeset(course, %{}) |> to_form(),
           course: course
         )}

      {:error, cs} ->
        {:noreply, assign(socket, form: to_form(cs))}
    end
  end

  def handle_event("toggle-tag", %{"id" => raw_id}, socket) do
    course_tags_ids = socket.assigns.course_tags_ids

    tag =
      raw_id
      |> String.to_integer()
      |> Categories.get_tag!()

    next_ids =
      if tag.id in course_tags_ids do
        Enum.filter(course_tags_ids, fn other -> other != tag.id end)
      else
        [tag.id | course_tags_ids]
      end

    {:noreply, socket |> assign(:course_tags_ids, next_ids) |> stream_insert(:tags, tag)}
  end

  defp consume_banner_image_upload(socket) do
    uploaded_images =
      consume_uploaded_entries(socket, :banner_image, fn %{path: path}, entry ->
        filename = "#{entry.uuid}.#{ext(entry)}"
        dist = Path.join([:code.priv_dir(:lukas), "static", "images", filename])

        File.cp!(path, dist)

        {:ok, filename}
      end)

    List.first(uploaded_images, socket.assigns.course.banner_image)
  end

  defp ext(upload_entry) do
    [ext | _] = MIME.extensions(upload_entry.client_type)
    ext
  end
end

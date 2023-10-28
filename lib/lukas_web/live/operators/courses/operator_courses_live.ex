defmodule LukasWeb.Operator.AllCoursesLive do
  use LukasWeb, :live_view

  alias Lukas.Learning
  alias Lukas.Learning.Course
  alias Lukas.Categories

  alias LukasWeb.InfiniteListLive
  alias LukasWeb.CommonComponents

  alias Phoenix.LiveView.AsyncResult

  def mount(_, _, socket) do
    if connected?(socket) do
      Learning.watch_courses()
    end

    next_socket =
      socket
      |> stream_configure(:search_tags, dom_id: fn t -> "search-tags-#{t.id}" end)
      |> assign(:picked_search_tags, [])
      |> assign(:search_name, "")
      |> assign(:loading_tags, AsyncResult.loading())
      |> start_async(:loading_tags, fn -> Categories.list_tags() end)
      |> allow_upload(:banner_image, accept: ~w(.jpg .jpeg .png .webp))

    {:ok, next_socket}
  end

  def handle_async(:loading_tags, {:ok, tags}, socket) do
    next_socket =
      socket
      |> assign(:loading_tags, AsyncResult.ok(socket.assigns.loading_tags, nil))
      |> stream(:search_tags, tags)

    {:noreply, next_socket}
  end

  def handle_async(:loading_tags, {:exit, reason}, socket) do
    {:noreply,
     assign(socket, loading_tags: AsyncResult.failed(socket.assigns.loading_tags, reason))}
  end

  def handle_params(params, _, socket),
    do: {:noreply, apply_action(socket, params, socket.assigns.live_action)}

  defp apply_action(socket, _, :new) do
    tags = Categories.list_tags()
    cs = Learning.create_course_changeset()
    form = to_form(cs)

    socket
    |> assign(form: form)
    |> assign(tag_ids: [])
    |> stream(:tags, tags, reset: true)
  end

  defp apply_action(socket, %{"id" => raw_id}, :edit) do
    {course, course_tags} = raw_id |> String.to_integer() |> Learning.get_course_and_tags()
    tags = Categories.list_tags()
    form = to_form(Learning.update_course_changeset(course, %{}))

    socket
    |> assign(course: course)
    |> assign(form: form)
    |> assign(tag_ids: Enum.map(course_tags, & &1.id))
    |> stream(:tags, tags, reset: true)
  end

  defp apply_action(socket, _, _) do
    socket
    |> assign(course: nil)
    |> assign(form: nil)
    |> assign(tag_ids: nil)
  end

  def render(assigns) do
    ~H"""
    <CommonComponents.navigate_breadcrumbs links={[
      {~p"/controls", gettext("home")},
      {~p"/controls/courses", gettext("courses")}
    ]} />

    <div class="flex justify-end mt-10 mb-16">
      <.link patch={~p"/controls/courses/new"}>
        <.button class="px-5 flex items-center">
          <%= gettext("Create course") %> <.icon name="hero-plus-circle-solid ms-2" />
        </.button>
      </.link>
    </div>

    <form id="search-form" phx-submit="search" class="mb-3">
      <label for="name" class="text-secondary font-bold px-3">
        <%= gettext("Search") %>
      </label>
      <input
        type="text"
        name="name"
        value={@search_name}
        class="w-full mt-3 rounded-full border-0 shadow"
      />
    </form>

    <.async_result assign={@loading_tags}>
      <ul id="search-tags" phx-update="stream" class="px-3 flex gap-2 flex-wrap">
        <li
          :for={{id, tag} <- @streams.search_tags}
          id={id}
          phx-click="toggle-search-tag"
          phx-value-id={tag.id}
          phx-throttle={500}
          class={[
            "hover:bg-green-600 hover:text-white transition-all hover:cursor-pointer font-bold px-6 py-2 rounded-full",
            if(
              tag.id in @picked_search_tags,
              do: "bg-primary text-white",
              else: "bg-gray-300 text-secondary"
            )
          ]}
        >
          <%= tag.name %>
        </li>
      </ul>
    </.async_result>

    <.live_component
      module={InfiniteListLive}
      id="courses-list"
      page={1}
      limit={50}
      load={fn opts -> Learning.list_courses(opts) end}
      entry_dom_id={fn course -> "courses-#{course.id}" end}
      enable_replace={true}
    >
      <:item :let={course} class="flex items-center text-secondary font-bold mb-3">
        <img src={~p"/images/#{course.banner_image}"} width={80} height={80} class="rounded" />

        <.link navigate={~p"/controls/courses/#{course.id}"} class="ms-5 hover:underline">
          <%= course.name %>
        </.link>

        <.link class="ms-auto" patch={~p"/controls/courses/#{course.id}/edit"}>
          <.icon name="hero-pencil-solid" />
        </.link>
      </:item>
    </.live_component>

    <.modal
      :if={@live_action in [:new, :edit]}
      id="new-course-modal"
      on_cancel={JS.patch(~p"/controls/courses")}
      show
    >
      <h1 class="mb-5 font-bold text-lg text-primary">
        <%= gettext("Create new course") %>
      </h1>

      <.form
        for={@form}
        phx-change="validate"
        phx-submit={if @live_action == :edit, do: "edit", else: "create"}
        id="course-form"
      >
        <.input field={@form[:name]} type="text" label={gettext("Name")} phx-debounce="blur" />
        <.input field={@form[:price]} type="number" label={gettext("Price")} phx-debounce="blur" />
        <.input
          field={@form[:description]}
          type="textarea"
          label={gettext("Description")}
          phx-debounce="blur"
        />

        <p class="font-semibold mt-5"><%= gettext("Tags") %></p>
        <ul id="tags" phx-update="stream" class="mt-3 flex flex-wrap gap-2">
          <li
            :for={{id, tag} <- @streams.tags}
            id={id}
            phx-click="toggle-tag"
            phx-value-id={tag.id}
            class={[
              "hover:bg-green-600 hover:text-white transition-all hover:cursor-pointer font-bold text-sm px-4 py-1 rounded-full",
              if(
                tag.id in @tag_ids,
                do: "bg-primary text-white",
                else: "bg-gray-300 text-secondary"
              )
            ]}
          >
            <%= tag.name %>
          </li>
        </ul>

        <div class="my-5">
          <p class="font-bold mb-3">
            <%= gettext("Banner image") %>
          </p>

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

        <div class="flex justify-end">
          <.button class="px-10">
            <%= gettext("Create") %>
          </.button>
        </div>
      </.form>
    </.modal>
    """
  end

  def error_to_string(:too_large), do: gettext("Too large")
  def error_to_string(:not_accepted), do: gettext("You have selected an unacceptable file type")

  def handle_event("validate", %{"course" => course_attrs}, socket) do
    cs = Learning.validate_course(course_attrs)
    form = to_form(cs)
    {:noreply, assign(socket, form: form)}
  end

  def handle_event("edit", %{"course" => attrs}, socket) do
    opts = [
      get_banner_image_path: fn -> consume_banner_image_upload(socket) end,
      tag_ids: socket.assigns.tag_ids
    ]

    case Learning.update_course(socket.assigns.course, attrs, opts) do
      {:ok, _} ->
        {:noreply, push_patch(socket, to: ~p"/controls/courses")}

      {:error, cs} ->
        {:noreply, assign(socket, form: to_form(cs))}
    end
  end

  def handle_event("create", %{"course" => attrs}, socket) do
    opts = [
      get_banner_image_path: fn -> consume_banner_image_upload(socket) end,
      tag_ids: socket.assigns.tag_ids
    ]

    case Learning.create_course(attrs, opts) do
      {:ok, _} ->
        {:noreply, push_patch(socket, to: ~p"/controls/courses")}

      {:error, cs} ->
        {:noreply, assign(socket, form: to_form(cs))}
    end
  end

  def handle_event("toggle-tag", %{"id" => raw_id}, socket) do
    id = String.to_integer(raw_id)
    tag = Categories.get_tag!(id)
    tag_ids = socket.assigns.tag_ids

    if Enum.find(tag_ids, nil, fn other_id -> other_id == id end) do
      next_socket =
        socket
        |> assign(tag_ids: Enum.filter(tag_ids, fn other_id -> other_id != id end))
        |> stream_insert(:tags, tag)

      {:noreply, next_socket}
    else
      {:noreply, socket |> assign(tag_ids: [id | tag_ids]) |> stream_insert(:tags, tag)}
    end
  end

  def handle_event("search", %{"name" => name}, socket) do
    cleaned_name = String.trim(name)

    send_update(
      self(),
      LukasWeb.InfiniteListLive,
      id: "courses-list",
      page: 1,
      limit: 50,
      next_loader: fn opts ->
        opts
        |> Keyword.put(:name, cleaned_name)
        |> Keyword.put(:tags, socket.assigns.picked_search_tags)
        |> Learning.list_courses()
      end
    )

    {:noreply, assign(socket, :search_name, cleaned_name)}
  end

  def handle_event("toggle-search-tag", %{"id" => raw_id}, socket) do
    tag =
      raw_id
      |> String.to_integer()
      |> Categories.get_tag!()

    next_tags_ids =
      case Enum.filter(socket.assigns.picked_search_tags, fn id -> id == tag.id end) do
        [] ->
          [tag.id | socket.assigns.picked_search_tags]

        _ ->
          Enum.filter(socket.assigns.picked_search_tags, fn id -> id != tag.id end)
      end

    send_update(
      self(),
      LukasWeb.InfiniteListLive,
      id: "courses-list",
      page: 1,
      limit: 50,
      next_loader: fn opts ->
        opts
        |> Keyword.put(:name, socket.assigns.search_name)
        |> Keyword.put(:tags, next_tags_ids)
        |> Learning.list_courses()
      end
    )

    {:noreply,
     socket |> assign(picked_search_tags: next_tags_ids) |> stream_insert(:search_tags, tag)}
  end

  def handle_info({:courses, :course_created, course}, socket) do
    send_update(self(), LukasWeb.InfiniteListLive, id: "courses-list", first_page_insert: course)
    {:noreply, socket}
  end

  def handle_info({:courses, :course_updated, course}, socket) do
    send_update(self(), LukasWeb.InfiniteListLive, id: "courses-list", replace: course)
    {:noreply, socket}
  end

  defp consume_banner_image_upload(socket) do
    uploaded_images =
      consume_uploaded_entries(socket, :banner_image, fn %{path: path}, entry ->
        filename = "#{entry.uuid}.#{ext(entry)}"
        dist = Path.join([:code.priv_dir(:lukas), "static", "images", filename])

        File.cp!(path, dist)

        {:ok, filename}
      end)

    default_image =
      case socket.assigns.live_action do
        :edit -> socket.assigns.course.banner_image
        _ -> Course.default_banner_image()
      end

    List.first(uploaded_images, default_image)
  end

  defp ext(upload_entry) do
    [ext | _] = MIME.extensions(upload_entry.client_type)
    ext
  end
end

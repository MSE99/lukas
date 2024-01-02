defmodule LukasWeb.Public.CoursesLive do
  use LukasWeb, :live_view

  alias Lukas.Learning
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

  defp apply_action(socket, _, _) do
    socket
    |> assign(course: nil)
    |> assign(form: nil)
    |> assign(tag_ids: nil)
  end

  def render(assigns) do
    ~H"""
    <CommonComponents.navigate_breadcrumbs links={[
      {~p"/", gettext("home")},
      {~p"/courses", gettext("courses")}
    ]} />

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
            "md:hover:bg-purple-800 md:hover:text-white transition-all hover:cursor-pointer font-bold px-6 py-2 rounded-full",
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
      <:item :let={course}>
        <.link navigate={~p"/courses/#{course.id}"} class="block mb-2 max-w-md mx-auto">
          <CommonComponents.course_card course={course} />
        </.link>
      </:item>
    </.live_component>
    """
  end

  def error_to_string(:too_large), do: gettext("Too large")
  def error_to_string(:not_accepted), do: gettext("You have selected an unacceptable file type")

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
end

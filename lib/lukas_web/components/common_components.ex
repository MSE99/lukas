defmodule LukasWeb.CommonComponents do
  use Phoenix.Component
  use LukasWeb, :html

  slot :inner_block, required: true

  def greeting(assigns) do
    ~H"""
    <h1 class="text-3xl text-secondary font-bold mt-10">
      <%= render_slot(@inner_block) %>
    </h1>
    """
  end

  attr :user, Lukas.Accounts.User, required: true

  slot :action, default: []
  slot :links

  def user_record(assigns) do
    ~H"""
    <div class={[
      !@user.enabled && "opacity-50",
      "text-xs font-bold lg:font-regular md:text-base transition-all flex items-center"
    ]}>
      <img
        src={~p"/profile-image?user_id=#{@user.id}"}
        width="50"
        height="50"
        class="w-[50px] h-[50px] rounded-full me-3 lg:me-5 border-4 border-primary-opaque"
      />

      <%= render_slot(@links, @user) || rendered_username(assigns) %>

      <%= for action <- @action do %>
        <%= render_slot(action, @user) %>
      <% end %>
    </div>
    """
  end

  defp rendered_username(assigns) do
    ~H"""
    <span class="me-auto text-secondary">
      <%= @user.name %>
    </span>
    """
  end

  def basic_navbar(assigns) do
    ~H"""
    <h1 class="text-2xl text-center font-bold text-orange-300">
      <%= gettext("Lukas") %>
    </h1>
    """
  end

  def navbar(assigns) do
    ~H"""
    <header class="px-6 sm:px-8 lg:px-10">
      <nav class="mx-auto max-w-3xl">
        <h1
          :if={assigns[:current_user] == nil}
          class="text-primary font-bold text-2xl mt-8 mb-16 flex justify-start"
        >
          <.link href={~p"/"} class="flex gap-3 max-w-fit">
            <%= gettext("Lukas") %>
          </.link>
        </h1>

        <ul :if={assigns[:current_user]} class="flex items-center justify-center pt-4">
          <li class="me-auto">
            <h1 class="text-primary font-bold text-2xl mt-8">
              <.link href={~p"/"} class="flex gap-3 max-w-fit">
                <%= gettext("Lukas") %>
              </.link>
            </h1>
          </li>

          <li class="-mr-3 -ml-3">
            <.link href={~p"/users/settings"}>
              <img
                width="100"
                height="100"
                class="rounded-full border-8 border-primary-opaque w-[100px] h-[100px]"
                src={~p"/profile-image"}
              />
            </.link>
          </li>
        </ul>
      </nav>
    </header>
    """
  end

  def profile_card(assigns) do
    ~H"""
    <section class="my-10 flex flex-col justify-center items-center">
      <img
        width="260"
        height="260"
        src={~p"/profile-image?user_id=#{@user.profile_image}"}
        class="rounded-full border-8 border-[rgba(253,186,116,0.27)] mb-8"
      />

      <h3 class="font-bold text-3xl text-orange-300"><%= @user.name %></h3>
      <p class="font-bold text-orange-300 text-sm">~ <%= @user.kind %> ~</p>
    </section>
    """
  end

  attr :rest, :global, include: ~w(disabled form name value)
  attr :class, :string, default: ""

  slot(:inner_block, required: true)

  def danger_button(assigns) do
    ~H"""
    <.button class={["bg-red-400 px-8 shadow hover:bg-red-600", @class] |> Enum.join(" ")} {@rest}>
      <%= render_slot(@inner_block) %>
    </.button>
    """
  end

  attr :links, :list, required: true

  def navigate_breadcrumbs(assigns) do
    ~H"""
    <ul class="gap-1 text-lg text-secondary my-8">
      <%= for {path, name} <- @links do %>
        <li class="inline">
          <.link navigate={path}><%= name %></.link>
        </li>
        <li :if={Enum.count(@links) > 1 && List.last(@links) != {path, name}} class="inline">/</li>
      <% end %>
    </ul>
    """
  end

  attr :image_src, :string, required: true

  def course_banner(assigns) do
    ~H"""
    <div class="my-5">
      <img
        src={@image_src}
        class="w-full max-w-2xl mx-auto h-auto max-h-52 md:max-h-96 rounded-lg shadow"
      />
    </div>
    """
  end

  attr :description, :string, required: true

  def course_description(assigns) do
    ~H"""
    <p>
      <%= @description %>
    </p>
    """
  end

  attr :id, :string, required: true
  attr :users, :list, required: true
  attr :title, :string, required: true

  def streamed_users_mini_list(assigns) do
    ~H"""
    <p class="font-bold mt-5 mb-6 text-secondary"><%= @title %></p>

    <ul id={@id} phx-update="stream">
      <li :for={{id, user} <- @users} id={id} class="flex items-center gap-3 mb-3">
        <img
          src={~p"/profile-image?user_id=#{user.id}"}
          height="38"
          width="38"
          class="rounded-full h-[38px] w-[38px] border-4 border-primary-opaque"
        />

        <%= user.name %>
      </li>
    </ul>
    """
  end

  attr :id, :string, required: true
  attr :tags, :list, required: true
  attr :title, :string, required: true

  def streamed_tag_list(assigns) do
    ~H"""
    <p class="font-bold mt-5 mb-6 text-secondary"><%= @title %></p>

    <ul id={@id} phx-update="stream" class="flex gap-1 flex-wrap">
      <li
        :for={{id, tag} <- @tags}
        id={id}
        class="bg-primary text-white font-bold sm:text-sm lg:text-base px-6 py-2 rounded-full"
      >
        <%= tag.name %>
      </li>
    </ul>
    """
  end

  def tag(assigns) do
    ~H"""
    <div class="bg-primary hover:bg-purple-800 transition-all text-white font-bold px-6 py-2 rounded-full">
      <%= @tag.name %>
    </div>
    """
  end

  attr :on_click, :string, required: true
  attr :price, :float, required: true
  attr :rest, :global

  def buy_button(assigns) do
    ~H"""
    <div :if={@price != "0.0"} class="flex">
      <button
        phx-click={@on_click}
        phx-throttle
        class="shadow px-4 py-2 bg-primary font-bold text-white rounded-ts-lg rounded-bs-lg hover:bg-green-500 transition-all"
        {@rest}
      >
        <%= gettext("Buy now") %>
      </button>
      <label class="shadow p-2 bg-white rounded-te-lg rounded-be-lg font-bold">
        <%= @price %> LYD
      </label>
    </div>

    <div :if={@price == "0.0"} class="flex">
      <button
        phx-click={@on_click}
        phx-throttle
        class="shadow px-4 py-2 bg-primary font-bold text-white rounded-lg hover:bg-green-500 transition-all"
        {@rest}
      >
        <%= gettext("Enlist for free") %>
      </button>
    </div>
    """
  end

  slot :inner_block
  attr :rest, :global

  def transparent_button(assigns) do
    ~H"""
    <button
      class="px-4 py-2 font-bold rounded-lg transition-all text-secondary hover:bg-gray-200 active:scale-95"
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </button>
    """
  end

  attr :course, Lukas.Learning.Course, required: true
  attr :banner_image_url, :string, required: true

  def course_card(assigns) do
    ~H"""
    <div class="flex h-[104px] bg-white shadow rounded text-secondary max-w-md mx-auto rounded-ts-lg rounded-bs-lg">
      <img
        src={@banner_image_url}
        width={110}
        height={104}
        class="w-[110px] h-[104px] rounded-ts-lg rounded-bs-lg"
      />

      <div class="p-3 text-ellipsis overflow-y-auto">
        <strong><%= @course.name %></strong>

        <p class="mt-1">
          <%= @course.description %>
        </p>
      </div>
    </div>
    """
  end

  attr :course, Lukas.Learning.Course, required: true
  attr :banner_image_url, :string, required: true

  def course_info(assigns) do
    ~H"""
    <div class="group">
      <img
        src={@banner_image_url}
        width="120"
        height="120"
        width="120"
        class="w-[135px] h-[120px] rounded-xl"
      />

      <p class="block font-bold group-hover:underline text-center text-secondary mt-2">
        <%= @course.name %>
      </p>
    </div>
    """
  end
end

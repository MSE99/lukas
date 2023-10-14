defmodule LukasWeb.CommonComponents do
  use Phoenix.Component
  use LukasWeb, :html

  def basic_navbar(assigns) do
    ~H"""
    <h1 class="text-2xl text-center font-bold text-orange-300">
      Lukas
    </h1>
    """
  end

  def profile_card(assigns) do
    ~H"""
    <section class="my-10 flex flex-col justify-center items-center">
      <img
        width="260"
        height="260"
        src={~p"/images/#{@user.profile_image}"}
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
    <ul class="flex gap-1 text-lg text-secondary my-8">
      <%= for {path, name} <- @links do %>
        <li>
          <.link navigate={path}><%= name %></.link>
        </li>
        <li :if={Enum.count(@links) > 1 && List.last(@links) != {path, name}}>/</li>
      <% end %>
    </ul>
    """
  end

  attr :image_src, :string, required: true

  def course_banner(assigns) do
    ~H"""
    <div class="my-5">
      <img src={@image_src} class="w-full h-auto max-h-52 md:max-h-96 rounded-lg shadow" />
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
          src={~p"/images/#{user.profile_image}"}
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

    <ul id={@id} phx-update="stream" class="flex gap-1">
      <li
        :for={{id, tag} <- @tags}
        id={id}
        class="bg-primary text-white font-bold px-6 py-2 rounded-full"
      >
        <%= tag.name %>
      </li>
    </ul>
    """
  end

  attr :on_click, :string, required: true
  attr :price, :float, required: true
  attr :rest, :global

  def buy_button(assigns) do
    ~H"""
    <div class="flex">
      <button
        phx-click={@on_click}
        phx-throttle
        {@rest}
        class="shadow px-4 py-2 bg-primary font-bold text-white rounded-tl-lg rounded-bl-lg hover:bg-green-500 transition-all"
      >
        Buy now
      </button>
      <label class="shadow p-2 bg-white rounded-tr-lg rounded-br-lg font-bold">
        <%= @price %> LYD
      </label>
    </div>
    """
  end

  attr :course, Lukas.Learning.Course, required: true

  def course_card(assigns) do
    ~H"""
    <div class="flex h-[104px] bg-white shadow rounded text-secondary">
      <img
        src={~p"/images/#{@course.banner_image}"}
        width={110}
        height={104}
        class="w-[110px] h-[104px] rounded-tl-lg rounded-bl-lg"
      />

      <div class="p-3">
        <strong><%= @course.name %></strong>

        <p class="mt-1">
          The description of the course lays here
        </p>
      </div>
    </div>
    """
  end
end

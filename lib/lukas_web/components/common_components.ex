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
end

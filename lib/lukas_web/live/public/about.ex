defmodule LukasWeb.Public.AboutUsLive do
  use LukasWeb, :live_view

  def mount(_, _, socket) do
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <p class="text-lg ">
      <span class="me-3">🚀</span> <%= gettext(
        "Lukas is an advanced LMS, it's a platform for both students and lecturers to study"
      ) %>
    </p>

    <h3 class="mt-8 font-bold">
      <span class="me-3">📞</span>
      <%= gettext("Contact us") %>
    </h3>

    <ul class="mt-5 text-sm">
      <li>
        <span class="me-3">📧</span>
        <%= gettext("Email") %>: lukas@mail.com
      </li>
      <li>
        <span class="me-3">📱</span>
        <%= gettext("Phone number") %>: 0911974326
      </li>
    </ul>
    """
  end
end

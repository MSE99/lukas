defmodule LukasWeb.TagLiveTest do
  use LukasWeb.ConnCase

  import Phoenix.LiveViewTest
  import Lukas.LearningFixtures

  @create_attrs %{name: "some name"}
  @update_attrs %{name: "some updated name"}
  @invalid_attrs %{name: nil}

  defp create_tag(_) do
    tag = tag_fixture()
    %{tag: tag}
  end

  describe "Index" do
    setup [:create_tag, :register_and_log_in_user]

    test "lists all tags", %{conn: conn, tag: tag} do
      {:ok, _index_live, html} = live(conn, ~p"/controls/tags")

      assert html =~ "Listing Tags"
      assert html =~ tag.name
    end

    test "saves new tag", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/controls/tags/new")

      assert index_live
             |> form("#tag-form", tag: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#tag-form", tag: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/controls/tags")

      html = render(index_live)
      assert html =~ "Tag created successfully"
      assert html =~ "some name"
    end

    test "updates tag in listing", %{conn: conn, tag: tag} do
      {:ok, index_live, _html} = live(conn, ~p"/controls/tags/#{tag.id}/edit")

      assert index_live
             |> form("#tag-form", tag: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#tag-form", tag: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/controls/tags")

      html = render(index_live)
      assert html =~ "Tag updated successfully"
      assert html =~ "some updated name"
    end
  end

  describe "Show" do
    setup [:create_tag, :register_and_log_in_user]

    test "displays tag", %{conn: conn, tag: tag} do
      {:ok, _show_live, html} = live(conn, ~p"/controls/tags/#{tag}")

      assert html =~ "Show Tag"
      assert html =~ tag.name
    end

    test "updates tag within modal", %{conn: conn, tag: tag} do
      {:ok, show_live, _html} = live(conn, ~p"/controls/tags/#{tag}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Tag"

      assert_patch(show_live, ~p"/controls/tags/#{tag}/show/edit")

      assert show_live
             |> form("#tag-form", tag: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#tag-form", tag: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/controls/tags/#{tag}")

      html = render(show_live)
      assert html =~ "Tag updated successfully"
      assert html =~ "some updated name"
    end
  end
end

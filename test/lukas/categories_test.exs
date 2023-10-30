defmodule Lukas.CategoriesTest do
  use Lukas.DataCase, async: true

  import Lukas.LearningFixtures

  alias Lukas.Categories
  alias Lukas.Categories.Tag

  @invalid_attrs %{name: nil}

  describe "tags" do
    test "list_tags/0 returns all tags" do
      tag = tag_fixture()
      assert Categories.list_tags() == [tag]
    end

    test "get_tag!/1 returns the tag with given id" do
      tag = tag_fixture()
      assert Categories.get_tag!(tag.id) == tag
    end

    test "create_tag/1 with valid data creates a tag" do
      valid_attrs = %{name: "some name"}

      assert {:ok, %Tag{} = tag} = Categories.create_tag(valid_attrs)
      assert tag.name == "some name"
    end

    test "create_tag/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Categories.create_tag(@invalid_attrs)
    end

    test "update_tag/2 with valid data updates the tag" do
      tag = tag_fixture()
      update_attrs = %{name: "some updated name"}

      assert {:ok, %Tag{} = tag} = Categories.update_tag(tag, update_attrs)
      assert tag.name == "some updated name"
    end

    test "update_tag/2 with invalid data returns error changeset" do
      tag = tag_fixture()
      assert {:error, %Ecto.Changeset{}} = Categories.update_tag(tag, @invalid_attrs)
      assert tag == Categories.get_tag!(tag.id)
    end

    test "change_tag/1 returns a tag changeset" do
      tag = tag_fixture()
      assert %Ecto.Changeset{} = Categories.change_tag(tag)
    end
  end
end

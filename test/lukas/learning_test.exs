defmodule Lukas.LearningTest do
  use Lukas.DataCase

  alias Lukas.Learning

  import Lukas.LearningFixtures

  describe "tags" do
    alias Lukas.Learning.Tag

    import Lukas.LearningFixtures

    @invalid_attrs %{name: nil}

    test "list_tags/0 returns all tags" do
      tag = tag_fixture()
      assert Learning.list_tags() == [tag]
    end

    test "get_tag!/1 returns the tag with given id" do
      tag = tag_fixture()
      assert Learning.get_tag!(tag.id) == tag
    end

    test "create_tag/1 with valid data creates a tag" do
      valid_attrs = %{name: "some name"}

      assert {:ok, %Tag{} = tag} = Learning.create_tag(valid_attrs)
      assert tag.name == "some name"
    end

    test "create_tag/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Learning.create_tag(@invalid_attrs)
    end

    test "update_tag/2 with valid data updates the tag" do
      tag = tag_fixture()
      update_attrs = %{name: "some updated name"}

      assert {:ok, %Tag{} = tag} = Learning.update_tag(tag, update_attrs)
      assert tag.name == "some updated name"
    end

    test "update_tag/2 with invalid data returns error changeset" do
      tag = tag_fixture()
      assert {:error, %Ecto.Changeset{}} = Learning.update_tag(tag, @invalid_attrs)
      assert tag == Learning.get_tag!(tag.id)
    end

    test "delete_tag/1 deletes the tag" do
      tag = tag_fixture()
      assert {:ok, %Tag{}} = Learning.delete_tag(tag)
      assert_raise Ecto.NoResultsError, fn -> Learning.get_tag!(tag.id) end
    end

    test "change_tag/1 returns a tag changeset" do
      tag = tag_fixture()
      assert %Ecto.Changeset{} = Learning.change_tag(tag)
    end
  end

  describe "courses" do
    setup do
      %{tag: tag_fixture()}
    end

    test "should create a new course and dispatch an event.", %{tag: tag} do
      Learning.watch_courses()

      {:ok, course} = Learning.create_course(%{"name" => "Japanese basic"}, [tag.id])
      assert course.name == "Japanese basic"

      assert_received({:course_created, ^course})
    end

    test "tag_course/2 should add the tag to the course with the given id and update the course.",
         %{tag: tag} do
      {:ok, course} = Learning.create_course(%{"name" => "Japanese basic"})
      Learning.tag_course(course.id, tag.id)

      assert Learning.get_course_and_tags(course.id) == {course, [tag]}
    end

    test "untag_course/2 should remove the tag to the course with the given id and update the course.",
         %{tag: tag} do
      {:ok, course} = Learning.create_course(%{"name" => "Japanese basic"}, [tag.id])

      Learning.untag_course(course.id, tag.id)
      assert Learning.get_course_and_tags(course.id) == {course, []}
    end

    test "update_course/2 should update the course." do
      {:ok, course} = Learning.create_course(%{"name" => "Japanese basic"}, [])
      {:ok, next_course} = Learning.update_course(course, %{"name" => "Japanese advanced"})
      assert next_course.name =~ "Japanese advanced"
    end

    test "watch_course/1 should allow us to watch a course for any updates.", %{tag: tag} do
      cr = course_fixture()
      Learning.watch_course(cr)

      {:ok, updated} = Learning.update_course(cr, %{"name" => "Japanese advanced"})
      assert_received({:course_updated, ^updated})

      Learning.tag_course(cr.id, tag.id)
      assert_received({:course_tagged, ^tag})

      Learning.untag_course(cr.id, tag.id)
      assert_received({:course_untagged, ^tag})
    end
  end
end

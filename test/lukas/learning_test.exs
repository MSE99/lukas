defmodule Lukas.LearningTest do
  use Lukas.DataCase

  alias Lukas.Learning

  import Lukas.LearningFixtures
  import Lukas.AccountsFixtures

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

      assert_received({:courses, :course_created, ^course})
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
      assert_received({:course, _, :course_updated, ^updated})

      Learning.tag_course(cr.id, tag.id)
      assert_received({:course, _, :course_tagged, ^tag})

      Learning.untag_course(cr.id, tag.id)
      assert_received({:course, _, :course_untagged, ^tag})
    end
  end

  describe "courses lessons" do
    setup do
      %{course: course_fixture()}
    end

    test "create_lesson/2 should create a new lesson and dispatch an event.", %{course: course} do
      Learning.watch_course(course)

      {:ok, lesson} =
        Learning.create_lesson(course, %{"title" => "Lesson 1", "description" => "Mathematics I"})

      assert_received({:course, _, :lesson_added, ^lesson})
    end

    test "update_lesson/2 should update a lesson and dispatch an event.", %{course: course} do
      Learning.watch_course(course)

      {:ok, lesson} =
        Learning.create_lesson(course, %{"title" => "Lesson 1", "description" => "Mathematics I"})

      assert_received({:course, _, :lesson_added, ^lesson})

      {:ok, next_lesson} =
        Learning.update_lesson(lesson, %{"title" => "Lesson 2", "description" => "Mathematics I"})

      assert_received({:course, _, :lesson_updated, ^next_lesson})
    end

    test "remove_lesson/1 should remove a lesson and dispatch a removal event.", %{course: course} do
      Learning.watch_course(course)

      {:ok, lesson} =
        Learning.create_lesson(course, %{"title" => "Lesson 1", "description" => "Mathematics I"})

      assert_received({:course, _, :lesson_added, ^lesson})

      {:ok, removed_lesson} = Learning.remove_lesson(lesson)
      assert_received({:course, _, :lesson_deleted, ^removed_lesson})
    end
  end

  describe "courses lesson topics" do
    setup do
      course = course_fixture()

      {:ok, lesson} =
        Learning.create_lesson(course, %{"title" => "Lesson 1", "description" => "Mathematics I"})

      %{course: course, lesson: lesson}
    end

    test "create_text_topic/2 should add a topic to a given lesson.", %{
      lesson: lesson,
      course: course
    } do
      Learning.watch_course(course)

      {:ok, topic} =
        Learning.create_text_topic(lesson, %{
          "title" => "Topic 1",
          "content" => "foo is great bar is none."
        })

      assert topic.lesson_id == lesson.id
      assert topic.title == "Topic 1"
      assert topic.content == "foo is great bar is none."

      assert_receive({:course, _, :topic_added, ^topic})
    end

    test "remove_text_topic/1 should remove a topic.", %{
      lesson: lesson,
      course: course
    } do
      Learning.watch_course(course)

      {:ok, topic} =
        Learning.create_text_topic(lesson, %{
          "title" => "Topic 1",
          "content" => "foo is great bar is none."
        })

      assert_receive({:course, _, :topic_added, ^topic})

      {:ok, removed_topic} = Learning.remove_topic(topic)

      assert_receive({:course, _, :topic_removed, ^removed_topic})
    end

    test "update_topic/1 should update a topic and dispatch an event.", %{
      lesson: lesson,
      course: course
    } do
      Learning.watch_course(course)

      {:ok, topic} =
        Learning.create_text_topic(lesson, %{
          "title" => "Topic 1",
          "content" => "foo is great bar is none."
        })

      assert_receive({:course, _, :topic_added, ^topic})

      {:ok, updated_topic} =
        Learning.update_topic(topic, %{
          "title" => "Topic 2",
          "content" => "foo is great bar is none."
        })

      assert_received({:course, _, :topic_updated, ^updated_topic})
    end
  end

  describe "teaching" do
    setup do
      course = course_fixture()
      lecturer = user_fixture(%{kind: :lecturer})

      %{course: course, lecturer: lecturer}
    end

    test "list_course_lecturers/1 should return an empty list.", %{course: course} do
      assert Learning.list_course_lecturers(course) == []
    end

    test "list_course_lecturers/1 should return a list of all lecturers for the given course.", %{
      course: course,
      lecturer: lecturer
    } do
      {:ok, _} = Learning.add_lecturer_to_course(course, lecturer)
      assert Learning.list_course_lecturers(course) == [lecturer]
    end

    test "possible_lecturers_for/1 should return list of possible lecturers for course.", %{
      course: course,
      lecturer: lecturer
    } do
      lecturers = Learning.possible_lecturers_for(course)

      assert Enum.find(lecturers, fn lect -> lect.id == lecturer.id end)
    end
  end

  describe "enrollment" do
    setup do
      course = course_fixture()
      student = user_fixture(%{kind: :student})

      %{student: student, course: course}
    end

    test "enroll_student/2 should enroll a student into a given course and publish an event to the course.",
         %{
           student: student,
           course: course
         } do
      course_id = course.id
      Learning.watch_course(course_id)
      {:ok, enrollment} = Learning.enroll_student(course, student)

      assert enrollment.student_id == student.id
      assert enrollment.course_id == course.id

      assert_received({:course, ^course_id, :student_enrolled, ^student})
    end

    test "enroll_student/2 should return an error if the student is already enrolled.", %{
      student: student,
      course: course
    } do
      Learning.enroll_student(course, student)
      assert {:error, _} = Learning.enroll_student(course, student)
    end
  end
end

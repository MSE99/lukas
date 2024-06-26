defmodule Lukas.LearningFixtures do
  alias Lukas.{Learning, Accounts, Categories}

  def tag_fixture(attrs \\ %{}) do
    {:ok, tag} =
      attrs
      |> Enum.into(%{
        name: "Tag ##{System.unique_integer()}"
      })
      |> Categories.create_tag()

    tag
  end

  def course_fixture(attrs \\ %{}) do
    {:ok, course} =
      attrs
      |> Map.put_new(:name, "Course ##{System.unique_integer([:positive])}")
      |> Map.put_new(:price, 200.0)
      |> Map.put_new(:description, "Course description ##{System.unique_integer([:positive])}")
      |> Learning.create_course([])

    course
  end

  def lesson_fixture(%Learning.Course{} = course, attrs \\ %{}) do
    filled =
      attrs
      |> Map.put_new("title", "Lesson ##{System.unique_integer([:positive])}")
      |> Map.put_new("description", "##{System.unique_integer([:positive])}")

    {:ok, lesson} = Learning.Course.Content.create_lesson(course, filled)

    lesson
  end

  def text_topic_fixture(%Learning.Lesson{} = lesson, attrs \\ %{}) do
    filled =
      attrs
      |> Map.put_new("title", "Topic ##{System.unique_integer([:positive])}")
      |> Map.put_new("content", "##{System.unique_integer([:positive])}")

    {:ok, topic} = Learning.Course.Content.create_text_topic(lesson, filled)
    topic
  end

  def teaching_fixture(
        %Learning.Course{} = course,
        %Accounts.User{kind: :lecturer} = teacher
      ) do
    {:ok, teaching} = Learning.Course.Staff.add_lecturer_to_course(course, teacher)
    teaching
  end
end

defmodule Lukas.LearningFixtures do
  def tag_fixture(attrs \\ %{}) do
    {:ok, tag} =
      attrs
      |> Enum.into(%{
        name: "Tag ##{System.unique_integer()}"
      })
      |> Lukas.Learning.create_tag()

    tag
  end

  def course_fixture(attrs \\ %{}) do
    {:ok, course} =
      attrs
      |> Map.put_new(:name, "Course ##{System.unique_integer([:positive])}")
      |> Lukas.Learning.create_course()

    course
  end

  def lesson_fixture(%Lukas.Learning.Course{} = course, attrs \\ %{}) do
    filled =
      attrs
      |> Map.put_new("title", "Lesson ##{System.unique_integer([:positive])}")
      |> Map.put_new("description", "##{System.unique_integer([:positive])}")

    {:ok, lesson} = Lukas.Learning.create_lesson(course, filled)

    lesson
  end

  def text_topic_fixture(%Lukas.Learning.Lesson{} = lesson, attrs \\ %{}) do
    filled =
      attrs
      |> Map.put_new("title", "Topic ##{System.unique_integer([:positive])}")
      |> Map.put_new("content", "##{System.unique_integer([:positive])}")

    {:ok, topic} = Lukas.Learning.create_text_topic(lesson, filled)
    topic
  end

  def teaching_fixture(
        %Lukas.Learning.Course{} = course,
        %Lukas.Accounts.User{kind: :lecturer} = teacher
      ) do
    {:ok, teaching} = Lukas.Learning.add_lecturer_to_course(course, teacher)
    teaching
  end
end

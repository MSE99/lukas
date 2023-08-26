defmodule Lukas.LearningFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Lukas.Learning` context.
  """

  @doc """
  Generate a tag.
  """
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
end

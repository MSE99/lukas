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
        name: "some name"
      })
      |> Lukas.Learning.create_tag()

    tag
  end

  def course_fixture(attrs \\ %{}) do
    {:ok, course} =
      attrs
      |> Map.put_new(:name, "some name")
      |> Map.put_new_lazy(:tags, fn -> [tag_fixture()] end)
      |> Map.put_new_lazy(:teachings, fn ->
        [Lukas.AccountsFixtures.user_fixture(%{kind: :lecturer})]
      end)
      |> Lukas.Learning.create_course()

    course
  end
end

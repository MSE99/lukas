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
end

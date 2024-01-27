defmodule Lukas.Media do
  @moduledoc """
    Module Media contains procedures for storing and retrieving blobs (images/videos) from the file system
  """

  alias Lukas.Learning

  def read_lesson_image!(%Learning.Lesson{} = l) do
    l
    |> get_lesson_image_filepath()
    |> File.read!()
  end

  def get_lesson_image_filepath(%Learning.Lesson{image: image}) do
    Path.join([
      :code.priv_dir(:lukas),
      "static",
      "content",
      "courses",
      "images",
      image
    ])
  end
end

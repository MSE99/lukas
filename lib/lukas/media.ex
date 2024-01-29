defmodule Lukas.Media do
  @moduledoc """
    Module Media contains procedures for storing and retrieving blobs (images/videos) from the file system
  """

  def read_lesson_image!(l) do
    l
    |> get_lesson_image_filepath()
    |> File.read!()
  end

  def get_topic_media_filepath(%{media: media}) do
    get_lesson_image_filepath(media)
  end

  def get_lesson_image_filepath(%{image: image}) do
    get_lesson_image_filepath(image)
  end

  def get_lesson_image_filepath(image) when is_binary(image) do
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

defmodule Lukas.Learning do
  import Ecto.Query, warn: false

  alias Lukas.Repo

  ## Courses
  alias Lukas.Learning.Course
  alias Lukas.Learning.Tagging

  def list_courses(), do: from(c in Course, preload: [:tags]) |> Repo.all()

  def create_course(attrs) do
    %Course{}
    |> Course.changeset(attrs)
    |> Repo.insert()
    |> maybe_emit_course_created()
  end

  def create_course(attrs, tag_ids) do
    Ecto.Multi.new()
    |> Ecto.Multi.insert(:course, Course.changeset(%Course{}, attrs))
    |> Ecto.Multi.run(
      :tags,
      fn _, %{course: course} ->
        course_id = course.id

        taggings =
          tag_ids
          |> Enum.map(fn tag_id -> Repo.insert(Tagging.new(tag_id, course_id)) end)

        {:ok, taggings}
      end
    )
    |> Repo.transaction()
    |> case do
      {:ok, %{course: course}} ->
        :ok
        Phoenix.PubSub.broadcast(Lukas.PubSub, "courses", {:course_created, course})

      {:error, :course, cs, _} ->
        {:error, cs}
    end
  end

  def update_course(course, attrs) do
    course
    |> Course.changeset(attrs)
    |> Repo.update()
    |> maybe_emit_course_updated()
  end

  def create_course_changeset(attrs \\ %{}) do
    Course.changeset(%Course{}, attrs)
  end

  def validate_course(attrs) do
    Course.changeset(%Course{}, attrs)
    |> Map.put(:action, :validate)
  end

  def watch_courses(), do: Phoenix.PubSub.subscribe(Lukas.PubSub, "courses")

  def maybe_emit_course_created({:ok, course} = res) do
    Phoenix.PubSub.broadcast(Lukas.PubSub, "courses", {:course_created, course})
    res
  end

  def maybe_emit_course_created(res), do: res

  def maybe_emit_course_updated({:ok, course} = res) do
    Phoenix.PubSub.broadcast(Lukas.PubSub, "courses", {:course_updated, course})
    res
  end

  def maybe_emit_course_updated(res), do: res

  ## Tags

  alias Lukas.Learning.Tag

  def list_tags do
    Repo.all(Tag)
  end

  def get_tag!(id), do: Repo.get!(Tag, id)

  def create_tag(attrs \\ %{}) do
    %Tag{}
    |> Tag.changeset(attrs)
    |> Repo.insert()
    |> maybe_emit_tag_created()
  end

  def update_tag(%Tag{} = tag, attrs) do
    tag
    |> Tag.changeset(attrs)
    |> Repo.update()
    |> maybe_emit_tag_updated()
  end

  def delete_tag(%Tag{} = tag) do
    Repo.delete(tag)
  end

  def change_tag(%Tag{} = tag, attrs \\ %{}) do
    Tag.changeset(tag, attrs)
  end

  def watch_tags(), do: Phoenix.PubSub.subscribe(Lukas.PubSub, "tags")

  def maybe_emit_tag_created({:ok, tag} = res) do
    Phoenix.PubSub.broadcast(Lukas.PubSub, "tags", {:tag_created, tag})
    res
  end

  def maybe_emit_tag_created(res), do: res

  def maybe_emit_tag_updated({:ok, tag} = res) do
    Phoenix.PubSub.broadcast(Lukas.PubSub, "tags", {:tag_updated, tag})
    res
  end

  def maybe_emit_tag_updated(res), do: res
end

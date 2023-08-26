defmodule Lukas.Learning do
  import Ecto.Query, warn: false

  alias Lukas.Repo

  ## Courses
  alias Lukas.Learning.Course

  def list_courses(), do: Repo.all(Course)

  def create_course(attrs) do
    %Course{}
    |> Course.changeset(attrs)
    |> Repo.insert()
    |> maybe_emit_course_created()
  end

  def update_course(attrs) do
    %Course{}
    |> Course.changeset(attrs)
    |> Repo.update()
    |> maybe_emit_course_updated()
  end

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

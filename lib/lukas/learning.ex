defmodule Lukas.Learning do
  import Ecto.Query, warn: false

  alias Lukas.Repo

  ## Courses
  alias Lukas.Learning.Course
  alias Lukas.Learning.Lesson
  alias Lukas.Learning.Tagging
  alias Lukas.Learning.Tag

  def create_lesson(%Course{} = course, attrs \\ %{}) do
    attrs_with_course = Map.merge(attrs, %{"course_id" => course.id})

    %Lesson{}
    |> Lesson.changeset(attrs_with_course)
    |> Repo.insert()
    |> maybe_emit_lesson_added()
  end

  def update_lesson(%Lesson{} = lesson, attrs \\ %{}) do
    lesson
    |> Lesson.changeset(attrs)
    |> Repo.update()
    |> maybe_emit_lesson_updated()
  end

  def remove_lesson(%Lesson{} = lesson) do
    Repo.delete(lesson)
    |> maybe_emit_lesson_deleted()
  end

  def create_text_topic(%Lesson{id: lesson_id} = lesson, attrs) do
    %Lesson.TextTopic{lesson_id: lesson_id}
    |> Lesson.TextTopic.changeset(attrs)
    |> Repo.insert()
    |> maybe_emit_topic_added(lesson)
  end

  def remove_topic(%Lesson.TextTopic{} = topic) do
    topic_with_lesson = Repo.preload(topic, :lesson)

    Repo.delete(topic_with_lesson)
    |> maybe_emit_topic_removed(topic_with_lesson.lesson)
  end

  def update_topic(%Lesson.TextTopic{} = topic, attrs) do
    topic_with_lesson = Repo.preload(topic, :lesson)

    topic_with_lesson
    |> Lesson.TextTopic.changeset(attrs)
    |> Repo.update()
    |> maybe_emit_topic_updated(topic_with_lesson.lesson)
  end

  def list_courses(), do: from(c in Course, preload: [:tags]) |> Repo.all()

  def get_course_and_tags(course_id) when is_integer(course_id) do
    Ecto.Multi.new()
    |> Ecto.Multi.one(:course, from(c in Course, where: c.id == ^course_id))
    |> Ecto.Multi.all(
      :tags,
      from(
        tagging in Tagging,
        join: tag in Tag,
        on: tag.id == tagging.tag_id,
        where: tagging.course_id == ^course_id,
        select: tag
      )
    )
    |> Repo.transaction()
    |> case do
      {:ok, %{course: course, tags: tags}} ->
        {course, tags}
    end
  end

  def untag_course(course_id, tag_id) when is_integer(course_id) and is_integer(tag_id) do
    from(
      tagging in Tagging,
      where: tagging.course_id == ^course_id and tagging.tag_id == ^tag_id
    )
    |> Repo.delete_all()

    emit_course_untagged(course_id, tag_id)
  end

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
        Phoenix.PubSub.broadcast(Lukas.PubSub, "courses", {:courses, :course_created, course})
        {:ok, course}

      {:error, :course, cs, _} ->
        {:error, cs}
    end
  end

  def tag_course(course, tag) when is_integer(course) and is_integer(tag) do
    Tagging.new(tag, course)
    |> Repo.insert()
    |> maybe_emit_course_tagged()
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

  def watch_course(%Course{id: id}), do: Phoenix.PubSub.subscribe(Lukas.PubSub, "courses/#{id}")

  def maybe_emit_course_created({:ok, course} = res) do
    Phoenix.PubSub.broadcast(Lukas.PubSub, "courses", {:courses, :course_created, course})
    res
  end

  def maybe_emit_course_created(res), do: res

  def maybe_emit_course_updated({:ok, course} = res) do
    Phoenix.PubSub.broadcast(Lukas.PubSub, "courses", {:courses, :course_updated, course})

    Phoenix.PubSub.broadcast(
      Lukas.PubSub,
      "courses/#{course.id}",
      {:courses, :course_updated, course}
    )

    res
  end

  def maybe_emit_course_updated(res), do: res

  def maybe_emit_course_tagged({:ok, tagging} = res) do
    tag = Repo.get!(Tag, tagging.tag_id)

    Phoenix.PubSub.broadcast(
      Lukas.PubSub,
      "courses/#{tagging.course_id}",
      {:courses, :course_tagged, tag}
    )

    res
  end

  def maybe_emit_course_tagged(res), do: res

  def maybe_emit_lesson_added({:ok, lesson} = res) do
    Phoenix.PubSub.broadcast(
      Lukas.PubSub,
      "courses/#{lesson.course_id}",
      {:courses, :lesson_added, lesson}
    )

    res
  end

  def maybe_emit_course_lesson_added(res), do: res

  def maybe_emit_lesson_updated({:ok, lesson} = res) do
    Phoenix.PubSub.broadcast(
      Lukas.PubSub,
      "courses/#{lesson.course_id}",
      {:courses, :lesson_updated, lesson}
    )

    res
  end

  def maybe_emit_course_lesson_updated(res), do: res

  def maybe_emit_lesson_deleted({:ok, lesson} = res) do
    Phoenix.PubSub.broadcast(
      Lukas.PubSub,
      "courses/#{lesson.course_id}",
      {:courses, :lesson_deleted, lesson}
    )

    res
  end

  def maybe_emit_course_lesson_deleted(res), do: res

  def maybe_emit_topic_added({:ok, topic} = res, lesson) do
    Phoenix.PubSub.broadcast(
      Lukas.PubSub,
      "courses/#{lesson.course_id}",
      {:courses, :topic_added, topic}
    )

    res
  end

  def maybe_emit_topic_added(res, _), do: res

  def maybe_emit_topic_removed({:ok, topic} = res, lesson) do
    Phoenix.PubSub.broadcast(
      Lukas.PubSub,
      "courses/#{lesson.course_id}",
      {:courses, :topic_removed, topic}
    )

    res
  end

  def maybe_emit_topic_removed(res, _), do: res

  def maybe_emit_topic_updated({:ok, topic} = res, lesson) do
    Phoenix.PubSub.broadcast(
      Lukas.PubSub,
      "courses/#{lesson.course_id}",
      {:courses, :topic_updated, topic}
    )

    res
  end

  def maybe_emit_topic_updated(res, _), do: res

  def emit_course_untagged(course_id, tag_id) do
    tag = Repo.get!(Tag, tag_id)

    Phoenix.PubSub.broadcast(
      Lukas.PubSub,
      "courses/#{course_id}",
      {:courses, :course_untagged, tag}
    )
  end

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

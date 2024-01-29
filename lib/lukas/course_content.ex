defmodule Lukas.Learning.Course.Content do
  import LukasWeb.Gettext

  alias Lukas.Learning.{Course, Lesson, Query}
  alias Lukas.Accounts
  alias Lukas.Repo

  alias Ecto.Multi

  def topic_kinds() do
    %{
      gettext("text") => "text",
      gettext("video") => "video",
      gettext("file") => "file"
    }
  end

  def get_lesson(course_id, lesson_id) when is_integer(course_id) and is_integer(lesson_id) do
    Query.lesson_by_course_id_and_id(course_id, lesson_id)
    |> Repo.one()
  end

  def get_lesson!(course_id, lesson_id) when is_integer(course_id) and is_integer(lesson_id) do
    Query.lesson_by_course_id_and_id(course_id, lesson_id)
    |> Repo.one!()
  end

  def get_lesson_for_student!(%Accounts.User{} = student, course_id, lesson_id) do
    Multi.new()
    |> Multi.one(:lesson, Query.lesson_by_course_id_and_id(course_id, lesson_id))
    |> Multi.one(:prog, Query.lesson_progress(course_id, lesson_id, student.id))
    |> Multi.one(:enrollment, Query.student_enrollment(course_id, student.id))
    |> Repo.transaction()
    |> case do
      {:ok, %{lesson: lesson, prog: prog, enrollment: enr}} when enr != nil ->
        lesson
        |> Map.from_struct()
        |> Map.put(:progressed, prog != nil)
    end
  end

  def get_topic_for_student!(%Accounts.User{} = student, course_id, lesson_id, topic_id) do
    Multi.new()
    |> Multi.one(:topic, Query.topic_by_ids(course_id, lesson_id, topic_id))
    |> Multi.one(:prog, Query.topic_progress(course_id, lesson_id, topic_id, student.id))
    |> Multi.one(:enrollment, Query.student_enrollment(course_id, student.id))
    |> Repo.transaction()
    |> case do
      {:ok, %{topic: topic, prog: prog, enrollment: enr}} when enr != nil ->
        topic
        |> Map.from_struct()
        |> Map.put(:progressed, prog != nil)
    end
  end

  def get_topic_by_ids(course_id, lesson_id, topic_id) do
    Query.topic_by_ids(course_id, lesson_id, topic_id)
    |> Repo.one()
  end

  def get_topic_for_lecturer(%Accounts.User{} = lecturer, course_id, lesson_id, topic_id) do
    Multi.new()
    |> Multi.one(:topic, Query.topic_by_ids(course_id, lesson_id, topic_id))
    |> Multi.one(:course, Query.course_for_lecturer(course_id, lecturer.id))
    |> Repo.transaction()
    |> case do
      {:ok, %{topic: topic, course: course}} when course != nil -> topic
      _ -> nil
    end
  end

  def get_lesson_and_topic_names(course_id, lesson_id) do
    Ecto.Multi.new()
    |> Ecto.Multi.one(:lesson, Query.lesson_by_course_id_and_id(course_id, lesson_id))
    |> Ecto.Multi.all(:topics, Query.topics_for_lesson_with_no_content(course_id, lesson_id))
    |> Repo.transaction()
    |> case do
      {:ok, %{lesson: lesson, topics: topics}} -> {lesson, topics}
    end
  end

  def create_lesson(%Course{} = course, attrs \\ %{}, opts \\ []) do
    get_image = Keyword.get(opts, :get_image, fn -> Lesson.default_image() end)
    attrs_with_course = Map.merge(attrs, %{"course_id" => course.id})

    Ecto.Multi.new()
    |> Ecto.Multi.insert(:lesson, Lesson.changeset(%Lesson{}, attrs_with_course))
    |> Ecto.Multi.run(:lesson_with_image, fn _repo, %{lesson: lesson} ->
      lesson_with_image =
        Lesson.update_image_changeset(lesson, %{image: get_image.()})
        |> Repo.update!()

      {:ok, lesson_with_image}
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{lesson_with_image: lesson}} -> {:ok, lesson}
      {:error, :lesson, lesson_cs, _} -> {:error, lesson_cs}
    end
    |> maybe_emit_lesson_added()
  end

  def validate_lesson(%Course{} = course, attrs \\ %{}) do
    create_lesson_changeset(course, attrs)
    |> Map.put(:action, :validate)
  end

  def create_lesson_changeset(%Course{} = course, attrs \\ %{}) do
    attrs_with_course = Map.merge(attrs, %{"course_id" => course.id})

    %Lesson{}
    |> Lesson.changeset(attrs_with_course)
  end

  def edit_lesson_changeset(%Lesson{} = lesson, attrs \\ %{}) do
    lesson
    |> Lesson.changeset(attrs)
  end

  def update_lesson(%Lesson{} = lesson, attrs \\ %{}, opts \\ []) do
    get_image = Keyword.get(opts, :get_image, fn -> Lesson.default_image() end)

    Ecto.Multi.new()
    |> Ecto.Multi.update(:lesson, Lesson.changeset(lesson, attrs))
    |> Ecto.Multi.run(:lesson_with_image, fn _repo, %{lesson: lesson} ->
      lesson_with_image =
        Lesson.update_image_changeset(lesson, %{image: get_image.()})
        |> Repo.update!()

      {:ok, lesson_with_image}
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{lesson_with_image: lesson}} -> {:ok, lesson}
      {:error, :lesson, lesson_cs, _} -> {:error, lesson_cs}
    end
    |> maybe_emit_lesson_updated()
  end

  def remove_lesson(id) when is_integer(id) do
    Repo.get(Lesson, id) |> remove_lesson()
  end

  def remove_lesson(%Lesson{} = lesson) do
    Repo.delete(lesson)
    |> maybe_emit_lesson_deleted()
  end

  def create_text_topic(%Lesson{id: lesson_id} = lesson, attrs, opts \\ []) do
    get_media = Keyword.get(opts, :get_media, fn -> Lesson.Topic.default_image() end)

    Ecto.Multi.new()
    |> Ecto.Multi.insert(
      :topic,
      Lesson.Topic.changeset(%Lesson.Topic{lesson_id: lesson_id, kind: :text}, attrs)
    )
    |> Ecto.Multi.run(:topic_with_image, fn _, %{topic: topic} ->
      topic_with_image =
        topic
        |> Lesson.Topic.update_changeset(%{media: get_media.()})
        |> Repo.update!()

      {:ok, topic_with_image}
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{topic_with_image: topic}} ->
        {:ok, topic}

      {:error, :topic, topic_cs, _} ->
        {:error, topic_cs}
    end
    |> maybe_emit_topic_added(lesson)
  end

  def get_topic!(course_id, lesson_id, topic_id)
      when is_integer(lesson_id) and is_integer(topic_id) do
    Query.topic_by_ids(course_id, lesson_id, topic_id)
    |> Repo.one!()
  end

  def get_topic(lesson_id, topic_id) when is_integer(topic_id) do
    Query.topic_by_lesson_id_and_id(lesson_id, topic_id)
    |> Repo.one()
  end

  def update_topic_changeset(attrs \\ %{}) do
    %Lesson.Topic{}
    |> Lesson.Topic.changeset(attrs)
  end

  def create_topic_changeset(%Lesson{id: lesson_id}, attrs \\ %{}) do
    %Lesson.Topic{lesson_id: lesson_id}
    |> Lesson.Topic.changeset(attrs)
  end

  def validate_topic(%Lesson{} = lesson, attrs \\ %{}) do
    create_topic_changeset(lesson, attrs)
    |> Map.put(:action, :validate)
  end

  def remove_topic(%Lesson.Topic{} = topic) do
    topic_with_lesson = Repo.preload(topic, :lesson)

    Repo.delete(topic_with_lesson)
    |> maybe_emit_topic_removed(topic_with_lesson.lesson)
  end

  def update_topic(%Lesson.Topic{} = topic, attrs, opts \\ []) do
    get_media = Keyword.get(opts, :get_media, fn -> topic.media end)
    topic_with_lesson = Repo.preload(topic, :lesson)

    Ecto.Multi.new()
    |> Ecto.Multi.update(
      :topic,
      Lesson.Topic.update_changeset(topic_with_lesson, attrs)
    )
    |> Ecto.Multi.run(
      :topic_with_image,
      fn _, %{topic: topic} ->
        next_topic =
          Lesson.Topic.update_changeset(topic, %{media: get_media.()}) |> Repo.update!()

        {:ok, next_topic}
      end
    )
    |> Repo.transaction()
    |> case do
      {:ok, %{topic_with_image: topic}} -> {:ok, topic}
      {:error, :topic, topic_cs, _} -> {:error, topic_cs}
    end
    |> maybe_emit_topic_updated(topic_with_lesson.lesson)
  end

  def maybe_emit_lesson_added({:ok, lesson} = res) do
    emit(
      "courses/#{lesson.course_id}",
      {:course, lesson.course_id, :lesson_added, lesson}
    )

    res
  end

  def maybe_emit_lesson_added(res), do: res

  def maybe_emit_lesson_updated({:ok, lesson} = res) do
    emit(
      "courses/#{lesson.course_id}",
      {:course, lesson.course_id, :lesson_updated, lesson}
    )

    res
  end

  def maybe_emit_lesson_updated(res), do: res

  def maybe_emit_lesson_deleted({:ok, lesson} = res) do
    emit(
      "courses/#{lesson.course_id}",
      {:course, lesson.course_id, :lesson_deleted, lesson}
    )

    res
  end

  def maybe_emit_lesson_deleted(res), do: res

  def maybe_emit_topic_added({:ok, topic} = res, lesson) do
    emit(
      "courses/#{lesson.course_id}",
      {:course, lesson.course_id, :topic_added, topic}
    )

    res
  end

  def maybe_emit_topic_added(res, _), do: res

  def maybe_emit_topic_removed({:ok, topic} = res, lesson) do
    emit(
      "courses/#{lesson.course_id}",
      {:course, lesson.course_id, :topic_removed, topic}
    )

    res
  end

  def maybe_emit_topic_removed(res, _), do: res

  def maybe_emit_topic_updated({:ok, topic} = res, lesson) do
    emit(
      "courses/#{lesson.course_id}",
      {:course, lesson.course_id, :topic_updated, topic}
    )

    res
  end

  def maybe_emit_topic_updated(res, _), do: res

  defp emit(topic, message) do
    Phoenix.PubSub.broadcast(Lukas.PubSub, topic, message)
  end
end

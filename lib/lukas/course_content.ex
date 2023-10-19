defmodule Lukas.Learning.Course.Content do
  alias Lukas.Learning.{Course, Lesson, Query}
  alias Lukas.Accounts
  alias Lukas.Repo

  alias Ecto.Multi

  def topic_kinds() do
    %{
      "text" => "text"
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

  def get_lesson_and_topic_names(course_id, lesson_id) do
    Ecto.Multi.new()
    |> Ecto.Multi.one(:lesson, Query.lesson_by_course_id_and_id(course_id, lesson_id))
    |> Ecto.Multi.all(:topics, Query.topics_for_lesson_with_no_content(course_id, lesson_id))
    |> Repo.transaction()
    |> case do
      {:ok, %{lesson: lesson, topics: topics}} -> {lesson, topics}
    end
  end

  def create_lesson(%Course{} = course, attrs \\ %{}) do
    attrs_with_course = Map.merge(attrs, %{"course_id" => course.id})

    %Lesson{}
    |> Lesson.changeset(attrs_with_course)
    |> Repo.insert()
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

  def update_lesson(%Lesson{} = lesson, attrs \\ %{}) do
    lesson
    |> Lesson.changeset(attrs)
    |> Repo.update()
    |> maybe_emit_lesson_updated()
  end

  def remove_lesson(id) when is_integer(id) do
    Repo.get(Lesson, id) |> remove_lesson()
  end

  def remove_lesson(%Lesson{} = lesson) do
    Repo.delete(lesson)
    |> maybe_emit_lesson_deleted()
  end

  def create_text_topic(%Lesson{id: lesson_id} = lesson, attrs) do
    %Lesson.Topic{lesson_id: lesson_id, kind: :text}
    |> Lesson.Topic.changeset(attrs)
    |> Repo.insert()
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

  def update_topic(%Lesson.Topic{} = topic, attrs) do
    topic_with_lesson = Repo.preload(topic, :lesson)

    topic_with_lesson
    |> Lesson.Topic.update_changeset(attrs)
    |> Repo.update()
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

defmodule Lukas.Learning do
  ## NOTE: MODULE IS IN DIRE NEED OF REFACTORING
  ## TOO MUCH DUPLICATION + LOW PERF CODE PROBABLY
  ## HELLA BUGGY TOO

  import Ecto.Query, warn: false

  alias Lukas.Repo
  alias Lukas.Accounts
  alias Lukas.Categories.Tag
  alias Lukas.Learning.{Enrollment, Course, Lesson, Tagging, Teaching}

  def list_courses(opts \\ []), do: Course.query_all_with_tags(opts) |> Repo.all()

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

  def get_course(id), do: Repo.get(Course, id)

  def get_course_with_students(id) when is_integer(id) do
    Ecto.Multi.new()
    |> Ecto.Multi.one(:course, from(c in Course, where: c.id == ^id))
    |> Ecto.Multi.all(
      :students,
      from(
        enr in Enrollment,
        join: u in Accounts.User,
        on: u.id == enr.student_id,
        where: enr.course_id == ^id,
        select: u
      )
    )
    |> Repo.transaction()
    |> case do
      {:ok, %{course: course, students: students}} -> {course, students}
    end
  end

  def get_course_for_student(id, %Accounts.User{} = student) when is_integer(id) do
    Ecto.Multi.new()
    |> Ecto.Multi.one(:course, from(c in Course, where: c.id == ^id))
    |> Ecto.Multi.all(
      :lecturers,
      from(
        t in Teaching,
        join: u in Accounts.User,
        on: u.id == t.lecturer_id and u.kind == :lecturer,
        where: t.course_id == ^id,
        select: u
      )
    )
    |> Ecto.Multi.all(
      :tags,
      from(
        t in Tagging,
        join: tag in Tag,
        on: t.tag_id == tag.id,
        where: t.course_id == ^id,
        select: tag
      )
    )
    |> Ecto.Multi.exists?(
      :is_enrolled,
      from(
        e in Enrollment,
        where: e.student_id == ^student.id and e.course_id == ^id
      )
    )
    |> Repo.transaction()
    |> case do
      {:ok,
       %{
         course: course,
         lecturers: lecturers,
         tags: tags,
         is_enrolled: is_enrolled
       }} ->
        {course, lecturers, tags, is_enrolled}
    end
  end

  def get_lessons(%Course{id: course_id}),
    do: from(l in Lesson, where: l.course_id == ^course_id) |> Repo.all()

  def create_course(attrs) do
    %Course{}
    |> Course.changeset(attrs)
    |> Repo.insert()
    |> maybe_emit_course_created()
  end

  def create_course(attrs, tag_ids) do
    Ecto.Multi.new()
    |> create_course_multi(attrs, tag_ids, &Course.default_banner_image/0)
    |> Repo.transaction()
    |> case do
      {:ok, %{course: course}} ->
        :ok
        emit("courses", {:courses, :course_created, course})
        {:ok, course}

      {:error, :course, cs, _} ->
        {:error, cs}
    end
  end

  def create_course_by_lecturer(attrs, tag_ids, lecturer, opts \\ []) do
    side_effect = Keyword.get(opts, :side_effect, fn -> nil end)
    get_banner_image_path = Keyword.get(opts, :banner_image, &Course.default_banner_image/0)

    Ecto.Multi.new()
    |> create_course_multi(attrs, tag_ids, get_banner_image_path)
    |> Ecto.Multi.run(:teachings, fn _, %{course: course} ->
      Teaching.changeset(%Teaching{}, %{course_id: course.id, lecturer_id: lecturer.id})
      |> Repo.insert!()

      {:ok, nil}
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{course: course}} ->
        :ok
        side_effect.(course)
        emit("courses", {:courses, :course_created, course})
        {:ok, course}

      {:error, :course, cs, _} ->
        {:error, cs}
    end
  end

  def create_course_multi(
        m,
        attrs,
        tag_ids,
        get_banner_image_path
      ) do
    m
    |> Ecto.Multi.insert(
      :course,
      Course.changeset(%Course{banner_image: get_banner_image_path.()}, attrs)
    )
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

  def watch_courses(), do: watch("courses")

  def watch_course(course_id) when is_integer(course_id) do
    course = Repo.get(Course, course_id)
    watch_course(course)
  end

  def watch_course(%Course{id: id}), do: watch("courses/#{id}")

  def maybe_emit_course_created({:ok, course} = res) do
    emit("courses", {:courses, :course_created, course})
    res
  end

  def maybe_emit_course_created(res), do: res

  def maybe_emit_course_updated({:ok, course} = res) do
    emit("courses", {:courses, :course_updated, course})

    emit(
      "courses/#{course.id}",
      {:course, course.id, :course_updated, course}
    )

    res
  end

  def maybe_emit_course_updated(res), do: res

  def maybe_emit_course_tagged({:ok, tagging} = res) do
    tag = Repo.get!(Tag, tagging.tag_id)

    emit(
      "courses/#{tagging.course_id}",
      {:course, tagging.course_id, :course_tagged, tag}
    )

    res
  end

  def maybe_emit_course_tagged(res), do: res

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

  def emit_course_untagged(course_id, tag_id) do
    tag = Repo.get!(Tag, tag_id)

    emit(
      "courses/#{course_id}",
      {:course, course_id, :course_untagged, tag}
    )
  end

  defp emit(topic, message) do
    Phoenix.PubSub.broadcast(Lukas.PubSub, topic, message)
  end

  defp watch(topic) do
    Phoenix.PubSub.subscribe(Lukas.PubSub, topic)
  end
end

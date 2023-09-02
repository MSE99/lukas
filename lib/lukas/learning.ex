defmodule Lukas.Learning do
  import Ecto.Query, warn: false
  import Lukas.Accounts.User, only: [must_be_lecturer: 1, must_be_student: 1]

  alias Lukas.Repo
  alias Lukas.Accounts
  alias Lukas.Learning.{Enrollment, Course}

  ## Enrollments
  def list_student_courses(%Accounts.User{} = user) do
    from(
      c in Course,
      join: e in Enrollment,
      on: c.id == e.course_id,
      where: e.student_id == ^user.id
    )
    |> Repo.all()
  end

  def list_open_courses_for_student(%Accounts.User{} = student) do
    Ecto.Multi.new()
    |> Ecto.Multi.all(
      :enrolled_ids,
      from(
        c in Course,
        join: e in Enrollment,
        on: c.id == e.course_id,
        where: e.student_id == ^student.id,
        select: c.id
      )
    )
    |> Ecto.Multi.run(:courses, fn _repo, %{enrolled_ids: enrolled_ids} ->
      {:ok, from(c in Course, where: c.id not in ^enrolled_ids) |> Repo.all()}
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{courses: courses}} -> courses
    end
  end

  def list_enrolled() do
    from(e in Enrollment, join: u in Accounts.User, on: e.student_id == u.id, select: u)
    |> Repo.all()
  end

  def enroll_student(%Course{} = course, %Accounts.User{} = student)
      when must_be_student(student) do
    Enrollment.changeset(%Enrollment{}, %{course_id: course.id, student_id: student.id})
    |> Repo.insert()
    |> maybe_emit_student_enrolled(student, course)
  end

  def maybe_emit_student_enrolled({:ok, enrollment} = res, student, course) do
    Phoenix.PubSub.broadcast(
      Lukas.PubSub,
      "courses/#{enrollment.course_id}",
      {:course, enrollment.course_id, :student_enrolled, student}
    )

    Phoenix.PubSub.broadcast(
      Lukas.PubSub,
      "enrollments/#{enrollment.student_id}",
      {:enrollments, :enrolled, course}
    )

    res
  end

  def maybe_emit_student_enrolled(res, _, _), do: res

  def watch_student_enrollments(%Accounts.User{} = user) do
    Phoenix.PubSub.subscribe(Lukas.PubSub, "enrollments/#{user.id}")
  end

  ## Courses
  alias Lukas.Learning.{Course, Lesson, Tagging, Tag, Teaching}

  def possible_lecturers_for(%Course{} = course) do
    {:ok, lecturers} =
      Repo.transaction(fn ->
        lecturers = list_course_lecturers(course) |> Enum.map(fn lect -> lect.id end)

        possible_lecturers =
          from(u in Accounts.User, where: u.kind == :lecturer and u.id not in ^lecturers)
          |> Repo.all()

        possible_lecturers
      end)

    lecturers
  end

  def list_course_lecturers(%Course{} = course) do
    from(
      l in Teaching,
      join: u in Accounts.User,
      on: l.lecturer_id == u.id,
      where: l.course_id == ^course.id,
      select: u
    )
    |> Repo.all()
  end

  def add_lecturer_to_course(%Course{} = course, lecturer) when must_be_lecturer(lecturer) do
    Teaching.changeset(%Teaching{}, %{course_id: course.id, lecturer_id: lecturer.id})
    |> Repo.insert()
    |> maybe_emit_lecturer_added_to_course(lecturer)
  end

  def remove_lecturer_from_course(%Course{} = course, lecturer) do
    lecturer_id = lecturer.id
    course_id = course.id

    from(t in Teaching, where: t.lecturer_id == ^lecturer_id and t.course_id == ^course_id)
    |> Repo.one()
    |> Repo.delete()
    |> maybe_emit_lecturer_removed_from_course(lecturer)
  end

  defp maybe_emit_lecturer_removed_from_course({:ok, teaching} = res, lecturer) do
    Phoenix.PubSub.broadcast(
      Lukas.PubSub,
      "courses/#{teaching.course_id}",
      {:course, teaching.course_id, :lecturer_removed, lecturer}
    )

    res
  end

  defp maybe_emit_lecturer_removed_from_course(res, _), do: res

  defp maybe_emit_lecturer_added_to_course({:ok, teaching} = res, lecturer) do
    Phoenix.PubSub.broadcast(
      Lukas.PubSub,
      "courses/#{teaching.course_id}",
      {:course, teaching.course_id, :lecturer_added, lecturer}
    )

    res
  end

  defp maybe_emit_lecturer_added_to_course(res, _), do: res

  def topic_kinds() do
    %{
      "text" => "text"
    }
  end

  def get_lesson(course_id, lesson_id) when is_integer(course_id) and is_integer(lesson_id) do
    from(l in Lesson, where: l.course_id == ^course_id and l.id == ^lesson_id) |> Repo.one()
  end

  def get_lesson_and_topic_names(course_id, lesson_id) do
    Ecto.Multi.new()
    |> Ecto.Multi.one(
      :lesson,
      from(l in Lesson, where: l.course_id == ^course_id and l.id == ^lesson_id)
    )
    |> Ecto.Multi.all(
      :topics,
      from(
        t in Lesson.Topic,
        where: t.lesson_id == ^lesson_id,
        select: %{id: t.id, title: t.title, kind: t.kind}
      )
    )
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

  def get_topic(lesson_id, topic_id) when is_integer(lesson_id) and is_integer(topic_id) do
    from(t in Lesson.Topic, where: t.lesson_id == ^lesson_id and t.id == ^topic_id) |> Repo.one()
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
      :enrollment,
      from(
        e in Enrollment,
        where: e.student_id == ^student.id and e.course_id == ^id,
        select: true
      )
    )
    |> Repo.transaction()
    |> case do
      {:ok, %{course: course, lecturers: lecturers, tags: tags}} ->
        {course, lecturers, tags}
    end
  end

  def get_course_with_lecturers(id) when is_integer(id) do
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
    |> Repo.transaction()
    |> case do
      {:ok, %{course: course, lecturers: lecturers}} -> {course, lecturers}
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

  def watch_course(course_id) when is_integer(course_id) do
    course = Repo.get(Course, course_id)
    watch_course(course)
  end

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
      {:course, course.id, :course_updated, course}
    )

    res
  end

  def maybe_emit_course_updated(res), do: res

  def maybe_emit_course_tagged({:ok, tagging} = res) do
    tag = Repo.get!(Tag, tagging.tag_id)

    Phoenix.PubSub.broadcast(
      Lukas.PubSub,
      "courses/#{tagging.course_id}",
      {:course, tagging.course_id, :course_tagged, tag}
    )

    res
  end

  def maybe_emit_course_tagged(res), do: res

  def maybe_emit_lesson_added({:ok, lesson} = res) do
    Phoenix.PubSub.broadcast(
      Lukas.PubSub,
      "courses/#{lesson.course_id}",
      {:course, lesson.course_id, :lesson_added, lesson}
    )

    res
  end

  def maybe_emit_lesson_added(res), do: res

  def maybe_emit_lesson_updated({:ok, lesson} = res) do
    Phoenix.PubSub.broadcast(
      Lukas.PubSub,
      "courses/#{lesson.course_id}",
      {:course, lesson.course_id, :lesson_updated, lesson}
    )

    res
  end

  def maybe_emit_lesson_updated(res), do: res

  def maybe_emit_lesson_deleted({:ok, lesson} = res) do
    Phoenix.PubSub.broadcast(
      Lukas.PubSub,
      "courses/#{lesson.course_id}",
      {:course, lesson.course_id, :lesson_deleted, lesson}
    )

    res
  end

  def maybe_emit_lesson_deleted(res), do: res

  def maybe_emit_topic_added({:ok, topic} = res, lesson) do
    Phoenix.PubSub.broadcast(
      Lukas.PubSub,
      "courses/#{lesson.course_id}",
      {:course, lesson.course_id, :topic_added, topic}
    )

    res
  end

  def maybe_emit_topic_added(res, _), do: res

  def maybe_emit_topic_removed({:ok, topic} = res, lesson) do
    Phoenix.PubSub.broadcast(
      Lukas.PubSub,
      "courses/#{lesson.course_id}",
      {:course, lesson.course_id, :topic_removed, topic}
    )

    res
  end

  def maybe_emit_topic_removed(res, _), do: res

  def maybe_emit_topic_updated({:ok, topic} = res, lesson) do
    Phoenix.PubSub.broadcast(
      Lukas.PubSub,
      "courses/#{lesson.course_id}",
      {:course, lesson.course_id, :topic_updated, topic}
    )

    res
  end

  def maybe_emit_topic_updated(res, _), do: res

  def emit_course_untagged(course_id, tag_id) do
    tag = Repo.get!(Tag, tag_id)

    Phoenix.PubSub.broadcast(
      Lukas.PubSub,
      "courses/#{course_id}",
      {:course, course_id, :course_untagged, tag}
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

defmodule Lukas.Learning.Query do
  import Ecto.Query

  alias Lukas.Learning.{Course, Tagging, Teaching, Enrollment, Lesson, Progress}
  alias Lukas.Categories.Tag

  alias Lukas.Accounts

  def courses_count() do
    from(c in Course, select: count(c.id))
  end

  def courses_with_taggings(opts \\ []) do
    limit = Keyword.get(opts, :limit, 50)
    offset = Keyword.get(opts, :offset, 0)
    order_by = Keyword.get(opts, :order_by, desc: :inserted_at)
    name = Keyword.get(opts, :name, "")
    tag_ids = Keyword.get(opts, :tags, [])
    excluded = Keyword.get(opts, :excluded, [])
    free = Keyword.get(opts, :free, false)

    like_clause = "%" <> name <> "%"

    case tag_ids do
      [] ->
        q =
          if free do
            from(
              c in Course,
              limit: ^limit,
              offset: ^offset,
              preload: [:tags],
              order_by: ^order_by,
              where: c.id not in ^excluded and c.price == 0.0
            )
          else
            from(
              c in Course,
              limit: ^limit,
              offset: ^offset,
              preload: [:tags],
              order_by: ^order_by,
              where: c.id not in ^excluded and c.price >= 0.0
            )
          end

        if name == "" do
          q
        else
          where(q, [c], like(c.name, ^like_clause))
        end

      _ ->
        q =
          if free do
            from(
              c in Course,
              join: t in Tagging,
              on: t.course_id == c.id,
              where: t.tag_id in ^tag_ids and c.id not in ^excluded and c.price == 0.0,
              group_by: c.id,
              limit: ^limit,
              offset: ^offset,
              order_by: ^order_by,
              select: c
            )
          else
            from(
              c in Course,
              join: t in Tagging,
              on: t.course_id == c.id,
              where: t.tag_id in ^tag_ids and c.id not in ^excluded,
              group_by: c.id,
              limit: ^limit,
              offset: ^offset,
              order_by: ^order_by,
              select: c
            )
          end

        if name == "" do
          q
        else
          where(q, [c], like(c.name, ^like_clause))
        end
    end
  end

  def course_by_id(course_id) do
    from(c in Course, where: c.id == ^course_id)
  end

  def course_for_lecturer(course_id, lecturer_id) do
    from(
      c in Course,
      join: t in Teaching,
      on: t.course_id == c.id,
      where: t.lecturer_id == ^lecturer_id and c.id == ^course_id,
      select: c
    )
  end

  def course_tags(course_id) do
    from(
      tagging in Tagging,
      join: tag in Tag,
      on: tag.id == tagging.tag_id,
      where: tagging.course_id == ^course_id,
      select: tag
    )
  end

  def course_tagging(course_id, tag_id) do
    from(
      tagging in Tagging,
      where: tagging.course_id == ^course_id and tagging.tag_id == ^tag_id
    )
  end

  def course_taggings(course_id) do
    from(
      tagging in Tagging,
      where: tagging.course_id == ^course_id
    )
  end

  def lecturer_courses(lecturer_id) do
    from(
      c in Course,
      join: t in Teaching,
      on: t.course_id == c.id,
      where: t.lecturer_id == ^lecturer_id,
      select: c
    )
  end

  def enrolled_students(course_id, opts \\ []) do
    limit = Keyword.get(opts, :limit, 50)
    offset = Keyword.get(opts, :offset, 0)

    from(
      enr in Enrollment,
      join: u in Lukas.Accounts.User,
      on: enr.student_id == u.id,
      where: enr.course_id == ^course_id,
      select: u,
      limit: ^limit,
      offset: ^offset
    )
  end

  def student_enrollment(course_id, student_id) do
    from(
      e in Enrollment,
      where: e.student_id == ^student_id and e.course_id == ^course_id
    )
  end

  def course_lecturers(course_id) do
    from(
      t in Teaching,
      join: u in Accounts.User,
      on: u.id == t.lecturer_id and u.kind == :lecturer,
      where: t.course_id == ^course_id,
      select: u
    )
  end

  def course_lecturers_ids(course_id) do
    from(
      t in Teaching,
      join: u in Accounts.User,
      on: u.id == t.lecturer_id and u.kind == :lecturer,
      where: t.course_id == ^course_id,
      select: u.id
    )
  end

  def teaching_by_lecturer_and_course_ids(course_id, lecturer_id) do
    from(
      t in Teaching,
      where: t.course_id == ^course_id and t.lecturer_id == ^lecturer_id
    )
  end

  def course_lessons(course_id) do
    from(l in Lesson, where: l.course_id == ^course_id)
  end

  def lesson_by_course_id_and_id(course_id, lesson_id) do
    from(l in Lesson, where: l.course_id == ^course_id and l.id == ^lesson_id)
  end

  def lesson_progress(course_id, lesson_id, student_id) do
    from(
      prog in Progress,
      where:
        prog.lesson_id == ^lesson_id and prog.student_id == ^student_id and
          prog.course_id == ^course_id and is_nil(prog.topic_id)
    )
  end

  def topic_by_ids(course_id, lesson_id, topic_id) do
    from(
      t in Lesson.Topic,
      join: l in Lesson,
      on: t.lesson_id == ^lesson_id,
      where: t.id == ^topic_id and l.course_id == ^course_id and l.id == ^lesson_id
    )
  end

  def topics_for_lesson_with_no_content(course_id, lesson_id) do
    from(
      t in Lesson.Topic,
      join: l in Lesson,
      on: t.lesson_id == ^lesson_id,
      where: l.course_id == ^course_id and l.id == ^lesson_id,
      select: %{
        id: t.id,
        title: t.title,
        kind: t.kind,
        inserted_at: t.inserted_at,
        lesson_id: t.lesson_id
      }
    )
  end

  def topics_for_lesson_with_no_content(lesson_id) do
    from(
      t in Lesson.Topic,
      join: l in Lesson,
      on: t.lesson_id == ^lesson_id,
      where: l.id == ^lesson_id,
      select: %{
        id: t.id,
        title: t.title,
        kind: t.kind,
        inserted_at: t.inserted_at,
        lesson_id: t.lesson_id
      }
    )
  end

  def topic_by_lesson_id_and_id(lesson_id, topic_id) do
    from(
      t in Lesson.Topic,
      where: t.id == ^topic_id and t.lesson_id == ^lesson_id
    )
  end

  def topic_progress(course_id, lesson_id, topic_id, student_id) do
    from(
      prog in Progress,
      where:
        prog.lesson_id == ^lesson_id and prog.student_id == ^student_id and
          prog.course_id == ^course_id and prog.topic_id == ^topic_id
    )
  end

  def student_courses(student_id) do
    from(
      c in Course,
      join: enr in Enrollment,
      on: c.id == enr.course_id,
      where: enr.student_id == ^student_id,
      select: c
    )
  end

  def student_course_ids(student_id) do
    from(
      c in Course,
      join: enr in Enrollment,
      on: c.id == enr.course_id,
      where: enr.student_id == ^student_id,
      select: c.id
    )
  end

  def course_whose_id_not_in(not_wanted, opts \\ []) do
    limit = Keyword.get(opts, :limit, 50)
    offset = Keyword.get(opts, :offset, 0)

    from(c in Course, where: c.id not in ^not_wanted, limit: ^limit, offset: ^offset)
  end

  def progress_by_course_and_student_id(course_id, student_id) do
    from(
      prog in Progress,
      where: prog.student_id == ^student_id and prog.course_id == ^course_id
    )
  end

  def count_lessons(course_id) do
    from(
      l in Lesson,
      where: l.course_id == ^course_id,
      select: count(l.id)
    )
  end

  def count_topics(course_id) do
    from(
      t in Lesson.Topic,
      join: l in Lesson,
      on: l.id == t.lesson_id,
      where: l.course_id == ^course_id,
      select: count(t.id)
    )
  end

  def count_finished_lessons(course_id, student_id) do
    from(
      l in Lesson,
      where: l.course_id == ^course_id,
      join: p in Progress,
      on: p.lesson_id == l.id and p.student_id == ^student_id,
      where: is_nil(p.topic_id),
      select: count(l.id)
    )
  end

  def count_finished_topics(course_id, student_id) do
    from(
      t in Lesson.Topic,
      join: l in Lesson,
      on: l.id == t.lesson_id,
      join: p in Progress,
      on: p.lesson_id == l.id and p.student_id == ^student_id,
      where: p.lesson_id == l.id and p.topic_id == t.id and l.course_id == ^course_id,
      select: count(t.id)
    )
  end
end

defmodule Lukas.Learning.Course.Students do
  import Lukas.Accounts.User, only: [must_be_student: 1]

  alias Lukas.Money
  alias Lukas.Accounts
  alias Lukas.Learning.{Enrollment, Course, Lesson, Progress}
  alias Lukas.Repo

  alias Ecto.Multi

  def list_student_courses(%Accounts.User{} = student) do
    Course.query_student_courses(student.id) |> Repo.all()
  end

  def list_open_courses_for_student(%Accounts.User{} = student, opts \\ []) do
    Ecto.Multi.new()
    |> Ecto.Multi.all(
      :enrolled_ids,
      Course.query_student_courses_for_course_ids(student.id)
    )
    |> Ecto.Multi.run(:courses, fn _repo, %{enrolled_ids: enrolled_ids} ->
      {:ok, Course.query_course_not_in(enrolled_ids, opts) |> Repo.all()}
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{courses: courses}} -> courses
    end
  end

  def list_enrolled(course_id) do
    Enrollment.query_enrolled_students(course_id) |> Repo.all()
  end

  def enroll_student(%Course{} = course, student) when must_be_student(student) do
    Multi.new()
    |> Multi.insert(:enrollment, Enrollment.new(course.id, student.id))
    |> Money.purchase_course_for(student, course)
    |> case do
      {:ok, %{enrollment: enr}} -> emit_student_enrolled(enr, student, course)
    end
  end

  def emit_student_enrolled(enrollment, student, course) do
    emit(
      course_topic(enrollment.course_id),
      {:course, enrollment.course_id, :student_enrolled, student}
    )

    emit(enrollments_topic(student), {:enrollments, :enrolled, course})

    {:ok, enrollment}
  end

  def watch_student_enrollments(%Accounts.User{} = user), do: enrollments_topic(user) |> watch()

  def progress_through_lesson(%Accounts.User{} = student, %{} = lesson) do
    Progress.new_lesson_progress(student.id, lesson.course_id, lesson.id) |> Repo.insert!()
    emit_progress_update(student, lesson.course_id)
    nil
  end

  ## TODO: Needs refactoring, performs one read and write
  ## sequentially, both should be done inside a tx.
  def progress_through_topic(%Accounts.User{} = student, %{} = topic) do
    lesson = Repo.get!(Lesson, topic.lesson_id)

    Progress.new_topic_progress(student.id, lesson.course_id, lesson.id, topic.id)
    |> Repo.insert!()

    emit_progress_update(student, lesson.course_id)

    nil
  end

  defp emit_progress_update(student, course_id) do
    prog = Course.Students.get_progress(student, course_id)

    emit(
      progress_topic(student.id, course_id),
      {:progress, course_id, prog}
    )
  end

  ## TODO: needs refactoring :3
  def get_next_lesson_or_topic(lessons) do
    Enum.reduce(lessons, :course_home, fn
      lesson, acc ->
        if acc != :course_home do
          acc
        else
          if !lesson.progressed do
            {:lesson, lesson}
          else
            topic = Enum.find(lesson.topics, fn t -> t.progressed == false end)

            if topic != nil do
              {:topic, topic}
            else
              acc
            end
          end
        end
    end)
  end

  def watch_progress(student, course_id), do: progress_topic(student.id, course_id) |> watch()

  def get_progress(%Accounts.User{} = student, course_id) when must_be_student(student) do
    Multi.new()
    |> multi_course_by_id(course_id)
    |> multi_enrollment_for_student_in_course(student, course_id)
    |> multi_course_progress_for_student(student, course_id)
    |> multi_load_lessons_with_patched_progress()
    |> Repo.transaction()
    |> case do
      {:ok, %{course: course, lessons: lessons}} ->
        {course, lessons}
    end
  end

  defp multi_load_lessons_with_patched_progress(m) do
    Multi.run(m, :lessons, fn _, %{enrollment: enr, progresses: progs} when enr != nil ->
      {:ok, load_lessons_with_patched_progress_and_topics(enr.course_id, progs)}
    end)
  end

  defp multi_course_progress_for_student(m, student, course_id) do
    Multi.all(
      m,
      :progresses,
      Progress.query_by_student_and_course_ids(student.id, course_id)
    )
  end

  defp multi_enrollment_for_student_in_course(m, student, course_id) do
    Multi.one(
      m,
      :enrollment,
      Enrollment.query_by_student_and_course_ids(student.id, course_id)
    )
  end

  defp multi_course_by_id(m, course_id) do
    Multi.one(m, :course, Course.query_by_id(course_id))
  end

  defp load_lessons_with_patched_progress_and_topics(course_id, progs) do
    course_id
    |> Lesson.query_by_course_id()
    |> Repo.all()
    |> Enum.map(fn l -> patch_progress_into_lesson(l, progs) end)
  end

  defp patch_progress_into_lesson(%Lesson{} = l, progs) do
    topics = load_topics_without_content_with_progress_for(l, progs)

    l
    |> Map.from_struct()
    |> Map.put(:topics, topics)
    |> Map.put(
      :progressed,
      Enum.find(progs, fn prog -> prog.lesson_id == l.id and prog.topic_id == nil end) !=
        nil
    )
  end

  defp load_topics_without_content_with_progress_for(%Lesson{} = l, progs) do
    l.id
    |> Lesson.Topic.query_by_lesson_id_with_no_content()
    |> Repo.all()
    |> Enum.map(fn t ->
      progress_for_topic =
        Enum.find(progs, fn prog -> prog.topic_id == t.id and prog.lesson_id == l.id end)

      Map.put(
        t,
        :progressed,
        progress_for_topic != nil
      )
    end)
  end

  defp watch(topic) do
    Phoenix.PubSub.subscribe(Lukas.PubSub, topic)
  end

  defp emit(topic, message) do
    Phoenix.PubSub.broadcast(Lukas.PubSub, topic, message)
  end

  defp progress_topic(student_id, course_id), do: "progress/courses/#{course_id}/#{student_id}"

  defp enrollments_topic(%Accounts.User{id: student_id}), do: "student/#{student_id}/enrollments"
  defp enrollments_topic(student_id), do: "student/#{student_id}/enrollments"
  defp course_topic(course_id), do: "courses/#{course_id}"
end

defmodule Lukas.Learning.Course.Staff do
  import Lukas.Accounts.User, only: [must_be_lecturer: 1]

  alias Lukas.Learning.{Course, Teaching, Query}
  alias Lukas.Accounts
  alias Lukas.Repo

  alias Ecto.Multi

  def emit_course_created_by_lecturer(course, lecturer) do
    emit(staff_status_topic(lecturer.id), {:staff_status, :added_to_course, course})
  end

  def list_lecturer_courses(lecturer_id) when is_integer(lecturer_id) do
    lecturer_id
    |> Query.lecturer_courses()
    |> Repo.all()
  end

  def watch_staff_status(staff_id) do
    staff_id
    |> staff_status_topic()
    |> watch()
  end

  def staff_status_topic(staff_id), do: "staff-status/#{staff_id}"

  def get_course_with_lecturers(id) when is_integer(id) do
    Multi.new()
    |> Multi.one(:course, Query.course_by_id(id))
    |> Multi.all(:lecturers, Query.course_lecturers(id))
    |> Multi.all(:tags, Query.course_tags(id))
    |> Repo.transaction()
    |> case do
      {:ok, %{course: course, lecturers: lecturers, tags: tags}} ->
        {course, lecturers, tags}
    end
  end

  def possible_lecturers_for(%Course{} = course, opts \\ []) do
    opts_with_kind = Keyword.put(opts, :kind, :lecturer)

    {:ok, lecturers} =
      Repo.transaction(fn ->
        course
        |> list_course_lecturers_ids()
        |> Accounts.User.query_whose_id_not_in(opts_with_kind)
        |> Repo.all()
      end)

    lecturers
  end

  def list_course_lecturers_ids(%Course{} = course) do
    Query.course_lecturers_ids(course.id) |> Repo.all()
  end

  def list_course_lecturers(%Course{} = course) do
    Query.course_lecturers(course.id) |> Repo.all()
  end

  def add_lecturer_to_course(%Course{} = course, lecturer) when must_be_lecturer(lecturer) do
    Teaching.changeset(%Teaching{}, %{course_id: course.id, lecturer_id: lecturer.id})
    |> Repo.insert()
    |> maybe_emit_lecturer_added_to_course(lecturer, course)
  end

  defp maybe_emit_lecturer_added_to_course({:ok, teaching} = res, lecturer, course) do
    emit(
      course_topic(teaching.course_id),
      {:course, teaching.course_id, :lecturer_added, lecturer}
    )

    emit(
      staff_status_topic(lecturer.id),
      {:staff_status, :added_to_course, course}
    )

    res
  end

  defp maybe_emit_lecturer_added_to_course(res, _, _), do: res

  def remove_lecturer_from_course(%Course{} = course, lecturer) do
    lecturer_id = lecturer.id
    course_id = course.id

    Multi.new()
    |> Multi.one(:teaching, Query.teaching_by_lecturer_and_course_ids(course_id, lecturer_id))
    |> Multi.run(:deletion, fn _, %{teaching: t} -> {:ok, Repo.delete(t)} end)
    |> Repo.transaction()
    |> case do
      {:ok, %{teaching: teaching}} ->
        {:ok, teaching}

      {:error, _, _, _} ->
        {:error, :failed_to_delete}
    end
    |> maybe_emit_lecturer_removed_from_course(lecturer, course)
  end

  defp maybe_emit_lecturer_removed_from_course({:ok, teaching} = res, lecturer, course) do
    emit(
      course_topic(teaching.course_id),
      {:course, teaching.course_id, :lecturer_removed, lecturer}
    )

    emit(
      staff_status_topic(lecturer.id),
      {:staff_status, :removed_from_course, course}
    )

    res
  end

  defp maybe_emit_lecturer_removed_from_course(res, _, _), do: res

  defp emit(topic, message) do
    Phoenix.PubSub.broadcast(Lukas.PubSub, topic, message)
  end

  defp watch(topic), do: Phoenix.PubSub.subscribe(Lukas.PubSub, topic)

  defp course_topic(course_id), do: "courses/#{course_id}"
end

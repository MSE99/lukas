defmodule Lukas.LearningTest do
  use Lukas.DataCase, async: true

  alias Lukas.Learning
  alias Lukas.Learning.Course.{Content, Students}

  import Lukas.LearningFixtures
  import Lukas.AccountsFixtures
  import Lukas.MoneyFixtures

  describe "courses" do
    setup do
      %{tag: tag_fixture()}
    end

    test "should create a new course and dispatch an event.", %{tag: tag} do
      Learning.watch_courses()

      {:ok, course} =
        Learning.create_course(%{"name" => "Japanese basic", "price" => 50.0}, [tag.id])

      assert course.name == "Japanese basic"
      assert course.price == 50.0

      assert_received({:courses, :course_created, ^course})
    end

    test "tag_course/2 should add the tag to the course with the given id and update the course.",
         %{tag: tag} do
      {:ok, course} = Learning.create_course(%{"name" => "Japanese basic", "price" => 500}, [])
      Learning.tag_course(course.id, tag.id)

      assert Learning.get_course_and_tags(course.id) == {course, [tag]}
    end

    test "untag_course/2 should remove the tag to the course with the given id and update the course.",
         %{tag: tag} do
      {:ok, course} =
        Learning.create_course(%{"name" => "Japanese basic", "price" => 500}, [tag.id])

      Learning.untag_course(course.id, tag.id)
      assert Learning.get_course_and_tags(course.id) == {course, []}
    end

    test "update_course/2 should update the course." do
      {:ok, course} = Learning.create_course(%{"name" => "Japanese basic", "price" => 50}, [])

      {:ok, next_course} =
        Learning.update_course(course, %{"name" => "Japanese advanced", "price" => 500.0})

      assert next_course.name =~ "Japanese advanced"
      assert next_course.price == 500.0
    end

    test "watch_course/1 should allow us to watch a course for any updates.", %{tag: tag} do
      cr = course_fixture()
      Learning.watch_course(cr)

      {:ok, updated} = Learning.update_course(cr, %{"name" => "Japanese advanced"})
      assert_received({:course, _, :course_updated, ^updated})

      Learning.tag_course(cr.id, tag.id)
      assert_received({:course, _, :course_tagged, ^tag})

      Learning.untag_course(cr.id, tag.id)
      assert_received({:course, _, :course_untagged, ^tag})
    end

    test "count_courses/1 should return a count of all the courses in the system." do
      assert Learning.count_courses() == 0

      1..100
      |> Enum.each(fn _ -> course_fixture() end)

      assert Learning.count_courses() == 100
    end
  end

  describe "courses lessons" do
    setup do
      %{course: course_fixture()}
    end

    test "create_lesson/2 should create a new lesson and dispatch an event.", %{course: course} do
      Learning.watch_course(course)

      {:ok, lesson} =
        Content.create_lesson(course, %{"title" => "Lesson 1", "description" => "Mathematics I"})

      assert_received({:course, _, :lesson_added, ^lesson})
    end

    test "update_lesson/2 should update a lesson and dispatch an event.", %{course: course} do
      Learning.watch_course(course)

      {:ok, lesson} =
        Content.create_lesson(course, %{"title" => "Lesson 1", "description" => "Mathematics I"})

      assert_received({:course, _, :lesson_added, ^lesson})

      {:ok, next_lesson} =
        Content.update_lesson(lesson, %{"title" => "Lesson 2", "description" => "Mathematics I"})

      assert_received({:course, _, :lesson_updated, ^next_lesson})
    end

    test "remove_lesson/1 should remove a lesson and dispatch a removal event.", %{course: course} do
      Learning.watch_course(course)

      {:ok, lesson} =
        Content.create_lesson(course, %{"title" => "Lesson 1", "description" => "Mathematics I"})

      text_topic_fixture(lesson, %{"content" => "foo is great bar is none", "title" => "FOO"})

      assert_received({:course, _, :lesson_added, ^lesson})

      {:ok, removed_lesson} = Content.remove_lesson(lesson)
      assert_received({:course, _, :lesson_deleted, ^removed_lesson})

      assert Content.get_lesson_and_topic_names(course.id, lesson.id) == {nil, []}
    end
  end

  describe "courses lesson topics" do
    setup do
      course = course_fixture()

      {:ok, lesson} =
        Content.create_lesson(course, %{"title" => "Lesson 1", "description" => "Mathematics I"})

      %{course: course, lesson: lesson}
    end

    test "create_text_topic/2 should add a topic to a given lesson.", %{
      lesson: lesson,
      course: course
    } do
      Learning.watch_course(course)

      {:ok, topic} =
        Content.create_text_topic(lesson, %{
          "title" => "Topic 1",
          "content" => "foo is great bar is none."
        })

      assert topic.lesson_id == lesson.id
      assert topic.title == "Topic 1"
      assert topic.content == "foo is great bar is none."

      assert_receive({:course, _, :topic_added, ^topic})
    end

    test "remove_text_topic/1 should remove a topic.", %{
      lesson: lesson,
      course: course
    } do
      Learning.watch_course(course)

      {:ok, topic} =
        Content.create_text_topic(lesson, %{
          "title" => "Topic 1",
          "content" => "foo is great bar is none."
        })

      assert_receive({:course, _, :topic_added, ^topic})

      {:ok, removed_topic} = Content.remove_topic(topic)

      assert_receive({:course, _, :topic_removed, ^removed_topic})
    end

    test "update_topic/1 should update a topic and dispatch an event.", %{
      lesson: lesson,
      course: course
    } do
      Learning.watch_course(course)

      {:ok, topic} =
        Content.create_text_topic(lesson, %{
          "title" => "Topic 1",
          "content" => "foo is great bar is none."
        })

      assert_receive({:course, _, :topic_added, ^topic})

      {:ok, updated_topic} =
        Content.update_topic(topic, %{
          "title" => "Topic 2",
          "content" => "foo is great bar is none."
        })

      assert_received({:course, _, :topic_updated, ^updated_topic})
    end
  end

  describe "teaching" do
    setup do
      course = course_fixture()
      lecturer = lecturer_fixture()

      %{course: course, lecturer: lecturer}
    end

    test "list_course_lecturers/1 should return an empty list.", %{course: course} do
      assert Learning.Course.Staff.list_course_lecturers(course) == []
    end

    test "list_course_lecturers/1 should return a list of all lecturers for the given course.", %{
      course: course,
      lecturer: lecturer
    } do
      {:ok, _} = Learning.Course.Staff.add_lecturer_to_course(course, lecturer)
      assert Learning.Course.Staff.list_course_lecturers(course) == [lecturer]
    end

    test "possible_lecturers_for/1 should return list of possible lecturers for course.", %{
      course: course,
      lecturer: lecturer
    } do
      lecturers = Learning.Course.Staff.possible_lecturers_for(course)

      assert Enum.find(lecturers, fn lect -> lect.id == lecturer.id end)
    end
  end

  describe "enrollment" do
    setup do
      course = course_fixture()
      student = student_fixture()

      direct_deposit_fixture(user_fixture(), student, 500_000.0)

      %{student: student, course: course}
    end

    test "enroll_student/2 should enroll a student into a given course and publish an event to the course.",
         %{
           student: student,
           course: course
         } do
      course_id = course.id
      Learning.watch_course(course_id)
      {:ok, enrollment} = Students.enroll_student(course, student)

      assert enrollment.student_id == student.id
      assert enrollment.course_id == course.id

      assert_received({:course, ^course_id, :student_enrolled, ^student})
    end

    test "list_enrolled/0 should list all the enrolled students of the course.", %{course: course} do
      student1 = student_fixture()
      direct_deposit_fixture(user_fixture(), student1, 5000)

      student2 = student_fixture()
      direct_deposit_fixture(user_fixture(), student2, 5000)

      student3 = student_fixture()
      direct_deposit_fixture(user_fixture(), student3, 5000)

      {:ok, _} = Students.enroll_student(course, student1)
      {:ok, _} = Students.enroll_student(course, student2)
      {:ok, _} = Students.enroll_student(course, student3)

      assert Students.list_enrolled(course.id) == [student1, student2, student3]
    end
  end

  def setup_progress_tests(ctx) do
    course = course_fixture()

    lessons =
      [
        lesson_fixture(course),
        lesson_fixture(course),
        lesson_fixture(course),
        lesson_fixture(course)
      ]
      |> Enum.map(fn lesson ->
        topic = text_topic_fixture(lesson)
        Map.from_struct(lesson) |> Map.put(:topics, [topic])
      end)

    student = student_fixture()

    direct_deposit_fixture(user_fixture(), student, 50_000.0)

    Students.enroll_student(course, student)

    Map.merge(ctx, %{course: course, student: student, lessons: lessons})
  end

  describe "progress" do
    setup [:setup_progress_tests]

    test "get_progress/2 should return the progress of a given student.", %{
      student: student,
      course: course
    } do
      {_, lessons} = Students.get_progress(student, course.id)

      Enum.each(
        lessons,
        fn l ->
          refute l.progressed
          Enum.each(l.topics, &refute(&1.progressed))
        end
      )
    end

    test "get_progress/2 should mark a lesson as having been progressed.", %{
      course: course,
      student: student,
      lessons: [lesson | _]
    } do
      Students.progress_through_lesson(student, lesson)

      {_, lessons} = Students.get_progress(student, course.id)

      lesson_from_prog = Enum.at(lessons, 0)

      assert lesson_from_prog.progressed
      first_topic = Enum.at(lesson_from_prog.topics, 0)

      assert {:topic, ^first_topic} = Students.get_next_lesson_or_topic(lessons)
    end

    test "get_progress/2 should mark a topic as having been progressed.", %{
      course: course,
      student: student,
      lessons: [lesson | [next_lesson | _]]
    } do
      Students.progress_through_lesson(student, lesson)
      Students.progress_through_topic(student, Enum.at(lesson.topics, 0))

      {_, lessons} = Students.get_progress(student, course.id)

      lesson_from_prog = Enum.at(lessons, 0)

      assert lesson_from_prog.progressed

      assert Enum.at(lesson_from_prog.topics, 0).progressed

      {:lesson, gotten_next_lesson} = Students.get_next_lesson_or_topic(lessons)

      assert gotten_next_lesson.id == next_lesson.id
    end

    test "get_next_lesson_or_topic/1 should return the next topic.", %{student: student} do
      course = course_fixture()
      {:ok, _} = Students.enroll_student(course, student)

      lesson = lesson_fixture(course)
      first_topic = text_topic_fixture(lesson)
      wanted_next = text_topic_fixture(lesson)

      Students.progress_through_lesson(student, lesson)
      Students.progress_through_topic(student, first_topic)

      {_, lessons} = Students.get_progress(student, course.id)
      {:topic, next_topic} = Students.get_next_lesson_or_topic(lessons)
      assert next_topic.id == wanted_next.id
    end

    test "get_next_lesson_or_topic/1 should return the next lesson after the prev lesson & topics are completed.",
         %{student: student} do
      course = course_fixture()

      first_lesson = lesson_fixture(course)
      second_lesson = lesson_fixture(course)

      first_topic = text_topic_fixture(first_lesson)
      second_topic = text_topic_fixture(first_lesson)

      {:ok, _} = Students.enroll_student(course, student)

      Students.progress_through_lesson(student, first_lesson)
      Students.progress_through_topic(student, first_topic)
      Students.progress_through_topic(student, second_topic)

      {_, lessons} = Students.get_progress(student, course.id)
      {:lesson, next_lesson} = Students.get_next_lesson_or_topic(lessons)
      assert next_lesson.id == second_lesson.id
    end

    test "get_next_lesson_or_topic/1 should return :course_home if there are no lessons.", %{
      student: student
    } do
      course = course_fixture()
      {:ok, _} = Students.enroll_student(course, student)

      {_, lessons} = Students.get_progress(student, course.id)
      assert :course_home == Students.get_next_lesson_or_topic(lessons)
    end

    test "get_next_lesson_or_topic/1 should return :course_home if all lessons are completed.", %{
      student: student
    } do
      course = course_fixture()

      lesson1 = lesson_fixture(course)
      lesson2 = lesson_fixture(course)
      lesson3 = lesson_fixture(course)

      topic1 = text_topic_fixture(lesson1)
      topic2 = text_topic_fixture(lesson2)
      topic3 = text_topic_fixture(lesson3)

      {:ok, _} = Students.enroll_student(course, student)

      Students.progress_through_lesson(student, lesson1)
      Students.progress_through_topic(student, topic1)

      Students.progress_through_lesson(student, lesson2)
      Students.progress_through_topic(student, topic2)

      Students.progress_through_lesson(student, lesson3)
      Students.progress_through_topic(student, topic3)

      {_, lessons} = Students.get_progress(student, course.id)
      assert :course_home == Students.get_next_lesson_or_topic(lessons)
    end

    test "calculate_progress_percentage/1 should return 0.0 when given []." do
      assert Students.calculate_progress_percentage([]) == 0.0
    end

    test "calculate_progress_percentage/1 should return 0.0 when the user has progressed through none of the content.",
         %{student: student} do
      course = course_fixture()

      lesson1 = lesson_fixture(course)
      lesson2 = lesson_fixture(course)
      lesson3 = lesson_fixture(course)

      text_topic_fixture(lesson1)
      text_topic_fixture(lesson2)
      text_topic_fixture(lesson3)

      {:ok, _} = Students.enroll_student(course, student)
      {_, lessons} = Students.get_progress(student, course.id)

      assert Students.calculate_progress_percentage(lessons) == 0.0
    end

    test "calculate_progress_percentage/1 should return %50.0 when the user has progressed through half of the content.",
         %{student: student} do
      course = course_fixture()

      lesson1 = lesson_fixture(course)
      topic1 = text_topic_fixture(lesson1)

      lesson2 = lesson_fixture(course)
      topic2 = text_topic_fixture(lesson2)

      lesson3 = lesson_fixture(course)
      text_topic_fixture(lesson3)

      lesson4 = lesson_fixture(course)
      text_topic_fixture(lesson4)

      {:ok, _} = Students.enroll_student(course, student)

      Students.progress_through_lesson(student, lesson1)
      Students.progress_through_topic(student, topic1)

      Students.progress_through_lesson(student, lesson2)
      Students.progress_through_topic(student, topic2)

      {_, lessons} = Students.get_progress(student, course.id)

      assert Students.calculate_progress_percentage(lessons) == 50.0
    end

    test "calculate_progress_percentage/1 should return %25.0 when the user has progressed through quarter of the content.",
         %{student: student} do
      course = course_fixture()

      lesson1 = lesson_fixture(course)
      topic1 = text_topic_fixture(lesson1)

      lesson2 = lesson_fixture(course)
      text_topic_fixture(lesson2)

      lesson3 = lesson_fixture(course)
      text_topic_fixture(lesson3)

      lesson4 = lesson_fixture(course)
      text_topic_fixture(lesson4)

      {:ok, _} = Students.enroll_student(course, student)

      Students.progress_through_lesson(student, lesson1)
      Students.progress_through_topic(student, topic1)

      {_, lessons} = Students.get_progress(student, course.id)

      assert Students.calculate_progress_percentage(lessons) == 25.0
    end

    test "calculate_progress_percentage/1 should return %100.0 when the user has finished the course.",
         %{student: student} do
      course = course_fixture()

      lesson1 = lesson_fixture(course)
      topic1 = text_topic_fixture(lesson1)

      lesson2 = lesson_fixture(course)
      topic2 = text_topic_fixture(lesson2)

      lesson3 = lesson_fixture(course)
      topic3 = text_topic_fixture(lesson3)

      lesson4 = lesson_fixture(course)
      topic4 = text_topic_fixture(lesson4)

      {:ok, _} = Students.enroll_student(course, student)

      Students.progress_through_lesson(student, lesson1)
      Students.progress_through_topic(student, topic1)

      Students.progress_through_lesson(student, lesson2)
      Students.progress_through_topic(student, topic2)

      Students.progress_through_lesson(student, lesson3)
      Students.progress_through_topic(student, topic3)

      Students.progress_through_lesson(student, lesson4)
      Students.progress_through_topic(student, topic4)

      {_, lessons} = Students.get_progress(student, course.id)

      assert Students.calculate_progress_percentage(lessons) == 100.0
    end

    test "reset_progress/3 should reset the progress of a given student in a given course.", %{
      student: student
    } do
      course = course_fixture()
      {:ok, _} = Students.enroll_student(course, student)

      lesson1 = lesson_fixture(course)
      topic1 = text_topic_fixture(lesson1)

      lesson2 = lesson_fixture(course)
      topic2 = text_topic_fixture(lesson2)

      lesson3 = lesson_fixture(course)
      topic3 = text_topic_fixture(lesson3)

      lesson4 = lesson_fixture(course)
      topic4 = text_topic_fixture(lesson4)

      Students.progress_through_lesson(student, lesson1)
      Students.progress_through_topic(student, topic1)

      Students.progress_through_lesson(student, lesson2)
      Students.progress_through_topic(student, topic2)

      Students.progress_through_lesson(student, lesson3)
      Students.progress_through_topic(student, topic3)

      Students.progress_through_lesson(student, lesson4)
      Students.progress_through_topic(student, topic4)

      Students.reset_progress(course, student)

      {_, lessons} = Students.get_progress(student, course.id)
      {:lesson, next_lesson} = Students.get_next_lesson_or_topic(lessons)

      assert lesson1.id == next_lesson.id
    end
  end
end

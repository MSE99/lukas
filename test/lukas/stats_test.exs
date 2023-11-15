defmodule Lukas.StatsTest do
  use Lukas.DataCase, async: true

  import Lukas.Stats
  import Lukas.LearningFixtures

  describe "count_courses/0" do
    test "count_courses/0 should return 0" do
      assert count_courses() == 0
    end

    test "count_courses/0 should return the number of courses in the system." do
      1..20 |> Enum.each(fn _ -> course_fixture() end)
      assert count_courses() == 20
    end
  end
end

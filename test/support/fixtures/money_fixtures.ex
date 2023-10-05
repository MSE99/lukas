defmodule Lukas.MoneyFixtures do
  alias Lukas.Money

  def direct_deposit_fixture(clerk, student, amount) do
    Money.directly_deposit_to_student!(clerk, student, amount)
  end

  def purchase_fixture(student, course) do
    Money.purchase_course_for(student, course)
  end
end

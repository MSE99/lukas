defmodule Lukas.MoneyFixtures do
  alias Lukas.Money

  def direct_deposit_fixture(clerk, student, amount) do
    Money.directly_deposit_to_student!(clerk, student, amount)
  end

  def purchase_fixture(student, course) do
    Money.purchase_course_for(student, course)
  end

  def top_up_card_fixture(val \\ 20) do
    {:ok, card} = Money.generate_top_up_card(val)
    card
  end
end

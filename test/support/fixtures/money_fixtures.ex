defmodule Lukas.MoneyFixtures do
  alias Lukas.Money

  def direct_deposit_fixture(clerk, student, amount) do
    Money.directly_deposit_to_student!(clerk, student, amount)
  end
end

defmodule Lukas.MoneyTest do
  use Lukas.DataCase

  import Lukas.AccountsFixtures
  import Lukas.MoneyFixtures

  alias Lukas.Money

  setup do
    %{student: student_fixture(), clerk: user_fixture()}
  end

  test "get_deposited_amount/1 should return 0", %{student: student} do
    assert Money.get_deposited_amount!(student) == 0
  end

  test "get_deposited_amount/1 should return 1000 (for 2 deposits)", %{
    student: student,
    clerk: clerk
  } do
    direct_deposit_fixture(clerk, student, 500)
    direct_deposit_fixture(clerk, student, 500)

    assert Money.get_deposited_amount!(student) == 1000
  end
end

defmodule Lukas.Accounts.Query do
  import Ecto.Query

  alias Lukas.Accounts.User

  def operator_by_id(id) when is_integer(id) do
    from(opr in User, where: opr.kind == :operator and opr.id == ^id)
  end

  def operators(opts \\ []) do
    limit = Keyword.get(opts, :limit, 50)
    offset = Keyword.get(opts, :offset, 0)

    from(
      u in User,
      where: u.kind == :operator,
      limit: ^limit,
      offset: ^offset,
      order_by: [desc: :inserted_at]
    )
  end

  def students(opts \\ []) do
    limit = Keyword.get(opts, :limit, 50)
    offset = Keyword.get(opts, :offset, 0)
    name = Keyword.get(opts, :name, "")

    q =
      from(
        u in User,
        where: u.kind == :student,
        limit: ^limit,
        offset: ^offset,
        order_by: [asc: :id]
      )

    if name != "" do
      like_clause = "%" <> name <> "%"
      q |> where([u], like(u.name, ^like_clause))
    else
      q
    end
  end

  def user_by_phone_number_and_enabled(phone_number) when is_binary(phone_number) do
    from(u in User, where: u.phone_number == ^phone_number and u.enabled)
  end

  def user_by_email_and_enabled(email) when is_binary(email) do
    from(u in User, where: u.email == ^email and u.enabled)
  end

  def student_by_id(id) do
    from(u in User, where: u.kind == :student and u.id == ^id)
  end

  def lecturers_whose_id_not_in(exclusion_list, opts \\ []) do
    limit = Keyword.get(opts, :limit, 50)
    offset = Keyword.get(opts, :offset, 0)
    order_by = Keyword.get(opts, :order_by, desc: :inserted_at)

    from(
      u in User,
      where: u.kind == :lecturer and u.id not in ^exclusion_list,
      limit: ^limit,
      offset: ^offset,
      order_by: ^order_by
    )
  end

  def lecturers(opts) do
    limit = Keyword.get(opts, :limit, 50)
    offset = Keyword.get(opts, :offset, 0)
    order_by = Keyword.get(opts, :order_by, desc: :inserted_at)

    from(
      u in User,
      where: u.kind == :lecturer,
      limit: ^limit,
      offset: ^offset,
      order_by: ^order_by
    )
  end
end

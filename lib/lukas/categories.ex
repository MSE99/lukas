defmodule Lukas.Categories do
  alias Lukas.Categories.Tag
  alias Lukas.Repo

  def list_tags do
    Repo.all(Tag)
  end

  def get_tag!(id), do: Repo.get!(Tag, id)

  def create_tag(attrs \\ %{}) do
    %Tag{}
    |> Tag.changeset(attrs)
    |> Repo.insert()
    |> maybe_emit_tag_created()
  end

  def update_tag(%Tag{} = tag, attrs) do
    tag
    |> Tag.changeset(attrs)
    |> Repo.update()
    |> maybe_emit_tag_updated()
  end

  def delete_tag(%Tag{} = tag) do
    Repo.delete(tag)
  end

  def change_tag(%Tag{} = tag, attrs \\ %{}) do
    Tag.changeset(tag, attrs)
  end

  def watch_tags(), do: watch("tags")

  def maybe_emit_tag_created({:ok, tag} = res) do
    emit("tags", {:tag_created, tag})
    res
  end

  def maybe_emit_tag_created(res), do: res

  def maybe_emit_tag_updated({:ok, tag} = res) do
    emit("tags", {:tag_updated, tag})
    res
  end

  def maybe_emit_tag_updated(res), do: res

  # PubSub
  defp emit(topic, message) do
    Phoenix.PubSub.broadcast(Lukas.PubSub, topic, message)
  end

  defp watch(topic) do
    Phoenix.PubSub.subscribe(Lukas.PubSub, topic)
  end
end

defmodule Docs.DocumentChannel do
  use Docs.Web, :channel

  def join("documents:" <> doc_id, _params, socket) do
    {:ok, assign(socket, :doc_id, doc_id)}
    # or :error
  end

  # enfore the shape of the data here rather than relaying the raw params
  # boundary keys should be strings, internal should be atoms

  def handle_in("text_change", %{"ops" => ops}, socket) do
    # broadcast_from excludes the sender from the broadcast
    broadcast_from socket, "text_change", %{
      ops: ops
    }

    {:reply, :ok, socket}
  end

  def handle_in("save", params, socket) do
    Document
    |> Repo.get(socket.assigns.doc_id)
    |> Document.changeset(params)
    |> Repo.update()
    |> case do
      {:ok, _document}    ->
        {:reply, :ok, socket }
      {:error, changeset} ->
        {:reply, {:error, %{reasons: changeset}}, socket} # will serialize error messages
    end
  end

  def handle_in("new_message", params, socket) do
    Document
    |> Repo.get(socket.assigns.doc_id)
    |> Ecto.Model.build(:messages)
    |> Message.changeset(params)
    |> Repo.insert()
    |> case do
      {:ok, msg} ->
        broadcast! socket, "new_message", %{body: params["body"]}
        {:reply, :ok, socket }
      {:error, changeset} ->
        {:reply, {:error, %{reasons: changeset}}, socket} # will serialize error messages
    end
  end
end

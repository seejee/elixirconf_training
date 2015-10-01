defmodule Docs.DocumentChannel do
  use Docs.Web, :channel
  import SweetXml

  def join("documents:" <> doc_id, params, socket) do
    send(self, {:after_join, params})
    {:ok, assign(socket, :doc_id, doc_id)}
    # or :error
  end

  def handle_info({:after_join, params}, socket) do
    doc             = Repo.get(Document, socket.assigns.doc_id)
    last_message_id = params["last_message_id"] || 0
    messages = Repo.all(
      from m in assoc(doc, :messages),
      order_by: [asc: m.inserted_at],
      select: %{id: m.id, body: m.body},
      where: m.id > ^last_message_id,
      limit: 100
    )

    push socket, "messages", %{messages: messages}
    {:noreply, socket}
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

  defp app_id(), do: Application.get_env(:docs, :wolfram)[:app_id]

  def handle_in("compute_image", params, socket) do
    input = URI.encode(params["expr"])
    {:ok, {_, _, body}} = :httpc.request(String.to_char_list(
      "http://api.wolframalpha.com/v2/query?appid=#{app_id()}&input=#{input}&format=image,plaintext"
    ))

    img_url =
      body
      |> xpath(~x"/queryresult/pod[contains(@title, 'Result') or
                                contains(@title, 'Results') or
                                contains(@title, 'Plot')]
                          /subpod/img/@src")
      |> to_string()



    broadcast! socket, "insert_image", %{
      start: params["start"],
      end: params["end"],
      url: img_url
    }
    {:reply, :ok, socket}
  end
end

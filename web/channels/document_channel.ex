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
end
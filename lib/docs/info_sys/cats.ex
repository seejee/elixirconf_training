defmodule Docs.InfoSys.Cats do
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  def init(opts) do
    send(self, :request)
    :random.seed(:os.timestamp())
    {:ok, opts}
  end

  def handle_info(:request, opts) do
    img_url = random_cat()
    send(opts[:client_pid], {:result, self, %{score: 100, img_url: img_url}})
    {:stop, :shutdown, opts}
  end

  defp random_cat() do
    Enum.random([
      "http://i.imgur.com/1cDcop1.gifv",
      "http://i.imgur.com/tVE0I8K.gifv",
      "http://i.imgur.com/crxGKQs.jpg",
    ])
  end
end


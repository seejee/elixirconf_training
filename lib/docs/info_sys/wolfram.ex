defmodule Docs.InfoSys.Wolfram do
  use GenServer
  import SweetXml

  defp app_id, do: Application.get_env(:docs, :wolfram)[:app_id]

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  def init(opts) do
    send(self, :request)
    {:ok, opts}
  end

  def handle_info(:request, opts) do
    input = URI.encode(opts[:expr])

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

    case img_url do
      "" ->
        send(opts[:client_pid], {:noresult, self})
      imge_url ->
        send(opts[:client_pid], {:result, self, %{score: 90, img_url: img_url}})
    end

    {:stop, :shutdown, opts}
  end
end

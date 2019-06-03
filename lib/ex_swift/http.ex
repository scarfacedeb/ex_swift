defmodule ExSwift.Http do
  @headers [{"content-type", "application/json"}]

  def post(url, body) do
    request(:post, url, @headers, body)
  end

  def request(method, url, headers, body) do
    case Mojito.request(method, url, headers, body) do
      {:ok, %Mojito.Response{status_code: status} = resp} when status in 200..299 ->
        {:ok, resp}

      {:ok, %Mojito.Response{status_code: status} = resp} ->
        {:error, {:http_error, status, resp}}

      {:error, error} ->
        {:error, error}
    end
  end

  def get_header(%Mojito.Response{headers: headers}, name) do
    Mojito.Headers.get(headers, name)
  end
end

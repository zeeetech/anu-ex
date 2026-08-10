defmodule Anu.Cloud.Client do
  @moduledoc false

  # Private HTTP client for the anu_cloud backend. Not part of the public API.
  #
  # Tests can swap the implementation by configuring:
  #
  #     config :anu, :cloud_client, MyMock
  #
  # The bound module must implement the `Anu.Cloud.Client` behaviour below.
  # The `%Anu.Client{}` is passed as the first argument to every callback.

  @behaviour Anu.Cloud.Client

  alias Anu.Client
  alias Anu.Error

  @type result :: {:ok, map()} | {:error, Error.t() | :cloud_not_configured}

  @callback post(Client.t(), path :: String.t(), body :: map()) :: result()

  @impl true
  def post(%Client{} = client, path, body) when is_binary(path) and is_map(body) do
    if configured?(client) do
      do_post(client, path, body)
    else
      {:error, :cloud_not_configured}
    end
  end

  defp configured?(%Client{cloud_api_key: key}) do
    is_binary(key) and key != ""
  end

  defp do_post(%Client{} = client, path, body) do
    url = client.cloud_url <> path
    payload = JSON.encode!(body)

    :post
    |> Finch.build(url, headers(client), payload)
    |> Finch.request(client.finch)
    |> handle_response()
  end

  defp headers(%Client{} = client) do
    [
      {"authorization", "Bearer " <> client.cloud_api_key},
      {"content-type", "application/json"},
      {"user-agent", user_agent()}
    ]
  end

  defp user_agent do
    case Application.spec(:anu, :vsn) do
      nil -> "anu_ex"
      vsn -> "anu_ex/#{vsn}"
    end
  end

  defp handle_response({:ok, %Finch.Response{status: status, body: body}}) when status in 200..299 do
    {:ok, decode!(body)}
  end

  defp handle_response({:ok, %Finch.Response{status: status, body: body}}) do
    error = body |> decode_safely() |> Error.from_response()

    {:error, %{error | code: error.code || status}}
  end

  defp handle_response({:error, reason}) do
    {:error, %Error{code: :transport, message: "HTTP request failed: #{inspect(reason)}"}}
  end

  defp decode!(body), do: JSON.decode!(body)

  defp decode_safely(body) do
    case JSON.decode(body) do
      {:ok, decoded} when is_map(decoded) -> decoded
      _ -> %{"error" => %{"message" => body}}
    end
  end
end

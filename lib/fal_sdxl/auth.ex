defmodule Membrane.FalSDXL.Auth do
  @moduledoc """
  Authentication for the fal.ai API.
  """

  require Logger

  @rest_api_url "https://rest.alpha.fal.ai"

  @spec get_token(String.t(), String.t()) ::
          {:ok, String.t()}
          | {:error, String.t()}
          | {:error, Exception.t()}
  @doc """
  Get a JWT authentication token
  """
  def get_token(app_id, api_key) do
    base_app_id = app_id |> String.split("/") |> Enum.at(1)

    body = %{
      "allowed_apps" => [base_app_id],
      "token_expiration" => 120
    }

    Logger.debug("Membrane.FalSDXL.Auth: Requesting token for app: #{inspect(app_id)}")

    case Req.post("#{@rest_api_url}/tokens/",
           json: body,
           headers: [
             {"authorization", "Key #{api_key}"},
             {"accept", "application/json"},
             {"content-type", "application/json"}
           ]
         ) do
      {:ok, %{status: 201, body: token}} when is_binary(token) ->
        {:ok, token}

      {:ok, %{status: status, body: body}} ->
        Logger.error("Membrane.FalSDXL.Auth: Token request failed (HTTP #{status}): #{inspect(body)}")
        {:error, "HTTP #{status}: #{inspect(body)}"}

      {:error, error} ->
        Logger.error("Membrane.FalSDXL.Auth: Token request error: #{inspect(error)}")
        {:error, error}
    end
  end
end

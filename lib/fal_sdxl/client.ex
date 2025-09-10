defmodule Membrane.FalSDXL.Client do
  @moduledoc """
  WebSockex client for the Fal websocket API.
  """

  use WebSockex
  require Logger
  alias Membrane.FalSDXL.{Auth, GenerationParams}

  @app_id "fal-ai/fast-lcm-diffusion/image-to-image"
  @websocket_host "wss://fal.run"
  # Refresh after 3/4 of token lifetime
  @token_refresh_interval :timer.seconds(90)

  @spec start_link(String.t(), Keyword.t()) :: {:error, any()} | {:ok, pid()}
  def start_link(api_key, opts \\ []) do
    Logger.info("Membrane.FalSDXL.Client: Starting Fal client")

    case Auth.get_token(@app_id, api_key) do
      {:ok, token} ->
        Logger.info("Membrane.FalSDXL.Client: Got Fal token: #{String.slice(token, 0..10)}...")
        url = build_realtime_url(@app_id, token)

        Logger.info("Membrane.FalSDXL.Client: Connecting to #{url}")

        websockex_opts = [
          extra_headers: [{"Sec-WebSocket-Protocol", "fal-realtime"}],
          handle_initial_conn_failure: true
        ]

        WebSockex.start_link(
          url,
          __MODULE__,
          %{
            api_key: api_key,
            credentials: token,
            app_id: @app_id,
            on_result: opts[:on_result],
            on_error: opts[:on_error],
            refresh_timer: nil
          },
          websockex_opts
        )

      {:error, reason} ->
        Logger.error("Membrane.FalSDXL.Client: Failed to get Fal auth token: #{inspect(reason)}")
        {:error, :auth_failed}
    end
  end

  @spec send_image(
          atom() | pid() | {:global, any()} | {:via, atom(), any()},
          binary(),
          %GenerationParams{}
        ) :: :ok
  def send_image(client, image_binary, %GenerationParams{} = params) do
    data_uri = encode_binary_image(image_binary)
    params = %{params | image_url: data_uri}
    send_message(client, Map.from_struct(params))
  end

  @spec send_message(
          atom() | pid() | {:global, any()} | {:via, atom(), any()},
          map()
        ) :: :ok
  def send_message(client, message) when is_map(message) do
    WebSockex.cast(client, {:send_message, message})
  end

  # WebSockex callbacks

  @impl WebSockex
  def handle_connect(_conn, state) do
    Logger.info("Membrane.FalSDXL.Client: Fal WebSocket connected")
    {:ok, refresh_timer} = :timer.send_interval(@token_refresh_interval, :refresh_token)

    {:ok, %{state | refresh_timer: refresh_timer}}
  end

  @impl WebSockex
  def handle_frame({:binary, msg}, state) do
    case Msgpax.unpack(msg) do
      {:ok, decoded} ->
        Logger.debug("Membrane.FalSDXL.Client: Received binary message")
        handle_message(decoded, state)

      {:error, error} ->
        Logger.error(
          "Membrane.FalSDXL.Client: Failed to decode binary message: #{inspect(error)}"
        )

        {:ok, state}
    end
  end

  def handle_frame({:text, msg}, state) do
    Logger.debug("Membrane.FalSDXL.Client: Received text message: #{inspect(msg)}")
    {:ok, state}
  end

  @impl WebSockex
  def handle_cast({:send_message, message}, state) do
    case Msgpax.pack(message) do
      {:ok, packed} ->
        binary = if is_list(packed), do: IO.iodata_to_binary(packed), else: packed
        Logger.debug("Membrane.FalSDXL.Client: Sending message (#{byte_size(binary)} bytes)")
        {:reply, {:binary, binary}, state}

      {:error, reason} ->
        Logger.error("Membrane.FalSDXL.Client: Failed to encode message: #{inspect(reason)}")
        {:ok, state}
    end
  end

  @impl WebSockex
  def handle_info(:refresh_token, state) do
    Logger.info("Membrane.FalSDXL.Client: Refreshing Fal auth token")

    case Auth.get_token(state.app_id, state.api_key) do
      {:ok, new_token} ->
        Logger.info("Membrane.FalSDXL.Client: Token refreshed successfully")
        {:ok, %{state | credentials: new_token}}

      {:error, reason} ->
        Logger.error("Membrane.FalSDXL.Client: Failed to refresh token: #{inspect(reason)}")
        {:close, {:error, :token_refresh_failed}, state}
    end
  end

  @impl WebSockex
  def handle_disconnect(%{reason: reason}, state) do
    Logger.warning(
      "Membrane.FalSDXL.Client: WebSocket disconnected: #{inspect(reason)}. Attempting to reconnect"
    )

    if state.refresh_timer, do: :timer.cancel(state.refresh_timer)
    {:reconnect, %{state | refresh_timer: nil}}
  end

  @impl WebSockex
  def terminate(reason, state) do
    Logger.info("Membrane.FalSDXL.Client: Terminating: #{inspect(reason)}")
    if state.refresh_timer, do: :timer.cancel(state.refresh_timer)
  end

  # Helper functions

  defp handle_message(%{"status" => "error", "error" => error}, state) do
    state.on_error.(%{status: 400, message: error})
    {:ok, state}
  end

  defp handle_message(%{"type" => "x-fal-message"} = msg, state) do
    state.on_result.(msg)
    {:ok, state}
  end

  defp handle_message(%{"type" => "x-fal-error"} = msg, state) do
    state.on_error.(msg)
    {:ok, state}
  end

  defp handle_message(msg, state) do
    state.on_result.(msg)
    {:ok, state}
  end

  defp build_realtime_url(app_id, token) do
    endpoint = ensure_endpoint_id_format!(app_id)
    encoded_token = URI.encode_www_form(token)
    query = URI.encode_query(%{fal_jwt_token: encoded_token})
    "#{@websocket_host}/#{endpoint}/realtime?#{query}"
  end

  defp ensure_endpoint_id_format!(id) do
    case String.split(id, "/") do
      [_single] ->
        case Regex.run(~r/^([0-9]+)-([a-zA-Z0-9-]+)$/, id) do
          [_hd, app_owner, app_id] ->
            "#{app_owner}/#{app_id}"

          _invalid ->
            raise "Membrane.FalSDXL.Client: Invalid app id: #{id}. Must be in the format <appOwner>/<appId>"
        end

      parts when length(parts) > 1 ->
        id
    end
  end

  defp encode_binary_image(binary) do
    "data:image/jpeg;base64," <> Base.encode64(binary)
  end
end

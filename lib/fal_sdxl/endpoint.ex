defmodule Membrane.FalSDXL.Endpoint do
  use Membrane.Endpoint

  require Membrane.Logger

  alias Membrane.Buffer
  alias Membrane.FalSDXL.{Client, GenerationParams, JpegStream}

  def_options api_key: [
                type: :string,
                description: "API key for Fal.ai"
              ],
              initial_generation_params: [
                type: %GenerationParams{},
                description: "Initial Fal generation params when starting playback",
                default: %GenerationParams{}
              ]

  def_input_pad :input, flow_control: :auto, accepted_format: JpegStream

  def_output_pad :output, flow_control: :push, accepted_format: JpegStream

  defmodule State do
    defstruct [
      :client,
      :generation_params,
      processing?: false,
      current_pts: nil
    ]
  end

  defp fal_result_handler(endpoint_pid) do
    fn response ->
      case response do
        %{"images" => [%{"content" => content} | _rest]} ->
          Membrane.Logger.info("Fal endpoint: Fal result content received")
          send(endpoint_pid, {:fal_result, content})

        other ->
          Membrane.Logger.warning("Unexpected Fal response format: #{inspect(other)}")
      end
    end
  end

  defp fal_error_handler(endpoint_pid) do
    fn error ->
      send(endpoint_pid, {:fal_error, error})
    end
  end

  @impl true
  def handle_init(_ctx, opts) do
    {:ok, client} =
      Client.start_link(
        opts.api_key,
        on_result: fal_result_handler(self()),
        on_error: fal_error_handler(self())
      )

    state = %State{
      client: client,
      generation_params: opts.initial_generation_params,
      processing?: false
    }

    {[], state}
  end

  @impl true
  def handle_stream_format(:input, stream_format, _ctx, state) do
    {[stream_format: {:output, stream_format}], state}
  end

  @impl true
  def handle_info({:fal_result, jpeg_binary}, _ctx, state) do
    Membrane.Logger.debug("Received processed image from Fal")
    buffer = %Buffer{payload: jpeg_binary, pts: state.current_pts}
    {[buffer: {:output, buffer}], %{state | processing?: false}}
  end

  @impl true
  def handle_info({:fal_error, error}, _ctx, state) do
    Membrane.Logger.warning("Fal error: #{inspect(error)}")
    {[], %{state | processing?: false}}
  end

  @impl true
  def handle_buffer(
        :input,
        %Buffer{payload: payload} = buffer,
        _ctx,
        %{processing?: false} = state
      ) do
    Client.send_image(state.client, payload, state.generation_params)
    {[], %{state | processing?: true, current_pts: buffer.pts}}
  end

  @impl true
  def handle_buffer(:input, _buffer, _ctx, state) do
    # Drop frame if we're still processing
    {[], state}
  end

  @impl true
  def handle_terminate_request(_ctx, state) do
    if state.client do
      GenServer.stop(state.client)
    end

    {[{:terminate, :normal}], state}
  end

  @impl true
  def handle_parent_notification(
        {:update_generation_params, %GenerationParams{} = params},
        _context,
        state
      ) do
    {[], %{state | generation_params: params}}
  end
end

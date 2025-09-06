defmodule Membrane.FalSDXL.JpegDecoder do
  @moduledoc """
  Membrane filter converting JPEG to raw video frames.
  """
  use Membrane.Filter

  alias Membrane.Buffer
  alias Membrane.FalSDXL.JpegStream
  alias Membrane.RawVideo

  def_input_pad(:input,
    flow_control: :auto,
    accepted_format: JpegStream
  )

  def_output_pad(:output,
    flow_control: :auto,
    accepted_format: %RawVideo{pixel_format: pix_fmt} when pix_fmt in [:I420, :I422, :I444]
  )

  @impl true
  def handle_init(_ctx, _options) do
    {[], %{}}
  end

  @impl true
  def handle_stream_format(:input, %JpegStream{} = format, _ctx, state) do
    stream_format = %RawVideo{
      width: format.width,
      height: format.height,
      pixel_format: format.pixel_format,
      framerate: {10, 1},
      aligned: true
    }

    {[stream_format: {:output, stream_format}], state}
  end

  @impl true
  def handle_buffer(:input, %Buffer{payload: payload} = buffer, _ctx, state) do
    case Turbojpeg.jpeg_to_yuv(payload) do
      {:ok, yuv} ->
        {[buffer: {:output, %Buffer{buffer | payload: yuv}}], state}

      error ->
        raise "could not decode JPEG image: #{inspect(error)}"
    end
  end
end

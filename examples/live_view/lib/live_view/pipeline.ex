defmodule LiveView.Pipeline do
  use Membrane.Pipeline

  alias Membrane.FalSDXL.GenerationParams

  @impl Membrane.Pipeline
  def handle_init(_ctx, opts) do
    spec =
      child(:webrtc_source, %Membrane.WebRTC.Source{
        allowed_video_codecs: :vp8,
        signaling: opts[:ingress_signaling]
      })
      |> via_out(:output, options: [kind: :video])
      |> child(Membrane.VP8.Decoder)
      |> child(:converter, %Membrane.FFmpeg.SWScale.Converter{
        output_height: 512,
        output_width: 512,
        format: :I420
      })
      |> child(:fal, %Membrane.FalSDXL{
        api_key: opts[:api_key],
        initial_generation_params: opts[:initial_generation_params]
      })
      |> child(%Membrane.VP8.Encoder{g_lag_in_frames: 0})
      |> via_in(:input, options: [kind: :video])
      |> child(:webrtc_sink, %Membrane.WebRTC.Sink{
        video_codec: :vp8,
        signaling: opts[:egress_signaling]
      })

    {[spec: spec], %{}}
  end

  @impl true
  def handle_info(
        {:update_generation_params, %GenerationParams{} = params},
        _context,
        state
      ) do
    {[notify_child: {:fal, {:update_generation_params, params}}], state}
  end
end

defmodule LiveView.Pipeline do
  use Membrane.Pipeline

  @impl Membrane.Pipeline
  def handle_init(_ctx, opts) do
    spec =
      child(:webrtc_source, %Membrane.WebRTC.Source{
        allowed_video_codecs: :vp8,
        signaling: opts[:ingress_signaling]
      })
      |> via_out(:output, options: [kind: :video])
      |> child(Membrane.VP8.Decoder)
      |> child(%Membrane.FalSDXL{api_key: opts[:api_key]})
      |> child(%Membrane.VP8.Encoder{g_lag_in_frames: 0})
      |> via_in(:input, options: [kind: :video])
      |> child(:webrtc_sink, %Membrane.WebRTC.Sink{
        video_codec: :vp8,
        signaling: opts[:egress_signaling]
      })

    {[spec: spec], %{}}
  end
end

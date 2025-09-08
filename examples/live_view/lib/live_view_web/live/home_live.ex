defmodule LiveViewWeb.HomeLive do
  use LiveViewWeb, :live_view

  alias Membrane.WebRTC.Live.{Capture, Player}

  def mount(_params, _session, socket) do
    socket =
      if connected?(socket) do
        ingress_signaling = Membrane.WebRTC.Signaling.new()
        egress_signaling = Membrane.WebRTC.Signaling.new()
        api_key = Application.get_env(:live_view, :api_key)

        Membrane.Pipeline.start_link(LiveView.Pipeline,
          ingress_signaling: ingress_signaling,
          egress_signaling: egress_signaling,
          api_key: api_key
        )

        socket
        |> Capture.attach(
          id: "mediaCapture",
          signaling: ingress_signaling,
          video?: true,
          audio?: false
        )
        |> Player.attach(
          id: "videoPlayer",
          signaling: egress_signaling
        )
      else
        socket
      end

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="flex gap-3">
          <Capture.live_render socket={@socket} capture_id="mediaCapture" />

          <Player.live_render socket={@socket} player_id="videoPlayer" />
      </div>
    </Layouts.app>
    """
  end
end

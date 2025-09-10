defmodule LiveViewWeb.HomeLive do
  use LiveViewWeb, :live_view

  require Logger

  alias Membrane.FalSDXL.GenerationParams
  alias Membrane.WebRTC.Live.{Capture, Player}

  @initial_generation_params %GenerationParams{
    prompt: "an elf with pointy ears wearing a green robe and hat, torch lit dungeon background",
    strength: 0.4
  }

  @impl true
  def mount(_params, _session, socket) do
    socket =
      if connected?(socket) do
        ingress_signaling = Membrane.WebRTC.Signaling.new()
        egress_signaling = Membrane.WebRTC.Signaling.new()
        api_key = Application.get_env(:live_view, :api_key)

        {:ok, _supervisor_pid, pipeline_pid} =
          Membrane.Pipeline.start_link(LiveView.Pipeline,
            ingress_signaling: ingress_signaling,
            egress_signaling: egress_signaling,
            api_key: api_key,
            initial_generation_params: @initial_generation_params
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
        |> assign(pipeline_pid: pipeline_pid)
      else
        socket
      end

    {:ok,
     socket
     |> assign(
       form:
         @initial_generation_params
         |> GenerationParams.to_params_map()
         |> Phoenix.Component.to_form()
     )}
  end

  @impl true
  def handle_event("update", %{"prompt" => prompt, "strength" => strength}, socket) do
    updated_params = %GenerationParams{prompt: prompt, strength: Float.parse(strength) |> elem(0)}

    send(
      socket.assigns.pipeline_pid,
      {:update_generation_params, updated_params}
    )

    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="flex flex-wrap justify-center gap-3">
        <Capture.live_render socket={@socket} capture_id="mediaCapture" />

        <Player.live_render socket={@socket} player_id="videoPlayer" class="w-lg h-lg" />

        <.form for={@form} phx-change="update" class="w-lg">
          <.input type="textarea" field={@form["prompt"]} label="Prompt" />
          <.input
            type="range"
            field={@form["strength"]}
            label="Strength"
            min="0.05"
            max="1.0"
            step="0.05"
            class="range w-full"
          />
        </.form>
      </div>
    </Layouts.app>
    """
  end
end

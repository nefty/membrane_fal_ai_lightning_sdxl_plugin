defmodule Membrane.FalSDXL do
  @moduledoc """
  A Membrane bin which styles a video according to a prompt with fast Stable
  Diffusion XL, via Fal.ai.
  """

  use Membrane.Bin

  alias Membrane.RawVideo
  alias Membrane.FalSDXL.{Endpoint, GenerationParams, JpegDecoder, JpegEncoder}

  def_input_pad :input,
    accepted_format: %RawVideo{pixel_format: pix_fmt} when pix_fmt in [:I420, :I422, :I444]

  def_output_pad :output,
    accepted_format: %RawVideo{pixel_format: pix_fmt} when pix_fmt in [:I420, :I422, :I444]

  def_options api_key: [
                type: :string,
                description: "API key for Fal.ai"
              ],
              initial_generation_params: [
                type: %GenerationParams{},
                description: "Initial Fal generation params when starting playback",
                default: %GenerationParams{}
              ]

  @impl Membrane.Bin
  def handle_init(_ctx, opts) do
    spec = [
      bin_input(:input)
      |> child(:jpeg_encoder, JpegEncoder)
      |> child(:endpoint, %Endpoint{
        api_key: opts.api_key,
        initial_generation_params: opts.initial_generation_params
      })
      |> child(:jpeg_decoder, JpegDecoder)
      |> bin_output(:output)
    ]

    {[spec: spec], %{}}
  end

  @impl Membrane.Bin
  def handle_parent_notification(
        {:update_generation_params, %GenerationParams{} = params},
        _context,
        state
      ) do
    {[notify_child: {:endpoint, {:update_generation_params, params}}], state}
  end
end

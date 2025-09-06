defmodule Membrane.FalSDXL.GenerationParams do
  @moduledoc """
  Input parameters for Fal.ai.
  More info:
  https://fal.ai/models/fal-ai/fast-lcm-diffusion/image-to-image/api#schema
  """

  @enforce_keys [:prompt]
  defstruct [
    :prompt,
    :image_url,
    :seed,
    negative_prompt: "",
    image_size: "square",
    model_name: "stabilityai/stable-diffusion-xl-base-1.0",
    num_inference_steps: 2,
    guidance_scale: 1.0,
    strength: 0.95,
    sync_mode: true,
    num_images: 1,
    enable_safety_checker: false,
    expand_prompt: false,
    format: "jpeg"
  ]

  @type image_size :: String.t() | %{width: pos_integer(), height: pos_integer()}

  @type t :: %__MODULE__{
          prompt: String.t(),
          image_url: String.t(),
          negative_prompt: String.t(),
          image_size: image_size() | nil,
          model_name: String.t(),
          num_inference_steps: pos_integer(),
          guidance_scale: float(),
          strength: float(),
          seed: pos_integer() | nil,
          sync_mode: boolean(),
          num_images: pos_integer(),
          enable_safety_checker: boolean(),
          expand_prompt: boolean(),
          format: String.t()
        }
end

defmodule Membrane.FalSDXL.GenerationParams do
  @moduledoc """
  Input parameters for Fal.ai.
  More info:
  https://fal.ai/models/fal-ai/fast-lcm-diffusion/image-to-image/api#schema
  """

  defstruct [
    :image_url,
    :seed,
    prompt: "",
    negative_prompt: "",
    image_size: "square",
    model_name: "runwayml/stable-diffusion-v1-5",
    num_inference_steps: 2,
    guidance_scale: 1.5,
    strength: 0.4,
    sync_mode: true,
    num_images: 1,
    enable_safety_checker: false,
    expand_prompt: false,
    format: "jpeg"
  ]

  @doc """
  Convert a %GenerationParams{} struct to a Phoenix params style map,
  with string keys and values for use with Phoenix.Component.to_form/1
  """
  def to_params_map(%__MODULE{} = struct) do
    struct
    |> Map.from_struct()
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Enum.reduce(%{}, fn {key, value}, acc ->
      Map.put(acc, to_string(key), to_string(value))
    end)
  end
end

defmodule Membrane.FalSDXL.JpegStream do
  @moduledoc """
  Stream format for JPEG-encoded video frames.
  Contains information about the image dimensions and format.
  """

  @enforce_keys [:width, :height, :pixel_format]
  defstruct [:width, :height, :pixel_format]

  @type format :: :I420 | :I422 | :I444
  @type t :: %__MODULE__{
          width: pos_integer(),
          height: pos_integer(),
          pixel_format: format()
        }
end

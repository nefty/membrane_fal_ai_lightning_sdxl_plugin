# Membrane Fal.ai Lightning SDXL Plugin

This is a Membrane plugin which styles video in real time using fast Stable Diffusion XL via Fal.ai.

See [https://fal.ai/models/fal-ai/fast-lcm-diffusion/image-to-image/api](https://fal.ai/models/fal-ai/fast-lcm-diffusion/image-to-image/api)
for more information on the model.

## Installation

The package can be installed by adding `membrane_fal_ai_lightning_sdxl_plugin` to your list of dependencies in `mix.exs`.
It is not available in Hex and must be loaded from GitHub:

```elixir
def deps do
  [
    {:membrane_fal_ai_lightning_sdxl_plugin, github: "nefty/membrane_fal_ai_lightning_sdxl_plugin"}
  ]
end
```

Because it depends on [turbojpeg](https://hex.pm/packages/turbojpeg), it
requires [libjpeg-turbo](https://libjpeg-turbo.org/) to be installed.

### Arch Linux

```shell
sudo pacman -S libjpeg-turbo
```

### Ubuntu/Debian

```shell
sudo apt-get install libturbojpeg libturbojpeg0-dev
```

### OSX

```shell
brew install libjpeg-turbo
```

## Usage

`Membrane.FalSDXL` is a Membrane Bin which takes raw video as input and outputs
raw video. It first encodes a frame as JPEG.  Then, `Membrane.FalSDXL.Endpoint`
sends the image along with a set of generation parameters (such as a prompt) to
Fal.ai via its real-time WebSocket API. The Stable Diffusion transformed image is
returned to the Endpoint. Finally, it is passed on to a JPEG decoder filter. A raw video frame is
output from the Bin.

See `examples/live_view` for a Phoenix LiveView WebRTC demo.

# Membrane Fal.ai Lightning SDXL LiveView Example

This demo shows how to use the plugin to transform live video over WebRTC in a
Phoenix application. This demo works best in Chrome or Chromium-based browsers.

Note `assets/js/capture.js`. This is the same hook from
`membrane_webrtc_plugin`, but with the addition of this section:

```js
        mediaConstraints.video = {
          width: { exact: 512 },
          height: { exact: 512 },
          frameRate: { exact: 10 }
        };
```

This is because the model is fastest with 512x512 resolution images.

Additionally, see `LiveView.Pipeline.handle_info/3` to see how to change the
generation parameters during playback.

## Environment

You must set your Fal API key in your environment as `FAL_API_KEY`.

```shell
export FAL_API_KEY="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
```

To start your Phoenix server:

* Run `mix setup` to install and setup dependencies
* Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

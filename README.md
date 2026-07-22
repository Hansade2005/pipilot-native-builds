# pipilot-native-builds

The **generic PiPilot desktop shell** — a [Native SDK](https://native-sdk.dev) WebView app
that loads whatever URL is in `NATIVE_SDK_FRONTEND_URL` at launch, with
`security.navigation.allowed_origins = .{ "*" }` so **one binary per OS wraps any deployed
`*.pipilot.dev` app**. No per-app build; the desktop app always shows the latest deploy.

## How it's used

PiPilot's "Get Desktop Version" hands the user the pre-built shell for their OS and launches
it with `NATIVE_SDK_FRONTEND_URL=https://<their-app>.pipilot.dev`.

## Building

The `Build Shells` GitHub Actions workflow (`.github/workflows/build-shells.yml`) packages the
shell for macOS / Linux / Windows on free public-repo runners:

- **`workflow_dispatch`** — build on demand (Actions tab, or via API from PiPilot's backend).
- **Push a `v*` tag** — build + attach the artifacts to a GitHub Release.

## Local dev

```bash
npm i -g @native-sdk/cli@0.5.4
NATIVE_SDK_FRONTEND_URL="https://yourapp.pipilot.dev/" native dev   # run the shell against a URL
native validate && native build && native package --target macos    # build a binary
```

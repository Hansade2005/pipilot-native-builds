// Per-app identity baked at build time. The committed default targets the PiPilot
// hub; the per-app installer workflow (build-app.yml) overwrites this file with the
// user's deployed URL + app name before `native build`. Launch-time env vars
// (NATIVE_SDK_FRONTEND_URL / NATIVE_SDK_APP_NAME) still take precedence over these.
pub const frontend_url = "https://pipilot.dev";
pub const app_name = "PiPilot";

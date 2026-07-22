const std = @import("std");
const runner = @import("runner");
const native_sdk = @import("native_sdk");
const app_config = @import("app_config.zig");

pub const panic = std.debug.FullPanic(native_sdk.debug.capturePanic);

// Baked per-app identity (see app_config.zig). The per-app installer workflow
// compiles the user's URL + name in here; env vars still override at launch.
const default_url = app_config.frontend_url;
const default_name = app_config.app_name;

fn envOr(env_map: *std.process.Environ.Map, key: []const u8, fallback: []const u8) []const u8 {
    if (env_map.get(key)) |v| {
        if (v.len > 0) return v;
    }
    return fallback;
}

const Shell = struct {
    env_map: *std.process.Environ.Map,

    fn app(self: *@This()) native_sdk.App {
        return .{
            .context = self,
            .name = "pipilot-shell",
            // Static default; the runtime prefers source_fn below when present.
            .source = native_sdk.WebViewSource.url(default_url),
            .source_fn = source,
        };
    }

    // Resolve the WebView target at launch: the env URL, else the default.
    fn source(context: *anyopaque) anyerror!native_sdk.WebViewSource {
        const self: *@This() = @ptrCast(@alignCast(context));
        if (self.env_map.get("NATIVE_SDK_FRONTEND_URL")) |url| {
            if (url.len > 0) return native_sdk.WebViewSource.url(url);
        }
        return native_sdk.WebViewSource.url(default_url);
    }
};

pub fn main(init: std.process.Init) !void {
    var shell = Shell{ .env_map = init.environ_map };
    // Prefer the launcher-injected app name; fall back to the generic "PiPilot".
    const app_name = envOr(init.environ_map, "NATIVE_SDK_APP_NAME", default_name);
    try runner.runWithOptions(shell.app(), .{
        .app_name = app_name,
        .window_title = app_name,
        .bundle_id = "dev.pipilot.shell",
        .security = .{
            .navigation = .{
                .allowed_origins = &.{"*"},
                .external_links = .{
                    .action = .open_system_browser,
                    .allowed_urls = &.{"*"},
                },
            },
        },
    }, init);
}

test "shell falls back to the default url when env is unset" {
    var env = std.process.Environ.Map.init(std.testing.allocator);
    defer env.deinit();
    var shell = Shell{ .env_map = &env };
    const src = try Shell.source(&shell);
    try std.testing.expectEqual(native_sdk.WebViewSourceKind.url, src.kind);
    try std.testing.expectEqualStrings(default_url, src.bytes);
}

test "app name falls back to default, else honors NATIVE_SDK_APP_NAME" {
    var env = std.process.Environ.Map.init(std.testing.allocator);
    defer env.deinit();
    try std.testing.expectEqualStrings(default_name, envOr(&env, "NATIVE_SDK_APP_NAME", default_name));
    try env.put("NATIVE_SDK_APP_NAME", "Acme Notes");
    try std.testing.expectEqualStrings("Acme Notes", envOr(&env, "NATIVE_SDK_APP_NAME", default_name));
}

test "shell uses NATIVE_SDK_FRONTEND_URL when set" {
    var env = std.process.Environ.Map.init(std.testing.allocator);
    defer env.deinit();
    try env.put("NATIVE_SDK_FRONTEND_URL", "https://myapp.pipilot.dev/");
    var shell = Shell{ .env_map = &env };
    const src = try Shell.source(&shell);
    try std.testing.expectEqual(native_sdk.WebViewSourceKind.url, src.kind);
    try std.testing.expectEqualStrings("https://myapp.pipilot.dev/", src.bytes);
}

const std = @import("std");
const runner = @import("runner");
const native_sdk = @import("native_sdk");

pub const panic = std.debug.FullPanic(native_sdk.debug.capturePanic);

// Fallback when NATIVE_SDK_FRONTEND_URL isn't provided at launch. In production
// the launcher always sets the env var to the user's deployed *.pipilot.dev URL.
const default_url = "https://pipilot.dev";

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
    try runner.runWithOptions(shell.app(), .{
        .app_name = "PiPilot",
        .window_title = "PiPilot",
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

test "shell uses NATIVE_SDK_FRONTEND_URL when set" {
    var env = std.process.Environ.Map.init(std.testing.allocator);
    defer env.deinit();
    try env.put("NATIVE_SDK_FRONTEND_URL", "https://myapp.pipilot.dev/");
    var shell = Shell{ .env_map = &env };
    const src = try Shell.source(&shell);
    try std.testing.expectEqual(native_sdk.WebViewSourceKind.url, src.kind);
    try std.testing.expectEqualStrings("https://myapp.pipilot.dev/", src.bytes);
}

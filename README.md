# zig_vda

[![MIT License](http://img.shields.io/badge/license-MIT-blue.svg?style=flat-square)](LICENSE.md)

Zig bindings for the Windows virtual desktop COM interfaces.

## Features

- Enumerate virtual desktops
- Switch the active desktop
- Create and remove desktops
- Get and set desktop names
- Get and set desktop wallpapers
- Move windows between desktops
- Pin and unpin windows and applications
- Query which desktop a window is on
- Monitor desktop change events
- Automatic reconnect when the COM service drops

## Requirements

- Zig 0.17.0 or later
- Windows 10 or later

## Usage

```zig
const std = @import("std");
const vd = @import("vd");

pub fn main() !void {
    try vd.com.initialize(vd.com.COINIT_MULTITHREADED);
    defer vd.com.uninitialize();

    var service = try vd.Service.init();
    defer service.deinit();

    const count = try service.getDesktopCount();
    const current = try service.getCurrentDesktopIndex();

    var i: u32 = 0;
    while (i < count) : (i += 1) {
        var name_buf: [vd.NAME_LEN_MAX]u8 = undefined;
        const name = service.getDesktopName(i, &name_buf) catch "?";
        const marker: []const u8 = if (i == current) " <-- active" else "";
        std.debug.print("  [{d}] {s}{s}\n", .{ i, name, marker });
    }
}
```

## Examples

Examples are located in the `examples` directory:

| Example | Description |
|---------|-------------|
| `enumerate_desktops` | List all virtual desktops |
| `switch_desktop` | Switch the active desktop |
| `create_remove_desktop` | Create and remove desktops |
| `rename_desktop` | Get and set desktop names |
| `move_window` | Move a window to another desktop |
| `pin_window` | Pin and unpin a window |
| `pin_app` | Pin and unpin an application |
| `desktop_notifications` | Monitor desktop change events |
| `error_handling` | Handle service errors and reconnect |

Run an example:

```console
zig build enumerate_desktops
```

## Documentation

This library wraps the Windows virtual desktop COM interfaces. Only
`IVirtualDesktopManager` is part of the public Windows SDK:

- [IVirtualDesktopManager](https://learn.microsoft.com/en-us/windows/win32/api/shobjidl_core/nn-shobjidl_core-ivirtualdesktopmanager)

The remaining interfaces (`IVirtualDesktopManagerInternal`,
`IApplicationViewCollection`, `IVirtualDesktopPinnedApps`,
`IVirtualDesktopNotificationService`, and others) are undocumented internal
shell interfaces. Their method layouts and GUIDs change between Windows builds
and were reverse-engineered with reference to the project below.

## Acknowledgments

This project references the COM interface definitions and GUIDs from
[VirtualDesktopAccessor](https://github.com/Ciantic/VirtualDesktopAccessor) by
Jari Pennanen.

## License

[MIT](LICENSE.md)

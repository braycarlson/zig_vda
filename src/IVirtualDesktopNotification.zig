const std = @import("std");
const com = @import("com.zig");
const guid = @import("guid.zig");
const vd = @import("vd.zig");

const GUID = guid.GUID;
const HRESULT = vd.HRESULT;
const HSTRING = com.HSTRING;
const IVirtualDesktop = @import("IVirtualDesktop.zig").IVirtualDesktop;
const IApplicationView = @import("IApplicationView.zig").IApplicationView;
const ApplicationViewChange = @import("IApplicationViewChangeListener.zig").ApplicationViewChange;
const MultitaskingViewType = @import("IMultitaskingViewVisibilityService.zig").MultitaskingViewType;

pub const NotificationCallback = struct {
    onDesktopCreated: ?*const fn (GUID) void = null,
    onDesktopDestroyBegin: ?*const fn (GUID, GUID) void = null,
    onDesktopDestroyFailed: ?*const fn (GUID, GUID) void = null,
    onDesktopDestroyed: ?*const fn (GUID, GUID) void = null,
    onDesktopChanged: ?*const fn (GUID, GUID) void = null,
    onDesktopSwitched: ?*const fn (GUID, u32) void = null,
    onDesktopNameChanged: ?*const fn (GUID, []const u8) void = null,
    onDesktopWallpaperChanged: ?*const fn (GUID, []const u8) void = null,
    onDesktopMoved: ?*const fn (GUID, u32, u32) void = null,
    onRemoteDesktopConnected: ?*const fn (GUID) void = null,
    onWindowDesktopChanged: ?*const fn (isize, GUID) void = null,
    onWindowEvent: ?*const fn (isize, ApplicationViewChange) void = null,
    onMultitaskingViewShown: ?*const fn (MultitaskingViewType) void = null,
    onMultitaskingViewDismissed: ?*const fn (MultitaskingViewType) void = null,
};

pub const IVirtualDesktopNotificationVtbl = extern struct {
    QueryInterface: *const fn (*VirtualDesktopNotification, *const GUID, *?*anyopaque) callconv(.winapi) HRESULT,
    AddRef: *const fn (*VirtualDesktopNotification) callconv(.winapi) u32,
    Release: *const fn (*VirtualDesktopNotification) callconv(.winapi) u32,
    VirtualDesktopCreated: *const fn (*VirtualDesktopNotification, *IVirtualDesktop) callconv(.winapi) HRESULT,
    VirtualDesktopDestroyBegin: *const fn (*VirtualDesktopNotification, *IVirtualDesktop, *IVirtualDesktop) callconv(.winapi) HRESULT,
    VirtualDesktopDestroyFailed: *const fn (*VirtualDesktopNotification, *IVirtualDesktop, *IVirtualDesktop) callconv(.winapi) HRESULT,
    VirtualDesktopDestroyed: *const fn (*VirtualDesktopNotification, *IVirtualDesktop, *IVirtualDesktop) callconv(.winapi) HRESULT,
    VirtualDesktopMoved: *const fn (*VirtualDesktopNotification, *IVirtualDesktop, u32, u32) callconv(.winapi) HRESULT,
    VirtualDesktopNameChanged: *const fn (*VirtualDesktopNotification, *IVirtualDesktop, HSTRING) callconv(.winapi) HRESULT,
    ViewVirtualDesktopChanged: *const fn (*VirtualDesktopNotification, *IApplicationView) callconv(.winapi) HRESULT,
    CurrentVirtualDesktopChanged: *const fn (*VirtualDesktopNotification, *IVirtualDesktop, *IVirtualDesktop) callconv(.winapi) HRESULT,
    VirtualDesktopWallpaperChanged: *const fn (*VirtualDesktopNotification, *IVirtualDesktop, HSTRING) callconv(.winapi) HRESULT,
    VirtualDesktopSwitched: *const fn (*VirtualDesktopNotification, *IVirtualDesktop, u32) callconv(.winapi) HRESULT,
    RemoteVirtualDesktopConnected: *const fn (*VirtualDesktopNotification, *IVirtualDesktop) callconv(.winapi) HRESULT,
};

pub const VirtualDesktopNotification = extern struct {
    vtable: *const IVirtualDesktopNotificationVtbl,
    ref_count: i32,
    callback: *const NotificationCallback,

    pub fn init(callback: *const NotificationCallback) VirtualDesktopNotification {
        return .{
            .vtable = &vtable_instance,
            .ref_count = 1,
            .callback = callback,
        };
    }

    fn desktopId(desktop: *IVirtualDesktop) GUID {
        return desktop.getId() catch GUID.ZERO;
    }

    fn queryInterface(self: *VirtualDesktopNotification, riid: *const GUID, ppv: *?*anyopaque) callconv(.winapi) HRESULT {
        if (riid.eql(guid.IID_IUnknown) or riid.eql(guid.IID_IVirtualDesktopNotification)) {
            ppv.* = self;
            _ = @atomicRmw(i32, &self.ref_count, .Add, 1, .monotonic);

            return 0;
        }

        ppv.* = null;
        return @bitCast(@as(u32, 0x80004002));
    }

    fn addRef(self: *VirtualDesktopNotification) callconv(.winapi) u32 {
        const old = @atomicRmw(i32, &self.ref_count, .Add, 1, .monotonic);
        return @intCast(old + 1);
    }

    fn releaseRef(self: *VirtualDesktopNotification) callconv(.winapi) u32 {
        const old = @atomicRmw(i32, &self.ref_count, .Sub, 1, .release);
        return @intCast(old - 1);
    }

    fn onDesktopCreated(self: *VirtualDesktopNotification, desktop: *IVirtualDesktop) callconv(.winapi) HRESULT {
        if (self.callback.onDesktopCreated) |cb| cb(desktopId(desktop));
        return 0;
    }

    fn onDestroyBegin(self: *VirtualDesktopNotification, destroyed: *IVirtualDesktop, fallback: *IVirtualDesktop) callconv(.winapi) HRESULT {
        if (self.callback.onDesktopDestroyBegin) |cb| cb(desktopId(destroyed), desktopId(fallback));
        return 0;
    }

    fn onDestroyFailed(self: *VirtualDesktopNotification, destroyed: *IVirtualDesktop, fallback: *IVirtualDesktop) callconv(.winapi) HRESULT {
        if (self.callback.onDesktopDestroyFailed) |cb| cb(desktopId(destroyed), desktopId(fallback));
        return 0;
    }

    fn onDesktopDestroyed(self: *VirtualDesktopNotification, destroyed: *IVirtualDesktop, fallback: *IVirtualDesktop) callconv(.winapi) HRESULT {
        if (self.callback.onDesktopDestroyed) |cb| cb(desktopId(destroyed), desktopId(fallback));
        return 0;
    }

    fn onDesktopMoved(self: *VirtualDesktopNotification, desktop: *IVirtualDesktop, old_index: u32, new_index: u32) callconv(.winapi) HRESULT {
        if (self.callback.onDesktopMoved) |cb| cb(desktopId(desktop), old_index, new_index);
        return 0;
    }

    fn onNameChanged(self: *VirtualDesktopNotification, desktop: *IVirtualDesktop, name: HSTRING) callconv(.winapi) HRESULT {
        if (self.callback.onDesktopNameChanged) |cb| {
            var buf: [com.HSTRING_UTF8_MAX]u8 = undefined;
            cb(desktopId(desktop), com.hstringToUtf8Truncated(name, &buf));
        }

        return 0;
    }

    fn onViewChanged(self: *VirtualDesktopNotification, view: *IApplicationView) callconv(.winapi) HRESULT {
        if (self.callback.onWindowDesktopChanged) |cb| {
            const handle = view.getThumbnailWindow() catch 0;
            const desktop_id = view.getVirtualDesktopId() catch GUID.ZERO;
            cb(handle, desktop_id);
        }

        return 0;
    }

    fn onDesktopChanged(self: *VirtualDesktopNotification, old: *IVirtualDesktop, new: *IVirtualDesktop) callconv(.winapi) HRESULT {
        if (self.callback.onDesktopChanged) |cb| cb(desktopId(old), desktopId(new));
        return 0;
    }

    fn onWallpaperChanged(self: *VirtualDesktopNotification, desktop: *IVirtualDesktop, path: HSTRING) callconv(.winapi) HRESULT {
        if (self.callback.onDesktopWallpaperChanged) |cb| {
            var buf: [com.HSTRING_UTF8_MAX]u8 = undefined;
            cb(desktopId(desktop), com.hstringToUtf8Truncated(path, &buf));
        }

        return 0;
    }

    fn onDesktopSwitched(self: *VirtualDesktopNotification, desktop: *IVirtualDesktop, switch_type: u32) callconv(.winapi) HRESULT {
        if (self.callback.onDesktopSwitched) |cb| cb(desktopId(desktop), switch_type);
        return 0;
    }

    fn onRemoteConnected(self: *VirtualDesktopNotification, desktop: *IVirtualDesktop) callconv(.winapi) HRESULT {
        if (self.callback.onRemoteDesktopConnected) |cb| cb(desktopId(desktop));
        return 0;
    }

    const vtable_instance = IVirtualDesktopNotificationVtbl{
        .QueryInterface = @ptrCast(&queryInterface),
        .AddRef = @ptrCast(&addRef),
        .Release = @ptrCast(&releaseRef),
        .VirtualDesktopCreated = @ptrCast(&onDesktopCreated),
        .VirtualDesktopDestroyBegin = @ptrCast(&onDestroyBegin),
        .VirtualDesktopDestroyFailed = @ptrCast(&onDestroyFailed),
        .VirtualDesktopDestroyed = @ptrCast(&onDesktopDestroyed),
        .VirtualDesktopMoved = @ptrCast(&onDesktopMoved),
        .VirtualDesktopNameChanged = @ptrCast(&onNameChanged),
        .ViewVirtualDesktopChanged = @ptrCast(&onViewChanged),
        .CurrentVirtualDesktopChanged = @ptrCast(&onDesktopChanged),
        .VirtualDesktopWallpaperChanged = @ptrCast(&onWallpaperChanged),
        .VirtualDesktopSwitched = @ptrCast(&onDesktopSwitched),
        .RemoteVirtualDesktopConnected = @ptrCast(&onRemoteConnected),
    };
};

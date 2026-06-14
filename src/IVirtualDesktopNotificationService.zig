const std = @import("std");
const com = @import("com.zig");
const vd = @import("vd.zig");

const HRESULT = vd.HRESULT;

const IVirtualDesktopNotificationServiceVtbl = extern struct {
    base: com.IUnknownVtbl,
    Register: *const fn (*IVirtualDesktopNotificationService, *anyopaque, *u32) callconv(.winapi) HRESULT,
    Unregister: *const fn (*IVirtualDesktopNotificationService, u32) callconv(.winapi) HRESULT,
};

pub const IVirtualDesktopNotificationService = extern struct {
    vtable: *const IVirtualDesktopNotificationServiceVtbl,

    pub fn register(self: *IVirtualDesktopNotificationService, notification: *anyopaque) vd.Error!u32 {
        var cookie: u32 = 0;
        const hr = self.vtable.Register(self, notification, &cookie);
        try vd.hresultToError(hr);

        return cookie;
    }

    pub fn unregister(self: *IVirtualDesktopNotificationService, cookie: u32) vd.Error!void {
        const hr = self.vtable.Unregister(self, cookie);
        try vd.hresultToError(hr);
    }
};

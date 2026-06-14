const std = @import("std");
const com = @import("com.zig");
const guid = @import("guid.zig");
const vd = @import("vd.zig");

const GUID = guid.GUID;
const HRESULT = vd.HRESULT;

const IVirtualDesktopManagerVtbl = extern struct {
    base: com.IUnknownVtbl,
    IsWindowOnCurrentVirtualDesktop: *const fn (*IVirtualDesktopManager, isize, *i32) callconv(.winapi) HRESULT,
    GetWindowDesktopId: *const fn (*IVirtualDesktopManager, isize, *GUID) callconv(.winapi) HRESULT,
    MoveWindowToDesktop: *const fn (*IVirtualDesktopManager, isize, *const GUID) callconv(.winapi) HRESULT,
};

pub const IVirtualDesktopManager = extern struct {
    vtable: *const IVirtualDesktopManagerVtbl,

    pub fn isWindowOnCurrentDesktop(self: *IVirtualDesktopManager, handle: isize) vd.Error!bool {
        var result: i32 = 0;
        const hr = self.vtable.IsWindowOnCurrentVirtualDesktop(self, handle, &result);

        vd.hresultToError(hr) catch |err| {
            if (err == vd.Error.DesktopNotFound) return vd.Error.WindowNotFound;
            return err;
        };

        return result != 0;
    }

    pub fn getWindowDesktopId(self: *IVirtualDesktopManager, handle: isize) vd.Error!GUID {
        var id: GUID = GUID.ZERO;
        const hr = self.vtable.GetWindowDesktopId(self, handle, &id);

        vd.hresultToError(hr) catch |err| {
            if (err == vd.Error.DesktopNotFound) return vd.Error.WindowNotFound;
            return err;
        };

        if (id.eql(GUID.ZERO)) return vd.Error.WindowNotFound;
        return id;
    }

    pub fn moveWindowToDesktop(self: *IVirtualDesktopManager, handle: isize, desktop_id: *const GUID) vd.Error!void {
        const hr = self.vtable.MoveWindowToDesktop(self, handle, desktop_id);
        try vd.hresultToError(hr);
    }
};

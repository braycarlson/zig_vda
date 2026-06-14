const std = @import("std");
const com = @import("com.zig");
const guid = @import("guid.zig");
const vd = @import("vd.zig");

const GUID = guid.GUID;
const HRESULT = vd.HRESULT;
const HSTRING = com.HSTRING;
const IObjectArray = @import("IObjectArray.zig").IObjectArray;
const IVirtualDesktop = @import("IVirtualDesktop.zig").IVirtualDesktop;
const IApplicationView = @import("IApplicationView.zig").IApplicationView;

const IVirtualDesktopManagerInternalVtbl = extern struct {
    base: com.IUnknownVtbl,
    GetDesktopCount: *const fn (*IVirtualDesktopManagerInternal, *u32) callconv(.winapi) HRESULT,
    MoveViewToDesktop: *const fn (*IVirtualDesktopManagerInternal, *IApplicationView, *IVirtualDesktop) callconv(.winapi) HRESULT,
    CanMoveViewBetweenDesktops: *const fn (*IVirtualDesktopManagerInternal, *IApplicationView, *i32) callconv(.winapi) HRESULT,
    GetCurrentDesktop: *const fn (*IVirtualDesktopManagerInternal, *?*IVirtualDesktop) callconv(.winapi) HRESULT,
    GetDesktops: *const fn (*IVirtualDesktopManagerInternal, *?*IObjectArray) callconv(.winapi) HRESULT,
    GetAdjacentDesktop: *const fn (*IVirtualDesktopManagerInternal, *IVirtualDesktop, u32, *?*IVirtualDesktop) callconv(.winapi) HRESULT,
    SwitchDesktop: *const fn (*IVirtualDesktopManagerInternal, *IVirtualDesktop) callconv(.winapi) HRESULT,
    SwitchDesktopAndMoveForegroundView: *const fn (*IVirtualDesktopManagerInternal, *IVirtualDesktop) callconv(.winapi) HRESULT,
    CreateDesktop: *const fn (*IVirtualDesktopManagerInternal, *?*IVirtualDesktop) callconv(.winapi) HRESULT,
    MoveDesktop: *const fn (*IVirtualDesktopManagerInternal, *IVirtualDesktop, u32) callconv(.winapi) HRESULT,
    RemoveDesktop: *const fn (*IVirtualDesktopManagerInternal, *IVirtualDesktop, *IVirtualDesktop) callconv(.winapi) HRESULT,
    FindDesktop: *const fn (*IVirtualDesktopManagerInternal, *const GUID, *?*IVirtualDesktop) callconv(.winapi) HRESULT,
    GetDesktopSwitchIncludeExcludeViews: *const fn (*IVirtualDesktopManagerInternal, *IVirtualDesktop, *?*IObjectArray, *?*IObjectArray) callconv(.winapi) HRESULT,
    SetName: *const fn (*IVirtualDesktopManagerInternal, *IVirtualDesktop, HSTRING) callconv(.winapi) HRESULT,
    SetWallpaper: *const fn (*IVirtualDesktopManagerInternal, *IVirtualDesktop, HSTRING) callconv(.winapi) HRESULT,
    UpdateWallpaperForAll: *const fn (*IVirtualDesktopManagerInternal, HSTRING) callconv(.winapi) HRESULT,
};

pub const IVirtualDesktopManagerInternal = extern struct {
    vtable: *const IVirtualDesktopManagerInternalVtbl,

    pub fn getDesktopCount(self: *IVirtualDesktopManagerInternal) vd.Error!u32 {
        var count: u32 = 0;
        const hr = self.vtable.GetDesktopCount(self, &count);
        try vd.hresultToError(hr);

        return count;
    }

    pub fn getCurrentDesktop(self: *IVirtualDesktopManagerInternal) vd.Error!*IVirtualDesktop {
        var desktop: ?*IVirtualDesktop = null;
        const hr = self.vtable.GetCurrentDesktop(self, &desktop);
        try vd.hresultToError(hr);

        return desktop orelse return vd.Error.NullPointer;
    }

    pub fn getDesktops(self: *IVirtualDesktopManagerInternal) vd.Error!*IObjectArray {
        var desktops: ?*IObjectArray = null;
        const hr = self.vtable.GetDesktops(self, &desktops);
        try vd.hresultToError(hr);

        return desktops orelse return vd.Error.NullPointer;
    }

    pub fn switchDesktop(self: *IVirtualDesktopManagerInternal, desktop: *IVirtualDesktop) vd.Error!void {
        const hr = self.vtable.SwitchDesktop(self, desktop);
        try vd.hresultToError(hr);
    }

    pub fn createDesktop(self: *IVirtualDesktopManagerInternal) vd.Error!*IVirtualDesktop {
        var desktop: ?*IVirtualDesktop = null;
        const hr = self.vtable.CreateDesktop(self, &desktop);
        try vd.hresultToError(hr);

        return desktop orelse return vd.Error.NullPointer;
    }

    pub fn removeDesktop(self: *IVirtualDesktopManagerInternal, target: *IVirtualDesktop, fallback: *IVirtualDesktop) vd.Error!void {
        const hr = self.vtable.RemoveDesktop(self, target, fallback);
        try vd.hresultToError(hr);
    }

    pub fn findDesktop(self: *IVirtualDesktopManagerInternal, id: *const GUID) vd.Error!*IVirtualDesktop {
        var desktop: ?*IVirtualDesktop = null;
        const hr = self.vtable.FindDesktop(self, id, &desktop);
        try vd.hresultToError(hr);

        return desktop orelse return vd.Error.DesktopNotFound;
    }

    pub fn moveViewToDesktop(self: *IVirtualDesktopManagerInternal, view: *IApplicationView, desktop: *IVirtualDesktop) vd.Error!void {
        const hr = self.vtable.MoveViewToDesktop(self, view, desktop);
        try vd.hresultToError(hr);
    }

    pub fn setName(self: *IVirtualDesktopManagerInternal, desktop: *IVirtualDesktop, name: HSTRING) vd.Error!void {
        const hr = self.vtable.SetName(self, desktop, name);
        try vd.hresultToError(hr);
    }

    pub fn setWallpaper(self: *IVirtualDesktopManagerInternal, desktop: *IVirtualDesktop, path: HSTRING) vd.Error!void {
        const hr = self.vtable.SetWallpaper(self, desktop, path);
        try vd.hresultToError(hr);
    }
};

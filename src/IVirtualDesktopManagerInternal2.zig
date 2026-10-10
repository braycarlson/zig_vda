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

pub const AdjacentDirection = enum(u32) {
    left = 3,
    right = 4,
    forward = 5,
    backward = 6,
};

const IVirtualDesktopManagerInternal2Vtbl = extern struct {
    base: com.IUnknownVtbl,
    GetCount: *const fn (*IVirtualDesktopManagerInternal2, *u32) callconv(.winapi) HRESULT,
    MoveViewToDesktop: *const fn (*IVirtualDesktopManagerInternal2, *IApplicationView, *IVirtualDesktop) callconv(.winapi) HRESULT,
    CanViewMoveDesktops: *const fn (*IVirtualDesktopManagerInternal2, *IApplicationView, *i32) callconv(.winapi) HRESULT,
    GetCurrentDesktop: *const fn (*IVirtualDesktopManagerInternal2, *?*IVirtualDesktop) callconv(.winapi) HRESULT,
    GetDesktops: *const fn (*IVirtualDesktopManagerInternal2, *?*IObjectArray) callconv(.winapi) HRESULT,
    GetAdjacentDesktop: *const fn (*IVirtualDesktopManagerInternal2, ?*IVirtualDesktop, AdjacentDirection, *?*IVirtualDesktop) callconv(.winapi) HRESULT,
    SwitchDesktop: *const fn (*IVirtualDesktopManagerInternal2, *IVirtualDesktop) callconv(.winapi) HRESULT,
    SwitchDesktopAndMoveForegroundView: *const fn (*IVirtualDesktopManagerInternal2, *IVirtualDesktop) callconv(.winapi) HRESULT,
    CreateDesktop: *const fn (*IVirtualDesktopManagerInternal2, *?*IVirtualDesktop) callconv(.winapi) HRESULT,
    MoveDesktop: *const fn (*IVirtualDesktopManagerInternal2, *IVirtualDesktop, u32) callconv(.winapi) HRESULT,
    RemoveDesktop: *const fn (*IVirtualDesktopManagerInternal2, *IVirtualDesktop, *IVirtualDesktop) callconv(.winapi) HRESULT,
    FindDesktop: *const fn (*IVirtualDesktopManagerInternal2, *const GUID, *?*IVirtualDesktop) callconv(.winapi) HRESULT,
    GetDesktopSwitchIncludeExcludeViews: *const fn (*IVirtualDesktopManagerInternal2, *IVirtualDesktop, *?*IObjectArray, *?*IObjectArray) callconv(.winapi) HRESULT,
    SetDesktopName: *const fn (*IVirtualDesktopManagerInternal2, *IVirtualDesktop, HSTRING) callconv(.winapi) HRESULT,
    SetDesktopWallpaper: *const fn (*IVirtualDesktopManagerInternal2, *IVirtualDesktop, HSTRING) callconv(.winapi) HRESULT,
    UpdateWallpaperPathForAllDesktops: *const fn (*IVirtualDesktopManagerInternal2, HSTRING) callconv(.winapi) HRESULT,
    CopyDesktopState: *const fn (*IVirtualDesktopManagerInternal2, *IApplicationView, *IApplicationView) callconv(.winapi) HRESULT,
    CreateRemoteDesktop: *const fn (*IVirtualDesktopManagerInternal2, HSTRING, *?*IVirtualDesktop) callconv(.winapi) HRESULT,
    SwitchRemoteDesktop: *const fn (*IVirtualDesktopManagerInternal2, *IVirtualDesktop, u32) callconv(.winapi) HRESULT,
    SwitchDesktopWithAnimation: *const fn (*IVirtualDesktopManagerInternal2, *IVirtualDesktop) callconv(.winapi) HRESULT,
    GetLastActiveDesktop: *const fn (*IVirtualDesktopManagerInternal2, *?*IVirtualDesktop) callconv(.winapi) HRESULT,
    WaitForAnimationToComplete: *const fn (*IVirtualDesktopManagerInternal2) callconv(.winapi) HRESULT,
};

pub const IVirtualDesktopManagerInternal2 = extern struct {
    vtable: *const IVirtualDesktopManagerInternal2Vtbl,

    pub fn getDesktopCount(self: *IVirtualDesktopManagerInternal2) vd.Error!u32 {
        var count: u32 = 0;
        const hr = self.vtable.GetCount(self, &count);
        try vd.hresultToError(hr);

        return count;
    }

    pub fn getCurrentDesktop(self: *IVirtualDesktopManagerInternal2) vd.Error!*IVirtualDesktop {
        var desktop: ?*IVirtualDesktop = null;
        const hr = self.vtable.GetCurrentDesktop(self, &desktop);
        try vd.hresultToError(hr);

        return desktop orelse return vd.Error.NullPointer;
    }

    pub fn getDesktops(self: *IVirtualDesktopManagerInternal2) vd.Error!*IObjectArray {
        var desktops: ?*IObjectArray = null;
        const hr = self.vtable.GetDesktops(self, &desktops);
        try vd.hresultToError(hr);

        return desktops orelse return vd.Error.NullPointer;
    }

    pub fn getAdjacentDesktop(self: *IVirtualDesktopManagerInternal2, desktop: ?*IVirtualDesktop, direction: AdjacentDirection) vd.Error!*IVirtualDesktop {
        var adjacent: ?*IVirtualDesktop = null;
        const hr = self.vtable.GetAdjacentDesktop(self, desktop, direction, &adjacent);
        try vd.hresultToError(hr);

        return adjacent orelse return vd.Error.DesktopNotFound;
    }

    pub fn switchDesktop(self: *IVirtualDesktopManagerInternal2, desktop: *IVirtualDesktop) vd.Error!void {
        const hr = self.vtable.SwitchDesktop(self, desktop);
        try vd.hresultToError(hr);
    }

    pub fn switchDesktopAndMoveForegroundView(self: *IVirtualDesktopManagerInternal2, desktop: *IVirtualDesktop) vd.Error!void {
        const hr = self.vtable.SwitchDesktopAndMoveForegroundView(self, desktop);
        try vd.hresultToError(hr);
    }

    pub fn switchDesktopWithAnimation(self: *IVirtualDesktopManagerInternal2, desktop: *IVirtualDesktop) vd.Error!void {
        const hr = self.vtable.SwitchDesktopWithAnimation(self, desktop);
        try vd.hresultToError(hr);
    }

    pub fn waitForAnimationToComplete(self: *IVirtualDesktopManagerInternal2) vd.Error!void {
        const hr = self.vtable.WaitForAnimationToComplete(self);
        try vd.hresultToError(hr);
    }

    pub fn getLastActiveDesktop(self: *IVirtualDesktopManagerInternal2) vd.Error!*IVirtualDesktop {
        var desktop: ?*IVirtualDesktop = null;
        const hr = self.vtable.GetLastActiveDesktop(self, &desktop);
        try vd.hresultToError(hr);

        return desktop orelse return vd.Error.DesktopNotFound;
    }

    pub fn createDesktop(self: *IVirtualDesktopManagerInternal2) vd.Error!*IVirtualDesktop {
        var desktop: ?*IVirtualDesktop = null;
        const hr = self.vtable.CreateDesktop(self, &desktop);
        try vd.hresultToError(hr);

        return desktop orelse return vd.Error.NullPointer;
    }

    pub fn moveDesktop(self: *IVirtualDesktopManagerInternal2, desktop: *IVirtualDesktop, index: u32) vd.Error!void {
        const hr = self.vtable.MoveDesktop(self, desktop, index);
        try vd.hresultToError(hr);
    }

    pub fn removeDesktop(self: *IVirtualDesktopManagerInternal2, target: *IVirtualDesktop, fallback: *IVirtualDesktop) vd.Error!void {
        const hr = self.vtable.RemoveDesktop(self, target, fallback);
        try vd.hresultToError(hr);
    }

    pub fn findDesktop(self: *IVirtualDesktopManagerInternal2, id: *const GUID) vd.Error!*IVirtualDesktop {
        var desktop: ?*IVirtualDesktop = null;
        const hr = self.vtable.FindDesktop(self, id, &desktop);
        try vd.hresultToError(hr);

        return desktop orelse return vd.Error.DesktopNotFound;
    }

    pub fn canViewMoveDesktops(self: *IVirtualDesktopManagerInternal2, view: *IApplicationView) vd.Error!bool {
        var can_move: i32 = 0;
        const hr = self.vtable.CanViewMoveDesktops(self, view, &can_move);
        try vd.hresultToError(hr);

        return can_move != 0;
    }

    pub fn moveViewToDesktop(self: *IVirtualDesktopManagerInternal2, view: *IApplicationView, desktop: *IVirtualDesktop) vd.Error!void {
        const hr = self.vtable.MoveViewToDesktop(self, view, desktop);
        try vd.hresultToError(hr);
    }

    pub fn setName(self: *IVirtualDesktopManagerInternal2, desktop: *IVirtualDesktop, name: HSTRING) vd.Error!void {
        const hr = self.vtable.SetDesktopName(self, desktop, name);
        try vd.hresultToError(hr);
    }

    pub fn setWallpaper(self: *IVirtualDesktopManagerInternal2, desktop: *IVirtualDesktop, path: HSTRING) vd.Error!void {
        const hr = self.vtable.SetDesktopWallpaper(self, desktop, path);
        try vd.hresultToError(hr);
    }
};

const std = @import("std");
const com = @import("com.zig");
const vd = @import("vd.zig");

const HRESULT = vd.HRESULT;
const IObjectArray = @import("IObjectArray.zig").IObjectArray;
const IApplicationView = @import("IApplicationView.zig").IApplicationView;

const IApplicationViewCollectionVtbl = extern struct {
    base: com.IUnknownVtbl,
    GetViews: *const fn (*IApplicationViewCollection, *?*IObjectArray) callconv(.winapi) HRESULT,
    GetViewsByZOrder: *const fn (*IApplicationViewCollection, *?*IObjectArray) callconv(.winapi) HRESULT,
    GetViewsByAppUserModelId: *const fn (*IApplicationViewCollection, [*:0]const u16, *?*IObjectArray) callconv(.winapi) HRESULT,
    GetViewForHwnd: *const fn (*IApplicationViewCollection, isize, *?*IApplicationView) callconv(.winapi) HRESULT,
    GetViewForApplication: *const fn (*IApplicationViewCollection, ?*anyopaque, *?*IApplicationView) callconv(.winapi) HRESULT,
    GetViewForAppUserModelId: *const fn (*IApplicationViewCollection, [*:0]const u16, *?*IApplicationView) callconv(.winapi) HRESULT,
    GetViewInFocus: *const fn (*IApplicationViewCollection, *?*IApplicationView) callconv(.winapi) HRESULT,
    TryGetLastActiveVisibleView: *const fn (*IApplicationViewCollection, *?*IApplicationView) callconv(.winapi) HRESULT,
    RefreshCollection: *const fn (*IApplicationViewCollection) callconv(.winapi) HRESULT,
    RegisterForApplicationViewChanges: *const fn (*IApplicationViewCollection, *anyopaque, *u32) callconv(.winapi) HRESULT,
    UnregisterForApplicationViewChanges: *const fn (*IApplicationViewCollection, u32) callconv(.winapi) HRESULT,
};

pub const IApplicationViewCollection = extern struct {
    vtable: *const IApplicationViewCollectionVtbl,

    pub fn getViewForHwnd(self: *IApplicationViewCollection, handle: isize) vd.Error!*IApplicationView {
        var view: ?*IApplicationView = null;
        const hr = self.vtable.GetViewForHwnd(self, handle, &view);

        vd.hresultToError(hr) catch |err| {
            if (err == vd.Error.DesktopNotFound) return vd.Error.WindowNotFound;
            return err;
        };

        return view orelse return vd.Error.WindowNotFound;
    }

    pub fn registerForApplicationViewChanges(self: *IApplicationViewCollection, listener: *anyopaque) vd.Error!u32 {
        var cookie: u32 = 0;
        const hr = self.vtable.RegisterForApplicationViewChanges(self, listener, &cookie);
        try vd.hresultToError(hr);

        return cookie;
    }

    pub fn unregisterForApplicationViewChanges(self: *IApplicationViewCollection, cookie: u32) vd.Error!void {
        const hr = self.vtable.UnregisterForApplicationViewChanges(self, cookie);
        try vd.hresultToError(hr);
    }
};

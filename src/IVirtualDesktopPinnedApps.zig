const com = @import("com.zig");
const vd = @import("vd.zig");

const HRESULT = vd.HRESULT;
const IApplicationView = @import("IApplicationView.zig").IApplicationView;

const IVirtualDesktopPinnedAppsVtbl = extern struct {
    base: com.IUnknownVtbl,
    IsAppIdPinned: *const fn (*IVirtualDesktopPinnedApps, [*:0]const u16, *i32) callconv(.winapi) HRESULT,
    PinAppID: *const fn (*IVirtualDesktopPinnedApps, [*:0]const u16) callconv(.winapi) HRESULT,
    UnpinAppID: *const fn (*IVirtualDesktopPinnedApps, [*:0]const u16) callconv(.winapi) HRESULT,
    IsViewPinned: *const fn (*IVirtualDesktopPinnedApps, *IApplicationView, *i32) callconv(.winapi) HRESULT,
    PinView: *const fn (*IVirtualDesktopPinnedApps, *IApplicationView) callconv(.winapi) HRESULT,
    UnpinView: *const fn (*IVirtualDesktopPinnedApps, *IApplicationView) callconv(.winapi) HRESULT,
};

pub const IVirtualDesktopPinnedApps = extern struct {
    vtable: *const IVirtualDesktopPinnedAppsVtbl,

    pub fn isAppPinned(self: *IVirtualDesktopPinnedApps, app_id: [*:0]const u16) vd.Error!bool {
        var pinned: i32 = 0;
        const hr = self.vtable.IsAppIdPinned(self, app_id, &pinned);
        try vd.hresultToError(hr);
        return pinned != 0;
    }

    pub fn pinApp(self: *IVirtualDesktopPinnedApps, app_id: [*:0]const u16) vd.Error!void {
        const hr = self.vtable.PinAppID(self, app_id);
        try vd.hresultToError(hr);
    }

    pub fn unpinApp(self: *IVirtualDesktopPinnedApps, app_id: [*:0]const u16) vd.Error!void {
        const hr = self.vtable.UnpinAppID(self, app_id);
        try vd.hresultToError(hr);
    }

    pub fn isViewPinned(self: *IVirtualDesktopPinnedApps, view: *IApplicationView) vd.Error!bool {
        var pinned: i32 = 0;
        const hr = self.vtable.IsViewPinned(self, view, &pinned);
        try vd.hresultToError(hr);
        return pinned != 0;
    }

    pub fn pinView(self: *IVirtualDesktopPinnedApps, view: *IApplicationView) vd.Error!void {
        const hr = self.vtable.PinView(self, view);
        try vd.hresultToError(hr);
    }

    pub fn unpinView(self: *IVirtualDesktopPinnedApps, view: *IApplicationView) vd.Error!void {
        const hr = self.vtable.UnpinView(self, view);
        try vd.hresultToError(hr);
    }
};

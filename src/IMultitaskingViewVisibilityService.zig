const com = @import("com.zig");
const vd = @import("vd.zig");

const HRESULT = vd.HRESULT;

pub const MultitaskingViewType = enum(u32) {
    alt_tab = 0x1,
    task_view = 0x2,
    virtual_desktop_switcher = 0x10,
    _,
};

const IMultitaskingViewVisibilityServiceVtbl = extern struct {
    base: com.IUnknownVtbl,
    IsViewVisible: *const fn (*IMultitaskingViewVisibilityService, u32, *u32) callconv(.winapi) HRESULT,
    Register: *const fn (*IMultitaskingViewVisibilityService, *anyopaque, *u32) callconv(.winapi) HRESULT,
    Unregister: *const fn (*IMultitaskingViewVisibilityService, u32) callconv(.winapi) HRESULT,
};

pub const IMultitaskingViewVisibilityService = extern struct {
    vtable: *const IMultitaskingViewVisibilityServiceVtbl,

    pub fn isViewVisible(self: *IMultitaskingViewVisibilityService, mask: u32) vd.Error!u32 {
        var visible: u32 = 0;
        const hr = self.vtable.IsViewVisible(self, mask, &visible);
        try vd.hresultToError(hr);

        return visible;
    }

    pub fn register(self: *IMultitaskingViewVisibilityService, notification: *anyopaque) vd.Error!u32 {
        var cookie: u32 = 0;
        const hr = self.vtable.Register(self, notification, &cookie);
        try vd.hresultToError(hr);

        return cookie;
    }

    pub fn unregister(self: *IMultitaskingViewVisibilityService, cookie: u32) vd.Error!void {
        const hr = self.vtable.Unregister(self, cookie);
        try vd.hresultToError(hr);
    }
};

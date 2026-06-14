const com = @import("com.zig");
const guid = @import("guid.zig");
const vd = @import("vd.zig");

const GUID = guid.GUID;
const HRESULT = vd.HRESULT;
const HSTRING = com.HSTRING;
const IApplicationView = @import("IApplicationView.zig").IApplicationView;

const IVirtualDesktopVtbl = extern struct {
    base: com.IUnknownVtbl,
    IsViewVisible: *const fn (*IVirtualDesktop, *IApplicationView, *u32) callconv(.winapi) HRESULT,
    GetId: *const fn (*IVirtualDesktop, *GUID) callconv(.winapi) HRESULT,
    GetName: *const fn (*IVirtualDesktop, *HSTRING) callconv(.winapi) HRESULT,
    GetWallpaper: *const fn (*IVirtualDesktop, *HSTRING) callconv(.winapi) HRESULT,
};

pub const IVirtualDesktop = extern struct {
    vtable: *const IVirtualDesktopVtbl,

    pub fn getId(self: *IVirtualDesktop) vd.Error!GUID {
        var id: GUID = GUID.ZERO;
        const hr = self.vtable.GetId(self, &id);
        try vd.hresultToError(hr);

        return id;
    }

    pub fn getName(self: *IVirtualDesktop, buf: []u8) vd.Error![]const u8 {
        var name: HSTRING = null;
        const hr = self.vtable.GetName(self, &name);
        try vd.hresultToError(hr);
        defer com.deleteHString(name);

        return com.hstringToUtf8(name, buf);
    }

    pub fn getWallpaper(self: *IVirtualDesktop, buf: []u8) vd.Error![]const u8 {
        var path: HSTRING = null;
        const hr = self.vtable.GetWallpaper(self, &path);
        try vd.hresultToError(hr);
        defer com.deleteHString(path);

        return com.hstringToUtf8(path, buf);
    }
};

const com = @import("com.zig");
const guid = @import("guid.zig");
const vd = @import("vd.zig");

const GUID = guid.GUID;
const HRESULT = vd.HRESULT;
const HSTRING = com.HSTRING;
const IApplicationView = @import("IApplicationView.zig").IApplicationView;

const IVirtualDesktop2Vtbl = extern struct {
    base: com.IUnknownVtbl,
    IsViewVisible: *const fn (*IVirtualDesktop2, *IApplicationView, *i32) callconv(.winapi) HRESULT,
    GetID: *const fn (*IVirtualDesktop2, *GUID) callconv(.winapi) HRESULT,
    GetName: *const fn (*IVirtualDesktop2, *HSTRING) callconv(.winapi) HRESULT,
    GetWallpaper: *const fn (*IVirtualDesktop2, *HSTRING) callconv(.winapi) HRESULT,
    IsRemote: *const fn (*IVirtualDesktop2, *i32) callconv(.winapi) HRESULT,
};

pub const IVirtualDesktop2 = extern struct {
    vtable: *const IVirtualDesktop2Vtbl,

    pub fn isRemote(self: *IVirtualDesktop2) vd.Error!bool {
        var remote: i32 = 0;
        const hr = self.vtable.IsRemote(self, &remote);
        try vd.hresultToError(hr);

        return remote != 0;
    }
};

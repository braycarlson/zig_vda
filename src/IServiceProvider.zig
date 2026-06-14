const com = @import("com.zig");
const guid = @import("guid.zig");
const vd = @import("vd.zig");

const GUID = guid.GUID;
const HRESULT = vd.HRESULT;

const IServiceProviderVtbl = extern struct {
    base: com.IUnknownVtbl,
    QueryService: *const fn (*IServiceProvider, *const GUID, *const GUID, *?*anyopaque) callconv(.winapi) HRESULT,
};

pub const IServiceProvider = extern struct {
    vtable: *const IServiceProviderVtbl,

    pub fn queryService(self: *IServiceProvider, comptime T: type, service: *const GUID, iid: *const GUID) vd.Error!*T {
        var obj: ?*anyopaque = null;
        const hr = self.vtable.QueryService(self, service, iid, &obj);
        try vd.hresultToError(hr);

        return @ptrCast(@alignCast(obj orelse return vd.Error.NullPointer));
    }
};

const com = @import("com.zig");
const guid = @import("guid.zig");
const vd = @import("vd.zig");

const GUID = guid.GUID;
const HRESULT = vd.HRESULT;

const IObjectArrayVtbl = extern struct {
    base: com.IUnknownVtbl,
    GetCount: *const fn (*IObjectArray, *u32) callconv(.winapi) HRESULT,
    GetAt: *const fn (*IObjectArray, u32, *const GUID, *?*anyopaque) callconv(.winapi) HRESULT,
};

pub const IObjectArray = extern struct {
    vtable: *const IObjectArrayVtbl,

    pub fn getCount(self: *IObjectArray) vd.Error!u32 {
        var count: u32 = 0;
        const hr = self.vtable.GetCount(self, &count);
        try vd.hresultToError(hr);

        return count;
    }

    pub fn getAt(self: *IObjectArray, comptime T: type, index: u32, iid: *const GUID) vd.Error!*T {
        var obj: ?*anyopaque = null;
        const hr = self.vtable.GetAt(self, index, iid, &obj);
        try vd.hresultToError(hr);

        return @ptrCast(@alignCast(obj orelse return vd.Error.NullPointer));
    }
};

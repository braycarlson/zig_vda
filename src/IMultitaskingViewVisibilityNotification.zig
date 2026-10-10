const guid = @import("guid.zig");
const vd = @import("vd.zig");

const GUID = guid.GUID;
const HRESULT = vd.HRESULT;
const MultitaskingViewType = @import("IMultitaskingViewVisibilityService.zig").MultitaskingViewType;
const NotificationCallback = @import("IVirtualDesktopNotification.zig").NotificationCallback;

pub const IMultitaskingViewVisibilityNotificationVtbl = extern struct {
    QueryInterface: *const fn (*MultitaskingViewVisibilityNotification, *const GUID, *?*anyopaque) callconv(.winapi) HRESULT,
    AddRef: *const fn (*MultitaskingViewVisibilityNotification) callconv(.winapi) u32,
    Release: *const fn (*MultitaskingViewVisibilityNotification) callconv(.winapi) u32,
    MultitaskingViewShown: *const fn (*MultitaskingViewVisibilityNotification, MultitaskingViewType) callconv(.winapi) HRESULT,
    MultitaskingViewDismissed: *const fn (*MultitaskingViewVisibilityNotification, MultitaskingViewType) callconv(.winapi) HRESULT,
};

pub const MultitaskingViewVisibilityNotification = extern struct {
    vtable: *const IMultitaskingViewVisibilityNotificationVtbl,
    ref_count: i32,
    callback: *const NotificationCallback,

    pub fn init(callback: *const NotificationCallback) MultitaskingViewVisibilityNotification {
        return .{
            .vtable = &vtable_instance,
            .ref_count = 1,
            .callback = callback,
        };
    }

    fn queryInterface(self: *MultitaskingViewVisibilityNotification, riid: *const GUID, ppv: *?*anyopaque) callconv(.winapi) HRESULT {
        if (riid.eql(guid.IID_IUnknown) or riid.eql(guid.IID_IMultitaskingViewVisibilityNotification)) {
            ppv.* = self;
            _ = @atomicRmw(i32, &self.ref_count, .Add, 1, .monotonic);

            return 0;
        }

        ppv.* = null;
        return @bitCast(@as(u32, 0x80004002));
    }

    fn addRef(self: *MultitaskingViewVisibilityNotification) callconv(.winapi) u32 {
        const old = @atomicRmw(i32, &self.ref_count, .Add, 1, .monotonic);
        return @intCast(old + 1);
    }

    fn releaseRef(self: *MultitaskingViewVisibilityNotification) callconv(.winapi) u32 {
        const old = @atomicRmw(i32, &self.ref_count, .Sub, 1, .release);
        return @intCast(old - 1);
    }

    fn onShown(self: *MultitaskingViewVisibilityNotification, view_type: MultitaskingViewType) callconv(.winapi) HRESULT {
        if (self.callback.onMultitaskingViewShown) |cb| cb(view_type);
        return 0;
    }

    fn onDismissed(self: *MultitaskingViewVisibilityNotification, view_type: MultitaskingViewType) callconv(.winapi) HRESULT {
        if (self.callback.onMultitaskingViewDismissed) |cb| cb(view_type);
        return 0;
    }

    const vtable_instance = IMultitaskingViewVisibilityNotificationVtbl{
        .QueryInterface = &queryInterface,
        .AddRef = &addRef,
        .Release = &releaseRef,
        .MultitaskingViewShown = &onShown,
        .MultitaskingViewDismissed = &onDismissed,
    };
};

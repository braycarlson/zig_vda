const com = @import("com.zig");
const guid = @import("guid.zig");
const vd = @import("vd.zig");

const GUID = guid.GUID;
const HRESULT = vd.HRESULT;
const IApplicationView = @import("IApplicationView.zig").IApplicationView;
const NotificationCallback = @import("IVirtualDesktopNotification.zig").NotificationCallback;

pub const ApplicationViewChange = enum(u32) {
    added = 0,
    removed = 1,
    forgotten = 2,
    visible = 3,
    hidden = 4,
    neediness = 6,
    focus = 7,
    pending_focus = 8,
    unfocus = 9,
    show_in_switchers = 10,
    removed_from_switchers = 11,
    thumbnail_window = 12,
    monitor_changed = 13,
    window_changed = 14,
    size_constraints = 15,
    tray_changed = 16,
    owner_changed = 17,
    enterprise_id_changed = 18,
    enterprise_chrome_preference_changed = 19,
    can_tab = 20,
    _,
};

pub const IApplicationViewChangeListenerVtbl = extern struct {
    QueryInterface: *const fn (*ApplicationViewChangeListener, *const GUID, *?*anyopaque) callconv(.winapi) HRESULT,
    AddRef: *const fn (*ApplicationViewChangeListener) callconv(.winapi) u32,
    Release: *const fn (*ApplicationViewChangeListener) callconv(.winapi) u32,
    OnApplicationViewChanged: *const fn (*ApplicationViewChangeListener, *IApplicationView, ApplicationViewChange, ?*com.IUnknown) callconv(.winapi) HRESULT,
};

pub const ApplicationViewChangeListener = extern struct {
    vtable: *const IApplicationViewChangeListenerVtbl,
    ref_count: i32,
    callback: *const NotificationCallback,

    pub fn init(callback: *const NotificationCallback) ApplicationViewChangeListener {
        return .{
            .vtable = &vtable_instance,
            .ref_count = 1,
            .callback = callback,
        };
    }

    fn queryInterface(self: *ApplicationViewChangeListener, riid: *const GUID, ppv: *?*anyopaque) callconv(.winapi) HRESULT {
        if (riid.eql(guid.IID_IUnknown) or riid.eql(guid.IID_IApplicationViewChangeListener)) {
            ppv.* = self;
            _ = @atomicRmw(i32, &self.ref_count, .Add, 1, .monotonic);

            return 0;
        }

        ppv.* = null;
        return @bitCast(@as(u32, 0x80004002));
    }

    fn addRef(self: *ApplicationViewChangeListener) callconv(.winapi) u32 {
        const old = @atomicRmw(i32, &self.ref_count, .Add, 1, .monotonic);
        return @intCast(old + 1);
    }

    fn releaseRef(self: *ApplicationViewChangeListener) callconv(.winapi) u32 {
        const old = @atomicRmw(i32, &self.ref_count, .Sub, 1, .release);
        return @intCast(old - 1);
    }

    fn onApplicationViewChanged(self: *ApplicationViewChangeListener, view: *IApplicationView, change: ApplicationViewChange, _: ?*com.IUnknown) callconv(.winapi) HRESULT {
        if (self.callback.onWindowEvent) |cb| {
            const handle = view.getThumbnailWindow() catch 0;
            cb(handle, change);
        }

        return 0;
    }

    const vtable_instance = IApplicationViewChangeListenerVtbl{
        .QueryInterface = &queryInterface,
        .AddRef = &addRef,
        .Release = &releaseRef,
        .OnApplicationViewChanged = &onApplicationViewChanged,
    };
};

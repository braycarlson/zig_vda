const std = @import("std");
const com = @import("com.zig");
const guid = @import("guid.zig");
const vd = @import("vd.zig");

const GUID = guid.GUID;
const HSTRING = com.HSTRING;
const IObjectArray = @import("IObjectArray.zig").IObjectArray;
const IServiceProvider = @import("IServiceProvider.zig").IServiceProvider;
const IVirtualDesktop = @import("IVirtualDesktop.zig").IVirtualDesktop;
const IVirtualDesktop2 = @import("IVirtualDesktop2.zig").IVirtualDesktop2;
const IVirtualDesktopManager = @import("IVirtualDesktopManager.zig").IVirtualDesktopManager;
const IVirtualDesktopManagerInternal2 = @import("IVirtualDesktopManagerInternal2.zig").IVirtualDesktopManagerInternal2;
const AdjacentDirection = @import("IVirtualDesktopManagerInternal2.zig").AdjacentDirection;
const IApplicationViewCollection = @import("IApplicationViewCollection.zig").IApplicationViewCollection;
const ApplicationViewChangeListener = @import("IApplicationViewChangeListener.zig").ApplicationViewChangeListener;
const IVirtualDesktopPinnedApps = @import("IVirtualDesktopPinnedApps.zig").IVirtualDesktopPinnedApps;
const IVirtualDesktopNotificationService = @import("IVirtualDesktopNotificationService.zig").IVirtualDesktopNotificationService;
const VirtualDesktopNotification = @import("IVirtualDesktopNotification.zig").VirtualDesktopNotification;
const NotificationCallback = @import("IVirtualDesktopNotification.zig").NotificationCallback;
const IMultitaskingViewVisibilityService = @import("IMultitaskingViewVisibilityService.zig").IMultitaskingViewVisibilityService;
const MultitaskingViewVisibilityNotification = @import("IMultitaskingViewVisibilityNotification.zig").MultitaskingViewVisibilityNotification;

pub const DESKTOPS_MAX: u32 = 32;
pub const NAME_LEN_MAX: usize = com.HSTRING_UTF8_MAX;

extern "user32" fn GetAncestor(window: isize, flags: u32) callconv(.winapi) isize;
extern "user32" fn GetWindow(window: isize, command: u32) callconv(.winapi) isize;

pub const DesktopInfo = struct {
    index: u32,
    guid: GUID,
};

pub const DesktopsResult = struct {
    items: [DESKTOPS_MAX]DesktopInfo,
    count: u32,
};

pub const Service = struct {
    provider: *IServiceProvider,
    manager: *IVirtualDesktopManager,
    manager_internal: *IVirtualDesktopManagerInternal2,
    view_collection: *IApplicationViewCollection,
    pinned_apps: *IVirtualDesktopPinnedApps,
    notification_service: *IVirtualDesktopNotificationService,
    multitasking_service: *IMultitaskingViewVisibilityService,
    notification: VirtualDesktopNotification,
    notification_cookie: u32,
    multitasking_notification: MultitaskingViewVisibilityNotification,
    multitasking_cookie: u32,
    view_listener: ApplicationViewChangeListener,
    view_cookie: u32,

    pub fn init() vd.Error!Service {
        const provider = try com.createInstance(
            IServiceProvider,
            &guid.CLSID_ImmersiveShell,
            com.CLSCTX_LOCAL_SERVER,
            &guid.IID_IServiceProvider,
        );
        errdefer com.releaseObj(provider);

        const manager = try com.createInstance(
            IVirtualDesktopManager,
            &guid.CLSID_VirtualDesktopManager,
            com.CLSCTX_ALL,
            &guid.IID_IVirtualDesktopManager,
        );
        errdefer com.releaseObj(manager);

        const manager_internal = try provider.queryService(
            IVirtualDesktopManagerInternal2,
            &guid.SID_VirtualDesktopManager,
            &guid.IID_IVirtualDesktopManagerInternal2,
        );
        errdefer com.releaseObj(manager_internal);

        const view_collection = try provider.queryService(
            IApplicationViewCollection,
            &guid.IID_IApplicationViewCollection,
            &guid.IID_IApplicationViewCollection,
        );
        errdefer com.releaseObj(view_collection);

        const pinned_apps = try provider.queryService(
            IVirtualDesktopPinnedApps,
            &guid.SID_VirtualDesktopPinnedApps,
            &guid.IID_IVirtualDesktopPinnedApps,
        );
        errdefer com.releaseObj(pinned_apps);

        const notification_service = try provider.queryService(
            IVirtualDesktopNotificationService,
            &guid.SID_VirtualDesktopNotificationService,
            &guid.IID_IVirtualDesktopNotificationService,
        );
        errdefer com.releaseObj(notification_service);

        const multitasking_service = try provider.queryService(
            IMultitaskingViewVisibilityService,
            &guid.SID_MultitaskingViewVisibilityService,
            &guid.IID_IMultitaskingViewVisibilityService,
        );

        return .{
            .provider = provider,
            .manager = manager,
            .manager_internal = manager_internal,
            .view_collection = view_collection,
            .pinned_apps = pinned_apps,
            .notification_service = notification_service,
            .multitasking_service = multitasking_service,
            .notification = VirtualDesktopNotification.init(&EMPTY_CALLBACK),
            .notification_cookie = 0,
            .multitasking_notification = MultitaskingViewVisibilityNotification.init(&EMPTY_CALLBACK),
            .multitasking_cookie = 0,
            .view_listener = ApplicationViewChangeListener.init(&EMPTY_CALLBACK),
            .view_cookie = 0,
        };
    }

    pub fn deinit(self: *Service) void {
        self.releaseResources();
        self.* = undefined;
    }

    pub fn reconnect(self: *Service) vd.Error!void {
        const had_notification = self.notification_cookie != 0;
        const callback = self.notification.callback;

        const service = try Service.init();
        self.releaseResources();
        self.* = service;

        if (had_notification) {
            self.registerNotification(callback) catch {};
        }
    }

    pub fn isConnected(self: *Service) bool {
        const count = self.manager_internal.getDesktopCount() catch return false;
        return count > 0;
    }

    pub fn registerNotification(self: *Service, callback: *const NotificationCallback) vd.Error!void {
        self.unregisterNotification() catch {};
        self.disconnectListeners();

        self.notification = VirtualDesktopNotification.init(callback);
        self.multitasking_notification = MultitaskingViewVisibilityNotification.init(callback);
        self.view_listener = ApplicationViewChangeListener.init(callback);

        self.notification_cookie = try self.notification_service.register(@ptrCast(&self.notification));
        errdefer self.unregisterNotification() catch {};

        if (callback.onMultitaskingViewShown != null or callback.onMultitaskingViewDismissed != null) {
            self.multitasking_cookie = try self.multitasking_service.register(@ptrCast(&self.multitasking_notification));
        }

        if (callback.onWindowEvent != null) {
            self.view_cookie = try self.view_collection.registerForApplicationViewChanges(@ptrCast(&self.view_listener));
        }
    }

    pub fn unregisterNotification(self: *Service) vd.Error!void {
        var first_error: ?vd.Error = null;

        if (self.view_cookie != 0) {
            self.view_collection.unregisterForApplicationViewChanges(self.view_cookie) catch |err| {
                first_error = first_error orelse err;
            };

            self.view_cookie = 0;
        }

        if (self.multitasking_cookie != 0) {
            self.multitasking_service.unregister(self.multitasking_cookie) catch |err| {
                first_error = first_error orelse err;
            };

            self.multitasking_cookie = 0;
        }

        if (self.notification_cookie != 0) {
            self.notification_service.unregister(self.notification_cookie) catch |err| {
                first_error = first_error orelse err;
            };

            self.notification_cookie = 0;
        }

        if (first_error) |err| return err;
    }

    pub fn getDesktopCount(self: *Service) vd.Error!u32 {
        return self.withRetry(u32, ops.getDesktopCount, .{});
    }

    pub fn getCurrentDesktopIndex(self: *Service) vd.Error!u32 {
        return self.withRetry(u32, ops.getCurrentDesktopIndex, .{});
    }

    pub fn getDesktops(self: *Service) vd.Error!DesktopsResult {
        return self.withRetry(DesktopsResult, ops.getDesktops, .{});
    }

    pub fn getDesktopGuid(self: *Service, index: u32) vd.Error!GUID {
        return self.withRetry(GUID, ops.getDesktopGuid, .{index});
    }

    pub fn getDesktopIndexByGuid(self: *Service, id: *const GUID) vd.Error!u32 {
        return self.withRetry(u32, ops.getDesktopIndexByGuid, .{id});
    }

    pub fn getAdjacentDesktopIndex(self: *Service, index: u32, direction: AdjacentDirection) vd.Error!u32 {
        return self.withRetry(u32, ops.getAdjacentDesktopIndex, .{ index, direction });
    }

    pub fn getLastActiveDesktopIndex(self: *Service) vd.Error!u32 {
        return self.withRetry(u32, ops.getLastActiveDesktopIndex, .{});
    }

    pub fn isDesktopRemote(self: *Service, index: u32) vd.Error!bool {
        return self.withRetry(bool, ops.isDesktopRemote, .{index});
    }

    pub fn switchDesktop(self: *Service, index: u32) vd.Error!void {
        return self.withRetry(void, ops.switchDesktop, .{index});
    }

    pub fn switchDesktopWithAnimation(self: *Service, index: u32) vd.Error!void {
        return self.withRetry(void, ops.switchDesktopWithAnimation, .{index});
    }

    pub fn waitForAnimationToComplete(self: *Service) vd.Error!void {
        return self.withRetry(void, ops.waitForAnimationToComplete, .{});
    }

    pub fn createDesktop(self: *Service) vd.Error!u32 {
        return self.withRetry(u32, ops.createDesktop, .{});
    }

    pub fn moveDesktop(self: *Service, index: u32, new_index: u32) vd.Error!void {
        return self.withRetry(void, ops.moveDesktop, .{ index, new_index });
    }

    pub fn removeDesktop(self: *Service, index: u32, fallback_index: u32) vd.Error!void {
        return self.withRetry(void, ops.removeDesktop, .{ index, fallback_index });
    }

    pub fn moveWindowToDesktop(self: *Service, handle: isize, index: u32) vd.Error!void {
        return self.withRetry(void, ops.moveWindowToDesktop, .{ handle, index });
    }

    pub fn isWindowOnCurrentDesktop(self: *Service, handle: isize) vd.Error!bool {
        return self.withRetry(bool, ops.isWindowOnCurrentDesktop, .{handle});
    }

    pub fn getWindowDesktopGuid(self: *Service, handle: isize) vd.Error!GUID {
        return self.withRetry(GUID, ops.getWindowDesktopGuid, .{handle});
    }

    pub fn getWindowDesktopIndex(self: *Service, handle: isize) vd.Error!u32 {
        return self.withRetry(u32, ops.getWindowDesktopIndex, .{handle});
    }

    pub fn isWindowOnDesktop(self: *Service, handle: isize, index: u32) vd.Error!bool {
        return self.withRetry(bool, ops.isWindowOnDesktop, .{ handle, index });
    }

    pub fn isPinnedWindow(self: *Service, handle: isize) vd.Error!bool {
        return self.withRetry(bool, ops.isPinnedWindow, .{handle});
    }

    pub fn pinWindow(self: *Service, handle: isize) vd.Error!void {
        return self.withRetry(void, ops.pinWindow, .{handle});
    }

    pub fn unpinWindow(self: *Service, handle: isize) vd.Error!void {
        return self.withRetry(void, ops.unpinWindow, .{handle});
    }

    pub fn isPinnedApp(self: *Service, handle: isize) vd.Error!bool {
        return self.withRetry(bool, ops.isPinnedApp, .{handle});
    }

    pub fn pinApp(self: *Service, handle: isize) vd.Error!void {
        return self.withRetry(void, ops.pinApp, .{handle});
    }

    pub fn unpinApp(self: *Service, handle: isize) vd.Error!void {
        return self.withRetry(void, ops.unpinApp, .{handle});
    }

    pub fn getDesktopName(self: *Service, index: u32, buf: *[NAME_LEN_MAX]u8) vd.Error![]const u8 {
        return self.withRetry([]const u8, ops.getDesktopName, .{ index, buf });
    }

    pub fn setDesktopName(self: *Service, index: u32, name: []const u8) vd.Error!void {
        return self.withRetry(void, ops.setDesktopName, .{ index, name });
    }

    pub fn getDesktopWallpaper(self: *Service, index: u32, buf: *[NAME_LEN_MAX]u8) vd.Error![]const u8 {
        return self.withRetry([]const u8, ops.getDesktopWallpaper, .{ index, buf });
    }

    pub fn setDesktopWallpaper(self: *Service, index: u32, path: []const u8) vd.Error!void {
        return self.withRetry(void, ops.setDesktopWallpaper, .{ index, path });
    }

    pub fn getVisibleMultitaskingViews(self: *Service) vd.Error!u32 {
        return self.withRetry(u32, ops.getVisibleMultitaskingViews, .{});
    }

    const ops = struct {
        fn getDesktopCount(self: *Service) vd.Error!u32 {
            return self.manager_internal.getDesktopCount();
        }

        fn getCurrentDesktopIndex(self: *Service) vd.Error!u32 {
            const current = try self.manager_internal.getCurrentDesktop();
            defer com.releaseObj(current);
            const current_id = try current.getId();
            return self.findDesktopIndex(&current_id);
        }

        fn getDesktops(self: *Service) vd.Error!DesktopsResult {
            const desktops = try self.manager_internal.getDesktops();
            defer com.releaseObj(desktops);
            const count = try desktops.getCount();
            if (count > DESKTOPS_MAX) return vd.Error.DesktopLimitReached;

            var result: DesktopsResult = undefined;
            result.count = count;

            var i: u32 = 0;

            while (i < result.count) : (i += 1) {
                const desktop = try desktops.getAt(IVirtualDesktop, i, &guid.IID_IVirtualDesktop);
                defer com.releaseObj(desktop);
                const id = try desktop.getId();
                result.items[i] = .{ .index = i, .guid = id };
            }

            return result;
        }

        fn getDesktopGuid(self: *Service, index: u32) vd.Error!GUID {
            const desktop = try self.getDesktopByIndex(index);
            defer com.releaseObj(desktop);
            return desktop.getId();
        }

        fn getDesktopIndexByGuid(self: *Service, id: *const GUID) vd.Error!u32 {
            return self.findDesktopIndex(id);
        }

        fn getAdjacentDesktopIndex(self: *Service, index: u32, direction: AdjacentDirection) vd.Error!u32 {
            const desktop = try self.getDesktopByIndex(index);
            defer com.releaseObj(desktop);
            const adjacent = try self.manager_internal.getAdjacentDesktop(desktop, direction);
            defer com.releaseObj(adjacent);
            const id = try adjacent.getId();
            return self.findDesktopIndex(&id);
        }

        fn getLastActiveDesktopIndex(self: *Service) vd.Error!u32 {
            const desktop = try self.manager_internal.getLastActiveDesktop();
            defer com.releaseObj(desktop);
            const id = try desktop.getId();
            return self.findDesktopIndex(&id);
        }

        fn isDesktopRemote(self: *Service, index: u32) vd.Error!bool {
            const desktops = try self.manager_internal.getDesktops();
            defer com.releaseObj(desktops);
            const count = try desktops.getCount();
            if (index >= count) return vd.Error.DesktopNotFound;

            const desktop = try desktops.getAt(IVirtualDesktop2, index, &guid.IID_IVirtualDesktop2);
            defer com.releaseObj(desktop);
            return desktop.isRemote();
        }

        fn switchDesktop(self: *Service, index: u32) vd.Error!void {
            const desktop = try self.getDesktopByIndex(index);
            defer com.releaseObj(desktop);
            try self.manager_internal.switchDesktop(desktop);
        }

        fn switchDesktopWithAnimation(self: *Service, index: u32) vd.Error!void {
            const desktop = try self.getDesktopByIndex(index);
            defer com.releaseObj(desktop);
            try self.manager_internal.switchDesktopWithAnimation(desktop);
        }

        fn waitForAnimationToComplete(self: *Service) vd.Error!void {
            try self.manager_internal.waitForAnimationToComplete();
        }

        fn createDesktop(self: *Service) vd.Error!u32 {
            const count = try self.manager_internal.getDesktopCount();
            if (count >= DESKTOPS_MAX) return vd.Error.DesktopLimitReached;
            const desktop = try self.manager_internal.createDesktop();
            defer com.releaseObj(desktop);
            const id = try desktop.getId();
            return self.findDesktopIndex(&id);
        }

        fn moveDesktop(self: *Service, index: u32, new_index: u32) vd.Error!void {
            const count = try self.manager_internal.getDesktopCount();
            if (new_index >= count) return vd.Error.DesktopNotFound;

            const desktop = try self.getDesktopByIndex(index);
            defer com.releaseObj(desktop);
            try self.manager_internal.moveDesktop(desktop, new_index);
        }

        fn removeDesktop(self: *Service, index: u32, fallback_index: u32) vd.Error!void {
            const target = try self.getDesktopByIndex(index);
            defer com.releaseObj(target);
            const fallback = try self.getDesktopByIndex(fallback_index);
            defer com.releaseObj(fallback);
            try self.manager_internal.removeDesktop(target, fallback);
        }

        fn moveWindowToDesktop(self: *Service, handle: isize, index: u32) vd.Error!void {
            const view = try self.view_collection.getViewForHwnd(self.rootWindow(handle));
            defer com.releaseObj(view);
            const desktop = try self.getDesktopByIndex(index);
            defer com.releaseObj(desktop);
            try self.manager_internal.moveViewToDesktop(view, desktop);
        }

        fn isWindowOnCurrentDesktop(self: *Service, handle: isize) vd.Error!bool {
            return self.manager.isWindowOnCurrentDesktop(self.rootWindow(handle));
        }

        fn getWindowDesktopGuid(self: *Service, handle: isize) vd.Error!GUID {
            return self.manager.getWindowDesktopId(self.rootWindow(handle));
        }

        fn getWindowDesktopIndex(self: *Service, handle: isize) vd.Error!u32 {
            const id = try self.manager.getWindowDesktopId(self.rootWindow(handle));
            if (isPinnedDesktopId(&id)) return vd.Error.WindowPinned;
            return self.findDesktopIndex(&id);
        }

        fn isWindowOnDesktop(self: *Service, handle: isize, index: u32) vd.Error!bool {
            const view = try self.view_collection.getViewForHwnd(self.rootWindow(handle));
            defer com.releaseObj(view);
            const desktop = try self.getDesktopByIndex(index);
            defer com.releaseObj(desktop);
            return desktop.isViewVisible(view);
        }

        fn isPinnedWindow(self: *Service, handle: isize) vd.Error!bool {
            const view = try self.view_collection.getViewForHwnd(self.rootWindow(handle));
            defer com.releaseObj(view);
            return self.pinned_apps.isViewPinned(view);
        }

        fn pinWindow(self: *Service, handle: isize) vd.Error!void {
            const view = try self.view_collection.getViewForHwnd(self.rootWindow(handle));
            defer com.releaseObj(view);
            try self.pinned_apps.pinView(view);
        }

        fn unpinWindow(self: *Service, handle: isize) vd.Error!void {
            const view = try self.view_collection.getViewForHwnd(self.rootWindow(handle));
            defer com.releaseObj(view);
            try self.pinned_apps.unpinView(view);
        }

        fn isPinnedApp(self: *Service, handle: isize) vd.Error!bool {
            const app_id = try self.getWindowAppId(handle);
            defer com.taskMemFree(@ptrCast(app_id));
            return self.pinned_apps.isAppPinned(app_id);
        }

        fn pinApp(self: *Service, handle: isize) vd.Error!void {
            const app_id = try self.getWindowAppId(handle);
            defer com.taskMemFree(@ptrCast(app_id));
            try self.pinned_apps.pinApp(app_id);
        }

        fn unpinApp(self: *Service, handle: isize) vd.Error!void {
            const app_id = try self.getWindowAppId(handle);
            defer com.taskMemFree(@ptrCast(app_id));
            try self.pinned_apps.unpinApp(app_id);
        }

        fn getDesktopName(self: *Service, index: u32, buf: *[NAME_LEN_MAX]u8) vd.Error![]const u8 {
            const desktop = try self.getDesktopByIndex(index);
            defer com.releaseObj(desktop);
            return desktop.getName(buf);
        }

        fn setDesktopName(self: *Service, index: u32, name: []const u8) vd.Error!void {
            const desktop = try self.getDesktopByIndex(index);
            defer com.releaseObj(desktop);
            const hstr = try com.createHString(name);
            defer com.deleteHString(hstr);
            try self.manager_internal.setName(desktop, hstr);
        }

        fn getDesktopWallpaper(self: *Service, index: u32, buf: *[NAME_LEN_MAX]u8) vd.Error![]const u8 {
            const desktop = try self.getDesktopByIndex(index);
            defer com.releaseObj(desktop);
            return desktop.getWallpaper(buf);
        }

        fn setDesktopWallpaper(self: *Service, index: u32, path: []const u8) vd.Error!void {
            const desktop = try self.getDesktopByIndex(index);
            defer com.releaseObj(desktop);
            const hstr = try com.createHString(path);
            defer com.deleteHString(hstr);
            try self.manager_internal.setWallpaper(desktop, hstr);
        }

        fn getVisibleMultitaskingViews(self: *Service) vd.Error!u32 {
            return self.multitasking_service.isViewVisible(MULTITASKING_VIEWS_ALL);
        }
    };

    fn getDesktopByIndex(self: *Service, index: u32) vd.Error!*IVirtualDesktop {
        const desktops = try self.manager_internal.getDesktops();
        defer com.releaseObj(desktops);
        const count = try desktops.getCount();
        if (index >= count) return vd.Error.DesktopNotFound;
        return desktops.getAt(IVirtualDesktop, index, &guid.IID_IVirtualDesktop);
    }

    fn findDesktopIndex(self: *Service, id: *const GUID) vd.Error!u32 {
        const desktops = try self.manager_internal.getDesktops();
        defer com.releaseObj(desktops);
        const count = try desktops.getCount();

        var i: u32 = 0;

        while (i < count) : (i += 1) {
            const desktop = try desktops.getAt(IVirtualDesktop, i, &guid.IID_IVirtualDesktop);
            defer com.releaseObj(desktop);
            const desktop_id = try desktop.getId();
            if (desktop_id.eql(id.*)) return i;
        }

        return vd.Error.DesktopNotFound;
    }

    fn getWindowAppId(self: *Service, handle: isize) vd.Error![*:0]u16 {
        const view = try self.view_collection.getViewForHwnd(self.rootWindow(handle));
        defer com.releaseObj(view);
        const app_id = try view.getAppUserModelId();
        return app_id orelse return vd.Error.InvalidArgument;
    }

    fn rootWindow(self: *Service, handle: isize) isize {
        var root = GetAncestor(handle, GA_ROOT);
        if (root == 0) return handle;

        for (0..OWNER_DEPTH_MAX) |_| {
            const owner = GetWindow(root, GW_OWNER);
            if (owner == 0) break;

            root = owner;
        }

        if (root == handle) return handle;

        const view = self.view_collection.getViewForHwnd(handle) catch return root;
        defer com.releaseObj(view);
        const id = view.getVirtualDesktopId() catch return handle;
        return if (id.eql(GUID.ZERO)) root else handle;
    }

    fn isPinnedDesktopId(id: *const GUID) bool {
        return id.eql(guid.DESKTOP_ID_PINNED_VIEW) or id.eql(guid.DESKTOP_ID_PINNED_APP);
    }

    fn disconnectListeners(self: *Service) void {
        com.disconnectObject(@ptrCast(&self.notification));
        com.disconnectObject(@ptrCast(&self.multitasking_notification));
        com.disconnectObject(@ptrCast(&self.view_listener));
    }

    fn releaseResources(self: *Service) void {
        self.unregisterNotification() catch {};
        self.disconnectListeners();

        com.releaseObj(self.multitasking_service);
        com.releaseObj(self.notification_service);
        com.releaseObj(self.pinned_apps);
        com.releaseObj(self.view_collection);
        com.releaseObj(self.manager_internal);
        com.releaseObj(self.manager);
        com.releaseObj(self.provider);
    }

    fn isRecoverable(err: vd.Error) bool {
        return switch (err) {
            vd.Error.ServiceNotConnected,
            vd.Error.ComInitFailed,
            vd.Error.NullPointer,
            => true,
            else => false,
        };
    }

    fn withRetry(self: *Service, comptime R: type, comptime func: anytype, args: anytype) vd.Error!R {
        var last_err: vd.Error = vd.Error.ComCallFailed;

        for (0..4) |attempt| {
            if (attempt > 0) {
                if (last_err == vd.Error.ComInitFailed) com.ensureMTAInitialized();
                self.reconnect() catch return last_err;
            }

            return @call(.auto, func, .{self} ++ args) catch |err| {
                if (!isRecoverable(err)) return err;
                last_err = err;

                continue;
            };
        }

        return last_err;
    }

    const EMPTY_CALLBACK = NotificationCallback{};
    const GA_ROOT: u32 = 2;
    const GW_OWNER: u32 = 4;
    const MULTITASKING_VIEWS_ALL: u32 = 0xFFFFFFFF;
    const OWNER_DEPTH_MAX = 64;
};

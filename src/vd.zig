pub const com = @import("com.zig");
pub const guid = @import("guid.zig");

pub const IServiceProvider = @import("IServiceProvider.zig").IServiceProvider;
pub const IObjectArray = @import("IObjectArray.zig").IObjectArray;
pub const IVirtualDesktop = @import("IVirtualDesktop.zig").IVirtualDesktop;
pub const IApplicationView = @import("IApplicationView.zig").IApplicationView;
pub const IVirtualDesktopManager = @import("IVirtualDesktopManager.zig").IVirtualDesktopManager;
pub const IVirtualDesktopManagerInternal = @import("IVirtualDesktopManagerInternal.zig").IVirtualDesktopManagerInternal;
pub const IApplicationViewCollection = @import("IApplicationViewCollection.zig").IApplicationViewCollection;
pub const IVirtualDesktopPinnedApps = @import("IVirtualDesktopPinnedApps.zig").IVirtualDesktopPinnedApps;
pub const IVirtualDesktopNotificationService = @import("IVirtualDesktopNotificationService.zig").IVirtualDesktopNotificationService;
pub const VirtualDesktopNotification = @import("IVirtualDesktopNotification.zig").VirtualDesktopNotification;
pub const NotificationCallback = @import("IVirtualDesktopNotification.zig").NotificationCallback;
pub const Service = @import("Service.zig").Service;
pub const DesktopInfo = @import("Service.zig").DesktopInfo;
pub const DesktopsResult = @import("Service.zig").DesktopsResult;

pub const GUID = guid.GUID;
pub const HRESULT = i32;
pub const HSTRING = com.HSTRING;
pub const DESKTOPS_MAX = @import("Service.zig").DESKTOPS_MAX;
pub const NAME_LEN_MAX = @import("Service.zig").NAME_LEN_MAX;

pub const Error = error{
    ComInitFailed,
    ComCreateFailed,
    ComCallFailed,
    ServiceNotConnected,
    DesktopNotFound,
    WindowNotFound,
    DesktopLimitReached,
    StringTooLong,
    NullPointer,
};

pub fn hresultToError(hr: HRESULT) Error!void {
    if (hr >= 0) return;

    return switch (@as(u32, @bitCast(hr))) {
        0x80040154 => Error.ServiceNotConnected,
        0x800706BA => Error.ServiceNotConnected,
        0x800401FD => Error.ServiceNotConnected,
        0x800401F0 => Error.ComInitFailed,
        0x8002802B => Error.DesktopNotFound,
        else => Error.ComCallFailed,
    };
}

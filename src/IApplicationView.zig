const std = @import("std");
const com = @import("com.zig");
const guid = @import("guid.zig");
const vd = @import("vd.zig");

const GUID = guid.GUID;
const HRESULT = vd.HRESULT;
const HSTRING = com.HSTRING;
const IObjectArray = @import("IObjectArray.zig").IObjectArray;

const IApplicationViewVtbl = extern struct {
    base: com.IUnknownVtbl,
    // IInspectable
    GetIids: *const fn (*IApplicationView, *u32, *?*GUID) callconv(.winapi) HRESULT,
    GetRuntimeClassName: *const fn (*IApplicationView, *HSTRING) callconv(.winapi) HRESULT,
    GetTrustLevel: *const fn (*IApplicationView, *i32) callconv(.winapi) HRESULT,

    // IApplicationView
    SetFocus: *const fn (*IApplicationView) callconv(.winapi) HRESULT,
    SwitchTo: *const fn (*IApplicationView) callconv(.winapi) HRESULT,
    TryInvokeBack: *const fn (*IApplicationView, ?*anyopaque) callconv(.winapi) HRESULT,
    GetThumbnailWindow: *const fn (*IApplicationView, *isize) callconv(.winapi) HRESULT,
    GetMonitor: *const fn (*IApplicationView, *?*anyopaque) callconv(.winapi) HRESULT,
    GetVisibility: *const fn (*IApplicationView, *i32) callconv(.winapi) HRESULT,
    SetCloak: *const fn (*IApplicationView, u32, i32) callconv(.winapi) HRESULT,
    GetPosition: *const fn (*IApplicationView, *const GUID, *?*anyopaque) callconv(.winapi) HRESULT,
    SetPosition: *const fn (*IApplicationView, ?*anyopaque) callconv(.winapi) HRESULT,
    InsertAfterWindow: *const fn (*IApplicationView, isize) callconv(.winapi) HRESULT,
    GetExtendedFramePosition: *const fn (*IApplicationView, *anyopaque) callconv(.winapi) HRESULT,
    GetAppUserModelId: *const fn (*IApplicationView, *?[*:0]u16) callconv(.winapi) HRESULT,
    SetAppUserModelId: *const fn (*IApplicationView, [*:0]const u16) callconv(.winapi) HRESULT,
    IsEqualByAppUserModelId: *const fn (*IApplicationView, [*:0]const u16, *i32) callconv(.winapi) HRESULT,
    GetViewState: *const fn (*IApplicationView, *u32) callconv(.winapi) HRESULT,
    SetViewState: *const fn (*IApplicationView, u32) callconv(.winapi) HRESULT,
    GetNeediness: *const fn (*IApplicationView, *i32) callconv(.winapi) HRESULT,
    GetLastActivationTimestamp: *const fn (*IApplicationView, *u64) callconv(.winapi) HRESULT,
    SetLastActivationTimestamp: *const fn (*IApplicationView, u64) callconv(.winapi) HRESULT,
    GetVirtualDesktopId: *const fn (*IApplicationView, *GUID) callconv(.winapi) HRESULT,
    SetVirtualDesktopId: *const fn (*IApplicationView, *const GUID) callconv(.winapi) HRESULT,
    GetShowInSwitchers: *const fn (*IApplicationView, *i32) callconv(.winapi) HRESULT,
    SetShowInSwitchers: *const fn (*IApplicationView, i32) callconv(.winapi) HRESULT,
    GetScaleFactor: *const fn (*IApplicationView, *u32) callconv(.winapi) HRESULT,
    CanReceiveInput: *const fn (*IApplicationView, *i32) callconv(.winapi) HRESULT,
    GetCompatibilityPolicyType: *const fn (*IApplicationView, *u32) callconv(.winapi) HRESULT,
    SetCompatibilityPolicyType: *const fn (*IApplicationView, u32) callconv(.winapi) HRESULT,
    GetPositionerPriority: *const fn (*IApplicationView, *?*anyopaque) callconv(.winapi) HRESULT,
    SetPositionerPriority: *const fn (*IApplicationView, ?*anyopaque) callconv(.winapi) HRESULT,
    GetSizeConstraints: *const fn (*IApplicationView, ?*anyopaque, *anyopaque, *anyopaque) callconv(.winapi) HRESULT,
    GetSizeConstraintsForDpi: *const fn (*IApplicationView, u32, *anyopaque, *anyopaque) callconv(.winapi) HRESULT,
    SetSizeConstraintsForDpi: *const fn (*IApplicationView, ?*const u32, ?*const anyopaque, ?*const anyopaque) callconv(.winapi) HRESULT,
    QuerySizeConstraintsFromApp: *const fn (*IApplicationView) callconv(.winapi) HRESULT,
    OnMinSizePreferencesUpdated: *const fn (*IApplicationView, isize) callconv(.winapi) HRESULT,
    ApplyOperation: *const fn (*IApplicationView, ?*anyopaque) callconv(.winapi) HRESULT,
    IsTray: *const fn (*IApplicationView, *i32) callconv(.winapi) HRESULT,
    IsInHighZOrderBand: *const fn (*IApplicationView, *i32) callconv(.winapi) HRESULT,
    IsSplashScreenPresented: *const fn (*IApplicationView, *i32) callconv(.winapi) HRESULT,
    Flash: *const fn (*IApplicationView) callconv(.winapi) HRESULT,
    GetRootSwitchableOwner: *const fn (*IApplicationView, *?*IApplicationView) callconv(.winapi) HRESULT,
    EnumerateOwnershipTree: *const fn (*IApplicationView, *?*IObjectArray) callconv(.winapi) HRESULT,
    GetEnterpriseId: *const fn (*IApplicationView, *?[*:0]u16) callconv(.winapi) HRESULT,
    GetEnterpriseChromePreference: *const fn (*IApplicationView, *i32) callconv(.winapi) HRESULT,
    IsMirrored: *const fn (*IApplicationView, *i32) callconv(.winapi) HRESULT,
    GetFrameworkViewType: *const fn (*IApplicationView, *u32) callconv(.winapi) HRESULT,
    GetCanTab: *const fn (*IApplicationView, *i32) callconv(.winapi) HRESULT,
    SetCanTab: *const fn (*IApplicationView, i32) callconv(.winapi) HRESULT,
    GetIsTabbed: *const fn (*IApplicationView, *i32) callconv(.winapi) HRESULT,
    SetIsTabbed: *const fn (*IApplicationView, i32) callconv(.winapi) HRESULT,
    RefreshCanTab: *const fn (*IApplicationView) callconv(.winapi) HRESULT,
    GetIsOccluded: *const fn (*IApplicationView, *i32) callconv(.winapi) HRESULT,
    SetIsOccluded: *const fn (*IApplicationView, i32) callconv(.winapi) HRESULT,
    UpdateEngagementFlags: *const fn (*IApplicationView, u32, u32) callconv(.winapi) HRESULT,
    SetForceActiveWindowAppearance: *const fn (*IApplicationView, i32) callconv(.winapi) HRESULT,
    GetLastActivationFILETIME: *const fn (*IApplicationView, *anyopaque) callconv(.winapi) HRESULT,
    GetPersistingStateName: *const fn (*IApplicationView, *?[*:0]u16) callconv(.winapi) HRESULT,
};

pub const IApplicationView = extern struct {
    vtable: *const IApplicationViewVtbl,

    pub fn getThumbnailWindow(self: *IApplicationView) vd.Error!isize {
        var handle: isize = 0;
        const hr = self.vtable.GetThumbnailWindow(self, &handle);
        try vd.hresultToError(hr);

        return handle;
    }

    pub fn getAppUserModelId(self: *IApplicationView) vd.Error!?[*:0]u16 {
        var id: ?[*:0]u16 = null;
        const hr = self.vtable.GetAppUserModelId(self, &id);
        try vd.hresultToError(hr);

        return id;
    }

    pub fn getVirtualDesktopId(self: *IApplicationView) vd.Error!GUID {
        var id: GUID = GUID.ZERO;
        const hr = self.vtable.GetVirtualDesktopId(self, &id);
        try vd.hresultToError(hr);

        return id;
    }
};

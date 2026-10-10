# Virtual Desktop Internals

## Overview

This page maps the virtual desktop implementation of the Windows 11 shell on build 26100.9457. The map is useful when a method is missing from the bindings, or when an app has to know how the shell behaves around switching, pinning, owned windows, notifications, and explorer restarts. The interface IDs change between Windows builds, so the map applies to this build.

## Windows Build

| Field | Value |
|-------|-------|
| Windows | Windows 11 Enterprise Evaluation, version 24H2, build 26100.9457. |
| `twinui.pcshell.dll` | The SHA-256 is `fba9d85a82d63a9d09958c77a6d27f65c14c213257e99d5acfaa733f505fdc82`. |

## Binaries

| Binary | Role |
|--------|------|
| `twinui.pcshell.dll` | The implementation loaded into explorer, with `CVirtualDesktopManager`, `CVirtualDesktop`, `CVirtualDesktopNotifications`, `VirtualPinnedAppsHandler`, `CApplicationViewManager`, `MultitaskingViewVisibilityService`, and the hotkey, switcher, and animation services. |
| `twinapi.dll` | The in-process server for the public `CLSID_VirtualDesktopManager`, which forwards each call to explorer and reacquires the explorer side after a restart. |
| `actxprxy.dll` | The proxy and stub for the internal virtual desktop interfaces and the multitasking view interfaces. |
| `OneCoreUAPCommonProxyStub.dll` | The proxy and stub for `IApplicationView`, `IApplicationViewCollection`, `IApplicationViewChangeListener`, the public `IVirtualDesktopManager`, and the immersive monitor interfaces. |
| `Taskbar.dll` | A client that registers `IVirtualDesktopAnimationSyncNotification`, so the taskbar redraws in step with the slide animation. |
| `DesktopSwitcherDataModel.dll` | A client of the desktop controller and data source services behind the desktop switcher. |
| `twinui.dll` | A client of the desktop manager, the notification service, and the view collection. |

## How It Works

The shell publishes its services through `CLSID_ImmersiveShell` `{C2F03A33-21F5-47FA-B4BB-156362A2F239}`, a class that explorer registers at runtime, so `CoCreateInstance` with `CLSCTX_LOCAL_SERVER` fails with `REGDB_E_CLASSNOTREG` while explorer is down. The returned object is an `IServiceProvider` whose `QueryService` takes a service ID and an interface ID. Each interface crosses into explorer through a proxy, so an interface is usable from another process only when its IID has a registered proxy and stub. The `Windows.Internal.ComposableShell.Multitasking` interfaces behind `SID_VirtualDesktopController` have none, which keeps that WinRT surface out of reach even though the service answers `QueryService` for `IUnknown`.

The public `IVirtualDesktopManager` takes a separate path. Its class lives in `twinapi.dll`, which forwards each call to `VirtualDesktopsApi` inside explorer.

## Services

| Service ID | Interface | Description |
|------------|-----------|-------------|
| `SID_VirtualDesktopManager` `{C5E0CDCA-7B6E-41B2-9FC4-D93975CC467B}` | `IVirtualDesktopManagerInternal2` | The desktop manager, which also answers for `IVirtualDesktopManagerInternal`. |
| `SID_VirtualDesktopNotificationService` `{A501FDEC-4A09-464C-AE4E-1B9C21B84918}` | `IVirtualDesktopNotificationService` | The registration point for `IVirtualDesktopNotification`. |
| `SID_VirtualDesktopPinnedApps` `{B5A399E7-1C87-46B8-88E9-FC5747B171BD}` | `IVirtualDesktopPinnedApps` | The pinning service for windows and apps. |
| `IID_IApplicationViewCollection` `{1841C6D7-4F9D-42C0-AF41-8747538F10E5}` | `IApplicationViewCollection` | The window list of the shell, published under its own IID. |
| `SID_MultitaskingViewVisibilityService` `{785702DD-B8EF-469F-8C19-E91B5F4CA564}` | `IMultitaskingViewVisibilityService` | The visibility state and events of Task View, Alt+Tab, and the desktop switcher. |
| `SID_VirtualDesktopAnimationSyncNotificationService` `{023B1604-45FE-4524-A708-AFFC39BE5564}` | `IVirtualDesktopAnimationSyncNotificationService` | The registration point for `IVirtualDesktopAnimationSyncNotification`. |
| `SID_VirtualDesktopHotkeyHandler` `{A822A81E-15B6-4759-96A9-7B88F391557F}` | `IVirtualDesktopHotkeyHandler` | The handler behind the desktop hotkeys, which wedges the animation of explorer when another process sends it a switch or create hotkey. |
| `SID_VirtualDesktopSwitcher` `{9813E2B3-29F9-4D41-B573-B7D903EB7621}` | `IVirtualDesktopSwitcherInvoker` | The desktop switcher overlay, which refuses another process with `E_ACCESSDENIED`. |
| `SID_VirtualDesktopTabletModePolicyService` `{615EC5E3-38FC-4058-ABAC-A204FCF42AC3}` | `IVirtualDesktopTabletModePolicyService` | The tablet mode policy, which takes an `IAppLayout` the bindings do not map. |
| `SID_VirtualDesktopController` `{82847A3E-9D2B-4C5A-9205-0EA22BFF5492}` | `IUnknown` | The WinRT desktop controller, whose own interfaces have no proxy. |
| `SID_VirtualDesktopDataSource` `{1E814A56-3460-4541-A8EA-5F34FCADC4D9}` | `IUnknown` | The WinRT data source behind the switcher, whose own interfaces have no proxy. |

## Interfaces

Each listing gives the vtable slot, counting `IUnknown` as slots 0 to 2, and the signature of each method. Each method returns an `HRESULT`. A method marked `[local]` has no proxy entry, so a call from another process crashes the caller inside the COM runtime. A parameter without a name is one whose meaning is not settled.

### Desktops

```
IVirtualDesktop  {3F07F4BE-B107-441A-AF0F-39D82529072C}  actxprxy.dll
 3  IsViewVisible(IApplicationView* view, BOOL* visible)
 4  GetID(GUID* id)
 5  GetName(HSTRING* name)
 6  GetWallpaper(HSTRING* path)

IVirtualDesktop2 : IVirtualDesktop  {A871910E-6CC0-4E65-8B9B-458CE9115E30}  actxprxy.dll
 7  IsRemote(BOOL* remote)
```

### Desktop Manager

```
IVirtualDesktopManagerInternal  {4970BA3D-FD4E-4647-BEA3-D89076EF4B9C}  actxprxy.dll
 3  GetCount(UINT* count)
 4  MoveViewToDesktop(IApplicationView* view, IVirtualDesktop* desktop)
 5  CanViewMoveDesktops(IApplicationView* view, BOOL* can_move)
 6  GetCurrentDesktop(IVirtualDesktop** desktop)
 7  GetDesktops(IObjectArray** desktops)
 8  GetAdjacentDesktop(IVirtualDesktop* from, UINT direction, IVirtualDesktop** desktop)
 9  SwitchDesktop(IVirtualDesktop* desktop)
10  SwitchDesktopAndMoveForegroundView(IVirtualDesktop* desktop)
11  CreateDesktop(IVirtualDesktop** desktop)
12  MoveDesktop(IVirtualDesktop* desktop, UINT index)
13  RemoveDesktop(IVirtualDesktop* desktop, IVirtualDesktop* fallback)
14  FindDesktop(REFGUID id, IVirtualDesktop** desktop)
15  GetDesktopSwitchIncludeExcludeViews(IVirtualDesktop* desktop, IObjectArray** include, IObjectArray** exclude)
16  SetDesktopName(IVirtualDesktop* desktop, HSTRING name)
17  SetDesktopWallpaper(IVirtualDesktop* desktop, HSTRING path)
18  UpdateWallpaperPathForAllDesktops(HSTRING path)
19  CopyDesktopState(IApplicationView* target, IApplicationView* source)

IVirtualDesktopManagerInternal2 : IVirtualDesktopManagerInternal  {53F5CA0B-158F-4124-900C-057158060B27}  actxprxy.dll
20  CreateRemoteDesktop(HSTRING name, IVirtualDesktop** desktop)
21  SwitchRemoteDesktop(IVirtualDesktop* desktop, VirtualDesktopSwitchType type)
22  SwitchDesktopWithAnimation(IVirtualDesktop* desktop)
23  GetLastActiveDesktop(IVirtualDesktop** desktop)
24  WaitForAnimationToComplete()
```

### Notifications

```
IVirtualDesktopNotificationService  {0CD45E71-D927-4F15-8B0A-8FEF525337BF}  actxprxy.dll
 3  Register(IVirtualDesktopNotification* notification, DWORD* cookie)
 4  Unregister(DWORD cookie)

IVirtualDesktopNotification  {B9E5E94D-233E-49AB-AF5C-2B4541C3AADE}  actxprxy.dll
 3  VirtualDesktopCreated(IVirtualDesktop* desktop)
 4  VirtualDesktopDestroyBegin(IVirtualDesktop* desktop, IVirtualDesktop* fallback)
 5  VirtualDesktopDestroyFailed(IVirtualDesktop* desktop, IVirtualDesktop* fallback)
 6  VirtualDesktopDestroyed(IVirtualDesktop* desktop, IVirtualDesktop* fallback)
 7  VirtualDesktopMoved(IVirtualDesktop* desktop, UINT from, UINT to)
 8  VirtualDesktopNameChanged(IVirtualDesktop* desktop, HSTRING name)
 9  ViewVirtualDesktopChanged(IApplicationView* view)
10  CurrentVirtualDesktopChanged(IVirtualDesktop* old, IVirtualDesktop* new)
11  VirtualDesktopWallpaperChanged(IVirtualDesktop* desktop, HSTRING path)
12  VirtualDesktopSwitched(IVirtualDesktop* desktop, VirtualDesktopSwitchType type)
13  RemoteVirtualDesktopConnected(IVirtualDesktop* desktop)
```

### Pinning

```
IVirtualDesktopPinnedApps  {4CE81583-1E4C-4632-A621-07A53543148F}  actxprxy.dll
 3  IsAppIdPinned(PCWSTR app_id, BOOL* pinned)
 4  PinAppID(PCWSTR app_id)
 5  UnpinAppID(PCWSTR app_id)
 6  IsViewPinned(IApplicationView* view, BOOL* pinned)
 7  PinView(IApplicationView* view)
 8  UnpinView(IApplicationView* view)
```

### Application Views

Slots 3 to 5 of `IApplicationView` belong to `IInspectable`.

```
IApplicationView : IInspectable  {372E1D3B-38D3-42E4-A15B-8AB2B178F513}  OneCoreUAPCommonProxyStub.dll
 6  SetFocus()
 7  SwitchTo()
 8  TryInvokeBack(IAsyncCallback* callback)
 9  GetThumbnailWindow(HWND* window)
10  GetMonitor(IImmersiveMonitor** monitor)
11  GetVisibility(BOOL* visible)
12  SetCloak(APPLICATION_VIEW_CLOAK_TYPE type, BOOL cloak)
13  GetPosition(REFIID iid, void** position)
14  SetPosition(IApplicationViewPosition* position)
15  InsertAfterWindow(HWND window)
16  GetExtendedFramePosition(RECT* rect)
17  GetAppUserModelId(PWSTR* app_id)
18  SetAppUserModelId(PCWSTR app_id)
19  IsEqualByAppUserModelId(PCWSTR app_id, BOOL* equal)
20  GetViewState(UINT* state)
21  SetViewState(UINT state)
22  GetNeediness(BOOL* neediness)
23  GetLastActivationTimestamp(ULONGLONG* timestamp)
24  SetLastActivationTimestamp(ULONGLONG timestamp)
25  GetVirtualDesktopId(GUID* id)
26  SetVirtualDesktopId(REFGUID id)
27  GetShowInSwitchers(BOOL* show)
28  SetShowInSwitchers(BOOL show)
29  GetScaleFactor(UINT* factor)
30  CanReceiveInput(BOOL* can_receive)
31  GetCompatibilityPolicyType(APPLICATION_VIEW_COMPATIBILITY_POLICY* policy)
32  SetCompatibilityPolicyType(APPLICATION_VIEW_COMPATIBILITY_POLICY policy)
33  GetPositionerPriority(IShellPositionerPriority** priority)
34  SetPositionerPriority(IShellPositionerPriority* priority)
35  GetSizeConstraints(IImmersiveMonitor* monitor, SIZE* min, SIZE* max)
36  GetSizeConstraintsForDpi(UINT dpi, SIZE* min, SIZE* max)
37  SetSizeConstraintsForDpi(const UINT* dpi, const SIZE* min, const SIZE* max)
38  QuerySizeConstraintsFromApp()  [local]
39  OnMinSizePreferencesUpdated(HWND window)
40  ApplyOperation(IApplicationViewOperation* operation)
41  IsTray(BOOL* tray)
42  IsInHighZOrderBand(BOOL* high)
43  IsSplashScreenPresented(BOOL* presented)
44  Flash()
45  GetRootSwitchableOwner(IApplicationView** owner)
46  EnumerateOwnershipTree(IObjectArray** views)
47  GetEnterpriseId(PWSTR* id)
48  GetEnterpriseChromePreference(BOOL* preference)
49  IsMirrored(BOOL* mirrored)
50  GetFrameworkViewType(FRAMEWORK_VIEW_TYPE* type)
51  GetCanTab(BOOL* can_tab)
52  SetCanTab(BOOL can_tab)
53  GetIsTabbed(BOOL* tabbed)
54  SetIsTabbed(BOOL tabbed)
55  RefreshCanTab()
56  GetIsOccluded(BOOL* occluded)
57  SetIsOccluded(BOOL occluded)
58  UpdateEngagementFlags(VIEW_ENGAGEMENT_FLAGS, VIEW_ENGAGEMENT_FLAGS)
59  SetForceActiveWindowAppearance(BOOL force)
60  GetLastActivationFILETIME(FILETIME* time)
61  GetPersistingStateName(PWSTR* name)

IApplicationViewCollection  {1841C6D7-4F9D-42C0-AF41-8747538F10E5}  OneCoreUAPCommonProxyStub.dll
 3  GetViews(IObjectArray** views)
 4  GetViewsByZOrder(IObjectArray** views)
 5  GetViewsByAppUserModelId(PCWSTR app_id, IObjectArray** views)
 6  GetViewForHwnd(HWND window, IApplicationView** view)
 7  GetViewForApplication(IImmersiveApplication* application, IApplicationView** view)
 8  GetViewForAppUserModelId(PCWSTR app_id, IApplicationView** view)
 9  GetViewInFocus(IApplicationView** view)
10  TryGetLastActiveVisibleView(IApplicationView** view)
11  RefreshCollection()
12  RegisterForApplicationViewChanges(IApplicationViewChangeListener* listener, DWORD* cookie)
13  UnregisterForApplicationViewChanges(DWORD cookie)

IApplicationViewCollectionManagement : IApplicationViewCollection  {52840C9B-DBCA-427B-94CD-6989EE80A480}  OneCoreUAPCommonProxyStub.dll
14  AddWin32ApplicationView(IClassicWindowExternal* window, IApplicationView** view)
15  AddWinRTApplicationView(IImmersiveApplication* application, IUnknown*)
16  AddApplicationView(IApplicationView* view)
17  RemoveApplicationView(IApplicationView* view, REMOVE_APPLICATION_VIEW_OPTIONS options)
18  SetViewInFocus(IApplicationView* view)
19  SetViewPendingFocus(IApplicationView* view)
20  HandleWindowReplaced(HWND old, HWND new)  [local]
21  RaiseApplicationViewChanged(IApplicationView* view, APPLICATION_VIEW_CHANGE change, IUnknown* context)

IApplicationViewChangeListener  {727F9E97-76EE-497B-A942-B6371328485C}  OneCoreUAPCommonProxyStub.dll
 3  OnApplicationViewChanged(IApplicationView* view, APPLICATION_VIEW_CHANGE change, IUnknown* context)
```

The `IApplicationViewCollection2` interface `{BC0E1680-C223-45E5-A40F-EFC7D939FE18}` has a proxy but no implementation on this build, so `QueryInterface` for it returns `E_NOINTERFACE`.

### Multitasking Views

```
IMultitaskingViewVisibilityService  {AC11CDA3-1601-4AD7-A40E-FE2CED187307}  actxprxy.dll
 3  IsViewVisible(MULTITASKING_VIEW_TYPES mask, MULTITASKING_VIEW_TYPES* visible)
 4  Register(IMultitaskingViewVisibilityNotification* notification, DWORD* cookie)
 5  Unregister(DWORD cookie)

IMultitaskingViewVisibilityNotification  {C59A7A3C-0676-4526-8192-5D0BF9B89B95}  actxprxy.dll
 3  MultitaskingViewShown(MULTITASKING_VIEW_TYPES type)
 4  MultitaskingViewDismissed(MULTITASKING_VIEW_TYPES type)
```

### Animation, Hotkeys, and Switcher

```
IVirtualDesktopAnimationSyncNotificationService  {0DDAF2D8-C38F-4638-95FC-FB9C6DDAE52F}  actxprxy.dll
 3  Register(IVirtualDesktopAnimationSyncNotification* notification, DWORD* cookie)
 4  Unregister(DWORD cookie)

IVirtualDesktopAnimationSyncNotification  {6CAFD3F1-05D1-4D26-A32A-9907A72C920B}  actxprxy.dll
 3  CurrentVirtualDesktopChangedAnimated(IVirtualDesktop* old, IVirtualDesktop* new)

IVirtualDesktopHotkeyHandler  {44B664EC-253C-4F5C-827B-78FB573756AE}  actxprxy.dll
 3  HandleHotkey(IMMERSIVE_HOT_KEY_ID id)

IVirtualDesktopSwitcherInvoker  {7A25165A-86F1-4B4A-B1D2-E89650CD9589}  actxprxy.dll
 3  ShowVirtualDesktopSwitcher(HMONITOR monitor, VIRTUAL_DESKTOP_SWITCHER_INVOKE_DETAILS details)
 4  DismissVirtualDesktopSwitcher()

IVirtualDesktopTabletModePolicyService  {56B32065-0BB3-42E2-975D-A559DE1316E8}  actxprxy.dll
 3  TabletModePositionerControlLost(IAppLayout* layout)

IVirtualDesktopAccessibility  {9975B71D-0A84-4909-BDDE-B455BBFA55C6}  actxprxy.dll
 3  GetCurrentDesktopName(BSTR* name)
```

None of the services above returns the accessibility interface.

## Enumerations

The names of directions 5 and 6 belong to these bindings. Left and right follow the layout, so they swap under a right-to-left language.

```
GetAdjacentDesktop direction
 3  Left       The previous desktop.
 4  Right      The next desktop.
 5  Forward    The next desktop, whatever the layout.
 6  Backward   The previous desktop, whatever the layout.
```

The `APPLICATION_VIEW_CHANGE` names are the shell's own. The value 5 has no name of its own: the shell logs it as `AVC_HIDDEN`, and it follows a new window joining a desktop.

```
APPLICATION_VIEW_CHANGE
 0  AVC_ADDED                                  11  AVC_REMOVED_FROM_SWITCHERS
 1  AVC_REMOVED                                12  AVC_THUMBNAIL_WINDOW
 2  AVC_FORGOTTEN                              13  AVC_MONITOR_CHANGED
 3  AVC_VISIBLE                                14  AVC_WINDOW_CHANGED
 4  AVC_HIDDEN                                 15  AVC_SIZE_CONSTRAINTS
 5  (logged as AVC_HIDDEN)                     16  AVC_TRAY_CHANGED
 6  AVC_NEEDINESS                              17  AVC_OWNER_CHANGED
 7  AVC_FOCUS                                  18  AVC_ENTERPRISEID_CHANGED
 8  AVC_PENDING_FOCUS                          19  AVC_ENTERPRISE_CHROME_PREFERENCE_CHANGED
 9  AVC_UNFOCUS                                20  AVC_CANTAB
10  AVC_SHOW_IN_SWITCHERS
```

The `MULTITASKING_VIEW_TYPES` values are bits, so `IsViewVisible` takes a mask. The snap assist and PPI all-up views have bits of their own that this map does not cover.

```
MULTITASKING_VIEW_TYPES
0x01  Alt+Tab
0x02  Task View
0x10  Virtual desktop switcher
```

The `IMMERSIVE_HOT_KEY_ID` values below are the ones `HandleHotkey` accepts, and any other value returns `E_NOTIMPL`. A step past either end of the list fails with `TYPE_E_OUTOFBOUNDS`.

```
IMMERSIVE_HOT_KEY_ID
 36  Switch to the desktop on the left
 37  Switch to the desktop on the right
 38  Create a desktop and switch to it
 39  Remove the current desktop
109  Move the foreground window to the desktop on the left and switch with it
110  Move the foreground window to the desktop on the right and switch with it
```

The `VirtualDesktopSwitchType` is 0 for each local switch, including `SwitchDesktop`, `SwitchDesktopWithAnimation`, `SwitchDesktopAndMoveForegroundView`, and Win+Ctrl+arrow. The `SwitchRemoteDesktop` method switches to any desktop, a local one included, and hands its type to `VirtualDesktopSwitched` unchanged.

## Special Desktop IDs

| Desktop ID | Description |
|------------|-------------|
| `{C2DDEA68-66F2-4CF9-8264-1BFD00FBBBAC}` | The id of a window pinned with `PinView`, returned by `GetVirtualDesktopId` and the public `GetWindowDesktopId`. |
| `{BB64D5B7-4DE3-4AB2-A87C-DB7601AEA7DC}` | The id of each window of an app pinned with `PinAppID`, returned by the same two methods. |
| `{00000000-0000-0000-0000-000000000000}` | The id of a view without a desktop of its own, such as an owned window, which shares the desktop of its owner. |

## Behavior

### Switching

- The `SwitchDesktop` method changes the current desktop before it returns, and the events follow on an RPC thread: `CurrentVirtualDesktopChanged`, then `VirtualDesktopSwitched`.
- A switch to the desktop that is already current fires `VirtualDesktopSwitched` alone.
- The `SwitchDesktopWithAnimation` method also changes the current desktop before it returns, and `WaitForAnimationToComplete` blocks for the slide, about 370 ms.
- The `SwitchDesktopAndMoveForegroundView` method takes the foreground window along, which from a console app is the console itself.
- The shell hides the windows of other desktops by cloaking them, so a window on another desktop reports `DWMWA_CLOAKED` as `DWM_CLOAKED_SHELL` (2). A tiler that enumerates top-level windows has to skip cloaked ones.
- The `GetLastActiveDesktop` method returns the desktop that was current before the last switch, and it keeps returning that desktop after it is removed. Until the first switch after explorer starts, it returns a desktop outside `GetDesktops`.
- The animation sync notification does not fire for API, keyboard, or hotkey handler switches, and only the taskbar registers for it.

### Desktop List

- The `CreateDesktop` method has no count limit in the shell, which holds at least 40 desktops. The bindings work with at most `DESKTOPS_MAX` desktops, so `createDesktop` and `getDesktops` fail with `DesktopLimitReached` past it.
- The `RemoveDesktop` method fails with `E_INVALIDARG` when the fallback is the desktop being removed, a desktop outside the list, or a remote desktop. An attempt to remove the only desktop therefore fails with `E_INVALIDARG`, since no valid fallback exists.
- The `CreateDesktop`, `CreateRemoteDesktop`, `MoveDesktop`, `MoveViewToDesktop`, and `RemoveDesktop` methods fail with `ERROR_INVALID_STATE` while the shell holds desktop changes suspended. Neither Task View nor Alt+Tab suspends them.
- A `MoveDesktop` to the current index returns `S_OK` without moving, and an index past the end fails with `E_INVALIDARG`.
- The `SetDesktopName` method stores a name of at least 300,000 UTF-16 code units, and a null `HSTRING` clears the name, which then reads back as an empty string.
- The bindings read and write names and wallpaper paths of up to `NAME_LEN_MAX` UTF-8 bytes. A longer one fails with `StringTooLong`, and a notification delivers it cut at the last whole character that fits.
- The `FindDesktop` method fails with `TYPE_E_ELEMENTNOTFOUND` for an unknown id.
- A `GetAdjacentDesktop` step past either end fails with `TYPE_E_OUTOFBOUNDS`, and a null starting desktop returns the first desktop for right and forward and the last for left and backward.
- The `CreateRemoteDesktop` method appends a desktop with the given name, for which `IsRemote` returns true, and it fires no `RemoteVirtualDesktopConnected`.

### Wallpapers

- The `SetDesktopWallpaper` method stores a path for the desktop and fires `VirtualDesktopWallpaperChanged`. The shell applies the path when that desktop is current or becomes current, and a null `HSTRING` clears the path.
- The `UpdateWallpaperPathForAllDesktops` method gives each desktop the same path, applies it, and fires `VirtualDesktopWallpaperChanged` for each desktop.
- A wallpaper set with `SPI_SETDESKWALLPAPER` becomes the path of the current desktop.
- The `GetWallpaper` method returns an empty string while the background is a solid color, a slideshow, or Windows Spotlight, and while desktop background images are turned off, even when the desktop has a path of its own.

### Moving Windows

- The public `MoveWindowToDesktop` compares the process that owns the window with the RPC caller and fails with `E_ACCESSDENIED` for a window of another process. The internal `MoveViewToDesktop` has no such check, which is why the bindings use it.
- The `CanViewMoveDesktops` method returns false for a window in the UIAccess or system tools z-order band, and for a window the shell itself registers in its app bar role. A window that registers with `SHAppBarMessage` still returns true.
- Each move fires `ViewVirtualDesktopChanged`.
- The `CopyDesktopState` method gives the target view the desktop and the pin state of the source view.

### Owned and Tool Windows

- An ownership tree shares one desktop. A move of the owner, or of an owned window with `WS_EX_APPWINDOW`, moves the whole tree, and the owned windows are cloaked along with the owner.
- An owned window without `WS_EX_APPWINDOW` has no desktop of its own. Its view reports the zero id, the public `GetWindowDesktopId` returns the zero id, and `IsViewVisible` returns true on each desktop.
- The public `IsWindowOnCurrentVirtualDesktop` returns true for such an owned window even while it is cloaked with its owner on another desktop.
- A `MoveViewToDesktop` of such an owned window fails with `ERROR_INVALID_STATE` after the shell has written the new id to its view, and the window stays with its owner.
- A `PinView` of such an owned window succeeds and marks that view alone as pinned.
- An unowned window with `WS_EX_TOOLWINDOW` has no view, so `GetViewForHwnd` fails with `TYPE_E_ELEMENTNOTFOUND`. The shell never cloaks it, so it shows on each desktop.
- The bindings resolve a window without a desktop of its own to the root of its ownership tree, and a child window to its top-level window, so each window call on an owned window acts on its owner.

### Application Views

- The getters of `IApplicationView` work from another process, apart from the ones below.
- The `GetRuntimeClassName`, `GetViewState`, `SetShowInSwitchers`, and `SetLastActivationTimestamp` methods return `E_NOTIMPL` for a Win32 window.
- The `GetPositionerPriority` method fails with `REGDB_E_IIDNOTREG` for another process, since `IShellPositionerPriority` has no proxy.
- The `SetFocus` method fails with `E_ACCESSDENIED` for another process.
- The `GetRootSwitchableOwner` method returns the view of the owner for an owned window, and fails with `ERROR_NOT_FOUND` for an unowned one.
- The `IsTray` and `GetShowInSwitchers` methods return true for a window with a taskbar button, such as an unowned window or an owned window with `WS_EX_APPWINDOW`, and false for another owned window.

### Pinning

- The `PinView` method sets the desktop id of the view to the pinned view id, and `PinAppID` sets each window of the app to the pinned app id.
- The `IsViewVisible` method returns true on each desktop for a pinned window, and `IsViewPinned` returns true for either kind of pin.
- The `IsAppIdPinned`, `PinAppID`, and `UnpinAppID` methods marshal the app id as a `[ref]` string, so a null app id fails in the local proxy with `RPC_X_NULL_REF_POINTER`.
- Each pin and unpin fires `ViewVirtualDesktopChanged`.

### Notifications

- Each callback arrives on a COM RPC thread of the MTA, and two callbacks for one switch can arrive on different threads. An app that depends on ordering has to serialize them itself.
- A callback can call back into the shell, such as `GetID`, `GetDesktops`, or `GetThumbnailWindow`, without deadlocking.
- Explorer calls the listeners one at a time, so a callback that blocks delays each later delivery, to every listener. A call such as `SwitchDesktop` returns without waiting for the listeners.
- A listener object stays referenced by COM after `Unregister` returns, and for good once explorer exits, so its memory must not be reused until `CoDisconnectObject` has dropped those references.
- A thread in an STA receives callbacks only while it pumps messages.

### Explorer Restarts

- A call on a proxy from an explorer that exited fails with `RPC_S_SERVER_UNAVAILABLE`, and `CoCreateInstance` on `CLSID_ImmersiveShell` fails with `REGDB_E_CLASSNOTREG` until the new explorer registers the class.
- The new shell answers about a second after `explorer.exe` starts. A fresh connection then works, and each registration has to be repeated.
- Explorer keeps the desktop of each window under `SessionInfo` in the registry, so the windows return to their desktops after the restart.
- The `Service` of these bindings reconnects on `ServiceNotConnected` and repeats its registrations.

### Hazards

- The `HandleHotkey` method with 36, 37, or 38, called from another process, performs the action and then leaves the animation path of explorer wedged until explorer restarts. While it is wedged, `WaitForAnimationToComplete` and `SwitchDesktopWithAnimation` block, Win+Ctrl+arrow switches nothing, while `SwitchDesktop` still switches. The IDs 39, 109, and 110 leave it intact.
- The `ShowVirtualDesktopSwitcher` method fails with `E_ACCESSDENIED` for another process.
- The `IApplicationViewCollectionManagement` interface answers `QueryInterface` on the view collection and exposes methods that add, remove, and refocus entries in the window list of the shell. A call from an app edits state the shell owns, so the bindings leave it out.

## Error Codes

| HRESULT | Name | Source | Library Error |
|---------|------|--------|---------------|
| `0x80040154` | `REGDB_E_CLASSNOTREG` | The `CoCreateInstance` call fails with it while explorer is down. | `ServiceNotConnected` |
| `0x800706BA` | `RPC_S_SERVER_UNAVAILABLE` | A proxy from an explorer that exited fails with it. | `ServiceNotConnected` |
| `0x80010108` | `RPC_E_DISCONNECTED` | A disconnected shell object fails with it, and a switch returns it before the view collection is attached. | `ServiceNotConnected` |
| `0x8002802B` | `TYPE_E_ELEMENTNOTFOUND` | The `FindDesktop` and `GetViewForHwnd` methods return it for an unknown id or a window without a view. | `DesktopNotFound` or `WindowNotFound` |
| `0x80028CA1` | `TYPE_E_OUTOFBOUNDS` | The `GetAdjacentDesktop` and `HandleHotkey` methods return it for a step past either end of the list. | `DesktopNotFound` |
| `0x80070005` | `E_ACCESSDENIED` | The public `MoveWindowToDesktop`, `ShowVirtualDesktopSwitcher`, and `IApplicationView::SetFocus` return it to another process. | `AccessDenied` |
| `0x80070057` | `E_INVALIDARG` | The shell returns it for a desktop outside the list, a bad direction, a move past the end, and a removal without a valid fallback. | `InvalidArgument` |
| `0x800706F4` | `RPC_X_NULL_REF_POINTER` | The local proxy returns it for a null `[ref]` argument. | `InvalidArgument` |
| `0x8007139F` | `ERROR_INVALID_STATE` | The shell returns it for a desktop change while changes are suspended, and for a move of an owned window without a desktop of its own. | `InvalidState` |
| `0x80004005` | `E_FAIL` | The `GetLastActiveDesktop` method can return it when the shell has no last desktop. | `ComCallFailed` |

## Registry

The registry is the persistence of explorer, read at startup and written as state changes, so it suits a read-only view of the desktops. The keys sit under `HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer`.

| Key or Value | Description |
|--------------|-------------|
| `VirtualDesktops\VirtualDesktopIDs` | The desktop ids in order, as 16-byte GUIDs packed into one `REG_BINARY` value. |
| `VirtualDesktops\CurrentVirtualDesktop` | The id of the current desktop as a 16-byte `REG_BINARY` value. |
| `VirtualDesktops\Desktops\{id}\Name` | The name of a desktop as `REG_SZ`, present once a name is set. |
| `VirtualDesktops\Desktops\{id}\Wallpaper` | The wallpaper path of a desktop as `REG_SZ`, present once a wallpaper is set. |
| `VirtualDesktops\PinnedApps\<app id>` | A `REG_DWORD` of 0 for each app pinned with `PinAppID`. |
| `SessionInfo\<session>\ApplicationViewManagement\W32:<hwnd>` | The desktop and cloak type of a window, which explorer restores after a restart. |

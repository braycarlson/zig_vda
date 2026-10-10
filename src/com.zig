const std = @import("std");
const guid = @import("guid.zig");
const vd = @import("vd.zig");

const GUID = guid.GUID;
const HRESULT = vd.HRESULT;

pub const HSTRING = ?*anyopaque;

pub const CLSCTX_INPROC_SERVER: u32 = 0x1;
pub const CLSCTX_INPROC_HANDLER: u32 = 0x2;
pub const CLSCTX_LOCAL_SERVER: u32 = 0x4;
pub const CLSCTX_REMOTE_SERVER: u32 = 0x10;
pub const CLSCTX_ALL: u32 = CLSCTX_INPROC_SERVER | CLSCTX_INPROC_HANDLER | CLSCTX_LOCAL_SERVER | CLSCTX_REMOTE_SERVER;

pub const COINIT_APARTMENTTHREADED: u32 = 0x2;
pub const COINIT_MULTITHREADED: u32 = 0x0;

pub const IUnknownVtbl = extern struct {
    QueryInterface: *const fn (*IUnknown, *const GUID, *?*anyopaque) callconv(.winapi) HRESULT,
    AddRef: *const fn (*IUnknown) callconv(.winapi) u32,
    Release: *const fn (*IUnknown) callconv(.winapi) u32,
};

pub const IUnknown = extern struct {
    vtable: *const IUnknownVtbl,

    pub fn release(self: *IUnknown) u32 {
        return self.vtable.Release(self);
    }
};

extern "ole32" fn CoInitializeEx(reserved: ?*anyopaque, coinit: u32) callconv(.winapi) HRESULT;
extern "ole32" fn CoUninitialize() callconv(.winapi) void;
extern "ole32" fn CoIncrementMTAUsage(cookie: *?*anyopaque) callconv(.winapi) HRESULT;
extern "ole32" fn CoCreateInstance(
    rclsid: *const GUID,
    punk_outer: ?*IUnknown,
    cls_context: u32,
    riid: *const GUID,
    ppv: *?*anyopaque,
) callconv(.winapi) HRESULT;
extern "ole32" fn CoTaskMemFree(pv: ?*anyopaque) callconv(.winapi) void;
extern "ole32" fn CoDisconnectObject(unknown: *anyopaque, reserved: u32) callconv(.winapi) HRESULT;

extern "kernel32" fn LoadLibraryA(name: [*:0]const u8) callconv(.winapi) ?std.os.windows.HMODULE;
extern "kernel32" fn GetProcAddress(module: std.os.windows.HMODULE, name: [*:0]const u8) callconv(.winapi) ?*anyopaque;
extern "kernel32" fn AcquireSRWLockExclusive(lock: *SRWLOCK) callconv(.winapi) void;
extern "kernel32" fn ReleaseSRWLockExclusive(lock: *SRWLOCK) callconv(.winapi) void;

const SRWLOCK = std.os.windows.SRWLOCK;

const Mutex = struct {
    srwlock: SRWLOCK = .{},

    fn lock(self: *Mutex) void {
        AcquireSRWLockExclusive(&self.srwlock);
    }

    fn unlock(self: *Mutex) void {
        ReleaseSRWLockExclusive(&self.srwlock);
    }
};

const CreateStringFn = *const fn (?[*]const u16, u32, *HSTRING) callconv(.winapi) HRESULT;
const DeleteStringFn = *const fn (HSTRING) callconv(.winapi) HRESULT;
const GetRawBufferFn = *const fn (HSTRING, ?*u32) callconv(.winapi) ?[*:0]const u16;

var combase_loaded = std.atomic.Value(bool).init(false);
var combase_mutex: Mutex = .{};
var fn_create_string: ?CreateStringFn = null;
var fn_delete_string: ?DeleteStringFn = null;
var fn_get_raw_buffer: ?GetRawBufferFn = null;

fn loadCombase() void {
    if (combase_loaded.load(.acquire)) return;

    combase_mutex.lock();
    defer combase_mutex.unlock();

    if (combase_loaded.load(.acquire)) return;

    const dll = LoadLibraryA("combase.dll") orelse {
        combase_loaded.store(true, .release);
        return;
    };

    fn_create_string = @ptrCast(GetProcAddress(dll, "WindowsCreateString"));
    fn_delete_string = @ptrCast(GetProcAddress(dll, "WindowsDeleteString"));
    fn_get_raw_buffer = @ptrCast(GetProcAddress(dll, "WindowsGetStringRawBuffer"));
    combase_loaded.store(true, .release);
}

pub fn initialize(coinit: u32) !void {
    const hr = CoInitializeEx(null, coinit);
    if (hr < 0) return error.ComInitFailed;
}

pub fn uninitialize() void {
    CoUninitialize();
}

pub fn ensureMTAInitialized() void {
    var cookie: ?*anyopaque = null;
    _ = CoIncrementMTAUsage(&cookie);
}

pub fn createInstance(comptime T: type, clsid: *const GUID, context: u32, iid: *const GUID) !*T {
    var obj: ?*anyopaque = null;
    const hr = CoCreateInstance(clsid, null, context, iid, &obj);
    if (hr < 0 or obj == null) return error.ComCreateFailed;

    return @ptrCast(@alignCast(obj.?));
}

pub fn releaseObj(ptr: anytype) void {
    _ = @as(*IUnknown, @ptrCast(@alignCast(ptr))).release();
}

pub fn taskMemFree(ptr: ?*anyopaque) void {
    CoTaskMemFree(ptr);
}

pub fn disconnectObject(object: *anyopaque) void {
    _ = CoDisconnectObject(object, 0);
}

pub const HSTRING_UTF8_MAX = 3072;

pub fn createHString(utf8: []const u8) vd.Error!HSTRING {
    loadCombase();
    const create = fn_create_string orelse return vd.Error.ComCallFailed;

    if (utf8.len > HSTRING_UTF8_MAX) return vd.Error.StringTooLong;

    var wide_buf: [HSTRING_UTF8_MAX]u16 = undefined;
    const wide_len = std.unicode.utf8ToUtf16Le(&wide_buf, utf8) catch return vd.Error.InvalidArgument;

    var result: HSTRING = null;
    const hr = create(&wide_buf, @intCast(wide_len), &result);
    try vd.hresultToError(hr);

    return result;
}

pub fn deleteHString(string: HSTRING) void {
    loadCombase();
    const delete = fn_delete_string orelse return;
    _ = delete(string);
}

pub fn hstringToUtf8(string: HSTRING, buf: []u8) vd.Error![]const u8 {
    loadCombase();
    const get_buf = fn_get_raw_buffer orelse return vd.Error.ComCallFailed;

    var length: u32 = 0;
    const raw = get_buf(string, &length);

    if (raw == null or length == 0) return buf[0..0];

    const ptr = raw.?;
    const utf16_slice = ptr[0..length];
    if (std.unicode.calcWtf8Len(utf16_slice) > buf.len) return vd.Error.StringTooLong;

    const utf8_len = std.unicode.wtf16LeToWtf8(buf, utf16_slice);

    return buf[0..utf8_len];
}

pub fn hstringToUtf8Truncated(string: HSTRING, buf: []u8) []const u8 {
    loadCombase();
    const get_buf = fn_get_raw_buffer orelse return buf[0..0];

    var length: u32 = 0;
    const raw = get_buf(string, &length);

    if (raw == null or length == 0) return buf[0..0];

    const ptr = raw.?;
    var iterator = std.unicode.Wtf16LeIterator.init(ptr[0..length]);
    var utf8_len: usize = 0;

    while (iterator.nextCodepoint()) |codepoint| {
        const size = std.unicode.utf8CodepointSequenceLength(codepoint) catch break;
        if (utf8_len + size > buf.len) break;

        utf8_len += std.unicode.wtf8Encode(codepoint, buf[utf8_len..]) catch break;
    }

    return buf[0..utf8_len];
}

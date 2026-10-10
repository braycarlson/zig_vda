pub const GUID = extern struct {
    data1: u32,
    data2: u16,
    data3: u16,
    data4: [8]u8,

    pub const ZERO: GUID = .{
        .data1 = 0,
        .data2 = 0,
        .data3 = 0,
        .data4 = .{ 0, 0, 0, 0, 0, 0, 0, 0 },
    };

    pub fn eql(self: GUID, other: GUID) bool {
        return self.data1 == other.data1 and
            self.data2 == other.data2 and
            self.data3 == other.data3 and
            @as(u64, @bitCast(self.data4)) == @as(u64, @bitCast(other.data4));
    }
};

fn parseGuid(comptime str: []const u8) GUID {
    comptime {
        if (str.len != 36 and str.len != 38) @compileError("Invalid GUID string length");
        const s = if (str[0] == '{') str[1..37] else str[0..36];

        return GUID{
            .data1 = parseHex(u32, s[0..8]),
            .data2 = parseHex(u16, s[9..13]),
            .data3 = parseHex(u16, s[14..18]),
            .data4 = .{
                parseHex(u8, s[19..21]), parseHex(u8, s[21..23]),
                parseHex(u8, s[24..26]), parseHex(u8, s[26..28]),
                parseHex(u8, s[28..30]), parseHex(u8, s[30..32]),
                parseHex(u8, s[32..34]), parseHex(u8, s[34..36]),
            },
        };
    }
}

fn parseHex(comptime T: type, comptime str: []const u8) T {
    comptime {
        var result: T = 0;

        for (str) |c| {
            const digit: T = switch (c) {
                '0'...'9' => c - '0',
                'a'...'f' => c - 'a' + 10,
                'A'...'F' => c - 'A' + 10,
                else => @compileError("Invalid hex character"),
            };

            result = result * 16 + digit;
        }

        return result;
    }
}

pub const IID_IUnknown = parseGuid("00000000-0000-0000-C000-000000000046");
pub const IID_IServiceProvider = parseGuid("6D5140C1-7436-11CE-8034-00AA006009FA");
pub const IID_IObjectArray = parseGuid("92CA9DCD-5622-4BBA-A805-5E9F541BD8C9");

pub const CLSID_VirtualDesktopManager = parseGuid("AA509086-5CA9-4C25-8F95-589D3C07B48A");
pub const IID_IVirtualDesktopManager = parseGuid("A5CD92FF-29BE-454C-8D04-D82879FB3F1B");

pub const CLSID_ImmersiveShell = parseGuid("C2F03A33-21F5-47FA-B4BB-156362A2F239");
pub const SID_VirtualDesktopManager = parseGuid("C5E0CDCA-7B6E-41B2-9FC4-D93975CC467B");
pub const SID_VirtualDesktopPinnedApps = parseGuid("B5A399E7-1C87-46B8-88E9-FC5747B171BD");
pub const SID_VirtualDesktopNotificationService = parseGuid("A501FDEC-4A09-464C-AE4E-1B9C21B84918");
pub const SID_MultitaskingViewVisibilityService = parseGuid("785702DD-B8EF-469F-8C19-E91B5F4CA564");

pub const IID_IVirtualDesktop = parseGuid("3F07F4BE-B107-441A-AF0F-39D82529072C");
pub const IID_IVirtualDesktop2 = parseGuid("A871910E-6CC0-4E65-8B9B-458CE9115E30");
pub const IID_IVirtualDesktopManagerInternal = parseGuid("4970BA3D-FD4E-4647-BEA3-D89076EF4B9C");
pub const IID_IVirtualDesktopManagerInternal2 = parseGuid("53F5CA0B-158F-4124-900C-057158060B27");
pub const IID_IApplicationView = parseGuid("372E1D3B-38D3-42E4-A15B-8AB2B178F513");
pub const IID_IApplicationViewCollection = parseGuid("1841C6D7-4F9D-42C0-AF41-8747538F10E5");
pub const IID_IApplicationViewChangeListener = parseGuid("727F9E97-76EE-497B-A942-B6371328485C");
pub const IID_IVirtualDesktopPinnedApps = parseGuid("4CE81583-1E4C-4632-A621-07A53543148F");
pub const IID_IVirtualDesktopNotificationService = parseGuid("0CD45E71-D927-4F15-8B0A-8FEF525337BF");
pub const IID_IVirtualDesktopNotification = parseGuid("B9E5E94D-233E-49AB-AF5C-2B4541C3AADE");
pub const IID_IMultitaskingViewVisibilityService = parseGuid("AC11CDA3-1601-4AD7-A40E-FE2CED187307");
pub const IID_IMultitaskingViewVisibilityNotification = parseGuid("C59A7A3C-0676-4526-8192-5D0BF9B89B95");

pub const DESKTOP_ID_PINNED_VIEW = parseGuid("C2DDEA68-66F2-4CF9-8264-1BFD00FBBBAC");
pub const DESKTOP_ID_PINNED_APP = parseGuid("BB64D5B7-4DE3-4AB2-A87C-DB7601AEA7DC");

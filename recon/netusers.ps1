Add-Type -TypeDefinition @"
    using System;
    using System.Runtime.InteropServices;

    public class NetApi32 {
        [DllImport("netapi32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
        public static extern int NetUserEnum(
            [MarshalAs(UnmanagedType.LPWStr)] string servername,
            int level,
            int filter,
            out IntPtr bufptr,
            int prefmaxlen,
            out int entriesread,
            out int totalentries,
            ref int resume_handle
        );

        [DllImport("netapi32.dll")]
        public static extern int NetApiBufferFree(IntPtr Buffer);
    }

    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    public struct USER_INFO_0 {
        public string usri0_name;
    }
"@

function Get-LocalUsers {
    $level = 0
    $filter = 0
    $resumeHandle = 0

    do {
        $buffer = [IntPtr]::Zero
        $entriesRead = 0
        $totalEntries = 0

        $result = [NetApi32]::NetUserEnum("\\localhost", $level, $filter, [ref] $buffer, -1, [ref] $entriesRead, [ref] $totalEntries, [ref] $resumeHandle)

        if ($result -eq 0 -or $result -eq 234) {
            for ($i = 0; $i -lt $entriesRead; $i++) {
                $userPtr = [IntPtr]($buffer.ToInt64() + $i * [System.Runtime.InteropServices.Marshal]::SizeOf([type][USER_INFO_0]))
                $userInfo = [USER_INFO_0] [System.Runtime.InteropServices.Marshal]::PtrToStructure($userPtr, [type][USER_INFO_0])

                $userInfo.usri0_name
            }
        }

        [NetApi32]::NetApiBufferFree($buffer)
    } while ($result -eq 234)
}

Get-LocalUsers | ForEach-Object { Write-Host "Username: $_" }

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

        [DllImport("netapi32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
        public static extern int NetUserGetGroups(
            [MarshalAs(UnmanagedType.LPWStr)] string servername,
            [MarshalAs(UnmanagedType.LPWStr)] string username,
            int level,
            out IntPtr bufptr,
            int prefmaxlen,
            out int entriesread,
            out int totalentries
        );

        [DllImport("netapi32.dll")]
        public static extern int NetApiBufferFree(IntPtr Buffer);
		
		[DllImport("netapi32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
		public static extern int NetUserGetLocalGroups(
			[MarshalAs(UnmanagedType.LPWStr)] string servername,
			[MarshalAs(UnmanagedType.LPWStr)] string username,
			int level,
			int flags,
			out IntPtr bufptr,
			int prefmaxlen,
			out int entriesread,
			out int totalentries
		);
    }

    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    public struct USER_INFO_0 {
        public string usri0_name;
    }

	[StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
	public struct GROUP_USERS_INFO_0 {
    public string grui0_name;
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

                $username = $userInfo.usri0_name
                $groups = Get-LocalUserGroups -Username $username
                [PSCustomObject]@{
                    Username = $username
                    Groups = $groups -join ", "
                }
            }
        }

        [NetApi32]::NetApiBufferFree($buffer)
    } while ($result -eq 234)
}

function Get-LocalUserGroups {
    param(
        [string]$Username
    )

    $level = 0
    $buffer = [IntPtr]::Zero
    $entriesRead = 0
    $totalEntries = 0

    $result = [NetApi32]::NetUserGetLocalGroups("\\localhost", $Username, $level, 0, [ref] $buffer, -1, [ref] $entriesRead, [ref] $totalEntries)

    if ($result -eq 0) {
        $groups = @()

        for ($i = 0; $i -lt $entriesRead; $i++) {
            $groupPtr = [IntPtr]($buffer.ToInt64() + $i * [System.Runtime.InteropServices.Marshal]::SizeOf([type][GROUP_USERS_INFO_0]))
			$groupInfo = [GROUP_USERS_INFO_0] [System.Runtime.InteropServices.Marshal]::PtrToStructure($groupPtr, [type][GROUP_USERS_INFO_0])

            $groups += $groupInfo.grui0_name
        }

        [NetApi32]::NetApiBufferFree($buffer)

        return $groups
    } else {
        Write-Host "Error: Unable to retrieve groups for user '$Username'."
        return @()
    }
}

$results = Get-LocalUsers

$results | Format-Table -AutoSize

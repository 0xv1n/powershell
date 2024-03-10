# https://ss64.com/nt/fltmc.html
# Minifilters are assigned a specific altitude by Microsoft. This will sit within a range that is specific to the function of the minifilter.
#   e.g. Anti-Virus minifilters are assigned an altitude between 320,000 and 329,999.
#   and encryption minifilters are assigned an altitude between 140,000 and 149,999.

#  For file Writes, Altitudes are processed in descending order.
#  For file Reads, Altitudes are processed in ascending order.

So when writing anti-virus is handled before encryption, but when reading decryption is handled before anti-virus.
fltmc | Where-Object { $_ -match '^\s*([\w]+)\s+(\d+)\s+(\d+)\s+(\d+)' -and $matches[3] -ge 320000 -and $matches[3] -le 329999 } | ForEach-Object {
    $driverName = $matches[1]
    $altitude = [int]$matches[3]
    
    $driverInfo = Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\$driverName" -ErrorAction SilentlyContinue
    if ($driverInfo) {
        [PSCustomObject]@{
            FilterName = $driverName
            NumInstances = [int]$matches[2]
            Altitude = $altitude
            Frame = [int]$matches[4]
            DisplayName = $driverInfo.DisplayName
            StartType = $driverInfo.StartType
            Status = $driverInfo.Status
        }
    }
}

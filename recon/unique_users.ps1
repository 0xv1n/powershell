$logName = "Security"

# Calculate the start time for the last 30 days
$startTime = (Get-Date).AddDays(-30)

# Specify the log file path where the data will be exported
$exportPath = "C:\some\path\ExportedLogonData.csv"

# Query the event log for logon events in the last 30 days
$logonEvents = Get-EventLog -LogName $logName -InstanceId 4624 -After $startTime

$logonData = @()
$uniqueUsernames = @()

# Process each logon event and extract the username and timestamp
foreach ($event in $logonEvents) {
    $username = $event.ReplacementStrings[5]
    $timestamp = $event.TimeGenerated

    # Exclude specified usernames and GUIDs
    if ($username -notin @("SYSTEM", "LOCAL SERVICE", "NETWORK SERVICE") -and
        -not ($username -like "DWM-*" -or $username -like "UMFD-*") -and
        -not ([System.Guid]::TryParse($username, [ref][System.Guid]::Empty))
    ) {
        $logonData += [PSCustomObject]@{
            "Username" = $username
            "LastSignIn" = $timestamp
        }

        if ($username -notin $uniqueUsernames) {
            $uniqueUsernames += $username
        }
    }
}

Write-Host "Unique Usernames:"
$uniqueUsernames

# Export the logon data to a CSV file
$logonData | Export-Csv -Path $exportPath -NoTypeInformation
Write-Host "Logon data exported to $exportPath"

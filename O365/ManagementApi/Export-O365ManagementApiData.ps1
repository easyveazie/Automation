<#
.SYNOPSIS
    Exports audit data collected via Office 365 Management API

.DESCRIPTION
    The Office 365 Management API has the ability to collect audit data across most O365 services. This script
    shows an example of how to export this data to disk using a user's email.
    See here for an overview:
        https://docs.microsoft.com/en-us/office/office-365-management-api/office-365-management-activity-api-schema

.EXAMPLE
    PS C:\> Export-O365ManagementApiData.ps1 -ExportPath 'C:\temp\export' -DaysToExport 90 -UserId 'user@contoso.com'
.NOTES
    Review this article to understand other parameters and limitations of the Search-UnifiedAuditLog Cmdlet
        https://docs.microsoft.com/en-us/powershell/module/exchange/policy-and-compliance-audit/Search-UnifiedAuditLog?view=exchange-ps
#>
Param(
    [string]$ExportPath,
    [int]$DaysToExport = 90,
    [string]$UserId
)

$UserCredential = Get-Credential
$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $UserCredential -Authentication Basic -AllowRedirection
Import-PSSession $Session -DisableNameChecking

foreach($day in $DaysToExport..0)
{
    "[{0}] On day {1}" -f [DateTime]::Now.ToString(), $day | Write-Host -ForegroundColor: Green    

    $exportFileName = $UserId + "_" + ([DateTime]::Now.AddDays($day * -1)).Date.ToString("s").Split("T")[0] + ".csv"
    $outfile = Join-Path $ExportPath -ChildPath $exportFileName

    $todaysResults = Search-UnifiedAuditLog -UserIds $UserId -StartDate ([DateTime]::Now.AddDays($day * -1)).ToshortDateString() -EndDate ([DateTime]::Now.AddDays($day * -1 + 1)).ToshortDateString()

    if($todaysResults[0].ResultCount -gt 5000)
    {
        # https://docs.microsoft.com/en-us/powershell/module/exchange/policy-and-compliance-audit/Search-UnifiedAuditLog?view=exchange-ps
        "`tMore than 5,000 results returned and will be truncated. Need to implement ReturnLargeSet for more results" | Write-Warning
    }
    
    $todaysResults | Export-Csv $outfile -NoTypeInformation -Force
}

Remove-PSSession $Session
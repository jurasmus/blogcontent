<#
    .SYNOPSIS
    .\export-cap.ps1
    .\export-cap.ps1 -exportPath C:\CABackup-Idefix\

    .DESCRIPTION
    Export Conditional Access policies to JSON files for backup purposes.

    .LINK
    
    .NOTES
    Written by: Julian Rasmussen
    Website:    idefixwiki.no
    BlueSky:    julianrasmussen.bsky.social
    LinkedIn:   https://www.linkedin.com/in/julianrasmussen/
    Twitter:    https://twitter.com/JulianRasmussen
    GitHub:     https://github.com/jurasmus/blogcontent

    .VERSIONS
    1.0 - 15. feb. 2025 - Initial version
#>

# Connect to Microsoft Graph API
param (
    [Parameter(Mandatory=$false)]
    [string]$ExportPath = "C:\CABackup\"
)

# Check and Install Graph module if not installed
$checkModule = "Microsoft.Graph"
$scopes = "Policy.Read.All"

if(-not (Get-Module $checkModule -ListAvailable))
{
    write-host "$checkModule is not installed" -ForegroundColor Red
    Write-Host "Installing $checkModule PowerShell Module" -ForegroundColor Yellow
    Install-Module $checkModule -Scope CurrentUser -Force
    Connect-MgGraph -Scopes $scopes -NoWelcome
    Write-Host "Connected to Microsoft Graph API with scope $scopes permissions" -ForegroundColor Green
}
else {
    Write-Host "$checkModule is already installed" -ForegroundColor Green
    Connect-MgGraph -Scopes $scopes -NoWelcome
    Write-Host "Connected to Microsoft Graph API with scope $scopes permissions" -ForegroundColor Green
}


# Check if the export path exists
if (-not (Test-Path $ExportPath)) {
    Write-Host "Export path $ExportPath does not exist. Creating the path..." -ForegroundColor Yellow
    New-Item -Path $ExportPath -ItemType Directory
    Write-Host "Export path $ExportPath created successfully." -ForegroundColor Green
}

try {
    # Extract all CAP's from tenant via Microsoft Graph API
    $AllPolicies = Get-MgIdentityConditionalAccessPolicy -All

    if ($AllPolicies.Count -eq 0) {
        Write-Host "Non policies found..." -ForegroundColor Yellow
    }
    else {
        # foreach through each policy
        foreach ($Policy in $AllPolicies) {
            try {
                # Get display name of the policy
                $PolicyName = $Policy.DisplayName
            
                # Convert the policy object to JSON with a depth of 6
                $PolicyJSON = $Policy | ConvertTo-Json -Depth 6
            
                # Write the JSON to a file in the export path
                $PolicyJSON | Out-File "$ExportPath\$PolicyName.json" -Force
            
                # Write a success message for the policy backup export
                Write-Host "Exported CA policy: $($PolicyName) to $ExportPath" -ForegroundColor Green
            }
            catch {
                # If error when exporting CA Policy
                Write-Host "Error while exporting CA policy: $($Policy.DisplayName). $($_.Exception.Message)" -ForegroundColor Red
            }
        }
    }
}
catch {
    # write a generic error message
    Write-Host "Error while exporting conditional access policies: $($_.Exception.Message)" -ForegroundColor Red
}
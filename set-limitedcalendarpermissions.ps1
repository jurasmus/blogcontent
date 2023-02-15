<#
    .DESCRIPTION
        This script are used for setting the default calendar permission on all users within the organization to "Limited Details".
        All users can therefor se more information on eachothers calendar.

        Automation is using managed identity for connecting to Exchange Online

    .NOTES
        AUTHOR: Julian Rasmussen
        LASTEDIT: 15.02.2023
#>

# Connect Exchange Online as managed identity

$Tenant = "yourdomain.onmicrosoft.com"
Connect-ExchangeOnline -ManagedIdentity -Organization $Tenant

# Get all user mailboxes
$Users = Get-Mailbox -ResultSize Unlimited -RecipientTypeDetails UserMailbox

# Users exception
$Exception = @("Name X", "Name Y")

# Permissions
$Permission = "LimitedDetails"

# Calendar name languages
$FolderCalendars = @("Agenda", "Calendar", "Calendrier", "Kalender")

# Loop through each user
foreach ($User in $Users) {

    # Get calendar in every user mailbox
    $Calendars = (Get-EXOMailboxFolderStatistics $User.Identity -FolderScope Calendar)

    # Leave permissions if user is exception
    if ($Exception -Contains ($User)) {
        Write-Host "$User is an exception, don't touch permissions" -ForegroundColor Red
    }
    else {

        # Loop through each user calendar
        foreach ($Calendar in $Calendars) {
            $CalendarName = $Calendar.Name

            # Check if calendar exist
            if ($FolderCalendars -Contains $CalendarName) {
                $Cal = $User.Identity.ToString() + ":\$CalendarName"
                $CurrentMailFolderPermission = Get-MailboxFolderPermission -Identity $Cal -User Default
                
                # Set calendar permission / Remove -WhatIf parameter after testing
                Set-MailboxFolderPermission -Identity $Cal -User Default -AccessRights $Permission -WarningAction:SilentlyContinue
                
                # Write output
                if ($CurrentMailFolderPermission.AccessRights -eq "$Permission") {
                    Write-Host $User.Identity already has the permission $CurrentMailFolderPermission.AccessRights -ForegroundColor Yellow
                }
                else {
                    Write-Host $User.Identity added permissions $Permission -ForegroundColor Green
                }
            }
        }
    }
}


<#
# Connect to Azure AD
connect-azuread

# Get the App ID from your Managed ID (navigate to Enterprise applications -> search for your object ID (that you got from Azure Automation) and copy the Application ID)
$AppID = "8497929c-3fc2-765h-8eda-ef1a6c99bb1f"

# Leave these attributes 
$ExchangeOnlineObjectID = (Get-AzureADServicePrincipal -Filter " AppId eq '00000002-0000-0ff1-ce00-000000000000'").ObjectID
$ExchangeRightsID = "dc50a0fb-09a3-484d-be87-e023b12c6440"
$ServicePrincipalID = (Get-AzureADServicePrincipal -Filter "AppId eq '$AppID'").ObjectId 

# Run this to actually give the access (and wait for 5 minutes..)
New-AzureAdServiceAppRoleAssignment -ObjectId $ServicePrincipalID -PrincipalId $ServicePrincipalID -ResourceId $ExchangeOnlineObjectID -Id $ExchangeRightsID

#> 

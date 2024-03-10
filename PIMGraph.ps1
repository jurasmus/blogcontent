<#
.Synopsis
    Activate eligible PIM roles via Microsoft Graph.
.DESCRIPTION
    This script activates eligible Privileged Identity Management (PIM) roles for the current user using Microsoft Graph API.
    It retrieves the eligible roles for the user, and then activates each role with a specified duration and justification.
.EXAMPLE
    $roles = "Exchange Administrator","Intune administrator"
    $justification = "Automated activation via Microsoft Graph"
    .\PIMGraph.ps1
    Activates the "Exchange Administrator" and "Intune administrator" role with the specified justification.
.Notes
Created   : 2023-12-07
Version   : 1.0
Author    : Julian Rasmussen
X         : @julianrasmussen
Blog      : https://idefixwiki.no
Disclaimer: This script is provided "AS IS" without any warranties.
#>

# Add roles here e.g. "User Administrator","SharePoint Administrator", "Intune Administrator", "Exchange Administrator", "Global Administrator"
$roles = "Global Reader","User Administrator"
$justification = "Automated activation via Microsoft Graph"

Connect-MgGraph -Scope "RoleEligibilitySchedule.ReadWrite.Directory","RoleAssignmentSchedule.ReadWrite.Directory" -NoWelcome
$MgContext = Get-MgContext
$myUser = (Get-MgUser -UserId $MgContext.Account).Id
$myRoles = Get-MgRoleManagementDirectoryRoleEligibilitySchedule -ExpandProperty RoleDefinition -All -Filter "principalId eq '$myUser'"

foreach ($role in $roles) {
    $myRoleName = $myroles | Select-Object -ExpandProperty RoleDefinition | Where-Object {$_.DisplayName -eq $role}
    $myRoleNameid = $myRoleName.Id
    $myRole = $myroles | Where-Object {$_.RoleDefinitionId -eq $myRoleNameid}
    $params = @{
        Action = "selfActivate"
        PrincipalId = $myUser
        RoleDefinitionId = $myRole.RoleDefinitionId
        DirectoryScopeId = $myRole.DirectoryScopeId
        Justification = $justification
        ScheduleInfo = @{
            StartDateTime = Get-Date
            Expiration = @{
                Type = "AfterDuration"
                Duration = "PT4H"
            }
        }
    }
    New-MgRoleManagementDirectoryRoleAssignmentScheduleRequest -BodyParameter $params
}
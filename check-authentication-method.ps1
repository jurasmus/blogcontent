#run script
Import-Module Microsoft.Graph
Import-Module Microsoft.Graph.Beta.Users
Connect-MgGraph -Scopes "User.ReadWrite.All","UserAuthenticationMethod.ReadWrite.All"

# Get all users from your tenant
$allusers = Get-MgBetaUser -All

# Add your webhook URL here. You generate it from your dedicated notification channel in Teams.
$webhookUrl = "Insert Webhook url here"

# Add your notification title here
$teamschanneltitle = "Checking for missing phone authentication methods"

function SendTeamsNotification {
    $JSONBody = [PSCustomObject][Ordered]@{
        "@type" = "MessageCard"
        "@context" = http://schema.org/extensions
        "summary" = $teamschanneltitle
        "themeColor" = '0078D7'
        "title" = $teamschanneltitle
        "text" = "$message"
    }
    $TeamMessageBody = ConvertTo-Json $JSONBody
    $parameters = @{
        "URI" = $webhookUrl
        "Method" = 'POST'
        "Body" = $TeamMessageBody
        "ContentType" = 'application/json'
    }
    Invoke-RestMethod @parameters
}

$missingphoneauth = @()

foreach ($user in $allusers) {
    $existingPhoneMethods = Get-MgBetaUserAuthenticationPhoneMethod -UserId $user.Id
    if (!$existingPhoneMethods) {
        Write-Host "Missing phone authentication method for user $($user.UserPrincipalName)" -ForegroundColor Yellow
        $missingphoneauth += $user.UserPrincipalName
        $message = "Missing phone authentication method for user $($user.UserPrincipalName)"
        SendTeamsNotification
    }
    else {
        Write-Host "All good! Phone methods for user $($user.UserPrincipalName) exists" -ForegroundColor Green
    }
}
#run script
Import-Module Microsoft.Graph
Import-Module Microsoft.Graph.Beta.Users
Connect-MgGraph -Scopes "User.ReadWrite.All","UserAuthenticationMethod.ReadWrite.All"

# Get all users from your tenant
$allusers = Get-MgBetaUser -All

# Add your webhook URL here. You generate it from your dedicated notification channel in Teams.
$webhookUrl = "https://idefixw365.webhook.office.com/webhookb2/47837571-9f59-4a37-9649-09712a7dd893@dd1a5a82-b9cc-4855-96d0-98e8dd7e7055/IncomingWebhook/1adc45a3784b4e0d94f0be085a77bbdd/072338a1-0159-43cd-819d-3e6cef0237de"

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
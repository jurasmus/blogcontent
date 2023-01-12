$tenantID="YOUR TENANT ID"
$contentType = "application/json"

$Body = @{    
    Grant_Type    = "client_credentials"
    Scope         = "https://graph.microsoft.com/.default"
    client_Id     = "YOUR CLIENT ID"
    Client_Secret = "YOUR CLIENT SECRET"
}
$ConnectGraph = Invoke-RestMethod -Uri "https://login.microsoftonline.com/$tenantID/oauth2/v2.0/token" -Method POST -Body $Body

$token = $ConnectGraph.access_token
$headers = @{ 'Authorization' = "Bearer $token" }


$queryURL = 'https://graph.microsoft.com/beta/users?$select=displayName,createddatetime,userprincipalname,mail,usertype,signInActivity,accountEnabled,companyName'
$SignInData = Invoke-RestMethod -Method GET -Uri $queryUrl -Headers $headers -contentType $contentType
$relLink = $SignInData.'@odata.nextLink'

$outList = @()
while ($SignInData.'@odata.nextLink' -ne $null){
   foreach ($relLink in $SignInData.'@odata.nextLink') {
      Write-Output "Getting data from $relLink"
      $SignInData = Invoke-RestMethod -Method GET -Uri $relLink -Headers $headers -contentType $contentType

          foreach ($user in $SignInData.Value) {
            If ($Null -ne $User.SignInActivity)     {
               $LastSignIn = Get-Date($User.SignInActivity.LastSignInDateTime)
               $DaysSinceSignIn = (New-TimeSpan $LastSignIn).Days }
            Else { #No sign in data for user
               $LastSignIn = "Never or > 90 days" 
               $DaysSinceSignIn = "N/A" }

              $Values  = [PSCustomObject] @{
                  UPN                = $User.UserPrincipalName
                  DisplayName        = $User.DisplayName
                  Email              = $User.Mail
                  Created            = Get-Date($User.CreatedDateTime)
                  LastSignIn         = $LastSignIn
                  DaysSinceSignIn    = $DaysSinceSignIn
                  UserType           = $User.UserType
                  accountEnabled     = $user.accountEnabled
                  Company            = $user.companyName}
                $outList += $Values
          }
  }
}

$outList.Count
$outList | Export-Csv -Path '.\User_Signin_Activity.csv' -Encoding UTF8 -NoTypeInformation
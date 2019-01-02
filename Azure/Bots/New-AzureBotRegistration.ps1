<#
.SYNOPSIS
    Creates a Bot Channel Registration in Azure and enables the Microsoft Teams Channel

.EXAMPLE
    PS C:\> New-AzureBotRegistration.ps1 -Name <bot-name> -SubscriptionId <subscription-guid> -ResourceGroup <resourceGroupName>
    
.OUTPUTS
    Bot AppId and Secret used for registration

.NOTES
    More information on Azure cli commands available here
    https://docs.microsoft.com/en-us/cli/azure/bot?view=azure-cli-latest
#>

Param(
    [Parameter(Mandatory=$true)]
    $Name,
    [Parameter(Mandatory=$true)]
    $SubscriptionId,
    [Parameter(Mandatory=$true)]
    $ResourceGroup,
    $Description = " ",
    $Location = 'centralus',
    $Sku = 'F0'
)

<#
    Generates a random string of ASCII characters and base64 encodes them for our client secret
#>
Function New-AppSecret
{
    $secret = ""
    $rand = New-Object System.Random
    $length = $rand.Next(30,40)
    for($i = 0; $i -lt $length;$i++)
    {
        $secret += [char]($rand.Next(33,126)) #just pulling an ascii character
    }

    return [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($secret))
}

$botRegAppId = [System.Guid]::NewGuid().Guid
$botRegSecret = New-AppSecret

# Log into Azure Portal. You will need contributor writes to create the bot registration
#   For unattended install. 
#       az login --username 'john@doe.com' --password 'password1'
az login

az account set --subscription $SubscriptionId

# Creates the bot channel registration with a random AppId and secret. 
# The endpoint parameter is required, although we're just putting in false data for now and updatin this in the portal at a later date.
"Creating Bot Registration" | Write-Host -ForegroundColor:Green
az bot create --kind registration --name $Name --description $Description --appid $botRegAppId --password $botRegSecret --location $Location --sku $Sku --endpoint "https://notreal.azurewebsites.net/api/messages" --resource-group $ResourceGroup

"Enabling MSTeams channel on Bot Registration" | Write-Host -ForegroundColor:Green
az bot msteams create --name $Name --resource-group $ResourceGroup

"[AppId]: '$($botRegAppId)'" | Write-Host -ForegroundColor:Yellow
"[AppSecret]: '$($botRegSecret)'" | Write-Host -ForegroundColor:Yellow
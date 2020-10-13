# resource attributes
Test-Path $env:resource_group
Test-Path $env:location
Test-Path $env:name
Test-Path $env:plan_id

Import-Module AzureHelpers
$InformationPreference = 'Continue'
$ErrorActionPreference = 'Stop'

function Invoke-AzAPI {
    [CmdletBinding()]
    param([string]$method,[string]$body="",[string]$cert_name)
    $token = Get-AzToken -AuthMethod ClientSecret
    $secure_token = ConvertTo-SecureString $token -AsPlainText -Force
    $URL = "https://management.azure.com/subscriptions/$env:AzureSubscription/resourceGroups/$env:resource_group/providers/Microsoft.Web/certificates/$($cert_name)?api-version=2019-08-01"
    $result = Invoke-RestMethod -Method $method -Uri $URL -Authentication Bearer -Token $secure_token -Body $body -ContentType 'application/json'
    Write-Information "AzAPI Result: $result"
    return $result
}

function Read-WebAppCert {
    [CmdletBinding()]
    param([Parameter(ValueFromPipeline)][string]$pipeline)
    
    $cert_name = ""
    if (![String]::IsNullOrEmpty($pipeline)) {
        $cert_name = $(ConvertFrom-Json $pipeline).name
    } else {
        $cert_name = $env:name
    }

    $result = Invoke-AzAPI -method 'GET' -cert_name $cert_name

    $state = @{
        name  = $result.name
        thumbprint = $result.properties.thumbprint
    }

    $json = ConvertTo-Json $state
    Write-Output $json
}

function Set-WebAppCert {
    Remove-WebAppCert
    New-WebAppCert
}

function Remove-WebAppCert {
    Invoke-AzAPI -method 'DELETE' -cert_name $env:name
}

function New-WebAppCert {
    $body = @{
        location = $env:location
        properties = @{
            password = ""
            serverFarmId = $env:plan_id
            canonicalName = $env:name 
        }
    }
    $jsonBody = ConvertTo-Json -InputObject $body -Depth 3
    $result = Invoke-AzAPI -method 'PUT' -body $jsonBody -cert_name $env:name
    Read-WebAppCert
}
function Get-EndpointParameters {
    param ( $endpoint,
            $parametersFile )

    process {
        $parameters = @{}
        if ($parametersFile) {
            $jsonData = Get-Content $parametersFile | ConvertFrom-Json
            $jsonData.$endpoint.PSObject.Properties | ForEach-Object {
            $parameters.Add($_.Name, $_.Value)
            }
        }
        return $parameters
    }
}

function Get-AllAccessTokens {

}

function Get-AccessTokenForEndpoint {

}



$version = 1
$baseurl = "https://horizonleeds-api.dev.avamae.co.uk"
$parametersFile = "parameters.json"
$auths = ""

$swaggerDoc = Invoke-RestMethod -Uri ($baseurl + "/v" + $version.ToString() + "/doc.json")

$accesstokens = @{}
foreach ($auth in $auths) {
    $response = Invoke-RestMethod -Uri ($baseurl + $auth)
}

[System.Collections.ArrayList] $endpointsList = @()

$swaggerDoc."paths".PSObject.Properties | ForEach-Object {
    $endpoint = $_.Name
    $_.Value.PSObject.Properties | ForEach-Object {
        $method = $_.Name
        $endpointsList.Add(@($endpoint, $method, "`n")) > $null
        Write-Host( $endpointsList)
    }
}
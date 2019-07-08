# Parse command line arguments
###############################################################################

param(
    [alias("a")][string[]]$auths = @(),
    [alias("p")][string]$parametersFile = "parameters.json",
    [alias("v")][int]$version = 1,
    [alias("o")][string]$outFilename = "endpoints",
    [Parameter(Mandatory=$true,Position=1)][alias("url")][string]$baseurl = ""
)

# Function definitions
###############################################################################

function Get-EndpointParameters {
    param ( $endpoint,
            $parametersList )
    process {
        $parameters = @{}
        $parametersList.PSObject.Properties | ForEach-Object {
            if ($_.Name -eq $endpoint) {
                $_.Value.PSObject.Properties | ForEach-Object {
                    $parameters.Add($_.Name, $_.Value)
                }
            }
        }
        return $parameters
    }
}

function Get-AllAccessTokens {
    param ( $baseurl,
            $authEndpoints,
            $parametersFile )
    process {
        $accessTokens = @{}
        foreach ($auth in $authEndpoints) {
            $jsonData = Get-Content $parametersFile | ConvertFrom-Json
            $jsonData.PSObject.Properties | ForEach-Object {
                if ($_.Name -eq $auth) {
                    $loginDetails = $_Value | ConvertTo-Json
                    $response = Invoke-RestMethod `
                                -Method POST `
                                -Uri ($baseurl + $_.Name) `
                                -Body ($_.Value|ConvertTo-Json) `
                                -ContentType "application/json"
                    $accessTokens.Add($_.Name, $response."access_token")
                }
            }
        }
        return $accessTokens
    }
}

function Get-AccessTokenForEndpoint {
    param ( $endpointDescription,
            $accessTokens )
    process {
        $identifier = "auth="
        $start = $endpointDescription.IndexOf($identifier)
        if ($start -ne -1) {
            if ($endpointDescription.IndexOf(" ", $start) -ne -1) {
                $end = $endpointDescription.IndexOf(" ", $start)
            }
            else {
                $end = $endpointDescription.Length
            }
            $auth = $endpointDescription.Substring(($start + $identifier.Length), ($end - ($start + $identifier.Length)))
        }
        try { return $accessTokens.$auth } catch { return "" }
    }
}

# Set up variables used during the script
###############################################################################

$parametersList = Get-Content $parametersFile | ConvertFrom-Json

$swaggerDoc = Invoke-RestMethod -Uri ($baseurl + "/v" + $version.ToString() + "/doc.json")

$accesstokens = @{}
if ($auths.Count -ne 0) {
    $accesstokens = Get-AllAccessTokens $baseurl $auths $parametersFile
}

$outputFile = $outFilename + ".csv"

Out-File $outputFile -Encoding UTF8

# Get info for all endpoints by running through Swagger document paths
###############################################################################

$swaggerDoc."paths".PSObject.Properties | ForEach-Object {
    $endpoint = $_.Name
    [string]$row = $endpoint + ","
    $_.Value.PSObject.Properties | ForEach-Object {
        $row += $_.Name + ","
        $token = ""
        try {
            $token = Get-AccessTokenForEndpoint $_.Value.description $accesstokens
        } catch { }
        $row += $token + ","
        $params = (Get-EndpointParameters $endpoint $parametersList)
        foreach ($key in $params.Keys) {
            $row += ($key + "=" + $params.$key + ";")
        }
        $row = $row.TrimEnd(";")
        $row += ","
        $contentType = If ($_.Value.consumes) {$_.Value.consumes} else {""}
        $row += $contentType
    }
    $row | Add-Content -path $outputFile -Encoding UTF8
}

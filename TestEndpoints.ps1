# Parse command line arguments
###############################################################################

param(
    [alias("a")][string[]]$auths = @(),
    [alias("p")][string]$parametersFile = "parameters.json",
    [alias("v")][int]$version = 1,
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

# Set up variables used during the test
###############################################################################

$parametersList = Get-Content $parametersFile | ConvertFrom-Json

$bAllTestPassed = 1
$separator = $("-" * 80)

$swaggerDoc = Invoke-RestMethod -Uri ($baseurl + "/v" + $version.ToString() + "/doc.json")

$accesstokens = @{}
if ($auths.Count -ne 0) {
    $accesstokens = Get-AllAccessTokens $baseurl $auths $parametersFile
}

# Test all endpoints by running through Swagger document paths
###############################################################################

$swaggerDoc."paths".PSObject.Properties | ForEach-Object {
    $endpoint = $_.Name
    $_.Value.PSObject.Properties | ForEach-Object {
        $method = $_.Name
        $contentType = If ($_.Value.consumes) {$_.Value.consumes} else {""}
        $parameters = Get-EndpointParameters $endpoint $parametersList
        if ($method -ieq "POST") {
            $parameters = $parameters | ConvertTo-Json
        }
        $token = ""
        try {
            $token = Get-AccessTokenForEndpoint $_.Value.description $accesstokens
        } catch { }

        $headers = @{}
        $headers.Add("IsTestData", 1)
        $headers.Add("Authorization", $token)

        try {
            $response = Invoke-WebRequest -Method $method `
                                        -ContentType $contentType `
                                        -Uri ($baseurl + $endpoint) `
                                        -Body $parameters `
                                        -Headers $headers
            $responseContentType = $response.Headers["content-type"]
            if ($responseContentType -like "*application/json*") {
                $body = ConvertFrom-Json -InputObject $response
                if ($body."errors".Count -eq 0) {
                    Write-Host -n "`nTest of "
                    Write-Host -n -f Green $endpoint; Write-Host " succeeded."
                    Write-Host $separator
                }
                else {
                    $bAllTestPassed = 0
                    Write-Host -n "Test of "
                    Write-Host -n -f Yellow $endpoint
                    Write-Host " returned a successful status code, 
                                but there were errors in the JSON response body:`n"
                    $errors = $body."errors"[0]
                    Write-Host -n "Method: "; Write-Host $method.ToUpper()
                    Write-Host -n "Request Parameters: "
                    if ($parameters) {Write-Host $parameters}
                    else {Write-Host "None"}
                    Write-Host "Errors:"
                    $errors.PSObject.Properties | ForEach-Object {
                        $name = $_.Name
                        $value = $_.value
                        Write-Host"`t`t$name : $value"
                    }
                    Write-Host $separator
                }
            }
            else {
                Write-Host -n "Test of "
               Write-Host -n -f Green $endpoint; Write-Host " succeeded."
               Write-Host $separator
            }
        }
        catch {
            $bAllTestPassed = 0

            $res = $_.Exception.Response

            Write-Host -n "Test of "
            Write-Host -n -f Yellow $endpoint
            Write-Host "failed; "`
                        + "here are some (hopefully!) helpful "`
                        + "details:`n"
            Write-Host -n "Method: "; Write-Host $res.Method
            Write-Host -n "Error Code: "; Write-Host -f Yellow $res.StatusCode.value__.ToString() + " - " + $res.StatusCode
            Write-Host -n "Access token: "
            if ($accesstoken) { Write-Host $accesstoken } else { Write-Host "None" }
            Write-Host -n "Request Parameters: "
            if ($parameters) { Write-Host $parameters} else { Write-Host "None" }
            Write-Host $separator
        }
    }
}

# Print an mildly informative message upon completion of tests
###############################################################################

if ($bAllTestPassed) {
    Write-Host -f Green "-----TESTING PASSED-----"
    Write-Host "All endpoints seem to be responding properly!"
    exit 0
}
else {
    Write-Host -f Yellow "-----TESTING FAILED-----"
    Write-Host "One or more endpoints aren't working correctly; see test results above."
    exit 1
}

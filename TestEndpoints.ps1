param(
    [int]$version = 1,
    [string]$baseurl = ""
    )
    
$endpointList = import-csv ($baseurl.Replace("https://","") + $version.ToString() + ".csv")

$bAllTestPassed = 1
$separator = $("-" * 80)

Write-Host "`n"

foreach($line in $endpointList){

    $endpoint = $line.("endpoint")  
    $method = $line.("method")
    $accesstoken = $line.("accesstoken")
    $parameters = $line.("parameters")
    $contentType = "application/json"

    $headers = @{"IsTestData"=1}
    if ($accesstoken) {$headers.Add("Authorization", $accesstoken)}

    try {
        $response = Invoke-WebRequest -Method $method -ContentType $contentType -Uri ($baseurl + $endpoint) -Headers $headers
        $responseContentType = $response.Headers["content-type"]
        if ($responseContentType -like "*application/json*") {
            $body = ConvertFrom-Json -InputObject $response
            if ($body."errors".Count -eq 0) {
                Write-Host -n ("`nTest of ")
                Write-Host -n -f Green ($endpoint); Write-Host (" succeeded.")
            }
            else {
                $bAllTestPassed = 0
                Write-Host -n ("Test of ")
                Write-Host -n -f Yellow ($endpoint); Write-Host (" returned a successful status code, but there were errors in the JSON response body:`n")
                $errors = $body."errors"[0]
                Write-Host -n ("Method: "); Write-Host ($method.ToUpper())
                Write-Host -n ("Request Parameters: ")
                if ($parameters) { Write-Host ($parameters)} else { Write-Host ("None") }
                Write-Host ("Errors:")
                $errors.PSObject.Properties | ForEach-Object {
                    $name = $_.Name 
                    $value = $_.value
                    Write-Host("`t`t$name : $value")
                }
                Write-Host ($separator)
            }
        }
        Write-Host -n ("Test of ")
        Write-Host -n -f Green ($endpoint); Write-Host (" succeeded.")
        Write-Host ($separator)
    }
    catch {
        $bAllTestPassed = 0

        $res = $_.Exception.Response

        Write-Host -n ("Test of ")
        Write-Host -n -f Yellow ($endpoint)
        Write-Host(" failed; "`
                    + "here are some (hopefully!) helpful "`
                    + "details:`n")
        Write-Host -n ("Method: "); Write-Host ($res.Method)
        Write-Host -n ("Error Code: "); Write-Host -f Yellow ($res.StatusCode.value__.ToString() + " - " + $res.StatusCode)
        Write-Host -n ("Access token: ")
        if ($accesstoken) { Write-Host ($accesstoken) } else { Write-Host ("None") }
        Write-Host -n ("Request Parameters: ")
        if ($parameters) { Write-Host ($parameters)} else { Write-Host ("None") }
        Write-Host ($separator)
    }
}

if ($bAllTestPassed) {
    Write-Host -f Green ("-----TESTING PASSED-----")
    Write-Host ("All endpoints seem to be responding properly!")
    exit 0
}
else {
    Write-Host -f Yellow ("-----TESTING FAILED-----")
    Write-Host ("One or more endpoints aren't working correctly (see test results above).")
    exit 1
}
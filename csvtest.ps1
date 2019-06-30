$testcsv = import-csv psycruitclient-api.dev.avamae.co.uk1.csv

Out-File -FilePath .\results.txt

$bAllTestPassed = 1

foreach($test in $testcsv){

    $endpoint = $test.("endpoint")  
    $method = $test.("method")
    $accesstoken = $test.("accesstoken")
    $parameters = $test.("parameters")
   
    $auth_endpoint = "https://psycruitclient-api.dev.avamae.co.uk" + $endpoint

    $contentType = "application/json"

    $headers = @{"IsTestData"=1}
    if ($accesstoken) {$headers.Add("Authorization", $accesstoken)}

    try {
        $response = Invoke-WebRequest -Method $method -ContentType $contentType -Uri $auth_endpoint -Headers $headers
    }
    catch {
        $bAllTestPassed = 1

        $res = $_.Exception.Response

        Write-Host -NoNewline ("`nTest of ")
        Write-Host -NoNewline -ForegroundColor Red ($endpoint)
        Write-Host(" failed; "`
                    + "here are some (hopefully!) helpful "`
                    + "details:`n")
        Write-Host -NoNewline ("Method: "); Write-Host ($res.Method)
        Write-Host -NoNewline ("Error Code: "); Write-Host -ForegroundColor Red ($res.StatusCode.value__.ToString() + " - " + $res.StatusCode)
        Write-Host -NoNewline ("Access token: ")
        if ($accesstoken) { Write-Host ($accesstoken) } else { Write-Host ("None") }
        Write-Host -NoNewline ("Request Parameters: ")
        if ($parameters) { Write-Host ($parameters)} else { Write-Host ("None") }
        Write-Host $("-" * 40)
    }
}
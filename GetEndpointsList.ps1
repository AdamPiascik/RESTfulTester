param(
    [string[]]$auths = "",
    [string]$parameters = "",
    [int]$version = 1,
    [string]$url = ""
    )

$docURL = $url + "/v" + $version + "/doc.json"

$swaggerdoc = Invoke-RestMethod -Method GET -Uri $docURL

$login = @{
    userName="larina.correia@avamae.co.uk"
    password="!LC123456a"
}

$auth_endpoint = $url + "/v1/Auth"

$json = $login | ConvertTo-Json

$access = Invoke-RestMethod -Method POST -ContentType 'application/json' -Uri $auth_endpoint -Body $json

Write-Output($access)
@ECHO off

CALL powershell.exe -Command .\jsontest.ps1 -a "/v1/Auth,/v1/ManagerAuth" https://horizonleeds-api.dev.avamae.co.uk

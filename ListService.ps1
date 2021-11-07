# List a Windows Service Details
# Author tay@cimitra.com

$scriptName = Split-Path -leaf $PSCommandpath

function SHOW_HELP()
{
Write-Output ""
Write-Output "Usage: $scriptName <Windows Service Name>"
Write-Output ""
exit 0
}

if(!($args[0])){
SHOW_HELP
}


$SERVICE_TO_LIST = $args[0]

if ($SERVICE_TO_LIST.equals("*")){
Write-Output ""
Write-Output "Error: Cannot do that!"
Write-Output ""
exit 1
}

Write-Output ""
Write-Output "Information on Windows Service: [ $SERVICE_TO_LIST ]"
Write-Output "------------------------------------------------"

Get-Service $SERVICE_TO_LIST | fl

Write-Output "------------------------------------------------"
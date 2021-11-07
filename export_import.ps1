# Bulk import/export users from Active Directory
# Author: Tay Kratzer tay@cimitra.com
# Modify Date: 11/6/2021
# -------------------------------------------------
    
<#
.DESCRIPTION
Export/Import Active Directory Users
#>

Param(
[switch] $Menu,
[switch] $MassExport,
[switch] $MassImport,
[switch] $AllImport,
[switch] $ImportOus,
[switch] $ExportOus,
[string] $OU,
[string] $CsvFile,
[switch] $Import,
[switch] $Export
)

try{ 
    New-Item -Path "c:\" -Name "temp" -ItemType "directory" -ErrorAction SilentlyContinue
}catch{
    Write-Output "ERROR: Insufficient rights to create directory: c:\temp"
    exit 1
}

$Global:CONTEXTS_CSV_FILE = "c:\temp\UserContexts.csv"
$Global:TheOU = ""
$Global:TheCsvFile = ""
$Global:DiscoverUserContextsRan = $false

function Discover-User-Contexts-CSV(){

if($DiscoverUserContextsRan){
    return
}

$Global:DiscoverUserContextsRan = $true

$ContextsWithUsers = [System.Collections.ArrayList]::new()

Import-Module ActiveDirectory -WarningAction Ignore

$CanGetContexts = $true

try{
    $ListOfContexts = Get-ADOrganizationalUnit -ErrorAction Stop -Filter * | Select-Object "DistinguishedName"
}catch{
    $CanGetContexts = $false
}

$NumberOfContexts = $ListOfContexts.Length

if(!($CanGetContexts)){
    Write-Output "Cannot Discover any Active Directory Contexts"
    Write-Output ""
}

$ContextsWithUsers = [System.Collections.ArrayList]::new()

$ListOfContexts.ForEach({ $CurrentContext = $_.DistinguishedName

    if($EnableActiveDirectoryAdminUser){
        $UsersInContextCount = (Get-ADUser @SrvConnect -Filter * -SearchBase "$CurrentContext").count
    }else{
        $UsersInContextCount = (Get-ADUser -Filter * -SearchBase "$CurrentContext").count
    }

    if($UsersInContextCount -gt 0 ){

       [void]$ContextsWithUsers.Add("$CurrentContext")
    }
})


$NumberOfUsersContexts = $ContextsWithUsers.Length

if( $NumberOfUsersContexts -eq 0 ){
    Write-Output "ERROR: Cannot Discover any Active Directory Contexts Containing User Objects"
    exit 1
}


$TEMP_FILE_ONE = New-TemporaryFile

$ContextsWithUsers.ForEach({ 

    $TheContext = $_ 

    # Remove New Lines

    $TheContext = [string]::join("",($TheContext.Split("`n")))

    $TheContextTitle = ($TheContext.Split('OU=',1).Split(',',2)[0] -split "OU=")

    $TheContextTitle =  [string]::join("",($TheContextTitle.Split("`n")))

    if(!($DisableContextTitleCase)){
        $TheContextTitle = $TheContextTitle.ToUpper()
    }

    Add-Content -Path $TEMP_FILE_ONE -Value "$TheContextTitle,$TheContext"
})


Move-Item -Force -Path $TEMP_FILE_ONE -Destination ${CONTEXTS_CSV_FILE}


$Global:DiscoverUserContextsRan = $true
}

function ListContexts(){

Discover-User-Contexts-CSV

if(!($DiscoverUserContextsRan)){
    Write-Output "Cannot Discover Contexts"
    exit 1
}
    $CSVFileContent = Get-content -Path "$CONTEXTS_CSV_FILE"
    $Counter = 0

    if(!($ExportOus)){
        Write-Output "Choose Context To Import To |OR| Export From"
    }

            while($Counter -lt $CSVFileContent.Length){

            $TheLine = $CSVFileContent[$Counter]
            $Counter++
            $TheContextTitle = $TheLine.Split(',')[0]
            $TheContextValue = $TheLine.Split(',',2)[1]
            Write-Output "[${Counter}]: $TheContextTitle ($TheContextValue)"
            # Write-Output "Value: $TheContextValue"
            $NO_SPACES_CONTEXT = $TheContextTitle.Replace(' ','')
            
        }
}

if(!($Menu)){

    if($OU.Length -lt 5){
        $Global:TheOU = 'OU=ADMINISTRATION,OU=USERS,OU=KCC,OU=DEMOSYSTEM,DC=cimitrademo,DC=com'
    }else{
        $Global:TheOU = $OU
    }



    if($CsvFile.Length -lt 5){
       $Global:TheCsvFile = 'C:\temp\export.csv'
    }else{
       $Global:TheCsvFile = $CsvFile
    }

}

if($Menu){
    Write-Output "Export or Import?"
    Write-Output ""
    Write-Output "1 = Export"
    Write-Output ""
    Write-Output "2 = Import"
    Write-Output ""
    $TheAction = Read-Host "Export or Import? "
    if($TheAction -eq 1){
        Write-Output ""
        Write-Output "Export Users From Context"
        Write-Output ""
        $Export = $true
    }else{
        Write-Output ""
        Write-Output "Export Users From Context"
        Write-Output ""
        $Import = $true
    }

    ListContexts
    $ContextNumberInput = Read-Host "Please Specify The Context Number "
    $ContextNumber = ($ContextNumberInput - 1)

        $CSVFileContent = Get-content -Path "$CONTEXTS_CSV_FILE"

            $TheLine = $CSVFileContent[$ContextNumber]
            $TheContextTitle = $TheLine.Split(',')[0]
            $TheContextValue = $TheLine.Split(',',2)[1]
            $TheOU = $TheContextValue
            Write-Output "[$ContextNumberInput]: $TheContextTitle ($TheContextValue)"
            $NO_SPACES_CONTEXT = $TheContextTitle.Replace(' ','')
            $NO_SPACES_CONTEXT_LOWER_CASE = $NO_SPACES_CONTEXT.ToLower()
            $TheCsvFile = "c:\temp\${NO_SPACES_CONTEXT_LOWER_CASE}.csv"
}


if($Import){
    Write-Output "CSV File: $TheCsvFile"
    Write-Output "OU: $TheOU"
    Import-Csv $TheCsvFile | New-ADUser -Enabled $True -Path $TheOU -AccountPassword (ConvertTo-SecureString Pass123 -AsPlainText -force)
    exit 0
}

if($Export){
    Get-ADUser -Filter * -SearchBase $TheOU -Properties SamAccountName,DisplayName,GivenName,Name,Surname | Export-Csv $TheCsvFile
    exit 0
}



function MassExportFunction(){

    Discover-User-Contexts-CSV
    $CSVFileContent = Get-content -Path "$CONTEXTS_CSV_FILE"
    $Counter = 0


            while($Counter -lt $CSVFileContent.Length){
            $TheLine = $CSVFileContent[$Counter]
            $Counter++
            $TheContextTitle = $TheLine.Split(',')[0]
            $TheContextValue = $TheLine.Split(',',2)[1]
            $TheOU = $TheContextValue
            Write-Output "[${Counter}]: $TheContextTitle ($TheContextValue)"
            # Write-Output "Value: $TheContextValue"
            $NO_SPACES_CONTEXT = $TheContextTitle.Replace(' ','')
            $NO_SPACES_CONTEXT_LOWER_CASE = $NO_SPACES_CONTEXT.ToLower()
            $TheCsvFile = "c:\temp\${NO_SPACES_CONTEXT_LOWER_CASE}.csv"
            
            Get-ADUser -Filter * -SearchBase $TheOU -Properties SamAccountName,DisplayName,GivenName,Name,Surname | Export-Csv $TheCsvFile
            Write-Output "Created OU Export File: $TheCsvFile"
        }


}

if($MassExport){

    MassExportFunction
    exit 0
}



function MassImportFunction(){

    
    $CSVFileContent = Get-content -Path "$CONTEXTS_CSV_FILE"
    $Counter = 0


            while($Counter -lt $CSVFileContent.Length){
            $TheLine = $CSVFileContent[$Counter]
            $Counter++
            $TheContextTitle = $TheLine.Split(',')[0]
            $TheContextValue = $TheLine.Split(',',2)[1]
            $TheOU = $TheContextValue
            Write-Output "[${Counter}]: $TheContextTitle ($TheContextValue)"
            # Write-Output "Value: $TheContextValue"
            $NO_SPACES_CONTEXT = $TheContextTitle.Replace(' ','')
            $NO_SPACES_CONTEXT_LOWER_CASE = $NO_SPACES_CONTEXT.ToLower()
            $TheCsvFile = "c:\temp\${NO_SPACES_CONTEXT_LOWER_CASE}.csv"
            
            Import-Csv $TheCsvFile | New-ADUser -Enabled $True -Path $TheOU -AccountPassword (ConvertTo-SecureString Pass123 -AsPlainText -force)
            Write-Output "Created Users From Import File: $TheCsvFile"
        }


}

if($MassImport){

    MassImportFunction
    exit 0
}


if($ExportOus){
Write-Output "Exporting All Contexts With Users"
ListContexts
Write-Output ""
Write-Output "Export File: $CONTEXTS_CSV_FILE"
Write-Output ""
exit 0

}

if($ImportOus){


$CSVFileContent = Get-content -Path "$CONTEXTS_CSV_FILE"
ForEach($OU in $CSVFileContent){
 
try{
#Get Name and Path from the source file

$OUName = $OU.Split(',')[0]
$OUPath = $OU.Split(',',2)[1]
$THE_OU_PATH = ($OUPath.Split('OU=',1).Split(',',2)[1])
Write-Output "OU Name: $OUName"
Write-Output "OU Path: $THE_OU_PATH"

#Display the name and path of the new OU
Write-Host -Foregroundcolor Yellow $OUName $THE_OU_PATH
 
#Create OU
New-ADOrganizationalUnit -Name "$OUName" -Path "$THE_OU_PATH" -ProtectedFromAccidentalDeletion $false
 
#Display confirmation
Write-Host -ForegroundColor Green "OU $OUName created"
}catch{
 
Write-Host $error[0].Exception.Message
}
 
}

}


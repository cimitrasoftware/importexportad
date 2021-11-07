Param(
[string] $OU,
[string] $CsvFile
)
if($OU.Length -lt 5){
    $TheOU = 'OU=ADMINISTRATION,OU=USERS,OU=KCC,OU=DEMOSYSTEM,DC=cimitrademo,DC=com'
}else{
    $TheOU = $OU
}

if($CsvFile.Length -lt 5){
    $TheCsvFile = 'C:\temp\export.csv'
}else{
    $TheCsvFile = $CsvFile
}


Get-ADUser -Filter * -SearchBase $TheOU -Properties CanonicalName,CN,DisplayName,GivenName,Name,Surname | Export-Csv $TheCsvFile
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


Import-Csv $TheCsvFile | New-ADUser -Enabled $True -Path $TheOU -AccountPassword (ConvertTo-SecureString Pass123 -AsPlainText -force)


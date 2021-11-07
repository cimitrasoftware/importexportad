function GroupMembership-Report-New($GroupGUIDIn){

$ExcludeGroupEmpty = [string]::IsNullOrWhiteSpace($AD_EXCLUDE_GROUP)

if($IgnoreExcludeGroup){
    $ExcludeGroupEmpty = $true
}

try{
    $GroupObject = Get-ADGroup @SrvConnect   -Identity "$GroupGUIDIn"
    $GroupGUID = $GroupObject.ObjectGUID.ToString()
    $GroupName = $GroupObject.Name.ToString()
    $DistinguishedName = $GroupObject.DistinguishedName.ToString()
    $GroupOU = "OU="+($DistinguishedName -split ",OU=",2)[1]
}catch{}

Write-Output "------------------------------------------------------"
Write-Output "Membership For Group [ $GroupName ]"
Write-Output "------------------------------------------------------"
     if(!($ExcludeGroupEmpty)){
        $GroupDN = (Get-ADGroup @SrvConnect   -Identity $AD_EXCLUDE_GROUP).DistinguishedName
        $UsersInGroup = (Get-ADGroupMember @SrvConnect -Identity "$GroupGUIDIn" | Select-Object name, SamAccountName).where{$_.memberof -notcontains $GroupDN}
        }else{
        $UsersInGroup = (Get-ADGroupMember @SrvConnect -Identity "$GroupGUIDIn" | Select-Object name, SamAccountName)

        }
        $UsersInGroup | ft -HideTableHeaders
Write-Output "------------------------------------------------------"
# BLISS
}

if($GroupReport -or $GroupMembershipReport){
Process-GroupGUIDs

    foreach ($GroupGuid in $ValidatedGroupGUIDList) {

        if($GroupReport)
        {
            Group-Report "$GroupGuid"
        }else{
            GroupMembership-Report "$GroupGuid"
        }
    }

exit 0
}


$ExcludeGroupEmpty = [string]::IsNullOrWhiteSpace($AD_EXCLUDE_GROUP)

if($IgnoreExcludeGroup){
    $ExcludeGroupEmpty = $true
}

$runResult = $true

    if($FindAndShowAllUsersInContext){
        Write-Output "USERS IN ORGANIZATION REPORT"
        Write-Output "----------------------------"
        try{
        #Get-ADUser -Filter * -Searchbase $contextIn  -ErrorAction Stop | select Name,Givenname,Surname,sAMAccountName,distinguishedName  | fl 
            if(!($ExcludeGroupEmpty)){

                    $GroupDN = (Get-ADGroup @SrvConnect   -Identity $AD_EXCLUDE_GROUP).DistinguishedName

                if($SkipUserSamAccountNameDisplay){
                    $Users = (Get-ADUser @SrvConnect   -filter {objectclass -eq "user"} -Searchbase $contextIn -ErrorAction Stop -properties memberof).where{$_.memberof -notcontains $GroupDN} | select Givenname,Surname  | Format-Table -HideTableHeaders
                }else{
                    $Users = (Get-ADUser @SrvConnect   -filter {objectclass -eq "user"} -Searchbase $contextIn -ErrorAction Stop -properties memberof).where{$_.memberof -notcontains $GroupDN} | select Givenname,Surname,SamAccountName  | Format-Table -HideTableHeaders
                }
                    $Users
            }else{
                Get-ADUser @SrvConnect   -Filter * -Searchbase $contextIn -ErrorAction Stop | select Givenname,Surname  | Format-Table -HideTableHeaders
            }catch{}


          

            }
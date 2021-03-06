#################
#
# Rowdy Vinson
# 8/16/16
# Pulls members of the sysadmin role and resolves groups to individual users in seperate CSVs. This works well for Excel-driven reporting.
# This was part of a broader tool set, so some of it is probably inefficient and could be inproved. 
#
#################
#
# Rights requirement: The account you run this as needs SA rights to the SQL server and Modify rights to the output path. 
# Prereqs: Expects RSAT and SQL Provider snapins to be available. 
#
#################

$OutputPath = "C:\it"
$Server = Read-Host "Enter SQL server name"


if (! (Get-PSSnapin -Name sqlservercmdletsnapin100 -ErrorAction SilentlyContinue))
{
    "Loading SQL server commandlets"
    Add-PSSnapin sqlservercmdletsnapin100 -ErrorAction SilentlyContinue
}
        
if (! (Get-PSSnapin -Name sqlserverprovidersnapin100 -ErrorAction SilentlyContinue))
{
    "Loading SQL provider commandlets"
    Add-PSSnapin sqlserverprovidersnapin100 -ErrorAction SilentlyContinue
}

if (! (Get-module -Name activedirectory -ErrorAction SilentlyContinue))
{
    "Loading Active Directory commandlets"
    import-module activedirectory -ErrorAction stop
}

$Domain = $env:USERDNSDOMAIN.Split('.')[0]

#################
#
# Identities files. Unique removes duplicates and is used to pull AD reports to resolve groups into lists of users in txt files.
#
#################

Write-Host "Setting up Identities files"
$IdentitiesUnique = $OutputPath + "\Identities.csv"
$IdentitiesOutfile = $OutputPath + "\IdentitiesWithDuplicates.csv" # This is a working document and not part of the result packet.
# Header format for identity file
$IdentitiesHeader = "IdentityReference"
Del $IdentitiesOutfile -ErrorAction SilentlyContinue
Del $IdentitiesUnique -ErrorAction SilentlyContinue
Add-Content -Value $IdentitiesHeader -Path $IdentitiesUnique 

#Begin SA gathering
$ReportFile1 = $OutputPath + "\" + $Server + "_SA-Members.csv"
$SQL1 = "exec sp_helpsrvrolemember 'sysadmin'"
$Sysadmins = Invoke-Sqlcmd -Query $SQL1 -ServerInstance $Server
$Sysadmins | Export-Csv -Path $ReportFile1
$DomainSAs = @()
foreach ($Sysadmin in $Sysadmins)
    {
    $DomainSAs += $Sysadmin.MemberName | where ({$_ -like ($Domain + '*')})
    }
Add-Content -Value  $DomainSAs -path $IdentitiesOutfile 

#################
#
# Identity handling (Resolves groups back down to users. This supplements the above reports.)
#
#################

#Cleanup of bad/irrelevant accounts, sort alphebetically, and remove duplicates
$Identities = Get-Content -path $IdentitiesOutfile | sort-object | Get-unique | Where ({$_ -ne 'Administrator'-and $_ -ne 'BUILTIN\Administrators'})
Add-Content -Value $Identities -Path $IdentitiesUnique

write-host "Beginning identity lookups" 

#Loop to identify groups and resolve members. 
foreach ($Identity in $Identities)
    {
    write-host "working on identity: " $Identity 
    $Identity = $Identity.Split('\')[-1] 
    $Object = get-adobject -Filter 'samaccountname -like $Identity -and ObjectClass -eq "group"'
    If ($Object.ObjectClass -eq 'group')
        {
        Write-Host "Getting members of: " $Object.Name
        $path = $OutputPath + "\" + $Object.Name + ".csv"
        del $path -ErrorAction SilentlyContinue
        get-adgroupmember -identity $Object.Name -recursive | export-csv -path $path
        }
    }

Write-Host "Finished with Identities"
Import-Module activedirectory

#Server Postmaster runs on
$servers   = Get-ADComputer -Filter {name -like 'pla-rvinson2*'}|select -Property name
#Account used to run postmaster
$username = 'csnow-admin'



foreach ($Server in $Servers){
    #Finds Sessionname for RDP connection
    $server = $Server.name 
    Write-host 'Working on' $server 'Logging off user '$username
    $session = try { 
        $ErrorActionPreference = 'Stop'
        ((quser /server:$server | ? { $_ -match $username }) -split ' +')[2]}
        catch {
            $Null
            }
    #Logs User off of RDP
    If ($session -ne $Null){
        try {
            $ErrorActionPreference = 'Stop'
            logoff $session /server:$server.name
            }
        catch {
            Write-Host 'Error contacting' $Server
            }
        }
    }
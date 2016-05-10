# Add relevant cmdlets and modules
if (Get-Command -name 'Get-NetLocalGroup' -ErrorAction SilentlyContinue)
{
     write-host 'Get-NetLocalGroup exists. Continuing.'
}
else
{
	 write-host 'Adding Get-NetLocalGroup'
	Function Get-NetLocalGroup {
	[cmdletbinding()]

	Param(
	[Parameter(Position=0)]
	[ValidateNotNullorEmpty()]
	[object[]]$Computername=$env:computername,
	[ValidateNotNullorEmpty()]
	[string]$Group = "Administrators",
	[switch]$Asjob
	)

	Write-Verbose "Getting members of local group $Group"

	#define the scriptblock
	$sb = {
	 Param([string]$Name = "Administrators")
	$members = net localgroup $Name | 
	 where {$_ -AND $_ -notmatch "command completed successfully"} | 
	 select -skip 4
	New-Object PSObject -Property @{
	 Computername = $env:COMPUTERNAME
	 Group = $Name
	 Members=$members
	 }
	} #end scriptblock

	#define a parameter hash table for splatting
	$paramhash = @{
	 Scriptblock = $sb
	 HideComputername=$True
	 ArgumentList=$Group
	 }

	if ($Computername[0] -is [management.automation.runspaces.pssession]) {
		$paramhash.Add("Session",$Computername)
	}
	else {
		$paramhash.Add("Computername",$Computername)
	}

	if ($asjob) {
		Write-Verbose "Running as job"
		$paramhash.Add("AsJob",$True)
	}

	#run the command
	Invoke-Command @paramhash | Select * -ExcludeProperty RunspaceID

	} #end Get-NetLocalGroup
}
if (Get-Command -name 'Invoke-Sqlcmd2' -ErrorAction SilentlyContinue)
{
     write-host 'Invoke-Sqlcmd2 exists. Continuing.'
}
else
{
	 write-host 'Adding Invoke-Sqlcmd2'
	
    function Invoke-Sqlcmd2 
    { 
        [CmdletBinding()] 
        param( 
        [Parameter(Position=0, Mandatory=$true)] [string]$ServerInstance, 
        [Parameter(Position=1, Mandatory=$false)] [string]$Database, 
        [Parameter(Position=2, Mandatory=$false)] [string]$Query, 
        [Parameter(Position=3, Mandatory=$false)] [string]$Username, 
        [Parameter(Position=4, Mandatory=$false)] [string]$Password, 
        [Parameter(Position=5, Mandatory=$false)] [Int32]$QueryTimeout=600, 
        [Parameter(Position=6, Mandatory=$false)] [Int32]$ConnectionTimeout=15, 
        [Parameter(Position=7, Mandatory=$false)] [ValidateScript({test-path $_})] [string]$InputFile, 
        [Parameter(Position=8, Mandatory=$false)] [ValidateSet("DataSet", "DataTable", "DataRow")] [string]$As="DataRow" 
        ) 
 
        if ($InputFile) 
        { 
            $filePath = $(resolve-path $InputFile).path 
            $Query =  [System.IO.File]::ReadAllText("$filePath") 
        } 
 
        $conn=new-object System.Data.SqlClient.SQLConnection 
      
        if ($Username) 
        { $ConnectionString = "Server={0};Database={1};User ID={2};Password={3};Trusted_Connection=False;Connect Timeout={4}" -f $ServerInstance,$Database,$Username,$Password,$ConnectionTimeout } 
        else 
        { $ConnectionString = "Server={0};Database={1};Integrated Security=True;Connect Timeout={2}" -f $ServerInstance,$Database,$ConnectionTimeout } 
 
        $conn.ConnectionString=$ConnectionString 
     
        #Following EventHandler is used for PRINT and RAISERROR T-SQL statements. Executed when -Verbose parameter specified by caller 
        if ($PSBoundParameters.Verbose) 
        { 
            $conn.FireInfoMessageEventOnUserErrors=$true 
            $handler = [System.Data.SqlClient.SqlInfoMessageEventHandler] {Write-Verbose "$($_)"} 
            $conn.add_InfoMessage($handler) 
        } 
     
        $conn.Open() 
        $cmd=new-object system.Data.SqlClient.SqlCommand($Query,$conn) 
        $cmd.CommandTimeout=$QueryTimeout 
        $ds=New-Object system.Data.DataSet 
        $da=New-Object system.Data.SqlClient.SqlDataAdapter($cmd) 
        [void]$da.fill($ds) 
        $conn.Close() 
        switch ($As) 
        { 
            'DataSet'   { Write-Output ($ds) } 
            'DataTable' { Write-Output ($ds.Tables) } 
            'DataRow'   { Write-Output ($ds.Tables[0]) } 
        } 
 
    } #Adds Invoke-Sqlcmd2

	
}
<#
if (Get-Command -name 'Write-DataTable' -ErrorAction SilentlyContinue)
{
     write-host 'Write-DataTable exists. Continuing.'
}
else
{
	 write-host 'Adding Write-DataTable'
	
    function Write-DataTable 
    { 
        [CmdletBinding()] 
        param( 
        [Parameter(Position=0, Mandatory=$true)] [string]$ServerInstance, 
        [Parameter(Position=1, Mandatory=$true)] [string]$Database, 
        [Parameter(Position=2, Mandatory=$true)] [string]$TableName, 
        [Parameter(Position=3, Mandatory=$true)] $Data, 
        [Parameter(Position=4, Mandatory=$false)] [string]$Username, 
        [Parameter(Position=5, Mandatory=$false)] [string]$Password, 
        [Parameter(Position=6, Mandatory=$false)] [Int32]$BatchSize=50000, 
        [Parameter(Position=7, Mandatory=$false)] [Int32]$QueryTimeout=0, 
        [Parameter(Position=8, Mandatory=$false)] [Int32]$ConnectionTimeout=15 
        ) 
     
        $conn=new-object System.Data.SqlClient.SQLConnection 
 
        if ($Username) 
        { $ConnectionString = "Server={0};Database={1};User ID={2};Password={3};Trusted_Connection=False;Connect Timeout={4}" -f $ServerInstance,$Database,$Username,$Password,$ConnectionTimeout } 
        else 
        { $ConnectionString = "Server={0};Database={1};Integrated Security=True;Connect Timeout={2}" -f $ServerInstance,$Database,$ConnectionTimeout } 
 
        $conn.ConnectionString=$ConnectionString 
 
        try 
        { 
            $conn.Open() 
            $bulkCopy = new-object ("Data.SqlClient.SqlBulkCopy") $connectionString 
            $bulkCopy.DestinationTableName = $tableName 
            $bulkCopy.BatchSize = $BatchSize 
            $bulkCopy.BulkCopyTimeout = $QueryTimeOut 
            $bulkCopy.WriteToServer($Data) 
            $conn.Close() 
        } 
        catch 
        { 
            $ex = $_.Exception 
            Write-Error "$ex.Message" 
            continue 
        } 
 
    } # Adds Write-DataTable

	
}
if (Get-Command -name 'Get-Type' -ErrorAction SilentlyContinue)
{
     write-host 'Get-Type  exists. Continuing.'
}
else
{
	 write-host 'Adding Get-Type '
	
    function Get-Type 
    { 
        param($type) 
 
    $types = @( 
    'System.Boolean', 
    'System.Byte[]', 
    'System.Byte', 
    'System.Char', 
    'System.Datetime', 
    'System.Decimal', 
    'System.Double', 
    'System.Guid', 
    'System.Int16', 
    'System.Int32', 
    'System.Int64', 
    'System.Single', 
    'System.UInt16', 
    'System.UInt32', 
    'System.UInt64') 
 
        if ( $types -contains $type ) { 
            Write-Output "$type" 
        } 
        else { 
            Write-Output 'System.String' 
         
        } 
    } #Adds Get-Type 

}
if (Get-Command -name 'Out-DataTable' -ErrorAction SilentlyContinue)
{
     write-host 'Out-DataTable  exists. Continuing.'
}
else
{
	write-host 'Adding Out-DataTable '
	
    function Out-DataTable 
    { 
        [CmdletBinding()] 
        param([Parameter(Position=0, Mandatory=$true, ValueFromPipeline = $true)] [PSObject[]]$InputObject) 
 
        Begin 
        { 
            $dt = new-object Data.datatable   
            $First = $true  
        } 
        Process 
        { 
            foreach ($object in $InputObject) 
            { 
                $DR = $DT.NewRow()   
                foreach($property in $object.PsObject.get_properties()) 
                {   
                    if ($first) 
                    {   
                        $Col =  new-object Data.DataColumn   
                        $Col.ColumnName = $property.Name.ToString()   
                        if ($property.value) 
                        { 
                            if ($property.value -isnot [System.DBNull]) { 
                                $Col.DataType = [System.Type]::GetType("$(Get-Type $property.TypeNameOfValue)") 
                             } 
                        } 
                        $DT.Columns.Add($Col) 
                    }   
                    if ($property.Gettype().IsArray) { 
                        $DR.Item($property.Name) =$property.value | ConvertTo-XML -AS String -NoTypeInformation -Depth 1 
                    }   
                   else { 
                        $DR.Item($property.Name) = $property.value 
                    } 
                }   
                $DT.Rows.Add($DR)   
                $First = $false 
            } 
        }  
      
        End 
        { 
            Write-Output @(,($dt)) 
        } 
 
    } # Adds Out-DataTable

}
#>
if (Get-Command -name 'Add-RSMembers' -ErrorAction SilentlyContinue)
{
     write-host 'Add-RSMembers exists. Continuing.'
}
else
{
    Function Add-RSMembers ($MemberArray, $ObjectID, $SQLServer, $Database) 
    {
    <# Add-RSMembers - Rowdy Vinson 4/28/16
    This function will take an array that matches samaccountname, a protected objectID, SQL server instance, and database name.
    This function will sort the members of the supplied array in to groups and user/computers. 
    Groups are inserted into the Groups table. Groups will be resolved to users (recursively) and their parent group will be noted. 
    Users/computers will be inserted into the Users table with Direct object membership noted. 
    #>    
        Foreach ($Member in $MemberArray)
            {
            #Clean up names to match SAMAccountName structure
            $Member = $Member.Split('\')[-1] 
            #Check if group
            If (Get-ADObject -Filter {(SAMACCOUNTNAME -eq $Member) -and (ObjectClass -eq 'group')} -ErrorAction SilentlyContinue)
            {
                $Group = Get-ADGroup -Filter {SAMACCOUNTNAME -eq $Member} -Properties Samaccountname,members
                $GroupName = $Group.SamAccountName
                $GroupMembers = Get-ADgroupmember -Identity $GroupName -Recursive
                $InsertGroupSQL = "if (Select GroupID from Groups G where G.GroupName = '"+$GroupName+"' AND G.ObjectIDAccess = "+$ObjectID+") IS NULL Begin Insert into Groups (GroupName,ObjectIDAccess,FirstSeen,LastSeen) Values ('"+$Groupname+"',"+$ObjectID+",GETDATE(),GETDATE()) End else update Groups set LastSeen=Getdate() where GroupName='"+$Groupname+"' AND ObjectIDAccess="+$ObjectID
                Invoke-Sqlcmd2 -ServerInstance $SQLServer -Database $database -Query $InsertGroupSQL

                $SelectGroupIDSQL = "Select GroupID from Groups G where G.GroupName = '"+$GroupName+"' AND G.ObjectIDAccess = "+$ObjectID
                $GroupID = Invoke-Sqlcmd2 -ServerInstance $SQLServer -Database $database -Query $SelectGroupIDSQL
                foreach ($GroupMember in $GroupMembers) 
                { 
                    $UserName = $GroupMember.samaccountname
                    $InsertUserSQL = "if (Select UserInstanceID from Users U where U.UserName = '"+$UserName+"' AND U.ObjectIDAccess = "+$ObjectID+" AND U.GroupID = "+$GroupID.GroupID+") IS NULL Begin Insert into Users(UserName,ObjectIDAccess,GroupID,FirstSeen,LastSeen) Values ('"+$UserName+"',"+$ObjectID+","+$GroupID.GroupID+",GETDATE(),GETDATE()) End else update Users set LastSeen=Getdate() where UserName='"+$UserName+"' AND GroupID = "+$GroupID.GroupID+" AND ObjectIDAccess= "+$ObjectID
                    Invoke-Sqlcmd2 -ServerInstance $SQLServer -Database $database -Query $InsertUserSQL
                }
            }
            #Checks if user or computer is a direct member of the protected server group
            ElseIf (Get-ADObject -Filter {(SAMACCOUNTNAME -eq $Member) -and ((ObjectClass -eq 'user') -or (ObjectClass -eq 'computer'))} -ErrorAction SilentlyContinue)
            {
                #Adds Direct Membership GroupID
                $GroupName = 'Direct Object Membership'
                $InsertGroupSQL = "if (Select GroupID from Groups G where G.GroupName = '"+$GroupName+"' AND G.ObjectIDAccess = "+$ObjectID+") IS NULL Begin Insert into Groups (GroupName,ObjectIDAccess,FirstSeen,LastSeen) Values ('"+$Groupname+"',"+$ObjectID+",GETDATE(),GETDATE()) End else update Groups set LastSeen=Getdate() where GroupName='"+$Groupname+"' AND ObjectIDAccess="+$ObjectID
                Invoke-Sqlcmd2 -ServerInstance $SQLServer -Database $database -Query $InsertGroupSQL
                #Get the ID for the group marker we just added
                $SelectGroupIDSQL = "Select GroupID from Groups G where G.GroupName = '"+$GroupName+"' AND G.ObjectIDAccess = "+$ObjectID
                $GroupID = Invoke-Sqlcmd2 -ServerInstance $SQLServer -Database $database -Query $SelectGroupIDSQL
                $DirectUserName = Get-ADObject -Filter {SAMACCOUNTNAME -eq $Member} -Properties Samaccountname 
                $UserName = $DirectUserName.samaccountname
                $InsertDirectUserSQL = "if (Select UserInstanceID from Users U where U.UserName = '"+$UserName+"' AND U.ObjectIDAccess = "+$ObjectID+" AND U.GroupID = "+$GroupID.GroupID+") IS NULL Begin Insert into Users(UserName,ObjectIDAccess,GroupID,FirstSeen,LastSeen) Values ('"+$UserName+"',"+$ObjectID+","+$GroupID.GroupID+",GETDATE(),GETDATE()) End else update Users set LastSeen=Getdate() where UserName='"+$UserName+"' AND GroupID = "+$GroupID.GroupID+" AND ObjectIDAccess= "+$ObjectID
                Invoke-Sqlcmd2 -ServerInstance $SQLServer -Database $database -Query $InsertDirectUserSQL
            }
            else
            {
                Write-Output $Member 'is not supported'
            }
        }
    }
}
# Hardcoded variables 
    $SqlServer = 'vm-sql-umra1'
    $Database = 'Shepherd'

# Assemble and populate variables for later
	#$AllDCServers = Get-ADComputer -Filter {(OperatingSystem -like '*Server*') -AND (Enabled -eq $True) } -Properties CN,OperatingSystem,IPv4Address | where {($_.IPv4Address -Like '10.104.*') -or ($_.IPv4Address -Like '10.108.*')} |Select CN,IPv4Address
    $ProtectedServers = Invoke-Sqlcmd2 -ServerInstance $SQLServer -Database $Database -Query "SELECT [ObjectID],[ObjectDesc],[TypeID] FROM [dbo].[ProtectedObjects] Where TypeID = 1"
    $ProtectedADGroups = Invoke-Sqlcmd2 -ServerInstance $SQLServer -Database $Database -Query "SELECT [ObjectID],[ObjectDesc],[TypeID] FROM [dbo].[ProtectedObjects] Where TypeID = 2"
    $ProtectedSQLSARoles = Invoke-Sqlcmd2 -ServerInstance $SQLServer -Database $Database -Query "SELECT [ObjectID],[ObjectDesc],[TypeID] FROM [dbo].[ProtectedObjects] Where TypeID = 3"

# Gets local admins and sends to Add-RSMembers
foreach ($Server in $ProtectedServers)
{
    $LocalAdmins = Get-NetLocalGroup -Computername $Server.ObjectDesc -Group "Administrators"
    $Members = $LocalAdmins.Members.ToArray()
    Add-RSMembers -MemberArray $members -ObjectID $Server.ObjectID -SQLServer $SQLServer -Database $Database
    $LastCheckSQL = "update ProtectedObjects set LastChecked=Getdate() where ObjectID = " + $Server.ObjectID
    Invoke-Sqlcmd2 -ServerInstance $SQLServer -Database $Database -Query $LastCheckSQL
}

#Gets Members of the protected group and sends to Add-RSMembers
foreach ($ADGroup in $ProtectedADGroups)
{
    $ADGroupName = $ADGroup.ObjectDesc
    If (Get-ADObject -Filter {(SAMACCOUNTNAME -eq $ADGroupName) -and (ObjectClass -eq 'group')} -ErrorAction SilentlyContinue)
    {
        $ADGroupMembers = Get-ADGroup -identity $ADGroupName -Properties members | Select Members 
        $MembersCN = $ADGroupMembers.Members | get-adobject -Properties samaccountname | Select samaccountname
        #The $MembersCN is not compatable with Add-RSMembers, so we have to make a new $Members array. 
        $Members = New-Object System.Collections.Generic.List[System.Object]
        Foreach ($member in $MembersCN)
        {
            $Members.Add($Member.samaccountname)
        }
        Add-RSMembers -MemberArray $Members -ObjectID $ADGroup.ObjectID -SQLServer $SQLServer -Database $Database
        $LastCheckSQL = "update ProtectedObjects set LastChecked=Getdate() where ObjectID = " + $ADGroup.ObjectID
        Invoke-Sqlcmd2 -ServerInstance $SQLServer -Database $Database -Query $LastCheckSQL
    }
    Else
    {
        Write-Host $ADGroup 'is not a group. Please check that the group exists in AD.'
    }
}

# Gets sysadmins and sends to Add-RSMembers
foreach ($SQLServerSARole in $ProtectedSQLSARoles)
{
    #$SARoleMembers = Invoke-Sqlcmd2 -ServerInstance $SQLServerSARole.ObjectDesc -Query "exec sp_helpsrvrolemember 'sysadmin'"
    $SARoleMembers = Invoke-Sqlcmd2 -ServerInstance $SQLServerSARole.ObjectDesc -Query "exec sp_helpsrvrolemember 'sysadmin'"
    $Members = $SARoleMembers.MemberName
    Add-RSMembers -MemberArray $members -ObjectID $SQLServerSARole.ObjectID -SQLServer $SQLServer -Database $Database
    $LastCheckSQL = "update ProtectedObjects set LastChecked=Getdate() where ObjectID = " + $SQLServerSARole.ObjectID
    Invoke-Sqlcmd2 -ServerInstance $SqlServer -Database $Database -Query $LastCheckSQL
}


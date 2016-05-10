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
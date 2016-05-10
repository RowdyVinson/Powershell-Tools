$ClusterName = 'clst-win-jet3'
$LogDirectory = 'C:\it\'

#$ErrorActionPreference = 'Stop'

#Log file checks
if (Get-Item -Path $LogDirectory) 
    {
    Write-Host "Log path looks good"
    }
Else
    {
    Write-Host "Log path is bad. Please fix it."
    }
$datetime = (((get-date).ToUniversalTime()).ToString("yyyyMMddThhmmssZ"))
$LogFile = $LogDirectory + 'CheckCluster_' + $datetime + '.txt'

# Begin logging
####Start-Transcript -Path $LogFile

# Check that clustering is loaded and load it if it isn't already.
If (!(Get-Module failoverclusters))
    {
    Import-Module failoverclusters
    }

# Ping cluster DNS to see if it is online at all
$PingCluster = Test-Connection -ComputerName $ClusterName
$PingCluster

# Get Node list and state
$Nodes = Get-Cluster -Name $ClusterName | Get-ClusterNode
# Report Nodes and state
$Nodes | Format-Table

# Ping Nodes
Foreach ($Node in $Nodes) {Test-Connection -ComputerName $Node}

# Show resources, states, and groups
$ClusterResources = Get-Cluster -Name $ClusterName | Get-ClusterResource
$ClusterResources | sort -Property OwnerGroup | ft


# Show owners of cluster Groups
$ClusterGroups = Get-Cluster -Name $ClusterName | Get-ClusterGroup 
$ClusterGroups 

# Find SQL Group and give more depth
$SQLIPGroup = $ClusterResources | where ({$_.name -like 'SQL IP Address 1 *'})
$SQLIPGroup
$SQLName = $SQLIPGroup.name.replace("SQL IP Address 1 (", "")
$SQLName = $SQLName.replace(")", "")

# Ping the first SQL IP
Test-Connection -ComputerName $SQLName | ft

########################################################
#
# Logic for suggested remediation. 
# Unofficial as of 3/18/16 Rowdy Vinson
#
########################################################

#Did pinging the cluster fail?
IF ((Test-Connection -count 1 -ComputerName $ClusterName -quiet) -eq ($FALSE))
    {
    Write-host 'Looks like the cluster ping failed'
    }
#Are both nodes up?
Foreach ($Node in $Nodes) 
    {IF ((Test-Connection -count 1 -ComputerName $Node -quiet) -eq ($FALSE))
        {
        $Message = 'Looks like the ' + $Node + ' ping failed'
        Write-host $Message
        Write-host 'If you get this message for both nodes, try connecting to SQL via Management Studio and if that fails, initiate Mirror Failove actions (DR).'
        Write-Host 'If you get this message for a single node, check that no groups are hosted on the offline node. If they are, force them to the online node with "Move-ClusterGroup".'
        $FailedNodes += $Node
        }
    
    }
#Are any Groups owned by a node that is down?
Foreach ($Group in $ClusterGroups)
    {If (($Group.OwnerNode) -in ($FailedNodes))
        {
        $Message = 'Looks like Group ' + $Group.Name + 'is on ' + $Group.OwnerNode + 'which is down. Double check that the group resources are online. 
        Current Group state for group' + $Group.Name + ' is ' + $Group.State
        Write-host $Message
        }
    }

#Are any SQL resources offline?
Foreach ($Resource in $ClusterResources)
    {If (($Resource.OwnerGroup) -like ('SQL'))
            {
            $Message1 = 'Looks like resource "' + $Resource.Name + '" part of ' + $Resource.OwnerGroup + ' is down. This Resource is a/an ' + $Resource.ResourceType + '
    Use the Failover Cluster Management GUI to try to bring the resources back online.'
            Write-host $Message1
            
            }
        }

#Found nothing, recommend next steps.
Write-Host 'If nothing was found in error above, you may still have a problem. Read the information about the cluster, nodes, and resources to find leads that can resolve whatever problem brought you here.'

# End log

####Stop-Transcript


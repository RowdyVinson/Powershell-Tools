﻿<#  
        .SYNOPSIS
           ExportPlans.ps1 - returns the top ten most expensive execution plans based on the criteria you provide 
        .DESCRIPTION
           Execution plans are saved to the location of your choosing as .sqlplan files
        .PARAMETER sqlServer
           SQL Server and Instance you want to query
        .EXAMPLE
           c:\Scripts\ExportPlans.ps1 -sqlServer "Server\Instance"

           Queries against Server\Instance, saving files in the default location.
        .EXAMPLE
           c:\Scripts\ExportPlans.ps1 -sqlServer "Server\Instance" -filePath "D:\ServerAnalysis\ExpensivePlans"

           Queries against Server\Instance, saving files in D:\ServerAnalysis\ExpensivePlans
        .NOTES
           Script provided as is with no guarantees.  Use at your own risk and modify/share as desired
        #>
    param
    (
        [Parameter(Mandatory=$true, 
                    ValueFromPipeline=$true,
                    ValueFromPipelineByPropertyName=$true, 
                    ValueFromRemainingArguments=$false, 
                    Position=1,
                    ParameterSetName='Parameter Set 1')]
        [string]$sqlServer,


        [Parameter(Mandatory=$false, 
                    ValueFromPipeline=$true,
                    ValueFromPipelineByPropertyName=$true, 
                    ValueFromRemainingArguments=$false, 
                    Position=2,
                    ParameterSetName='Parameter Set 1')]
        [string]$filePath="C:\temp\"

    )

    #=============================#
    if (Get-Command invoke-sqlcmd -ErrorAction SilentlyContinue)
        {
        }
    else {
    Import-Module sqlps
    }

    #Here is the tsql that gets the execution plans and sprocs
    $sqlcmd="SELECT dat.name, 
                  OBJECT_NAME(object_id, eps.database_id) 'procname',   
                  execution_count,
                  query_plan
    FROM sys.dm_exec_procedure_stats AS eps  
                  join sys.databases as dat on dat.database_id = eps.database_id
                  CROSS APPLY sys.dm_exec_query_plan(eps.plan_handle)
    WHERE dat.name like 'DBNAME%' --Change For other databasename standards or to filter as needed
    ORDER BY [procname] ASC; "

    $iAmHere=Get-Location
    $filePath=($filePath+"\").Replace("\\","\")
    #$Creds = Get-Credential 'DOMAIN\user'
    $sqlResult=Invoke-SqlCmd -MaxCharLength 99999999 -Query $sqlcmd -ServerInstance $sqlServer # -Username $Creds.UserName -Password ($Creds.GetNetworkCredential().Password)

    If($?)
    {
        $timestamp = Get-Date -Format s | foreach {$_ -replace ":", ""} | foreach {$_ -replace "-",""}

        $filePath+=($sqlServer.replace("\","_"))+"\"+$timestamp

        If (!(Test-Path $filePath))
        {
            New-Item -Path $filePath -ItemType "Directory"
        }

        $queryNum=0
        $Procs = @()
        foreach ($d in $sqlResult)
        {
            $queryNum+=1
            $fileName=$filepath+"\"+$d.Name+"_"+$d.procname+"_"+$queryNum+".sqlplan"
            $fileValue=$d.query_plan
            New-Item -Path $fileName -ItemType file -Value $d.query_plan
            #Set namespace manager
            [xml]$plan = $Filevalue
            $nsMgr = new-object 'System.Xml.XmlNamespaceManager' $plan.NameTable;
            $nsMgr.AddNamespace("sm", 'http://schemas.microsoft.com/sqlserver/2004/07/showplan');
            $fileName=$filepath+"\"+$d.Name+"_"+$d.procname+"_"+$queryNum+"IndexesUsed.CSV"
            $plan.SelectNodes("//sm:Object", $nsMgr) | where {$_.Index -ne $null -and $_.Index -ne [string]::Empty -and $_.database -ne '[tempdb]'} | Export-Csv -Path $fileName
            $procs += $d.procname + ',' + $d.execution_count
        }

        Set-Location $iAmHere
        $fileName=$filepath+"\"+($sqlServer.replace("\","_"))+"-ProcList.txt"
        $Procs = $Procs | select -Unique
        $Procs | Out-File -FilePath $fileName
    }
    Else
    {    
        Throw $error[0].Exception
    }

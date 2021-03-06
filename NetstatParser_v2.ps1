<# Gather data by running a batch file to capture netstat data regularly. Something like below.
rem From http://stackoverflow.com/questions/203090/how-to-get-current-datetime-on-windows-command-line-in-a-suitable-format-for-us
set _my_datetime=%date%_%time%
set _my_datetime=%_my_datetime: =_%
set _my_datetime=%_my_datetime::=%
set _my_datetime=%_my_datetime:/=_%
set _my_datetime=%_my_datetime:.=_%
Netstat -n > c:\it\Netstat\Netstat_%_my_datetime%.txt
#>


# Configure these for the directory you have your netstat outputs stored and the desired output filename
$NetstatDir = "C:\it\netstat"
$OutFile = "c:\it\rowdy2.csv"



# Create blank array for catching Objects created during parsing
$OutArray = @()
# Grabs files for parsing
$NetstatFiles = get-childitem -path $NetstatDir

# Loop for handling many files
foreach ($FilePath in $NetstatFiles)
{
        # Reads Netstat output files for parsing
        $data = get-content $FilePath 
        
        # Remove starting lines
        $data = $data[4..$data.count]
        
        # Loop for parsing the contents of the data region of the file
        foreach ($line in $data)
        {
            # Uses LazyWinAdmin approach to parsing NetStat
            # http://www.lazywinadmin.com/2014/08/powershell-parse-this-netstatexe.html
            # Get rid of the first whitespaces, at the beginning of the line
            $line = $line -replace '^\s+', ''
            
            # Split each property on whitespaces block
            $line = $line -split '\s+'
            
            # Define the object and properties
                $Obj = "" | select "Protocol","LocalAddressIP","LocalAddressPort","ForeignAddressIP","ForeignAddressPort","State"
                $Obj.Protocol = $line[0]
                $Obj.LocalAddressIP = ($line[1] -split ":")[0]
                $Obj.LocalAddressPort = ($line[1] -split ":")[1]
                $Obj.ForeignAddressIP = ($line[2] -split ":")[0]
                $Obj.ForeignAddressPort = ($line[2] -split ":")[1]
                $Obj.State = $line[3]
            # Dump Obj to array
            $OutArray += $Obj
            
        }
        
}
# Write the array out to file
$outarray | export-csv $OutFile

<#
.SYNOPSIS
    ck11.proxy log parser
    v1.0
    https://github.com/itkibo/proxyparser

.DESCRIPTION
    This script extracts data from source log file and save result as csv file.
    By default, it processes all files by mask from script running folder.
    One source file = one result file.
#>

[CmdletBinding()]
param(
    [string]$folder = ".\",         # default source files folder
    [string]$filter = "*.usrlog",   # default source files extension 
    [string]$addr = 0               # default param number to extract 
)


function Extract_data([string]$file_path, [int]$addr) {

    $csv_path = $file_path + "___$([string]$addr)__.csv"
    $k_order = @('row', 'time', 'msec', 'ip', 'addr', 'value')
    $csv_row = $($k_order -join ';')
    
    'sep=;' >> $csv_path
    $csv_row >> $csv_path

    $row_num = 0
    $reader = new-object System.IO.StreamReader($file_path)

    while($null -ne ($line = $reader.ReadLine())) {

        $row_num++

        # check header pattern
        $matched_row = [regex]::match($line, "^(\d{2}:\d{2}:\d{2})\.(\d{3})\s.+'(.+)'") 
        if ($matched_row.success -eq $true) {

            # it is header
            
            $row_data = @{
                'row' = $row_num
                'time' = $matched_row.groups[1].value
                'msec' = $matched_row.groups[2].value
                'ip' = $matched_row.groups[3].value
            }

        } else {

            # check ordinary row pattern
            $matched_row = [regex]::match($line, "^\s+Addr=(\d{1,4})\sValue=(.+?)\s")
            # it is ordinary row
            if ($matched_row.success -eq $true) {
                
                # check addr number
                if ([int]$matched_row.groups[1].value -ne $addr) { continue }
                
                $row_data['addr'] = $matched_row.groups[1].value
                $row_data['value'] = [string]($matched_row.groups[2].value).replace('.', ',')

                # append row to csv
                $ordinary_row = ''
                foreach ($k in $k_order) {
                    $ordinary_row = $ordinary_row + $row_data[$k] + ';'
                }
                $ordinary_row >> $csv_path

            }

        }  # if

    }  # while

}  # Extract_data


<#
    GO
#>

$script_path = Split-Path -parent $MyInvocation.MyCommand.Definition
Set-Location -Path $script_path

if (Test-Path -Path $folder -PathType Container) {
    $folder = Resolve-Path -Path $folder
}

foreach ($file in Get-Item -Path "$folder\$filter") {
    Extract_data -file_path $file.FullName -addr $addr
    Write-host "$($file.Name) done."
}

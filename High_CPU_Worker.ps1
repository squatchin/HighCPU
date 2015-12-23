param( 
    [string] $sortCriteria = "Processor", 
    [int] $Count = 5
    )

function main { 

    Write-Host "
    888    888 8888888 .d8888b.  888    888       .d8888b.  8888888b.  888     888 
    888    888   888  d88P  Y88b 888    888      d88P  Y88b 888   Y88b 888     888 
    888    888   888  888    888 888    888      888    888 888    888 888     888 
    8888888888   888  888        8888888888      888        888   d88P 888     888 
    888    888   888  888  88888 888    888      888        8888888P   888     888 
    888    888   888  888    888 888    888      888    888 888        888     888 
    888    888   888  Y88b  d88P 888    888      Y88b  d88P 888        Y88b. .d88P 
    888    888 8888888 Y8888P88  888    888        Y8888P   888          Y88888P 

    Finding the PID with the highest CPU usage.. 
    ";
    $cpuPerfCounters = @{} 
    $ioOtherOpsPerfCounters = @{} 
    $ioOtherBytesPerfCounters = @{} 
    $ioDataOpsPerfCounters = @{} 
    $ioDataBytesPerfCounters = @{} 
    $processes = $null 
    $lastPoll = get-date 
     
    $lastSnapshotCount = 0 
    $lastWindowHeight = 0 
     
    $processes = get-process | sort Id 

    foreach($process in $processes) 
    { 
        $cpuPercent = @(for($i=0;$i -lt 10;$i++)
        { 
            get-cpuPercent $process
        }) | measure-object -average 
        
        [int]$Percent = $cpuPercent.Average
        $process | add-member NoteProperty Processor $Percent -force

     } 
     
     $output = $processes | sort -desc $sortCriteria | select -Index 0
     $output | format-table Id -Autosize -HideTableHeaders | Out-File C:\procdump\pid.txt
         
} 


function get-diskActivity ( 
    $process = $(throw "Please specify a process for which to get disk usage.") 
    ) 
{ 
    $processName = get-processName $process 
     
    if(-not $ioOtherOpsPerfCounters[$processName]) 
    { 
        $ioOtherOpsPerfCounters[$processName] = new-object System.Diagnostics.PerformanceCounter("Process","IO Other Operations/sec",$processName)
    } 
    if(-not $ioOtherBytesPerfCounters[$processName]) 
    { 
        $ioOtherBytesPerfCounters[$processName] = new-object System.Diagnostics.PerformanceCounter("Process","IO Other Bytes/sec",$processName) 
    } 
    if(-not $ioDataOpsPerfCounters[$processName]) 
    { 
        $ioDataOpsPerfCounters[$processName] = new-object System.Diagnostics.PerformanceCounter("Process","IO Data Operations/sec",$processName)
    } 
    if(-not $ioDataBytesPerfCounters[$processName]) 
    { 
        $ioDataBytesPerfCounters[$processName] = new-object System.Diagnostics.PerformanceCounter("Process","IO Data Bytes/sec",$processName)
    } 


    trap { continue; } 

    $ioOther = (100 * $ioOtherOpsPerfCounters[$processName].NextValue()) + ($ioOtherBytesPerfCounters[$processName].NextValue()) 
    $ioData = (100 * $ioDataOpsPerfCounters[$processName].NextValue()) + ($ioDataBytesPerfCounters[$processName].NextValue()) 
     
    return [int] ($ioOther + $ioData)     
} 


function get-cpuPercent ( 
    $process = $(throw "Please specify a process for which to get CPU usage.") 
    ) 
{ 
    $processName = get-processName $process 
      
    if(-not $cpuPerfCounters[$processName]) 
    { 
        $cpuPerfCounters[$processName] = new-object System.Diagnostics.PerformanceCounter("Process","% Processor Time",$processName)
    } 

    trap { continue; } 

    $cpuTime = ($cpuPerfCounters[$processName].NextValue() / $env:NUMBER_OF_PROCESSORS) 
    return [int] $cpuTime 
} 


function get-processName ( 
    $process = $(throw "Please specify a process for which to get the name.") 
    ) 
{ 

    $errorActionPreference = "SilentlyContinue" 

    $processName = $process.ProcessName 
    $localProcesses = get-process -ProcessName $processName | sort Id 
     
    if(@($localProcesses).Count -gt 1) 
    { 
 
        $processNumber = -1 
        for($counter = 0; $counter -lt $localProcesses.Count; $counter++) 
        { 
            if($localProcesses[$counter].Id -eq $process.Id) { break } 
        } 
         
        $processName += "#$counter" 
    } 
     
    return $processName 
} 

. main

$apppath = "C:\procdump\procdump.exe"
$switch = '-ma'
$path = 'C:\appdumps\'
$eula = '-accepteula'
$file = "C:\procdump\pid.txt"

$newpid = (get-content C:\procdump\pid.txt -totalcount 9)[1]

if($newpid -gt 0) {
    & $apppath $switch $newpid $path $eula}
else {"    The PID is: " + $newpid + "(System Idle Process). Cannot continue."
      Write-Host "";
     }

#& $apppath $switch $newpid $path $eula

    pause
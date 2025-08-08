# PersonalUtils Module
# Personal utility functions and helpers

function Get-SystemInfo {
    <#
    .SYNOPSIS
        Gets comprehensive system information
    .EXAMPLE
        Get-SystemInfo
    #>
    [CmdletBinding()]
    param()

    try {
        $os = Get-CimInstance -ClassName Win32_OperatingSystem
        $computer = Get-CimInstance -ClassName Win32_ComputerSystem
        $processor = Get-CimInstance -ClassName Win32_Processor | Select-Object -First 1
        
        return [PSCustomObject]@{
            ComputerName = $env:COMPUTERNAME
            OperatingSystem = $os.Caption
            Version = $os.Version
            Architecture = $os.OSArchitecture
            TotalMemoryGB = [math]::Round($computer.TotalPhysicalMemory / 1GB, 2)
            Processor = $processor.Name
            ProcessorCores = $processor.NumberOfCores
            LogicalProcessors = $processor.NumberOfLogicalProcessors
            CurrentUser = $env:USERNAME
            Domain = $env:USERDOMAIN
            PowerShellVersion = $PSVersionTable.PSVersion
            LastBootTime = $os.LastBootUpTime
            Uptime = (Get-Date) - $os.LastBootUpTime
        }
    }
    catch {
        Write-Error "Failed to get system info: $($_.Exception.Message)"
    }
}

function Start-ElevatedProcess {
    <#
    .SYNOPSIS
        Starts a process with elevated privileges
    .PARAMETER FilePath
        Path to the executable
    .PARAMETER ArgumentList
        Arguments to pass to the process
    .EXAMPLE
        Start-ElevatedProcess -FilePath "powershell.exe" -ArgumentList "-NoProfile"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        
        [Parameter()]
        [string[]]$ArgumentList = @()
    )

    try {
        $processInfo = New-Object System.Diagnostics.ProcessStartInfo
        $processInfo.FileName = $FilePath
        $processInfo.Arguments = $ArgumentList -join ' '
        $processInfo.Verb = "RunAs"
        $processInfo.UseShellExecute = $true
        
        $process = [System.Diagnostics.Process]::Start($processInfo)
        Write-Host "✅ Started elevated process: $FilePath" -ForegroundColor Green
        return $process
    }
    catch {
        Write-Error "Failed to start elevated process: $($_.Exception.Message)"
    }
}

function Test-Port {
    <#
    .SYNOPSIS
        Tests if a TCP port is open on a remote host
    .PARAMETER ComputerName
        The target computer name or IP address
    .PARAMETER Port
        The TCP port to test
    .PARAMETER TimeoutSeconds
        Connection timeout in seconds
    .EXAMPLE
        Test-Port -ComputerName "google.com" -Port 443
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ComputerName,
        
        [Parameter(Mandatory = $true)]
        [int]$Port,
        
        [Parameter()]
        [int]$TimeoutSeconds = 3
    )

    try {
        $tcpClient = New-Object System.Net.Sockets.TcpClient
        $connect = $tcpClient.BeginConnect($ComputerName, $Port, $null, $null)
        $wait = $connect.AsyncWaitHandle.WaitOne($TimeoutSeconds * 1000, $false)
        
        if ($wait) {
            try {
                $tcpClient.EndConnect($connect)
                $result = $true
                Write-Host "✅ Port $Port is open on $ComputerName" -ForegroundColor Green
            }
            catch {
                $result = $false
                Write-Host "❌ Port $Port is closed on $ComputerName" -ForegroundColor Red
            }
        }
        else {
            $result = $false
            Write-Host "⏱️ Connection to $ComputerName`:$Port timed out" -ForegroundColor Yellow
        }
        
        $tcpClient.Close()
        return $result
    }
    catch {
        Write-Error "Failed to test port: $($_.Exception.Message)"
        return $false
    }
}
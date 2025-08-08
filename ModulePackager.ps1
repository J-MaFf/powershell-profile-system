# Module Packaging and Deployment Utilities
# This script helps package modules for Gist storage and deployment

function Export-ModuleToGist {
    <#
    .SYNOPSIS
        Packages a PowerShell module for storage in a GitHub gist
    .DESCRIPTION
        Compresses and encodes module files for efficient storage and transfer
    .PARAMETER ModulePath
        Path to the module directory containing .psm1, .psd1, and other files
    .PARAMETER ModuleName
        Name of the module (will be used for the output JSON filename)
    .PARAMETER GistID
        Optional: GitHub Gist ID to upload directly (requires GitHub CLI)
    .EXAMPLE
        Export-ModuleToGist -ModulePath "C:\MyModule" -ModuleName "MyModule"
    .EXAMPLE
        Export-ModuleToGist -ModulePath ".\ActiveDirectoryUtils" -ModuleName "ActiveDirectoryUtils" -GistID "9703719c416c0209f2e6877b3befd491"
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$ModulePath,

        [Parameter(Mandatory = $true)]
        [string]$ModuleName,

        [Parameter()]
        [string]$GistID
    )

    if (-not (Test-Path $ModulePath)) {
        Write-Error "Module path not found: $ModulePath"
        return
    }

    Write-Host "📦 Packaging module: $ModuleName" -ForegroundColor Cyan

    # Resolve the module path to absolute path
    $resolvedModulePath = Resolve-Path $ModulePath

    # Get all files in the module directory
    $moduleFiles = Get-ChildItem -Path $ModulePath -Recurse -File

    # Create a hashtable to store module structure
    $moduleData = @{
        Name        = $ModuleName
        Version     = '1.0.0'
        CreatedDate = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
        Files       = @{}
    }

    $totalOriginalSize = 0
    $totalCompressedSize = 0

    foreach ($file in $moduleFiles) {
        $relativePath = $file.FullName.Substring($resolvedModulePath.Path.Length + 1)
        $content = Get-Content -Path $file.FullName -Raw -Encoding UTF8

        # Compress and encode the content for storage
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($content)
        $compressed = [System.IO.MemoryStream]::new()
        $gzipStream = [System.IO.Compression.GzipStream]::new($compressed, [System.IO.Compression.CompressionMode]::Compress)
        $gzipStream.Write($bytes, 0, $bytes.Length)
        $gzipStream.Close()
        $compressedBytes = $compressed.ToArray()
        $encoded = [Convert]::ToBase64String($compressedBytes)

        $moduleData.Files[$relativePath] = @{
            Content        = $encoded
            OriginalSize   = $bytes.Length
            CompressedSize = $compressedBytes.Length
        }

        $totalOriginalSize += $bytes.Length
        $totalCompressedSize += $compressedBytes.Length

        Write-Verbose "Compressed $relativePath`: $($bytes.Length) → $($compressedBytes.Length) bytes"
    }

    # Convert to JSON
    $json = $moduleData | ConvertTo-Json -Depth 10 -Compress

    # Save to file for upload to Gist
    $outputFile = "$ModuleName-Module.json"
    Set-Content -Path $outputFile -Value $json -Encoding UTF8

    # Calculate compression ratio
    $compressionRatio = [math]::Round((1 - ($totalCompressedSize / $totalOriginalSize)) * 100, 1)

    Write-Host "✅ Module '$ModuleName' packaged successfully!" -ForegroundColor Green
    Write-Host "📁 Output file: $outputFile" -ForegroundColor White
    Write-Host "📊 Compression: $totalOriginalSize → $totalCompressedSize bytes ($compressionRatio% reduction)" -ForegroundColor Yellow

    if ($GistID) {
        # Try to upload to gist if GitHub CLI is available
        if (Get-Command gh -ErrorAction SilentlyContinue) {
            try {
                Write-Host "🚀 Uploading to gist $GistID..." -ForegroundColor Cyan
                gh gist edit $GistID --add $outputFile
                Write-Host '✅ Successfully uploaded to gist!' -ForegroundColor Green
            }
            catch {
                Write-Warning "Failed to upload to gist: $($_.Exception.Message)"
                Write-Host "📝 Manually upload $outputFile to your gist" -ForegroundColor Yellow
            }
        }
        else {
            Write-Host "📝 GitHub CLI not found. Manually upload $outputFile to gist: $GistID" -ForegroundColor Yellow
        }
    }
    else {
        Write-Host "📝 Upload $outputFile to your PowerShell system gist" -ForegroundColor Cyan
    }

    return $json
}

function Import-ModuleFromGist {
    <#
    .SYNOPSIS
        Imports a module from compressed JSON format to a local directory
    .DESCRIPTION
        Decompresses and extracts module files from the Gist JSON format
    .PARAMETER ModuleJson
        JSON string containing the compressed module data
    .PARAMETER DestinationPath
        Path where the module should be extracted
    .EXAMPLE
        $json = Get-Content "ActiveDirectoryUtils-Module.json" -Raw
        Import-ModuleFromGist -ModuleJson $json -DestinationPath "C:\Modules"
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$ModuleJson,

        [Parameter(Mandatory = $true)]
        [string]$DestinationPath
    )

    try {
        Write-Host '📦 Importing module from JSON...' -ForegroundColor Cyan

        $moduleData = $ModuleJson | ConvertFrom-Json
        $modulePath = Join-Path $DestinationPath $moduleData.Name

        if (-not (Test-Path $modulePath)) {
            New-Item -ItemType Directory -Path $modulePath -Force | Out-Null
        }

        foreach ($fileInfo in $moduleData.Files.PSObject.Properties) {
            $filePath = Join-Path $modulePath $fileInfo.Name
            $fileDir = Split-Path $filePath -Parent

            if (-not (Test-Path $fileDir)) {
                New-Item -ItemType Directory -Path $fileDir -Force | Out-Null
            }

            # Decode and decompress content
            $encoded = $fileInfo.Value.Content
            $compressedBytes = [Convert]::FromBase64String($encoded)

            $compressed = [System.IO.MemoryStream]::new($compressedBytes)
            $gzipStream = [System.IO.Compression.GzipStream]::new($compressed, [System.IO.Compression.CompressionMode]::Decompress)
            $decompressed = [System.IO.MemoryStream]::new()
            $gzipStream.CopyTo($decompressed)
            $bytes = $decompressed.ToArray()
            $content = [System.Text.Encoding]::UTF8.GetString($bytes)

            Set-Content -Path $filePath -Value $content -Encoding UTF8

            # Cleanup streams
            $gzipStream.Close()
            $compressed.Close()
            $decompressed.Close()

            Write-Verbose "Extracted: $($fileInfo.Name)"
        }

        Write-Host "✅ Module '$($moduleData.Name)' extracted to: $modulePath" -ForegroundColor Green
        return $modulePath
    }
    catch {
        Write-Error "Failed to import module: $($_.Exception.Message)"
        return $null
    }
}

function Update-ModuleInGist {
    <#
    .SYNOPSIS
        Updates an existing module in your PowerShell system gist
    .DESCRIPTION
        Re-packages a local module and updates it in the consolidated gist
    .PARAMETER ModulePath
        Path to the updated module directory
    .PARAMETER ModuleName
        Name of the module to update
    .PARAMETER GistID
        The consolidated PowerShell system gist ID
    .EXAMPLE
        Update-ModuleInGist -ModulePath ".\ActiveDirectoryUtils" -ModuleName "ActiveDirectoryUtils" -GistID "9703719c416c0209f2e6877b3befd491"
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$ModulePath,

        [Parameter(Mandatory = $true)]
        [string]$ModuleName,

        [Parameter()]
        [string]$GistID = '9703719c416c0209f2e6877b3befd491'  # Default to consolidated gist
    )

    Write-Host "🔄 Updating module '$ModuleName' in gist..." -ForegroundColor Cyan

    # Package the module
    $result = Export-ModuleToGist -ModulePath $ModulePath -ModuleName $ModuleName -GistID $GistID

    if ($result) {
        Write-Host "✅ Module '$ModuleName' updated successfully!" -ForegroundColor Green
        Write-Host '🔄 Clear your profile cache to use the updated module:' -ForegroundColor Yellow
        Write-Host "   Remove-Item `"`$env:TEMP\GistModules`" -Recurse -Force" -ForegroundColor White
    }
}

# Example usage when script is run directly
if ($null -eq $MyInvocation.InvocationName -or $MyInvocation.Line -eq $MyInvocation.MyCommand.Definition) {
    Write-Host '🛠️ PowerShell Module Packager' -ForegroundColor Green
    Write-Host '================================' -ForegroundColor Green
    Write-Host ''
    Write-Host 'Available functions:' -ForegroundColor Cyan
    Write-Host '• Export-ModuleToGist   - Package a module for gist storage' -ForegroundColor White
    Write-Host '• Import-ModuleFromGist - Extract a module from gist JSON' -ForegroundColor White
    Write-Host '• Update-ModuleInGist   - Update an existing module in gist' -ForegroundColor White
    Write-Host ''
    Write-Host 'Examples:' -ForegroundColor Cyan
    Write-Host "Export-ModuleToGist -ModulePath '.\MyModule' -ModuleName 'MyModule'" -ForegroundColor Gray
    Write-Host "Update-ModuleInGist -ModulePath '.\ActiveDirectoryUtils' -ModuleName 'ActiveDirectoryUtils'" -ForegroundColor Gray
    Write-Host ''
    Write-Host 'Current consolidated gist: 9703719c416c0209f2e6877b3befd491' -ForegroundColor Yellow
}
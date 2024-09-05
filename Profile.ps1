function Merge-CsFiles {
    param(
        [string]$OutputFolderPath = $(Get-Location),
        [switch]$Recurse
    )

    if ($Recurse) {
        $allCsFiles = Get-ChildItem *.cs -Recurse
    } else {
        $allCsFiles = Get-ChildItem *.cs -Depth 0
    }

    if ($allCsFiles.Count -eq 0) {
        Write-Host "No .cs files found"
        return
    }

    $OriginalLocation = Get-Location
    $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss" 
    $OutputFilePath = Join-Path $OutputFolderPath "merged_$timestamp.txt"

    try {
        if ($Recurse) {
            $topLevelFiles = $allCsFiles | Where-Object { $_.Directory.FullName -eq $OriginalLocation } 
            $subfolderFiles = $allCsFiles | Where-Object { $_.Directory.FullName -ne $OriginalLocation }
        } else {
            $topLevelFiles = $allCsFiles
            $subfolderFiles = @()
        }
        $topLevelFiles | ForEach-Object { 
            ProcessFile $_ $OutputFilePath
        }

        if ($Recurse) {
            $subfolderFiles | Group-Object { $_.Directory.FullName } | Sort-Object { $_.Name } | ForEach-Object {
                $relativeFolderPath = Resolve-Path $_.Name -Relative
                $_.Group | Sort-Object { $_.Name } | ForEach-Object {
                    ProcessFile $_ $OutputFilePath
                }
            }
        }

        $relativeOutputFilePath = Resolve-Path $OutputFilePath -Relative
        Write-Host "Files merged successfully to $relativeOutputFilePath"
    }
    catch [System.IO.FileNotFoundException] {
        Write-Error "File not found: $($_.Exception.Message)"
    }
    catch [System.UnauthorizedAccessException] {
        Write-Error "Permission denied: $($_.Exception.Message)"
    }
    catch {
        Write-Error "An error occurred: $($_.Exception.Message)"
    }
    finally {
        Set-Location $OriginalLocation
    }
}

function ProcessFile($file, $outputFilePath) {
    $streamReader = New-Object System.IO.StreamReader($file.FullName)
    $encoding = $streamReader.CurrentEncoding
    $streamReader.Close()

    Add-Content $outputFilePath "" -Encoding $encoding
    $relativePath = Resolve-Path $file.FullName -Relative
    Add-Content $outputFilePath "// FILE: $relativePath" -Encoding $encoding
    Add-Content $outputFilePath "" -Encoding $encoding
    Get-Content $file.FullName -Encoding $encoding | Add-Content $outputFilePath -Encoding $encoding
}
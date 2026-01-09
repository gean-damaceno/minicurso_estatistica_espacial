param(
    [string]$ProjectPath = (Get-Location).Path
)

$mf = Join-Path $ProjectPath "minicurso_files"

Write-Host "Stopping quarto processes (if any)..."
Get-Process -Name quarto -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue

Write-Host "Attempting to remove: $mf"
if (Test-Path $mf) {
    try {
        Remove-Item -LiteralPath $mf -Recurse -Force -ErrorAction Stop
        Write-Host "Removed: $mf"
    } catch {
        Write-Host "ERROR: Failed to remove '$mf' — $($_.Exception.Message)"
        Write-Host "Suggestion: pause Google Drive/OneDrive sync, close Explorer windows, then re-run this script."
        exit 1
    }
} else {
    Write-Host "No existing minicurso_files directory found — continuing"
}

Write-Host "Starting quarto preview for: $ProjectPath\minicurso.qmd"
quarto preview "$ProjectPath\minicurso.qmd" --no-browser

param(
    [switch]$WhatIf
)

$ErrorActionPreference = "Stop"

# ---------- paths ----------
$kitDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$globalSkillsDir = "$env:USERPROFILE\.claude\skills"

Write-Host ""
Write-Host "=== Pipeline Runner - Uninstall ==="
Write-Host ""

# ---------- skill mapping ----------
$skillMap = @(
    @{ Name="pipeline-runner" },
    @{ Name="solution-design" },
    @{ Name="task-splitter" },
    @{ Name="backend-coder" },
    @{ Name="frontend-coder" },
    @{ Name="test-master" },
    @{ Name="code-reviewer-agent" },
    @{ Name="security-reviewer" },
    @{ Name="perf-reviewer" }
)

# ---------- remove skills ----------
$removed = 0
$notFound = 0
$failed = 0

foreach ($skill in $skillMap) {
    $destDir = Join-Path $globalSkillsDir $skill.Name

    if (-not (Test-Path $destDir)) {
        Write-Host "  - $($skill.Name) (not installed)" -ForegroundColor Gray
        $notFound++
        continue
    }

    try {
        Remove-Item -Path $destDir -Recurse -Force -WhatIf:$WhatIf
        Write-Host "  $([char]0x2713) $($skill.Name) (removed)" -ForegroundColor Green
        $removed++
    } catch {
        Write-Host "  $([char]0x2717) $($skill.Name) FAILED: $_" -ForegroundColor Red
        $failed++
    }
}

# ---------- clean workflow ----------
$workflowDir = Join-Path $kitDir ".claude\workflow"
if (Test-Path $workflowDir) {
    try {
        Remove-Item -Path $workflowDir -Recurse -Force -WhatIf:$WhatIf
        Write-Host ""
        Write-Host "  $([char]0x2713) .claude/workflow (runtime state cleaned)" -ForegroundColor Green
    } catch {
        Write-Host ""
        Write-Host "  $([char]0x2717) .claude/workflow clean FAILED: $_" -ForegroundColor Red
    }
}

# ---------- summary ----------
Write-Host ""
Write-Host "=== Uninstall Complete ===" -ForegroundColor Cyan
Write-Host "  Removed: $removed" -ForegroundColor Green
if ($notFound -gt 0) {
    Write-Host "  Not installed: $notFound" -ForegroundColor Yellow
}
if ($failed -gt 0) {
    Write-Host "  Failed: $failed" -ForegroundColor Red
}
Write-Host ""
Write-Host "Note: permission entries in $env:USERPROFILE\.claude\settings.local.json" -ForegroundColor Yellow
Write-Host "  were not modified. You may remove Pipeline Runner entries manually if desired."
Write-Host ""

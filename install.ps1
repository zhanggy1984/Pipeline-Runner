param(
    [switch]$Force
)

$ErrorActionPreference = "Stop"

# ---------- paths ----------
$kitDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$globalSkillsDir = "$env:USERPROFILE\.claude\skills"

Write-Host ""
Write-Host "=== Pipeline Runner - Install ==="
Write-Host ""

# ---------- skill mapping ----------
# category/subdir -> skill name (directory name under ~/.claude/skills/)
$skillMap = @(
    @{ Src="skills/workflow/pipeline-runner.md"; Name="pipeline-runner" },
    @{ Src="skills/design/solution-design.md";       Name="solution-design" },
    @{ Src="skills/planning/task-splitter.md";       Name="task-splitter" },
    @{ Src="skills/coding/backend-coder.md";         Name="backend-coder" },
    @{ Src="skills/coding/frontend-coder.md";        Name="frontend-coder" },
    @{ Src="skills/testing/test-master.md";          Name="test-master" },
    @{ Src="skills/review/code-reviewer-agent.md";   Name="code-reviewer-agent" },
    @{ Src="skills/review/security-reviewer.md";     Name="security-reviewer" },
    @{ Src="skills/review/perf-reviewer.md";         Name="perf-reviewer" }
)

# ---------- check ----------
if (-not (Test-Path $globalSkillsDir)) {
    Write-Host "Creating $globalSkillsDir ..." -ForegroundColor Cyan
    New-Item -ItemType Directory -Path $globalSkillsDir -Force | Out-Null
}

# ---------- install ----------
$installed = 0
$failed = 0

foreach ($skill in $skillMap) {
    $srcFile = Join-Path $kitDir $skill.Src
    $destDir = Join-Path $globalSkillsDir $skill.Name
    $destFile = Join-Path $destDir "SKILL.md"

    if (-not (Test-Path $srcFile)) {
        Write-Host "  ✗ MISSING: $($skill.Src)" -ForegroundColor Red
        $failed++
        continue
    }

    # Check if already installed
    $exists = Test-Path $destFile
    if ($exists -and -not $Force) {
        Write-Host "  ~ $($skill.Name) already exists (use -Force to overwrite)" -ForegroundColor Yellow
        $installed++
        continue
    }

    if (-not (Test-Path $destDir)) {
        New-Item -ItemType Directory -Path $destDir -Force | Out-Null
    }

    try {
        Copy-Item -Path $srcFile -Destination $destFile -Force
        if ($exists) {
            Write-Host "  ↻ $($skill.Name) (updated)" -ForegroundColor Green
        } else {
            Write-Host "  + $($skill.Name)" -ForegroundColor Green
        }
        $installed++
    } catch {
        Write-Host "  ✗ $($skill.Name) FAILED: $_" -ForegroundColor Red
        $failed++
    }
}

# ---------- summary ----------
Write-Host ""
Write-Host "=== Install Complete ===" -ForegroundColor Cyan
Write-Host "  Installed/OK: $installed" -ForegroundColor Green
if ($failed -gt 0) {
    Write-Host "  Failed: $failed" -ForegroundColor Red
}
Write-Host ""
Write-Host "Available skills:" -ForegroundColor Yellow
Write-Host "  /pipeline-runner       Pipeline orchestrator (entry point)"
Write-Host "  /solution-design       Technical solution design"
Write-Host "  /task-splitter         Task breakdown"
Write-Host "  /backend-coder         Backend coding (Java/Spring Boot)"
Write-Host "  /frontend-coder        Frontend coding (React/Vue)"
Write-Host "  /test-master           Unit test generation & execution"
Write-Host "  /code-reviewer-agent   Code review"
Write-Host "  /security-reviewer     Security audit"
Write-Host "  /perf-reviewer         Performance audit"
Write-Host ""
Write-Host "Quick Start: /pipeline-runner full 'your task description'" -ForegroundColor Cyan
Write-Host ""

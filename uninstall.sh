#!/usr/bin/env bash
set -euo pipefail

# ---------- args ----------
DRY_RUN=false
if [ "${1:-}" = "--dry-run" ]; then
    DRY_RUN=true
fi

# ---------- paths ----------
KIT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILLS_DIR="${HOME}/.claude/skills"

echo ""
echo "=== Pipeline Runner - Uninstall ==="
if $DRY_RUN; then
    echo -e "  \033[33m[Dry-run mode — no changes will be made]\033[0m"
fi
echo ""

# ---------- skill mapping ----------
SKILL_NAMES=(
    "pipeline-runner"
    "solution-design"
    "task-splitter"
    "backend-coder"
    "frontend-coder"
    "test-master"
    "code-reviewer-agent"
    "security-reviewer"
    "perf-reviewer"
)

# ---------- remove skills ----------
REMOVED=0
NOT_FOUND=0
FAILED=0

for NAME in "${SKILL_NAMES[@]}"; do
    DEST_DIR="${SKILLS_DIR}/${NAME}"

    if [ ! -d "$DEST_DIR" ]; then
        echo -e "  \033[90m- ${NAME} (not installed)\033[0m"
        ((NOT_FOUND++)) || true
        continue
    fi

    if $DRY_RUN; then
        echo -e "  \033[33m→ ${NAME} (would remove)\033[0m"
        ((REMOVED++)) || true
    elif rm -rf "$DEST_DIR"; then
        echo -e "  \033[32m✓ ${NAME} (removed)\033[0m"
        ((REMOVED++)) || true
    else
        echo -e "  \033[31m✗ ${NAME} FAILED\033[0m"
        ((FAILED++)) || true
    fi
done

# ---------- clean workflow ----------
WORKFLOW_DIR="${KIT_DIR}/.claude/workflow"
if [ -d "$WORKFLOW_DIR" ]; then
    if $DRY_RUN; then
        echo ""
        echo -e "  \033[33m→ .claude/workflow (would remove)\033[0m"
    elif rm -rf "$WORKFLOW_DIR"; then
        echo ""
        echo -e "  \033[32m✓ .claude/workflow (runtime state cleaned)\033[0m"
    else
        echo ""
        echo -e "  \033[31m✗ .claude/workflow clean FAILED\033[0m"
    fi
fi

# ---------- summary ----------
echo ""
echo -e "\033[36m=== Uninstall Complete ===\033[0m"
echo -e "  Removed: ${REMOVED}"
if [ "$NOT_FOUND" -gt 0 ]; then
    echo -e "  \033[33mNot installed: ${NOT_FOUND}\033[0m"
fi
if [ "$FAILED" -gt 0 ]; then
    echo -e "  \033[31mFailed: ${FAILED}\033[0m"
fi
echo ""
echo -e "\033[33mNote: permission entries in ~/.claude/settings.local.json\033[0m"
echo -e "\033[33m  were not modified. You may remove Pipeline Runner entries manually if desired.\033[0m"
echo ""

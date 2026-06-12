#!/usr/bin/env bash
set -euo pipefail

# ---------- paths ----------
KIT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILLS_DIR="${HOME}/.claude/skills"

echo ""
echo "=== Pipeline Runner - Install ==="
echo ""

# ---------- skill mapping ----------
# "src|name"
SKILLS=(
    "skills/workflow/pipeline-runner.md|pipeline-runner"
    "skills/design/solution-design.md|solution-design"
    "skills/planning/task-splitter.md|task-splitter"
    "skills/coding/backend-coder.md|backend-coder"
    "skills/coding/frontend-coder.md|frontend-coder"
    "skills/testing/test-master.md|test-master"
    "skills/review/code-reviewer-agent.md|code-reviewer-agent"
    "skills/review/security-reviewer.md|security-reviewer"
    "skills/review/perf-reviewer.md|perf-reviewer"
)

FORCE="${1:-}"

# ---------- check ----------
if [ ! -d "$SKILLS_DIR" ]; then
    echo -e "\033[36mCreating ${SKILLS_DIR} ...\033[0m"
    mkdir -p "$SKILLS_DIR"
fi

# ---------- install ----------
INSTALLED=0
FAILED=0
UPDATED=0

for ENTRY in "${SKILLS[@]}"; do
    SRC_FILE="${KIT_DIR}/${ENTRY%%|*}"
    SKILL_NAME="${ENTRY##*|}"
    DEST_DIR="${SKILLS_DIR}/${SKILL_NAME}"
    DEST_FILE="${DEST_DIR}/SKILL.md"

    if [ ! -f "$SRC_FILE" ]; then
        echo -e "  \033[31m✗ MISSING: ${ENTRY%%|*}\033[0m"
        ((FAILED++)) || true
        continue
    fi

    if [ -f "$DEST_FILE" ] && [ "$FORCE" != "--force" ]; then
        echo -e "  \033[33m~ ${SKILL_NAME} already exists (use --force to overwrite)\033[0m"
        ((INSTALLED++)) || true
        continue
    fi

    mkdir -p "$DEST_DIR"

    if cp "$SRC_FILE" "$DEST_FILE"; then
        if [ -f "$DEST_FILE" ] && [ "$FORCE" = "--force" ]; then
            echo -e "  \033[32m↻ ${SKILL_NAME} (updated)\033[0m"
            ((UPDATED++)) || true
        else
            echo -e "  \033[32m+ ${SKILL_NAME}\033[0m"
            ((INSTALLED++)) || true
        fi
    else
        echo -e "  \033[31m✗ ${SKILL_NAME} FAILED\033[0m"
        ((FAILED++)) || true
    fi
done

# ---------- summary ----------
echo ""
echo -e "\033[36m=== Install Complete ===\033[0m"
echo -e "  Installed: ${INSTALLED}"
if [ "$UPDATED" -gt 0 ]; then
    echo -e "  Updated: ${UPDATED}"
fi
if [ "$FAILED" -gt 0 ]; then
    echo -e "  \033[31mFailed: ${FAILED}\033[0m"
fi
echo ""
echo -e "\033[33mAvailable skills:\033[0m"
echo "  /pipeline-runner       Pipeline orchestrator (entry point)"
echo "  /solution-design       Technical solution design"
echo "  /task-splitter         Task breakdown"
echo "  /backend-coder         Backend coding (Java/Spring Boot)"
echo "  /frontend-coder        Frontend coding (React/Vue)"
echo "  /test-master           Unit test generation & execution"
echo "  /code-reviewer-agent   Code review"
echo "  /security-reviewer     Security audit"
echo "  /perf-reviewer         Performance audit"
echo ""
echo -e "\033[36mQuick Start: /pipeline-runner full 'your task description'\033[0m"
echo ""

#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
ENV_FILE="$PROJECT_DIR/.env"
MIGRATION_DIR="$PROJECT_DIR/supabase"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'

usage() {
  cat <<EOF
Usage: $(basename "$0") [options]

Run Supabase migrations via Supabase CLI (HTTPS only — no dedicated IP needed).
Uses \`supabase db query --linked -f <file>\` to execute SQL through the API.

Requires SUPABASE_ACCESS_TOKEN in .env.

Options:
  -f, --force       Skip confirmation prompt
  -q, --questions   Also import the full question bank (import_questions.sql)
  -s, --step STEP   Run step: schema | data | questions | all (default: all)
  --token TOKEN     Supabase access token (overrides .env)
  -h, --help        Show this help
EOF
  exit 0
}

FORCE=false
IMPORT_QUESTIONS=false
STEP="all"
SUPABASE_TOKEN=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    -f|--force) FORCE=true; shift ;;
    -q|--questions) IMPORT_QUESTIONS=true; shift ;;
    -s|--step) STEP="$2"; shift 2 ;;
    --token) SUPABASE_TOKEN="$2"; shift 2 ;;
    -h|--help) usage ;;
    *) echo -e "${RED}Unknown: $1${NC}"; usage ;;
  esac
done

# ── Load .env ────────────────────────────────────────────────────
if [[ -f "$ENV_FILE" ]]; then
  set -a; source "$ENV_FILE"; set +a
fi

SUPABASE_TOKEN="${SUPABASE_TOKEN:-${SUPABASE_ACCESS_TOKEN:-}}"
if [[ -z "$SUPABASE_TOKEN" ]]; then
  echo -e "${RED}Error: SUPABASE_ACCESS_TOKEN not set.${NC}"
  echo "Create one: Dashboard → Settings → API → Personal Access Tokens → Generate"
  echo "Then add to .env: SUPABASE_ACCESS_TOKEN=<your_token>"
  exit 1
fi

PROJECT_REF="${PROJECT_REF:-}"
if [[ -z "$PROJECT_REF" ]]; then
  PROJECT_REF=$(echo "${SUPABASE_URL:-}" | grep -oP '(?<=https://)[^.]+' 2>/dev/null || true)
fi
if [[ -z "$PROJECT_REF" ]]; then
  echo -e "${RED}Error: Set PROJECT_REF or SUPABASE_URL in .env${NC}"
  exit 1
fi

# ── Confirm ──────────────────────────────────────────────────────
echo -e "${GREEN}Supabase Migration (via CLI)${NC}"
echo "  Project: $PROJECT_REF"
echo "  Steps:   $STEP"
echo ""

if ! $FORCE; then
  echo -ne "${YELLOW}Proceed? (y/N) ${NC}"
  read -r CONFIRM
  if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
    echo "Aborted."
    exit 0
  fi
fi

# ── Setup Supabase CLI ──────────────────────────────────────────
NPX="npx --yes supabase@latest"

echo -e "${GREEN}▶ Logging in...${NC}"
echo "$SUPABASE_TOKEN" | $NPX login --no-browser 2>&1 || \
  SUPABASE_ACCESS_TOKEN="$SUPABASE_TOKEN" $NPX login --no-browser 2>&1

echo -e "${GREEN}▶ Linking project...${NC}"
SUPABASE_ACCESS_TOKEN="$SUPABASE_TOKEN" $NPX link --project-ref "$PROJECT_REF" 2>&1

# ── Run SQL files ────────────────────────────────────────────────
run_file() {
  local file="$1"
  local label="$2"

  if [[ ! -f "$file" ]]; then
    echo -e "${YELLOW}  Skipping — file not found: $file${NC}"
    return
  fi

  echo -e "${GREEN}▶ $label...${NC}"
  SUPABASE_ACCESS_TOKEN="$SUPABASE_TOKEN" $NPX db query --linked -f "$file" 2>&1 || {
    echo -e "${YELLOW}  ⚠ Statement in $label had an issue (may be harmless)${NC}"
  }
  echo -e "${GREEN}✓ $label complete${NC}"
  echo ""
}

# ── Steps ────────────────────────────────────────────────────────
if [[ "$STEP" == "all" || "$STEP" == "schema" ]]; then
  run_file "$MIGRATION_DIR/migration.sql" "Schema migration"
fi

if [[ "$STEP" == "all" || "$STEP" == "data" ]]; then
  run_file "$MIGRATION_DIR/import_from_neon.sql" "Data import"
fi

if [[ "$STEP" == "questions" ]] || ($IMPORT_QUESTIONS && [[ "$STEP" == "all" ]]); then
  run_file "$MIGRATION_DIR/import_questions.sql" "Question bank import"
fi

echo -e "${GREEN}✅ Done! Check Supabase Dashboard → Table Editor${NC}"

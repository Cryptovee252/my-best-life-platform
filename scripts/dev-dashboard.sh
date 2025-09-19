#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOG_DIR="$ROOT_DIR/logs"
TMP_DIR="$ROOT_DIR/tmp"
BACKEND_LOG="$LOG_DIR/backend-dev.log"
FRONTEND_LOG="$LOG_DIR/frontend-dev.log"
BACKEND_PID_FILE="$TMP_DIR/backend-dev.pid"
FRONTEND_PID_FILE="$TMP_DIR/frontend-dev.pid"

mkdir -p "$LOG_DIR" "$TMP_DIR"

print_header() {
  echo "============================================"
  echo " HelpMyBestLife Dev Dashboard"
  echo " Root: $ROOT_DIR"
  echo "============================================"
}

is_running() {
  local pid_file="$1"
  if [[ -f "$pid_file" ]]; then
    local pid
    pid="$(cat "$pid_file")"
    if ps -p "$pid" > /dev/null 2>&1; then
      return 0
    fi
  fi
  return 1
}

start_backend() {
  if is_running "$BACKEND_PID_FILE"; then
    echo "Backend already running (PID $(cat "$BACKEND_PID_FILE"))"
    return
  fi
  echo "Starting backend (Express + Prisma) ..."
  (cd "$ROOT_DIR/backend" && nohup npm run dev > "$BACKEND_LOG" 2>&1 & echo $! > "$BACKEND_PID_FILE")
  sleep 1
  echo "Backend started. Logs: $BACKEND_LOG"
}

stop_backend() {
  if ! is_running "$BACKEND_PID_FILE"; then
    echo "Backend is not running."
    rm -f "$BACKEND_PID_FILE"
    return
  fi
  local pid
  pid="$(cat "$BACKEND_PID_FILE")"
  echo "Stopping backend (PID $pid) ..."
  kill "$pid" && rm -f "$BACKEND_PID_FILE"
  echo "Backend stopped."
}

start_frontend() {
  if is_running "$FRONTEND_PID_FILE"; then
    echo "Frontend already running (PID $(cat "$FRONTEND_PID_FILE"))"
    return
  fi
  echo "Starting frontend (Expo) ..."
  (cd "$ROOT_DIR/frontend" && nohup npm start -- --web > "$FRONTEND_LOG" 2>&1 & echo $! > "$FRONTEND_PID_FILE")
  sleep 2
  echo "Frontend started in web mode. Logs: $FRONTEND_LOG"
  echo "Open http://localhost:8081 in your browser once Metro finishes bundling."
}

stop_frontend() {
  if ! is_running "$FRONTEND_PID_FILE"; then
    echo "Frontend is not running."
    rm -f "$FRONTEND_PID_FILE"
    return
  fi
  local pid
  pid="$(cat "$FRONTEND_PID_FILE")"
  echo "Stopping frontend (PID $pid) ..."
  kill "$pid" && rm -f "$FRONTEND_PID_FILE"
  echo "Frontend stopped."
}

run_prisma_push() {
  echo "Applying Prisma schema to local database ..."
  (cd "$ROOT_DIR/backend" && npx prisma db push)
}

run_api_health_check() {
  echo "Checking backend health endpoint ..."
  if command -v curl >/dev/null 2>&1; then
    curl -s http://localhost:5000/api/health | sed 's/{/\n{/'
  else
    echo "curl not found. Please install curl to use this option."
  fi
}

run_tests() {
  echo "Running backend tests (if any) ..."
  (cd "$ROOT_DIR/backend" && npm test || true)
  echo "Running frontend tests (if any) ..."
  (cd "$ROOT_DIR/frontend" && npm test || true)
}

build_frontend_web() {
  echo "Building Expo web bundle ..."
  (cd "$ROOT_DIR/frontend" && npm run build:web)
}

git_status() {
  echo "Git status:"
  (cd "$ROOT_DIR" && git status -sb)
}

git_commit_push() {
  read -rp "Commit message: " commit_msg
  if [[ -z "$commit_msg" ]]; then
    echo "Commit aborted: message required."
    return
  fi
  (cd "$ROOT_DIR" && git add . && git commit -m "$commit_msg" && git push)
}

deploy_to_vps() {
  local script="$ROOT_DIR/deploy-to-vps.sh"
  if [[ ! -x "$script" ]]; then
    echo "Deployment script not executable. Running with bash."
    if [[ ! -f "$script" ]]; then
      echo "deploy-to-vps.sh not found."
      return
    fi
    bash "$script"
  else
    "$script"
  fi
}

show_logs() {
  echo "--- Backend log ($BACKEND_LOG) ---"
  [[ -f "$BACKEND_LOG" ]] && tail -n 20 "$BACKEND_LOG" || echo "No backend log yet."
  echo "--- Frontend log ($FRONTEND_LOG) ---"
  [[ -f "$FRONTEND_LOG" ]] && tail -n 20 "$FRONTEND_LOG" || echo "No frontend log yet."
}

main_menu() {
  while true; do
    print_header
    if is_running "$BACKEND_PID_FILE"; then
      echo "Backend: RUNNING (PID $(cat "$BACKEND_PID_FILE"))"
    else
      echo "Backend: stopped"
    fi
    if is_running "$FRONTEND_PID_FILE"; then
      echo "Frontend: RUNNING (PID $(cat "$FRONTEND_PID_FILE"))"
    else
      echo "Frontend: stopped"
    fi
    echo
    cat <<'MENU'
1) Start backend
2) Stop backend
3) Start frontend (web)
4) Stop frontend
5) Run Prisma db push
6) API health check
7) Run tests
8) Build frontend web bundle
9) Show git status
10) Commit + push to GitHub
11) Deploy to VPS
12) Show latest logs
0) Exit
MENU
    read -rp "Select an option: " choice
    case "$choice" in
      1) start_backend ;;
      2) stop_backend ;;
      3) start_frontend ;;
      4) stop_frontend ;;
      5) run_prisma_push ;;
      6) run_api_health_check ;;
      7) run_tests ;;
      8) build_frontend_web ;;
      9) git_status ;;
      10) git_commit_push ;;
      11) deploy_to_vps ;;
      12) show_logs ;;
      0) echo "Goodbye!"; exit 0 ;;
      *) echo "Invalid option" ;;
    esac
    echo
    read -rp "Press Enter to return to the menu..." _
  done
}

main_menu

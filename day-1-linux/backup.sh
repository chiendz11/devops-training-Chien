#!/usr/bin/env bash
set -euo pipefail

show_help() {
  cat <<'HELP'
Usage:
  ./backup.sh <directory>

Description:
  Backup a directory into ~/backups/ as <dir>-YYYYMMDD-HHMMSS.tar.gz

Options:
  -h, --help    Show this help message
HELP
}

die() {
  echo "Error: $*" >&2
  exit 1
}

main() {
  if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    show_help
    exit 0
  fi

  if [[ $# -ne 1 ]]; then
    show_help
    die "Missing directory argument"
  fi

  local dir="$1"

  if [[ ! -d "$dir" ]]; then
    die "Directory does not exist: $dir"
  fi

  local backup_dir="$HOME/backups"
  mkdir -p "$backup_dir"

  local abs_dir
  abs_dir="$(realpath "$dir")"

  local base_name
  base_name="$(basename "$abs_dir")"

  local parent_dir
  parent_dir="$(dirname "$abs_dir")"

  local timestamp
  timestamp="$(date +%Y%m%d-%H%M%S)"

  local archive_file="$backup_dir/${base_name}-${timestamp}.tar.gz"

  local file_count
  file_count="$(find "$abs_dir" -type f | wc -l)"

  local total_size
  total_size="$(du -sh "$abs_dir" | awk '{print $1}')"

  tar -czf "$archive_file" -C "$parent_dir" "$base_name"

  echo "Backup created: $archive_file"
  echo "Files backed up: $file_count"
  echo "Total size backed up: $total_size"
}

main "$@"

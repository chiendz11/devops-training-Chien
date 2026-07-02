#!/usr/bin/env bash

set -euo pipefail

# Có thể thay các giá trị này khi chạy để test nhanh.
INTERVAL="${INTERVAL:-10}"
CPU_THRESHOLD="${CPU_THRESHOLD:-80}"
LOG_FILE="${LOG_FILE:-$HOME/monitor.log}"

high_cpu_count=0

stop_monitor() {
  echo
  echo "Received stop signal. Monitor is exiting gracefully..."
  echo "Monitor stopped."
  exit 0
}

trap stop_monitor SIGINT SIGTERM

touch "$LOG_FILE"

echo "Monitor started"
echo "Interval: ${INTERVAL}s"
echo "CPU threshold: ${CPU_THRESHOLD}%"
echo "Warning log: $LOG_FILE"
echo "Press Ctrl+C to stop."

# Lấy giá trị CPU ban đầu từ /proc/stat.
read -r _ user nice system idle iowait irq softirq steal _ < /proc/stat
previous_idle=$((idle + iowait))
previous_total=$((user + nice + system + idle + iowait + irq + softirq + steal))

while true; do
  sleep "$INTERVAL"

  read -r _ user nice system idle iowait irq softirq steal _ < /proc/stat
  current_idle=$((idle + iowait))
  current_total=$((user + nice + system + idle + iowait + irq + softirq + steal))

  total_diff=$((current_total - previous_total))
  idle_diff=$((current_idle - previous_idle))

  if (( total_diff > 0 )); then
    cpu_usage=$((100 * (total_diff - idle_diff) / total_diff))
  else
    cpu_usage=0
  fi

  # Tính phần trăm RAM đang sử dụng.
  memory_usage="$(
    free | awk '/^Mem:/ { printf "%.0f", $3 * 100 / $2 }'
  )"

  timestamp="$(date '+%Y-%m-%d %H:%M:%S %z')"

  echo
  echo "[$timestamp] CPU=${cpu_usage}% MEM=${memory_usage}%"
  echo "Top 3 processes by CPU:"
  printf '%7s %7s %-15s %5s %5s\n' "PID" "PPID" "COMMAND" "%CPU" "%MEM"
  ps -eo pid,ppid,comm,%cpu,%mem --sort=-%cpu --no-headers |
    awk 'count < 3 && $3 != "ps" { print; count++ }'

  if (( cpu_usage > CPU_THRESHOLD )); then
    high_cpu_count=$((high_cpu_count + 1))
    echo "High CPU samples: ${high_cpu_count}/3"
  else
    high_cpu_count=0
  fi

  if (( high_cpu_count >= 3 )); then
    warning="$timestamp WARNING: CPU usage exceeded ${CPU_THRESHOLD}% for 3 consecutive samples (current=${cpu_usage}%)"
    echo "$warning"
    echo "$warning" >> "$LOG_FILE"
    high_cpu_count=0
  fi

  previous_idle="$current_idle"
  previous_total="$current_total"
done

#!/usr/bin/env bash

set -u 

sleep 300 &
child_pid=$!

echo "Spawned background process:"
echo "PID: $child_pid"
echo "PPID: $$"

echo "Sending SIGTERM to background process..."
kill -SIGTERM $child_pid

wait $child_pid
exit_code=$?

echo "Background process exited with code: $exit_code"

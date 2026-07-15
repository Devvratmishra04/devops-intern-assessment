#!/bin/bash
# sysinfo.sh - Display basic system information

echo "============================="
echo "  System Information Report"
echo "============================="
echo ""
echo "Current User : $(whoami)"
echo "Hostname     : $(hostname)"
echo "Date & Time  : $(date)"
echo "Uptime       : $(uptime -p 2>/dev/null || uptime)"
echo ""
echo "--- Disk Usage ---"
df -h
echo ""
echo "--- Memory Usage ---"
free -h 2>/dev/null || echo "(free command not available on this OS)"
echo ""
echo "============================="

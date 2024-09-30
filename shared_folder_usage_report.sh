#!/bin/bash
#==================================================================================
# Script Name: shared_folder_usage_report.sh
# Version: 1.0
# Author: Andy Saputra
# License: MIT License
# Link: https://github.com/ajsap/synology_shared_folders_usage_report/
# Description: Calculates shared folder sizes and generates a usage report.
#
# Copyright (C) 2024 Andy Saputra
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#
#==================================================================================

# Exit immediately if a command exits with a non-zero status
set -e

# Command paths
DU_CMD="/usr/bin/du"
AWK_CMD="/bin/awk"
DF_CMD="/bin/df"
UPTIME_CMD="/usr/bin/uptime"
FREE_CMD="/usr/bin/free"
TOP_CMD="/usr/bin/top"
LS_CMD="/bin/ls"

# Ensure commands exist
for cmd in "$DU_CMD" "$AWK_CMD" "$DF_CMD" "$UPTIME_CMD" "$FREE_CMD" "$TOP_CMD" "$LS_CMD"; do
    if ! [ -x "$cmd" ]; then
        echo "Error: Command not found or not executable: $cmd"
        exit 1
    fi
done

# Shared folder base path (adjust if necessary)
SHARED_FOLDER_BASE="/volume1"

# Get list of shared folders
SHARE_LIST=$($LS_CMD -1 "$SHARED_FOLDER_BASE")

# Initialize total usage
TOTAL_USAGE=0

# Start the report
echo "=========================================================="
echo "              Shared Folder Usage Report"
echo "                  $(date)"
echo "=========================================================="
echo ""

printf "%-30s %15s\n" "Shared Folder" "Size (GB)"
echo "----------------------------------------------------------"

for SHARE_NAME in $SHARE_LIST; do
    SHARE_PATH="$SHARED_FOLDER_BASE/$SHARE_NAME"
    # Check if it's a directory and does not start with '@'
    if [ -d "$SHARE_PATH" ] && [[ "$SHARE_NAME" != @* ]]; then
        # Exclude system shares or specific folders if necessary
        if [[ "$SHARE_NAME" == "#recycle" ]]; then
            continue
        fi
        # Get size in bytes, excluding snapshots and recycle bins
        SIZE_BYTES=$($DU_CMD -s -B1 --exclude="$SHARE_PATH/@eaDir" \
                                      --exclude="$SHARE_PATH/@Recycle" \
                                      --exclude="$SHARE_PATH/@ShareBin" \
                                      --exclude="$SHARE_PATH/@SynoResource" \
                                      --exclude="$SHARE_PATH/.snapshot" \
                                      --exclude="$SHARE_PATH/#recycle" \
                                      --one-file-system "$SHARE_PATH" 2>/dev/null | $AWK_CMD '{print $1}')
        if [ -n "$SIZE_BYTES" ]; then
            # Convert bytes to GB
            SIZE_GB=$($AWK_CMD -v bytes="$SIZE_BYTES" 'BEGIN {printf "%.2f", bytes/1024/1024/1024}')
            printf "%-30s %15s\n" "$SHARE_NAME" "$SIZE_GB"
            TOTAL_USAGE=$($AWK_CMD -v total="$TOTAL_USAGE" -v size="$SIZE_GB" 'BEGIN {printf "%.2f", total + size}')
        else
            echo "Warning: Could not determine size for $SHARE_NAME"
        fi
    fi
done

echo "----------------------------------------------------------"
printf "%-30s %15.2f GB\n" "Total Usage:" "$TOTAL_USAGE"
echo ""

# System Stats
echo "=========================================================="
echo "                   System Statistics"
echo "=========================================================="
echo ""

# Uptime
echo "System Uptime:"
echo "--------------"
$UPTIME_CMD
echo ""

# Memory Usage
echo "Memory Usage:"
echo "-------------"
$FREE_CMD -h
echo ""

# CPU Load Average
echo "CPU Load Average:"
echo "-----------------"
$UPTIME_CMD | $AWK_CMD -F'load average:' '{ print $2 }'
echo ""

# Top 5 Processes by CPU Usage
echo "Top 5 Processes by CPU Usage:"
echo "-----------------------------"
$TOP_CMD -b -n1 | head -n17 | tail -n15
echo ""

# Volume Usage
echo "Volume Usage:"
echo "-------------"
$DF_CMD -hT | $AWK_CMD 'NR==1 || /^\/dev/ {printf "%-15s %-8s %-10s %-10s %-6s %-15s\n", $1, $2, $3, $4, $6, $7}'
echo ""

# Disk Usage Percentage
echo "Disk Usage Percentage:"
echo "----------------------"
$DF_CMD -h --output=source,pcent,target | $AWK_CMD 'NR==1 || /^\/dev/ {printf "%-15s %-8s %-15s\n", $1, $2, $3}'
echo ""

echo "=========================================================="

# Exit successfully
exit 0

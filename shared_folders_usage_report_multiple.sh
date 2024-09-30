#!/bin/bash
#==================================================================================
# Script Name: shared_folders_usage_report_multiple.sh
# Version: 2.1
# Author: Andy Saputra
# License: MIT License
# Link: https://github.com/ajsap/synology_shared_folders_usage_report/
# Description: Calculates shared folder sizes across multiple volumes and generates
#              a usage report with detailed system statistics.
#
# Background: The original version of the “Shared Folders Usage Report” script was
# crafted to provide a detailed overview of shared folder usage within a single
# volume. Recognising the need for a more comprehensive tool that accommodates
# the complexities of modern storage environments, this enhanced version extends
# the functionality to support multiple storage volumes. This advancement is
# particularly valuable for administrators managing larger data arrays across
# various storage units within their Synology NAS systems or similar setups.
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
SED_CMD="/bin/sed"
TR_CMD="/usr/bin/tr"
SORT_CMD="/usr/bin/sort"

# Ensure commands exist
for cmd in "$DU_CMD" "$AWK_CMD" "$DF_CMD" "$UPTIME_CMD" "$FREE_CMD" "$TOP_CMD" "$LS_CMD" "$SED_CMD" "$TR_CMD" "$SORT_CMD"; do
    if ! [ -x "$cmd" ]; then
        echo "Error: Command not found or not executable: $cmd"
        exit 1
    fi
done

# Shared folder base paths (add or remove volumes as needed)
SHARED_FOLDER_BASE=(
/volume1
/volume2
/volume5
)

# Initialize total usage
TOTAL_USAGE=0

# Start the report
echo "=========================================================="
echo "           Synology Shared Folders Usage Report"
echo "                  $(date)"
echo "=========================================================="
echo ""

# Loop through each volume
for VOLUME in "${SHARED_FOLDER_BASE[@]}"; do
    # Check if the volume exists
    if [ -d "$VOLUME" ]; then
        # Get list of shared folders in the volume
        SHARE_LIST=$($LS_CMD -1 "$VOLUME")

        # Initialize subtotal for the volume
        SUBTOTAL=0

        # Print header for the volume
        VOLUME_NAME=$(basename "$VOLUME")
        printf "Shared Folders in %s\n" "$VOLUME_NAME"
        printf "%-30s %15s\n" "------------------------------" "---------------"
        printf "%-30s %15s\n" "Shared Folder" "Size (GB)"
        printf "%-30s %15s\n" "------------------------------" "---------------"

        for SHARE_NAME in $SHARE_LIST; do
            SHARE_PATH="$VOLUME/$SHARE_NAME"
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
                    SUBTOTAL=$($AWK_CMD -v total="$SUBTOTAL" -v size="$SIZE_GB" 'BEGIN {printf "%.2f", total + size}')
                else
                    echo "Warning: Could not determine size for $SHARE_NAME"
                fi
            fi
        done

        # Print subtotal for the volume
        printf "========== Subtotal for %s: %s GB\n\n" "$VOLUME_NAME" "$SUBTOTAL"

        # Add subtotal to total usage
        TOTAL_USAGE=$($AWK_CMD -v total="$TOTAL_USAGE" -v subtotal="$SUBTOTAL" 'BEGIN {printf "%.2f", total + subtotal}')
    else
        echo "Warning: Volume $VOLUME does not exist."
    fi
done

# Print total usage
echo "----------------------------------------------------------"
printf "%-30s %15.2f GB\n" "Total Usage:" "$TOTAL_USAGE"
echo ""

# System Stats
echo "=========================================================="
echo "                   System Statistics"
echo "=========================================================="
echo ""

# System Uptime
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
$UPTIME_CMD | $AWK_CMD -F'load average:' '{ print $2 }' | $SED_CMD 's/^ //'
echo ""

# Top 15 Processes by CPU Usage
echo "Top 15 Processes by CPU Usage:"
echo "------------------------------"
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

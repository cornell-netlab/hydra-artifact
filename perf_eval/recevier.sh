#/bin/bash
# Receiver iperf3 command
#
# Both sender and receiver interface MTU setting should be 9000.
# 
#
# Example: 
#   - File name that has the iperf3 receiver logs: after.txt
#   - Final command: bash receiver.sh after.txt

export FNAME=$1;

iperf3 -s -f kbps -J --logfile $FNAME

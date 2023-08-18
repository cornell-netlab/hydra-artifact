#/bin/bash
# Sender iperf3 and ping command
# 
# Both sender and receiver interface MTU setting should be 9000.
#
# Example: 
#   - receiver IP: 10.0.0.1
#   - Run each test for: 60 seconds
#   - Number of times to run tests: 10
#   - Name of ping file: allcheck60
#   - Final command: bash sender.sh 10.0.0.1 60 10 allcheck60

export TARGET=$1;
export DUR=$2; 
export NUM=$3; 
export NAME=$4;
PINGCOUNT=`expr 5 \* $DUR`

for N in `seq 1 $NUM`; 
do  
    # iperf3 tests
    iperf3 -u -b 0 -P 3 -c $TARGET -t $DUR & 

    # ping tests
    ping -i 0.2 $TARGET -c $PINGCOUNT > ${NAME}_${N}.txt

    # cool down
    sleep 15
done

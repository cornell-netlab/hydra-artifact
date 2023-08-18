# Hydra Performance Evaluation Scripts

This repo contains the necessary code and instructions to run the evaluation and plot graphs using the results.

Note: Running performance evaluation in software emulation does not reflect the reality.

## Run evaluation 
1. Connect two servers (Sender and receiver) through a programmable switch that can host the Hydra program. 
2. In each server, install iperf3: 
  - `sudo apt update`
  - `sudo apt install iperf3`
3. On the receiver machine, run the iperf3 server: `bash receiver.sh <output filename>`
  - Example: `bash receiver before.txt`
4. Make sure to run the right Hydra program on the programmable switch and enable forwarding between two servers. First, load the Hydra programs with no checks enabled.
5. On the sender machine, run iperf3 as background traffic and run fast pings with the following command: `bash sender.sh <receiver IP> <test seconds of each run> <number of times to run test> <name of output file>`
  - Example: Receiver IP: 10.0.0.1. Run each test for 60 seconds, and run 10 tests. The name of the file with ping results is allcheck60.
  - `bash sender.sh 10.0.0.1 60 10 base60`
6. Repeat the step above with a Hydra program with all checks enabled.
  - `bash sender.sh 10.0.0.1 60 10 allcheck60`

## Plot results 
1. Collect ping result files in the servern and put all ping result files in one directory. Assume this directory name is `./input`
2. You will need matplotlib installed
  - `sudo apt-get install python3-matplotlib`
4. Run plot command: `python ping_plotting -i ./input`
  - The script assumes your file names with `base60_*` and `allcheck60_*`. Change script accordingly.
3. Plot explanation:
  - `out_rtt.png`: CDF of RTT before and after all checks are enabled.
  - `out_rtt_time.png`: RTT along a time, for both before and after all checks are enabled.
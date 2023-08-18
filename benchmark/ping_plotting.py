#################################################
# Script for plotting ping results
#
# SIGCOMM 2023 Hydra Artifact 
#################################################

import os
import argparse, pickle
import plot_lib
import sys
import pickle
import numpy as np


SECONDS = 300

def plot_the_data(the_map, output_dir, saveAsFileName, plot_title):


    xa = []
    ymap = {}
    
    #### Do your stuff
    for idx,m in enumerate(the_map):
        print(m)
        y_data = []
        xa = []
        for idx2,i in enumerate(the_map[m]):
            xa.append(idx2)
            y_data.append(i)
        ymap[idx] = y_data

    plot_lib.plot_multiline(xa, ymap, output_dir, saveAsFileName, plot_title, 'Minutes', 'RTT (ms)', ['Baseline', 'All Checkers'])

    return   


def read_pings_cdf(input_dir):

    rtt_base_list = []
    rtt_all_list =  [] 

    for p in range(10,11):
        # open base
        lines_list =  []
        with open(input_dir + 'base60_' + str(p) + '.txt', 'r') as fd:
#        with open(input_dir + 'base1805_light1_2.txt', 'r') as fd:
            lines_list = fd.readlines()
        idx = 0
        for l in lines_list:
            if l.startswith('64 bytes from '):
                piece_list = l.split(' ')
                rtt = piece_list[6].split('=')[1]
                rtt_base_list.append(float(rtt))
                idx+=1

        # open base
        lines_list =  []
        with open(input_dir + 'allcheck60_' + str(p) + '.txt', 'r') as fd:
#        with open(input_dir + 'rr1805_light1_2.txt', 'r') as fd:
            lines_list = fd.readlines()
        idx = 0
        for l in lines_list:
            if l.startswith('64 bytes from '):
                piece_list = l.split(' ')
                rtt = piece_list[6].split('=')[1]
                rtt_all_list.append(float(rtt))
                idx+=1

    xtna, ytna = plot_lib.get_cdf2(rtt_base_list)
    xrr, yrr = plot_lib.get_cdf2(rtt_all_list)

    data = {}
    data[0] = rtt_base_list
    data[1] = rtt_all_list

    plot_lib.plot_multiline_inde(xtna, ytna, xrr, yrr, "./", "out_rtt.png", '', 'RTT (ms)', 'CDF', ["Baseline","All Checkers"])

    return data

    
def main():
    parser = argparse.ArgumentParser(description='Script for plotting ping data')
    parser.add_argument('-i', dest='input_dir', action='store', required=True,
                        help='input_dir')

    # Parse
    args = parser.parse_args()

    # Check number of arguments. 
    if len(sys.argv[1:])<1:
        print ("\nERROR: Wrong number of parameters. \n")
        parser.print_help()
        sys.exit(0)

    input_dir =  args.input_dir
    if not input_dir.endswith('/'):
        input_dir =  input_dir + '/'

    # open directory, read data
    data = read_pings_cdf(input_dir)

    # Plot
    saveAsFileName = 'out_rtt_time.png'  # Add file extension yourself.
    plot_title = ''
    plot_the_data(data, './', saveAsFileName, plot_title)


######        
if __name__ == '__main__':
    main()

#################################################
# Methods for matplotlib
#
# SIGCOMM 2023 Hydra Artifact 
#################################################

import operator
import string
import pickle
import sys
import re
import time
import os
import sqlite3 as db
import shlex, subprocess
import hashlib
import xml.etree.ElementTree as ET
from multiprocessing import Process
from multiprocessing import Pool
from collections import namedtuple
from datetime import datetime
import tarfile
import matplotlib as mpl
#mpl.use('PS')
mpl.use('pdf')
#mpl.use('AGG')
import matplotlib.pyplot as plt
from matplotlib.ticker import MultipleLocator
from numpy.random import normal
import numpy as np
from matplotlib.patches import ConnectionPatch
import struct
from socket import *


#mpl.rc('text', usetex=True)
mpl.rc('font', **{'family':'serif', 'sans-serif': ['Times'], 'size': 9})
#mpl.rc('figure', figsize=(5.33, 2.06))
#mpl.rc('figure', figsize=(4.33, 2.06))
mpl.rc('figure', figsize=(4.33, 2.06))
#mpl.rc('figure', figsize=(3.33, 2.06))
mpl.rc('axes', linewidth=0.5)
mpl.rc('patch', linewidth=0.5)
mpl.rc('lines', linewidth=0.5)
mpl.rc('grid', linewidth=0.25)


def plot_multiline_inde(x1, y1, x2, y2, output_dir, filename, title_text, xlabel_text, ylabel_text, legend_list):

    fig = plt.figure(dpi=700)
    ax = fig.add_subplot(111)
    colors = ['r-','k-','g-','c-','r-']
    pl = []
    ax.yaxis.grid(True, which='major')
  
    pl.append( plt.plot(x1, y1, colors[0], label="") )
    pl.append( plt.plot(x2, y2, colors[2], label="") )
 
    ff = plt.gcf()
    ff.subplots_adjust(bottom=0.20)
    ff.subplots_adjust(left=0.15)
    plt.title(title_text)
    plt.xlabel(xlabel_text)
    plt.ylabel(ylabel_text, rotation=90)
  
    plot_list = []
    for idx,legend in enumerate(legend_list):
        plot_list.append(pl[idx][0])

    l = plt.legend(plot_list, legend_list, bbox_to_anchor=(0.5, 0.25), loc='center',ncol=1, fancybox=True, shadow=False, prop={'size':7})    
    plt.savefig(output_dir + str(filename), dpi=700)


def plot_multiline(x_ax, y_map, output_dir, filename, title_text, xlabel_text, ylabel_text, legend_list):

    fig = plt.figure(dpi=700)
    ax = fig.add_subplot(111)
    colors = ['r-','k-','g-','c-','r-']
    pl = []
    ax.yaxis.grid(True, which='major')
  
    xlabels = ['0', '5', '10', '15', '20', '25', '30']
    majorind = np.arange(len(x_ax),step=300)
    ind_x = range(len(x_ax))
  
    plt.xticks(majorind, xlabels)
  
    for idx,y in enumerate(y_map):
        y_ax = y_map[y]
        # y_ax = y
        cidx = idx%len(colors)
        pl.append( plt.plot(ind_x, y_ax, '%s' %(colors[cidx]), label="") )
  
    ff = plt.gcf()
    ff.subplots_adjust(bottom=0.20)
    ff.subplots_adjust(left=0.15)
    plt.title(title_text)
    plt.xlabel(xlabel_text)
    plt.ylabel(ylabel_text, rotation=90)
  
    plot_list = []
    for idx,legend in enumerate(legend_list):
        plot_list.append(pl[idx][0])

    l = plt.legend(plot_list, legend_list, bbox_to_anchor=(0.5, 0.25), loc='center',ncol=2, fancybox=True, shadow=False, prop={'size':7})    
    plt.savefig(output_dir + str(filename), dpi=700)


def get_cdf2(arr):
  '''
      Fn to get CDF of an array
      Input: unsorted array with values
      Output: 2 arrays - x and y axes values
  '''
  sarr = np.sort(arr)
  l = len(sarr)
  x = []
  y = []
  for i in range(0,l):
    x.append(sarr[i])
    y.append((float(i+1)/l)*1)

  return x,y

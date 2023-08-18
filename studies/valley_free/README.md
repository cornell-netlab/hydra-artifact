# Valley Free Source Routing

This directory contains the necesarry code to run the valley free source routing example from the paper. The first step is to install the necesary p4 tools and mininet. Then, compile the Indus program and link it with the source routing forwarding program. Finally, run the example in mininet and experiment with different source routes. 

### Install P4 tools
```bash
git clone https://github.com/jafingerhut/p4-guide
./p4-guide/bin/install-p4dev-v5.sh |& tee log.txt
```
This installs the `p4c` compiler, `bmv2`, and `mininet`.

## Compiling and Linking the valley-free Indus Program with P4 source routing

Compile the valley-free Indus program from the `hydra/examples`` directory with the basic_topology.json file from the topologies directory. This topology contains a single leaf switch for the purpose of this demo (mininet will install the same program to all switches).
```bash
dune exec -- tpc valley-free.tpc ../../examples/basic_topology.json
```

### Linking with the source routing program 

add these two lines to the top of the P4 program output in the generated_p4 directory. This adds forwarding specific code to the generated monitoring p4 program.
```OCaml
#include <v1model.p4> 
#define ETHERTYPE_CHECKER 0x5678;
```

copy the file to the p4_tutorials directory where the source routing example lives in `exercises/valley_free/hydra`

## Running the source routing example in mininet

run `make` to run mininet and start the example with the following topology

![pod-topo](./p4_tutorials/exercises/basic/pod-topo/pod-topo.png)

You can run commands in mininet either by getting a terminal for each host (e.g. `xterm h1 h4`) or within the mininet console pre-pending the name of the host to the command (e.g. `h1 python3 receive.py`).

On host 4 (h4) run `python3 receive.py`

On host 1 (h1) run `python3 send.py 10.0.4.4`

This will prompt you to enter a list of egress ports that the forwarding P4 program uses to route the packet. All valley-free paths will make it to h4 and all other paths will be dropped. 


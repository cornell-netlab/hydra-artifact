# hydra-artifact

This repository contains the artifact for the SIGCOMM '23 paper "[Hydra: Practical Runtime Network Verification](https://www.cs.cornell.edu/~jnfoster/papers/hydra.pdf)".

For the most up-to-date version of the artifact, please visit [https://github.com/cornell-netlab/hydra-artifact](https://github.com/cornell-netlab/hydra-artifact).

# Organization

The codebase is organized into several sub-directories as follows:

* `indus/`: OCaml source code for the Indus compiler (Section 4)
* `studies/`: Data and scripts for the case studies  (Section 5)
* `examples/`: Indus source code for the example programs (Section 6.1)
* `benchmark/` Source code, data, and scripts for the performance benchmarks (Section 6.2)

Each sub-directory has its own `README.md` file with further instructions. 

We recommend exploring the codebase in the following order:
1. Build the Indus compiler (in `indus/`)
1. Run the "valley free" routing case study (in `studies/valley_free/`)
1. Compile the example programs (in `examples/`)
1. Explore the Aether case study (in `studies/aether`)
1. Explore the performance benchmarks (in `benchmarks`)

# Status

Note that this artifact is still being updated. We are making the source code available now, but some functionality is being updated from our private development. In addition, we plan to provide more detailed instructions for the case studies and benchmarks, some of which rely on proprietary hardware and data.

# Contact

Please contact us if you have any questions, either anonymously on HotCRP or by email as appropriate:
* Sundararajan Renganathan (rsundar@stanford.edu)
* Benny Rubin (bcr57@cornell.edu)
* Hyojoon Kim (hyojoonkim@virginia.edu)
* Nate Foster (jnfoster@cs.cornell.edu)


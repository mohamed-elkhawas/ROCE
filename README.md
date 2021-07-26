# RDMA Over Converged Ethernet




## Tech

Our project implements remote direct memory access over converged Ethernet. Our project proposes a methodology to support speedy data transmission between hosts enabling them to directly access the memory as input/output operations without CPU interference through DMA directly. Hence, minimizing latency and maximizing the processing speed. RDMA allows direct access of memory of one computer into the other’s memory without involving any OS. This is very useful nowadays in the distributed systems where individual computers are connected together and are communicating together easily to facilitate efficient data transfer and parallel processing and resource sharing to appear as one integrated system.

Our project supports RoCE V.2 protocol for RDMA implementation. This is an internet protocol which allows accessing memory between different hosts within multiple domains through gateways over an Ethernet network while providing congestion control mechanisms to deal with traffic congestions.

Our project aims at implementing an efficient programmable memory controller inside a PCIe endpoint connected to our host system. The controller will access the external shareable DDR5 DRAM of the endpoint and handle all incoming memory requests from other hosts there while offloading the host system memory. This approach helps in minimizing the latency gap difference between local and remote memory access. CPU power is used to perform other system operations requiring high processing in parallel to handled memory operations by the controller. Our implementation code and all simulation and emulation results are ellaborated on in deatils in our document.







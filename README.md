# SystemVerilog description of AMBA 

> Complete AMBA architecture and testbench in SystemVerilog - AHB side modules and AHB-APB bridge will be uploaded soon  

## Get Started

The source files for the APB side of the architecture:

- [APB_Master](./APB_Master.sv)
- [APB_Slave](./APB_Slave.sv)
- [APB Interconnect Fabric](./interconnect_fabric.sv)
- [APB_DUT](./APB_DUT.sv)
- [APB_TB](./APB_TB.sv)
- [wave](./wave.sv)

The source files for the AHB side of the architecture:

- XXX
- XXX

The source files for the AHB-APB bridge:

- XXX
- XXX

It is recomended to go over the various modules in the following order:
1. APB-side
2. AHB-side
3. AHB-APB bridge
4. Complete architecture
The following sections are written in this order.

## APB side 
A block diagram of the complete architecture is as follows:
	![APB_arch](./docs/APB_arch.jpg) 
A block diagram of the APB side interconnect fabric is as follows:
	![IF_APB](./docs/IF_APB.jpg) 

## Testbench

The testbench comprises three tests for a 32 8-bit word FIFO memory: continious writing (left), continious reading (middle) random read/write operation (right):

**Synchronous FIFO memory TB:**
	![Synchronous FIFO memory TB](./docs/synchronous_read_write_mix.JPG) 


1.	Continious writing of random data to the FIFO memory

	**Continious writing operation (waveform):**
		![Continious writing operation](./docs/synchronous_write.JPG) 

	As can be seen, the FIFO_full signal rises to logic high when 32 consecutive write operations are executed and the memory is full. 
	Please note that the 'FIFO_full_tst_final' mimicks the 'FIFO_full' signal.

	**Continious writing operation (terminal view):**
		![QuestaSim wave window](./docs/synchronous_write_terminal.JPG)  
	
	As can be seen in the terminal view of the first iterations, the mimicked FIFO memory matches the actual FIFO memory ('verification queue')	

### Possible Applications

Implementation of the synchronous FIFO memory in a complete UART module can be found in the [following repository](https://github.com/tom-urkin/UART)

## Support

I will be happy to answer any questions.  
Approach me here using GitHub Issues or at tom.urkin@gmail.com
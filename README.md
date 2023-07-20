# SystemVerilog description of AMBA 

> Complete SystemVerilog AMBA architecture and testbench - AHB side modules and AHB-APB bridge will be uploaded soon  

## Get Started

The source files for the APB side of the architecture:

- [APB_Master](./APB_Master.sv)
- [APB_Slave](./APB_Slave.sv)
- [APB Interconnect Fabric](./interconnect_fabric.sv)
- [APB_DUT](./APB_DUT.sv)
- [APB_TB](./APB_TB.sv)
- [wave](./wave.sv)

Choosing between Synchronous or Asynchronous implementation is carried out by modifying the 'TYPE' parameter in the module instantiation:
- Synchronous: TYPE=0
- Asynchronous: TYPE=1

To simulate the synchronous/asynchronous simply change the 'TYPE' parameter in the [FIFO_TB](./FIFO_TB.sv) file.
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

2.	Continious reading operation from the FIFO memory  
	
	**Continious reading operation (waveform):**
		![QuestaSim terminal window](./docs/synchronous_read.JPG) 

	As can be seen, the read values ('data_out') matches the written values of the previous test.

	**Continious writing operation (terminal):**
		![QuestaSim wave window](./docs/synchronous_read_terminal.JPG)  

	Here, a section of the terminal output is shown to illustrate the actual values stored in the mimiced and the actual FIFO_memory
	
3.	Random read/write operation 

	In the third test, a read/write command is randomly applied (the distribuition can be modified from the TB).

	**Random read/write operation with equal probabiities (waveform):**
		![Random read/write operation](./docs/synchronous_random.JPG) 
		
	As can be seem, the FIFO_empty condition is reached - this is since the FIFO is empty upon test initiation.
	
	**Random read/write operation with equal probabiities (terminal):**
		![Random read/write operation](./docs/synchronous_random_terminal.JPG) 

	As can be seen, a 'write' operation is carried in iteration 542 and a 'read' iteration is carried in the following iteration.
	The comparison between the actual FIFO memory and the mimicked FIFO memory is carried at each iteration.
	
	In the last iteration, the entire FIFO memory is printed alongside its relevant section (between 'read' and 'write' pointers).
	In addition, the final mimicked FIFO memory is printed as well to allow visual comparison.
	
	**Random read/write operation with unequal probabiities (write operation is carried 75% of the time)(waveform):**
		![Random read/write operation](./docs/synchronous_random_unequal_dist.JPG)
	
	As can be seem, the FIFO_full condition is reached in the majority of the iterations in accordance with the 'write' probabiity used (75%).
	
	**Random read/write operation with unequal probabiities (terminal):**
		![Random read/write operation](./docs/synchronous_random_unequal_dist_terminal.JPG)	
	
	In the last iteration, the entire FIFO memory is printed alongside its relevant section (between 'read' and 'write' pointers).
	In addition, the final mimicked FIFO memory is printed as well to allow visual comparison.	

**Asynchronous FIFO memory TB:**
The testbench comprises three tests for a 32 8-bit word FIFO memory: continious writing (left), continious reading (middle) random read/write operation (right):

![Aynchronous FIFO memory TB](./docs/asynchronous_read_write_mix.JPG) 

1.	Continious writing of random data to the FIFO memory

	**Continious writing operation (waveform):**
		![Continious writing operation](./docs/asynchronous_write.JPG) 

	As can be seen, the FIFO_full signal rises to logic high when 32 consecutive write operations are executed and the memory is full. 
	Please note that the 'FIFO_full_tst_final' mimicks the 'FIFO_full' signal and takes into consideration the synchronization logic between the read-write domains.

	**Continious writing operation (terminal view):**
		![QuestaSim wave window](./docs/asynchronous_write_terminal.JPG)  
	
	As can be seen in the terminal view of the first iterations, the mimicked FIFO memory matches the actual FIFO memory ('verification queue')	

2.	Continious reading operation from the FIFO memory  
	
	**Continious reading operation (waveform):**
		![QuestaSim terminal window](./docs/asynchronous_read.JPG) 

	As can be seen, the read values ('data_out') matches the written values of the previous test.

	**Continious writing operation (terminal):**
		![QuestaSim wave window](./docs/asynchronous_read_terminal.JPG)  

	Here, a section of the terminal output is shown to illustrate the actual values stored in the mimiced and the actual FIFO_memory as well as the 'FIFO_empty' condition verification.

3.	Random read/write operation 

	In the third test, a read/write command is randomly applied as done for the synchronous FIFO memory verification (the distribuition can be modified from the TB).

	**Random read/write operation with equal probabiities (waveform):**
		![Random read/write operation](./docs/asynchronous_random.JPG) 
		
	As can be seem, the FIFO_empty condition is reached - this is since the FIFO is empty upon test initiation.
	
	**Random read/write operation with equal probabiities (terminal):**
		![Random read/write operation](./docs/asynchronous_random_terminal.JPG) 

	In the last iteration, the entire FIFO memory is printed alongside its relevant section (between 'read' and 'write' pointers).
	In addition, the final mimicked FIFO memory is printed as well to allow visual comparison.
	
**Asynchronous FIFO memory TB with different clock frequencies for the read/write domains:**

A read/write command is randomly applied as done for the synchronous FIFO memory verification (the distribuition can be modified from the TB).

**Random read/write operation with equal probabiities (waveform):**
	![Random read/write operation](./docs/asynchronous_random_differen_clocks.JPG) 	
	
**Random read/write operation with equal probabiities (terminal):**
	![Random read/write operation](./docs/asynchronous_random_differen_clocks_terminal.JPG) 

### Possible Applications

Implementation of the synchronous FIFO memory in a complete UART module can be found in the [following repository](https://github.com/tom-urkin/UART)

## Support

I will be happy to answer any questions.  
Approach me here using GitHub Issues or at tom.urkin@gmail.com
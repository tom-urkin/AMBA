`timescale 1ns/100ps
//Multi-master, single slave APB system

module APB_TB();

//Parameter declarations
parameter CLK_PERIOD=20;                                         //Clock period

parameter DATA_WIDTH = 32;                                       //Data bus width
parameter ADDR_WIDTH = 32;                                       //Address bus width
parameter REG_NUM = 5;                                           //Address span within a given slave equals 2**REG_NUM [REG_NUM-1:0]
parameter MASTER_COUNT = 3;                                      //Maximum allowed number of masters
parameter SLAVE_COUNT=3;                                         //Number of slaves on the bus

localparam WORD_LEN = $clog2(DATA_WIDTH>>3);                     //Number of bits requried to specify a given byte within a word. Example: for 32-bit word 2 bits are needed for byte0-byte3. These are the LSBs of the address which are zeros in normal operation (access is word-based)
localparam ADDR_MSB_len = ADDR_WIDTH-WORD_LEN-REG_NUM;           //Part of the address bus used to select a slave unit. Address span for the salves equals 2**ADDR_MSB_len-1 

parameter [ADDR_MSB_len-1:0] ADDR_SLAVE_0 = 0;                   //Address of slave_0
parameter [ADDR_MSB_len-1:0] ADDR_SLAVE_1= 1;                    //Address of slave_1
parameter [ADDR_MSB_len-1:0] ADDR_SLAVE_2= 2;                    //Address of slave_2

//Internal signals declarations
logic clk;                                                       //System's clock
logic rstn;                                                      //Active high logic  

logic start_0;                                                   //Read/Write transer is initiated if the 'start' signal is logic high upon positive edge of clk
logic rw_0;                                                      //Dictates transfer direction. '1' for Master-->Slave (write) and '0' for Slave-->Master (read)
logic [DATA_WIDTH-1:0] data_rand_0;                              //Randomized data to be written by a Master to a Slave
logic [REG_NUM-1:0] addr_rand_0;                                 //addr_rand selects one of the registers in of a slave unit. There are 2**REG_NUM registers in each slave. 
logic [ADDR_MSB_len-1:0] slave_rand_0;                           //slave_rand selects one of the available slaves

logic start_1;                                                   //Read/Write transer is initiated if the 'start' signal is logic high upon positive edge of clk
logic rw_1;                                                      //Dictates transfer direction. '1' for Master-->Slave (write) and '0' for Slave-->Master (read)
logic [DATA_WIDTH-1:0] data_rand_1;                              //Randomized data to be written by a Master to a Slave
logic [REG_NUM-1:0] addr_rand_1;                                 //addr_rand selects one of the registers in of a slave unit. There are 2**REG_NUM registers in each slave. 
logic [ADDR_MSB_len-1:0] slave_rand_1;                           //slave_rand selects one of the available slaves


logic start_2;                                                   //Read/Write transer is initiated if the 'start' signal is logic high upon positive edge of clk
logic rw_2;                                                      //Dictates transfer direction. '1' for Master-->Slave (write) and '0' for Slave-->Master (read)
logic [DATA_WIDTH-1:0] data_rand_2;                              //Randomized data to be written by a Master to a Slave
logic [REG_NUM-1:0] addr_rand_2;                                 //addr_rand selects one of the registers in of a slave unit. There are 2**REG_NUM registers in each slave. 
logic [ADDR_MSB_len-1:0] slave_rand_2;                           //slave_rand selects one of the available slaves

integer SEED=198;                                                    //Used for randomization of i_Data_in

logic [DATA_WIDTH-1:0] o_data_out_m0;                            //Received data from one of the slaves as sampled by master #0 following a valid read command
logic transfer_status_m0;                                        //Communication status of master #0. '1' if transfer failed, '0' otherwise
logic valid_m0;                                                  //Indicates the validity of the output data. logic high for 'valid' data
logic ready_m0;                                                  //Indicates weather master #0 is busy (logic high) or free (logic low)

logic [DATA_WIDTH-1:0] o_data_out_m1;                            //Received data from one of the slaves as sampled by master #0 following a valid read command
logic transfer_status_m1;                                        //Communication status of master #0. '1' if transfer failed, '0' otherwise
logic valid_m1;                                                  //Indicates the validity of the output data. logic high for 'valid' data
logic ready_m1;                                                  //Indicates weather master #0 is busy (logic high) or free (logic low)

logic [DATA_WIDTH-1:0] o_data_out_m2;                            //Received data from one of the slaves as sampled by master #0 following a valid read command
logic transfer_status_m2;                                        //Communication status of master #0. '1' if transfer failed, '0' otherwise
logic valid_m2;                                                  //Indicates the validity of the output data. logic high for 'valid' data
logic ready_m2;                                                  //Indicates weather master #0 is busy (logic high) or free (logic low)

logic [MASTER_COUNT-1:0] gnt;                                    //grants access to the bus according to the arbitration process

logic [ADDR_WIDTH-1:0][DATA_WIDTH-1:0] mimic_mem_0;             //Mimicks slave #0                                    
logic [ADDR_WIDTH-1:0][DATA_WIDTH-1:0] mimic_mem_1;             //Mimicks slave #1                                  
logic [ADDR_WIDTH-1:0][DATA_WIDTH-1:0] mimic_mem_2;             //Mimicks slave #2                                    

logic ready;                                                     //The bus is free to initiate a new transfer if all masters are free
logic valid;                                                     //Rises to logic high after a read operation carried by any of the masters
logic transfer_status;                                           //Rises to logic high in case of a transfer failure

//Task declerations 

//Initiate transfer task randomized the number of requesting masters and the required operation, i.e. read/write, as well as the data to be written and the slave addresses
task initiate_transfer(input int n);
  @(posedge clk) 
  
  if (!ready)
     $display("\ Bus is not free - write command could not be issued on iteration #%d", n); 
  else begin
  
    {start_2,start_1,start_0}=$dist_uniform(SEED,1,7);               //Radomizing the initiating masters
	{rw_2,rw_1,rw_0}=$dist_uniform(SEED,1,7);                        //Randomizing the operation, i.e. read/write
    
    
	if (start_0) begin
	  if (rw_0)
        data_rand_0= $dist_uniform(SEED,10000,100000);               //32-bit random number to be written to the slave
      addr_rand_0= $dist_uniform(SEED,0,2**REG_NUM-1);               //Selecting a register to communicate with
      slave_rand_0= $dist_uniform(SEED,0,SLAVE_COUNT-1);             //Selecting the slave to be accessed	  
	end
	
	if (start_1) begin
	  if (rw_1)
	    data_rand_1= $dist_uniform(SEED,10000,100000);               //32-bit random number to be written to the slave
      addr_rand_1= $dist_uniform(SEED,0,2**REG_NUM-1);               //Selecting a register to communicate with
      slave_rand_1= $dist_uniform(SEED,0,SLAVE_COUNT-1);             //Selecting the slave to be accessed  
    end
	
	if (start_2) begin
	  if (rw_2)
	    data_rand_2= $dist_uniform(SEED,10000,100000);               //32-bit random number to be written to the slave
      addr_rand_2= $dist_uniform(SEED,0,2**REG_NUM-1);               //Selecting a register to communicate with 
      slave_rand_2= $dist_uniform(SEED,0,SLAVE_COUNT-1);             //Selecting the slave to be accessed	  
    end
	
    @(posedge clk) 
    {start_2,start_1,start_0}=3'b000;   
  end
endtask

//The compare task is called after a 'read' transfer. It verifies that the data stored in the mimicked memory matches the read value
task task_compare(input logic [MASTER_COUNT-1:0] gnt);   //UPDATE FOR 3 MIMICKED MEMORIES!!! [XXX]
@(negedge valid) begin
  case (gnt)
  3'b001:
    case (slave_rand_0)
	  ADDR_SLAVE_0:
    	if (o_data_out_m0!=mimic_mem_0[addr_rand_0])
            $display("\nData read by master number 0 from slave number 0 and register number %d is %h. Data stored on the mimic-memory number 0 is %h - TEST FAILED",addr_rand_0,o_data_out_m0, mimic_mem_0[addr_rand_0]); 
        else 
            $display("\nData read by master number 0 from slave number 0 and register number %d is %h. Data stored on the mimic-memory number 0 is %h - SUCCESS",addr_rand_0,o_data_out_m0, mimic_mem_0[addr_rand_0]); 

	  ADDR_SLAVE_1:
    	if (o_data_out_m0!=mimic_mem_1[addr_rand_0])
            $display("\nData read by master number 0 from slave number 1 and register number %d is %h. Data stored on the mimic-memory number 1 is %h - TEST FAILED",addr_rand_0,o_data_out_m0, mimic_mem_1[addr_rand_0]); 
        else 
            $display("\nData read by master number 0 from slave number 1 and register number %d is %h. Data stored on the mimic-memory number 1 is %h - SUCCESS",addr_rand_0,o_data_out_m0, mimic_mem_1[addr_rand_0]); 

	  ADDR_SLAVE_2:
    	if (o_data_out_m0!=mimic_mem_2[addr_rand_0])
            $display("\nData read by master number 0 from slave number 2 and register number %d is %h. Data stored on the mimic-memory number 2 is %h - TEST FAILED",addr_rand_0,o_data_out_m0, mimic_mem_2[addr_rand_0]); 
        else 
            $display("\nData read by master number 0 from slave number 2 and register number %d is %h. Data stored on the mimic-memory number 2 is %h - SUCCESS",addr_rand_0,o_data_out_m0, mimic_mem_2[addr_rand_0]); 
    endcase
   
  3'b010: 
    case(slave_rand_1)
      ADDR_SLAVE_0:
        if (o_data_out_m1!=mimic_mem_0[addr_rand_1])
          $display("\nData read by master number 1 from slave number 0 and register number %d is %h. Data stored on the mimic-memory number 0 is %h - TEST FAILED",addr_rand_1,o_data_out_m1, mimic_mem_0[addr_rand_1]); 
        else
          $display("\nData read by master number 1 from slave number 0 and register number %d is %h. Data stored on the mimic-memory number 0 is %h - SUCCESS",addr_rand_1,o_data_out_m1, mimic_mem_0[addr_rand_1]); 

      ADDR_SLAVE_1:
       if (o_data_out_m1!=mimic_mem_1[addr_rand_1])
          $display("\nData read by master number 1 from slave number 1 and register number %d is %h. Data stored on the mimic-memory number 1 is %h - TEST FAILED",addr_rand_1,o_data_out_m1, mimic_mem_1[addr_rand_1]); 
        else
          $display("\nData read by master number 1 from slave number 1 and register number %d is %h. Data stored on the mimic-memory number 1 is %h - SUCCESS",addr_rand_1,o_data_out_m1, mimic_mem_1[addr_rand_1]); 

      ADDR_SLAVE_2:
       if (o_data_out_m1!=mimic_mem_2[addr_rand_1])
          $display("\nData read by master number 1 from slave number 2 and register number %d is %h. Data stored on the mimic-memory number 2 is %h - TEST FAILED",addr_rand_1,o_data_out_m1, mimic_mem_2[addr_rand_1]); 
        else
          $display("\nData read by master number 1 from slave number 2 and register number %d is %h. Data stored on the mimic-memory number 2 is %h - SUCCESS",addr_rand_1,o_data_out_m1, mimic_mem_2[addr_rand_1]); 
    endcase

  3'b100: 
    case (slave_rand_2)	
    ADDR_SLAVE_0:
      if (o_data_out_m2!=mimic_mem_0[addr_rand_2])
        $display("\nData read by master number 2 from slave number 0 and register number %d is %h. Data stored on the mimic-memory number 0 is %h - TEST FAILED",addr_rand_2,o_data_out_m2, mimic_mem_0[addr_rand_2]); 
      else
        $display("\nData read by master number 2 from slave number 0 and register number %d is %h. Data stored on the mimic-memory number 0 is %h - SUCCESS",addr_rand_2,o_data_out_m2, mimic_mem_0[addr_rand_2]); 
  
    ADDR_SLAVE_1:
      if (o_data_out_m2!=mimic_mem_1[addr_rand_2])
        $display("\nData read by master number 2 from slave number 1 and register number %d is %h. Data stored on the mimic-memory number 1 is %h - TEST FAILED",addr_rand_2,o_data_out_m2, mimic_mem_1[addr_rand_2]); 
      else
        $display("\nData read by master number 2 from slave number 1 and register number %d is %h. Data stored on the mimic-memory number 1 is %h - SUCCESS",addr_rand_2,o_data_out_m2, mimic_mem_1[addr_rand_2]); 

    ADDR_SLAVE_2:
      if (o_data_out_m2!=mimic_mem_2[addr_rand_2])
        $display("\nData read by master number 2 from slave number 2 and register number %d is %h. Data stored on the mimic-memory number 2 is %h - TEST FAILED",addr_rand_2,o_data_out_m2, mimic_mem_2[addr_rand_2]); 
      else
        $display("\nData read by master number 2 from slave number 2 and register number %d is %h. Data stored on the mimic-memory number 2 is %h - SUCCESS",addr_rand_2,o_data_out_m2, mimic_mem_2[addr_rand_2]);      
    endcase
  
  endcase 
end
endtask



//DUT instantiation
APB_DUT #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(ADDR_WIDTH), .REG_NUM(REG_NUM), .MASTER_COUNT(MASTER_COUNT), .SLAVE_COUNT(SLAVE_COUNT), .ADDR_SLAVE_0(ADDR_SLAVE_0), .ADDR_SLAVE_1(ADDR_SLAVE_1), .ADDR_SLAVE_2(ADDR_SLAVE_2)) D0(.i_prstn(rstn),
      .i_pclk(clk),

      .i_start_0(start_0),
      .i_rw_0(rw_0),
      .i_data_in_0(data_rand_0),
      .i_addr_rand_0(addr_rand_0),
      .i_slave_rand_0(slave_rand_0),
      .o_data_out_m0(o_data_out_m0),
      .o_transfer_status_m0(transfer_status_m0),
      .o_valid_m0(valid_m0),
      .o_ready_m0(ready_m0),

      .i_start_1(start_1),
      .i_rw_1(rw_1),
      .i_data_in_1(data_rand_1),
      .i_addr_rand_1(addr_rand_1),
      .i_slave_rand_1(slave_rand_1),
      .o_data_out_m1(o_data_out_m1),
      .o_transfer_status_m1(transfer_status_m1),
      .o_valid_m1(valid_m1),
      .o_ready_m1(ready_m1),

      .i_start_2(start_2),
      .i_rw_2(rw_2),
      .i_data_in_2(data_rand_2),
      .i_addr_rand_2(addr_rand_2),
      .i_slave_rand_2(slave_rand_2),
      .o_data_out_m2(o_data_out_m2),
      .o_transfer_status_m2(transfer_status_m2),
      .o_valid_m2(valid_m2),
      .o_ready_m2(ready_m2),

      .o_gnt(gnt)
);


//Initial blocks
initial begin
rstn=1'b0;
clk=1'b0;

start_0=1'b0;
start_1=1'b0;
start_2=1'b0;

mimic_mem_0<='0;
mimic_mem_1<='0;
mimic_mem_2<='0;

#CLK_PERIOD
rstn=1'b1;


for (int i=0; i<400; i++) 
 begin
   #400
   initiate_transfer(i);  
 end

#1000
$display("\n -----------------------");
$display("\n ALL tests have passed - SUCCESS!");
end

//Clock generation
always
begin
#(CLK_PERIOD/2);
clk=~clk;
end


//HDL code
assign ready = ready_m0&ready_m1&ready_m2;                  
assign valid = valid_m0|valid_m1|valid_m2;                                            
assign transfer_status=transfer_status_m0|transfer_status_m1|transfer_status_m2;

always @(posedge clk) begin
  if (transfer_status==1'b1) begin
    $display("\ Communication error - TEST FAILED");                                  //Exit TB upon first failed transfer 
    $finish;
  end  
  
  if (gnt[0]&rw_0) begin
    if (slave_rand_0==ADDR_SLAVE_0)
      mimic_mem_0[addr_rand_0]=data_rand_0;
  else if (slave_rand_0==ADDR_SLAVE_1)
      mimic_mem_1[addr_rand_0]=data_rand_0;
  else
    mimic_mem_2[addr_rand_0]=data_rand_0;
  end  
  else if (gnt[0])
    task_compare(gnt);

  else if (gnt[1]&rw_1) begin	
    if (slave_rand_1==ADDR_SLAVE_0)
      mimic_mem_0[addr_rand_1]=data_rand_1;
  else if (slave_rand_1==ADDR_SLAVE_1)
      mimic_mem_1[addr_rand_1]=data_rand_1;
  else
    mimic_mem_2[addr_rand_1]=data_rand_1;  
  end
  else if (gnt[1])
     task_compare(gnt);

  else if (gnt[2]&rw_2) begin
    if (slave_rand_2==ADDR_SLAVE_0)
      mimic_mem_0[addr_rand_2]=data_rand_2;
  else if (slave_rand_2==ADDR_SLAVE_1)
      mimic_mem_1[addr_rand_2]=data_rand_2;
  else
    mimic_mem_2[addr_rand_2]=data_rand_2;
  end
  else if (gnt[2])
    task_compare(gnt);  
end

  
endmodule

`timescale 1ns/100ps
//AHB-lite TB. Please see documentation for further details and examplary results. 

module AHB_TB();

//Parameter declarations
parameter CLK_PERIOD=20;                                         //Clock period

parameter ADDR_WIDTH=32;                                         //Address bus width
parameter DATA_WIDTH=32;                                         //Data bus width
parameter MEMORY_DEPTH=1024;                                     //Slave memory 
parameter SLAVE_COUNT=3;                                         //Number of connected AHB slaves

parameter WAIT_WRITE=1;                                          //Number of wait cycles issued by the slave in response to a 'write' transfer
parameter WAIT_READ=2;                                           //Number of wait cycles issued by the slave in response to a 'read' transfer

localparam BYTE=3'b000;                                          //Transfer size encodding for 1-byte transfers. Note: 32-bit databus is assumed
localparam HALFWORD=3'b001;                                      //Transfer size encodding for 2-byte transfers, i.e. halfword. Note: 32-bit databus is assumed
localparam WORD=3'b010;                                          //Transfer size encodding for 4-byte transfers, i.e. word. Note: 32-bit databus is assumed

localparam SINGLE=3'b000;                                        //Single burst
localparam WRAP4=3'b010;                                         //4-beat wrapping burst
localparam INCR4=3'b011;                                         //4-beat incrementing burst
localparam WRAP8=3'b100;                                         //8-beat wrapping burst
localparam INCR8=3'b101;                                         //8 beat incrementing burst
localparam WRAP16=3'b110;                                        //16-beat wrapping burst
localparam INCR16=3'b111;                                        //16-beat incrementing burst

localparam REGISTER_SELECT_BITS=12;                              //Memory mapping - each slave's internal memory has maximum 2^REGISTER_SELECT_BITS-1 bytes (depends on MEMORY_DEPTH)
localparam SLAVE_SELECT_BITS=20;                                 //Memory mapping - width of slave address

//Internal signals declarations
logic clk;                                                       //System's clock
logic rstn;                                                      //Active high logic  
integer SEED=15;                                                  //Used for randomization

logic start_0;                                                   //Read/Write transer is initiated if the 'start' signal is logic high upon positive edge of clk
logic rw_0;                                                      //Dictates transfer direction. '1' for Master-->Slave (write) and '0' for Slave-->Master (read)
logic [2:0] hsize_0;                                             //transfer size for Master_0
logic [DATA_WIDTH-1:0] data_rand_0;                              //Randomized data to be written by a Master_0 to a Slave

logic [ADDR_WIDTH-1:0] addr_tmp_0;                               //Randomized register address prior to byte/half word/ word alighment
logic [ADDR_WIDTH-1:0] addr_rand_1;                              //Randomizes slave address
logic [ADDR_WIDTH-1:0] addr_rand_0;                              //Address for the transfer issued by Master_0

logic [2:0] hburst_0;                                            //Burst type

logic [DATA_WIDTH-1:0] data_out_m0;                              //Received data from one of the slaves as sampled by master #0 following a valid read command

logic hready;                                                    //hready signal indicates if the bus is busy

logic [SLAVE_COUNT-1:0][MEMORY_DEPTH-1:0][7:0]mem;               //mimic memory for slave 0

logic [2:0] burst_type;                                          //Supported burst types: Single, WRAP4, INCR4, WRAP8, INCR8, WRAP16 and INCR16
logic [3:0] beat_counter;                                        //Indicates the location within a certain burst

logic [2:0] addr_delta;                                          //Indicates the width of the transfer: byte=1, half word=2, word=4. 
logic [4:0] burst_len;                                           //Indicates the burst length: 1,4,8 or 16. 
logic [ADDR_WIDTH-1:0] addr_mimc;                                //addr_mimc mimics the internal logic within the master which calculates the address
logic [ADDR_WIDTH-1:0]haddr_rand;                                //

//Task declerations 

//Write to mimic memory task: upon invoking this task the relevant data and adress buses are sampled and written into the mimic memory after three 'hready' negative edges.
//This is since the data, address, slave number etc. which are generated within the TB are written into the slave internal memory with latency due to the pipeline nature of the architecture.
//This task is declared 'automatic' to allow parallel executions in case of consecutive 'write' commands 
task automatic write_to_mimic_task(input logic [2:0] hsize, input logic [SLAVE_COUNT-1:0] slave_idx, input logic [ADDR_WIDTH-1:0] addr_rand, input logic [DATA_WIDTH-1:0] data_rand);

  logic [2:0] hsize_s;                                           //Holds the value of hsize upon invokation
  logic [SLAVE_COUNT-1:0] slave_idx_s;                           //Holds the value of slave_idx upon invokation
  logic [ADDR_WIDTH-1:0] addr_rand_s;                            //Holds the value of haddr_rand upon invokation
  logic [DATA_WIDTH-1:0] data_rand_s;                            //Holds the value of data_rand upon invokation

  hsize_s=hsize;
  slave_idx_s=slave_idx;
  addr_rand_s=addr_rand;
  data_rand_s=data_rand;

  repeat (3) begin                                               //wait for 3 hclk positive edges where the hready is logic high due to pipeline related latency
    #1
    wait (hready==1'b1) 
    #1
    @(posedge clk);
  end
  
  
  case (hsize_s)                                                 //Write the value to the relevant mimic memory
    BYTE : mem[slave_idx_s][addr_rand_s]=data_rand_s[31:24];

    HALFWORD : begin
    mem[slave_idx_s][addr_rand_s]=data_rand_s[31:24];
    mem[slave_idx_s][addr_rand_s+1]=data_rand_s[23:16];
    end

    WORD : begin 
    mem[slave_idx_s][addr_rand_s]=data_rand_s[31:24];
    mem[slave_idx_s][addr_rand_s+1]=data_rand_s[23:16];
    mem[slave_idx_s][addr_rand_s+2]=data_rand_s[15:8];
    mem[slave_idx_s][addr_rand_s+3]=data_rand_s[7:0];
    end
  endcase	
endtask

//compare_task: upon invoking this task, the relevant data, slave index and address buses are sampled and after the latency period of 3 hready edges compared with the data obtained by the master at the end of a 'read' transfer
task automatic compare_task(input logic [2:0] hsize, input logic [SLAVE_COUNT-1:0] slave_idx, input logic [ADDR_WIDTH-1:0] addr_rand, input logic [4:0] wait_period);
  logic [2:0] hsize_s;                                           //Holds the value of hsize upon invokation
  logic [SLAVE_COUNT-1:0] slave_idx_s;                           //Holds the value of slave_idx upon invokation
  logic [ADDR_WIDTH-1:0] addr_rand_s;                            //Holds the value of haddr_rand upon invokation
 
  #1;
  hsize_s=hsize;
  slave_idx_s=slave_idx;
  addr_rand_s=addr_rand;

  repeat (wait_period) begin
    #1
    wait (hready==1'b1) 
    #1
    @(posedge clk);                                              //wait for 3 hclk positive edges where the hready is logic high due to pipeline related latency
  end
  #1;
 
  case (hsize_s)                                                 //Compare the value with the relevant mimic memory
    BYTE: 
    if (mem[slave_idx_s][addr_rand_s]==data_out_m0[31:24])
      $display("Data stored in mimic memory number %d in address %d is: %h, Data read from slave %d is: %2h - GREAT SUCCESS",slave_idx_s, addr_rand_s, mem[slave_idx_s][addr_rand_s],slave_idx_s, data_out_m0[31:24]);
    else begin
      $display ("Data stored in mimic memory number %d in address %d is: %h, Data read from slave %d is: %2h - FAILURE",slave_idx_s, addr_rand_s, mem[slave_idx_s][addr_rand_s],slave_idx_s, data_out_m0[31:24]);
      $timeformat(-9,2,"ns");
      $display("Time is %t", $realtime); 
      $finish;
  end 
	
    HALFWORD :
    if ({mem[slave_idx_s][addr_rand_s],mem[slave_idx_s][addr_rand_s+1]}==data_out_m0[31:16])
      $display("Data stored in mimic memory number %d in address %d is: %4h, Data read from slave %d is: %4h - GREAT SUCCESS",slave_idx_s, addr_rand_s, {mem[slave_idx_s][addr_rand_s],mem[slave_idx_s][addr_rand_s+1]},slave_idx_s, data_out_m0[31:16]);
    else begin
      $display("Data stored in mimic memory number %d in address %d is: %4h, Data read from slave %d is: %4h - FAILURE",slave_idx_s, addr_rand_s, mem[slave_idx_s][addr_rand_s+:1],slave_idx_s, data_out_m0[31:16]);
      $timeformat(-9,2,"ns");
      $display("Time is %t", $realtime);
      $finish;
    end 

    WORD :
    if ({mem[slave_idx_s][addr_rand_s],mem[slave_idx_s][addr_rand_s+1],mem[slave_idx_s][addr_rand_s+2],mem[slave_idx_s][addr_rand_s+3]}==data_out_m0[31:0])
      $display("Data stored in mimic memory number %d in address %d is: %8h, Data read from slave %d is: %8h - GREAT SUCCESS", slave_idx_s, addr_rand_s,{mem[slave_idx_s][addr_rand_s],mem[slave_idx_s][addr_rand_s+1],mem[slave_idx_s][addr_rand_s+2],mem[slave_idx_s][addr_rand_s+3]},slave_idx_s,data_out_m0);
    else begin
      $display("Data stored in mimic memory number %d in address %d is: %8h, Data read from slave %d is: %8h - FAILURE",slave_idx_s, addr_rand_s, {mem[slave_idx_s][addr_rand_s],mem[slave_idx_s][addr_rand_s+1],mem[slave_idx_s][addr_rand_s+2],mem[slave_idx_s][addr_rand_s+3]}, slave_idx_s,data_out_m0);
      $timeformat(-9,2,"ns");
      $display("Time is %t", $realtime);
      $finish;
  end 
  endcase 
endtask

//Initiate transfer task : issues m consecutive transfers with randomized parameters (addr,size,width,etc.)
task initiate_transfer(input int m);

  burst_len=1;                                                       //Initializaion of the burst length 
  beat_counter=0;                                                    //Initiatlization of the beat counter
  @(posedge clk)
  start_0=1'b1;                                                      //Transfer initiation is synchronized to positive clock edge
  @(posedge clk)

  for (int i=0; i<m; i++) begin

  if (beat_counter==(burst_len-1)) begin                             //Execute only on the last iteration of a burst - the master's output buses will be updted on the first beat of the following transfer
    beat_counter='0;

    rw_0=$dist_uniform(SEED,0,1);                                    //Randomize transfer command, i.e. read/write
    hsize_0=$dist_uniform(SEED,0,2);                                 //Randomize transfer size

    burst_type= $dist_uniform(SEED,0,7);                             //Randomize burst type and length
    case (burst_type)
    SINGLE: begin 
      hburst_0=SINGLE;
      burst_len=1;
    end 
    WRAP4: begin
      hburst_0=WRAP4;
      burst_len=4;
    end
    INCR4: begin
      hburst_0=INCR4;
      burst_len=4;
    end
    WRAP8: begin
      hburst_0=WRAP8;
      burst_len=8;
    end
    INCR8: begin 
      hburst_0=INCR8;
      burst_len=8;
    end
    WRAP16: begin
      hburst_0=WRAP16;
      burst_len=16;
    end
    INCR16: begin 
      hburst_0=INCR16;
      burst_len=16;
    end
    default: begin 
      hburst_0=SINGLE;
      burst_len=1;
    end 
  endcase
    
  addr_tmp_0= $dist_uniform(SEED,0,MEMORY_DEPTH-1-16*4);                //Selecting a register to communicate with. NOTE: I have restricted accesses to memory locations are prone to overflow in a case of 16 beat trasnfers of 32-bit length each - I will add the required logic that will limit access based on the burst leng and hsize product someday :)  
  case (hsize_0)                                                        //Address must be alighed according to the transfer size
    BYTE : begin
      addr_rand_0 = addr_tmp_0;
      addr_delta=1; 
      end
    HALFWORD : begin 
      addr_rand_0 = {addr_tmp_0[ADDR_WIDTH-1:1],1'b0};
      addr_delta=2; 
    end
    WORD : begin 
      addr_rand_0 = {addr_tmp_0[ADDR_WIDTH-1:2],2'b00};
      addr_delta=4; 
    end
  endcase
 
  addr_rand_1= $dist_uniform(SEED,0,SLAVE_COUNT-1);                   //Selecting a slave to initiate a trasfer with   
  
  haddr_rand = {addr_rand_1[SLAVE_SELECT_BITS-1:0],addr_rand_0[REGISTER_SELECT_BITS-1:0]};
  addr_mimc = addr_rand_0;
  end 
  else 
    beat_counter=beat_counter+$bits(beat_counter)'(1);

  //Calculate address for the mimic memory write task
  if (beat_counter>0)
  if ((hburst_0==INCR4)||(hburst_0==INCR8)||(hburst_0==INCR16))         //Incrementing bursts: INCR4, INCR8, INCR16
    addr_mimc= addr_mimc+$bits(addr_mimc)'(addr_delta);
  else if (hburst_0==WRAP4)                                             //4-beat wrapping burst
    case (hsize_0)
      BYTE: begin 
      addr_mimc[31:2]= addr_mimc[31:2];
      addr_mimc[1:0]= addr_mimc[1:0]+2'd1;
      end 

      HALFWORD: begin
      addr_mimc[31:3]= addr_mimc[31:3];
		  addr_mimc[2:0]=addr_mimc[2:0]+3'd2;
		  end

      WORD: begin
      addr_mimc[31:4]= addr_mimc[31:4];
      addr_mimc[3:0]=addr_mimc[3:0]+4'd4;
      end
    endcase   
  else if (hburst_0==WRAP8)                                             //8-beat wrapping burst 
    case (hsize_0)
      BYTE: begin 
      addr_mimc[31:3]= addr_mimc[31:3];
      addr_mimc[2:0]= addr_mimc[2:0]+3'd1;
      end 

      HALFWORD: begin
      addr_mimc[31:4]= addr_mimc[31:4];
      addr_mimc[3:0]=addr_mimc[3:0]+4'd2;
      end

      WORD: begin
      addr_mimc[31:5]= addr_mimc[31:5];
      addr_mimc[4:0]=addr_mimc[4:0]+5'd4;
      end
    endcase 	
  else if (hburst_0==WRAP16)                                            //16-beat wrapping burst
    case (hsize_0)
      BYTE: begin 
      addr_mimc[31:4]= addr_mimc[31:4];
      addr_mimc[3:0]= addr_mimc[3:0]+4'd1;
      end 

      HALFWORD: begin
      addr_mimc[31:5]= addr_mimc[31:5];
      addr_mimc[4:0]=addr_mimc[4:0]+5'd2;
      end

      WORD: begin
      addr_mimc[31:6]= addr_mimc[31:6];
      addr_mimc[5:0]=addr_mimc[5:0]+6'd4;
      end
    endcase

 
  if (rw_0) begin 
    data_rand_0= $dist_uniform(SEED,0,100000000);                        //Randomized write data for a 'write' transfer	
    fork                                                                 //Execute the 'write_to_mimic_task' which runs in the background
      write_to_mimic_task(hsize_0,addr_rand_1,addr_mimc,data_rand_0);
    join_none;
    end
  else begin
    fork
      compare_task(hsize_0,addr_rand_1,addr_mimc,3);                               //Execute the 'compare_task' which runs in the background	
      //wait (start_0==1'b0);                                              //Terminate comparison operations when TB-generated 'start' signal falls to logic low - stop comparison tasks for the last iteration of the simulation, can also be solved with changing the loop dimensions for comparison
      join_none;
  end 
  #1
  wait(hready);                                                                                  //Prevents from issueing new transfers while the bus is busy
  @(posedge clk);
  end

  start_0=1'b0;
endtask


//DUT instantiation
AHB_DUT #(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH), .MEMORY_DEPTH(MEMORY_DEPTH), .SLAVE_COUNT(SLAVE_COUNT), .WAIT_WRITE(WAIT_WRITE), .WAIT_READ(WAIT_READ)) d0(.i_hclk(clk),
                                                                                                                                                                       .i_hreset(rstn),
                                                                                                                                                                       .i_start_0(start_0),
                                                                                                                                                                       .i_hburst(hburst_0),
                                                                                                                                                                       .i_haddr_0(haddr_rand),
                                                                                                                                                                       .i_hwrite_0(rw_0),
                                                                                                                                                                       .i_hsize_0(hsize_0),
                                                                                                                                                                       .i_hwdata_0(data_rand_0),
                                                                                                                                                                       .o_hrdata_m0(data_out_m0),
                                                                                                                                                                       .o_hready(hready)
);

//Initial blocks
initial begin
rstn=1'b0;
clk=1'b0;
start_0=1'b0;
mem='0;
#CLK_PERIOD
rstn=1'b1;
#200

initiate_transfer(5000);
#1000
$display("\n -----------------------");
$display("\n ALL tests have passed - Hallelujah!");
end

//Clock generation
always
begin
#(CLK_PERIOD/2);
clk=~clk;
end

endmodule
//APB slave. Realized as a packed 2D memory array. 

module APB_Slave(i_prstn,i_pclk,i_paddr,i_pwrite,i_psel,i_penable,i_pwdata,o_prdata,o_pready,o_pslverr);

//Parameters
parameter DATA_WIDTH = 32;                                    //Data bus width
parameter ADDR_WIDTH = 32;                                    //Address bus width

parameter WAIT_WRITE = 0;                                     //Number of wait cycles following a write command
parameter WAIT_READ = 0;                                      //Number of wait cycles following a read command
localparam WAIT_MAX = 3;                                      //Maximum number of wait cycles is 2^WAIT_MAX-1. Note: can also be paramatrized to allow per-slave configuration.

parameter REG_NUM = 5;                                        //Dictates the size of the memory. Address span within a given slave equals 2**REG_NUM [REG_NUM-1:0]. Default: 32 registers.
localparam WORD_LEN = $clog2(DATA_WIDTH>>3);                  //Number of bits requried to specify a given byte within a word. Example: for 32-bit word 2 bits are needed for byte0-byte3. These are the LSBs of the address which are zeros in normal operation (access is word-based)
 
//Inputs
input logic i_prstn;                                          //Active high logic 
input logic i_pclk;                                           //System's clock

input logic [ADDR_WIDTH-1:0] i_paddr;                         //Peripheral address bus
input logic i_pwrite;                                         //Peripheral transfer direction
input logic i_psel;                                           //Peripheral slave select
input logic i_penable;                                        //Peripheral enable
input logic [DATA_WIDTH-1:0] i_pwdata;                        //Peripheral write data bus

//Outputs
output logic [DATA_WIDTH-1:0] o_prdata;                       //Peripheral read data bus
output logic o_pready;                                        //Read signal. The slave issues this signal to extend an APB transfer.
output logic o_pslverr;                                       //This signal indicates transfer failure. If it is logic high upon 'pread','psel' and 'penable' negative edge (i.e at the end of a read/write operation).

//Internal signals
logic [ADDR_WIDTH-1:0][DATA_WIDTH-1:0] mem;                   //Default: 32 word of 4 bytes each (32-bit). To access a 32-bit long word the 2 LSBs in the address bus are 2'b00. 
logic [WAIT_MAX-1:0] count_pready;                            //Wait state counter 

//HDL code

//Slave initialization and i_pwrdata sampling for a 'write' command
always @(posedge i_pclk or negedge i_prstn)
  if (!i_prstn)
    mem<='0;
  else if ((i_psel)&&(i_penable))
    if ((i_pwrite)&&(o_pready))
      mem[i_paddr[REG_NUM+WORD_LEN-1:WORD_LEN]]<=i_pwdata;

//pready signal generation and o_prdata update for a 'read' command
always @(posedge i_pclk or negedge i_prstn)
  if (!i_prstn) begin
    count_pready<='0;
    o_pready<=1'b0;
  end
  else if ((i_psel==1'b1)&&(i_penable==1'b0)) begin
    count_pready<='0; 
    if ((i_pwrite)&&(WAIT_WRITE=='0)) begin                                //Write commnad and no wait states
    o_pready<=1'b1;
    end
    else if ((~i_pwrite)&&(WAIT_READ=='0)) begin                           //Read commnad and no wait states
      o_pready<=1'b1;
      o_prdata<=mem[i_paddr[REG_NUM+WORD_LEN-1:WORD_LEN]];                 //Updating the o_prdata together with the rising edge of pready
    end
    else o_pready<=1'b0;
  end
  
  else if ((i_pwrite)&&(i_psel))	                                       //Write commnad with 'WAIT_WRITE' wait states
    if (count_pready==$bits(count_pready)'(WAIT_WRITE-1)) begin
      o_pready<=1'b1;
      count_pready<=count_pready+$bits(count_pready)'(1);	  
    end
    else if (count_pready==$bits(count_pready)'(WAIT_WRITE))
      o_pready<=1'b0;	
    else
      count_pready<=count_pready+$bits(count_pready)'(1);

  else if ((~i_pwrite)&&(i_psel))                                          //Read command with 'WAIT_READ' wait states
    if (count_pready==$bits(count_pready)'(WAIT_READ-1)) begin                    
      o_pready<=1'b1;
      o_prdata<=mem[i_paddr[REG_NUM+WORD_LEN-1:WORD_LEN]];                 //Updating the o_prdata with the rising edge of pready
      count_pready<=count_pready+$bits(count_pready)'(1);
    end
    else if (count_pready==$bits(count_pready)'(WAIT_READ))
      o_pready<=1'b0;
    else
      count_pready<=count_pready+$bits(count_pready)'(1);


//Error signal generation
assign o_pslverr = 1'b0;                                                   //Tied to logic zero for this simplified slave implementation. 
   
endmodule

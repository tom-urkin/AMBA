//AHB-lite master. The AHB master monitors the availability of the bus, samples data and address packets generated in the TB and produces the relevant signals with a selected slave according to the AHB-lite protocol. 
module AHB_master(i_hclk,i_hreset,i_start,i_haddr,i_hwrite,i_hsize,i_hwdata,i_hready,i_hresp,i_hrdata,i_hburst,
                  o_haddr,o_hwrite,o_hsize,o_htrans,o_hwdata,o_hrdata,o_hburst);

//Parameters
parameter ADDR_WIDTH=32;                                //Address bus width
parameter DATA_WIDTH=32;                                //Data bus width

localparam BYTE=3'b000;                                 //Transfer size encodding for 1-byte transfers. Note: 32-bit databus is assumed
localparam HALFWORD=3'b001;                             //Transfer size encodding for 2-byte transfers, i.e. halfword. Note: 32-bit databus is assumed
localparam WORD=3'b010;                                 //Transfer size encodding for 4-byte transfers, i.e. word. Note: 32-bit databus is assumed

localparam IDLE=2'b00;                                  //Indicates that no data transfer is required
localparam BUSY=2'b01;                                  //The BUSY transfer type enables masters to insert idle cycles in the middle of a burst
localparam NONSEQ= 2'b10;                               //Indicates a single transfer or the first transfer of a burst
localparam SEQ=2'b11;                                   //The remaining transfers in a burst are SEQUENTIAL

localparam SINGLE=3'b000;                               //Single burst
localparam WRAP4=3'b010;                                //4-beat wrapping burst
localparam INCR4=3'b011;                                //4-beat incrementing burst
localparam WRAP8=3'b100;                                //8-beat wrapping burst
localparam INCR8=3'b101;                                //8 beat incrementing burst
localparam WRAP16=3'b110;                               //16-beat wrapping burst
localparam INCR16=3'b111;                               //16-beat incrementing burst

//Inputs 
input logic i_hclk;                                     //All signal timings are related to the rising edge of hclk
input logic i_hreset;                                   //Active low bus reset

input logic i_start;                                    //At every positive edge of hclk, if i_start is logic high then the master initiates a transfer (generated in the TB)
input logic [ADDR_WIDTH-1:0] i_haddr;                   //Address bus (generated in the TB)
input logic i_hwrite;                                   //Indicates the transfer direction. Logic high values indicates a 'write' and logic low a 'read' (generated in the TB)
input logic [2:0] i_hsize;                              //Indicates the size of the transfer, i.e. byte, half word or word (generated in the TB)
input logic [DATA_WIDTH-1:0] i_hwdata;                  //Write data bus for 'write' transfers from the master to a slave (generated in the TB)

input logic i_hready;                                   //Generated within the accessed slave. When logic high, i_hready signal indicates the transfer has finished
input logic i_hresp;                                    //Generated within the accessed slave. When logic low, the transfer status is OKAY, when logic high the status is ERROR
input logic [DATA_WIDTH-1:0] i_hrdata;                  //During read operation, the read data bus transfers data from the selected slave to the master. 
input logic [2:0] i_hburst;                             //Burst type indicates if the transfer is a single transfer of forms a part of a burst. Here, fixed bursts of 4, 8 and 16 are supported for both incrementing/wrapping types.  

//Outpus
output logic [ADDR_WIDTH-1:0] o_haddr;                  //Sampled i_haddr bus
output logic o_hwrite;                                  //Sampled i_hwrite signal
output logic [2:0] o_hsize;                             //Sampled i_hsize bus
output logic [1:0] o_htrans;                            //Indicates the transfer type, i.e. IDLE, BUSY, NONSEQUENTIAL, SEQUENTIAL
output logic [DATA_WIDTH-1:0] o_hwdata;                 //Sampled i_hwdata bus
output logic [DATA_WIDTH-1:0] o_hrdata;                 //Data read from a slave
output logic [2:0] o_hburst;                            //Burst type

//Internal signals
logic [1:0] state;                                      //IDLE,BUSY,NONSEQ or SEQ (same as the 'o_htrans')
logic [1:0] next_state;                                 //FSM next state
logic read_flag;                                        //When 'read_flag' is logic high it means that a 'read' transfer has been initiated but the 'i_hrdata' has not been sampled yet
logic [2:0] read_size;                                  //Holds the size of the issued read transfer
logic [DATA_WIDTH-1:0] hwdata_reg;                      //Used to sample the incoming HWDATA generated in the TB. This is to support the pipelined architecture of the bus where the HWDATA is updated one cycle after the control buses are. 
logic start_samp;                                       //Sampled i_start signal - synchronized to the positive edge of hclk
logic [3:0] burst_count;                                //Indicates the beat within the burst

//HDL code
always @(posedge i_hclk or negedge i_hreset)
  if (!i_hreset)
    state<=IDLE;
  else if (i_hready)                                    //Transition between states is correlated to i_hready signal
    state<=next_state; 

always @(*) begin 
  case (state)  
    IDLE: next_state = (start_samp) ? (NONSEQ) : (IDLE);
    NONSEQ: next_state = (!start_samp) ? IDLE : (o_hburst!=SINGLE) ? SEQ : NONSEQ;
    SEQ: next_state = (!start_samp) ? IDLE : (burst_count>0) ? SEQ : (start_samp) ? NONSEQ : IDLE; 
  endcase 
end

always @(posedge i_hclk or negedge i_hreset)
  if (!i_hreset) begin
    o_haddr<='0;
    o_hwrite<=1'b1;
    hwdata_reg<='0;
    o_hwdata<='0;
    o_hsize<=3'b010;
    read_flag<=1'b0;
    read_size<=3'b010;
    o_hburst<=3'b000;
    burst_count<='0;
  end
  else 
  case (state)
    IDLE: begin
    if (start_samp&&i_hready) begin
      o_haddr<=i_haddr;
      o_hwrite<=i_hwrite;
      hwdata_reg<=i_hwdata;
      o_hwdata<=hwdata_reg;
      o_hsize<=i_hsize;
      o_hburst<=i_hburst;
      burst_count<='0;
    end
    start_samp<=i_start; 
    end

    NONSEQ: if (i_hready) begin
      if (o_hburst==SINGLE)                                                 //Single burst
        o_haddr<= i_haddr;
      else if ((o_hburst==INCR4)||(o_hburst==INCR8)||(o_hburst==INCR16))    //Incrementing bursts
        case (o_hsize)
          BYTE: o_haddr<= o_haddr+$bits(o_haddr)'(1);
          HALFWORD: o_haddr<= o_haddr+$bits(o_haddr)'(2);
          WORD: o_haddr<= o_haddr+$bits(o_haddr)'(4);
        endcase 
      else if (o_hburst==WRAP4)                                             //4-beat wrapping burst
        case (o_hsize)
          BYTE: begin 
          o_haddr[31:2]<= o_haddr[31:2];
          o_haddr[1:0]<= o_haddr[1:0]+2'd1;
          end

          HALFWORD: begin
          o_haddr[31:3]<= o_haddr[31:3];
          o_haddr[2:0]<=o_haddr[2:0]+3'd2;
          end

          WORD: begin
          o_haddr[31:4]<= o_haddr[31:4];
          o_haddr[3:0]<=o_haddr[3:0]+4'd4;
          end
        endcase
      else if (o_hburst==WRAP8)                                             //8-beat wraping burst
        case (o_hsize)
          BYTE: begin 
          o_haddr[31:3]<= o_haddr[31:3];
          o_haddr[2:0]<= o_haddr[2:0]+3'd1;
          end 

          HALFWORD: begin
          o_haddr[31:4]<= o_haddr[31:4];
          o_haddr[3:0]<=o_haddr[3:0]+4'd2;
          end

          WORD: begin
          o_haddr[31:5]<= o_haddr[31:5];
          o_haddr[4:0]<=o_haddr[4:0]+5'd4;
          end
        endcase
      else if (o_hburst==WRAP16)                                            //16-beat warpping burst
        case (o_hsize)
          BYTE: begin 
          o_haddr[31:4]<= o_haddr[31:4];
          o_haddr[3:0]<= o_haddr[3:0]+4'd1;
          end

          HALFWORD: begin
          o_haddr[31:5]<= o_haddr[31:5];
          o_haddr[4:0]<=o_haddr[4:0]+5'd2;
          end

          WORD: begin
          o_haddr[31:6]<= o_haddr[31:6];
          o_haddr[5:0]<=o_haddr[5:0]+6'd4;
          end
        endcase

      hwdata_reg<=i_hwdata;
      o_hwdata<= hwdata_reg;	

      if (o_hburst==SINGLE) begin
        o_hburst<=i_hburst;
        o_hsize<= i_hsize;
        o_hwrite<= i_hwrite;
      end

      read_flag<= ~o_hwrite;                                                //If read_flag is logic high --> a read transfer was issued. It is required to execute the sampling on the third clock edge (for zero wait states)
      read_size<= (~o_hwrite) ? o_hsize : read_size;                        //'read_size' holds the size of the read transfer, i.e. BYTE, HALFWORD or WORD
      
      case (o_hburst)
        SINGLE: burst_count<=$bits(burst_count)'(0);
        INCR4: burst_count<=$bits(burst_count)'(2);
        INCR8: burst_count<=$bits(burst_count)'(6);
        INCR16: burst_count<=$bits(burst_count)'(14);
        WRAP4: burst_count<=$bits(burst_count)'(2);
        WRAP8: burst_count<=$bits(burst_count)'(6);
        WRAP16: burst_count<=$bits(burst_count)'(14);
      endcase

      start_samp<=i_start; 
   
      if (read_flag)                                                        //Read transfer - 'rdata' has not been sampled yet and it is ready to be sampled since i_hready is logic high
        case (read_size)
          BYTE : o_hrdata[31:24]<= i_hrdata[31:24];
          HALFWORD : o_hrdata[31:16]<= i_hrdata[31:16];
          WORD : o_hrdata<= i_hrdata;	
        endcase
  end

  SEQ: if (i_hready) begin
    burst_count<=burst_count-$bits(burst_count)'(1);

    if (burst_count>0) begin
      if ((o_hburst==INCR4)||(o_hburst==INCR8)||(o_hburst==INCR16))         //Incrementing bursts
        case (o_hsize)
          BYTE: o_haddr<= o_haddr+$bits(o_haddr)'(1);
          HALFWORD: o_haddr<= o_haddr+$bits(o_haddr)'(2);
          WORD: o_haddr<= o_haddr+$bits(o_haddr)'(4);
        endcase
      else if (o_hburst==WRAP4)                                             //Wrapping bursts 
        case (o_hsize)
          BYTE: begin 
          o_haddr[31:2]<= o_haddr[31:2];
          o_haddr[1:0]<= o_haddr[1:0]+2'd1;
          end

          HALFWORD: begin
          o_haddr[31:3]<= o_haddr[31:3];
          o_haddr[2:0]<=o_haddr[2:0]+3'd2;
          end

          WORD: begin
          o_haddr[31:4]<= o_haddr[31:4];
          o_haddr[3:0]<=o_haddr[3:0]+4'd4;
          end
        endcase
      else if (o_hburst==WRAP8)                                             //Wrapping bursts 
        case (o_hsize)
          BYTE: begin 
          o_haddr[31:3]<= o_haddr[31:3];
          o_haddr[2:0]<= o_haddr[2:0]+3'd1;
          end

          HALFWORD: begin
          o_haddr[31:4]<= o_haddr[31:4];
          o_haddr[3:0]<=o_haddr[3:0]+4'd2;
          end

          WORD: begin
          o_haddr[31:5]<= o_haddr[31:5];
          o_haddr[4:0]<=o_haddr[4:0]+5'd4;
          end
        endcase
      else if (o_hburst==WRAP16)                                             //Wrapping bursts 
        case (o_hsize)
          BYTE: begin 
          o_haddr[31:4]<= o_haddr[31:4];
          o_haddr[3:0]<= o_haddr[3:0]+4'd1;
          end

          HALFWORD: begin
          o_haddr[31:5]<= o_haddr[31:5];
          o_haddr[4:0]<=o_haddr[4:0]+5'd2;
          end

          WORD: begin
          o_haddr[31:6]<= o_haddr[31:6];
          o_haddr[5:0]<=o_haddr[5:0]+6'd4;
           end
        endcase
    end
    else
      o_haddr<=i_haddr;

    hwdata_reg<=i_hwdata;                                                   //Sample data generated in the TB
    o_hwdata<= hwdata_reg;                                                  //Update msater's output data bus (1 cycle later in accordance with AHB protocol)

    if (burst_count==0) begin                                               //Sample new control buses on the last beat of a burst
      o_hwrite<= i_hwrite;
      o_hsize<= i_hsize;
      o_hburst<=i_hburst;
      case (i_hburst)
        SINGLE: burst_count<=$bits(burst_count)'(0);
        INCR4: burst_count<=$bits(burst_count)'(2);
        INCR8: burst_count<=$bits(burst_count)'(6);
        INCR16: burst_count<=$bits(burst_count)'(14);

        WRAP4: burst_count<=$bits(burst_count)'(2);
        WRAP8: burst_count<=$bits(burst_count)'(6);
        WRAP16: burst_count<=$bits(burst_count)'(14);
      endcase
    end

    if (read_flag)                                                          //Read transfer - 'rdata' has not been sampled yet and it is ready to be sampled since i_hready is logic high
      case (read_size)
      BYTE : o_hrdata[31:24]<= i_hrdata[31:24];
      HALFWORD : o_hrdata[31:16]<= i_hrdata[31:16];
      WORD : o_hrdata<= i_hrdata;	
      endcase 

    start_samp<=i_start; 
  end

  endcase

assign o_htrans = state;

endmodule

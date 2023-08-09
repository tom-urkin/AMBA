//
module AHB_IF(i_hclk,i_hreset,i_haddr,
              i_hresp_0,i_hrdata_0,i_hready_0,
			  i_hresp_1,i_hrdata_1,i_hready_1,
			  i_hresp_2,i_hrdata_2,i_hready_2,			  
			  o_sel,o_hrdata,o_hresp,o_hready);


//Parameters
parameter ADDR_WIDTH=32;                                   //Address bus width
parameter DATA_WIDTH=32;                                   //Data bus width
parameter SLAVE_COUNT=2;                                   //Number of connected AHB slaves

parameter REGISTER_SELECT_BITS=12;                         //Memory mapping - each slave's internal memory has maximum 2^REGISTER_SELECT_BITS-1 bytes (depends on MEMORY_DEPTH)
parameter SLAVE_SELECT_BITS=20;                            //Memory mapping - width of slave address

parameter [SLAVE_SELECT_BITS-1:0] ADDR_SLAVE_0 = 0;       //Address of slave 0
parameter [SLAVE_SELECT_BITS-1:0] ADDR_SLAVE_1 = 1;       //ADdress of slave 1
parameter [SLAVE_SELECT_BITS-1:0] ADDR_SLAVE_2 = 2;       //ADdress of slave 1 
 
localparam MUX_SELECT = $clog2(SLAVE_COUNT);               //Number of bits required to select a single slave

//Inputs 
input logic i_hclk;                                        //All signal timings are related to the rising edge of hclk
input logic i_hreset;                                      //Active low bus reset
input logic [ADDR_WIDTH-1:0] i_haddr;                      //Input address from which both a slave is selected (MSBs) and internal memory slot (LSBs)

input logic i_hresp_0;                                     //Slave 0 transfer response
input logic [DATA_WIDTH-1:0] i_hrdata_0;                   //Slave 0 read data bus
input logic i_hready_0;                                    //Slave 0 'hreadyout' signal

input logic i_hresp_1;                                     ///Slave 1 transfer response
input logic [DATA_WIDTH-1:0] i_hrdata_1;                   //Slave 1 read data bus
input logic i_hready_1;                                    //Slave 1 'hreadyout' signal

input logic i_hresp_2;                                     ///Slave 1 transfer response
input logic [DATA_WIDTH-1:0] i_hrdata_2;                   //Slave 1 read data bus
input logic i_hready_2;                                    //Slave 1 'hreadyout' signal

//Outpus
output logic [SLAVE_COUNT-1:0] o_sel;                      //Slave select bus 
output logic [DATA_WIDTH-1:0] o_hrdata;                    //read data bus (after multiplexer)
output logic o_hresp;                                      //slave transfer response (after multiplexer)
output logic o_hready;                                     //slave hreadyout signal (after multiplexer)

//Internal signals
logic [MUX_SELECT-1:0] mux_select;                         //'mux_select' signal selects a slave to provide the master with read data packet (hrdata,hresp and hready)

//HDL code

always @(*)
  case (i_haddr[ADDR_WIDTH-1:ADDR_WIDTH-SLAVE_SELECT_BITS])  //[31:12] for defualt settings
    ADDR_SLAVE_0 : o_sel=3'b001;
	ADDR_SLAVE_1 : o_sel=3'b010;
	ADDR_SLAVE_2 : o_sel=3'b100;	
	default      : o_sel=3'b001;
  endcase

always @(posedge i_hclk or negedge i_hreset)
  if (!i_hreset)
    mux_select<=$bits(mux_select)'(0);
  else if (o_hready)
    case (i_haddr[ADDR_WIDTH-1:ADDR_WIDTH-SLAVE_SELECT_BITS])
      ADDR_SLAVE_0 :  mux_select<=$bits(mux_select)'(0);
	  ADDR_SLAVE_1 :  mux_select<=$bits(mux_select)'(1);
	  ADDR_SLAVE_2 :  mux_select<=$bits(mux_select)'(2);	  
	  default      :  mux_select<=$bits(mux_select)'(0);
	endcase

always @(*)
  case (mux_select)
    $bits(mux_select)'(0) : begin
	  o_hrdata = i_hrdata_0;
	  o_hresp = i_hresp_0;
	  o_hready = i_hready_0;
	end
	
	$bits(mux_select)'(1) : begin
	  o_hrdata = i_hrdata_1;
	  o_hresp = i_hresp_1;
	  o_hready = i_hready_1;
	end

	$bits(mux_select)'(2) : begin
	  o_hrdata = i_hrdata_2;
	  o_hresp = i_hresp_2;
	  o_hready = i_hready_2;
	end	
  endcase 

endmodule

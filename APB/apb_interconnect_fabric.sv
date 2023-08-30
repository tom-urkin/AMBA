//Interconnect fabric module
//Recieves the communication packets from all masters and produces a grant vector that is used to shadow all inactive masters while passing to the slave the relevant data buses
//Multiple transfer requests given at the same cycle are processed automatically according to the priority scheme while the inactive masters are waiting in the ACCESS phase

//------------------------------------------------------------------------------------//
//Modified Round-Robin arbiter is implemented please see readme file for clarification
module arbiter(i_rst,i_clk,i_request_vec,i_update,o_gnt,o_end_of_transfer);

//Parameters
parameter MASTER_COUNT=3;
parameter SLAVE_COUNT=3;

localparam PRIORITY_WIDTH=$clog2(MASTER_COUNT);
localparam MASTER_2 = 2'b10;
localparam MASTER_1 = 2'b01;
localparam MASTER_0 = 2'b00;

//Inputs
input logic i_clk;
input logic i_rst;
input logic [MASTER_COUNT-1:0] i_request_vec;                       //Indicates which masters have initiated a transfer that has not been completed yet
input logic i_update;                                               //Generates a new grant vector when logic high. Note: it is assumed that 'pready' is logic high for one clock cycle only

//Outputs
output logic [MASTER_COUNT-1:0] o_gnt;                              //Dictates which master won the arbitration (one-hot encoded)
output logic o_end_of_transfer;                                     //Rises to logic high for one clock cycle after each transfer execution

//Internal signals
logic [PRIORITY_WIDTH-1:0] sel_idx_dec;                             //Decimal value of the location in the priority vector that won the arbitration. Example: priority[3] has won - sel_idx_dec=2'b11

logic [MASTER_COUNT-1:0][PRIORITY_WIDTH-1:0] next_priority_state;   //priority_state value once the current tranfer is complete
logic [MASTER_COUNT-1:0][PRIORITY_WIDTH-1:0] priority_state;        //priority_state details the priority order of the masters. 'priority_state[0]' has the highest priority.

logic [2*MASTER_COUNT-1:0] request_vec_rotate_double;               //Used to perform cyclic shift operation
logic [MASTER_COUNT-1:0] request_vec_rotate;                        //The 'request_vec' rotated according to priority[0]

logic [MASTER_COUNT-1:0] higher_priority;                           //Used in the 'simple' priority encoder involved in the >> -- priority encoder -- << scheme
logic [MASTER_COUNT-1:0] priority_tmp;                              //Output of the 'simple' priority encoder

logic [2*MASTER_COUNT-1:0] priority_tmp_left;                       //Grant vector after the cyclic rotate left (priority[0] times) 
logic [PRIORITY_WIDTH-1:0] gnt_dec;                                 //Granted master decimal identifier

integer i;                                                          //Used to update the priority after completion of a transfer 
integer j;                                                          //Used to calculate the winning master index within the priority vector

//HDL code
//Update priority queque
always @(posedge i_clk or negedge i_rst)
  if (!i_rst) begin
    priority_state<={MASTER_2,MASTER_1,MASTER_0};                   //Initial priority order 
  end
  else if (i_update) begin
    priority_state<=next_priority_state;
    o_end_of_transfer<=1'b1;	
  end
  else 
    o_end_of_transfer<=1'b0;
  
always @(*) begin
  for (i=0; i<MASTER_COUNT; i++)
    if (i<sel_idx_dec)
      next_priority_state[i]=priority_state[i];                    //Keeps the priority status of masters which have not initiated a transfer request
    else if (i==MASTER_COUNT-1)
      next_priority_state[i]=priority_state[sel_idx_dec];          //The master who won the arvitration is sent to the back of the line
    else
      next_priority_state[i]=priority_state[i+1];
end

//Rotate right
assign request_vec_rotate_double = {i_request_vec,i_request_vec}>>priority_state[0];
assign request_vec_rotate = request_vec_rotate_double[MASTER_COUNT-1:0];

//Priority encoder
assign higher_priority[0]=1'b0;
//assign higher_priority[MASTER_COUNT-1:1] = higher_priority[MASTER_COUNT-2:0]|request_vec_rotate[MASTER_COUNT-2:0];
assign higher_priority[1]=higher_priority[0]|request_vec_rotate[0];
assign higher_priority[2]=higher_priority[1]|request_vec_rotate[1];

assign priority_tmp = request_vec_rotate[MASTER_COUNT-1:0]&~higher_priority[MASTER_COUNT-1:0];

//Rotate left
assign priority_tmp_left = {priority_tmp,priority_tmp}<<priority_state[0];

assign o_gnt = priority_tmp_left[2*MASTER_COUNT-1:MASTER_COUNT];                         //Grant vector comprises the MASTER_COUNT MSBs (after the shift left operation)
assign gnt_dec = (o_gnt==3'b001) ? MASTER_0 : (o_gnt==3'b010) ? MASTER_1 : MASTER_2;     //Convert the winning master from one-hot to decimal encoding

always @(*)
  for (j=0; j<MASTER_COUNT; j++)
    if (priority_state[j]==gnt_dec)
      sel_idx_dec=j;                                                                     //Calculate the index of the winning master in the priority vector

endmodule

//------------------------------------------------------------------------------------//
//APB interconnect fabric (IF)
module apb_interconnect_fabric(i_prstn,i_pclk,
i_paddr_m0,i_pwrite_m0,i_psel_m0,i_penable_m0,i_pwdata_m0,
i_paddr_m1,i_pwrite_m1,i_psel_m1,i_penable_m1,i_pwdata_m1,
i_paddr_m2,i_pwrite_m2,i_psel_m2,i_penable_m2,i_pwdata_m2,
i_prdata_s0,i_pready_s0,i_pslverr_s0,
i_prdata_s1,i_pready_s1,i_pslverr_s1,
i_prdata_s2,i_pready_s2,i_pslverr_s2,

o_paddr,o_pwrite,o_psel,o_penable,o_pwdata,o_prdata,o_pready,o_pslverr,
o_gnt);

//Parameters
parameter DATA_WIDTH = 32;                                     //Data bus width
parameter ADDR_WIDTH = 32;                                     //Address bus width
parameter MASTER_COUNT = 3;                                    //Maximum allowed number of masters
parameter SLAVE_COUNT=3;                                       //Number of slaves on the bus
localparam PRIORITY_WIDTH = $clog2(MASTER_COUNT);              //Number of bits required to represent the masters in the system. Example: 3 masters - 2 bits (declared next)

//Inputs
input logic i_prstn;                                           //Active high logic 
input logic i_pclk;                                            //System's clock

input logic [ADDR_WIDTH-1:0] i_paddr_m0;                       //Peripheral address bus
input logic i_pwrite_m0;                                       //Peripheral transfer direction
input logic [SLAVE_COUNT-1:0] i_psel_m0;                                         //Peripheral slave select
input logic i_penable_m0;                                      //Peripheral enable
input logic [DATA_WIDTH-1:0] i_pwdata_m0;                      //Peripheral write data bus

input logic [ADDR_WIDTH-1:0] i_paddr_m1;                       //Peripheral address bus
input logic i_pwrite_m1;                                       //Peripheral transfer direction
input logic [SLAVE_COUNT-1:0] i_psel_m1;                       //Peripheral slave select
input logic i_penable_m1;                                      //Peripheral enable
input logic [DATA_WIDTH-1:0] i_pwdata_m1;                      //Peripheral write data bus

input logic [ADDR_WIDTH-1:0] i_paddr_m2;                       //Peripheral address bus
input logic i_pwrite_m2;                                       //Peripheral transfer direction
input logic [SLAVE_COUNT-1:0] i_psel_m2;                       //Peripheral slave select
input logic i_penable_m2;                                      //Peripheral enable
input logic [DATA_WIDTH-1:0] i_pwdata_m2;                      //Peripheral write data bus

input logic [DATA_WIDTH-1:0] i_prdata_s0;                      //Peripheral read data bus
input logic i_pready_s0;                                       //Ready signal. A slave may use this signal to extend an APB transfer
input logic i_pslverr_s0;                                      //pslverr indicates transfer failure

input logic [DATA_WIDTH-1:0] i_prdata_s1;                      //Peripheral read data bus
input logic i_pready_s1;                                       //Ready signal. A slave may use this signal to extend an APB transfer
input logic i_pslverr_s1;                                      //pslverr indicates transfer failure

input logic [DATA_WIDTH-1:0] i_prdata_s2;                      //Peripheral read data bus
input logic i_pready_s2;                                       //Ready signal. A slave may use this signal to extend an APB transfer
input logic i_pslverr_s2;                                      //pslverr indicates transfer failure

//Outputs
output logic [ADDR_WIDTH-1:0] o_paddr;                         //Peripheral address bus
output logic o_pwrite;                                         //Peripheral transfer direction
output logic [SLAVE_COUNT-1:0] o_psel;                         //Peripheral slave select
output logic o_penable;                                        //Peripheral enable
output logic [DATA_WIDTH-1:0] o_pwdata;                        //Peripheral write data bus
output logic [DATA_WIDTH-1:0] o_prdata;                        //Peripheral read data bus
output logic o_pready;                                         //Ready signal. A slave may use this signal to extend an APB transfer
output logic o_pslverr;                                        //pslverr indicates transfer failure. 

output logic [MASTER_COUNT-1:0] o_gnt;                         //The GRANT vector (one-hot coded) 

//Internal signals
logic [MASTER_COUNT-1:0] request_vec;                          //Indicates which masters have initiated a transfer that has not been completed yet
logic [MASTER_COUNT-1:0] gnt_tmp;                              //The GRANT vector (one-hot coded) 
logic end_of_transfer;                                         //Indicates pervious transfer has finished. If logic high and other masters are waiting in line - penable is low for one cycle

//HDL code
//Produce APB related signals (data and address packets)
always @(posedge i_pclk or negedge i_prstn)
  if (!i_prstn) begin
    o_paddr<='0;
    o_pwrite<='0;
    o_psel<='0;
    o_penable<='0;
    o_pwdata<='0;
    o_prdata<='0; 
    o_pready<=1'b0;
    o_pslverr<=1'b0;
  end
  else begin
    case (o_gnt)
    3'b001:                                                    //Master 0 has won the arbitration
      if ((end_of_transfer==1'b1)&&(|request_vec)) begin       //If a transfer has ended (pready=1'b1) and there are masters that lost the arbitration. Generate a single logic-low penable to comply with APB protocol.
        o_paddr<=i_paddr_m0;
        o_pwrite<=i_pwrite_m0;
        o_psel<=i_psel_m0;
        o_penable<=1'b0;
        o_pwdata<=i_pwdata_m0;  

        case (i_psel_m0)
        3'b001: begin
          o_prdata<=i_prdata_s0;
          o_pready<=i_pready_s0;
          o_pslverr<=i_pslverr_s0;	
        end
        3'b010: begin
          o_prdata<=i_prdata_s1;
          o_pready<=i_pready_s1;
          o_pslverr<=i_pslverr_s1;	
        end
        3'b100: begin
          o_prdata<=i_prdata_s2;
          o_pready<=i_pready_s2;
          o_pslverr<=i_pslverr_s2;
        end
      endcase

    end
    else begin
      o_paddr<=i_paddr_m0;
      o_pwrite<=i_pwrite_m0;
      o_psel<=i_psel_m0;
      o_penable<=i_penable_m0;
      o_pwdata<=i_pwdata_m0; 

      case (i_psel_m0)
      3'b001: begin
        o_prdata<=i_prdata_s0;
        o_pready<=i_pready_s0;
        o_pslverr<=i_pslverr_s0;	
      end
      3'b010: begin
        o_prdata<=i_prdata_s1;
        o_pready<=i_pready_s1;
        o_pslverr<=i_pslverr_s1;	
      end
      3'b100: begin
        o_prdata<=i_prdata_s2;
        o_pready<=i_pready_s2;
        o_pslverr<=i_pslverr_s2;
      end
      endcase
end

    3'b010:                                               //Master 1 has won the arbitration
      if ((end_of_transfer==1'b1)&&(|request_vec)) begin  //If a transfer has ended (pready=1'b1) and there are masters that lost the arbitration. Generate a single logic-low penable to comply with APB protocol.
        o_paddr<=i_paddr_m1;
        o_pwrite<=i_pwrite_m1;
        o_psel<=i_psel_m1;
        o_penable<=1'b0;
        o_pwdata<=i_pwdata_m1;  

        case (i_psel_m1)
        3'b001: begin
          o_prdata<=i_prdata_s0;
          o_pready<=i_pready_s0;
          o_pslverr<=i_pslverr_s0;	
        end
        3'b010: begin
          o_prdata<=i_prdata_s1;
          o_pready<=i_pready_s1;
          o_pslverr<=i_pslverr_s1;	
        end
        3'b100: begin
          o_prdata<=i_prdata_s2;
          o_pready<=i_pready_s2;
          o_pslverr<=i_pslverr_s2;
        end
      endcase
end 
  
  else begin
      o_paddr<=i_paddr_m1;
      o_pwrite<=i_pwrite_m1;
      o_psel<=i_psel_m1;
      o_penable<=i_penable_m1;
      o_pwdata<=i_pwdata_m1; 

      case (i_psel_m1)
      3'b001: begin
        o_prdata<=i_prdata_s0;
        o_pready<=i_pready_s0;
        o_pslverr<=i_pslverr_s0;	
      end
      3'b010: begin
        o_prdata<=i_prdata_s1;
        o_pready<=i_pready_s1;
        o_pslverr<=i_pslverr_s1;	
      end
      3'b100: begin
        o_prdata<=i_prdata_s2;
        o_pready<=i_pready_s2;
        o_pslverr<=i_pslverr_s2;
      end
      endcase
    end

    3'b100:                                                 //Master 2 has won the arbitration
      if ((end_of_transfer==1'b1)&&(|request_vec)) begin    //If a transfer has ended (pready=1'b1) and there are masters that lost the arbitration. Generate a single logic-low penable to comply with APB protocol.
        o_paddr<=i_paddr_m2;
        o_pwrite<=i_pwrite_m2;
        o_psel<=i_psel_m2;
        o_penable<=1'b0;
        o_pwdata<=i_pwdata_m2;  

      case (i_psel_m2)
      3'b001: begin
        o_prdata<=i_prdata_s0;
        o_pready<=i_pready_s0;
        o_pslverr<=i_pslverr_s0;	
      end
      3'b010: begin
        o_prdata<=i_prdata_s1;
        o_pready<=i_pready_s1;
        o_pslverr<=i_pslverr_s1;	
      end
      3'b100: begin
        o_prdata<=i_prdata_s2;
        o_pready<=i_pready_s2;
        o_pslverr<=i_pslverr_s2;
      end
      endcase
    end 
    else begin
      o_paddr<=i_paddr_m2;
      o_pwrite<=i_pwrite_m2;
      o_psel<=i_psel_m2;
      o_penable<=i_penable_m2;
      o_pwdata<=i_pwdata_m2;

      case (i_psel_m2)
      3'b001: begin
        o_prdata<=i_prdata_s0;
        o_pready<=i_pready_s0;
        o_pslverr<=i_pslverr_s0;	
      end
      3'b010: begin
        o_prdata<=i_prdata_s1;
        o_pready<=i_pready_s1;
        o_pslverr<=i_pslverr_s1;	
      end
      3'b100: begin
        o_prdata<=i_prdata_s2;
        o_pready<=i_pready_s2;
        o_pslverr<=i_pslverr_s2;
      end
      endcase
    end

    endcase
  end

assign request_vec={|i_psel_m2,|i_psel_m1,|i_psel_m0};     //Request vector. Values are determined by the masters wishing to get access to the bus

//arbiter instantiation
arbiter #(.MASTER_COUNT(MASTER_COUNT), .SLAVE_COUNT(SLAVE_COUNT)) A0(.i_clk(i_pclk),
                                                                     .i_rst(i_prstn),
                                                                     .i_request_vec(request_vec),
                                                                     .i_update(o_pready),
                                                                     .o_gnt(o_gnt),
                                                                     .o_end_of_transfer(end_of_transfer)
);
endmodule

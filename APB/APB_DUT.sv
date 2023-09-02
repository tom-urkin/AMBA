//APB DUT

module APB_DUT(i_prstn,i_pclk,
i_start_0,i_rw_0,i_data_in_0,i_addr_rand_0,i_slave_rand_0,o_data_out_m0,o_transfer_status_m0,o_valid_m0,o_ready_m0,
i_start_1,i_rw_1,i_data_in_1,i_addr_rand_1,i_slave_rand_1,o_data_out_m1,o_transfer_status_m1,o_valid_m1,o_ready_m1,
i_start_2,i_rw_2,i_data_in_2,i_addr_rand_2,i_slave_rand_2,o_data_out_m2,o_transfer_status_m2,o_valid_m2,o_ready_m2,
o_gnt);

//Parameters
parameter DATA_WIDTH = 32;                                           //Data bus width
parameter ADDR_WIDTH = 32;                                           //Address bus width
parameter REG_NUM = 5;                                               //Number of registers within a slave equals 2^REG_NUM. Address span within a given slave equals 2**REG_NUM [REG_NUM-1:0]
parameter MASTER_COUNT = 3;                                          //Maximum allowed number of masters
parameter SLAVE_COUNT=3;                                             //Number of slaves on the bus

localparam WORD_LEN = $clog2(DATA_WIDTH>>3);                         //Number of bits requried to specify a given byte within a word. Example: for 32-bit word 2 bits are needed for byte0-byte3. These are the LSBs of the address which are zeros in normal operation (access is word-based)
localparam ADDR_MSB_len = ADDR_WIDTH-WORD_LEN-REG_NUM;               //Part of the address bus used to select a slave unit. Address span for the salves equals 2**ADDR_MSB_len-1 

parameter [ADDR_MSB_len-1:0] ADDR_SLAVE_0 = 0;                       //Address of slave_0
parameter [ADDR_MSB_len-1:0] ADDR_SLAVE_1= 1;                        //Address of slave_1
parameter [ADDR_MSB_len-1:0] ADDR_SLAVE_2= 2;                        //Address of slave_2

//Inputs
input logic i_prstn;                                                 //APB reset
input logic i_pclk;                                                  //System's clock

input logic i_start_0;                                               //Read/Write transer is initiated if the 'start' signal is logic high upon positive edge of clk
input logic i_rw_0;                                                  //Dictates transfer direction. '1' for Master-->Slave (write) and '0' for Slave-->Master (read)
input logic [DATA_WIDTH-1:0] i_data_in_0;                            //Randomized data to be written by a Master to a Slave
input logic [REG_NUM-1:0] i_addr_rand_0;                             //Selects one of the registers in of a slave unit
input logic [ADDR_MSB_len-1:0] i_slave_rand_0;                       //Randomized slave to be accessed by master 0

input logic i_start_1;                                               //Read/Write transer is initiated if the 'start' signal is logic high upon positive edge of clk
input logic i_rw_1;                                                  //Dictates transfer direction. '1' for Master-->Slave (write) and '0' for Slave-->Master (read)
input logic [DATA_WIDTH-1:0] i_data_in_1;                            //Randomized data to be written by a Master to a Slave
input logic [REG_NUM-1:0] i_addr_rand_1;                             //Selects one of the registers in of a slave unit
input logic [ADDR_MSB_len-1:0] i_slave_rand_1;                       //Randomized slave to be accessed by master 1

input logic i_start_2;                                               //Read/Write transer is initiated if the 'start' signal is logic high upon positive edge of clk
input logic i_rw_2;                                                  //Dictates transfer direction. '1' for Master-->Slave (write) and '0' for Slave-->Master (read)
input logic [DATA_WIDTH-1:0] i_data_in_2;                            //Randomized data to be written by a Master to a Slave
input logic [REG_NUM-1:0] i_addr_rand_2;                             //Selects one of the registers in of a slave unit
input logic [ADDR_MSB_len-1:0] i_slave_rand_2;                       //Randomized slave to be accessed by master 2

//Internal signals
logic [ADDR_WIDTH-1:0] paddr_m0;                                     //Peripheral address bus on the master side of the interconnect fabric
logic pwrite_m0;                                                     //Peripheral transfer direction on the master side of the interconnect fabric
logic [SLAVE_COUNT-1:0] psel_m0;                                     //Peripheral slave select on the master side of the interconnect fabric
logic penable_m0;                                                    //Peripheral enable on the master side of the interconnect fabric
logic [DATA_WIDTH-1:0] pwdata_m0;                                    //Peripheral write data bus on the master side of the interconnect fabric

logic [ADDR_WIDTH-1:0] paddr_m1;                                     //Peripheral address bus on the master side of the interconnect fabric
logic pwrite_m1;                                                     //Peripheral transfer direction on the master side of the interconnect fabric
logic [SLAVE_COUNT-1:0] psel_m1;                                     //Peripheral slave select on the master side of the interconnect fabric
logic penable_m1;                                                    //Peripheral enable on the master side of the interconnect fabric
logic [DATA_WIDTH-1:0] pwdata_m1;                                    //Peripheral write data bus on the master side of the interconnect fabric

logic [ADDR_WIDTH-1:0] paddr_m2;                                     //Peripheral address bus on the master side of the interconnect fabric
logic pwrite_m2;                                                     //Peripheral transfer direction on the master side of the interconnect fabric
logic [SLAVE_COUNT-1:0] psel_m2;                                     //Peripheral slave select on the master side of the interconnect fabric
logic penable_m2;                                                    //Peripheral enable on the master side of the interconnect fabric
logic [DATA_WIDTH-1:0] pwdata_m2;                                    //Peripheral write data bus on the master side of the interconnect fabric

logic [DATA_WIDTH-1:0] prdata_m;                                     //Peripheral read data bus on the master side of the interconnect fabric
logic pready_m;                                                      //Ready signal. A slave may use this signal to extend an APB transfer
logic pslverr_m;                                                     //pslverr signal indicates a transfer failure

logic [ADDR_WIDTH-1:0] paddr_s;                                      //Peripheral address bus on the slave side of the interconnect fabric
logic pwrite_s;                                                      //Peripheral transfer direction on the slave side of the interconnect fabric
logic [SLAVE_COUNT-1:0] psel_s;                                      //Peripheral slave select on the slave side of the interconnect fabric
logic penable_s;                                                     //Peripheral enable on the slave side of the interconnect fabric
logic [DATA_WIDTH-1:0] pwdata_s;                                     //Peripheral write data bus on the slave side of the interconnect fabric

logic [DATA_WIDTH-1:0] prdata_s0;                                    //Peripheral read data bus on the slave side of the interconnect fabric
logic pready_s0;                                                     //Ready signal. A slave may use this signal to extend an APB transfer
logic pslverr_s0;                                                    //pslverr signal indicates a transfer failure

logic [DATA_WIDTH-1:0] prdata_s1;                                    //Peripheral read data bus on the slave side of the interconnect fabric
logic pready_s1;                                                     //Ready signal. A slave may use this signal to extend an APB transfer
logic pslverr_s1;                                                    //pslverr signal indicates a transfer failure

logic [DATA_WIDTH-1:0] prdata_s2;                                    //Peripheral read data bus on the slave side of the interconnect fabric
logic pready_s2;                                                     //Ready signal. A slave may use this signal to extend an APB transfer
logic pslverr_s2;                                                    //pslverr signal indicates a transfer failure

//Outputs // MAYBE ADD A SIGNAL INDICATING TRANSFER FAILURE
output logic [DATA_WIDTH-1:0] o_data_out_m0;                         //Received data from one of the slaves as sampled by master #0 following a valid read command
output logic o_transfer_status_m0;                                   //Communication status of master #0. '1' if transfer failed, '0' otherwise
output logic o_valid_m0;                                             //Indicates the validity of the output data. logic high for 'valid' data
output logic o_ready_m0;                                             //'ready' signal. New read/write commands cannot be issued if the bus is busy

output logic [DATA_WIDTH-1:0] o_data_out_m1;                         //Received data from one of the slaves as sampled by master #0 following a valid read command
output logic o_transfer_status_m1;                                   //Communication status of master #0. '1' if transfer failed, '0' otherwise
output logic o_valid_m1;                                             //Indicates the validity of the output data. logic high for 'valid' data
output logic o_ready_m1;                                             //'ready' signal. New read/write commands cannot be issued if the bus is busy

output logic [DATA_WIDTH-1:0] o_data_out_m2;                         //Received data from one of the slaves as sampled by master #0 following a valid read command
output logic o_transfer_status_m2;                                   //Communication status of master #0. '1' if transfer failed, '0' otherwise
output logic o_valid_m2;                                             //Indicates the validity of the output data. logic high for 'valid' data
output logic o_ready_m2;                                             //'ready' signal. New read/write commands cannot be issued if the bus is busy

output logic [MASTER_COUNT-1:0] o_gnt;                               //grant vector details the active master (one-hot encoded)

//HDL code

//APB msater instantiation
APB_Master #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(ADDR_WIDTH), .SLAVE_COUNT(SLAVE_COUNT), .ADDR_MSB_len(ADDR_MSB_len), .ADDR_SLAVE_0(ADDR_SLAVE_0), .ADDR_SLAVE_1(ADDR_SLAVE_1), .ADDR_SLAVE_2(ADDR_SLAVE_2)) M0(
                .i_prstn(i_prstn),                                                           
                .i_pclk(i_pclk),      

                .i_command(i_rw_0),                                                                     
                .i_start(i_start_0),                                                           
                .i_data_in(i_data_in_0),                                                                       
                .i_addr_in({i_slave_rand_0,i_addr_rand_0,{WORD_LEN{1'b0}}}),  //Access is word-based. For 32-bit word and 32 registers in each salve: {000...000||XXXXX||00}
                
                .i_prdata(prdata_m&{DATA_WIDTH{o_gnt[0]}}),                                                        
                .i_pready(pready_m&o_gnt[0]),   
                .i_pslverr(pslverr_m&o_gnt[0]),
                
                .o_paddr(paddr_m0),                                                          
                .o_pwrite(pwrite_m0),                                                        
                .o_psel(psel_m0),                                                            
                .o_penable(penable_m0),                                                      
                .o_pwdata(pwdata_m0),                                                        
                .o_data_out(o_data_out_m0),
                .o_transfer_status(o_transfer_status_m0),
                .o_valid(o_valid_m0),
                .o_ready(o_ready_m0)
                );


APB_Master #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(ADDR_WIDTH), .SLAVE_COUNT(SLAVE_COUNT), .ADDR_MSB_len(ADDR_MSB_len), .ADDR_SLAVE_0(ADDR_SLAVE_0), .ADDR_SLAVE_1(ADDR_SLAVE_1), .ADDR_SLAVE_2(ADDR_SLAVE_2)) M1(
                .i_prstn(i_prstn),                                                           
                .i_pclk(i_pclk),    

                .i_command(i_rw_1),                                                                     
                .i_start(i_start_1),                                                           
                .i_data_in(i_data_in_1),                                                                       
                .i_addr_in({i_slave_rand_1,i_addr_rand_1,{WORD_LEN{1'b0}}}),  //Access is word-based. For 32-bit word and 32 registers in each salve: {000...000||XXXXX||00}

                .i_prdata(prdata_m&{DATA_WIDTH{o_gnt[1]}}),                                                        
                .i_pready(pready_m&o_gnt[1]),   
                .i_pslverr(pslverr_m&o_gnt[1]),

                .o_paddr(paddr_m1),                                                          
                .o_pwrite(pwrite_m1),                                                        
                .o_psel(psel_m1),                                                            
                .o_penable(penable_m1),                                                      
                .o_pwdata(pwdata_m1),                                                        
                .o_data_out(o_data_out_m1),
                .o_transfer_status(o_transfer_status_m1),
                .o_valid(o_valid_m1),
                .o_ready(o_ready_m1)
                );

APB_Master #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(ADDR_WIDTH), .SLAVE_COUNT(SLAVE_COUNT), .ADDR_MSB_len(ADDR_MSB_len), .ADDR_SLAVE_0(ADDR_SLAVE_0), .ADDR_SLAVE_1(ADDR_SLAVE_1), .ADDR_SLAVE_2(ADDR_SLAVE_2)) M2(
                .i_prstn(i_prstn),                                                           
                .i_pclk(i_pclk),    

                .i_command(i_rw_2),                                                                     
                .i_start(i_start_2),                                                           
                .i_data_in(i_data_in_2),                                                                       
                .i_addr_in({i_slave_rand_2,i_addr_rand_2,{WORD_LEN{1'b0}}}),  //Access is word-based. For 32-bit word and 32 registers in each salve: {000...000||XXXXX||00}

                .i_prdata(prdata_m&{DATA_WIDTH{o_gnt[2]}}),                                                        
                .i_pready(pready_m&o_gnt[2]),   
                .i_pslverr(pslverr_m&o_gnt[2]),

                .o_paddr(paddr_m2),                                                          
                .o_pwrite(pwrite_m2),                                                        
                .o_psel(psel_m2),                                                            
                .o_penable(penable_m2),                                                      
                .o_pwdata(pwdata_m2),                                                        
                .o_data_out(o_data_out_m2),
                .o_transfer_status(o_transfer_status_m2),
                .o_valid(o_valid_m2),
                .o_ready(o_ready_m2)
                );

//APB slave instantiation
APB_Slave #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(ADDR_WIDTH), .REG_NUM(REG_NUM), .WAIT_WRITE(1), .WAIT_READ(2)) S0(
                .i_prstn(i_prstn),                                                           
                .i_pclk(i_pclk),                                                             
                .i_paddr(paddr_s),                                                                   
                .i_pwrite(pwrite_s),                                                        
                .i_psel(psel_s[0]),                                                                            
                .i_penable(penable_s),                                                      
                .i_pwdata(pwdata_s),                                                         
                .o_prdata(prdata_s0),                                                        
                .o_pready(pready_s0),                                                        
                .o_pslverr(pslverr_s0)
                );

APB_Slave #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(ADDR_WIDTH), .REG_NUM(REG_NUM), .WAIT_WRITE(1), .WAIT_READ(2)) S1(
                .i_prstn(i_prstn),                                                           
                .i_pclk(i_pclk),                                                             
                .i_paddr(paddr_s),                                                                   
                .i_pwrite(pwrite_s),                                                        
                .i_psel(psel_s[1]),                                                                            
                .i_penable(penable_s),                                                      
                .i_pwdata(pwdata_s),                                                         
                .o_prdata(prdata_s1),                                                        
				.o_pready(pready_s1),                                                        
				.o_pslverr(pslverr_s1)
                );

APB_Slave #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(ADDR_WIDTH), .REG_NUM(REG_NUM), .WAIT_WRITE(1), .WAIT_READ(2)) S2(
                .i_prstn(i_prstn),                                                           
                .i_pclk(i_pclk),                                                             
                .i_paddr(paddr_s),                                                                   
                .i_pwrite(pwrite_s),                                                        
                .i_psel(psel_s[2]),                                                                            
                .i_penable(penable_s),                                                      
                .i_pwdata(pwdata_s),                                                         
                .o_prdata(prdata_s2),                                                        
                .o_pready(pready_s2),                                                        
                .o_pslverr(pslverr_s2)
                );

//Interconnect fabric instantiation
apb_interconnect_fabric #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(ADDR_WIDTH), .MASTER_COUNT(MASTER_COUNT), .SLAVE_COUNT(SLAVE_COUNT)) f0(
                .i_prstn(i_prstn),                                                           
                .i_pclk(i_pclk),                                                             
 
                .i_paddr_m0(paddr_m0),                                                                   
                .i_pwrite_m0(pwrite_m0),                                                        
                .i_psel_m0(psel_m0),                                                                            
                .i_penable_m0(penable_m0),                                                      
                .i_pwdata_m0(pwdata_m0),    

                .i_paddr_m1(paddr_m1),                                                                   
                .i_pwrite_m1(pwrite_m1),                                                        
                .i_psel_m1(psel_m1),                                                                            
                .i_penable_m1(penable_m1),                                                      
                .i_pwdata_m1(pwdata_m1),    

                .i_paddr_m2(paddr_m2),                                                                   
                .i_pwrite_m2(pwrite_m2),                                                        
                .i_psel_m2(psel_m2),                                                                            
                .i_penable_m2(penable_m2),                                                      
                .i_pwdata_m2(pwdata_m2), 

                .i_prdata_s0(prdata_s0),                                                        		
                .i_pready_s0(pready_s0),
                .i_pslverr_s0(pslverr_s0),

                .i_prdata_s1(prdata_s1),                                                        		
                .i_pready_s1(pready_s1),
                .i_pslverr_s1(pslverr_s1),

                .i_prdata_s2(prdata_s2),                                                        		
                .i_pready_s2(pready_s2),
                .i_pslverr_s2(pslverr_s2),

                .o_paddr(paddr_s),                                                                   
                .o_pwrite(pwrite_s),                                                        
                .o_psel(psel_s),                                                                            
                .o_penable(penable_s),                                                      
                .o_pwdata(pwdata_s),

                .o_prdata(prdata_m),                                                        	
                .o_pready(pready_m),
                .o_pslverr(pslverr_m),

                .o_gnt(o_gnt)
);

endmodule

//----------------------------------------------------------------------
//                                                                     
// Description: write requests counter of Bank scheduler in the memory controller                   
//              
//          
// Functionality: Trace the current number of write requests in the bank scheduler            
//----------------------------------------------------------------------

module cntr_bs_cnt
#(
    parameter WR_FIFO_NUM  = 3,
    parameter WR_FIFO_SIZE = 2,
    parameter READ = 1'b0 ,
    parameter WRITE = 1'b1 
)
(
   clk,     // Input clock
   rst_n,   // Synchronous reset  
   t_i,     // Input type from txn controller/bank scheeduler fifo
   t_o,     // Input type of output from scheduler to Arbiter
   wr_valid,// Input successful push to scheduler fifo
   rd_valid,// Input successful pop from scheduler fifo
   wr_cnt   // Output Number of write requests in the scheduler to controller mode
); 

//*****************************************************************************
// Parameters definitions                                                                
//*****************************************************************************  
  localparam WR_BITS  = $clog2(WR_FIFO_SIZE * WR_FIFO_NUM) ; 


//*****************************************************************************
// Ports declarations                                                             
//*****************************************************************************    
  input wire                   clk;      // Input clock
  input wire                   rst_n;    // Synchronous reset           
  input wire                   t_i;      // Input type from txn controller/bank scheeduler fifo
  input wire                   t_o;      // Input type of output from scheduler to Arbiter
  input wire                   wr_valid; // Input successful writing to scheduler fifo
  input wire                   rd_valid; // Input successful reading from scheduler fifo     
  output reg [WR_BITS  -1 : 0] wr_cnt;   // Number of write requests in the scheduler to controller mode
             

always@(posedge clk) begin //update write requests counter
    if(!rst_n) begin
        wr_cnt <= 0;
    end
    else begin
        casex ( { {t_i   , wr_valid } , {t_o   , rd_valid}  }) 
            { {WRITE , 1'b1} , {READ , 1'b1} } , { {WRITE , 1'b1} , {1'bx , 1'b0} } : wr_cnt <= wr_cnt+1;
            { {READ  , 1'b1} , {WRITE , 1'b1} }, { {1'bx  , 1'b0} , {WRITE , 1'b1} } : wr_cnt <= wr_cnt-1;
            default : wr_cnt <= wr_cnt;
        endcase 
    end
end


endmodule
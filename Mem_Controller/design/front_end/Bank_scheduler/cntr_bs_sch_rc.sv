//----------------------------------------------------------------------
//                                                                     
// Description: inner read index counter in scheduler part of top bank scheduler module                   
//              of the controller
//          
// Functionality: compute next proper fifo index to be used satisfying the empty signal.
//                It loops over fifos in a round robin fashion, but since we may 
//                get next fifo as empty, we should keep in mind that is not.
//
//
// Modifications: changing number of fifos requires editing both the local parameters and
//                output block
//
//----------------------------------------------------------------------
/*module cntr_bs_sch_rc(   
   clk,      // Input clock
   rst_n,    // Synchronous reset                                    -> active low
   start,    // Input start signal to increment the out              -> active high
   valid,    // Input valid signals to help choose proper next out 
   idx       // Output idx value
);

//*****************************************************************************
// Parameters definitions                                                                
//*****************************************************************************  
  parameter FIFO_NUM = 2'h4;            // Number of fifos to loop over


 // States of counter fsm
  localparam [1:0] ZERO  = 2'b00 ;   
  localparam [1:0] ONE   = 2'b01 ;
  localparam [1:0] TWO   = 2'b10 ;
  localparam [1:0] THREE = 2'b11 ;
//*****************************************************************************
// Ports declarations                                                             
//*****************************************************************************    
  input wire                        clk;         // Input clock
  input wire                        rst_n;       // Synchronous reset                                    -> active low
  input wire                        start;       // Input start signal to increment the out              -> active high
  input wire [FIFO_NUM-1        :0] valid,    // Input valid signals to help choose proper next out 
  output     [$clog2(FIFO_NUM)-1:0] idx ;        // Output counter value



//*****************************************************************************
// Internal signals declarations                                                             
//*****************************************************************************    
  reg [$clog2(FIFO_NUM)-1:0] CS; // current index 
  reg [$clog2(FIFO_NUM)-1:0] NS; // Next index 
  
  
  assign idx = CS ; 
//*****************************************************************************
// Update the fsm                                                           
//*****************************************************************************    
always @(posedge clk)begin
    if(!rst_n)begin
        CS <= THREE;  //Three is suitable start value in order not to miss ZERO in initial state and fifos are filled in ascending order.
    end
    else begin
        CS <= NS ;
    end
end


//*****************************************************************************
// Compute next state and output                                                      
//*****************************************************************************   
always @(*) begin
   NS  = CS ;
   case(CS) 
      ZERO :begin
         casex({start,valid})
            {1'b1,4'bxx1x}  : NS = ONE;
            {1'b1,4'bx1xx}  : NS = TWO;
            {1'b1,4'b1xxx}  : NS = THREE; 
            {1'b1,4'bxxx1}  : NS = ZERO;   
         endcase
      ONE :begin
         casex({start,valid}) 
            {1'b1,4'bx1xx}  : NS = TWO;
            {1'b1,4'b1xxx}  : NS = THREE;
            {1'b1,4'bxxx1}  : NS = ZERO;
            {1'b1,4'bxx1x}  : NS = ONE;                
         endcase
      TWO :begin
         casex({start,valid})
            {1'b1,4'b1xxx}  : NS = THREE; 
            {1'b1,4'bxxx1}  : NS = ZERO; 
            {1'b1,4'bxx1x}  : NS = ONE;
            {1'b1,4'bx1xx}  : NS = TWO;                             
         endcase
      THREE :begin
         casex({start,valid}) 
            {1'b1,4'bxxx1}  : NS = ZERO;   
            {1'b1,4'bxx1x}  : NS = ONE;
            {1'b1,4'bx1xx}  : NS = TWO;
            {1'b1,4'b1xxx}  : NS = THREE;
         endcase
      end
         
   endcase

endmodule*/
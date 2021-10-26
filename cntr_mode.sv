//----------------------------------------------------------------------
//                                                                     
// Description: Controller mode module                   
//              
//          
// Functionality: This module determines controller draining mode, either read or write. 
//                It applies a threshold on total number of write requests to chec the High/Low watermark.
//----------------------------------------------------------------------

module cntr_mode
#(
    parameter WR_FIFO_SIZE = 4,
    parameter WR_FIFO_NUM = 3,
    parameter READ = 1'b0,
    parameter WRITE = 1'b1
)
(
   clk,       // Input clock
   rst_n,     // Synchronous reset 
   rd_empty,  // Input empty signal for read requests for each bank 
   num,       // Input number of write requests for each bank
   mode       // Output controller mode
); 

//*****************************************************************************
// Parameters definitions                                                                
//*****************************************************************************  
  // we use 7 bits as our upper bound of total requests is 16 bank * 6 
  parameter LOW_WM  = 7'd32;  //low watermark 30% of total write requests.
  parameter HIGH_WM = 7'd64;  //high watermark 60% of total write requests.

  //parameter LOW_WM  = 7'd3;  //low watermark 30% of total write requests.
  //parameter HIGH_WM = 7'd6;  //high watermark 60% of total write requests.

  localparam WR_BITS  = $clog2(WR_FIFO_SIZE * WR_FIFO_NUM) ; 

//*****************************************************************************
// Ports declarations                                                             
//*****************************************************************************    
  input wire                          clk;      // Input clock
  input wire                          rst_n;    // Synchronous reset           
  input wire [15 : 0]                 rd_empty; // Input empty signal for read requests for each bank
  input wire [15 : 0] [WR_BITS -1 :0] num;      // Input number of write requests for each bank
  output reg                          mode;     // Output controller mode


//*****************************************************************************
// Internal signals declarations                                           
//*****************************************************************************  
reg [6:0] wr_cnt;
wire hwm , lwm;
assign {hwm , lwm} = {wr_cnt >= HIGH_WM  , wr_cnt <= LOW_WM} ;
integer i ; 


// FSM states
  enum reg  { READ_MODE, WRITE_MODE } CS, NS;

//*****************************************************************************
// compute total write requests                                        
//***************************************************************************** 
always @ (*) begin
  wr_cnt = 7'd0;
  for(i =0 ;i<16 ; i++)
    wr_cnt = wr_cnt + num[i];
end

//*****************************************************************************
// Update the FSM                                                  
//***************************************************************************** 
always @(posedge clk)begin
    if(!rst_n) begin
        CS <= READ_MODE;
    end
    else begin
        CS  <= NS ;
    end
end

//*****************************************************************************
// Compute Next State and outputs                                        
//***************************************************************************** 
always @(*) begin
    NS = CS ;
    mode = READ;
    case(CS) 
        READ_MODE :begin
            mode = READ;
            if (hwm == 1'b1 || (lwm == 1'b1 && &rd_empty == 1'b1) ) //high watermark or low watermark with no read requests available
              NS = WRITE_MODE ;
        end
        WRITE_MODE :begin
            mode = WRITE;
            if (lwm == 1'b1 && &rd_empty == 1'b0 ) // switch to read in case of it is lwm and at least there is one read request
              NS = READ_MODE ;
        end           
    endcase
end


endmodule

module back_end import types_def::*;
#(
  parameter no_of_bursts  = 4,
  parameter IDX          = 6,
  parameter RA           = 16,
  parameter CA_           = 10 , //parameter CA= 10 , but we have output port with same name :(
  parameter DQ_          = 16   //parameter DQ= 16 , but we have output port with same name :(
)
(  
    input clk,    
    input rst_n,  
    
    //arbiter inputs
    input [15:0] valid_i , // from schedulers
    input  [(16 * DQ_) -1 :0] data_i ,
    input  [(IDX*16) -1 :0 ] idx_i ,
    input  [(RA*16)    -1 :0 ] row_i ,
    input  [(CA_*16)    -1 :0 ] col_i ,
    input  [16 -1 :0 ] t_i ,

    //arbiter output 
    output [15:0] ready , 
    // burst handler outputs to returner
    output logic returner_valid,
    output r_type returner_type,
    output logic [data_width-1:0] returner_data,
    output logic [read_entries_log -1:0] returner_index,

    // memory interface
   
    output logic CS_n                ,// Chip Select -> active low
    output logic [13:0] CA           ,// Command / Address Port   
    output logic CAI                 ,// Command / Address inversion
    output logic [2:0] DM_n          ,// Data Mask -> byte based 
    inout [data_width-1:0] DQ  ,// Data Port  
    inout [2:0] DQS_t , DQS_c  ,// Data Strobes (diff pair) // ~Data Strobes (diff pair)
    inout ALERT_n               // CRC/Parity error flag

);

    // intemediate signals between arbiter and burst handler
    wire   [DQ_-1  : 0 ] data_o ;
    wire   [IDX-1 : 0 ] idx_o ;
    wire   [RA-1    : 0 ] row_o ;
    wire   [CA_-1    : 0 ] col_o ;
    wire                       t_o;
    wire [1:0] ba_o , bg_o           ;
    wire wr_en ; //enable write to burst handler

    // intemediate signals between burst handler and timing controller
     burst_states_type [no_of_bursts-1:0] burst_state; // started_filling ,almost_done , full , empty , returning_data
     r_type [no_of_bursts-1:0] burst_type;

    logic [no_of_bursts-1:0] [1:0] burst_address_bank;
    logic [no_of_bursts-1:0] [1:0] burst_address_bg;
    logic [no_of_bursts-1:0] [15:0] burst_address_row;

    command burst_cmd_o;   // start cmd 
    wire [$clog2(no_of_bursts)-1:0] cmd_index_o;
    wire   start_new_burst;


Arbiter #(.IDX(IDX),.RA(RA),.CA(CA_),.DQ(DQ_)) arbiter
(
    .clk(clk),
    .rst_n(rst_n),
     .valid(valid_i),
      .flag(start_new_burst), 
      .data_i(data_i) ,
      .idx_i(idx_i) ,
      .row_i(row_i) ,
    .col_i(col_i) ,
    .t_i(t_i),
      .data_o(data_o) ,
      .idx_o(idx_o)  ,
      .row_o(row_o)  ,
       .col_o(col_o)  ,
      .t_o(t_o),
    .ba_o(ba_o) ,
    .bg_o(bg_o),
     .wr_en(wr_en),
     .ready(ready)
);



burst_handler #(.no_of_bursts(no_of_bursts))  the_handler  (.clk(clk),.rst_n(rst_n),.out_burst_state(burst_state),.out_burst_type(burst_type),
    .out_burst_address_bank(burst_address_bank),
    .out_burst_address_bg(burst_address_bg),
    .out_burst_address_row(burst_address_row),
    .in_burst_cmd(burst_cmd_o),
    .in_cmd_index(cmd_index_o),
    .start_new_burst(start_new_burst),
    .arbiter_valid(wr_en),
    .in_req_address({bg_o,ba_o,row_o,col_o}),
    .arbiter_data(data_o),
    .arbiter_index(idx_o),
    .arbiter_type_temp(t_o),
    .returner_valid(returner_valid),
    .returner_type(returner_type),
    .returner_data(returner_data),
    .returner_index(returner_index),
    .CS_n,.CA,.CAI,.DM_n,.DQ,.DQS_t,.DQS_c,.ALERT_n);

timing_controller#(.no_of_bursts(no_of_bursts) )the_timing_controller
 (
  .clk(clk),
  .rst_n(rst_n),
  .in_burst_state(burst_state),
  .in_burst_type(burst_type),
  .in_burst_address_bank(burst_address_bank),
  .in_burst_address_bg(burst_address_bg),
  .in_burst_address_row(burst_address_row),
  .burst_cmd_o(burst_cmd_o),
  .cmd_index_o(cmd_index_o)
 );

/*
// testing blocks

logic [40:0] no_precharges;
logic [40:0] total_no_bursts;

always_ff @(posedge clk ) begin 
  if(rst_n) begin
    if (burst_cmd_o == precharge) begin
      no_precharges <= no_precharges +1;
    end
    if (burst_cmd_o == read_cmd || burst_cmd_o == write_cmd) begin
      total_no_bursts <= total_no_bursts +1;
    end
  end 
  else begin
    no_precharges <= 0;
    total_no_bursts <= 0;
  end
end
*/

endmodule

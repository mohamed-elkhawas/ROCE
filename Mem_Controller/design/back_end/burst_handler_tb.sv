module burst_handler_tb  import types_def::*; ();


parameter no_of_bursts  = 4;


logic test;



logic clk,    // Clock
	 rst_n;  // synchronous reset active low

	//////////////////////////////////////////////////////////////// timing_controller
	 burst_states_type [no_of_bursts-1:0] out_burst_state;
	 r_type [no_of_bursts-1:0] out_burst_type;

	 logic [1:0] [no_of_bursts-1:0] out_burst_address_bank;
	 logic [1:0] [no_of_bursts-1:0] out_burst_address_bg;
	 logic [15:0] [no_of_bursts-1:0] out_burst_address_row;
	 command in_burst_cmd;
	 logic [$clog2(no_of_bursts)-1:0] in_cmd_index;
	
	/////////////////////////////////////////////////////////////// banks arbiter
	 logic start_new_burst;

	logic arbiter_valid;
	 address_type in_req_address;
	logic [data_width -1:0] arbiter_data;
	logic [read_entries_log -1:0] arbiter_index;
	logic arbiter_type_temp;
	
	/////////////////////////////////////////////////////////////// memory interface
	 logic CS_n                ;// Chip Select -> active low
	 logic [13:0] CA           ;// Command / Address Port   
	 logic CAI                 ;// Command / Address inversion
	 logic [2:0] DM_n          ;// Data Mask -> byte based 
	wire [data_width-1:0] DQ  ;// Data Port  
	wire [2:0] DQS_t , DQS_c ;// Data Strobes (diff pair) // ~Data Strobes (diff pair)
 	wire ALERT_n              ; // CRC/Parity error flag

	/////////////////////////////////////////////////////////////// returner interface
	 logic returner_valid;
	 r_type returner_type;
	 logic [data_width-1:0] returner_data;
	 logic [read_entries_log -1:0] returner_index;















burst_handler b (

.*
);



// Clock generator
  always
  begin
    #1 clk = 1;
    #1 clk = 0;
  end

initial begin 

	rst_n = 0;
	#10 
	@(posedge clk) 
	test=0;
	rst_n = 1;
	arbiter_valid=0;
	arbiter_type_temp = 0;
	in_req_address =0;
	arbiter_index =0;

	#11
	
	@(posedge clk)///////////////////read one burst two reqs
	arbiter_valid=1;
	in_req_address.column[3:0] =0;
	arbiter_index =0;
	@(posedge clk)
	in_req_address.column[3:0] =5;
	arbiter_index =2;
	@(posedge clk)
	arbiter_valid=0;

	@(posedge clk)///////////////////read
	arbiter_valid=1;
	@(posedge clk)
	arbiter_valid=0;

	@(posedge clk)///////////////////read
	arbiter_valid=1;
	@(posedge clk)///////////////////write
	arbiter_type_temp = 1;
	@(posedge clk)
	arbiter_valid=0;

	#100
	@(posedge clk)
	test=1;
	@(posedge clk)
	test=0;


	#100
	$stop;

end


endmodule

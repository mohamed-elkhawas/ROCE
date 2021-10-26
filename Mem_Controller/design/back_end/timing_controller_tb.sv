module timing_controller_tb import types_def::*; ();

parameter no_of_bursts = 4;

logic clk,rst_n;


	burst_states_type [no_of_bursts-1:0] in_burst_state; // started_filling ,almost_done , full , empty , returning_data
	r_type [no_of_bursts-1:0] in_burst_type;

	logic [no_of_bursts-1:0] [1:0] in_burst_address_bank;
	logic [no_of_bursts-1:0] [1:0] in_burst_address_bg;
	logic [no_of_bursts-1:0] [15:0] in_burst_address_row;

	command burst_cmd_o;	// start cmd 
	logic [$clog2(no_of_bursts)-1:0] cmd_index_o;



timing_controller t (.*);


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
	rst_n = 1;
	in_burst_state[0] =empty;
	in_burst_state[1] =empty;
	in_burst_state[2] =empty;
	in_burst_state[3] =empty;
	in_burst_type =0;
	in_burst_address_row = 0;
	in_burst_address_bg = 0;
	in_burst_address_bank = 0;

	#11
	

	#100
	@(posedge clk) 
	in_burst_state[0] = started_filling;

	@(posedge clk)
	in_burst_state[0] = full;

	@(posedge clk) 
	in_burst_state[1] = started_filling;
	in_burst_address_bank[1] = 0;
	in_burst_address_bg[1] = 0;

	@(posedge clk)
	in_burst_state[1] = full;

	@(posedge clk) 
	in_burst_state[2] = started_filling;
	in_burst_address_bank[2] = 1;
	in_burst_address_bg[2] = 0;

	@(posedge clk)
	in_burst_state[2] = full;

	@(posedge clk) 
	in_burst_state[3] = started_filling;
	in_burst_address_bank[3] = 2;
	in_burst_address_bg[3] = 1;
	
	in_burst_type[3] = write;

	@(posedge clk)
	in_burst_state[3] = full;



	#100 
	@(posedge clk)
	
	
	@(posedge clk)



	
	#100
	$stop;

end

endmodule

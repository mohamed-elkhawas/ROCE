module txn_controller import types_def::*;

#( parameter data_width = 32 )
 
 (
	input clk,    // Clock
	input rst_n,  // synchronous reset active low
	
//////////////////// the mapper \\\\\\\\\\\\\\\\\\\\\\\\\

	input in_valid, 	// from rnic
	input request in_request, // from rnic
	output logic out_busy, // to rnic

	output logic  valid_out, // to global array and over flow stopper

	output request out_req,// to global array
	output logic [read_entries_log -1:0] out_index,// to global array and to the bank {index , type ,row}

	input [15:0] in_busy, // from bank
	output logic  [15:0] bank_out_valid, // to bank 

///////////////////// the returner \\\\\\\\\\\\\\\\\\\\\\\\\
								  
	input request_done_valid,
	input the_type,
	input [ data_width -1  : 0 ] data_in,
	input [ read_entries_log -1 : 0 ] index,

	output logic write_done,
	output logic read_done,
	output logic  [ data_width -1 : 0 ] data_out
	
);


mapper input_controller (.clk(clk),.rst_n(rst_n),.in_valid(in_valid),.in_request(in_request),.out_busy(out_busy),.stop_reading(stop_reading) ,.stop_writing(stop_writing),.valid_out(valid_out),.out_req(out_req),.out_index(out_index),.in_busy(in_busy),.bank_out_valid(bank_out_valid));


returner #(.data_width(data_width)) output_controller (.clk(clk),.rst_n(rst_n),.valid(request_done_valid),.the_type(the_type),.data_in(data_in),.index(index),.write_done(write_done),.read_done(read_done),.data_out(data_out));


over_flow_stopper the_over_flow_stopper (.clk(clk),.rst_n(rst_n),.mapper_valid(valid_out),.the_req_type(out_req.req_type),.read_done(read_done),.write_done(write_done),.stop_reading(stop_reading),.stop_writing(stop_writing));


endmodule

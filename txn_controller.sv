module txn_controller import types_def::*;

#( parameter data_width = 16 )
 
 (
	input clk,    // Clock
	input rst_n,  // synchronous reset active low
	
//////////////////// the mapper \\\\\\\\\\\\\\\\\\\\\\\\\

	input in_valid, 	// from rnic
	input request in_request, // from rnic
	output logic out_busy2, // to rnic

	output opt_request out_req2,// to bank fifo
	output logic [read_entries_log -1:0] out_index2,// to the bank fifo

	input [15:0] fifo_grant_o, // from bank fifo
	output logic  [15:0] bank_out_valid2, // to bank fifo

///////////////////// the returner \\\\\\\\\\\\\\\\\\\\\\\\\
								  
	input request_done_valid,
	input the_type,
	input [ data_width -1  : 0 ] data_in,
	input [ read_entries_log -1 : 0 ] index,

	output logic write_done,
	output logic read_done,
	output logic  [ data_width -1 : 0 ] data_out
	
);

opt_request out_req;
logic [ read_entries_log -1 : 0 ] out_index;
logic  [15:0] bank_out_valid;

mapper input_controller (.clk(clk),.rst_n(rst_n),.in_valid(in_valid),.in_request(in_request),.out_busy_o(out_busy),.stop_reading((~grant_o2|stop_reading)) ,.stop_writing((~grant_o2|stop_writing)),.valid_out_o(valid_out),.out_req_o(out_req),.out_index_o(out_index),.in_busy(~fifo_grant_o),.bank_out_valid_o(bank_out_valid));


returner #(.data_width(data_width)) output_controller (.clk(clk),.rst_n(rst_n),.valid(request_done_valid),.the_type(the_type),.data_in(data_in),.index(index),.write_done(write_done),.read_done(read_done),.data_out(data_out));


over_flow_stopper the_over_flow_stopper (.clk(clk),.rst_n(rst_n),.mapper_valid(valid_out),.the_req_type(out_req.req_type),.read_done(read_done),.write_done(write_done),.stop_reading(stop_reading),.stop_writing(stop_writing));


request_saver the_request_saver (.clk(clk),.rst_n(rst_n),.request_i(out_req),.valid_i(bank_out_valid),.index_i(out_index),.grant_o2(grant_o2),.grant_o(fifo_grant_o),.request_i2(out_req2),.valid_i2(bank_out_valid2),.index_i2(out_index2));


assign out_busy2 = ( (!fifo_grant_o) || out_busy || stop_reading || stop_writing ) ;

endmodule
`timescale 1 ns / 1 ps
module the_controller_tb ;

// pragma attribute txn_controller_tb partition_module_xrt

logic clk , rst_n ,RESET_N ,CK_t , CK_c;


localparam lines_no = 9355, writes_no =1460, reads_no =7895, data_width = 16, address_width = 30;

int  request_counter = 0, w_data_counter = 0, r_data_counter = 0;

logic types [0:lines_no];
logic [address_width-1:0] addresses [0:lines_no];
logic [data_width-1:0] r_data [0:reads_no];
logic [data_width-1:0] w_data [0:writes_no];

/////////////////////////////////////////////////////

logic out_busy , in_valid, in_request_type ,write_done, read_done;
logic [data_width-1:0] in_request_data , data_out;
logic [address_width-1:0] in_request_address;

////////////// signals between memory  and controller \\\\\\\\\\\
logic CS_n;                
logic [13:0] CA;              
logic CAI;          
logic [2:0] DM_n;          
wire [data_width-1:0] DQ ; 
logic [data_width-1:0] DQ_l ;          
wire [2:0] DQS_t , DQS_c ;
wire ALERT_n;

////////////// signals to the memory \\\\\\\\\\\

assign RESET_N = rst_n;
assign CK_t = clk;
assign CK_c = ~clk; // or 0 not sure

 
memory_controller the_memory_controller (.*);
veloce_ddr5_sm #(.DENSITY(1),.DQ_SIZE(data_width)) the_memory (.*);


// tbx clkgen inactive_negedge
initial  begin
    clk = 0;
    #1;
    forever 
    #1 clk = ~clk;
end

//XlResetGenerator #(10) resetGenerator ( clk, rst);


logic done_entering_flag = 0;
logic [20:0] realy_done_this_time = 0;

logic [30:0] op_no =0;
logic op_type = 1; // write

logic done_done = 0;


initial begin

	$readmemb("/home/mohmos8e/ddr5_controller/Mem_Controller/over_all_test_bench/requests_types.txt",types);
	$readmemb("/home/mohmos8e/ddr5_controller/Mem_Controller/over_all_test_bench/requests_address.txt",addresses);
	$readmemb("/home/mohmos8e/ddr5_controller/Mem_Controller/over_all_test_bench/read_data.txt",r_data);
	$readmemb("/home/mohmos8e/ddr5_controller/Mem_Controller/over_all_test_bench/write_data.txt",w_data);

	$display("the addresses[0]",addresses[request_counter]);

	@(negedge clk)
	rst_n =1'b0;
	in_valid = 0;
	@(negedge clk)
	rst_n =1'b1;
	
	for (int i = 0; i < 10000000; i++) begin
		@(negedge clk)
		
		if (done_entering_flag == 0) begin
			if (!out_busy) begin
				
				in_valid =1;
				in_request_address = addresses[request_counter];
				in_request_type = types[request_counter];
				in_request_data = w_data[w_data_counter];

				if (request_counter == lines_no-1) begin
					done_entering_flag =1;
				end

				if (types[request_counter] == 1) begin
					w_data_counter ++;
				end

				request_counter ++;

			end
			else begin
				in_valid =0;
			end	
		end
		else begin
			
			in_valid =0;
			if (done_entering_flag == 0) begin
				$display("finished entering 1024 requests after %d cycle",i);
			end		
		end
		if (write_done == 1) begin // check if the data is right
			realy_done_this_time = 0;
		end	

		if (read_done == 1) begin // check if the data is right
			if (data_out != r_data[r_data_counter]) begin
				$display("error data returned from %h request is wrong",r_data[r_data_counter]);
			end
			r_data_counter ++;
			realy_done_this_time = 0;
		end	
		if (realy_done_this_time == 2000 && done_done == 0) begin // assuming 2000 is the max number of idle clks to have read request and not output any data
			$display("finished every thing after %d cycle",i-2000);
			done_done =1;
		end	
		realy_done_this_time ++;
	end
end

endmodule

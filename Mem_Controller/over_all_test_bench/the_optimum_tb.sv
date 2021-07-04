module the_optimum_tb ;

logic clk , rst_n;

localparam data_width = 16, address_width = 30;

logic out_busy , in_valid, in_request_type ,write_done, read_done;
logic [data_width-1:0] in_request_data , data_out;
logic [address_width-1:0] in_request_address;


// memory_controller the_memory_controller (.clk,.rst_n,.in_valid,.in_request_type,.in_request_data,.in_request_address,.out_busy,.write_done,.read_done,.data_out);


// Clock generator
  always begin
    #1 clk = 1;
    #1 clk = 0;
  end

logic done_entering_flag = 0;
logic [10:0] realy_done_this_time = 0;

logic [30:0] op_no =0;
logic op_type = 1;
logic [address_width-1:0] the_right_data = 0;

initial begin

	rst_n = 0;
	in_valid = 0;

	#10

	@(posedge clk)
	
	rst_n = 1;
	
	#100

	for (int i = 0; i < 100000; i++) begin
		if (done_entering_flag == 0) begin
			if (!out_busy) begin

				in_valid =1;
				in_request_address = op_no;

				if (op_type == 1 ) begin
					
					in_request_type = 1;
					in_request_data = op_no;
					op_no++;
					
					if (op_no == 1023) begin
						op_no = 0;
					end

				end
				else begin
					
					in_request_type = 0;
					
					if (op_no == 1023) begin
						done_entering_flag =1;
					end
				end
			end

			else begin
				in_valid =0;
			end	
		end

		else begin
			
			in_valid =0;

			if (done_entering_flag == 0) begin
				$display("finished entering %d requests after %d cycle",lines_no,i);
			end
			done_entering_flag = 1;
		
		end

		if (read_done == 1) begin // check if the data is right
			if (data_out != the_right_data) begin
				$display("error data returned from %b request is wrong",the_right_data);
			end
			the_right_data ++;
			realy_done_this_time = 0;
		end	

		if (realy_done_this_time == 200) begin // assuming 200 is the max number of idle clks to have read request and not output any data
			$display("finished every thing after %d cycle",i-200);
		end	

		realy_done_this_time ++;

	end

end

endmodule

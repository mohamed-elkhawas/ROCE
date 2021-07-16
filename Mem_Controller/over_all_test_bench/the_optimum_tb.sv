module the_optimum_tb ;

// pragma attribute txn_controller_tb partition_module_xrt

logic clk , rst_n ,RST_N ,CK_t , CK_c;

localparam data_width = 16, address_width = 30;

logic out_busy , in_valid, in_request_type ,write_done, read_done;
logic [data_width-1:0] in_request_data , data_out;
logic [address_width-1:0] in_request_address;


////////////// signals between memory  and controller \\\\\\\\\\\
logic CS_n;                
logic [13:0] CA;              
logic CAI;          
logic [2:0] DM_n;          
logic [data_width-1:0] DQ;          
logic [2:0] DQS_t , DQS_c ;
logic ALERT_n;

////////////// signals to the memory \\\\\\\\\\\

assign RST_N = rst_n;
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

XlResetGenerator #(10) resetGenerator ( clk, rst);

task delay(cycle);
	repeat (cycle) begin
		@(posedge clk);
	end
endtask 

	
logic done_entering_flag = 0;
logic [10:0] realy_done_this_time = 0;

logic [30:0] op_no =0;
logic op_type = 1; // write
logic [address_width-1:0] the_right_data = 0;

	
initial begin

	
	in_valid = 0;

	delay(100);

	for (int i = 0; i < 100000; i++) begin
		@(posedge clk)
		
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

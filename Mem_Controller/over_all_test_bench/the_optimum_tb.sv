`timescale 1 ns / 1 ps
module the_optimum_tb ;

// pragma attribute txn_controller_tb partition_module_xrt

logic clk , rst_n ,RESET_N ,CK_t , CK_c;

localparam data_width = 16, address_width = 30;

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
//veloce_ddr5_sm #(.DENSITY(1),.DQ_SIZE(data_width)) the_memory (.*);


// tbx clkgen inactive_negedge
initial  begin
    clk = 0;
    #1;
    forever 
    #1 clk = ~clk;
end

//XlResetGenerator #(10) resetGenerator ( clk, rst);

	
logic done_entering_flag = 0;
logic [10:0] realy_done_this_time = 0;

logic [30:0] op_no =0;
logic op_type = 1; // write
logic [address_width-1:0] the_right_data = 0;

logic done_done = 0;

	
initial begin

	@(negedge clk)
	rst_n =1'b0;
	in_valid = 0;
	@(negedge clk)
	rst_n =1'b1;
	
	for (int i = 0; i < 100000; i++) begin
		@(negedge clk)
		
		if (done_entering_flag == 0) begin
			if (!out_busy) begin
				
				in_valid =1;
				in_request_address = op_no;
				in_request_type = op_type;
				in_request_data = op_no;

				if (op_no == 1024) begin

					if (op_type == 1 ) begin
						op_no = 0;
						op_type =0;
					end
					else begin
						done_entering_flag =1;
					end
				end
				else begin
					op_no++;
				end

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
		if (read_done == 1 || write_done == 1) begin // check if the data is right
			if (data_out != the_right_data) begin
				$display("error data returned from %b request is wrong",the_right_data);
			end
			the_right_data ++;
			realy_done_this_time = 0;
		end	
		if (realy_done_this_time == 200 && done_done == 0) begin // assuming 200 is the max number of idle clks to have read request and not output any data
			$display("finished every thing after %d cycle",i-200);
			done_done =1;
		end	
		realy_done_this_time ++;
	end

end

endmodule


















/*`timescale 1 ns / 1 ps
module the_optimum_tb ;

// pragma attribute txn_controller_tb partition_module_xrt

logic clk , rst_n ,RESET_N ,CK_t , CK_c;

localparam data_width = 16, address_width = 30;

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
//assign DQ = DQ_l ;
memory_controller the_memory_controller (.*);
veloce_ddr5_sm #(.DENSITY(1),.DQ_SIZE(data_width)) the_memory (.*);

/*veloce_ddr5_sm #(.DENSITY(1),.DQ_SIZE(data_width)) the_memory
(
  .RESET_N(RESET_N),          // Asynchronous reset           -> active low
  .CK_t(CK_t),             // Clock (diff pair)
  .CK_c(CK_c),             // ~Clock (diff pair)
  .CS_n(CS_n),             // Chip Select                  -> active low
  .CA(CA),               // Command / Address Port 
  .CAI(CAI),              // Command / Address inversion  -> active high
  .DM_n(DM_n),             // Data Mask  -> byte based     -> active low 
  .DQ(DQ),               // Data Port 
  .DQS_t(DQS_t),            // Data Strobes (diff pair)
  .DQS_c(DQS_c),            // ~Data Strobes (diff pair)   
  .ALERT_n(ALERT_n)          // CRC/Parity error flag   

);

// tbx clkgen inactive_negedge
initial  begin
    clk = 0;
    #1;
    forever 
    #1 clk = ~clk;
end

//XlResetGenerator #(10) resetGenerator ( clk, rst);

logic a ;
task delay(cycle);
	repeat (cycle) begin
		@(posedge clk)
		a = 0 ;
	end
endtask 

	
logic done_entering_flag = 0;
logic [10:0] realy_done_this_time = 0;

logic [30:0] op_no =0;
logic op_type = 1; // write
logic [address_width-1:0] the_right_data = 0;

	
initial begin

	rst_n =1'b0;
	in_valid = 0;
	/*@(posedge clk)
	CS_n = 1 ;
	CA   = 0 ;
	DQ_l = 1 ;
	delay(100);
	@(posedge clk)
	@(posedge clk)
	rst_n = 1'b1;
	@(posedge clk)
	CS_n = 0 ;
	CA = 14'h5 ; // write register 
	CAI = 0 ;
	@(posedge clk)
	CS_n = 1 ;
	CA = 0 ;
	@(posedge clk)
	@(posedge clk)
	@(posedge clk)
	@(posedge clk)
	@(posedge clk)
	@(posedge clk)
	@(posedge clk)
	CS_n = 0 ;
	CA = 14'h10 ; //activate
	@(posedge clk)
	CS_n = 1 ;
	CA = 0 ;
	delay(10);
	CS_n = 0 ;
	CA = 14'h2c ;
	@(posedge clk) 
	CS_n = 1 ;
	CA = 0 ;

	/*in_valid =1;
	in_request_address = 2;
	in_request_type = 1;
	in_request_data = 10;
	@(posedge clk)
	in_valid =0;
	wait (write_done == 1);
	@(posedge clk)
	in_valid =1;
	in_request_address = 2;
	in_request_type = 0;
	@(posedge clk)
	in_valid =0;


	@(posedge clk)
	@(posedge clk)
	@(posedge clk)
	rst_n =1'b1;
	for (int i = 0; i < 15; i++) begin
		@(posedge clk)
		in_valid =1;
		in_request_address = 30'b000000000001000000000010000000 +i;
		in_request_type = 1;
		in_request_data = i;
	end
	for (int i = 0; i < 15; i++) begin
		@(posedge clk)
		in_valid =1;
		in_request_address = 30'b000000000001000000000010000000 +i;
		in_request_type = 0;
		in_request_data = i;
	end
	@(posedge clk)
	in_valid =0;

	//row 10 col 20 
	// write column 0x20

	/*for (int i = 0; i < 100000; i++) begin
		@(negedge clk)
		
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
						op_type =0;
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
				$display("finished entering 1024 requests after %d cycle",i);
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
/*

`timescale 1 ns / 1 ps
module the_optimum_tb ;

// pragma attribute txn_controller_tb partition_module_xrt

logic clk , rst_n ,RESET_N ,CK_t , CK_c;

localparam data_width = 16, address_width = 30;

logic out_busy , in_valid, in_request_type ,write_done, read_done;
logic [data_width-1:0] in_request_data , data_out;
logic [address_width-1:0] in_request_address;


////////////// signals between memory  and controller \\\\\\\\\\\
logic CS_n;                
logic [13:0] CA;              
logic CAI;          
logic [2:0] DM_n;          
wire [data_width-1:0] DQ ; 
//logic [data_width-1:0] DQ_l ;          
wire [2:0] DQS_t , DQS_c ;
wire ALERT_n;

////////////// signals to the memory \\\\\\\\\\\

assign RESET_N = rst_n;
assign CK_t = clk;
assign CK_c = ~clk; // or 0 not sure
//assign DQ = DQ_l ;
memory_controller the_memory_controller (.*);
//veloce_ddr5_sm #(.DENSITY(1),.DQ_SIZE(data_width)) the_memory (.*);

// tbx clkgen inactive_negedge
initial  begin
    clk = 0;
    #1;
    forever 
    #1 clk = ~clk;
end

//XlResetGenerator #(10) resetGenerator ( clk, rst);


	
logic done_entering_flag = 0;
logic [10:0] realy_done_this_time = 0;

logic [30:0] op_no =0;
logic op_type = 1; // write
logic [address_width-1:0] the_right_data = 0;
logic flag2 =0;

	
initial begin

	rst_n =1'b0;
	in_valid = 0;

	@(posedge clk)
	@(posedge clk)
	@(posedge clk)
	rst_n =1'b1;

	for (int i = 0; i < 100000; i++) begin
		@(negedge clk)
		
		if (done_entering_flag == 0) begin
			if (!out_busy) begin

				in_valid =1;
				in_request_address = op_no;
				in_request_data = op_no;
				in_request_type = op_type;
				op_no++;

				if (op_type == 1 && op_no == 1023 ) begin				
					op_no = 0;
					op_type =0;
				end
				else begin
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
				$display("finished entering 1024 requests after %d cycle",i);
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

		if (flag2 == 0) begin
			if (realy_done_this_time == 200) begin // assuming 200 is the max number of idle clks to have read request and not output any data
				$display("finished every thing after %d cycle",i-200);
			end	
			flag2 = 1;
			realy_done_this_time ++;
		end
		

	end

end

endmodule


*/

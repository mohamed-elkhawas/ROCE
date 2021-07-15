module the_controller_tb ;

logic clk , rst_n;

localparam lines_no = 582301, writes_no =283844, reads_no =298457, data_width = 16, address_width = 30;

int  request_counter=0 , w_data_counter=0 , r_data_counter=0;

logic types[0:lines_no];
logic [address_width-1:0]addresses [0:lines_no];
logic [data_width-1:0]r_data [0:reads_no];
logic [data_width-1:0]w_data [0:writes_no];


logic out_busy , in_valid, in_request_type ,write_done, read_done;
logic [data_width-1:0] in_request_data , data_out;
logic [address_width-1:0] in_request_address;

 
// memory_controller the_memory_controller (.*);

// 

// Clock generator
  always begin
    #1 clk = 1;
    #1 clk = 0;
  end

logic done_flag = 0;

initial begin

	$readmemb("requests_types.txt",types);
	$readmemb("requests_address.txt",address);
	$readmemb("read_data.txt",r_data);
	$readmemb("write_data.txt",w_data);

	rst_n = 0;
	in_valid = 0;

	#10

	@(posedge clk)
	
	rst_n = 1;
	
	#100

	for (int i = 0; i < 10000000; i++) begin
		@(posedge clk)


		if (request_counter < lines_no) begin

			if (!out_busy) begin
				
				in_valid =1;
				in_request_address = addresses[request_counter];
				in_request_type = types[request_counter];
				in_request_data = w_data[w_data_counter];
				request_counter++;

				if (types[request_counter] == 1) begin // write
					w_data_counter++;
				end
			end
			else begin
				in_valid =0;
			end

			if (read_done == 1) begin // check if the data is right
				if (data_out != r_data[r_data_counter]) begin
					$display("error data returned from %b request is wrong",request_counter);
				end
				r_data_counter ++;
			end
		end
		else begin
			if (done_flag == 0) begin
				$display("finished %d requests after %d cycle",lines_no,i);
			end
			done_flag = 1;
		end		
	end
end

endmodule

module request_saver import types_def::*;
(
	input clk,    // Clock
	input rst_n,  // reset active low
////////////////////////////////////////////////mapper
	input opt_request request_i,
	input logic [15:0] valid_i,
	input logic [read_entries_log -1:0] index_i,

	output logic grant_o2,
/////////////////////////////////////////////////fifo 
	input logic [15:0] grant_o,

	output opt_request request_i2,
	output logic [15:0] valid_i2,
	output logic [read_entries_log -1:0] index_i2
	
);


logic waiting_valid ;
                   
opt_request waiting ;
logic [read_entries_log -1:0] index_waiting ;

logic [$clog2(banks_no)-1 :0] j;


always_comb begin 

	for (int i = 0; i < banks_no; i++) begin
		if (valid_i[i] == 1) begin
			j=i;
		end
	end

	if (grant_o[j] == 0 && valid_i[j] == 1 ) begin // save the request
		grant_o2 = 0;
	end
  else begin // send normally
    grant_o2 = 1;
    valid_i2 = valid_i;
    index_i2 = index_i;
    request_i2 = request_i;
  end

  if (waiting_valid) begin // old request waiting
    
    grant_o2 = 0;
    if (grant_o[j]) begin
       valid_i2[j] = 1;
       index_i2 = index_waiting;
       request_i2 = waiting;
    end
  end
end

always_ff @(posedge clk ) begin
  
  if(rst_n) begin

    if (waiting_valid == 1 && grant_o[j] ==1) begin
       waiting_valid <=0;
    end

    if (grant_o[j] == 0 && valid_i[j] == 1 ) begin
      waiting <= request_i;
      index_waiting <= index_i;
      waiting_valid <=1;
    end
 
  end
  else begin // reset
    waiting_valid <=0;
  end 
end

endmodule

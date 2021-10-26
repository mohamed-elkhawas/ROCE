/*module cntr_mode_tb()
// pragma attribute txn_controller_tb partition_module_xrt

#(
    parameter WR_FIFO_SIZE = 4,
    parameter WR_FIFO_NUM = 3,
    parameter READ = 1'b0,
    parameter WRITE = 1'b1
)
(
   clk,    // Input clock
   rst_n,  // Synchronous reset  
   num,    // Input number of write requests for each bank
   mode   // Output controller mode
); 


// Clock generator
// tbx clkgen inactive_negedge
initial  begin
    clk = 0;
    #1;
    forever 
    #1 clk = ~clk;
end



endmodule*/
module Write_Counter
#(parameter ARR_NUM_WR , parameter ARR_SIZE_WR , parameter READ = 1'b1 , parameter WRITE = 1'b0 )
(
   input   clk , rst_n , in_type , out_type , grant_o, //grant_o =1 in case of successful reading the input to scheduler
   output  lwm , hwm                           // apply request to Arbiter to control the bus 
);

localparam LOW_WM  = 2,//(ARR_NUM_WR*ARR_SIZE_WR)*(10/100),//low water mark percentage of total write requests.
           HIGH_WM = 5;//(ARR_NUM_WR*ARR_SIZE_WR)*(70/100);//high water mark percentage of total write requests.


           
reg [$clog2(ARR_NUM_WR*ARR_SIZE_WR):0] wr_cnt;


always@(posedge clk) begin //update write requests counter
    if(!rst_n) begin
        wr_cnt <= 0;
    end
    else begin
        casex ({ {in_type , grant_o } , out_type  }) 
            { {WRITE , 1'b1 } , READ  } : wr_cnt <= wr_cnt+1;
            { {1'bx , 1'b0 }  , WRITE } : wr_cnt <= wr_cnt-1;
            { {READ  , 1'b1 } , WRITE } : wr_cnt <= wr_cnt-1;
            default : wr_cnt <= wr_cnt;
        endcase 
    end
end

assign {hwm , lwm} = { wr_cnt>=HIGH_WM  , wr_cnt<=LOW_WM };

endmodule
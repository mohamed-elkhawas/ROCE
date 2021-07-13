module Scheduler();
#(parameter READ =1'b1 , parameter WRITE = 1'b0 , parameter ARR_NUM_RD = 4, parameter ARR_NUM_WR = 3, parameter REQ_SIZE_READ = 5 , parameter REQ_SIZE_WRITE = 5 ,parameter RA_BITS = 16 )
(
   input   clk , rst_n , ready , mode, //mode-->read or write draining
   input   [(REQ_SIZE_READ*ARR_NUM_RD)-1:0]  in_rd         ,// input read data 
   input   [(REQ_SIZE_WRITE*ARR_NUM_WR)-1:0] in_wr         ,// input write data
   input   [(ARR_NUM_RD+ARR_NUM_WR)-1:0]     empty , 
   output  valid_o //to arbiter           
);

wire [ARR_NUM_RD-1:0] empty_rd  ;
wire [ARR_NUM_WR-1:0] empty_wr  ;

reg [ARR_NUM_RD-1:0] hits_rd ;
reg [ARR_NUM_WR-1:0] hits_wr ;  

assign {empty_rd , empty_wr} = { empty[ARR_NUM_RD-1:0] , empty[ARR_NUM_WR+ARR_NUM_RD -1:ARR_NUM_RD] }; 

integer i ;
always @(*) begin //find row Hits / burst hits signals
    for(i=0 ; i<ARR_NUM_RD ; i=i+1) 
        hits_rd[i] = (empty[i] ==1'b0)? in_rd[((i+1)*REQ_SIZE_READ)-1 : ((i+1)*REQ_SIZE_READ)-RA_BITS-1] ==  burst_addr[BURST_BITS-1:0]      :1'b0;// output burst hits
end


/************************************************FSM signals*****************************************************/
localparam [2:0] // 3 states are required
    EMPTY       = 3'b000,
    WAITING     = 3'b001,
    FINISH      = 3'b010,
    WRITE_BURST = 3'b011,
    READ_BURST  = 3'b100;

reg [1:0] CS, NS;
reg valid_o ;  
/*****************************************************************************************************************/


// UPDATE FSM 
always @(posedge clk)begin
    if(!rst_n)begin
        CS  <= EMPTY;
    end
    else begin
        CS  <= NS;
    end
end


// Compute Next State
always @(*) begin
    NS = CS ;
    valid_o = 1'b0 ; 
    case(CS) 
        EMPTY , FINISH:begin
            if(mode == READ) begin
                if( &empty_rd == 1'b1  )
                    NS = EMPTY ;
                else if( &empty_rd == 1'b0 ) begin
                    NS = WAITING;
                    valid_o = 1'b1 ; 
                end
            end
            else if(mode == WRITE) begin
                if( &empty_wr == 1'b1  )
                    NS = EMPTY ;
                else if( &empty_wr == 1'b0 ) begin
                    NS = WAITING;
                    valid_o = 1'b1 ; 
                end
            end
        end
        WAITING:begin
            if(mode == READ) begin
                if( &empty_rd == 1'b1  )
                    NS = EMPTY ;
                else if( &empty_rd == 1'b0 ) begin
                    NS = WAITING;
                    valid_o = 1'b1 ; 
                end
                else if( ready = 1'b1 ) begin
                    NS = READ_BURST;
                    valid_o = 1'b1 ; 
                end
            end
            else if(mode == WRITE) begin
                if( &empty_wr == 1'b1  )
                    NS = EMPTY ;
                else if( &empty_wr == 1'b0 ) begin
                    NS = WAITING;
                    valid_o = 1'b1 ; 
                end
                else if( ready = 1'b1 ) begin
                    NS = WRITE_BURST;
                    valid_o = 1'b1 ; 
                end
            end
        end
        READ_BURST : begin
            if ( |out_hits[ARR_NUM_RD-1:0] == 1'b1 ) begin // burst hit exists
                NS=READ_BURST;
            end
            else begin // burst hit does not exist 
                NS=IDLE;
            end                             
        end
        NEW_WRITE_BURST ,SAME_WRITE_BURST :begin
            if ( |out_hits[ALL_ARR- 1:ARR_NUM_RD] == 1'b1  ) begin // burst hit exists
                NS=SAME_WRITE_BURST;
            end
            else begin  // no burst hits
                if (lwm == 1'b0) begin // continue drain write till low watermark
                    NS=NEW_WRITE_BURST;
                end
                else if(lwm ==1'b1) begin //low water mark is set and no hits found
                    NS=IDLE;
                end 
            end      
        end 
    endcase
end

//compute output
always @(*)begin
    rd_en=7'd0 ;
    rst_burst=1'b1;//active low
    case(CS) 
        IDLE:begin
            if( &empty == 1'b1 || grant_i==1'b0 ) begin// all empty || no grant given to drain requests            
                rd_en=7'd0;
                rst_burst=0;
            end
            else if (grant_i ==1'b1)begin
                if ( hwm==1'b1 ||( lwm && &empty_rd==1'b1) )   // get first unempty array, no hits required
                    rd_en[get_index(~empty,`WRITE)]=1'b1;
                else if( &empty_rd == 1'b0 ) // get first unempty array, no hits required
                    rd_en[get_index(~empty,`READ)]=1'b1;
            end    

        end    
        READ_BURST:begin
            if ( |out_hits[ARR_NUM_RD-1:0] == 1'b1 ) begin // burst hit exists
                rd_en[get_index(out_hits,`READ)]=1'b1;
            end
            else begin // burst hit does not exist 
                rd_en=0;
                rst_burst=0;
            end        
        end
        NEW_WRITE_BURST , SAME_WRITE_BURST :begin
            if ( |out_hits[ALL_ARR- 1:ARR_NUM_RD] == 1'b1  ) begin // burst hit exists
                rd_en[get_index(out_hits,`WRITE)]=1'b1;
            end
            else begin  // continue drain write bursts till low water mark
                if (lwm == 1'b0) 
                    rd_en[get_index(~empty,`WRITE)]=1'b1;
                else begin
                    rd_en=0;
                    rst_burst=0;
                end
            end 
        end 
    endcase
    
end
endmodule
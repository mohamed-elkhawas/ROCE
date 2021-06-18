module Bank_Group_Fsm
(   
    input  clk, rst_n, start ,
    input  [3:0] Bank_Req,
    input  [3:0] Valid   ,
    output reg Ack_A, Ack_B, Ack_C, Ack_D, 
    output reg [1:0] sel , //bank index to drain from 
    output reg  en , done,
    output Req
);


wire ReqD, ReqC, ReqB, ReqA ;
wire valid_D, valid_C, valid_B, valid_A ;


assign { ReqD, ReqC, ReqB, ReqA } = Bank_Req;
assign { valid_D, valid_C, valid_B, valid_A } = Valid;





/*always @(*) begin
    casex ({Ack_A,Ack_B,Ack_C,Ack_D})
        4'b0001 : sel = 2'd0 ; 
        4'b0010 : sel = 2'd1 ;
        4'b0100 : sel = 2'd2 ;
        4'b1000 : sel = 2'd3 ;
        default : sel = 2'dx ;  
    endcase
end*/


localparam [2:0]
    IDLE   = 3'b000,
    BANK_A = 3'b001,
    BANK_B = 3'b010,
    BANK_C = 3'b011,
    BANK_D = 3'b100;

reg [2:0] CS, NS ;


/*always @(posedge clk) begin 
    if (!rst_n )
        Count <= 0;
    else
        Count <= Count +1;
end*/


/*always @(*)begin //TIMEOUT_COUNT2
    if (Count == TimeOutClockPeriods)
        TimesUp = 1;
    else
        TimesUp = 0;
end*/

//update fsm
always @ (posedge clk)begin
    if (!rst_n)
        CS <= IDLE;
    else
        CS <= NS;
end


// Compute Next State and mealy outputs
always @ (*)begin
    en    = 1'b0  ;
    sel   = 2'dx  ; 
    Ack_A = 1'b0  ;
    Ack_B = 1'b0  ;
    Ack_C = 1'b0  ;
    Ack_D = 1'b0  ;
    done  = 1'b0  ;
    NS    = CS    ;
    //Timeen = 0;
    //RunTimer  = 0;
    
    if(start == 1'b1)begin // continue the fsm
        case (CS)
            IDLE: begin
                if (ReqA == 1'b1)begin
                    en      = 1'b1    ;
                    sel     = 2'd0    ;
                    Ack_A   = 1'b1    ;
                    NS      = BANK_A  ;
                end
                else if (ReqB == 1'b1)begin
                    en      = 1'b1    ;
                    sel     = 2'd1    ;
                    Ack_B   = 1'b1    ;
                    NS      = BANK_B ;
                end
                else if (ReqC == 1'b1)begin
                    en      = 1'b1    ;
                    sel     = 2'd2    ;
                    Ack_C   = 1'b1    ;
                    NS      = BANK_C  ;
                end
                else if (ReqD == 1'b1)begin
                    en      = 1'b1    ;
                    sel     = 2'd3    ;
                    Ack_D   = 1'b1    ;
                    NS      = BANK_D  ;
                end
            end
            BANK_A: begin
                if (ReqA == 1'b1 &&  valid_A == 1'b1 )begin
                    en       = 1'b1   ;
                    sel      = 2'b0   ;
                    Ack_A    = 1'b0   ;
                    done     = 1'b0   ;
                    NS       = BANK_A ;
                end 
                else begin
                    if (ReqB == 1'b1) begin
                        done = 1'b1  ; // burst is finished
                        NS   = BANK_B ;
                    end
                    else if (ReqC == 1'b1)begin
                        done = 1'b1  ; // burst is finished
                        NS   = BANK_C ;
                    end
                    else if (ReqD == 1'b1)begin
                        done = 1'b1  ; // burst is finished
                        NS   = BANK_D ;
                    end
                    else begin
                        done = 1'b1 ; // burst is finished
                        NS   = IDLE  ;
                    end
                end
            end
            BANK_B: begin
                if (ReqB == 1'b1 && valid_B == 1'b1 )begin
                    en       = 1'b1   ;
                    sel      = 2'b0   ;
                    Ack_B    = 1'b0   ;
                    done     = 1'b0   ;
                    NS       = BANK_B ;
                end
                else begin
                    if (ReqC == 1'b1)begin
                        done = 1'b1  ; // burst is finished
                        NS   = BANK_C ;
                    end
                    else if (ReqD == 1'b1)begin
                        done = 1'b1  ; // burst is finished
                        NS   = BANK_D ;
                    end
                    else if (ReqA == 1'b1)begin
                        done = 1'b1  ; // burst is finished
                        NS   = BANK_A ;
                    end
                    else begin
                        done = 1'b1  ; // burst is finished
                        NS   = IDLE ;
                    end
                end
            end
            BANK_C: begin
                if (ReqC == 1'b1 && valid_C == 1'b1 )begin
                    en       = 1'b1   ;
                    sel      = 2'b0   ;
                    Ack_C    = 1'b0   ;
                    done     = 1'b0   ;
                    NS       = BANK_C ;
                end 
                else begin
                    if (ReqD == 1'b1)begin
                        done = 1'b1  ; // burst is finished
                        NS   = BANK_D ;
                    end
                    else if (ReqA == 1'b1)begin
                        done = 1'b1  ; // burst is finished
                        NS   = BANK_A ;
                    end
                    else if (ReqB == 1'b1)begin
                        done = 1'b1  ; // burst is finished
                        NS   = BANK_B ;
                    end
                    else begin
                        done = 1'b1  ; // burst is finished
                        NS   = IDLE ;
                    end
                end
            end
            BANK_D: begin
                if (ReqD == 1'b1 && valid_D == 1'b1 )begin
                    en       = 1'b1   ;
                    sel      = 2'b0   ;
                    Ack_D    = 1'b0   ;
                    done     = 1'b0   ;
                    NS       = BANK_D ;
                end 
                else begin
                    if (ReqA == 1'b1)begin
                        done = 1'b1  ; // burst is finished
                        NS   = BANK_A ;
                    end
                    else if (ReqB == 1'b1)begin
                        done = 1'b1  ; // burst is finished
                        NS   = BANK_B ;
                    end
                    else if (ReqC == 1'b1)begin
                        done = 1'b1  ; // burst is finished
                        NS   = BANK_C ;
                    end
                    else begin
                        done = 1'b1  ; // burst is finished
                        NS   = IDLE ;
                    end
                end
            end
        endcase
    end

   
end


assign Req = |{ReqA, ReqB, ReqC, ReqD};


endmodule
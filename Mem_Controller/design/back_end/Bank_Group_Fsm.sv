module Bank_Group_Fsm
(   
    input  clk, rst_n, start ,
    //input  [3:0] Bank_Req,
    input  [3:0] Valid   ,
    output reg Ready_A, Ready_B, Ready_C, Ready_D, 
    output reg [1:0] sel , //bank index to drain from 
    output reg done,
    output Req
);


//wire  ReqD, ReqC, ReqB, ReqA ;
//assign { ReqD, ReqC, ReqB, ReqA } = Bank_Req;

wire valid_D, valid_C, valid_B, valid_A ;
assign { valid_D, valid_C, valid_B, valid_A } = Valid;

enum reg [2:0] { IDLE, BANK_A, BANK_B, BANK_C, BANK_D } CS, NS;

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
    sel     = 2'd0  ;  //dont care
    Ready_A = 1'b0  ;
    Ready_B = 1'b0  ;
    Ready_C = 1'b0  ;
    Ready_D = 1'b0  ;
    done    = 1'b0  ;
    NS      = CS    ;
    //Timeen = 0;
    //RunTimer  = 0;
    
    if(start == 1'b1)begin // continue the fsm
        case (CS)
            IDLE: begin
                if (valid_A == 1'b1)begin
                    sel     = 2'd0    ;
                    Ready_A = 1'b1    ;
                    NS      = BANK_A  ;
                end
                else if (valid_B == 1'b1)begin
                    sel     = 2'd1    ;
                    Ready_B   = 1'b1    ;
                    NS      = BANK_B ;
                end
                else if (valid_C == 1'b1)begin
                    sel     = 2'd2    ;
                    Ready_C   = 1'b1    ;
                    NS      = BANK_C  ;
                end
                else if (valid_D == 1'b1)begin
                    sel     = 2'd3    ;
                    Ready_D = 1'b1    ;
                    NS      = BANK_D  ;
                end
            end
            BANK_A: begin
                //if (valid_A == 1'b1 &&  valid_A == 1'b1 )begin
                if (valid_A == 1'b1 )begin
                    sel      = 2'd0   ;
                    Ready_A  = 1'b1   ;
                    done     = 1'b0   ;
                    NS       = BANK_A ;
                end 
                else begin
                    if (valid_B == 1'b1) begin
                        done = 1'b1  ; // burst is finished
                        NS   = BANK_B ;
                    end
                    else if (valid_C == 1'b1)begin
                        done = 1'b1  ; // burst is finished
                        NS   = BANK_C ;
                    end
                    else if (valid_D == 1'b1)begin
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
                //if (valid_B == 1'b1 && valid_B == 1'b1 )begin
                if (valid_B == 1'b1 )begin
                    sel      = 2'd1   ;
                    Ready_B    = 1'b1   ;
                    done     = 1'b0   ;
                    NS       = BANK_B ;
                end
                else begin
                    if (valid_C == 1'b1)begin
                        done = 1'b1  ; // burst is finished
                        NS   = BANK_C ;
                    end
                    else if (valid_D == 1'b1)begin
                        done = 1'b1  ; // burst is finished
                        NS   = BANK_D ;
                    end
                    else if (valid_A == 1'b1)begin
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
                //if (valid_C == 1'b1 && valid_C == 1'b1 )begin
                if (valid_C == 1'b1 )begin
                    sel      = 2'd2   ;
                    Ready_C    = 1'b1   ;
                    done     = 1'b0   ;
                    NS       = BANK_C ;
                end 
                else begin
                    if (valid_D == 1'b1)begin
                        done = 1'b1  ; // burst is finished
                        NS   = BANK_D ;
                    end
                    else if (valid_A == 1'b1)begin
                        done = 1'b1  ; // burst is finished
                        NS   = BANK_A ;
                    end
                    else if (valid_B == 1'b1)begin
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
                //if (valid_D == 1'b1 && valid_D == 1'b1 )begin
                if (valid_D == 1'b1 )begin
                    sel      = 2'd3   ;
                    Ready_D    = 1'b1   ;
                    done     = 1'b0   ;
                    NS       = BANK_D ;
                end 
                else begin
                    if (valid_A == 1'b1)begin
                        done = 1'b1  ; // burst is finished
                        NS   = BANK_A ;
                    end
                    else if (valid_B == 1'b1)begin
                        done = 1'b1  ; // burst is finished
                        NS   = BANK_B ;
                    end
                    else if (valid_C == 1'b1)begin
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


// Compute Next State and mealy outputs
/*always @ (*)begin
    en      = 1'b0  ;
    sel     = 2'd0  ;  //dont care
    Ready_A = 4'd0  ;
    Ready_B = 4'd0  ;
    Ready_C = 4'd0  ;
    Ready_D = 4'd0  ;  
    done    = 1'b0  ;
    NS      = CS    ;
    case (CS)
        IDLE: begin
            if (valid_A == 1'b1)
                //en      = 1'b1    ;
                //sel     = 2'd0    ;
                //Ready_A = 1'b1    ;
                NS      = BANK_A  ;
            else if (valid_B == 1'b1)
                //en      = 1'b1    ;
                //sel     = 2'd1    ;
                //Ready_B   = 1'b1    ;
                NS      = BANK_B ;    
            else if (valid_C == 1'b1)
                //en      = 1'b1    ;
                //sel     = 2'd2    ;
                //Ready_C   = 1'b1    ;
                NS      = BANK_C  ;
            else if (valid_D == 1'b1)
                //en      = 1'b1    ;
                //sel     = 2'd3    ;
                //Ready_D = 1'b1    ;
                NS      = BANK_D  ;
        end
        BANK_A: begin
            en       = 1'b1   ;
            sel      = 2'd0   ;
            Ready_A  = 1'b1   ;
            done     = 1'b0   ;
            if (valid_A == 1'b1 )
                NS       = BANK_A ;
            else if (valid_B == 1'b1) begin
                done = 1'b1  ; // burst is finished
                NS   = BANK_B ;
            end
            else if (valid_C == 1'b1)begin
                done = 1'b1  ; // burst is finished
                NS   = BANK_C ;
            end
            else if (valid_D == 1'b1)begin
                done = 1'b1  ; // burst is finished
                NS   = BANK_D ;
            end
            else begin
                done = 1'b1 ; // burst is finished
                NS   = IDLE  ;
            end
        end
        BANK_B: begin
            en       = 1'b1   ;
            sel      = 2'd1   ;
            Ready_B  = 1'b1   ;
            done     = 1'b0   ;
            NS       = BANK_B ;
            if (valid_C == 1'b1)begin
                done = 1'b1  ; // burst is finished
                NS   = BANK_C ;
            end
            else if (valid_D == 1'b1)begin
                done = 1'b1  ; // burst is finished
                NS   = BANK_D ;
            end
            else if (valid_A == 1'b1)begin
                done = 1'b1  ; // burst is finished
                NS   = BANK_A ;
            end
            else begin
                done = 1'b1 ; // burst is finished
                NS   = IDLE ;
            end
        end
        BANK_C: begin
            en       = 1'b1   ;
            sel      = 2'd2   ;
            Ready_C  = 1'b1   ;
            done     = 1'b0   ;
            NS       = BANK_C ;
            if (valid_D == 1'b1)begin
                done = 1'b1  ; // burst is finished
                NS   = BANK_D ;
            end
            else if (valid_A == 1'b1)begin
                done = 1'b1  ; // burst is finished
                NS   = BANK_A ;
            end
            else if (valid_B == 1'b1)begin
                done = 1'b1  ; // burst is finished
                NS   = BANK_B ;
            end
            else begin
                done = 1'b1  ; // burst is finished
                NS   = IDLE ;
            end
        end
        BANK_D: begin
            en       = 1'b1   ;
            sel      = 2'd3   ;
            Ready_D  = 1'b1   ;
            done     = 1'b0   ;
            NS       = BANK_D ;
            if (valid_A == 1'b1)begin
                done = 1'b1  ; // burst is finished
                NS   = BANK_A ;
            end
            else if (valid_B == 1'b1)begin
                done = 1'b1  ; // burst is finished
                NS   = BANK_B ;
            end
            else if (valid_C == 1'b1)begin
                done = 1'b1  ; // burst is finished
                NS   = BANK_C ;
            end
            else begin
                done = 1'b1  ; // burst is finished
                NS   = IDLE ;
            end
        end
    endcase  
end

*/
assign Req = |{valid_A, valid_B, valid_C, valid_D};


endmodule
module Groups_Fsm
(   
    input  clk, rst_n,
    input  Req , //request from bank groups to enable each bank group fsm
    input  Done, // acknoledge from each bank group fsm after Starting a burst from scheduler is finished
    output reg Start_A, Start_B, Start_C, Start_D,
    output reg [1:0] sel
);


wire ReqD, ReqC, ReqB, ReqA ;
wire Done_D, Done_C, Done_B, Done_A ;


assign {ReqD, ReqC, ReqB, ReqA} = Req ;
assign {Done_D, Done_C, Done_B, Done_A} = Done ;

/*reg [NUM_OF_BURSTS-1:0] TimeOutClockPeriods;
reg RunTimer, TimesUp;
reg [$clog2(TIME_OUT_PERIOD)-1:0] Count;


always @(posedge clk) begin //TIMEOUT_COUNT1
    if (!rst_n )
        TimeOutClockPeriods = NUM_OF_BURSTS ; //maximum number of bursts to Start from each group bank
    //else if (En_TimeOutTime == 1'b1)
       // TimeOutClockPeriods <= DataWriteBus_ProcA;
end

always @(posedge clk) begin //increment counter
    if (!rst_n || RunTimer==1'b0)
        Count <= 0;
    else
        Count <= Count +1;
end


always @(*)begin //TIMEOUT_COUNT2
    if (Count == TimeOutClockPeriods)
        TimesUp = 1;
    else
        TimesUp = 0;
end*/


always @(*) begin
    casex {Start_A,Start_B,Start_C,Start_D}
        4'b0001 : sel = 2'd0 ; 
        4'b0010 : sel = 2'd1 ;
        4'b0100 : sel = 2'd2 ;
        4'b1000 : sel = 2'd3 ;
        default : sel = 2'dx ;  
    endcase
end
/************************************************FSM signals*****************************************************/
localparam [2:0] 
    IDLE    = 3'b000,
    GROUP_A = 3'b001,
    GROUP_B = 3'b010,
    GROUP_C = 3'b011,
    GROUP_D = 3'b100;

reg [2:0] CS, NS ;
/*****************************************************************************************************************/


/*// Bank group A states
localparam [2:0] 
    MASTER_IDLE = 3'b000,
    GROUP_A     = 3'b001,
    GROUP_B     = 3'b010,
    GROUP_C     = 3'b011,
    GROUP_D     = 3'b100;

reg [1:0] MASTER_CS, MASTER_NS ;

// Bank group A states
localparam [2:0] 
    MASTER_IDLE = 3'b000,
    GROUP_A     = 3'b001,
    GROUP_B     = 3'b010,
    GROUP_C     = 3'b011,
    GROUP_D     = 3'b100;

reg [1:0] MASTER_CS, MASTER_NS ;

// Bank group A states
localparam [2:0] 
    MASTER_IDLE = 3'b000,
    GROUP_A     = 3'b001,
    GROUP_B     = 3'b010,
    GROUP_C     = 3'b011,
    GROUP_D     = 3'b100;

reg [1:0] MASTER_CS, MASTER_NS ;

// Bank group A states
localparam [2:0] 
    MASTER_IDLE = 3'b000,
    GROUP_A     = 3'b001,
    GROUP_B     = 3'b010,
    GROUP_C     = 3'b011,
    GROUP_D     = 3'b100;

reg [1:0] MASTER_CS, MASTER_NS ;*/

/*****************************************************************************************************************/

 
//update fsm
always @ (posedge clk)begin
    if (!rst_n)
        CS <= IDLE;
    else
        CS <= NS;
end



// Compute Next State and mealy outputs
always @ (*)begin
    Start_A = 0 ;
    Start_B = 0 ;
    Start_C = 0 ;
    Start_D = 0 ;
    NS = CS ;
    case (CS)
        IDLE: begin
            if (ReqA == 1'b1)begin
                Start_A = 1'b1;
                NS=GROUP_A;
            end
            else if (ReqB == 1'b1)begin
                Start_B = 1'b1;
                NS=GROUP_B;
            end
            else if (ReqC == 1'b1)begin
                Start_C = 1'b1;
                NS=GROUP_C;
            end
            else if (ReqD == 1'b1)begin
                Start_D = 1'b1;
                NS=GROUP_D;
            end
        end
        GROUP_A: begin
            if (ReqA == 1'b1 &&  Done_A == 1'b0 )begin
                Start_A = 1'b1;
                NS=GROUP_A;
            end 
            else begin
                if (ReqB == 1'b1)
                    NS=GROUP_B;
                else if (ReqC == 1'b1)
                    NS=GROUP_C;
                else if (ReqD == 1'b1)
                    NS=GROUP_D;
                else 
                    NS=IDLE;
            end
        end
        GROUP_B: begin
            if (ReqB == 1'b1 && Done_B == 1'b0 )begin
                Start_B = 1'b1;
                NS=GROUP_B;
            end
            else begin
                if (ReqC == 1'b1)
                    NS=GROUP_C;
                else if (ReqD == 1'b1)
                    NS=GROUP_D;
                else if (ReqA == 1'b1)
                    NS=GROUP_A;
                else 
                    NS=IDLE;
            end
        end
        GROUP_C: begin
            if (ReqC == 1'b1 && Done_C == 1'b0 )begin
                Start_C = 1'b1;
                NS=GROUP_C;
            end 
            else begin
                if (ReqD == 1'b1)
                    NS=GROUP_D;
                else if (ReqA == 1'b1)
                    NS=GROUP_A;
                else if (ReqB == 1'b1)
                    NS=GROUP_B;
                else 
                    NS=IDLE;
            end
        end
        GROUP_D: begin
            if (ReqD == 1'b1 && Done_D == 1'b0 )begin
                Start_D = 1'b1;
                NS=GROUP_D;
            end 
            else begin
                if (ReqA == 1'b1)
                    NS=GROUP_B;
                else if (ReqB == 1'b1)
                    NS=GROUP_C;
                else if (ReqC == 1'b1)
                    NS=GROUP_D;
                else 
                    NS=IDLE;
            end
        end
    endcase
end

assign en =

endmodule

/*always @(posedge Reset or posedge Clock)
begin: 
if (Reset)
begin
EnA

0; EnA2

begin

Enc
case (NextState)
GROUP_A: begin EnAl = 1;EnA2 = 0; end

Gront_B: begin EnB1 = 1; €nB2
GROUP_C: begin EnC] = 1:EnC2 = 0; end
default:
begin
EnAl
   
endcase
end
end*/


/*

assign AddBus_RAM = EnAl ? AddBus_ProcA : 12’;
assign AddBus_RAM = EnBl ? AddBus_ProcB : 12'b Z;
assign AddBus_RAM = EnCl ? AddBus_ProcC : 12'bZ;


assign DataWriteBus_RAM = EnA2 ? DataWriteBus ProcA,
rez:
‘assign DataWriteBus_RAM = EnB2 ? DataWriteBus_Proc8
:ebZ:
‘assign DataWriteBus_RAM = EnC2 ? DataWriteBus_ProcC
rebZ;

assign R_Wb_RAM = EnA2? R_Wb_ProcA : I'bZ;
assign R_Wb_RAM = EnB2 ?R_Wb Proc : I'bZ:
assign R_Wb_RAM = EnC2 ? R_Wb_ProcC : 1'b Z;*/









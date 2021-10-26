module modified_fifo import types_def::*;
#(
   parameter                       entries_no = 12,
   parameter                       data_entries_no = 4
)
(
   input  logic                                    clk,
   input  logic                                    rst_n,
   //PUSH SIDE
   input  opt_request                              request_i,
   input  logic [read_entries_log -1:0]            index_i,
   input  logic                                    valid_i,
   output logic                                    grant_o,
   //POP SIDE
   output opt_request                              request_o,
   output logic [read_entries_log -1:0]            index_o,
   output logic                                    valid_o,
   input  logic                                    grant_i
);


  typedef struct packed {
  r_type req_type ;
  opt_address_type address ;
  logic [read_entries_log -1:0]   index;
  } comm ;


   // Local Parameter
   localparam  ADDR_DEPTH = $clog2(entries_no);

   localparam  DATA_ADDR_DEPTH = $clog2(data_entries_no);

   enum logic [1:0] { EMPTY, FULL, MIDDLE } CS, NS;
   // Internal Signals

   logic       gate_clock;
   logic       clk_gated;

   logic [ADDR_DEPTH-1:0]          Pop_Pointer_CS,  Pop_Pointer_NS;
   logic [ADDR_DEPTH-1:0]          Push_Pointer_CS, Push_Pointer_NS;
   comm  FIFO_REGISTERS [entries_no-1:0];

   logic [DATA_ADDR_DEPTH-1:0]          data_Pop_Pointer_CS,  data_Pop_Pointer_NS; 
   logic [DATA_ADDR_DEPTH-1:0]          data_Push_Pointer_CS, data_Push_Pointer_NS; 
   logic [data_width-1:0]      DATA_FIFO_REGISTERS [data_entries_no-1:0];


   assign clk_gated = clk;


   // UPDATE THE STATE
   always_ff @(posedge clk)
   begin
       if(rst_n == 1'b0)
       begin
               CS              <= EMPTY;
               Pop_Pointer_CS  <= 0;
               Push_Pointer_CS <= 0;

               data_Pop_Pointer_CS  <= 0;
               data_Push_Pointer_CS <= 0;
       end
       else
       begin
               CS              <= NS;
               Pop_Pointer_CS  <= Pop_Pointer_NS;
               Push_Pointer_CS <= Push_Pointer_NS;

               data_Pop_Pointer_CS  <= data_Pop_Pointer_NS;
               data_Push_Pointer_CS <= data_Push_Pointer_NS;
       end
   end


   // Compute Next State
   always_comb
   begin
      gate_clock      = 1'b0;

      case(CS)

      EMPTY:
      begin
          grant_o = 1'b1;
          valid_o = 1'b0;

          case(valid_i)
          1'b0 :
          begin
                  NS  = EMPTY;
                  Push_Pointer_NS = Push_Pointer_CS;
                  Pop_Pointer_NS  = Pop_Pointer_CS;

                  data_Push_Pointer_NS = data_Push_Pointer_CS;
                  data_Pop_Pointer_NS  = data_Pop_Pointer_CS;
                  
                  gate_clock      = 1'b1;
          end

          1'b1:
          begin
                  NS  = MIDDLE;
          if(Push_Pointer_CS == entries_no-1)
                        Push_Pointer_NS = 0;
                  else
                        Push_Pointer_NS = Push_Pointer_CS + 1'b1;
                  Pop_Pointer_NS  = Pop_Pointer_CS;


                  data_Pop_Pointer_NS  = data_Pop_Pointer_CS;

                  if (  request_i.req_type == write ) begin
                    data_Push_Pointer_NS = data_Push_Pointer_CS;

                    if(data_Push_Pointer_CS == data_entries_no-1)
                            data_Push_Pointer_NS  = 0;
                    else
                          data_Push_Pointer_NS  = data_Push_Pointer_CS  + 1'b1;
                  end
                  else begin
                    data_Push_Pointer_NS = data_Push_Pointer_CS;
                  end

          end

          endcase
      end

      MIDDLE:
      begin
          grant_o = 1'b1;
          valid_o = 1'b1;

          case({valid_i,grant_i})

          2'b01:
          begin
                  gate_clock      = 1'b1;

                  if((Pop_Pointer_CS == Push_Pointer_CS -1 ) || ((Pop_Pointer_CS == entries_no-1) && (Push_Pointer_CS == 0) ))
                          NS              = EMPTY;
                  else
                          NS              = MIDDLE;

                  Push_Pointer_NS = Push_Pointer_CS;

                  if(Pop_Pointer_CS == entries_no-1)
                          Pop_Pointer_NS  = 0;
                  else
                          Pop_Pointer_NS  = Pop_Pointer_CS + 1'b1;

                  
                  data_Push_Pointer_NS = data_Push_Pointer_CS;
                  if (  FIFO_REGISTERS[Pop_Pointer_CS].req_type == write ) begin  
                    if(data_Pop_Pointer_CS == data_entries_no-1)
                            data_Pop_Pointer_NS  = 0;
                    else
                          data_Pop_Pointer_NS  = data_Pop_Pointer_CS  + 1'b1;
                  end
                  else begin
                    data_Pop_Pointer_NS  = data_Pop_Pointer_CS;
                  end

          end

          2'b00 :
          begin
                  gate_clock      = 1'b1;
                  NS                      = MIDDLE;
                  Push_Pointer_NS = Push_Pointer_CS;
                  Pop_Pointer_NS  = Pop_Pointer_CS;

                  data_Push_Pointer_NS = data_Push_Pointer_CS;
                  data_Pop_Pointer_NS  = data_Pop_Pointer_CS;
          end

          2'b11:
          begin
                  NS              = MIDDLE;

                  if(Push_Pointer_CS == entries_no-1)
                          Push_Pointer_NS = 0;
                  else
                          Push_Pointer_NS = Push_Pointer_CS + 1'b1;

                  if(Pop_Pointer_CS == entries_no-1)
                          Pop_Pointer_NS  = 0;
                  else
                          Pop_Pointer_NS  = Pop_Pointer_CS  + 1'b1;

                  
                  if (  request_i.req_type == write ) begin
                    if(data_Push_Pointer_CS == data_entries_no-1)
                            data_Push_Pointer_NS  = 0;
                    else
                          data_Push_Pointer_NS  = data_Push_Pointer_CS  + 1'b1;
                  end
                  else begin
                    data_Push_Pointer_NS = data_Push_Pointer_CS;
                  end


                  if (  FIFO_REGISTERS[Pop_Pointer_CS].req_type == write ) begin
                    if(data_Pop_Pointer_CS == data_entries_no-1)
                            data_Pop_Pointer_NS  = 0;
                    else
                          data_Pop_Pointer_NS  = data_Pop_Pointer_CS  + 1'b1;
                  end
                  else begin
                    data_Pop_Pointer_NS  = data_Pop_Pointer_CS;
                  end

                  if (  FIFO_REGISTERS[Pop_Pointer_CS].req_type == read ) begin
      if (( data_Push_Pointer_CS == data_Pop_Pointer_CS - 1) || ( (data_Push_Pointer_CS == data_entries_no-1) && (data_Pop_Pointer_CS == 0) )) begin
        NS = FULL;
        end
      end

          end

          2'b10:
          begin
                  if(( Push_Pointer_CS == Pop_Pointer_CS - 1) || ( (Push_Pointer_CS == entries_no-1) && (Pop_Pointer_CS == 0) ) ||  ( data_Push_Pointer_CS == data_Pop_Pointer_CS - 1) || ( (data_Push_Pointer_CS == data_entries_no-1) && (data_Pop_Pointer_CS == 0) )  )
                          NS   = FULL;
                  else
                          NS   = MIDDLE;

                  if(Push_Pointer_CS == entries_no - 1)
                          Push_Pointer_NS = 0;
                  else
                          Push_Pointer_NS = Push_Pointer_CS + 1'b1;

                  Pop_Pointer_NS  = Pop_Pointer_CS;

                  data_Pop_Pointer_NS  = data_Pop_Pointer_CS;

                  if (  request_i.req_type == write ) begin
                    data_Push_Pointer_NS = data_Push_Pointer_CS;

                    if(data_Push_Pointer_CS == data_entries_no-1)
                            data_Push_Pointer_NS  = 0;
                    else
                          data_Push_Pointer_NS  = data_Push_Pointer_CS  + 1'b1;
                  end
                  else begin
                    data_Push_Pointer_NS = data_Push_Pointer_CS;
                  end

          end

          endcase
      end

      FULL:
      begin
          grant_o = 1'b0;
          valid_o = 1'b1;
          gate_clock      = 1'b1;

          case(grant_i)
          1'b1:
          begin
              if ( ( FIFO_REGISTERS[Pop_Pointer_CS].req_type == read ) && ( data_Push_Pointer_CS == data_Pop_Pointer_CS - 1 ||  (data_Push_Pointer_CS == data_entries_no-1 && data_Pop_Pointer_CS == 0) )) begin
                NS              = FULL;
              end
              
              else begin
                
                  NS              = MIDDLE;

                  Push_Pointer_NS = Push_Pointer_CS;

                  if(Pop_Pointer_CS == entries_no-1)
                          Pop_Pointer_NS  = 0;
                  else
                          Pop_Pointer_NS  = Pop_Pointer_CS  + 1'b1;

                  
                  data_Push_Pointer_NS = data_Push_Pointer_CS;
                  if (  FIFO_REGISTERS[Pop_Pointer_CS].req_type == write ) begin
                    if(data_Pop_Pointer_CS == data_entries_no-1)
                            data_Pop_Pointer_NS  = 0;
                    else
                          data_Pop_Pointer_NS  = data_Pop_Pointer_CS  + 1'b1;
                  end
                  else begin
                    data_Pop_Pointer_NS  = data_Pop_Pointer_CS;
                  end                  

                end
          end

          1'b0:
          begin
                  NS              = FULL;
                  Push_Pointer_NS = Push_Pointer_CS;
                  Pop_Pointer_NS  = Pop_Pointer_CS;

                  data_Push_Pointer_NS = data_Push_Pointer_CS;
                  data_Pop_Pointer_NS  = data_Pop_Pointer_CS;
          end
          endcase

      end // end of FULL

      default :
      begin
          gate_clock      = 1'b1;
          grant_o       = 1'b0;
          valid_o       = 1'b0;
          NS              = EMPTY;
          Pop_Pointer_NS  = 0;
          Push_Pointer_NS = 0;
          data_Pop_Pointer_NS  = 0;
          data_Push_Pointer_NS = 0;
      end

      endcase
    end

    always_ff @(posedge clk_gated) begin
      if(rst_n == 1'b0) begin
        for (int i=0; i< entries_no; i++) begin
            FIFO_REGISTERS[i] <= 0;
        end
        for (int i=0; i< data_entries_no; i++) begin
            DATA_FIFO_REGISTERS[i] <= 0;
        end
      end
      else begin
        if((grant_o == 1'b1) && (valid_i == 1'b1)) begin
          FIFO_REGISTERS[Push_Pointer_CS].address <= request_i.address;
          FIFO_REGISTERS[Push_Pointer_CS].index <= index_i;
          FIFO_REGISTERS[Push_Pointer_CS].req_type <= request_i.req_type;
          if (request_i.req_type == write) begin
            DATA_FIFO_REGISTERS[data_Push_Pointer_CS] <= request_i.data;
          end
        end
      end
    end

    

   assign request_o.address = FIFO_REGISTERS[Pop_Pointer_CS].address;
   assign index_o = FIFO_REGISTERS[Pop_Pointer_CS].index;
   assign request_o.req_type = FIFO_REGISTERS[Pop_Pointer_CS].req_type;
   assign request_o.data = DATA_FIFO_REGISTERS[data_Pop_Pointer_CS];

 

endmodule

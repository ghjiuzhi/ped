
//    Copyright (c) 2022 jojo_LIB, Inc.
//    All Rights Reserved.
//***********************************************************************
//-----------------------------------------------------------------------
// File:        pp_fifo.sv
// Auther:      jojo300 
// Created:     14:41:58, Feb 18, 2025
//-----------------------------------------------------------------------
// Abstract:    ADD DESCRIPTION HERE
//
//-----------------------------------------------------------------------

module pp_fifo #(parameter DEPTH = 6,parameter DATA_WIDTH = 32)(
    input                   clk,           // Clock
    input                   reset_n,        // Reset
    input                   clear_pointers, // Clear FIFO
    input                   push,           // FIFO Data In Push
    input                   pop,           // FIFO Data In Pop
    input  [DATA_WIDTH-1:0] data_in,        // Data Input
    output                  empty,          // FIFO Empty Flag
    output                  full,          // FIFO Full Flag
    output reg    [$clog2(DATA_WIDTH)-1:0] count,          // count
    output [DATA_WIDTH-1:0] data_out       // Data Output
    );
  
    localparam DEPTH_MIN1  = DEPTH-1;
    
    reg          [$clog2(DATA_WIDTH)-1:0] wr_ptr;         // Data Write Pointer
    wire                    safe_push;      // Safe Pusg Enable
    wire                    safe_pop;       // Safe Pop Enable
  
    integer              i;
  
    reg    [DATA_WIDTH-1:0] mem[DEPTH-1:0]; // Memory
   
  
    assign data_out      = mem[0];
  
  
    assign empty         = (count == 0);
    assign full          = (count == DEPTH);
    assign safe_push     = push & (~full | safe_pop);
    assign safe_pop      = pop & ~empty;
    //assign safe_pop      = pop & (~empty | push);
  
  
    always @ (posedge clk or negedge reset_n )
      begin
        if(~reset_n)
          begin
            wr_ptr   <=  {$clog2(DATA_WIDTH){1'b0}};
            count    <=  {$clog2(DATA_WIDTH){1'b0}};
            for(i=0; i < DEPTH; i=i+1)
              mem[i] <= 0;
          end
      else
        begin
          if(clear_pointers)
            begin
              wr_ptr  <= {$clog2(DATA_WIDTH){1'b0}};
              count   <= {$clog2(DATA_WIDTH){1'b0}};
            end
          else
            begin
              if(safe_push & ~safe_pop)
                begin
                  mem[wr_ptr]  <= data_in;
                  if(wr_ptr != DEPTH_MIN1)
                    wr_ptr     <= (wr_ptr + 1);
                end
              else if(~safe_push & safe_pop)
                begin
                  for(i=1; i < DEPTH; i= i+1)
                    mem[i-1]  <= mem[i];
                  if(~full)
                    wr_ptr    <= (wr_ptr - 1);
                end
              else if(safe_push & safe_pop)
                begin
                  for(i=1; i < DEPTH; i= i+1)
                    begin
                      if(~full & (wr_ptr == i))
                        mem[i-1]  <= data_in;
                      else
                        mem[i-1]  <= mem[i];
                    end
                    mem[DEPTH-1]  <= data_in;
                end
  
              if(safe_push & ~safe_pop)
                count          <= (count + 1);
              else if(~safe_push & safe_pop)
                count          <= (count - 1);
            end
          end
       end
  
  
  
  endmodule
  
  
  
  

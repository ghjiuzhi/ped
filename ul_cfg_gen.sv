
//    Copyright (c) 2022 JOJO300, Inc.
//    All Rights Reserved.
//***********************************************************************
//-----------------------------------------------------------------------
// File:        ul_cfg_gen.sv
// Auther:      KEJOJO300 
// Created:     15:35:35, Oct 15, 2025
//-----------------------------------------------------------------------
// Abstract:    ADD DESCRIPTION HERE
// config module to ped64 & bhp_128
//-----------------------------------------------------------------------
module ul_cfg_gen(
    input clk,
    input rst_n,
    //--  csr interface -- //
    input syn_rst,             // soft reset
    //--  soc interface -- //
    output soc_req,
    input soc_valid,
    input [32-1:0] soc_cfg_data,
    //--  operator interface -- //
    input ul_req,
    input [32-1:0] ul_addr,
    output ul_valid,
    output reg [256-1:0] ul_cfg_data_ch0,
    output reg [256-1:0] ul_cfg_data_ch1,
    output reg [256-1:0] ul_cfg_data_ch2,
    output reg [256-1:0] ul_cfg_data_ch3,
    output reg [256-1:0] ul_cfg_data_ch4,
    output reg [256-1:0] ul_cfg_data_ch5,
    output reg [256-1:0] ul_cfg_data_ch6,
    output reg [256-1:0] ul_cfg_data_ch7

);

`define UL_STATE_WIDTH 7
 `fsm_param_decl(CFG_IDLE,CFG_IDLE_BIT,0)    
 `fsm_param_decl(UL_REQ,UL_REQ_BIT,1)
 `fsm_param_decl(SOC_REQ,SOC_REQ_BIT,2)
 `fsm_param_decl(ADDR_CHK,ADDR_CHK_BIT,3)
 `fsm_param_decl(UL_RESP,UL_RESP_BIT,4)
 `fsm_param_decl(UL_CFG_FIN,UL_CFG_FIN_BIT,5)
 `fsm_param_decl(ADDR_CHK_FAILED,ADDR_CHK_FAILED_BIT,6)


//----------------------------------------------------- 
//   LOCAL WIRE & REG DECLARATIONS.
//-----------------------------------------------------
reg [`UL_STATE_WIDTH-1 :0] ul_cfg_state_nxt;
reg [`UL_STATE_WIDTH-1 :0] ul_cfg_state;

wire addr_match; 
wire addr_mismatch; 
wire ul_resp_done = 1'b1;

wire cfg_fifo_push;
wire cfg_fifo_pop;
wire [32-1:0] cfg_fifo_wdata;
wire cfg_fifo_empty;
wire cfg_fifo_full;
wire [5-1:0] cfg_fifo_cnt;
wire [32-1:0] cfg_fifo_rdata;
wire fifo_ready ;

reg [256-1:0] ul_cfg_data_lat_nxt;
reg [256-1:0] ul_cfg_data_lat;
reg [256-1:0] ul_cfg_data_lat_ch0;
reg [256-1:0] ul_cfg_data_lat_ch1;
reg [256-1:0] ul_cfg_data_lat_ch2;
reg [256-1:0] ul_cfg_data_lat_ch3;
reg [256-1:0] ul_cfg_data_lat_ch4;
reg [256-1:0] ul_cfg_data_lat_ch5;
reg [256-1:0] ul_cfg_data_lat_ch6;
reg [256-1:0] ul_cfg_data_lat_ch7;
reg [3-1:0] combine_cnt8;
wire combine_cnt8_done;
reg [3-1:0] round_combine_cnt8;
wire round_combine_cnt8_done;
reg [32-1:0] operator_addr;
reg [32-1:0] soc_cfg_addr;
//----------------------------------------------------- 
//   inst
//-----------------------------------------------------
  pp_fifo #(.DEPTH(`UL_CFG_FIFO_DEPTH),.DATA_WIDTH(32))   
                          u_soc_cfg_fifo(
  .clk                    (clk),           // Clock
  .reset_n                (rst_n),        // Reset
  .clear_pointers         (syn_rst), // Clear FIFO
  .push                   (cfg_fifo_push),           // FIFO Data In Push
  .pop                    (cfg_fifo_pop),           // FIFO Data In Pop
  .data_in                (cfg_fifo_wdata),        // Data Input
  .empty                  (cfg_fifo_empty),          // FIFO Empty Flag
  .full                   (cfg_fifo_full),          // FIFO Full Flag
  .count                  (cfg_fifo_cnt),          // count
  .data_out               (cfg_fifo_rdata)       // Data Output
    );

//----------------------------------------------------- 
//   comb
//-----------------------------------------------------
always@(*)
begin :CFG_STATE_OPERA
    case(1'b1)
        ul_cfg_state[CFG_IDLE_BIT] :
            begin
                ul_cfg_state_nxt = ul_req ? UL_REQ : ul_cfg_state;
            end
        ul_cfg_state[UL_REQ_BIT]:
            begin
                ul_cfg_state_nxt = SOC_REQ ;
              end
        ul_cfg_state[SOC_REQ_BIT]:
            begin
                ul_cfg_state_nxt = (soc_valid) ? ADDR_CHK : ul_cfg_state;
            end
        ul_cfg_state[ADDR_CHK_BIT]:
        begin
                ul_cfg_state_nxt = (addr_match  & fifo_ready ) ? UL_RESP :
                                   (addr_mismatch            ) ? ADDR_CHK_FAILED:
                                   ul_cfg_state;
            end
        ul_cfg_state[UL_RESP_BIT]:
            begin
                ul_cfg_state_nxt = (ul_resp_done) ? UL_CFG_FIN :ul_cfg_state ;
            end
        ul_cfg_state[UL_CFG_FIN_BIT]:
            begin
                ul_cfg_state_nxt = (!soc_valid) ? CFG_IDLE: ul_cfg_state;
            end
        ul_cfg_state[ADDR_CHK_FAILED_BIT]:
            begin
              ul_cfg_state_nxt = (!soc_valid) ? UL_REQ: ul_cfg_state;
            end
      default:ul_cfg_state_nxt = CFG_IDLE;
    endcase

end


always@(*)
begin:CONVERT_32_256
    case(combine_cnt8)
`ifdef MSB_ADV
      3'd0: ul_cfg_data_lat_nxt = {cfg_fifo_rdata,{7{32'd0}}                                };
      3'd1: ul_cfg_data_lat_nxt = {ul_cfg_data_lat[256-1:256-32]  ,cfg_fifo_rdata   ,{6{32'd0}}};
      3'd2: ul_cfg_data_lat_nxt = {ul_cfg_data_lat[256-1:256-32*2],cfg_fifo_rdata   ,{5{32'd0}}};
      3'd3: ul_cfg_data_lat_nxt = {ul_cfg_data_lat[256-1:256-32*3],cfg_fifo_rdata   ,{4{32'd0}}};
      3'd4: ul_cfg_data_lat_nxt = {ul_cfg_data_lat[256-1:256-32*4],cfg_fifo_rdata   ,{3{32'd0}}};
      3'd5: ul_cfg_data_lat_nxt = {ul_cfg_data_lat[256-1:256-32*5],cfg_fifo_rdata   ,{2{32'd0}}};
      3'd6: ul_cfg_data_lat_nxt = {ul_cfg_data_lat[256-1:256-32*6],cfg_fifo_rdata   ,{1{32'd0}}};
      3'd7: ul_cfg_data_lat_nxt = {ul_cfg_data_lat[256-1:256-32*7],cfg_fifo_rdata              };
`else
        3'd0: ul_cfg_data_lat_nxt = {{7{32'd0}},cfg_fifo_rdata};
        3'd1: ul_cfg_data_lat_nxt = {{6{32'd0}},cfg_fifo_rdata,  ul_cfg_data_lat[32-1:0]};
        3'd2: ul_cfg_data_lat_nxt = {{5{32'd0}},cfg_fifo_rdata,  ul_cfg_data_lat[32*2-1:0]};
        3'd3: ul_cfg_data_lat_nxt = {{4{32'd0}},cfg_fifo_rdata,  ul_cfg_data_lat[32*3-1:0]};
        3'd4: ul_cfg_data_lat_nxt = {{3{32'd0}},cfg_fifo_rdata,  ul_cfg_data_lat[32*4-1:0]};
        3'd5: ul_cfg_data_lat_nxt = {{2{32'd0}},cfg_fifo_rdata,  ul_cfg_data_lat[32*5-1:0]};
        3'd6: ul_cfg_data_lat_nxt = {{1{32'd0}},cfg_fifo_rdata,  ul_cfg_data_lat[32*6-1:0]};
        3'd7: ul_cfg_data_lat_nxt = {cfg_fifo_rdata           ,  ul_cfg_data_lat[32*7-1:0]};
`endif
        default: ul_cfg_data_lat_nxt = ul_cfg_data_lat;
    endcase
end

assign combine_cnt8_done = &combine_cnt8;
// assign round_combine_cnt8_done = &round_combine_cnt8;
assign round_combine_cnt8_done = round_combine_cnt8 == 2'd1;
assign soc_req = ul_cfg_state[UL_REQ_BIT];

assign addr_match = ~|(operator_addr^soc_cfg_addr) & ul_cfg_state[ADDR_CHK_BIT];
assign addr_mismatch = |(operator_addr^soc_cfg_addr) & ul_cfg_state[ADDR_CHK_BIT];
// fifo ctrl
assign cfg_fifo_push = soc_valid & addr_match;
assign cfg_fifo_wdata = soc_cfg_data;
assign cfg_fifo_pop = !cfg_fifo_empty;
assign fifo_ready = combine_cnt8_done && round_combine_cnt8_done;
// ul out
assign ul_valid = ul_cfg_state[UL_RESP_BIT];
// chan out
always @(*) 
begin: CHAN_OUT
      ul_cfg_data_ch0 = ul_cfg_data_lat_ch0;
      ul_cfg_data_ch1 = ul_cfg_data_lat_ch1;
      ul_cfg_data_ch2 = ul_cfg_data_lat_ch2;
      ul_cfg_data_ch3 = ul_cfg_data_lat_ch3;
      ul_cfg_data_ch4 = ul_cfg_data_lat_ch4;
      ul_cfg_data_ch5 = ul_cfg_data_lat_ch5;
      ul_cfg_data_ch6 = ul_cfg_data_lat_ch6;
      ul_cfg_data_ch7 = ul_cfg_data_lat_ch7;
end



//----------------------------------------------------- 
//   seq
//-----------------------------------------------------
always@(posedge clk or negedge rst_n)
begin:CFG_STATE_UPDATE
  if(!rst_n)
    ul_cfg_state <= CFG_IDLE;
  else if(syn_rst)
    ul_cfg_state <= CFG_IDLE;
  else
    ul_cfg_state <= ul_cfg_state_nxt;
end

always@(posedge clk or negedge rst_n)
begin:CNT8
  if(!rst_n)
    combine_cnt8 <= 3'd0;
  else if(ul_cfg_state[CFG_IDLE_BIT])
    combine_cnt8 <= 3'd0;
  else if(cfg_fifo_pop)
    combine_cnt8 <= combine_cnt8 + 1'b1;
end

always@(posedge clk or negedge rst_n)
begin:CNT8_ROUND
  if(!rst_n)
    round_combine_cnt8 <= 3'd0;
  else if(ul_cfg_state[CFG_IDLE_BIT])
    round_combine_cnt8 <= 3'd0;
  else if(combine_cnt8_done)
    round_combine_cnt8 <= round_combine_cnt8 + 1'b1;
end


always@(posedge clk or negedge rst_n)
begin:LAT_DFF
  if(!rst_n)
  begin
    ul_cfg_data_lat <= 256'd0;
    ul_cfg_data_lat_ch0 <= 256'd0;
    ul_cfg_data_lat_ch1 <= 256'd0;
    ul_cfg_data_lat_ch2 <= 256'd0;
    ul_cfg_data_lat_ch3 <= 256'd0;
    ul_cfg_data_lat_ch4 <= 256'd0;
    ul_cfg_data_lat_ch5 <= 256'd0;
    ul_cfg_data_lat_ch6 <= 256'd0;
    ul_cfg_data_lat_ch7 <= 256'd0;
  end
  else if(ul_cfg_state[CFG_IDLE_BIT])
    begin
      ul_cfg_data_lat <= 256'd0;
      ul_cfg_data_lat_ch0 <= 256'd0;
      ul_cfg_data_lat_ch1 <= 256'd0;
      ul_cfg_data_lat_ch2 <= 256'd0;
      ul_cfg_data_lat_ch3 <= 256'd0;
      ul_cfg_data_lat_ch4 <= 256'd0;
      ul_cfg_data_lat_ch5 <= 256'd0;
      ul_cfg_data_lat_ch6 <= 256'd0;
      ul_cfg_data_lat_ch7 <= 256'd0;
    end
  else
  begin
    ul_cfg_data_lat <= ul_cfg_data_lat_nxt;
    case({combine_cnt8_done,round_combine_cnt8})
      {1'b1,3'd0}: ul_cfg_data_lat_ch0 <= ul_cfg_data_lat_nxt;
      {1'b1,3'd1}: ul_cfg_data_lat_ch1 <= ul_cfg_data_lat_nxt;
      {1'b1,3'd2}: ul_cfg_data_lat_ch2 <= ul_cfg_data_lat_nxt;
      {1'b1,3'd3}: ul_cfg_data_lat_ch3 <= ul_cfg_data_lat_nxt;
      {1'b1,3'd4}: ul_cfg_data_lat_ch4 <= ul_cfg_data_lat_nxt;
      {1'b1,3'd5}: ul_cfg_data_lat_ch5 <= ul_cfg_data_lat_nxt;
      {1'b1,3'd6}: ul_cfg_data_lat_ch6 <= ul_cfg_data_lat_nxt;
      {1'b1,3'd7}: ul_cfg_data_lat_ch7 <= ul_cfg_data_lat_nxt;
    endcase
  end
end

always@(posedge clk or negedge rst_n)
begin:LAT_ADDR
  if(!rst_n)
    begin
      operator_addr <= 32'hDEAD_BEEF;
      soc_cfg_addr <= 32'hDEAD_BEEF;
    end
    else if(ul_cfg_state_nxt[CFG_IDLE_BIT])
      begin
        operator_addr <= 32'hDEAD_BEEF;
        soc_cfg_addr <= 32'hDEAD_BEEF;
      end
  else 
    begin
      operator_addr <= (ul_cfg_state[UL_REQ_BIT]) ?  ul_addr : operator_addr;
      soc_cfg_addr <= (!ul_cfg_state[ADDR_CHK_BIT] & ul_cfg_state_nxt[ADDR_CHK_BIT] ) ?  soc_cfg_data : soc_cfg_addr;
    end
end




endmodule

//----------------------------------------------------- 
//   dmux2to1
//-----------------------------------------------------
module ul_dmux2to1(
  input clk,
  input rst_n,
  input ul_valid,
  input  [256-1:0] ul_cfg_data_cha,
  input  [256-1:0] ul_cfg_data_chb,
  // output
  output  ul_valid_c,
  output  [256-1:0] ul_cfg_data_chc


);

reg [256-1:0] ul_cfg_data_cha_lat;
reg [256-1:0] ul_cfg_data_chb_lat;
reg ul_valid_lat;


always @(posedge clk or negedge rst_n) 
begin
    if(!rst_n)
      begin
        ul_valid_lat <= 1'b0;
      end
    else
      begin
        ul_valid_lat <= ul_valid;
      end  
end

always @(posedge clk or negedge rst_n) 
begin
    if(!rst_n)
      begin
        ul_cfg_data_cha_lat <= 256'd0;
        ul_cfg_data_chb_lat <= 256'd0;
      end
    else if(ul_valid)
      begin
        ul_cfg_data_cha_lat <= ul_cfg_data_cha;
        ul_cfg_data_chb_lat <= ul_cfg_data_chb;
      end  
end


assign ul_valid_c = ul_valid || ul_valid_lat;
assign ul_cfg_data_chc = ul_valid     ? ul_cfg_data_cha :
                         ul_valid_lat ? ul_cfg_data_chb_lat :
                         256'd0;

endmodule


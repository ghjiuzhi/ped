module ped64_top_wrapper#(
    parameter INPUT_SIZE = 32,
    parameter FIELD_SIZE = 253
)(
/*------ped64 inf------*/
    input                           i_clk,
    input                           i_rst_n,
    input                           i_vld,
    input [INPUT_SIZE-1:0]          i_a,
    input [2:0]                     i_size,       
    input                           i_signed,     // signed is 1, unsigned is 0
    output                           o_rdy, 
    /*------TBD------*/
    input                            i_lvs_rdy,   // connect to ped64 and lossy 
    output                           o_lvs_vld,   //  connect to ped64 or lossy 
    output  [256-1:0]                o_lvs,       // ped64 width = 253, lossy_width = 256, connect to ped64 and lossy mux 
    output                           o_res_vld,
    output  [128-1:0]                o_res,       // FIELD_SIZE-> 128 ? 
    // input                            i_res_rdy,
    output                           o_last,       
/*------soc inf------*/
    output                          top_request, 
    input                           bc_in_valid, 
    input [32-1:0]                  bc_din, 

/*------lossy inf------*/
    output                 o_signed  ,
    output [3-1:0]         o_size ,
    output [8-1:0]         o_length,
    output                 o_field_ena





);

localparam IDLE         = 3'd0 ;
localparam PED64_OP     = 3'b001;
localparam PED64_FIN    = 3'b011;
localparam LOSSY_OP     = 3'b100;
localparam LOSSY_FIN    = 3'b110;
//-----------------------------------------------------------------------
// WIRE & REG DECL
//-----------------------------------------------------------------------
/*------soc signal------*/
wire soc_req;
wire soc_valid;
wire [32-1:0] soc_cfg_data;
/*------ul signal------*/
wire ul_req;
wire [32-1:0] ul_addr;
reg [32-1:0] ul_addr_soc;
wire ul_valid;
wire [256-1:0] ul_cfg_data_ch0; 
wire [256-1:0] ul_cfg_data_ch1; 
wire [256-1:0] ul_cfg_data_ch2; 
wire [256-1:0] ul_cfg_data_ch3; 
wire [256-1:0] ul_cfg_data_ch4; 
wire [256-1:0] ul_cfg_data_ch5; 
wire [256-1:0] ul_cfg_data_ch6; 
wire [256-1:0] ul_cfg_data_ch7; 
wire [256-1:0] ped64_ch0;
wire [256-1:0] ped64_ch1;
wire ul_valid_dmux;
wire [256-1:0] ul_cfg_data_chx; 
wire  o_res_vld_ped64;
wire[FIELD_SIZE-1:0]   o_res_ped64;
wire  o_lvs_vld_ped64;
wire [FIELD_SIZE-1:0] o_lvs_ped64;      // all leaves in field
wire o_rdy_ped64;
wire o_last_ped64;  
wire i_res_rdy_ped64;
wire i_lvs_rdy_ped64;
wire i_vld_ped64;
wire [INPUT_SIZE-1:0] i_a_ped64;
reg [2:0]  i_mode_ped64;
/*------lossy signal------*/
wire o_rdy_lossy;
wire i_res_rdy_lossy;
wire i_vld_lossy;
wire [FIELD_SIZE-1:0] i_a_lossy;
wire [127:0] o_res_lossy;       // calculation result
wire  [2:0] o_size_lossy;
wire o_signed_lossy;
wire i_lvs_rdy_lossy;
wire o_lvs_vld_lossy;
wire [256-1:0] o_lvs_lossy;
wire o_field_ena_lossy;  // indicate if is a 253-bit field
wire o_last_lossy;       // last leaf
wire [7:0] o_length_lossy ;
wire o_res_vld_lossy;
reg [2:0] alu_indicate;
reg [2:0] alu_indicate_nxt;
wire ped64_indicate;
wire lossy_indicate;

wire i_res_rdy;
reg [INPUT_SIZE-1:0]          i_a_lat;
reg                           i_vld_d1;
reg [2:0]                     i_size_lat;       
reg                           i_signed_lat;     // signed is 1, unsigned is 0
//-----------------------------------------------------------------------
// MISC
//-----------------------------------------------------------------------
always @(posedge i_clk or negedge i_rst_n) 
begin: LAT_CFG
    if(!i_rst_n)
        begin
            i_a_lat <= 'd0;
            i_size_lat <= 3'd0;
            i_signed_lat <= 1'b0;
        end
    else if(i_vld && o_rdy)
        begin
            i_a_lat <= i_a;
            i_size_lat <= i_size;
            i_signed_lat <= i_signed;
        end
end

always @(posedge i_clk or negedge i_rst_n) 
begin: DEY_1
    if (!i_rst_n) begin
        i_vld_d1 <= 1'b0;
    end
    else begin
        i_vld_d1 <= i_vld;
    end
end

assign top_request = soc_req;
assign soc_valid = bc_in_valid;
assign soc_cfg_data = bc_din;
assign ped64_indicate = alu_indicate_nxt[0] || ( &alu_indicate_nxt[1:0]);
assign lossy_indicate = alu_indicate_nxt[2] || ( &alu_indicate_nxt[2:1]);
// connection for top < ----> ped64  
assign i_vld_ped64 = i_vld_d1;
assign i_a_ped64 = i_a_lat;
assign o_rdy = o_rdy_ped64 &&  o_rdy_lossy;
assign i_lvs_rdy_ped64 = i_lvs_rdy;
// connection for ped64 < ---->  lossy
assign i_res_rdy_ped64 = 1'b1;
assign i_vld_lossy = o_res_vld_ped64;
assign i_a_lossy = o_res_ped64;
// connection for top < ----> lossy  
assign o_lvs_vld = o_lvs_vld_ped64 || o_lvs_vld_lossy;
assign i_lvs_rdy_lossy = i_lvs_rdy;
assign o_length = ped64_indicate ? 8'd252 : o_length_lossy;       
assign o_field_ena = ped64_indicate ? (o_lvs_vld & 1'b1) :o_field_ena_lossy; 
assign o_last = o_last_lossy && o_lvs_vld_lossy;           
assign i_res_rdy_lossy = i_res_rdy;
assign o_res_vld = o_res_vld_lossy;
assign o_res = o_res_lossy;
assign o_size = o_size_lossy;
assign o_signed = o_signed_lossy;
assign o_lvs = ped64_indicate ? {3'd0,o_lvs_ped64[253-1:0]} : o_lvs_lossy;

assign i_res_rdy = 1;

always@(*) 
begin : I_MODE_MAP
    case ({i_signed_lat,i_size_lat})
        {1'b0,3'b001}:  i_mode_ped64 = 3'b000; // U8
        {1'b0,3'b010}:  i_mode_ped64 = 3'b001; // U16
        {1'b0,3'b011}:  i_mode_ped64 = 3'b010; // U32
        {1'b0,3'b100}:  i_mode_ped64 = `I_MODE_ERR; // U64  Error csr
        {1'b0,3'b101}:  i_mode_ped64 = `I_MODE_ERR; // U128  Error csr
        {1'b1,3'b001}:  i_mode_ped64 = 3'b100; // S8
        {1'b1,3'b010}:  i_mode_ped64 = 3'b101; // S16
        {1'b1,3'b011}:  i_mode_ped64 = 3'b110; // S32
        {1'b1,3'b100}:  i_mode_ped64 = `I_MODE_ERR; // S64   Error csr
        {1'b1,3'b101}:  i_mode_ped64 = `I_MODE_ERR; // S128  Error csr
        default: i_mode_ped64 = `I_MODE_ERR; // Error csr
    endcase    
end


always@(*)
begin:SOC_MMAP
    ul_addr_soc = {ul_addr[31:16],1'b0,ul_addr[15:1]};

end
//-----------------------------------------------------------------------
// ALU indicate gen
//-----------------------------------------------------------------------
always @(posedge i_clk or negedge i_rst_n) 
begin: OP_MODE
    if(!i_rst_n)
        alu_indicate <= IDLE;
    else 
        alu_indicate <= alu_indicate_nxt;
end

always@(*) 
begin : OP_MODE_NXT
    case(alu_indicate)
        IDLE:
            begin
                alu_indicate_nxt = (i_vld && o_rdy) ? PED64_OP : 
                                    alu_indicate;
            end
        PED64_OP:
            begin
                alu_indicate_nxt = ( o_res_vld_ped64) ? PED64_FIN : alu_indicate;
            end
        PED64_FIN:
            begin
                alu_indicate_nxt = LOSSY_OP;
            end
        LOSSY_OP:
            begin
                alu_indicate_nxt = (o_res_vld_lossy  ) ? LOSSY_FIN : alu_indicate;
            end
        LOSSY_FIN:
            begin
                alu_indicate_nxt = (!o_lvs_vld_lossy) ? IDLE : alu_indicate;
            end

    default: alu_indicate_nxt = IDLE;

    endcase

end


//-----------------------------------------------------------------------
// ul_cfg_gen
//-----------------------------------------------------------------------
ul_cfg_gen          u_ul_cfg_gen (
.clk                (i_clk),
.rst_n              (i_rst_n),
.syn_rst            (1'b0),
.soc_req            (soc_req),
.soc_valid          (soc_valid),
.soc_cfg_data       (soc_cfg_data),
.ul_req             (ul_req),
.ul_addr            (ul_addr_soc),
.ul_valid           (ul_valid),
.ul_cfg_data_ch0    (ul_cfg_data_ch0),
.ul_cfg_data_ch1    (ul_cfg_data_ch1),
.ul_cfg_data_ch2    (ul_cfg_data_ch2),
.ul_cfg_data_ch3    (ul_cfg_data_ch3),
.ul_cfg_data_ch4    (ul_cfg_data_ch4),
.ul_cfg_data_ch5    (ul_cfg_data_ch5),
.ul_cfg_data_ch6    (ul_cfg_data_ch6),
.ul_cfg_data_ch7    (ul_cfg_data_ch7)
  );

ul_chan_cfg         u_ul_chan_cfg (
.ul_ch_csr0         (32'd0),
.ul_cfg_data_ch0    (ul_cfg_data_ch0),
.ul_cfg_data_ch1    (ul_cfg_data_ch1),
.ul_cfg_data_ch2    (ul_cfg_data_ch2),
.ul_cfg_data_ch3    (ul_cfg_data_ch3),
.ul_cfg_data_ch4    (ul_cfg_data_ch4),
.ul_cfg_data_ch5    (ul_cfg_data_ch5),
.ul_cfg_data_ch6    (ul_cfg_data_ch6),
.ul_cfg_data_ch7    (ul_cfg_data_ch7),
.ped64_ch0          (ped64_ch0),
.ped64_ch1          (ped64_ch1)
);

ul_dmux2to1     u_ul_dmux2to1(
.clk              (i_clk),
.rst_n            (i_rst_n),
.ul_valid         (ul_valid),
.ul_cfg_data_cha  (ped64_ch0),
.ul_cfg_data_chb  (ped64_ch1),
.ul_valid_c       (ul_valid_dmux),
.ul_cfg_data_chc  (ul_cfg_data_chx)


);
//-----------------------------------------------------------------------
// ped64_no_rom
//-----------------------------------------------------------------------
ped64_no_rom #(
.INPUT_SIZE(INPUT_SIZE),
.FIELD_SIZE(FIELD_SIZE)
)               u_ped64_no_rom (
    .i_clk      (i_clk),
    .i_rst_n    (i_rst_n),

    .i_vld      (i_vld_ped64),
    .i_a        (i_a_ped64),
    .i_mode     (i_mode_ped64),
    .i_res_rdy  (i_res_rdy_ped64),
    .i_lvs_rdy  (i_lvs_rdy_ped64),      
    .o_res_vld  (o_res_vld_ped64),      
    .o_res      (o_res_ped64),
    .o_lvs_vld  (o_lvs_vld_ped64),      
    .o_lvs      (o_lvs_ped64),          
    .o_rdy      (o_rdy_ped64),
    .o_last     (o_last_ped64),
//  ul cfg interface
    .ul_req     (ul_req),
    .ul_addr    (ul_addr),
    .ul_valid   (ul_valid_dmux),
    .ul_cfg_data_chx(ul_cfg_data_chx)
);

//-----------------------------------------------------------------------
// cast_lossy
//-----------------------------------------------------------------------
cast_lossy  u_cast_lossy (
.i_clk      (i_clk),
.i_rst_n    (i_rst_n),
.i_vld      (i_vld_lossy),
.o_rdy      (o_rdy_lossy),
.i_a        (i_a_lossy),
.i_size      (i_size_lat),            
.i_signed    (i_signed_lat),            
.i_res_rdy   (i_res_rdy_lossy),
.o_res_vld   (o_res_vld_lossy),
.o_res       (o_res_lossy),
.o_size      (o_size_lossy),
.o_signed    (o_signed_lossy),
.i_lvs_rdy   (i_lvs_rdy_lossy),     
.o_lvs_vld   (o_lvs_vld_lossy),     
.o_lvs       (o_lvs_lossy),         
.o_field_ena  (o_field_ena_lossy),
.o_last       (o_last_lossy),
.o_length     (o_length_lossy)
  );


endmodule

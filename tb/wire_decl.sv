//=================================================
// WIRE REG decl
//=================================================
reg [256-1:0] rom_data_0 = 256'd0;
reg [256-1:0] rom_data_1 = 256'd0;
reg [255:0] rom_data [0:127];
logic ul_req ;
wire [32-1:0] ul_addr;
logic [32-1:0] broadcast_addr;
wire soc_req;
reg [255:0] soc_data_arr [0:1];
bit [31:0] soc_addr = 32'hA000_FFFF;
wire test_soc_valid = u_soc_if.valid;
wire[32-1:0] test_soc_cfg_data = u_soc_if.data_out;
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
wire o_last_no_rom;
wire o_lvs_vld_no_rom;
logic i_lvs_rdy_test ;

logic o_res_vld_dut;
logic [128-1:0] o_res_dut;


wire o_lvs_vld_dut;
wire [256-1:0]o_lvs_dut;


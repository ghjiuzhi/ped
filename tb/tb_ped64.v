`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/08/03 09:36:40
// Design Name: 
// Module Name: tb_ped64
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////



    parameter FIELD_SIZE = 253;

    // Inputs
    reg                      i_clk, i_rst_n, i_vld, i_res_rdy, i_lvs_rdy;
    reg [32-1:0]             i_a;
    reg [2:0]                i_mode;
    reg [7:0]                test_cnt;  // for test

    // Outputs
    wire                     o_res_vld, o_lvs_vld, o_rdy, o_last;
    wire [FIELD_SIZE-1:0]    o_res, o_lvs;
    reg i_vld_dut;
    reg [3-1:0] i_size_dut;
    reg i_signed_dut;
    wire o_rdy_dut;
    
    // PED64
    ped64 #(
        .INPUT_SIZE(32)
    ) u_ped64 (
        .i_clk      (i_clk),
        .i_rst_n    (i_rst_n),

        .i_vld      (i_vld_dut),
        .i_a        (i_a),
        .i_mode     (i_mode),

        .i_res_rdy  (i_res_rdy),
        .i_lvs_rdy  (i_lvs_rdy),

        .o_res_vld  (o_res_vld),
        .o_res      (o_res),

        .o_lvs_vld  (o_lvs_vld),
        .o_lvs      (o_lvs),

        .o_rdy      (o_rdy),
        
        .o_last     (o_last)
    );

    ped64_top_wrapper # (
        .INPUT_SIZE(32),
        .FIELD_SIZE(253)
      )
      u_ped64_top_wrapper (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .i_vld(i_vld_dut),
        .i_a(i_a),
        .i_size(i_size_dut),       
        .i_signed(i_signed_dut),     // signed is 1, unsigned is 0
        .i_lvs_rdy(i_lvs_rdy),
        .o_res_vld(o_res_vld_dut),
        .o_res(o_res_dut),
        .o_lvs_vld(o_lvs_vld_dut),
        .o_lvs(o_lvs_dut),
        .o_rdy(o_rdy_dut),
        .o_last(),
        .top_request(soc_req),
        .bc_in_valid(test_soc_valid),
        .bc_din(test_soc_cfg_data)
      );

    
/*    ped64_no_rom #(
        .INPUT_SIZE(32)
    ) u_ped64_no_rom (
        .i_clk      (i_clk),
        .i_rst_n    (i_rst_n),

        .i_vld      (i_vld),
        .i_a        (i_a),
        .i_mode     (i_mode),

        .i_res_rdy  (i_res_rdy),
        .i_lvs_rdy  (i_lvs_rdy),
        // .i_lvs_rdy  (i_lvs_rdy_test),

        .o_res_vld  (),
        .o_res      (),

        .o_lvs_vld  (o_lvs_vld_no_rom),
        .o_lvs      (),

        .o_rdy      (),
        
        .o_last     (o_last_no_rom),
            //  ul cfg interface
        .ul_req     (ul_req),
        .ul_addr    (ul_addr),
        .ul_valid   (ul_valid_dmux),
        .ul_cfg_data_chx(ul_cfg_data_chx)
    );*/
    
   
    initial begin
        i_lvs_rdy_test = 1'b0;
            wait(o_lvs_vld_no_rom)
                #1us;
                @(posedge i_clk)
                i_lvs_rdy_test = 1'b1;
                #200ns;
                @(posedge i_clk)
                i_lvs_rdy_test = 1'b0;
            wait(o_lvs_vld_no_rom)
                #1us;
                @(posedge i_clk)
                i_lvs_rdy_test = 1'b1;
                #200ns;
                @(posedge i_clk)
                i_lvs_rdy_test = 1'b0;
    end


    // Clock generation
    always #5 i_clk <= ~i_clk;

    // rdy random
    always @(posedge i_clk or negedge i_rst_n) begin
        if (~i_rst_n) begin
            i_res_rdy <= 1'b0;
            i_lvs_rdy <= 1'b0;
        end else begin
            i_lvs_rdy <= {$random()} % 2;
            // i_lvs_rdy <= 1'b1;
            i_res_rdy <= {$random()} % 2;
        end
    end



    initial begin
        // Init signals
        i_clk <= 0;
        i_rst_n <= 0;
        i_vld_dut <= 1'b0;
        i_a   <=  'b0;
        // i_vld <= 0;
        i_a <= 0;
        i_mode <= 0;
        i_res_rdy <= 0;
        i_lvs_rdy <= 0;
        i_mode<=  'd0; 
        i_signed_dut = 1'b0; 
        i_size_dut = 3'b000;

        // Apply reset
        #20us;
        i_rst_n <= 1;
        wait(o_rdy_dut)
        i_vld_dut <= 1'b1;
        i_a   <=  32'hca;
        // i_a   <=  32'd2749083748;
        i_mode<=  3'b100;
        i_signed_dut = 1'b1; 
        i_size_dut = 3'b001;
        @(posedge i_clk);
        i_vld_dut <= 1'b0;
        i_a   <=  32'h00;
        i_mode<=  3'b000;
        i_signed_dut = 1'b0; 
        i_size_dut = 3'b000;
        #20;

        // @(posedge i_clk);
        // i_a <= 'd181;
        // i_mode <= 3'b000;
        // i_vld     <= 1'b1;

        // @(posedge i_clk);
        // i_a <= 'd181;
        // i_mode <= 3'b000;
        // i_vld     <= 1'b0;

    end

    // test cnt
    always @(posedge o_lvs_vld or negedge i_rst_n) begin
        if (~i_rst_n) begin
            test_cnt <= 'b0;
        end else begin
            test_cnt <= test_cnt + 1;
        end
    end


// =====================================================
//  res_monitor
// =====================================================
res_monitor #(
    .DATA_WIDTH  (128),
    .MONITOR_NAME("RES_LOSSY_MON")
) u_mon_dut_top (
    .clk       (i_clk),
    .rst_n     (i_rst_n),
    .res_valid (o_res_vld_dut),
    .res_data  (o_res_dut)
);





/*
dual_res_monitor #(
        .DATA_WIDTH0   (253),
        .DATA_WIDTH1   (253),
        .MONITOR_NAME ("GOLDEN_VS_RES")
) u_dual_mon_res (
        .clk          (i_clk),
        .rst_n        (i_rst_n),
        .res_valid_0  (o_res_vld),
        .res_data_0   (o_res),
        .res_valid_1  (SVT_top.u_ped64_top_wrapper.u_ped64_no_rom.o_res_vld),
        .res_data_1   (SVT_top.u_ped64_top_wrapper.u_ped64_no_rom.o_res[252:0])
    );*/

    dual_res_monitor #(
        .DATA_WIDTH0   (253),
        .DATA_WIDTH1   (253),
        .MONITOR_NAME ("GOLDEN_VS_LVS")
    ) u_dual_mon_lvs (
        .clk          (i_clk),
        .rst_n        (i_rst_n),
        .res_valid_0  (o_lvs_vld),
        .res_data_0   (o_lvs),
        .res_valid_1  (SVT_top.u_ped64_top_wrapper.u_ped64_no_rom.o_lvs_vld),
        .res_data_1   (SVT_top.u_ped64_top_wrapper.u_ped64_no_rom.o_lvs[252:0])
    );

lvs_checker         u_lvs_checker(
.clk                (i_clk),      // Clock
.rst_n              (i_rst_n),    // Active-low reset
.valid              (o_lvs_vld_dut && i_lvs_rdy),    // Data valid signal
.lvs_in             (o_lvs_dut)   // 256-bit input data (8 x 32-bit words)
);
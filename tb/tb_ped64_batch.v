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


module tb_ped64_batch;

    parameter FIELD_SIZE = 253;

    // Inputs
    reg                      i_clk, i_rst_n, i_vld, i_res_rdy, i_lvs_rdy;
    reg [32-1:0]             i_a;
    reg [2:0]                i_mode;
    reg [7:0]                test_cnt;  // for test

    // Outputs
    wire                     o_res_vld, o_lvs_vld, o_rdy, o_last;
    wire [FIELD_SIZE-1:0]    o_res, o_lvs;

    
    // PED64
    ped64 #(
        .INPUT_SIZE(32)
    ) u_ped64 (
        .i_clk      (i_clk),
        .i_rst_n    (i_rst_n),

        .i_vld      (i_vld),
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

    
    // Clock generation
    always #5 i_clk <= ~i_clk;

    // rdy random
    always @(posedge i_clk or negedge i_rst_n) begin
        if (~i_rst_n) begin
            i_res_rdy <= 1'b0;
            i_lvs_rdy <= 1'b0;
        end else begin
            i_lvs_rdy <= {$random()} % 2;
            i_res_rdy <= {$random()} % 2;
        end
    end

    // i_vld random
    always @(posedge i_clk or negedge i_rst_n) begin
        if (~i_rst_n) begin
            i_vld <= 1'b0;
            i_a   <=  'b0;
            i_mode<=  'b0;  
        end else begin
            i_vld <= {$random()} % 2;
            i_a   <=  1692970200;  // data
            i_mode<=  'b110;   // 000=U8, 001=U16, 010=U32, 100=I8, 101=I16, 110=I32 
        end
    end

    initial begin
        // Init signals
        i_clk <= 0;
        i_rst_n <= 0;
        // i_vld <= 0;
        i_a <= 0;
        i_mode <= 0;
        i_res_rdy <= 0;
        i_lvs_rdy <= 0;

        // Apply reset
        #20;
        i_rst_n <= 1;
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
endmodule
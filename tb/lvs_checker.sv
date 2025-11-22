// Copyright (c) 2022 JOJO300, Inc.
// All Rights Reserved.
//***********************************************************************
//-----------------------------------------------------------------------
// File: lvs_checker.sv
// Author: KEJOJO300
// Created: 21:48:06, Nov 11, 2025
//-----------------------------------------------------------------------
// Abstract: LVS golden-data checker
//   - Capture 256-bit data on valid rising edge
//   - Store in dynamic queue
//   - Compare with golden array at $finish
//-----------------------------------------------------------------------


module lvs_checker (
    input  logic        clk,      // Clock
    input  logic        rst_n,    // Active-low reset
    input  logic        valid,    // Data valid signal
    input  logic [255:0] lvs_in   // 256-bit input data (8 x 32-bit words)
);

    // --------------------------------------------------------------------
    // Dynamic queue to store captured LVS data
    // --------------------------------------------------------------------
    logic [255:0] stored_lvs [$];

    // --------------------------------------------------------------------
    // Golden reference data (44 entries)
    // --------------------------------------------------------------------
// --------------------------------------------------------------------
// Golden reference data (44 entries) - \u4f7f\u7528 initial \u9010\u4e2a\u8d4b\u503c
// --------------------------------------------------------------------
logic [255:0] golden_lvs [0:47-1];

initial begin
    golden_lvs[0]  = 256'h0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000;
    golden_lvs[1]  = 256'h0196_2d1e_823a_dfc0_d0c3_e61b_805f_8645_a602_4555_2b7b_2193_4da0_7305_ad74_4a15;
    golden_lvs[2]  = 256'h023a_a55e_6bf0_77ca_77b4_1c12_c7c1_fc26_1528_46b1_aa9c_d7ae_83ff_c586_d81f_52b4;
    golden_lvs[3]  = 256'h031f_15eb_43d5_5cbc_7fc3_312c_766e_46a8_aa14_535d_ee07_b38e_cdbc_6a58_aaf4_5a19;
    golden_lvs[4]  = 256'h0da9_a48a_288d_27ac_4391_979d_96a8_c8d9_e855_cd00_896f_8f48_1d22_7f53_b9b0_99b9;
    golden_lvs[5]  = 256'h0e58_4365_0358_d409_72e6_5cb2_116e_c3aa_7ac9_2a55_2e83_39f7_2e95_6813_ab62_7be9;
    golden_lvs[6]  = 256'h0686_64f8_2ebf_9934_11b6_6eb0_6fea_f96f_1f5f_52d4_c6e2_bae9_b08f_9099_2a4b_84b9;
    golden_lvs[7]  = 256'h0e61_7aee_8bde_c27b_77f7_df3f_41be_b376_0e57_42c4_6b12_41d2_0c4c_89a2_3e8a_6b15;
    golden_lvs[8]  = 256'h002a_b5ec_312e_3382_c082_9418_a682_2e4a_c76f_a291_0fa6_4b71_8d1f_0357_e002_0450;
    golden_lvs[9]  = 256'h0e8c_30da_bd0c_f5fe_387a_7357_e840_e1c0_d5c6_e555_7ab8_8d43_996b_8cfa_1e8c_6f65;
    golden_lvs[10] = 256'h0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000;
    golden_lvs[11] = 256'h0e61_7aee_8bde_c27b_77f7_df3f_41be_b376_0e57_42c4_6b12_41d2_0c4c_89a2_3e8a_6b15;
    golden_lvs[12] = 256'h0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000;
    golden_lvs[13] = 256'h0e61_7aee_8bde_c27b_77f7_df3f_41be_b376_0e57_42c4_6b12_41d2_0c4c_89a2_3e8a_6b15;
    golden_lvs[14] = 256'h002a_b5ec_312e_3382_c082_9418_a682_2e4a_c76f_a291_0fa6_4b71_8d1f_0357_e002_0450;
    golden_lvs[15] = 256'h07f7_8503_e8c0_dd7a_14b0_bb44_db93_933a_66d6_3c78_8c65_249e_5676_da03_2d76_346a;
    golden_lvs[16] = 256'h0dbc_386d_c2fa_64a6_0116_c949_c90e_0b0b_51d8_b4c9_6bbd_40cd_6827_d91b_99e5_ba5f;
    golden_lvs[17] = 256'h07bf_113f_7bba_0199_4154_94a0_2a57_1893_307e_7755_6ead_b0f0_0bab_a210_cf40_55c4;
    golden_lvs[18] = 256'h00a6_c598_4f8f_94e5_6826_5aeb_7dd3_503a_7682_78d6_a01d_7644_ca44_92b7_4a80_1555;
    golden_lvs[19] = 256'h0237_bad0_0296_02f2_4100_430b_ae5f_31dc_af15_8136_a49e_a664_d129_1070_f96f_d3cc;
    golden_lvs[20] = 256'h119b_d478_a006_3268_b1da_687a_9d41_f55d_6701_c181_6bcc_27e0_d7d5_81e4_5520_7649;
    golden_lvs[21] = 256'h0128_29ea_086f_9004_9226_5e67_ef69_7738_bc6c_cbb9_406a_ce44_9eed_1255_4e90_4a14;
    golden_lvs[22] = 256'h0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000;
    golden_lvs[23] = 256'h0237_bad0_0296_02f2_4100_430b_ae5f_31dc_af15_8136_a49e_a664_d129_1070_f96f_d3cc;
    golden_lvs[24] = 256'h0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000;
    golden_lvs[25] = 256'h0237_bad0_0296_02f2_4100_430b_ae5f_31dc_af15_8136_a49e_a664_d129_1070_f96f_d3cc;
    golden_lvs[26] = 256'h119b_d478_a006_3268_b1da_687a_9d41_f55d_6701_c181_6bcc_27e0_d7d5_81e4_5520_7649;
    golden_lvs[27] = 256'h0128_29ea_086f_9004_9226_5e67_ef69_7738_bc6c_cbb9_406a_ce44_9eed_1255_4e90_4a14;
    golden_lvs[28] = 256'h0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000;
    golden_lvs[29] = 256'h0237_bad0_0296_02f2_4100_430b_ae5f_31dc_af15_8136_a49e_a664_d129_1070_f96f_d3cc;
    golden_lvs[30] = 256'h0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000;
    golden_lvs[31] = 256'h0237_bad0_0296_02f2_4100_430b_ae5f_31dc_af15_8136_a49e_a664_d129_1070_f96f_d3cc;
    golden_lvs[32] = 256'h119b_d478_a006_3268_b1da_687a_9d41_f55d_6701_c181_6bcc_27e0_d7d5_81e4_5520_7649;
    golden_lvs[33] = 256'h029e_7458_32b9_e3cf_1654_9f69_59fb_4df4_10f7_1c39_0b74_7152_76bf_da9d_1608_30b6;
    golden_lvs[34] = 256'h065a_4a30_e264_7996_cfe8_a81b_3687_dcf4_074c_042a_7b4d_e739_6ce7_c012_0229_9237;
    golden_lvs[35] = 256'h0607_86dc_bfc0_7158_6452_0ffd_2258_3154_7096_308c_2dde_38a3_3235_ca2d_e8de_fb3d;
    golden_lvs[36] = 256'h00b1_933d_26fe_51f1_71d0_3781_0bdb_210d_b9e9_0aae_d830_cf71_6cf7_547b_b8b9_aa60;
    golden_lvs[37] = 256'h0318_518f_cfc9_cdbb_9483_2e13_95fa_7483_25a0_33b4_3b70_a6cc_0efb_8712_cf8a_0514;
    golden_lvs[38] = 256'h1174_3ac2_7086_c95e_6d2d_52b8_6c8f_3011_7c5f_05b5_f146_6031_491b_2477_68c6_7926;
    golden_lvs[39] = 256'h0ac1_a37c_6bf4_3426_73d3_69b9_b510_411a_112d_ac4f_071a_833a_7df0_8a81_547e_cde5;
    golden_lvs[40] = 256'h0c4b_ea9a_0630_7790_0063_0910_a4ae_3e72_2f79_4b5e_84dc_1854_ddc6_8f3c_52f5_322e;
    golden_lvs[41] = 256'h0d77_2a09_60ec_00c4_c917_50be_a31e_1140_de9f_ed25_74a0_5f24_ffc1_2658_9688_6049;
    golden_lvs[42] = 256'h0d32_c940_9392_1a9b_3933_42e6_48ce_d281_4f5f_f357_4123_b6e2_2642_3315_5046_11db;
    golden_lvs[43] = 256'h0d3d_cd30_cfcd_16b5_44da_e055_5914_41b1_9528_07fb_6c3a_aad7_0b52_a912_0141_bb78;
    golden_lvs[44] = 256'h0c08_2b01_00e2_cdcf_754e_d939_7c5b_afd5_7c17_3404_ab25_d438_37d2_82f3_3af7_c8be;
    golden_lvs[45] = 256'h8d3d_cd30_cfcd_16b5_44da_e055_5914_41b1_9528_07fb_6c3a_aad7_0b52_a912_0141_bb78;
    golden_lvs[46] = 256'h00d7_d982_1cfd_f1ea_11fd_be0c_1030_04ff_f840_00f0_36ff_ffff_ffff_efff_ffff_ffff;
                  // 256'h00d7_d982_1cfd_f1ea_11fd_be0c_1030_04ff_f840_00f0_36ff_ffff_ffff_efff_ffff_ffff
  end

    // --------------------------------------------------------------------
    // Detect rising edge of valid
    // --------------------------------------------------------------------
    logic valid_d1;
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_d1 <= 1'b0;
        end else begin
            valid_d1 <= valid;              
        end
    end

    // --------------------------------------------------------------------
    // Capture data on rising edge of valid
    // --------------------------------------------------------------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stored_lvs.delete();          
        // end else if (!valid_d1 && valid) begin
       end else if (valid) begin
            stored_lvs.push_back(lvs_in);
        end
    end

    // --------------------------------------------------------------------
    // Final comparison
    // --------------------------------------------------------------------
    final begin
        automatic int total_stored = stored_lvs.size();
        automatic int errors       = 0;

        $display("========================================");
        $display("LVS Checker: Starting comparison (%0d entries)", total_stored);
        $display("========================================");

        if (total_stored == 0) begin
            $warning("LVS Checker: No data was stored!");
        end else begin
            for (int i = 0; i < total_stored; i++) begin
               
                if (i >= 47) begin
                    $error("LVS Checker: Index %0d exceeds golden array bound!", i);
                    errors++;
                    break;
                end

               
                if (stored_lvs[i] !== golden_lvs[i]) begin
                    $error("LVS MISMATCH at index %0d:\n  EXP: %h\n  GOT: %h",
                           i, golden_lvs[i], stored_lvs[i]);
                    errors++;
                  end
                else
                    begin
                         $display(" PASS: golden_lvs = 0x%h,check_lvs = 0x%h ", golden_lvs[i],stored_lvs[i]);
                    end

            end

            if (errors == 0) begin
                $display("LVS Checker: All %0d entries match successfully!", total_stored);
            end else begin
                $display("LVS Checker: Found %0d error(s).", errors);
            end
        end
        $display("========================================");
    end

endmodule
//    Copyright (c) 2022 JOJO300, Inc.
//    All Rights Reserved.
//***********************************************************************
//-----------------------------------------------------------------------
// File:        ul_chan_cfg.sv
// Auther:      KEJOJO300 
// Created:     15:35:35, Oct 15, 2025
//-----------------------------------------------------------------------
// Abstract:    ADD DESCRIPTION HERE
// ul_cfg_gen & ped64 channel config
//-----------------------------------------------------------------------
module ul_chan_cfg(
    input [32-1:0] ul_ch_csr0, // ul_ch_csr0[2:0] --> ped64 channel select
    input [256-1:0] ul_cfg_data_ch0,
    input [256-1:0] ul_cfg_data_ch1,
    input [256-1:0] ul_cfg_data_ch2,
    input [256-1:0] ul_cfg_data_ch3,
    input [256-1:0] ul_cfg_data_ch4,
    input [256-1:0] ul_cfg_data_ch5,
    input [256-1:0] ul_cfg_data_ch6,
    input [256-1:0] ul_cfg_data_ch7,
    output reg[256-1:0] ped64_ch0,
    output reg[256-1:0] ped64_ch1

);

always @(*) 
begin:CHAN_MAP
    case (ul_ch_csr0[2:0])
    3'd0:
    begin
        ped64_ch0 = ul_cfg_data_ch0;
        ped64_ch1 = ul_cfg_data_ch1;
    end
    3'd1:
    begin
        ped64_ch0 = ul_cfg_data_ch1;
        ped64_ch1 = ul_cfg_data_ch2;
    end
    3'd2:
    begin
        ped64_ch0 = ul_cfg_data_ch2;
        ped64_ch1 = ul_cfg_data_ch3;
    end
    3'd3:
    begin
        ped64_ch0 = ul_cfg_data_ch3;
        ped64_ch1 = ul_cfg_data_ch4;
    end
    3'd4:
    begin
        ped64_ch0 = ul_cfg_data_ch4;
        ped64_ch1 = ul_cfg_data_ch5;
    end
    3'd5:
    begin
        ped64_ch0 = ul_cfg_data_ch5;
        ped64_ch1 = ul_cfg_data_ch6;
    end
    3'd6:
    begin
        ped64_ch0 = ul_cfg_data_ch6;
        ped64_ch1 = ul_cfg_data_ch7;
    end
    default: 
        begin
            ped64_ch0 = ul_cfg_data_ch0;
            ped64_ch1 = ul_cfg_data_ch1;
        end
    endcase
end

endmodule
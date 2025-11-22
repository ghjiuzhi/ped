
//    All Rights Reserved.
//***********************************************************************
//-----------------------------------------------------------------------
// File:        TB_axi_gm.sv
// Auther:      JOJO300
// Created:     12:03:23, Feb 14, 2025
//-----------------------------------------------------------------------
// Abstract:    ADD DESCRIPTION HERE
//
//-----------------------------------------------------------------------
`include "ped64_bfm.sv"
`ifdef TEST_MODE
  `include "/mnt/hgfs/work_space/bj_prj/flow_tools/init_cfg_read.sv"
`endif 

module SVT_top;

reg gm_clk = 1'b0;
reg rst_n = 1'b0;

always #10 gm_clk = ~gm_clk;
initial
begin
     rst_n = 1'b0;
    #2us;
    rst_n = 1'b0;
    #2us;
    rst_n = 1'b1;
end
`ifdef TEST_MODE

reg [199:0] test_cfg0;
reg [199:0] test_cfg1;
  initial
  begin:TEST_MODE
    $display("============================================================");
    $display(" ===================  TEST_MODE ============================");
    $display("============================================================");
    INIT_CFG_RD(test_cfg0,test_cfg1);
  end






`else
//----------------------------------------------------- 
//   LOCAL WIRE & REG DECLARATIONS.
//   -----------------------------------------------------
`include "wire_decl.sv"
//----------------------------------------------------- 
//   tb
// -----------------------------------------------------
`include "tb_ped64.v"
`include "tb_ul_cfg_gen.sv"
//----------------------------------------------------- 
//   DUT
// -----------------------------------------------------
  `endif
    




initial
begin
    #500us;

      $display("//--------- SIM FINISH ----------\\ ");
    $finish;
end
//----------------------------------------------------- 
//   print & save
// -----------------------------------------------------
`define TB_HIER SVT_top
//`define VPD
`define FSDB

initial // save wave
        begin
          `ifdef VPD
                 $display("//---------test.vpd DUMP ----------\\ ");
                $vcdplusfile("test.vpd");
                $vcdplusmemon;
                $vcdpluson;
          `endif
          `ifdef FSDB
             if ($test$plusargs("dumpfsdb_on") )
             begin
                #2us;
                $display("//--------------------------------------\\ ");
                $display("//--------- test.fsdb DUMP ----------\\ ");
                $display("//--------------------------------------\\ ");
                //$fsdbDumpfile("TestBench_Ethernet.fsdb");
                $fsdbAutoSwitchDumpfile(1024,"test.fsdb",50);
                $fsdbDumpvars(0,`TB_HIER);
                $fsdbDumpMDA();
            end
            else
            begin
                #2us;
                 $display("//--------------------------------------\\ ");
                 $display("//--------- NOT DUMP WAVE !!! ----------\\ ");
                 $display("//--------------------------------------\\ ");
                 $display("--- please add W=dumpfsdb_on ---");
            end

           `endif
        end

always #100us
    begin
       $timeformat(-6,0,"us",12);               
        $display("Simulation Time now is : %t ",$time);
      end

endmodule




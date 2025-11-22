//=====================================================
// Interface definition
//=====================================================
interface soc_cfg_send_if(input bit clk, input bit rst_n);
logic        valid;
logic [31:0] addr;
logic [31:0] data_out;
endinterface


//=====================================================
// Data sender class
//=====================================================
class soc_cfg_sender;

virtual soc_cfg_send_if vif;

// Constructor
function new(virtual soc_cfg_send_if vif);
  this.vif = vif;
  vif.valid <= 1'b0;
  vif.data_out <= '0;
endfunction

// Main send task
task send(input bit [31:0] addr, input bit [255:0] data_array [0:1]);

  int rand_delay;
  bit [512-1:0] data_concat;
  bit [31:0] data_out_word;
  vif.valid <= 1'b0;
  vif.data_out <= '0;
  
    // Concatenate the 2x256-bit blocks into one 512-bit vector
    for (int i = 0; i < 2; i++)
    begin
      data_concat[i*256 +: 256] = data_array[i];
      // $display("[data_array = %0h] ", data_array[i]);
    end
  // Wait for a random number of cycles before sending
  rand_delay = $urandom_range(1, 5);
  $display("[%0t] INFO: Waiting %0d cycles...", $time, rand_delay);
  repeat (rand_delay) @(posedge vif.clk);

  // Wait for reset release
  wait (vif.rst_n == 1);
  // $display("[%0t] INFO: Reset released, starting transmission", $time);

  // Drive address and valid
  vif.valid <= 1'b1;
  vif.addr  <= addr;
  vif.data_out <= addr;
 // $display("[%0t] INFO: Sending address = 0x%08h", $time, addr);
  // Send 16 x 32-bit words (512 bits total)
  for (int i = 0; i <= 16; i++) begin
    @(posedge vif.clk);
    if (!vif.rst_n) begin
      vif.data_out <= '0;
      vif.valid <= 1'b0;
    //  $display("[%0t] INFO: Reset asserted during transmission, aborting", $time);
      return;
    end
    data_out_word = data_concat[i*32 +: 32];
    vif.data_out <= data_out_word;
   //$display("[%0t] INFO: Sending word[%0d] = 0x%08h", $time, i, data_out_word);
  end

  // Transmission done
  vif.valid <= 1'b0;
  vif.data_out <= '0;
  // $display("[%0t] INFO: Transmission completed", $time);
endtask



endclass


//=====================================================
// Example usage in testbench
//=====================================================
// module tb_top;
//   logic clk = 0;
//   logic rst_n = 0;
//   soc_cfg_send_if sif(clk, rst_n);
//   soc_cfg_sender sender;

//   always #5 clk = ~clk;

//   initial begin
//     sender = new(sif);
//     #20 rst_n = 1;  // Release reset after 20ns
//     bit [255:0] data [0:7];
//     foreach (data[i]) data[i] = $urandom();
//     sender.send(32'hA000_0000, data);
//   end
// endmodule
function automatic logic [255:0] swap_32bit_blocks(input bit [255:0] data_array);
    swap_32bit_blocks = {<<32{data_array}};
endfunction
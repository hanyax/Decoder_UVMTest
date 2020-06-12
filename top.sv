import uvm_pkg::*;
`include "reg_item.sv"
`include "generator.sv"
`include "gen_item_seq.sv"
`include "driver.sv"
`include "monitor.sv"
`include "scoreboard.sv"
`include "agent.sv"
`include "env.sv"
`include "test.sv"
`include "top_level_4_260.sv"
`include "dat_mem.sv"


// The interface allows verification components to access DUT signals
// using a virtual interface handle
interface reg_if (input bit clk);
  logic init;
  logic wr_en;
  logic [7:0] raddr;
  logic [7:0] waddr;
  logic [7:0] rdata;
  logic [7:0] wdata;
  logic done;
  logic writealldone;

endinterface

// Top level testbench module to instantiate design, interface
// start clocks and run the test
module tb;
  reg clk;

  always #10 clk =~ clk;

  reg_if _if (clk);

  top_level_4_260 dut (
    .clk(clk),
    .init(_if.init),
    .wr_en(_if.wr_en),
    .raddr(_if.raddr),
    .waddr(_if.waddr),
    .data_in(_if.wdata),
    .data_out(_if.rdata),
    .done(_if.done) );

  test t0;

  initial begin
    clk <= 0;
    uvm_config_db#(virtual reg_if)::set(null, "uvm_test_top", "reg_vif", _if);
    run_test("test");
  end

  // System tasks to dump VCD waveform file
  initial begin
    $dumpvars;
    $dumpfile ("dump.vcd");
  end
endmodule

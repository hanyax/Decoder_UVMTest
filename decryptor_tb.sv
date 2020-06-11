`include "uvm_macros.svh"
import uvm_pkg::*;

`define ADDR_WIDTH 8
`define DATA_WIDTH 16
`define DEPTH 256

// This is the base transaction object that will be used
// in the environment to initiate new transactions and
// capture transactions at DUT interface
class reg_item extends uvm_sequence_item;
  bit [`ADDR_WIDTH-1:0] raddr;
  bit [`ADDR_WIDTH-1:0] waddr;

  bit [`DATA_WIDTH-1:0] rdata;
  bit [`DATA_WIDTH-1:0] wdata;
  bit 						      wr_en;

  // Use utility macros to implement standard functions
  // like print, copy, clone, etc
  `uvm_object_utils_begin(reg_item)
  	`uvm_field_int (raddr, UVM_DEFAULT)
    `uvm_field_int (waddr, UVM_DEFAULT)
    `uvm_field_int (rdata, UVM_DEFAULT)
  	`uvm_field_int (wdata, UVM_DEFAULT)
  	`uvm_field_int (wr_en, UVM_DEFAULT)
  `uvm_object_utils_end

  virtual function string convert2str();
    return $sformatf("raddr=0x%0h waddr=0x%0h wr_en=0x%0h rdata=0x%0h wdata=0x%0h", raddr, waddr, wr_en, rdata, wdata);
  endfunction

  function new(string name = "reg_item");
    super.new(name);
  endfunction
endclass

class generator;
  string str2;
  int str_len;
  logic [7:0] msg_padded2[64], msg_crypto2[64], msg_decryp2[64];
  logic [5:0] LFSR_ptrn[6], LFSR_init, lfsr_ptrn, lfsr2[64];
  string  str_enc2[64];
  string  str_dec2[64];
  int ct;
  int lk;
  rand bit [7:0] pre_length;
  rand int pat_sel;

  constraint c1 {pre_length > 6; pre_length < 64;}
  constraint c2 {pat_sel > 0; pat_sel < 6;}

  function new(string aString);
    str2 = aString;
    str_len = str2.len;
    LFSR_ptrn[0] = 6'h21;
    LFSR_ptrn[1] = 6'h2D;
    LFSR_ptrn[2] = 6'h30;
    LFSR_ptrn[3] = 6'h33;
    LFSR_ptrn[4] = 6'h36;
    LFSR_ptrn[5] = 6'h39;
  endfunction

  function void encrypt;
    LFSR_init = 6'h01;                     // for program 2 run
    if(!LFSR_init) begin
      //$display("illegal zero LFSR start pattern chosen, overriding with 6'h01");
      LFSR_init = 6'h01;                   // override 0 with a legal (nonzero) value
    end
    else
      //$display("LFSR starting pattern = %b",LFSR_init);
    //$display("original message string length = %d",str_len);
    for(lk = 0; lk<str_len; lk++)
      if(str2[lk]==8'h5f) continue;	       // count leading _ chars in string
    else break;                          // we shall add these to preamble pad length
    //$display("embedded leading underscore count = %d",lk);
    // precompute encrypted message
    lfsr_ptrn = LFSR_ptrn[pat_sel];        // select one of the 6 permitted tap ptrns
    // write the three control settings into data_memory of DUT

    lfsr2[0]     = LFSR_init;              // any nonzero value (zero may be helpful for debug)
    /*
    $display("run encryption of this original message: ");
    $display("%s",str2)        ;           // print original message in transcript window
    $display();
    $display("LFSR_ptrn = %h, LFSR_init = %h %h",lfsr_ptrn,LFSR_init,lfsr2[0]);
    */

    for(int j=0; j<64; j++) 			   // pre-fill message_padded with ASCII _ characters
      msg_padded2[j] = 8'h5f;
    for(int l=0; l<str_len; l++)  		   // overwrite up to 60 of these spaces w/ message itself
    msg_padded2[pre_length+l] = byte'(str2[l]);
    // compute the LFSR sequence
    for (int ii=0;ii<63;ii++) begin :lfsr_loop
      lfsr2[ii+1] = (lfsr2[ii]<<1)+(^(lfsr2[ii]&lfsr_ptrn));//{LFSR[6:0],(^LFSR[5:3]^LFSR[7])};		   // roll the rolling code
    //      $display("lfsr_ptrn %d = %h",ii,lfsr2[ii]);
    end	  :lfsr_loop
    // encrypt the message
    for (int i=0; i<64; i++) begin		   // testbench will change on falling clocks
      msg_crypto2[i]        = msg_padded2[i] ^ lfsr2[i];  //{1'b0,LFSR[6:0]};	   // encrypt 7 LSBs
      str_enc2[i]           = string'(msg_crypto2[i]);
    end

  endfunction

endclass

// The generator class is replaced by a sequence
class gen_item_seq extends uvm_sequence;
  `uvm_object_utils(gen_item_seq)
  function new(string name="gen_item_seq");
    super.new(name);
  endfunction

  rand int num; 	// Config total number of items to be sent

  constraint c1 { soft num inside {[2:5]}; }

  virtual task body();
    ///////////// DataGenerator /////////////////////////////
    ///////////// DataGenerator /////////////////////////////
    ///////////// DataGenerator /////////////////////////////

    logic [7:0] msg_in[64];

    for (int i = 0; i < num; i ++) begin
      generator gen;
      gen = new(.aString("Mr_Watson_come_here_I_want_to_see_you"));
      gen.randomize();
      gen.encrypt();
      msg_in = gen.msg_crypto2;
      for (int j = 0; j < 64; j ++) begin
      	reg_item m_item = reg_item::type_id::create("m_item");
      	start_item(m_item);
        m_item.wr_en = 'b1;
        m_item.waddr = j + 64;
        m_item.wdata = msg_in[j];
        `uvm_info("SEQ", $sformatf("Generate new item: %s", m_item.convert2str()), UVM_LOW)
        finish_item(m_item);
      end
      `uvm_info("SEQ", $sformatf("Done generation of %0d items", num), UVM_LOW)
  endtask
endclass

// The driver is responsible for driving transactions to the DUT
// All it does is to get a transaction from the mailbox if it is
// available and drive it out into the DUT interface.
class driver extends uvm_driver #(reg_item);
  `uvm_component_utils(driver)
  function new(string name = "driver", uvm_component parent=null);
    super.new(name, parent);
  endfunction

  virtual reg_if vif;

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual reg_if)::get(this, "", "reg_vif", vif))
      `uvm_fatal("DRV", "Could not get vif")
  endfunction

  virtual task run_phase(uvm_phase phase);
    super.run_phase(phase);
    forever begin
      reg_item m_item;
      `uvm_info("DRV", $sformatf("Wait for item from sequencer"), UVM_LOW)
      seq_item_port.get_next_item(m_item);
      drive_item(m_item);
      seq_item_port.item_done();
    end
  endtask

  virtual task drive_item(reg_item m_item);
      vif.sel <= 1;
      vif.addr 	<= m_item.addr;
      vif.wr 	<= m_item.wr;
      vif.wdata <= m_item.wdata;
      @ (posedge vif.clk);
      while (!vif.ready)  begin
        `uvm_info("DRV", "Wait until ready is high", UVM_LOW)
        @(posedge vif.clk);
      end

      vif.sel <= 0;
  endtask
endclass

// The monitor has a virtual interface handle with which
// it can monitor the events happening on the interface.
// It sees new transactions and then captures information
// into a packet and sends it to the scoreboard
// using another mailbox.
class monitor extends uvm_monitor;
  `uvm_component_utils(monitor)
  function new(string name="monitor", uvm_component parent=null);
    super.new(name, parent);
  endfunction

  uvm_analysis_port  #(reg_item) mon_analysis_port;
  virtual reg_if vif;
  semaphore sema4;

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual reg_if)::get(this, "", "reg_vif", vif))
      `uvm_fatal("MON", "Could not get vif")
    sema4 = new(1);
    mon_analysis_port = new ("mon_analysis_port", this);
  endfunction

  virtual task run_phase(uvm_phase phase);
    super.run_phase(phase);
    // This task monitors the interface for a complete
    // transaction and writes into analysis port when complete
    forever begin
      @ (posedge vif.clk);
      if (vif.sel) begin
        reg_item item = new;
        item.addr = vif.addr;
        item.wr = vif.wr;
        item.wdata = vif.wdata;

        if (!vif.wr) begin
          @(posedge vif.clk);
        	item.rdata = vif.rdata;
        end
        `uvm_info(get_type_name(), $sformatf("Monitor found packet %s", item.convert2str()), UVM_LOW)
        mon_analysis_port.write(item);
      end
    end
  endtask
endclass

// The scoreboard is responsible to check data integrity. Since
// the design routes packets based on an address range, the
// scoreboard checks that the packet's address is within valid
// range.
class scoreboard extends uvm_scoreboard;
  `uvm_component_utils(scoreboard)
  function new(string name="scoreboard", uvm_component parent=null);
    super.new(name, parent);
  endfunction

  reg_item refq[`DEPTH];
  uvm_analysis_imp #(reg_item, scoreboard) m_analysis_imp;

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    m_analysis_imp = new("m_analysis_imp", this);
  endfunction

  virtual function write(reg_item item);
     if (item.wr) begin
        if (refq[item.addr] == null)
          refq[item.addr] = new;

        refq[item.addr] = item;
       `uvm_info(get_type_name(), $sformatf("Store addr=0x%0h wr=0x%0h data=0x%0h", item.addr, item.wr, item.wdata), UVM_LOW)
      end

        if (!item.wr) begin
          if (refq[item.addr] == null)
            if (item.rdata != 'h1234)
              `uvm_error (get_type_name(), $sformatf("First time read, addr=0x%0h exp=1234 act=0x%0h",
                                                     item.addr, item.rdata))
          	else
              `uvm_info(get_type_name(), $sformatf("PASS! First time read, addr=0x%0h exp=1234 act=0x%0h",
                                                   item.addr, item.rdata), UVM_LOW)
          else
            if (item.rdata != refq[item.addr].wdata)
              `uvm_error (get_type_name(), $sformatf("addr=0x%0h exp=0x%0h act=0x%0h",
                                                    item.addr, refq[item.addr].wdata, item.rdata))
           else
             `uvm_info(get_type_name(), $sformatf("PASS! addr=0x%0h exp=0x%0h act=0x%0h",
                       item.addr, refq[item.addr].wdata, item.rdata), UVM_LOW)
        end
  endfunction
endclass

// Create an intermediate container called "agent" to hold
// driver, monitor and sequencer
class agent extends uvm_agent;
  `uvm_component_utils(agent)
  function new(string name="agent", uvm_component parent=null);
    super.new(name, parent);
  endfunction

  driver 		d0; 		// Driver handle
  monitor 		m0; 		// Monitor handle
  uvm_sequencer #(reg_item)	s0; 		// Sequencer Handle

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    s0 = uvm_sequencer#(reg_item)::type_id::create("s0", this);
    d0 = driver::type_id::create("d0", this);
    m0 = monitor::type_id::create("m0", this);
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    d0.seq_item_port.connect(s0.seq_item_export);
  endfunction

endclass

// The environment is a container object simply to hold
// all verification  components together. This environment can
// then be reused later and all components in it would be
// automatically connected and available for use
class env extends uvm_env;
  `uvm_component_utils(env)
  function new(string name="env", uvm_component parent=null);
    super.new(name, parent);
  endfunction

  agent 		a0; 		// Agent handle
  scoreboard	sb0; 		// Scoreboard handle

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    a0 = agent::type_id::create("a0", this);
    sb0 = scoreboard::type_id::create("sb0", this);
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    a0.m0.mon_analysis_port.connect(sb0.m_analysis_imp);
  endfunction
endclass

// Test class instantiates the environment and starts it.
class test extends uvm_test;
  `uvm_component_utils(test)
  function new(string name = "test", uvm_component parent=null);
    super.new(name, parent);
  endfunction

  env e0;
  virtual reg_if vif;

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    e0 = env::type_id::create("e0", this);
    if (!uvm_config_db#(virtual reg_if)::get(this, "", "reg_vif", vif))
      `uvm_fatal("TEST", "Did not get vif")

      uvm_config_db#(virtual reg_if)::set(this, "e0.a0.*", "reg_vif", vif);
  endfunction

  virtual task run_phase(uvm_phase phase);
    gen_item_seq seq = gen_item_seq::type_id::create("seq");
    phase.raise_objection(this);
    apply_reset();

    seq.randomize() with {num inside {[20:30]}; };
    seq.start(e0.a0.s0);
    #200;
    phase.drop_objection(this);
  endtask

  virtual task apply_reset();
    vif.rstn <= 0;
    repeat(5) @ (posedge vif.clk);
    vif.rstn <= 1;
    repeat(10) @ (posedge vif.clk);
  endtask
endclass

// The interface allows verification components to access DUT signals
// using a virtual interface handle
interface reg_if (input bit clk);
  logic init;
  logic wr_en;
  logic [7:0] raddr;
  logic [7:0] waddr;
  logic [7:0] data_in;
  logic [7:0] data_out;
  logic done;

endinterface

// Top level testbench module to instantiate design, interface
// start clocks and run the test
module tb;
  reg clk;

  always #10 clk =~ clk;
  reg_if _if (clk);

  reg_ctrl u0 ( .clk (clk),
            .addr (_if.addr),
               .rstn(_if.rstn),
            .sel  (_if.sel),
               .wr (_if.wr),
            .wdata (_if.wdata),
            .rdata (_if.rdata),
            .ready (_if.ready));

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

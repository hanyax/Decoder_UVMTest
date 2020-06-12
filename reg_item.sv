`define ADDR_WIDTH 8
`define DATA_WIDTH 8
`define DEPTH 256


// This is the base transaction object that will be used
// in the environment to initiate new transactions and
// capture transactions at DUT interface
class reg_item extends uvm_sequence_item;
  bit [`ADDR_WIDTH-1:0] waddr;

  bit [`DATA_WIDTH-1:0] msg_decryp2[64];
  bit [`DATA_WIDTH-1:0] wdata;

  // Use utility macros to implement standard functions
  // like print, copy, clone, etc
  `uvm_object_utils_begin(reg_item)
    `uvm_field_int (waddr, UVM_DEFAULT)
  for (int i = 0; i < 64; i++) begin
    `uvm_field_int (msg_decryp2[i], UVM_DEFAULT)
  end
  `uvm_object_utils_end

  /*
  virtual function string convert2str();
    return $sformatf("raddr=0x%0h waddr=0x%0h wr_en=0x%0h rdata=0x%0h wdata=0x%0h", raddr, waddr, wr_en, rdata, wdata);
  endfunction
  */

  function new(string name = "reg_item");
    super.new(name);
  endfunction
endclass

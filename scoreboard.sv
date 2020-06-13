// The scoreboard is responsible to check data integrity. Since
// the design routes packets based on an address range, the
// scoreboard checks that the packet's address is within valid
// range.
class scoreboard extends uvm_scoreboard;
  `uvm_component_utils(scoreboard)
  string str_dec2[64];
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
    string str2 = "This_is_a_test";
    for(int rr=0; rr<str2.len+1; rr++)
      str_dec2[rr] = string'(item.msg_decryp2[rr]);
    for(int i=0; i<str2.len; i++) begin
      if (str_dec2[i] != str2[i])
        `uvm_error (get_type_name(), $sformatf("FAIL: output string = %s",  item.msg_decryp2[i]))
      else
        `uvm_info(get_type_name(), $sformatf("PASS! output string = %s",  item.msg_decryp2[i]), UVM_LOW)
    end
  endfunction
endclass

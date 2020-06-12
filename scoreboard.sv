// The scoreboard is responsible to check data integrity. Since
// the design routes packets based on an address range, the
// scoreboard checks that the packet's address is within valid
// range.
class scoreboard extends uvm_scoreboard;
  `uvm_component_utils(scoreboard)
  function new(string name="scoreboard", uvm_component parent=null);
    super.new(name, parent);
    //str2 = str;
  endfunction

  reg_item refq[`DEPTH];
  uvm_analysis_imp #(reg_item, scoreboard) m_analysis_imp;

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    m_analysis_imp = new("m_analysis_imp", this);
  endfunction


  virtual function write(reg_item item);
    string str2 = "Mr_Watson_come_here_I_want_to_see_you";
    string str_dec2[64];
    for(int rr=0; rr<str2.len+1; rr++)
      str_dec2[rr] = string'(item.msg_decryp2[rr]);
    for(int i=0; i<str2.len; i++) begin
      if (str_dec2[i] != str2[i])
        `uvm_error (get_type_name(), $sformatf("FAIL: output string = %p", str_dec2)) //string format print
      else
        `uvm_info(get_type_name(), $sformatf("PASS!"), UVM_LOW)
    end
  endfunction
endclass

// The monitor has a virtual interface handle with which
// it can monitor the events happening on the interface.
// It sees new transactions and then captures information
// into a packet and sends it to the scoreboard
// using another mailbox.
class monitor extends uvm_monitor;
  `uvm_component_utils(monitor)
  //int str_len;
  //reg_item item;
  string str2 = "This_is_a_test"; //extra defi
  function new(string name="monitor",uvm_component parent=null);
    super.new(name, parent);
    //str_len = slen;
    //item = new;
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

  virtual task run_phase(uvm_phase phase); //+ read addr & data
    super.run_phase(phase);
    // This task monitors the interface for a complete
    // transaction and writes into analysis port when complete
    forever begin
      if (!vif.done )  begin
        @(posedge vif.clk);
      end else begin
        reg_item item = new;
        for(int n=0; n<str2.len+1; n++) begin
          @(posedge vif.clk);
          vif.raddr          <= n;
          @(posedge vif.clk);
          item.msg_decryp2[n] = vif.rdata;

        end
        mon_analysis_port.write(item);
      end
    end

  endtask
endclass

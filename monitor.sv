// The monitor has a virtual interface handle with which
// it can monitor the events happening on the interface.
// It sees new transactions and then captures information
// into a packet and sends it to the scoreboard
// using another mailbox.
class monitor extends uvm_monitor;
  `uvm_component_utils(monitor)
  //int str_len;
  reg_item item;
  string str2 = "Mr_Watson_come_here_I_want_to_see_you"; //extra defi
  function new(string name="monitor",uvm_component parent=null);
    super.new(name, parent);
    //str_len = slen;
    item = new;
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


      while (!vif.writealldone)  begin
        `uvm_info("DRV", "Wait until done is high", UVM_LOW)
        @(posedge vif.clk);
      end

    //reg_item item = new; weird

    for(int n=0; n<str2.len+1; n++) begin
      @(posedge vif.clk);
      vif.raddr          <= n;
      @(posedge vif.clk);
      item.msg_decryp2[n] <= vif.rdata;
    end

    mon_analysis_port.write(item);

    //forever begin

      /*
      @(posedge vif.clk);
      item.rdata = vif.rdata;

      @ (posedge vif.clk);
      reg_item item = new;
      item.raddr = vif.raddr;
      item.waddr = vif.waddr;
      item.wr_en = vif.wr_en;
      item.wdata = vif.wdata;


      `uvm_info(get_type_name(), $sformatf("Monitor found packet %s", item.convert2str()), UVM_LOW)
      mon_analysis_port.write(item);
      */

    //end
  endtask
endclass

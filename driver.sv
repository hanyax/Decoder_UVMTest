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
    vif.init <= 'b1;
    vif.writealldone <= 'b0; //all done
    forever begin //writing all nums of 64byte message :maybe need a counter?
      reg_item m_item;
      `uvm_info("DRV", $sformatf("Wait for item from sequencer"), UVM_LOW)
      seq_item_port.get_next_item(m_item);
      drive_item(m_item);
      seq_item_port.item_done();
    end
    vif.wr_en <= 'b0;
    vif.init <= 'b0;
    vif.writealldone <= 'b1;


  endtask

  virtual task drive_item(reg_item m_item);
      //vif.init <= 'b1;
    //vif.wr_en <= 'b0;
      //vif.wr_en <= m_item.wr_en;
      vif.waddr <= m_item.waddr;
      vif.wdata <= m_item.wdata;
      @ (posedge vif.clk);
      while (!vif.done)  begin
        `uvm_info("DRV", "Wait until done is high", UVM_LOW)
        @(posedge vif.clk);
      end


  endtask
endclass

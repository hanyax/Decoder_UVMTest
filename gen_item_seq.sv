// The generator class is replaced by a sequence
class gen_item_seq extends uvm_sequence;
  `uvm_object_utils(gen_item_seq)

  function new(string name="gen_item_seq");
    super.new(name);

  endfunction

  //rand int num;  // Config total number of items to be sent


  //constraint c1 { soft num inside {[2:5]}; }

  int num = 1;

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
        m_item.waddr = j + 64;
        m_item.wdata = msg_in[j];
        //`uvm_info("SEQ", $sformatf("Generate new item: %s", m_item.convert2str()), UVM_LOW)
        finish_item(m_item);
      end
    end
      `uvm_info("SEQ", $sformatf("Done generation of %0d items", num), UVM_LOW)
  endtask
endclass

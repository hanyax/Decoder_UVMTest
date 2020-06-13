// The generator class is replaced by a sequence
class gen_item_seq extends uvm_sequence;
  `uvm_object_utils(gen_item_seq)

  function new(string name="gen_item_seq");
    super.new(name);
  endfunction
  
  int num = 1;

  virtual task body();
    logic [7:0] msg_in[64];

    for (int i = 0; i < num; i ++) begin
      generator gen;
      gen = new(.aString("This_is_a_test"));
      gen.randomize();
      gen.encrypt();
      msg_in = gen.msg_crypto2;

      for (int j = 0; j < 64; j ++) begin
        reg_item m_item = reg_item::type_id::create("m_item");
        start_item(m_item);
        m_item.waddr = j + 64;
        m_item.wdata = msg_in[j];
        finish_item(m_item);
      end
    end
      `uvm_info("SEQ", $sformatf("Done generation of %0d items", num), UVM_LOW)
  endtask
endclass

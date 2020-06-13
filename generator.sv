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
      LFSR_init = 6'h01;                   // override 0 with a legal (nonzero) value
    end
    else
    for(lk = 0; lk<str_len; lk++)
      if(str2[lk]==8'h5f) continue;        // count leading _ chars in string
    else break;                          // we shall add these to preamble pad length

    lfsr_ptrn = LFSR_ptrn[pat_sel];        // select one of the 6 permitted tap ptrns
    // write the three control settings into data_memory of DUT

    lfsr2[0]     = LFSR_init;              // any nonzero value (zero may be helpful for debug)


    for(int j=0; j<64; j++)       // pre-fill message_padded with ASCII _ characters
      msg_padded2[j] = 8'h5f;
    for(int l=0; l<str_len; l++)       // overwrite up to 60 of these spaces w/ message itself
    msg_padded2[pre_length+l] = byte'(str2[l]);
    // compute the LFSR sequence
    for (int ii=0;ii<63;ii++) begin :lfsr_loop
      lfsr2[ii+1] = (lfsr2[ii]<<1)+(^(lfsr2[ii]&lfsr_ptrn));//{LFSR[6:0],(^LFSR[5:3]^LFSR[7])};     	// roll the rolling code

    end   :lfsr_loop
    // encrypt the message
    for (int i=0; i<64; i++) begin     // testbench will change on falling clocks
      msg_crypto2[i]        = msg_padded2[i] ^ lfsr2[i];  //{1'b0,LFSR[6:0]};    // encrypt 7 LSBs
      str_enc2[i]           = string'(msg_crypto2[i]);
    end

  endfunction

endclass

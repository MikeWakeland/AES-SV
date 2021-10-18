//==========================================================================
    localparam MUX = 1;
    localparam AES_WID = 128;

/*
Advanced Encryption Standard - 128, User's Guide
Author:  LT Michael Wakeland, Naval Postgraduate School.
				 michael.c.wakeland@gmail.com
				 +1 713 894 0975
Advisor: Professor Glenn Henry, Centaur Technology

CONTENTS:
User manual
AES_Build
KeyExpansion
Keymaker (used as part of KeyExpansion)
AES_Encrypt
AES_Decrypt

Instruction Decode and required data:
0: Idle
1: Encrypt with pre existing expanded keys [func][text_in]
2: Decrypt with pre existing expanded keys [func][text_in]
3: Generate keys ONLY; no crypt operation  [func][true_key]

Data Return Decode:
0: Both data vectors are invalid
1: Encrypt text is valid
2: Decrypt text is valid
3: KeyExpansion is complete, but no output text is valid

Providing Data:
Provide input text [127:0], keys [127:0], and function calls [1:0] synchronously.
Not every function call requires every data vector.  Unneeded vectors are registered,
but are unused if the function does not require it.  For example, when calling func 2,
the hardware will sample a [true_key], but will use the previously stored expanded keys
from previous function calls.  

Timing Delays
Users MUST provide the next function call before the previous function completes.
There is negative slack (-2 clks) between a function return and when the next function is injested.
Use Streaming Delay values to plan function calls.
If the desired operation is Idle, the Idle opcode (func 0) must be *continuously* asserted.
While in an Idle state the opcode and data is being continuously sampled, so there is no delay
between a new function call and start. 

Non-Streaming Delays:  
Key Expansion Time Delay (func 3) (input data registered => output data registered): 13 clocks
Encrypt/Decrypt Time Delay (func 1/2): 12 clocks
KeyExpansion+Encrypt/Decrypt Time Delay (func 5/6): 25 clocks

Streaming Delays:
Key Expansion Stream Delay (func 3): 11 clocks
Encrypt/Decrypt Stream Delay (func 1/2): 10 clocks

Calling an Encrypt or Decrypt function without expanding keys after reset will 
result in an operation with zeros for all round keys.  
*/

     module aes_build (
            input logic                   eph1,
            input logic                   reset,

            input logic  [1:0]            func,  //0: idle, 1: encrypt w/ existing keys: 2: decrypt w/ existing keys, 3: gen keys
            input logic  [AES_WID-1:0]    text_in, 
            input logic  [AES_WID-1:0]    true_key,
             
            output logic [1:0]            call_complete,  //0: invalid, 1: ciphertext valid, 2: plaintext valid, 3: output text invalid, but keys expanded.   
            output logic [AES_WID-1:0]    ciphertext,
            output logic [AES_WID-1:0]    plaintext
    );    

 
        logic [1:0]                  call_complete_next, func_r; 
        logic [3:0]                  enc_ctr, enc_ctr_pr, dec_ctr_pr, dec_ctr, key_ctr, key_ctr_pr,enc_ctr_next, key_ctr_next;
        logic [255:0][7:0]           SBOX;  
        logic [11:1][AES_WID-1:0]    key_words;
        logic [AES_WID-1:0]          true_key_r, text_in_r ;
        
        logic encrypt_done_next, sm_idle, sm_idle_next, sm_key, sm_key_next, sm_enc, sm_enc_next, sm_dec, sm_dec_next,  decrypt_done_next, enc_call, dec_call,        
              enc_start, dec_start, key_call, encrypt_active, decrypt_active, key_flag, accept_inputs, keys_done_next;        
        

        assign accept_inputs = sm_idle_next| //accept on idle_next to have fastest uptake on provided data while in idle state.
                               (sm_key&(key_ctr == 4'h1))| //Accept inputs when we're almost done with keys, but there's no follow on encryption.
                               (sm_enc&(enc_ctr == 4'h2))|  //accept on timing for end of encrypt/decrypt, which necessitates a return to Idle.  
                               (sm_dec&(enc_ctr == 4'h2));
                             

        /*********************************
        Register Data Inputs.
        **********************************/
        rregs_en #(2,MUX)       call   (func_r     , reset?'0:func, eph1,reset | accept_inputs);
        rregs_en #(AES_WID,MUX) datain (text_in_r  , reset?'0:text_in, eph1    ,reset | accept_inputs); 
        rregs_en #(AES_WID,MUX) keys   (true_key_r , reset?'0:true_key, eph1  ,reset | accept_inputs);  
        
        /*********************************
        Instruction decode based on the registered func
        **********************************/        
        assign key_call =  (func_r == 2'b11); 
        assign enc_call =  (func_r == 2'b01); 
        assign dec_call =  (func_r == 2'b10);         
        
        /*********************************
        Finite state machine.
        The FSM next states are whatever the registered function values are.
        Users must continuously assert a function, even if it's idle.  
        **********************************/        
        assign sm_idle_next = ~sm_enc_next & ~sm_dec_next & ~sm_key_next;
        assign sm_key_next  = key_call;
        assign sm_enc_next  = enc_call;
        assign sm_dec_next  = dec_call;

        rregs #(1) smidle (sm_idle, ~reset & sm_idle_next, eph1);
        rregs #(1) smkey  (sm_key,  ~reset & sm_key_next,  eph1);
        rregs #(1) smenc  (sm_enc,  ~reset & sm_enc_next,  eph1);
        rregs #(1) smdec  (sm_dec,  ~reset & sm_dec_next,  eph1);                 
        
        /*********************************
        Output flag setup.
        Simply creates the output flags based on counters.  The decodes are the same as input:
        0: no valid output text.
        1: ciphertext vector valid.
        2: plaintext vector valid.
        3: no valid output text, but keys are ready.  
        **********************************/          
        assign keys_done_next     = (key_ctr == 4'h0);
        assign encrypt_done_next  = (enc_ctr == 4'h1) & sm_enc;
        assign decrypt_done_next  = (enc_ctr == 4'h1) & sm_dec;
        assign call_complete_next = {decrypt_done_next|keys_done_next,encrypt_done_next|keys_done_next };       
        rregs #(2) clcmpl ( call_complete, reset? '0: call_complete_next, eph1);
  
   
        /*********************************
        Counters.
        Two counters, one for keys (11), and one for encrypt/decrypt(10). 
        **********************************/  
        assign  key_ctr_next = reset | (sm_key_next&~sm_key) |keys_done_next  ? 4'ha : (key_ctr - 1'b1); 
        rregs_en #(4,MUX) keyctr (key_ctr, key_ctr_next, eph1, reset|sm_key|sm_key_next);   
        
        assign enc_ctr_next = reset|(~sm_enc&sm_enc_next)|(~sm_dec&sm_dec_next)|(enc_ctr==4'h1) ? 4'ha : enc_ctr-1'b1; 
        rregs_en #(4,MUX) encdecry (enc_ctr, enc_ctr_next, eph1,sm_enc|sm_dec|sm_enc_next|sm_dec_next);            
        assign  dec_ctr = 4'hb - enc_ctr; 

        
         keyexpansion keysked (
          .eph1                      (eph1),
          .reset                     (reset),                            
          .start_keys                ((key_ctr == 4'ha)),
          .run_keys                  (sm_key|sm_key_next),
          .SBOX                      (SBOX),  
          .true_key                  (true_key_r),           
          .key_words                 (key_words) //Four words per round, Four bytes per word, Eight bits per byte.
          );
      
       
       aes_encrypt  aes_encrypt (
            .eph1            (eph1),
            .ready           (sm_enc),
            .cycle_ctr       (enc_ctr),
            .plain_text      (text_in_r),
            .key_words       (key_words),
            
            .SBOX            (SBOX),
            .aes_encrypted   (ciphertext)
         );

       aes_decrypt  aes_decrypt (
            .eph1            (eph1),
            .ready           (sm_dec),
            .cycle_ctr       (dec_ctr),            
            .cipher          (text_in_r),
            .key_words       (key_words),

            .plain_out       (plaintext)
         );

    endmodule:aes_build 
      
     
     
    //==========================================================================

        module keyexpansion ( 
            input   logic                      eph1,
            input   logic                      reset,
            
            input   logic                      start_keys,
            input   logic                      run_keys, 
            
            input   logic   [255:0][7:0]       SBOX,  
            input   logic   [AES_WID-1:0]      true_key,

            output  logic   [11:1][AES_WID-1:0]      key_words 
        );
      
        logic   [AES_WID-1:0]           r0k, r1k, r2k, r3k, r4k, r5k, r6k, r7k, r8k, r9k, r10k, key_gen_r, key_gen, true_key_r;
        logic                     sm_idle,  sm_start, sm_run, sm_finish, sm_idle_next, sm_start_next, sm_start_ex,
                                  sm_run_next, sm_finish_next, key_done, run_lock;  
        logic   [3:0]             cycle_ctr, cycle_ctr_pr;
        

        //---------------------------------------------------------------------
        //KEYMAKER generates every successive round key for use in KEYEXPANSION
        //----------------------------------------------------------------------   
        keymaker kymker  (
            .eph1                     (eph1),                 
            .keys_start               (start_keys),
            
            .SBOX                     (SBOX),  
            .true_key                 (true_key),  
            .key_gen_r                (key_gen_r),
            
            .key_gen                  (key_gen) //Four words per round, Four bytes per word, Eight bits per byte.
        );

        //----------------------------------------------------------------------------------------------
        //This section registers each successive round in the key generation to be tied up for storage. 
        //The output is read as the concatenation of every register value. 
        //----------------------------------------------------------------------------------------------
        assign r0k = key_gen_r;
        
        rregs_en #(AES_WID,MUX) key0  (key_gen_r , reset? '0: key_gen, eph1, (reset | run_keys));
        rregs_en #(AES_WID,MUX) key1  ( r1k  ,  reset? '0:r0k  , eph1 , run_keys | reset );  
        rregs_en #(AES_WID,MUX) key2  ( r2k  ,  reset? '0:r1k  , eph1 , run_keys | reset);
        rregs_en #(AES_WID,MUX) key3  ( r3k  ,  reset? '0:r2k  , eph1 , run_keys | reset);
        rregs_en #(AES_WID,MUX) key4  ( r4k  ,  reset? '0:r3k  , eph1 , run_keys | reset);
        rregs_en #(AES_WID,MUX) key5  ( r5k  ,  reset? '0:r4k  , eph1 , run_keys | reset);
        rregs_en #(AES_WID,MUX) key6  ( r6k  ,  reset? '0:r5k  , eph1 , run_keys | reset);
        rregs_en #(AES_WID,MUX) key7  ( r7k  ,  reset? '0:r6k  , eph1 , run_keys | reset);      
        rregs_en #(AES_WID,MUX) key8  ( r8k  ,  reset? '0:r7k  , eph1 , run_keys | reset);      
        rregs_en #(AES_WID,MUX) key9  ( r9k  ,  reset? '0:r8k  , eph1 , run_keys | reset);      
        rregs_en #(AES_WID,MUX) key10 ( r10k ,  reset? '0:r9k  , eph1 , run_keys | reset);

        assign key_words = { r10k, r9k, r8k, r7k, r6k, r5k, r4k, r3k, r2k, r1k, r0k};
  
        /***********************************************************************************************/
        /***********************************************************************************************/
        /***********************************ENDMODULE: KEYEXPANSION*************************************/
        /***********************************************************************************************/
        /***********************************************************************************************/
        endmodule: keyexpansion
          
        module keymaker (
            input   logic                      eph1,
            input   logic                      keys_start,
            input   logic   [255:0][7:0]       SBOX,  
            input   logic   [AES_WID-1:0]      true_key,
            input   logic   [3:0][3:0][7:0]    key_gen_r,  
            
            output  logic   [3:0][31:0]        key_gen
        );

        logic   [3:0][7:0]        g_out, g_in, word_sbox, word_shift;
        logic   [7:0]             old_constant, new_constant;
        logic   [7:0]             round_prefix;
      
        //----------------------------------------------------------------------------------------------------------------- 
        //G FUNCTION
        //The G function in AES takes the least significant 4x32 bit key word from the previous round as an input.
        //Only applies after the initial set of key generation (which is just the true key), for every successive key.  
        //Performs a left barrel shift on each byte of the input word, then performs an SBOX lookup for each byte.
        //This SBOX lookup is reconcantentated and forms g_out.  
        //One round worth of keys is generated per clock cycle by rregs cons.
        //------------------------------------------------------------------------------------------------------------------
        
        assign g_in  = keys_start ?  true_key[31:0] : key_gen_r[0]  ;//whatever the last word is from the last round.
        assign new_constant = (old_constant == 8'h80) ? 8'h1b : {old_constant <<1};  
        assign round_prefix = old_constant;
        
        rregs  #(8) cons ( old_constant , keys_start ? 8'b1 : new_constant , eph1); 
        
        assign word_shift = {g_in[2:0] , g_in[3]};
        
        assign word_sbox[3] = SBOX[word_shift[3]]; 
        assign word_sbox[2] = SBOX[word_shift[2]];    
        assign word_sbox[1] = SBOX[word_shift[1]];
        assign word_sbox[0] = SBOX[word_shift[0]];
        
        assign g_out = word_sbox ^ {round_prefix, 24'b0};
        //---------------
        //End G function
        //---------------    
        
        //Each successive key is dependant upon the previous key.  The first word of each four word set is modified with the g function.      
        assign key_gen[3] = keys_start ? true_key[127:96] : g_out        ^ key_gen_r[3]; 
        assign key_gen[2] = keys_start ? true_key[95:64]  : key_gen[3]   ^ key_gen_r[2];
        assign key_gen[1] = keys_start ? true_key[63:32]  : key_gen[2]   ^ key_gen_r[1];
        assign key_gen[0] = keys_start ? true_key[31:0]   : key_gen[1]   ^ key_gen_r[0]; 

        /***********************************************************************************************/
        /***********************************************************************************************/
        /***********************************ENDMODULE: KEYMAKER*****************************************/
        /***********************************************************************************************/
        /***********************************************************************************************/        
        endmodule: keymaker  



        module aes_encrypt (
              
                input logic                          eph1,
                input logic                          ready,
                input logic  [AES_WID-1:0]           plain_text,
                input logic  [11:1][AES_WID-1:0]     key_words,
                input logic [3:0]                    cycle_ctr,
                
                output logic [255:0][7:0]            SBOX,            //Passed to keyexpansion to generate the keys.
                output logic [AES_WID-1:0]           aes_encrypted     
        );
         
         
        /***************************************************************************************************************************
                                                  Decrypt SBOX, reversed for indexing purposes.
        **************************************************************************************************************************/
        assign SBOX    = '{
        //   xf    xe     xd      xc     xb      xa     x9      x8     x7      x6     x5      x4     x3     x2     x1     x0       
          8'h16, 8'hbb, 8'h54, 8'hb0, 8'h0f, 8'h2d, 8'h99, 8'h41, 8'h68, 8'h42, 8'he6, 8'hbf, 8'h0d, 8'h89, 8'ha1, 8'h8c,
          8'hdf, 8'h28, 8'h55, 8'hce, 8'he9, 8'h87, 8'h1e, 8'h9b, 8'h94, 8'h8e, 8'hd9, 8'h69, 8'h11, 8'h98, 8'hf8, 8'he1,
          8'h9e, 8'h1d, 8'hc1, 8'h86, 8'hb9, 8'h57, 8'h35, 8'h61, 8'h0e, 8'hf6, 8'h03, 8'h48, 8'h66, 8'hb5, 8'h3e, 8'h70,
          8'h8a, 8'h8b, 8'hbd, 8'h4b, 8'h1f, 8'h74, 8'hdd, 8'he8, 8'hc6, 8'hb4, 8'ha6, 8'h1c, 8'h2e, 8'h25, 8'h78, 8'hba,
          8'h08, 8'hae, 8'h7a, 8'h65, 8'hea, 8'hf4, 8'h56, 8'h6c, 8'ha9, 8'h4e, 8'hd5, 8'h8d, 8'h6d, 8'h37, 8'hc8, 8'he7,
          8'h79, 8'he4, 8'h95, 8'h91, 8'h62, 8'hac, 8'hd3, 8'hc2, 8'h5c, 8'h24, 8'h06, 8'h49, 8'h0a, 8'h3a, 8'h32, 8'he0,
          8'hdb, 8'h0b, 8'h5e, 8'hde, 8'h14, 8'hb8, 8'hee, 8'h46, 8'h88, 8'h90, 8'h2a, 8'h22, 8'hdc, 8'h4f, 8'h81, 8'h60,
          8'h73, 8'h19, 8'h5d, 8'h64, 8'h3d, 8'h7e, 8'ha7, 8'hc4, 8'h17, 8'h44, 8'h97, 8'h5f, 8'hec, 8'h13, 8'h0c, 8'hcd,
          8'hd2, 8'hf3, 8'hff, 8'h10, 8'h21, 8'hda, 8'hb6, 8'hbc, 8'hf5, 8'h38, 8'h9d, 8'h92, 8'h8f, 8'h40, 8'ha3, 8'h51,
          8'ha8, 8'h9f, 8'h3c, 8'h50, 8'h7f, 8'h02, 8'hf9, 8'h45, 8'h85, 8'h33, 8'h4d, 8'h43, 8'hfb, 8'haa, 8'hef, 8'hd0,
          8'hcf, 8'h58, 8'h4c, 8'h4a, 8'h39, 8'hbe, 8'hcb, 8'h6a, 8'h5b, 8'hb1, 8'hfc, 8'h20, 8'hed, 8'h00, 8'hd1, 8'h53,
          8'h84, 8'h2f, 8'he3, 8'h29, 8'hb3, 8'hd6, 8'h3b, 8'h52, 8'ha0, 8'h5a, 8'h6e, 8'h1b, 8'h1a, 8'h2c, 8'h83, 8'h09,
          8'h75, 8'hb2, 8'h27, 8'heb, 8'he2, 8'h80, 8'h12, 8'h07, 8'h9a, 8'h05, 8'h96, 8'h18, 8'hc3, 8'h23, 8'hc7, 8'h04,
          8'h15, 8'h31, 8'hd8, 8'h71, 8'hf1, 8'he5, 8'ha5, 8'h34, 8'hcc, 8'hf7, 8'h3f, 8'h36, 8'h26, 8'h93, 8'hfd, 8'hb7,
          8'hc0, 8'h72, 8'ha4, 8'h9c, 8'haf, 8'ha2, 8'hd4, 8'had, 8'hf0, 8'h47, 8'h59, 8'hfa, 8'h7d, 8'hc9, 8'h82, 8'hca,
          8'h76, 8'hab, 8'hd7, 8'hfe, 8'h2b, 8'h67, 8'h01, 8'h30, 8'hc5, 8'h6f, 8'h6b, 8'hf2, 8'h7b, 8'h77, 8'h7c, 8'h63 };   
      
        /***************************************************************************************************************************
                                                            AES Datapath
        Defines every successive "round" of AES, where the "inputs" are the round key and previous round's text (or plaintext).
        ***************************************************************************************************************************/

        //Round_in selects the input for the next round.
        logic [AES_WID-1:0] round_in, round_out, round_recycle, round_key;
        assign aes_encrypted  = round_recycle;   
        rregs_en #(AES_WID,MUX)  rnrec ( round_recycle , round_out , eph1, ready);
        assign round_in = (cycle_ctr == 4'ha) ? plain_text^key_words[11] : round_recycle ; 
        
        assign round_key = key_words[cycle_ctr];  
        
        logic [15:0][7:0]   sbox_in, sbox_out;      
        assign sbox_in = round_in; 
        
        //---------------------------------------------------------
        //The formal S-BOX table lookup per the technical standard. 
        //---------------------------------------------------------
        assign sbox_out[15] = SBOX[sbox_in[15]];
        assign sbox_out[14] = SBOX[sbox_in[14]]; 
        assign sbox_out[13] = SBOX[sbox_in[13]];
        assign sbox_out[12] = SBOX[sbox_in[12]];
        assign sbox_out[11] = SBOX[sbox_in[11]]; 
        assign sbox_out[10] = SBOX[sbox_in[10]];
        assign sbox_out[9]  = SBOX[sbox_in[9]] ;
        assign sbox_out[8]  = SBOX[sbox_in[8]] ;
        assign sbox_out[7]  = SBOX[sbox_in[7]] ;
        assign sbox_out[6]  = SBOX[sbox_in[6]] ;
        assign sbox_out[5]  = SBOX[sbox_in[5]] ;
        assign sbox_out[4]  = SBOX[sbox_in[4]] ;
        assign sbox_out[3]  = SBOX[sbox_in[3]] ;
        assign sbox_out[2]  = SBOX[sbox_in[2]] ;
        assign sbox_out[1]  = SBOX[sbox_in[1]] ;
        assign sbox_out[0]  = SBOX[sbox_in[0]] ;

        //----------
        //ShiftRows
        //----------
        
        //Indicies are in column-major format.
        // example, key = {b15, b14, b13,..., b2, b1, b0}.  b0 = key[AES_WID-1:120] = key[15][7:0]
        /*
        input matrix (sbox_out):      output matrix, using input indicies:
        col   i    ii    iii  iv           i     ii   iii  iv
            | b15  b11  b7   b3   |      | b15   b11  b7   b3  |  
            | b14  b10  b6   b2   |      | b10   b6   b2   b14 |
            | b13  b9   b5   b1   |  =>  | b5    b1   b13  b9  |
            | b12  b8   b4   b0   |      | b0    b12  b8   b4  |
        */    
        
        logic [15:0][7:0]    shiftrows_out;    
        //i                                      //ii                                      //iii                                      //iv
        assign shiftrows_out[15] = sbox_out[15];  assign shiftrows_out[11] = sbox_out[11];  assign shiftrows_out[7] = sbox_out[7] ;    assign shiftrows_out[3] = sbox_out[3] ;
        assign shiftrows_out[14] = sbox_out[10];  assign shiftrows_out[10] = sbox_out[6] ;  assign shiftrows_out[6] = sbox_out[2] ;    assign shiftrows_out[2] = sbox_out[14];
        assign shiftrows_out[13] = sbox_out[5] ;  assign shiftrows_out[9]  = sbox_out[1] ;  assign shiftrows_out[5] = sbox_out[13];    assign shiftrows_out[1] = sbox_out[9] ;
        assign shiftrows_out[12] = sbox_out[0] ;  assign shiftrows_out[8]  = sbox_out[12];  assign shiftrows_out[4] = sbox_out[8] ;    assign shiftrows_out[0] = sbox_out[4] ;

        //---------------------------------------------------------------------------------------------
        //MixColumns
        //Performs matrix multiplication of the left arithmetic matrix with the right ShiftRows output
        //The multiplication function is done by a left shift and additions performed by bitwise XOR.  
        //----------------------------------------------------------------------------------------------
        logic [15:0][7:0]    mixcol_in, mixcol_out; 
        
        assign mixcol_in = shiftrows_out;

         /*The false 2x multiplication is equivalent to:
        function automatic logic [7:0] x2
           (input logic [7:0]  x);
            return (x[7] ? (x<<1)^(8'h1b) : x<<1); 
        endfunction; */
        
        function automatic logic [7:0] x2
           (input logic [7:0]  x);
            return ({x[6], x[5], x[4], x[3]^x[7], x[2]^x[7], x[1], x[0]^x[7], x[7]}); 
        endfunction;  

        /*The false 3x multiplication is equivalent to: 
        function automatic logic [7:0] x3
          (input logic [7:0]  x);
           return (x[7] ? x<<1^8'h1b : {x<<1})^x;
          endfunction; */
        
        function automatic logic [7:0] x3
          (input logic [7:0]  x);
           return ({x[6]^x[7], x[5]^x[6], x[4]^x[5], x[3]^x[4]^x[7], x[2]^x[3]^x[7], x[1]^x[2], x[0]^x[1]^x[7], x[0]^x[7]});
        endfunction;

        /*   Graphical representation of the Mixcolumn operation.
        | 2 3 1 1 |       | b15 b11 b7 b3 |        | c15 c11 c7 c3 |
        | 1 2 3 1 |       | b14 b10 b6 b2 |        | c14 c10 c6 c2 |
        | 1 1 2 3 |   *   | b13 b9  b5 b1 |   =    | c13 c9  c5 c1 |
        | 3 1 1 2 |       | b12 b8  b4 b0 |        | c12 c8  c4 c0 |  
        */

        assign mixcol_out[15]  = x2(mixcol_in[15])  ^ x3(mixcol_in[14])  ^    mixcol_in[13]    ^    mixcol_in[12] ;
        assign mixcol_out[14]  =    mixcol_in[15]   ^ x2(mixcol_in[14])  ^ x3(mixcol_in[13])   ^    mixcol_in[12] ;
        assign mixcol_out[13]  =    mixcol_in[15]   ^    mixcol_in[14]   ^ x2(mixcol_in[13])   ^ x3(mixcol_in[12]);
        assign mixcol_out[12]  = x3(mixcol_in[15])  ^    mixcol_in[14]   ^    mixcol_in[13]    ^ x2(mixcol_in[12]);

        assign mixcol_out[11]  = x2(mixcol_in[11])  ^ x3(mixcol_in[10])  ^    mixcol_in[9]     ^    mixcol_in[8]  ;
        assign mixcol_out[10]  =    mixcol_in[11]   ^ x2(mixcol_in[10])  ^ x3(mixcol_in[9])    ^    mixcol_in[8]  ; 
        assign mixcol_out[9]   =    mixcol_in[11]   ^    mixcol_in[10]   ^ x2(mixcol_in[9])    ^ x3(mixcol_in[8]) ; 
        assign mixcol_out[8]   = x3(mixcol_in[11])  ^    mixcol_in[10]   ^    mixcol_in[9]     ^ x2(mixcol_in[8]) ;

        assign mixcol_out[7]   = x2(mixcol_in[7])   ^ x3(mixcol_in[6])   ^    mixcol_in[5]     ^    mixcol_in[4]  ;
        assign mixcol_out[6]   =    mixcol_in[7]    ^ x2(mixcol_in[6])   ^ x3(mixcol_in[5])    ^    mixcol_in[4]  ; 
        assign mixcol_out[5]   =    mixcol_in[7]    ^     mixcol_in[6]   ^ x2(mixcol_in[5])    ^ x3(mixcol_in[4]) ; 
        assign mixcol_out[4]   = x3(mixcol_in[7])   ^    mixcol_in[6]    ^    mixcol_in[5]     ^ x2(mixcol_in[4]) ; 

        assign mixcol_out[3]   = x2(mixcol_in[3])   ^ x3(mixcol_in[2])   ^    mixcol_in[1]     ^    mixcol_in[0]  ;
        assign mixcol_out[2]   =    mixcol_in[3]    ^ x2(mixcol_in[2])   ^ x3(mixcol_in[1])    ^    mixcol_in[0]  ;
        assign mixcol_out[1]   =    mixcol_in[3]    ^    mixcol_in[2]    ^ x2(mixcol_in[1])    ^ x3(mixcol_in[0]) ; 
        assign mixcol_out[0]   = x3(mixcol_in[3])   ^    mixcol_in[2]    ^    mixcol_in[1]     ^ x2(mixcol_in[0]) ;

        //---------------------------------------------------------------------------------------------
        //AddRoundKey
        //bitwise XORs the key with the column output, completing the AddRoundKey step.
        //The mux selects shiftrows or mixcol as an input.  The impact is to skip MixColumns if this is the last AES round. 
        //---------------------------------------------------------------------------------------------
        assign round_out = (cycle_ctr == 4'h1 ? shiftrows_out : mixcol_out)^round_key; 
     
        /***********************************************************************************************/
        /***********************************************************************************************/
        /**********************************ENDMODULE: AES_ENCRYPT***************************************/
        /***********************************************************************************************/
        /***********************************************************************************************/         
        endmodule: aes_encrypt    

        module aes_decrypt (

            input logic                           eph1,        
            input logic                           ready,         
            input logic  [AES_WID-1:0]           cipher,       
            input logic  [11:1][AES_WID-1:0]     key_words,
            input logic [3:0]                    cycle_ctr,            
            
            output logic [AES_WID-1:0]           plain_out        
             
        );

        logic [AES_WID-1:0] round_recycle, round_in, round_out;
        logic [AES_WID-1:0] round_key;
        
        //The INVSBOX has been reversed to allow for easier indexing. Still functions as designed.
        const logic [255:0][7:0] INVSBOX = '{
         8'h7d, 8'h0c, 8'h21, 8'h55, 8'h63, 8'h14, 8'h69, 8'he1, 8'h26, 8'hd6, 8'h77, 8'hba, 8'h7e, 8'h04, 8'h2b, 8'h17,
         8'h61, 8'h99, 8'h53, 8'h83, 8'h3c, 8'hbb, 8'heb, 8'hc8, 8'hb0, 8'hf5, 8'h2a, 8'hae, 8'h4d, 8'h3b, 8'he0, 8'ha0,
         8'hef, 8'h9c, 8'hc9, 8'h93, 8'h9f, 8'h7a, 8'he5, 8'h2d, 8'h0d, 8'h4a, 8'hb5, 8'h19, 8'ha9, 8'h7f, 8'h51, 8'h60, 
         8'h5f, 8'hec, 8'h80, 8'h27, 8'h59, 8'h10, 8'h12, 8'hb1, 8'h31, 8'hc7, 8'h07, 8'h88, 8'h33, 8'ha8, 8'hdd, 8'h1f, 
         8'hf4, 8'h5a, 8'hcd, 8'h78, 8'hfe, 8'hc0, 8'hdb, 8'h9a, 8'h20, 8'h79, 8'hd2, 8'hc6, 8'h4b, 8'h3e, 8'h56, 8'hfc,
         8'h1b, 8'hbe, 8'h18, 8'haa, 8'h0e, 8'h62, 8'hb7, 8'h6f, 8'h89, 8'hc5, 8'h29, 8'h1d, 8'h71, 8'h1a, 8'hf1, 8'h47,
         8'h6e, 8'hdf, 8'h75, 8'h1c, 8'he8, 8'h37, 8'hf9, 8'he2, 8'h85, 8'h35, 8'had, 8'he7, 8'h22, 8'h74, 8'hac, 8'h96,
         8'h73, 8'he6, 8'hb4, 8'hf0, 8'hce, 8'hcf, 8'hf2, 8'h97, 8'hea, 8'hdc, 8'h67, 8'h4f, 8'h41, 8'h11, 8'h91, 8'h3a, 
         8'h6b, 8'h8a, 8'h13, 8'h01, 8'h03, 8'hbd, 8'haf, 8'hc1, 8'h02, 8'h0f, 8'h3f, 8'hca, 8'h8f, 8'h1e, 8'h2c, 8'hd0, 
         8'h06, 8'h45, 8'hb3, 8'hb8, 8'h05, 8'h58, 8'he4, 8'hf7, 8'h0a, 8'hd3, 8'hbc, 8'h8c, 8'h00, 8'hab, 8'hd8, 8'h90,
         8'h84, 8'h9d, 8'h8d, 8'ha7, 8'h57, 8'h46, 8'h15, 8'h5e, 8'hda, 8'hb9, 8'hed, 8'hfd, 8'h50, 8'h48, 8'h70, 8'h6c,
         8'h92, 8'hb6, 8'h65, 8'h5d, 8'hcc, 8'h5c, 8'ha4, 8'hd4, 8'h16, 8'h98, 8'h68, 8'h86, 8'h64, 8'hf6, 8'hf8, 8'h72,
         8'h25, 8'hd1, 8'h8b, 8'h6d, 8'h49, 8'ha2, 8'h5b, 8'h76, 8'hb2, 8'h24, 8'hd9, 8'h28, 8'h66, 8'ha1, 8'h2e, 8'h08,
         8'h4e, 8'hc3, 8'hfa, 8'h42, 8'h0b, 8'h95, 8'h4c, 8'hee, 8'h3d, 8'h23, 8'hc2, 8'ha6, 8'h32, 8'h94, 8'h7b, 8'h54,
         8'hcb, 8'he9, 8'hde, 8'hc4, 8'h44, 8'h43, 8'h8e, 8'h34, 8'h87, 8'hff, 8'h2f, 8'h9b, 8'h82, 8'h39, 8'he3, 8'h7c,
         8'hfb, 8'hd7, 8'hf3, 8'h81, 8'h9e, 8'ha3, 8'h40, 8'hbf, 8'h38, 8'ha5, 8'h36, 8'h30, 8'hd5, 8'h6a, 8'h09, 8'h52};

       /***************************************************************************************************************************
                                                          AES Decrypt Datapath 
       **************************************************************************************************************************/    

        //------------------------------------------------
        //Round recycle logic, end of round n -> start of n+1:  
        //------------------------------------------------
        assign plain_out     = round_recycle;
        rregs_en #(AES_WID,MUX)  rnrecd ( round_recycle , round_out , eph1, ready);    
        assign round_in = (cycle_ctr == 4'h1) ? cipher^key_words[1] : round_recycle;                                                  
        assign round_key = key_words[cycle_ctr+1];     
          
        //-----------------------------------------------------------------------------------
        ///ShiftRows 
        // example, key = {b15, b14, b13,..., b2, b1, b0}.  b0 = key[AES_WID-1:120] = key[15][7:0]
        //----------------------------------------------------------------------------------
        /*
        input matrix (invsbox_out):      output matrix, using input indicies:
        col    i    ii    iii  iv           i     ii   iii  iv
            | b15  b11  b7   b3   |      | b15   b11  b7   b3  |  
            | b14  b10  b6   b2   |      | b2    b14  b10  b6  | 
            | b13  b9   b5   b1   |  =>  | b5    b1   b13  b9  | 
            | b12  b8   b4   b0   |      | b8    b4   b0   b12 |
        */    
      
        logic [15:0][7:0]    shiftrows_out, shiftrows_in;
        assign shiftrows_in = round_in;
        //i                                            //ii                                          //iii                                          //iv
        assign shiftrows_out[15] = shiftrows_in[15];  assign shiftrows_out[11] = shiftrows_in[11];  assign shiftrows_out[7] = shiftrows_in[7] ;   assign shiftrows_out[3] = shiftrows_in[3] ;
        assign shiftrows_out[14] = shiftrows_in[2] ;  assign shiftrows_out[10] = shiftrows_in[14];  assign shiftrows_out[6] = shiftrows_in[10];    assign shiftrows_out[2] = shiftrows_in[6] ;
        assign shiftrows_out[13] = shiftrows_in[5] ;  assign shiftrows_out[9]  = shiftrows_in[1] ;  assign shiftrows_out[5] = shiftrows_in[13];    assign shiftrows_out[1] = shiftrows_in[9] ;
        assign shiftrows_out[12] = shiftrows_in[8] ;  assign shiftrows_out[8]  = shiftrows_in[4] ;  assign shiftrows_out[4] = shiftrows_in[0] ;    assign shiftrows_out[0] = shiftrows_in[12];

        //----------------------------------------------------------------------------------
        ///InvSBOX 
        // This section performs the inverse Rijndael SBOX lookup using the table in the technical specification.
        // The byte entries used in the table lookup are reversed due to the way that SystemVerilog indexes variables,
        // but the actual bits within each byte are still the same.  
        //----------------------------------------------------------------------------------

        logic [15:0][7:0]   invsbox_out;
        
        //This section performs the actual INVSBOX table lookup, which matches the contents of the input to the 8 bit address of the INVSBOX.
        assign invsbox_out[15] = INVSBOX[shiftrows_out[15]];
        assign invsbox_out[14] = INVSBOX[shiftrows_out[14]]; 
        assign invsbox_out[13] = INVSBOX[shiftrows_out[13]];
        assign invsbox_out[12] = INVSBOX[shiftrows_out[12]];
        assign invsbox_out[11] = INVSBOX[shiftrows_out[11]]; 
        assign invsbox_out[10] = INVSBOX[shiftrows_out[10]];
        assign invsbox_out[9]  = INVSBOX[shiftrows_out[9]] ;
        assign invsbox_out[8]  = INVSBOX[shiftrows_out[8]] ;
        assign invsbox_out[7]  = INVSBOX[shiftrows_out[7]] ;
        assign invsbox_out[6]  = INVSBOX[shiftrows_out[6]] ;
        assign invsbox_out[5]  = INVSBOX[shiftrows_out[5]] ;
        assign invsbox_out[4]  = INVSBOX[shiftrows_out[4]] ;
        assign invsbox_out[3]  = INVSBOX[shiftrows_out[3]] ;
        assign invsbox_out[2]  = INVSBOX[shiftrows_out[2]] ;
        assign invsbox_out[1]  = INVSBOX[shiftrows_out[1]] ;
        assign invsbox_out[0]  = INVSBOX[shiftrows_out[0]] ;
        
        //----------------------------------------------------------------------------------
        //AddRoundKey
        //The most simple step merely XORs the Roundkey with the INVSBOX's output.
        //----------------------------------------------------------------------------------
        logic [15:0][7:0]    addkey_out;
        assign addkey_out = invsbox_out^round_key; //This accomplishes the AddRoundKey step.    
        
        //----------------------------------------------------------------------------------
        ///InvMixColumns
        // This section performs the inverse mix columns function, which is operationally equivalent to the 
        // "forward" MixColumns in the encryption step.  However, the multiplication matrix is inverted 
        //  per the technical standard.  This is the mathematical operation:
        //----------------------------------------------------------------------------------
            
        /*   Graphical representation of the Invmixcolumn operation.
        | e b d 9 |       | b15 b11 b7 b3 |        | c15 c11 c7 c3 |
        | 9 e b d |       | b14 b10 b6 b2 |        | c14 c10 c6 c2 |
        | d 9 e b |   *   | b13 b9  b5 b1 |   =   | c13 c9  c5 c1 |
        | b d 9 e |       | b12 b8  b4 b0 |        | c12 c8  c4 c0 |  
         */
         
        /* Multiplicative functions.
         All multiplicative functions in InvMixColumns (9,b,d,e) are described within 8-bit Galois Field per the standard.
         The operational multiplication for all functions has been reduced through boolean logic in the "return" of each 
         section and has been verified to be bitwise equivalent to the described operation in the standard.  
         The two base multiplications are x2 and x3, which are described as:
             
         Symbolically...
        x*9=(((x*2)*2)*2)+x
        x*b=((((x*2*2)+x*2)+x
        x*d=((((x*2)+x*2*2)+x
        x*e=((((x*2)+x*2)+x*2 
        
        Behaviorally the base operations are...
        function automatic logic [7:0] x2
           (input logic [7:0]  x);
            return (x[7] ? (x<<1)^(8'h1b) : x<<1); 
        endfunction;
        function automatic logic [7:0] x3
          (input logic [7:0]  x);
           return (x[7] ? x<<1^8'h1b : {x<<1})^x;
        endfunction;*/

        function automatic logic [7:0] x9
        (input logic [7:0]  x);
        logic n67, n50, n56;
        n67 = x[6]^x[7];
        n50 = x[5]^x[0];
        n56 = x[5]^x[6];
        return ({x[4]^x[7], x[3]^n67, x[2]^x[5]^n67 ,x[1]^x[4]^n56, x[3]^n50^x[7], x[2]^n67, x[1]^n56, n50});
        endfunction;

        function automatic logic [7:0] xb
        (input logic [7:0]  x);
        logic n35, n67, n50;
        n50 = x[5]^x[0];
        n35 = x[3]^x[5];
        n67 = x[6]^x[7];
        return ({x[4]^n67, n35^n67, x[2]^x[4]^x[5]^n67, x[1]^x[4]^n35^n67, x[2]^x[3]^n50, x[1]^x[2]^n67, x[1]^n67^n50, n50^x[7]});
        endfunction;

        function automatic logic [7:0] xd
        (input logic [7:0]  x);
        logic n17, n35, n60, n47;
        n60 = x[6]^x[0];
        n17 = x[1]^x[7];
        n35 = x[3]^x[5];
        n47 = x[4]^x[7];  
        return ({n47^x[5], x[3]^n47^x[6], x[2]^n35^x[6], n17^x[2]^x[4]^x[5], n17^n35^n60, x[2]^n60, n17^x[5], x[5]^n60}); 
        endfunction;

        function automatic logic [7:0] xe
        (input logic [7:0]  x);
        logic n35, n26, n56, n50;
        n35 = x[3]^x[5];
        n26 = x[2]^x[6];
        n56 = x[5]^x[6];
        n50 = x[5]^x[0];
        return({x[4]^n56, n35^x[4]^x[7], n26^x[3]^x[4], x[1]^x[2]^n35, x[1]^n26^n50, x[1]^x[6]^x[0], n50, n56^x[7]});
        endfunction;
           
        logic [15:0][7:0]     mixcol_out;

        assign mixcol_out[15]  =  xe(addkey_out[15])  ^ xb(addkey_out[14]) ^ xd(addkey_out[13])  ^ x9(addkey_out[12]);
        assign mixcol_out[14]  =  x9(addkey_out[15])  ^ xe(addkey_out[14]) ^ xb(addkey_out[13])  ^ xd(addkey_out[12]);
        assign mixcol_out[13]  =  xd(addkey_out[15])  ^ x9(addkey_out[14]) ^ xe(addkey_out[13])  ^ xb(addkey_out[12]);
        assign mixcol_out[12]  =  xb(addkey_out[15])  ^ xd(addkey_out[14]) ^ x9(addkey_out[13])  ^ xe(addkey_out[12]);

        assign mixcol_out[11]  =  xe(addkey_out[11])  ^ xb(addkey_out[10]) ^ xd(addkey_out[9])  ^ x9(addkey_out[8]);
        assign mixcol_out[10]  =  x9(addkey_out[11])  ^ xe(addkey_out[10]) ^ xb(addkey_out[9])  ^ xd(addkey_out[8]);
        assign mixcol_out[9]   =  xd(addkey_out[11])  ^ x9(addkey_out[10]) ^ xe(addkey_out[9])  ^ xb(addkey_out[8]);
        assign mixcol_out[8]   =  xb(addkey_out[11])  ^ xd(addkey_out[10]) ^ x9(addkey_out[9])  ^ xe(addkey_out[8]);

        assign mixcol_out[7]   =  xe(addkey_out[7])   ^ xb(addkey_out[6])  ^ xd(addkey_out[5])  ^ x9(addkey_out[4]);
        assign mixcol_out[6]   =  x9(addkey_out[7])   ^ xe(addkey_out[6])  ^ xb(addkey_out[5])  ^ xd(addkey_out[4]);
        assign mixcol_out[5]   =  xd(addkey_out[7])   ^ x9(addkey_out[6])  ^ xe(addkey_out[5])  ^ xb(addkey_out[4]);
        assign mixcol_out[4]   =  xb(addkey_out[7])   ^ xd(addkey_out[6])  ^ x9(addkey_out[5])  ^ xe(addkey_out[4]);

        assign mixcol_out[3]   =  xe(addkey_out[3])   ^ xb(addkey_out[2])  ^ xd(addkey_out[1])  ^ x9(addkey_out[0]);
        assign mixcol_out[2]   =  x9(addkey_out[3])   ^ xe(addkey_out[2])  ^ xb(addkey_out[1])  ^ xd(addkey_out[0]);
        assign mixcol_out[1]   =  xd(addkey_out[3])   ^ x9(addkey_out[2])  ^ xe(addkey_out[1])  ^ xb(addkey_out[0]);
        assign mixcol_out[0]   =  xb(addkey_out[3])   ^ xd(addkey_out[2])  ^ x9(addkey_out[1])  ^ xe(addkey_out[0]);

       //The final round does not perform InvMixColumns, so round_out selects addkey_out for the final round.  
        assign round_out = ( (cycle_ctr == 4'ha) ? addkey_out : mixcol_out); 


        /***********************************************************************************************/
        /***********************************************************************************************/
        /**********************************ENDMODULE: AES_DECRYPT***************************************/
        /***********************************************************************************************/
        /***********************************************************************************************/
        endmodule: aes_decrypt


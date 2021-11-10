    `include "aeslib_functions.sv"
    `include "muxreglib.sv"
    `define SIM  //tick commands are commands to the tools.  Tells the tools that it should go to these files and grab whats in there.  

    //----------------------------------------------
    `timescale 1ns/1ps
    module tb_top ();
 
    //----------------------------------------------
 
   localparam MAX_CLKS = 5;

   //--clock gen
   logic eph1; 
   always 
      begin
          eph1  = 1'b1;
          #1; 
          eph1 = 1'b0; 
          #1; 
      end      

    int random_num;
    logic start, reset, reset_r;
    initial begin
        reset  = 1;
        $display("Starting Proc Simulation");
        random_num = $random(1);
   
        repeat(2) @(posedge eph1);
        #1 reset= '0;
    end
    rregs resetr (reset_r, reset , eph1);
    assign start = ~reset & (reset_r ^ reset);
    
//--params to aesround
    logic [15:0][7:0]       aes_out_r;
    logic                    fin_flag_r;
  
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////Bit stuffing section - fake inputs///////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////

/*
      Software key generation commands:
      KeyExpansion( 'key' , 4 ); //4 for 128 bits, 6 for 192 bits, 8 for 256 bits
      dec2hex(ans);
      ans';
      reshape(ans,32,[]);
      ans'
      */

logic [7:0][127:0] true_key;
logic [6:0] counter, ctr_next;
logic [7:0][1:0] funccalls;
logic [7:0][127:0] plaintexts, ciphertexts, texts;
initial counter = 7'b1111111;
assign ctr_next = counter - 1;
rregs #(7) ctrnxt (counter, ctr_next, eph1);


assign true_key = 
{
128'h000102030405060708090a0b0c0d0e0f, //128'h2b7e151628aed2a6abf7158809cf4f3c 128'h000102030405060708090a0b0c0d0e0f
//128'ha456740a57d56abdea87d6a421dce66b,
128'h2ffacf31edcf8e25057143cd16ab115b,
128'h3d054ae1bb3aafb19f1d5fa1008b868f,
128'h2e2dbf252f1c41d4433bde0e7eb7ca6e,
128'h36d36da6926c5309d0f70c3b28f6dd6b,
128'h09facb6f97daa7626c56ceed953b2e17,
128'hc0a018db5c28c90d4220589ad8b15968,
128'ha1bd49d1a18210d2df2ff805be2bbd3d
};


assign funccalls = {2'h3,  2'h3, 2'h2, 2'h2, 2'h1, 2'h1, 2'h3, 2'h1};



assign texts = funccalls[counter[6:4]][0]        ?      plaintexts[counter[6:4]] :   ciphertexts[counter[6:4]]    ;
 assign plaintexts = {
 
128'h2b2a6612897c2f26af0296f4f4baafc9,
//128'hdf2b102a8e753a9e592342a33da25d56,
128'h00112233445566778899aabbccddeeff,
128'h8e4c476bb72d2db935a462f0170847a7,
128'h27563a77c6d1ef49f885945386277a66,
128'h2a74dcdd59076969f698a0868889d998,
128'h4daeba4dac3b10813ccfaa535c28fd7a,
128'h24457a8ef1536e2a9aabb203a1842d0b,
128'h2482cef5f94bbb1d3900aed8bec0fe43
};

assign ciphertexts = {
//128'h69c4e0d86a7b0430d8cdb78070b4c55a,
128'ha2437cdbfe06fef23da7ba6f78fc688a,
128'h3d606b8a6b492289090bddbcbbf3233a,
128'h1f6d3d6ffa84867abfad4d37bfa4f204,
128'h0e493cc88fb83d2c4c522bd505bedf3c,
128'hfddceb7dc2391147041776365221b254,
128'hb810dded63afd37d1d97d9f9173cad20,
128'ha183e7db87898292c241c1e385c4e6c4,
128'hb82404cd95e0a0aac93c577aaeae6de6
};
 
/*



128'h3f75fab06c4375f2880f67f11fea08ff,
128'h48bb3f68f154d2e7060d528a05d64271,
128'hbafba4f91e36a31b72bb8ddcd2335ad0,
128'h8708f206e8983b09df73772cedec28ae,
128'haa18894dd66c967bcb3ed03af737d68b,
128'h615744a04137e6dbc80e3158839fdb37,
128'h00621fda58d154878abe3bbd5fa463cc,
128'hc07a2eee13b4fd356c1571c88499a66a,
128'h86abeed5c874bd1a920cfb84994a051f,
128'h87dc7074f6959b5d8c630260899cbc03,
128'h76b6d3b1a07b63c7aacec9cb6a934426,
128'hff222888dff1e2d57ae70314ecde07f2,
128'h374585dcb5c819b647580918aa1fb31f,
128'h0b9dc5c26db1f5d5496004931e197c8b,
128'hd18664565ef938cc8b49bab39c39416f,
128'ha5be3b5c609768fa5b999e435976d0fd,
 
128'h31c6b24ee7e06973e99c443c69afb6a7,
128'h99ce37f14c5f3fbc9b1daf98d6f71428,
128'h21319caa9e4eff38cfc75f0291c6e02a,
128'h257991aead5c0cf115bc05f586e8b192,
128'hc7f41912010d1fae83db11c05d025b48,
128'he65bad18809248d2325c237249bbe1df,
128'hbcb39a84df5f16f43c4664bd9508f98d,
128'he0518706425e023f9de6e1af6c0de7aa,
128'hdaa58ecf7a47f4a17467429c87d98bc3,
128'he6b5412bac25a995ec7b3dbe3a1881bf,
128'h1d30ea92beac8affc013e25ed9e1bc75,
128'hd915296d56da33a13474d59576855a81,
128'he2fbf3488e6426c86af2714fa7941cc8,
128'hd2e354456cb1a1b2f6b68bc30b90b5b8,
128'h515317d2f070d04476ef7ec61cc62c5e,
128'h9dd8afc9e19bf95c7810a5159ef2a250,
128'hf37309d26dcec5f331e9e46592e07354,
128'h594febb83234475264a6ce80b91d1bf6,
128'h88f018404897dedc48dfb7d9fec62e02,
128'h88e5138f454dc1ba8905099aadc62f46
*/


        
/////////////////////////////////////////////////////End fake input section///////////////////////////////////////////////////////    
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


   aes_build  aes_build (
   
        .eph1        (eph1),
        .reset      (reset),

        .func      (funccalls[counter[6:4]]),
        .text_in   (texts), 
        .true_key   (true_key[counter[6:4]]),
        .call_complete (call_complete_out),
        
        .ciphertext (ciphertext_out),
        .plaintext   (plaintext_out)
     );
    
    endmodule: tb_top
 
 

 
 

    
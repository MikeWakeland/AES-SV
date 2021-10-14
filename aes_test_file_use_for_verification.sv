		`include "aeslib.sv"
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
		logic [15:0][7:0] 			aes_out_r;
		logic										fin_flag_r;
	
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

logic [127:0] true_key;
logic [6:0] counter, ctr_next;
logic [7:0][1:0] funccalls;
logic [7:0][127:0] plaintexts, ciphertexts, texts;
initial counter = 7'b1111111;
assign ctr_next = counter - 1;
rregs #(7) ctrnxt (counter, ctr_next, eph1);


assign true_key = 128'h000102030405060708090a0b0c0d0e0f;  //128'h2b7e151628aed2a6abf7158809cf4f3c 128'h000102030405060708090a0b0c0d0e0f
assign funccalls = {2'h0, 2'h0, 2'h1, 2'h1, 2'h2, 2'h2, 2'h2, 2'h2};
assign texts = funccalls[counter[6:4]][0]        ?      plaintexts[counter[6:4]] :   ciphertexts[counter[6:4]]    ;
assign plaintexts = {
128'h00112233445566778899aabbccddeeff, 
128'h00112233445566778899aabbccddeeff,
128'h00112233445566778899aabbccddeeff,
128'h00112233445566778899aabbccddeeff,
128'h00112233445566778899aabbccddeeff,
128'h00112233445566778899aabbccddeeff,
128'h00112233445566778899aabbccddeeff,
128'h00112233445566778899aabbccddeeff};

assign ciphertexts = {
128'h69c4e0d86a7b0430d8cdb78070b4c55a,
128'h69c4e0d86a7b0430d8cdb78070b4c55a,
128'h69c4e0d86a7b0430d8cdb78070b4c55a,
128'h69c4e0d86a7b0430d8cdb78070b4c55a,
128'h69c4e0d86a7b0430d8cdb78070b4c55a,
128'h69c4e0d86a7b0430d8cdb78070b4c55a,
128'h69c4e0d86a7b0430d8cdb78070b4c55a,
128'h69c4e0d86a7b0430d8cdb78070b4c55a};
				
/////////////////////////////////////////////////////End fake input section///////////////////////////////////////////////////////		
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


	 aes_build	aes_build (
	 
				.eph1				(eph1),
				.reset      (reset),

				.func      (funccalls[counter[6:4]]),
				.text_in   (texts), 
				.true_key 	(true_key),
				.call_complete (call_complete_out),
				
        .ciphertext (ciphertext_out),
				.plaintext 	(plaintext_out)
		 );
		
		endmodule: tb_top
 
 

 
 

		
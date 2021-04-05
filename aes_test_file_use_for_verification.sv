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
		The fake inputs correspond to the user's inputs.  There are only three sets.
		i.		The key_size, which is a two bit user input.  00 for a 128' key, 01 for a 192' key, and 11|10 for a 256' key. 
		ii. 	The plain_text, which is the data to be encrypted. 128' binary no restrictions.
		iii. 	key_words, which are the expanded keys used in rounds.  They are based on the true key, which is not directly used.
		iv.		ready, which is a 1' flag from the keyexpansion module.  @ posedge ready AES will consider that set of plaintext and expanded keys to be valid. The
					fake implementation of the ready flag is contrived.  The actual ready flag will flick to HIGH and remain high. 
					
		The module will correctly compute AES outputs of any key length if the fake inputs are used correctly.  
		*/
		
		logic [1:0] key_size;
		assign key_size = 2'b00;
		
		logic [127:0] plain_text, true_key;
		//assign cipher_text = 128'he49549d94f313d7a7d02ff93dbdb88d6;   //Generated via matlab: binaryVectorToHex(ceil(rand(1,128)-.5))
		assign plain_text = temp ? 128'h00112233445566778899aabbccddeeff : 128'h27ECB2E3A5EE3894885B5289307400E3;


		assign true_key = temp ? 128'h000102030405060708090a0b0c0d0e0f : 128'h2b7e151628aed2a6abf7158809cf4f3c;
		
		// The true key is: 256'h0FB7C204C2C12D3997157A6FC8E4BBE432C40D35F2716092, for reference purposes only.
		logic [15:1][127:0] key_words;   
			//from 15:1 instead of 14:0 to conveniently index at round_key's index [key_words].
			/*
			Software key generation commands:
			KeyExpansion( 'key' , 4 ); //4 for 128 bits, 6 for 192 bits, 8 for 256 bits
			dec2hex(ans);
			ans';
			reshape(ans,32,[]);
			ans'
			*/
			//The key words are arrainged such the first key_word (128'h00010...) is index [15].
/* 		assign key_words = '{
				128'hF01F2E724AC0AB35BE3A20FF7A7D7FCA, //1
				128'hD005A3321BBF085C2BC611AE8820839D, //2
				128'h46F370B60C33DB83B209FB7CC87484B6, //3
				128'h3897FC7C2328F42008EEE58E80CE6613, //4
				128'hCFC00D7BC3F3D6F871FA2D84B98EA932, //5
				128'h6E8E2F5F4DA6DB7F45483EF1C58658E2, //6
				128'h8FAA95DD4C5943253DA36EA1842DC793,
				128'h3156E9837CF032FC39B80C0DFC3E54EF,
				128'h358A4A6D79D30948447067E9C05DA07A,
				128'h8B1A0959F7EA3BA5CE5237A8326C6347,   //10
				128'h7571EA4E0CA2E30648D284EF888F2495,
				128'h4F693F73B88304D676D1337E44BD5039,
				128'h2F22F85523801B536B529FBCE3DDBB29,
				128'h5EA8D5D6E62BD10090FAE27ED447B247,
				128'hCF15581DEC95434E87C7DCF2641A67DB}; */

			logic ready, res_latch, pulse_r,temp;
			

	assign ready = (ctr ==4'h7); 
logic [3:0] ctr, ctr_next;
initial ctr = 4'b0;  
assign ctr_next = ctr +1;
rregs #(4)  ctrtop (ctr, ctr_next, eph1);
 rregs #(1) dblcrypt ( temp ,~reset&(aes_decrypt_done | temp), eph1);

			logic [127:0] aes_decrypted;
			logic 		aes_decrypt_done;
				
/////////////////////////////////////////////////////End fake input section///////////////////////////////////////////////////////		
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


	 aes_build	aes_build (
	 
				.eph1				(eph1),
				.reset      (reset),

				.ready      (ready),
				.plain_text (plain_text), 
				.true_key 	(true_key),
				
				.aes_decrypt_done (aes_decrypt_done),
				.aes_decrypted		(aes_decrypted)
		 );
		
		endmodule: tb_top
 
		

		
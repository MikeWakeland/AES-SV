		`include "aes_hdr.sv"
		`include "aeslib.sv"
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
		assign key_size = 2'b10;
		
		logic [127:0] cipher_text;
		assign cipher_text = 128'he49549d94f313d7a7d02ff93dbdb88d6;   //Generated via matlab: binaryVectorToHex(ceil(rand(1,128)-.5))
		//Plaintext reference is: 27ECB2E3A5EE3894885B5289307400E3

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
		assign key_words = '{
				128'hF01F2E724AC0AB35BE3A20FF7A7D7FCA,
				128'hD005A3321BBF085C2BC611AE8820839D,
				128'h46F370B60C33DB83B209FB7CC87484B6,
				128'h3897FC7C2328F42008EEE58E80CE6613,
				128'hCFC00D7BC3F3D6F871FA2D84B98EA932,
				128'h6E8E2F5F4DA6DB7F45483EF1C58658E2,
				128'h8FAA95DD4C5943253DA36EA1842DC793,
				128'h3156E9837CF032FC39B80C0DFC3E54EF,
				128'h358A4A6D79D30948447067E9C05DA07A,
				128'h8B1A0959F7EA3BA5CE5237A8326C6347,   
				128'h7571EA4E0CA2E30648D284EF888F2495,
				128'h4F693F73B88304D676D1337E44BD5039,
				128'h2F22F85523801B536B529FBCE3DDBB29,
				128'h5EA8D5D6E62BD10090FAE27ED447B247,
				128'hCF15581DEC95434E87C7DCF2641A67DB};

			logic ready;

			assign ready = ~reset; //Ready will eventually have to be changed to be the out_ flag from the aes encrytpion round, but for now this is fine.  
/////////////////////////////////////////////////////End fake input section///////////////////////////////////////////////////////		
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

			aesdecrypt aesdec (  										//This module instantiates all of AES, which takes only fake inputs and spits out only real results.   
				.eph1         					(eph1),
				.reset        					(reset),
				.start 									(start),

				.ready_i 								(ready),
				.cipher_i								(cipher_text),
				.key_size_i							(key_size),  
				.key_words_i   					(key_words),

				.fin_flag_d							(fin_flag_r),
				.plain_out  						(aes_out_r)   
		); 


endmodule: tb_top

		 module aesdecrypt (
		 
				input logic										eph1,
				input logic										reset,
				input logic										start,
			
				input logic										ready_i, //ready to start decryption.
				input logic  [127:0]					cipher_i, //The cypher text to be decrypted.
				input logic  [1:0]						key_size_i, //The user defined key size, comes from keyexpansion.sv 
				input logic  [15:1][127:0] 		key_words_i, //The pre expanded keys which come from keyexpansion.sv.
				
				output logic									fin_flag_d, //	output logic									fin_flag_r,
				output logic [127:0] 					plain_out		//	output logic [127:0] 					aes_out_r
		 
		 );

 		logic 				keyflag_128, keyflag_192, keyflag_256, start_flag; 
		logic [127:0] round_recycle, round_in, round_out;
		logic [127:0] round_key;

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

			//Register inputs for timing purposes.  start, reset, and eph1 not registered.  
		 logic										ready, rdy_reg;
		 logic  [127:0]						cipher;
		 logic  [1:0]							key_size; 
		 logic  [15:1][127:0] 		key_words;
			
		//Register inputs for timing. 	
		rregs #(1) 		rdyid 	(ready, ready_i, eph1);
		rregs #(1) 		rdyregd (rdy_reg, reset ? '0 : ready, eph1); //rdy_reg exists to ensure that start_flag is only up for one c/c, which is the clock immediately after 
																															 //AES receives the positive edge of the ready flag input.  
		rregs #(128)	ptid 	(plain_text, plain_text_i, eph1);		
		rregs #(2)		ksid 	(key_size, key_size_i, eph1);					
		rregs #(1920) kwid 	(key_words, key_words_i, eph1);

		//Works with ready and rdy_reg to provide the start signal to AES
		rregs #(1) kdkedd (start_flag , reset ? '0 : ready^rdy_reg, eph1); 
		
		rregs #(128)  rnrecd ( round_recycle , round_out , eph1);
		assign round_in = start_flag ? cipher_i^key_words[ctr_initial] : round_recycle ;//selects the plaintext XOR key or previous round's output as the input to the next round.  																																																																			
		assign plain_out = fin_flag_d ? round_recycle : '0; 									 					//Captures the registered value of round out as the final output, avoiding another register.    		
		rregs #(1) 		finfld  (fin_flag_d, reset ? '0 : fin_flag, eph1);				 				//delays fin_flag by one c/c to match timing with the proper aes output.  				
		
  
		//Decides what size the key is based on the user's input. Have to initialize at zero due to registered user input.   
		assign keyflag_256 =	reset ? '0 : key_size[1];								 	 //1X
		assign keyflag_192 =  reset ? '0 : ~key_size[1] & key_size[0];	 //01
		assign keyflag_128 =  reset ? '0 : ~|key_size;									 //00
						
		logic [3:0] cycle_ctr_pr, ctr_initial, cycle_ctr;

		//Sets up the original value for the round counter
		rmuxdx3 #(4) ctrind ( ctr_initial,
					keyflag_256, ( 4'h1 ), //e
					keyflag_192, ( 4'h3 ),  //c
					keyflag_128, ( 4'h5 ) //a	
		 );
		//Raises the fin flag when the counter reaches 15.
		//The initial value determines how many clocks it takes to raise the flag.  
		assign fin_flag = ( cycle_ctr == 4'hf ); 

				
 		assign  cycle_ctr = (reset | start_flag ? ctr_initial : (cycle_ctr_pr ))+1'b1;  
		rregs #(4) cycrd (cycle_ctr_pr, cycle_ctr, eph1);			
				 
		assign round_key = key_words[cycle_ctr];		
			
		///ShiftRows 
		//Indicies are in column-major format.
		// example, key = {b15, b14, b13,..., b2, b1, b0}.  b0 = key[127:120] = key[15][7:0]
		/*
		input matrix (invsbox_out):		  output matrix, using input indicies:
		col		i    ii	  iii  iv 					i 		ii	 iii	iv
				| b15  b11  b7   b3   |  		| b15   b11  b7   b3  |  
				| b14  b10  b6   b2   |			| b2    b14  b10  b6  | 
				| b13  b9   b5   b1   |	=>	| b5    b1   b13  b9  | 
				| b12  b8   b4   b0   |			| b8    b4   b0   b12 |
		*/		
	
		logic [15:0][7:0]    shiftrows_out, shiftrows_in;
		assign shiftrows_in = round_in;
			//i																			//ii																			//iii																			//iv
		assign shiftrows_out[15] = shiftrows_in[15];	assign shiftrows_out[11] = shiftrows_in[11];	assign shiftrows_out[7] = shiftrows_in[7] ; 	assign shiftrows_out[3] = shiftrows_in[3] ;
		assign shiftrows_out[14] = shiftrows_in[2] ;	assign shiftrows_out[10] = shiftrows_in[14];	assign shiftrows_out[6] = shiftrows_in[10];		assign shiftrows_out[2] = shiftrows_in[6] ;
		assign shiftrows_out[13] = shiftrows_in[5] ;	assign shiftrows_out[9]  = shiftrows_in[1] ;	assign shiftrows_out[5] = shiftrows_in[13];		assign shiftrows_out[1] = shiftrows_in[9] ;
		assign shiftrows_out[12] = shiftrows_in[8] ;	assign shiftrows_out[8]  = shiftrows_in[4] ;	assign shiftrows_out[4] = shiftrows_in[0] ;		assign shiftrows_out[0] = shiftrows_in[12];


		///InvSBOX 
		// This section performs the inverse Rijndael SBOX lookup using the table in the technical specification.
		// The byte entries used in the table lookup are reversed due to the way that SystemVerilog indexes variables,
		// but the actual bits within each byte are still the same.  

		logic [15:0][7:0] 	invsbox_out;
		
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
		
		
		//AddRoundKey
		//The most simple step merely XORs the Roundkey with the INVSBOX's output.
  	logic [15:0][7:0] 	 addkey_out;
		assign addkey_out = invsbox_out^round_key; //This accomplishes the AddRoundKey step.		
		
		
		///InvMixColumns
		// This section performs the inverse mix columns function, which is operationally equivalent to the 
		// "forward" MixColumns in the encryption step.  However, the multiplication matrix is inverted 
		//  per the technical standard.  This is the mathematical operation:
				
		/* 	Graphical representation of the Invmixcolumn operation.
		| e b d 9 |       | b15 b11 b7 b3 |				| c15 c11 c7 c3 |
		| 9 e b d |       | b14 b10 b6 b2 |				| c14 c10 c6 c2 |
		| d 9 e b |   *   | b13 b9  b5 b1 |   = 	| c13 c9  c5 c1 |
		| b d 9 e |       | b12 b8  b4 b0 |				| c12 c8  c4 c0 |	
		 */
		 
		
		 //Multiplicative functions.
		 //All multiplicative functions in InvMixColumns (9,b,d,e) are described within 8-bit Galois Field per the standard.
		 //The operational multiplication for all functions has been reduced through boolean logic in the "return" of each 
		 //section and has been verified to be bitwise equivalent to the described operation in the standard.  
		 //The two base multiplications are x2 and x3, which are described as:
				 //
		/* Symbolically...
		x9=(((x×2)×2)×2)+x
		x×b=((((x×2)×2)+x)×2)+x
		x×d=((((x×2)+x)×2)×2)+x
		x×e=((((x×2)+x)×2)+x)×2 
		
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
	 		
  	logic [15:0][7:0] 	  mixcol_out;
		
		assign addkey_out = invsbox_out^round_key; //This accomplishes the AddRoundKey step.
		assign mixcol_out[15]  =	xe(addkey_out[15])  ^ xb(addkey_out[14])  	^ xd(addkey_out[13])  ^ x9(addkey_out[12]);
		assign mixcol_out[14]  =	x9(addkey_out[15])  ^ xe(addkey_out[14])  	^ xb(addkey_out[13])  ^ xd(addkey_out[12]);
		assign mixcol_out[13]  =	xd(addkey_out[15])  ^ x9(addkey_out[14])  	^ xe(addkey_out[13])  ^ xb(addkey_out[12]);
		assign mixcol_out[12]  =	xb(addkey_out[15])  ^ xd(addkey_out[14])  	^ x9(addkey_out[13])  ^ xe(addkey_out[12]);

		assign mixcol_out[11]  =  xe(addkey_out[11])  ^ xb(addkey_out[10])  	^ xd(addkey_out[9])  ^ x9(addkey_out[8]);
		assign mixcol_out[10]  =  x9(addkey_out[11])  ^ xe(addkey_out[10])  	^ xb(addkey_out[9])  ^ xd(addkey_out[8]);
		assign mixcol_out[9]   =  xd(addkey_out[11])  ^ x9(addkey_out[10])  	^ xe(addkey_out[9])  ^ xb(addkey_out[8]);
		assign mixcol_out[8]   =  xb(addkey_out[11])  ^ xd(addkey_out[10])  	^ x9(addkey_out[9])  ^ xe(addkey_out[8]);

		assign mixcol_out[7]	 =	xe(addkey_out[7])  ^ xb(addkey_out[6])  	^ xd(addkey_out[5])  ^ x9(addkey_out[4]);
		assign mixcol_out[6]   =	x9(addkey_out[7])  ^ xe(addkey_out[6])  	^ xb(addkey_out[5])  ^ xd(addkey_out[4]);
		assign mixcol_out[5] 	 =	xd(addkey_out[7])  ^ x9(addkey_out[6])  	^ xe(addkey_out[5])  ^ xb(addkey_out[4]);
		assign mixcol_out[4] 	 =	xb(addkey_out[7])  ^ xd(addkey_out[6])  	^ x9(addkey_out[5])  ^ xe(addkey_out[4]);

		assign mixcol_out[3]	 =	xe(addkey_out[3])  ^ xb(addkey_out[2])  	^ xd(addkey_out[1])  ^ x9(addkey_out[0]);
		assign mixcol_out[2]	 =	x9(addkey_out[3])  ^ xe(addkey_out[2])  	^ xb(addkey_out[1])  ^ xd(addkey_out[0]);
		assign mixcol_out[1] 	 =	xd(addkey_out[3])  ^ x9(addkey_out[2])  	^ xe(addkey_out[1])  ^ xb(addkey_out[0]);
		assign mixcol_out[0]	 =	xb(addkey_out[3])  ^ xd(addkey_out[2])  	^ x9(addkey_out[1])  ^ xe(addkey_out[0]);

	 //The final round does not perform InvMixColumns, so round_out selects addkey_out for the final round.  
		assign round_out = ( fin_flag ? addkey_out : mixcol_out); 

endmodule: aesdecrypt



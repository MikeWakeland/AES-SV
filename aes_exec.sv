	/*	//tasks to perform,
	
		1.  Replace fin counter with fin flag.
		2.  Support 196 and 256 bit keys. 
		3.  
		
	*/	
		
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
		logic [15:0][7:0] 			aes_out;
	
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////Bit stuffing section - fake inputs///////////////////////////////////////////////////
///At this point every fake input is comes as an output wire from keyexpansion.sv, so keyexpansion's outputs are therefore/////
///already defined.////////////////////////////////////////////////////////////////////////////////////////////////////////////
			
		logic [127:0] plain_text;
		assign plain_text = 128'h00112233445566778899aabbccddeeff;   //Generated via matlab: binaryVectorToHex(ceil(rand(1,128)-.5))

		logic [255:0] true_key;
		assign true_key = 256'h000102030405060708090a0b0c0d0e0f1011121314151617;  //This is a fake input, which is 256 bits long with 256 bits.  


		logic [15:1][127:0] key_words;   //from 15:1 instead of 14:0 to conveniently index at round_key's index [key_words].
			//key_words generated from true key KeyExpansion.m
			/*
			Software key generation commands:
			KeyExpansion( 'key' , 4 ); //4 for 128 bits, 6 for 192 bits, 8 for 256 bits
			dec2hex(ans);
			ans';
			reshape(ans,32,[]);
			ans'
			*/
			//The key words are arrainged such the first key_word (128'h00010...) is index [15].
		assign key_words = '{128'h000102030405060708090A0B0C0D0E0F,
				128'h10111213141516175846F2F95C43F4FE,
				128'h544AFEF55847F0FA4856E2E95C43F4FE,
				128'h40F949B31CBABD4D48F043B810B7B342,
				128'h58E151AB04A2A5557EFFB5416245080C,
				128'h2AB54BB43A02F8F662E3A95D66410C08,
				128'hF501857297448D7EBDF1C6CA87F33E3C,
				128'hE510976183519B6934157C9EA351F1E0,
				128'h1EA0372A995309167C439E77FF12051E,
				128'hDD7E0E887E2FFF68608FC842F9DCC154,
				128'h859F5F237A8D5A3DC0C02952BEEFD63A,   
				128'hDE601E7827BCDF2CA223800FD8AEDA32,
				128'hA4970A331A78DC09C418C271E3A41D5D,
				128'h650E80AD2885DF3E4CBE04CB04811FAB,
				128'h69ECD71EEA91761194E4F963A2F655E4};

			logic ready;
			assign ready = 1'b1;  //the ready flag will come from keyexpansion.sv when the last round_key has generated, telling AES that it can begin.
			
/////////////////////////////////////////////////////End fake input section///////////////////////////////////////////////////////		
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

			aes aesist (  										//This module instantiates all of AES, which takes only fake inputs and spits out only real results.   
				.eph1         				(eph1),
				.reset        				(reset),
				.start 								(start),

				.ready 								(ready),
				.plain_text						(plain_text),
				.true_key        			(true_key),    
				.key_words   					(key_words),

				.fin_flag							(fin_flag),
				.aes_out  						(aes_out)   
		); 


endmodule: tb_top
 
 
		 module aes (
		 
				input logic										eph1,
				input logic										reset,
				input logic										start,

				input logic										ready,
				input logic  [127:0]					plain_text,
				input logic	 [255:0]					true_key,
				input logic  [15:1][127:0] 		key_words,
				
				output logic									fin_flag,
				output logic [127:0] 					aes_out
		 
		 );
		 
 		/////////////////////////////////////////////////////////AES Admiinistration//////////////////////////////////////////////////////////////////////////////////
		//This section handles all of the round counters, key inputs, and flags required to control AES' inputs and outputs.  Acual executiion begins at AES Round////
 
 		logic keyflag_128, keyflag_192, keyflag_256, start_flag; 
		logic [127:0] round_recycle, round_in, aes_out;
		logic [127:0] round_key;
		logic [3:0] round_index, round_index_next;
				
		//This is the hard coded  Rijndael S-Box for use in AES.  Indicies are row major.   	
		//AES indexes the S-Box in the opposite manner, so the S-BOX is reversed so it can be referenced more 
		//efficiently using hardware. This SBOX behaves correctly according to the AES standard, with an index input of 8'b0 
		//correctly being looked up as 8'h16. Since SBOX is used in both AESround and in keyexpansion, it should be in tb_top
		//and passed as inputs to aesround and keyepansion.
		const logic [255:0][7:0] SBOX = '{
	  // 	xf		xe		 xd			xc		 xb			xa		 x9			x8		 x7			x6		 x5			x4     x3     x2     x1     x0	 		
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
	


		rregs #(1) kdked (start_flag , start, eph1); // start to be replaced by "ready" after the completion of keyexpansion. "ready" will be zero except for the first c/c 
																								 // after completing key expansion, which will be one.  
		
		rregs #(128)  finfl ( round_recycle , aes_out , eph1);
		
		assign round_in = start_flag ? plain_text^key_words[15] : round_recycle ; //selects the plaintext XOR key or previous round's output as the input to the next round.  																																																																			
																																																																														
		//////////////////////////////////////////////////////////////////////////////////////	///////////////////////////////////////////////////////////////////////////
		//This section times the fin_flag, the purpose of which is to tell the machine that it has reached the final round of AES.  The fin flag should rise
		//after either 10, 12, or 14 rounds depending on the key length.  
		//Decides what size the key is based on the inputs to the full sized (256 bit) input.  
		//The key is assumed to be of lower length if the Most of next Most significant 64 bits are all zeroes.
		assign keyflag_256 =	 |true_key[255:192];  
		assign keyflag_192 =  ~|true_key[255:192] & (|true_key[191:128]);
		assign keyflag_128 =  ~(keyflag_256 | keyflag_192);
				
		rmuxd4 #(1) finr 	 ( fin_flag,          //Raises the fin_flag when downcounter cycle_ctr reaches the appropriate value based on the key size.  
					keyflag_256, ( cycle_ctr == 4'b1 ),
					keyflag_192, ( cycle_ctr == 4'h3 ),
					keyflag_128, ( cycle_ctr == 4'h5 ), 
					1'b0	
		);
		
		 //Downcounter starts at 14d, counts down every clock.  The value is used to index key_words[] to pull the key from keyexpansion.sv
		 logic [3:0] cycle_ctr_pr, div_clks, cycle_ctr;
		 assign div_clks = 4'he;
		 assign  cycle_ctr = start_flag ? div_clks : (cycle_ctr_pr!='0 ? cycle_ctr_pr - 1'b1 : 3'hf);
		 rregs #(4) cycr (cycle_ctr_pr, cycle_ctr, eph1);	
				
		assign round_key = key_words[cycle_ctr];		
		
		/////////////////////////////////////////////////////////AES Round///////////////////////////////////////////////////////////////////////////////////////
		//////////////This section defines every successive "round" of AES, where the "inputs" are the round key and previous round's text (or plaintext).///////
	
		logic [15:0][7:0] 	sbox_in, sbox_out;	
		assign sbox_in = round_in; //need to restructure into a [15:0][7:0] bit packed array rather than [127:0].

		//This section performs the actual SBOX table lookup, which matches the contents of the input to the 8 bit address of the SBOX.
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

		///ShiftRows
		//Indicies are in column-major format.
		// example, key = {b15, b14, b13,..., b2, b1, b0}.  b0 = key[127:120] = key[15][7:0]
		/*
		input matrix (sbox_out):		  output matrix, using input indicies:
		col		i    ii	  iii  iv 					i 		ii	 iii	iv
				| b15  b11  b7   b3   |  		| b15   b11  b7   b3  |  
				| b14  b10  b6   b2   |			| b10   b6   b2   b14 |
				| b13  b9   b5   b1   |	=>	| b5    b1   b13  b9  |
				| b12  b8   b4   b0   |			| b0    b12  b8   b4  |
		*/		
	
		logic [15:0][7:0]    shiftrows_out; 	 
			//i																			//ii																			//iii																			//iv
		assign shiftrows_out[15] = sbox_out[15];	assign shiftrows_out[11] = sbox_out[11];	assign shiftrows_out[7] = sbox_out[7] ; 	assign shiftrows_out[3] = sbox_out[3] ;
		assign shiftrows_out[14] = sbox_out[10];	assign shiftrows_out[10] = sbox_out[6] ;	assign shiftrows_out[6] = sbox_out[2] ;		assign shiftrows_out[2] = sbox_out[14];
		assign shiftrows_out[13] = sbox_out[5] ;	assign shiftrows_out[9]  = sbox_out[1] ;	assign shiftrows_out[5] = sbox_out[13];		assign shiftrows_out[1] = sbox_out[9] ;
		assign shiftrows_out[12] = sbox_out[0] ;	assign shiftrows_out[8]  = sbox_out[12];	assign shiftrows_out[4] = sbox_out[8] ;		assign shiftrows_out[0] = sbox_out[4] ;

		//  MixColumns
		//	Performs matrix multiplication of the left arithmetic matrix with the right ShiftRows output
		//	The multiplication function is done by a left shift and additions performed by bitwise XOR.  

		logic [15:0][7:0] 	 mixcol_in, mixcol_out; 
		
		assign mixcol_in = shiftrows_out;

		 //This function defines the false 2x multiplication function, 
		//which is a left shift by one bit and an XOR with 0x1B if the carry out flag is up. 
		function automatic logic [7:0] x2
			 (input logic [7:0]  x);
				return (x[7] ? (x<<1)^(8'h1b) : x<<1); 
		endfunction;

		//This function defines the false 3x multiplication function.
		//It is the same as the 2x function but includes an XOR with the original value 
		function automatic logic [7:0] x3
			(input logic [7:0]  x);
			 return (x[7] ? x<<1^8'h1b : {x<<1})^x;
		endfunction;

		/* 	Graphical representation of the Mixcolumn operation.
		| 2 3 1 1 |       | b15 b11 b7 b3 |				| c15 c11 c7 c3 |
		| 1 2 3 1 |       | b14 b10 b6 b2 |				| c14 c10 c6 c2 |
		| 1 1 2 3 |   *   | b13 b9  b5 b1 |   = 	| c13 c9  c5 c1 |
		| 3 1 1 2 |       | b12 b8  b4 b0 |				| c12 c8  c4 c0 |	
		 */

		assign mixcol_out[15]  = x2(mixcol_in[15])  ^ x3(mixcol_in[14])  	^    mixcol_in[13]   ^ 	  mixcol_in[12] ;
		assign mixcol_out[14]  =    mixcol_in[15]   ^ x2(mixcol_in[14])  	^ x3(mixcol_in[13])  ^    mixcol_in[12] ;
		assign mixcol_out[13]  =    mixcol_in[15]   ^    mixcol_in[14]   	^ x2(mixcol_in[13])  ^ x3(mixcol_in[12]);
		assign mixcol_out[12]  = x3(mixcol_in[15])  ^    mixcol_in[14]   	^    mixcol_in[13]   ^ x2(mixcol_in[12]);

		assign mixcol_out[11]  = x2(mixcol_in[11])  ^ x3(mixcol_in[10])  	^    mixcol_in[9]	 	 ^    mixcol_in[8]  ;
		assign mixcol_out[10]  =    mixcol_in[11]   ^ x2(mixcol_in[10])  	^ x3(mixcol_in[9]) 	 ^    mixcol_in[8]  ; 
		assign mixcol_out[9]   =     mixcol_in[11]  ^    mixcol_in[10]   	^ x2(mixcol_in[9]) 	 ^ x3(mixcol_in[8]) ; 
		assign mixcol_out[8]   = x3(mixcol_in[11])  ^    mixcol_in[10]   	^    mixcol_in[9]  	 ^ x2(mixcol_in[8]) ;

		assign mixcol_out[7]  = x2(mixcol_in[7])  	^ x3(mixcol_in[6])  	^    mixcol_in[5] 	 ^    mixcol_in[4]  ;
		assign mixcol_out[6]  =    mixcol_in[7]   	^ x2(mixcol_in[6])  	^ x3(mixcol_in[5])	 ^    mixcol_in[4]  ; 
		assign mixcol_out[5] 	=    mixcol_in[7]   	^    mixcol_in[6]   	^ x2(mixcol_in[5]) 	 ^ x3(mixcol_in[4]) ; 
		assign mixcol_out[4] 	= x3(mixcol_in[7])  	^    mixcol_in[6]   	^    mixcol_in[5]  	 ^ x2(mixcol_in[4]) ; 

		assign mixcol_out[3] 	= x2(mixcol_in[3]) 		^ x3(mixcol_in[2]) 		^     mixcol_in[1]   ^		mixcol_in[0]  ;
		assign mixcol_out[2]	=    mixcol_in[3]  		^ x2(mixcol_in[2]) 		^ x3(mixcol_in[1]) 	 ^    mixcol_in[0]  ;
		assign mixcol_out[1] 	=    mixcol_in[3]  		^    mixcol_in[2] 		^ x2(mixcol_in[1]) 	 ^ x3(mixcol_in[0]) ; 
		assign mixcol_out[0]	= x3(mixcol_in[3]) 		^    mixcol_in[2]  		^    mixcol_in[1]    ^ x2(mixcol_in[0]) ;
	
			//bitwise XORs the key with the column output, completing the AddRoundKey step.
			//direct vector XOR is feasible because both the MixColumns output and roundkey input are orientated in the same way.
			//The mux selects shiftrows or mixcol as an input.  The impact is to skip MixColumns if this is the last AES round. 
			//This is also the final ciphertext output, but is only valid for the c/c that fin_flag is up.  
		assign aes_out = ( fin_flag ? shiftrows_out : mixcol_out)^round_key; 
 
 
 endmodule: aes
 
 
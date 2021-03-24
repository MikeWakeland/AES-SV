/**********************************
CONTENTS
AES
AES decryption

************************************/


	 module aesencrypt (
		 //ready must ALWAYS be asserted (0 or 1) to aes or the module will not work.  
		 //The module will read the plain_text input at the same posedge that ready becomes high.  	
		 //As written, ready takes a flatline high input, not a pulse.  
				input logic										eph1,
				input logic										reset,

				input logic										ready,
				input logic  [127:0]					plain_text,
				input logic  [1:0]						key_size, 
				input logic  [15:1][127:0] 		key_words,
				
				output logic									fin_flag_r,
				output logic [127:0] 					aes_out_r
		 
		 );
		 

		 
 		/////////////////////////////////////////////////////////AES Admiinistration//////////////////////////////////////////////////////////////////////////////////
		//This section handles all of the round counters, key inputs, and flags required to control AES' inputs and outputs.  Acual executiion begins at AES Round////
 
 		logic 				keyflag_128, keyflag_192, keyflag_256, start_flag; 
		logic [127:0] round_recycle, round_in, round_out;
		logic [127:0] round_key;
		
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
	
	
				//Register inputs for timing purposes.  start, reset, and eph1 not registered.  
		 logic										ready_r, rdy_reg, out_rdy;
		 logic  [127:0]						plain_text_r;
		 logic [3:0] cycle_ctr_pr, div_clks, cycle_ctr;
		 
		// logic  [15:1][127:0] 		key_words;
			
		//Register inputs for timing. 	
		rregs #(1) 		rdyi 	(ready_r, ~reset & ready, eph1);  //registers the input signal.
		rregs #(1) 		rdyreg (rdy_reg, ~reset & ready_r, eph1); //rdy_reg exists to ensure that start_flag is only up for one c/c, which is the clock immediately after 
																															//AES receives the positive edge of the ready_r flag input.  
		rregs #(128)	pti 	(plain_text_r, plain_text, eph1);		
	

		assign start_flag = ~reset & ready_r & ~rdy_reg;

		rregs #(128)  rnrec ( round_recycle , round_out , eph1);
		assign round_in = start_flag ? plain_text_r^key_words[15] : round_recycle ; //selects the plaintext XOR key or previous round's output as the input to the next round.  																																																																			
		assign aes_out_r = out_rdy & round_recycle; 									 		//Captures the registered value of round out as the final output, avoiding another register.    		
		rregs #(1) 		outr  (out_rdy, ~reset & fin_flag & ~fin_flag_r, eph1); //Ensures outr is only up for one cc
		rregs #(1) 		finfl  (fin_flag_r, ~reset & (fin_flag | fin_flag_r) , eph1); //delays fin_flag by one c/c to match timing with the proper aes output.  
																																								//Also latches "up" fin_flag_r so it becomes permanently up when AES is done
		
		
		
		//////////////////////////////////////////////////////////////////////////////////////	///////////////////////////////////////////////////////////////////////////
		//This section times the fin_flag, the purpose of which is to tell the machine that it has reached the final round of AES.  The fin flag should rise
		//after either 10, 12, or 14 rounds depending on the key length.  
		//Decides what size the key is based on the user's input. Have to initialize at zero due to registered user input.   
		assign keyflag_256 =	reset ? '0 : key_size[1];								 	 //1X
		assign keyflag_192 =  reset ? '0 : ~key_size[1] & key_size[0];	 //01
		assign keyflag_128 =  reset ? '0 : ~|key_size;									 //00
				
		rmuxd4 #(1) finr 	 ( fin_flag,          //Raises the fin_flag when downcounter cycle_ctr reaches the appropriate value based on the key size.  
					keyflag_256, ( cycle_ctr == 4'b1 ),
					keyflag_192, ( cycle_ctr == 4'h3 ),
					keyflag_128, ( cycle_ctr == 4'h5 ), 
					1'b0	
		);
		
		 //Downcounter starts at 14d, counts down every clock.  The value is used to index key_words[] to pull the key from keyexpansion.sv
		 assign div_clks = 4'he;
		 assign  cycle_ctr = reset | start_flag ? div_clks : (cycle_ctr_pr!='0 ? cycle_ctr_pr - 1'b1 : 3'hf); 
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
		assign round_out = ( fin_flag ? shiftrows_out : mixcol_out)^round_key; 
	
		
 
 endmodule: aesencrypt



		 module aesdecrypt (
		 
		 //ready must ALWAYS be asserted (0 or 1) to aes or the module will not work.  
		 //The module will read the cipher input at the same posedge that ready becomes high.  	
		 //As written, ready takes a flatline high input, not a pulse.  		 
				input logic										eph1,
				input logic										reset,
			
				input logic										ready, //ready_r to start decryption.
				input logic  [127:0]					cipher, //The cypher text to be decrypted.
				input logic  [1:0]						key_size, //The user defined key size, comes from keyexpansion.sv 
				input logic  [15:1][127:0] 		key_words, //The pre expanded keys which come from keyexpansion.sv.
				
				output logic									fin_flag_r, //	output logic									fin_flag_r,
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
		 logic										ready_r, rdy_reg;
		 logic  [127:0]						cipher_r, fin_flag_wide;
		 logic  [3:0]							cycle_ctr_pr, ctr_initial, cycle_ctr;

		//Register inputs for timing. 	
		rregs #(1) 		rdyid 	(ready_r, ~reset&ready, eph1);
		rregs #(1) 		rdyregd (rdy_reg, ~reset&ready_r, eph1); //rdy_reg exists to ensure that start_flag is only up for one c/c, which is the clock immediately after 
																															 //AES receives the positive edge of the ready_r flag input.  

		
		rregs #(128)	ptid 	(cipher_r, cipher, eph1);						

		//Works with ready_r and rdy_reg to provide the start signal to AES
		assign start_flag = ~reset & ready_r & ~rdy_reg; 
		
		rregs #(128)  rnrecd ( round_recycle , round_out , eph1);
		assign round_in = start_flag ? cipher_r^key_words[ctr_initial] : round_recycle ;//selects the plaintext XOR key or previous round's output as the input to the next round.  	
		assign fin_flag_wide = {128{fin_flag_r}};    																//Extends fin_flag_r to use AND gates to avoid using a 32' mux. 
		assign plain_out = fin_flag_wide&round_recycle; 									 					//Captures the registered value of round out as the final output, avoiding another register.    		
		rregs #(1) 		finfld  (fin_flag_r, ~reset&(cycle_ctr == 4'hf), eph1);				 				//delays fin_flag by one c/c to match timing with the proper aes output.  				
		
		
		/* logic in, pulse, in_r;

rregs xxx (in_r, ~reset & in, eph1);
assign pulse = in & ~in_r;
 */
/* logic pulse;
assign pulse = ready_r & ~rdy_reg;
 */
		
  
		//Decides what size the key is based on the user's input. Have to initialize at zero due to registered user input.   
		assign keyflag_256 =	 key_size[1];								 	 //1X
		assign keyflag_192 =  ~key_size[1] & key_size[0];	 //01
		assign keyflag_128 =  ~|key_size;									   //00
						


		//Sets up the original value for the round counter
		rmuxdx3 #(4) ctrind ( ctr_initial,
					keyflag_256, ( 4'h1 ), //e
					keyflag_192, ( 4'h3 ), //c
					keyflag_128, ( 4'h5 )  //a	
		 );
				
/*  		assign  cycle_ctr = ( start_flag ? ctr_initial : (cycle_ctr_pr ))+1'b1;  
		rregs #(4) cycrd (cycle_ctr_pr, cycle_ctr, eph1);			 */
		
		
 logic start_f_r;
  rregs #(1) flgr ( start_f_r , ~reset &(start_f_r |start_flag), eph1); 
	assign  cycle_ctr = ( (start_flag | start_f_r) ? (cycle_ctr_pr ) : ctr_initial)+1'b1;  
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
		assign round_out = ( (cycle_ctr == 4'hf) ? addkey_out : mixcol_out); 

endmodule: aesdecrypt




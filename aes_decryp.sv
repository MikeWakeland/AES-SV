
//This file is trash and should not be viewed by anyone.  
/*
Pseudocode per the AES technical standard.

InvCipher(byte in[4*Nb], byte out[4*Nb], word w[Nb*(Nr+1)])
begin
byte state[4,Nb]
state = in
AddRoundKey(state, w[Nr*Nb, (Nr+1)*Nb-1]) // See Sec. 5.1.4

for round = Nr-1 step -1 downto 1
InvShiftRows(state) // See Sec. 5.3.1
InvSubBytes(state) // See Sec. 5.3.2
AddRoundKey(state, w[round*Nb, (round+1)*Nb-1])
InvMixColumns(state) // See Sec. 5.3.3
end for

InvShiftRows(state)
InvSubBytes(state)
AddRoundKey(state, w[0, Nb-1])
out

*/

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
		assign round_in = start_flag ? plain_text^key_words[15] : round_recycle ; //selects the plaintext XOR key or previous round's output as the input to the next round.  																																																																			
		assign plain_out = fin_flag_d ? round_recycle : '0; 									 		//Captures the registered value of round out as the final output, avoiding another register.    		
		rregs #(1) 		finfld  (fin_flag_d, reset ? '0 : fin_flag, eph1);				 		//delays fin_flag by one c/c to match timing with the proper aes output.  				
		

		
		//////////////////////////////////////////////////////////////////////////////////////	///////////////////////////////////////////////////////////////////////////
		//This section times the fin_flag, the purpose of which is to tell the machine that it has reached the final round of AES.  The fin flag should rise
		//after either 10, 12, or 14 rounds depending on the key length.  
		//Decides what size the key is based on the user's input. Have to initialize at zero due to registered user input.   
		assign keyflag_256 =	reset ? '0 : key_size[1];								 	 //1X
		assign keyflag_192 =  reset ? '0 : ~key_size[1] & key_size[0];	 //01
		assign keyflag_128 =  reset ? '0 : ~|key_size;									 //00
				
		rmuxd4 #(1) finrd 	 ( fin_flag,          //Raises the fin_flag when downcounter cycle_ctr reaches the appropriate value based on the key size.  
					keyflag_256, ( cycle_ctr == 4'b1 ),
					keyflag_192, ( cycle_ctr == 4'h3 ),
					keyflag_128, ( cycle_ctr == 4'h5 ), 
					1'b0	
		);
		
		 //Downcounter starts at 14d, counts down every clock.  The value is used to index key_words[] to pull the key from keyexpansion.sv
		 logic [3:0] cycle_ctr_pr, div_clks, cycle_ctr;
		 assign div_clks = 4'he;
		 assign  cycle_ctr = reset | start_flag ? div_clks : (cycle_ctr_pr!='0 ? cycle_ctr_pr - 1'b1 : 3'hf); 
		 rregs #(4) cycrd (cycle_ctr_pr, cycle_ctr, eph1);	
				
		assign round_key = key_words[cycle_ctr];		
		
		////////////////////////////////////End admin///
	
		
		
				///ShiftRows (completed)
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
	
		logic [15:0][7:0]    shiftrows_out; 	 
			//i																			//ii																			//iii																			//iv
		assign shiftrows_out[15] = round_in[15];	assign shiftrows_out[11] = round_in[11];	assign shiftrows_out[7] = round_in[7] ; 	assign shiftrows_out[3] = round_in[3] ;
		assign shiftrows_out[14] = round_in[2] ;	assign shiftrows_out[10] = round_in[14];	assign shiftrows_out[6] = round_in[10];		assign shiftrows_out[2] = round_in[6] ;
		assign shiftrows_out[13] = round_in[5] ;	assign shiftrows_out[9]  = round_in[1] ;	assign shiftrows_out[5] = round_in[13];		assign shiftrows_out[1] = round_in[9] ;
		assign shiftrows_out[12] = round_in[8] ;	assign shiftrows_out[8]  = round_in[4] ;	assign shiftrows_out[4] = round_in[0] ;		assign shiftrows_out[0] = round_in[12];



		logic [15:0][7:0] 	invsbox_in, invsbox_out;	
		assign invsbox_in = shiftrows_out; //need to restructure into a [15:0][7:0] bit packed array rather than [127:0].

		//This section performs the actual INVSBOX table lookup, which matches the contents of the input to the 8 bit address of the INVSBOX.
		assign invsbox_out[15] = INVSBOX[invsbox_in[15]];
		assign invsbox_out[14] = INVSBOX[invsbox_in[14]]; 
		assign invsbox_out[13] = INVSBOX[invsbox_in[13]];
		assign invsbox_out[12] = INVSBOX[invsbox_in[12]];
		assign invsbox_out[11] = INVSBOX[invsbox_in[11]]; 
		assign invsbox_out[10] = INVSBOX[invsbox_in[10]];
		assign invsbox_out[9]  = INVSBOX[invsbox_in[9]] ;
		assign invsbox_out[8]  = INVSBOX[invsbox_in[8]] ;
		assign invsbox_out[7]  = INVSBOX[invsbox_in[7]] ;
		assign invsbox_out[6]  = INVSBOX[invsbox_in[6]] ;
		assign invsbox_out[5]  = INVSBOX[invsbox_in[5]] ;
		assign invsbox_out[4]  = INVSBOX[invsbox_in[4]] ;
		assign invsbox_out[3]  = INVSBOX[invsbox_in[3]] ;
		assign invsbox_out[2]  = INVSBOX[invsbox_in[2]] ;
		assign invsbox_out[1]  = INVSBOX[invsbox_in[1]] ;
		assign invsbox_out[0]  = INVSBOX[invsbox_in[0]] ;
		
		

		 //This function defines the false 9x multiplication function, 
		//which is three 2x functions followed by an XOR with the original value.
		function automatic logic [7:0] x9
			 (input logic [7:0]  x);
			 logic [7:0] x2, x4, x8;
			 assign x2=   x[7] ? (x<<1) ^(8'h1b) : x<<1;
			 assign x4 = x2[7] ? (x2<<1)^(8'h1b) : x<<1;
			 assign x8 = x4[7] ? (x4<<1)^(8'h1b) : x<<1;
				return (x8^x); 
		endfunction;

		//This function defines the false 11x multiplication function.
		function automatic logic [7:0] xb
			(input logic [7:0]  x);
			 logic [7:0] x2, x4;
			 assign x2 =   x[7] ? (x<<1) ^(8'h1b) : x<<1;
			 assign x5 = (x2[7] ? (x2<<1)^(8'h1b) : x<<1)^x;
			 return ((x5[7] ? (x5<<1)^(8'h1b) : x<<1)^x);			
			 return (x[7] ? x<<1^8'h1b : x<<1)^x;
		endfunction;

		 //This function defines the false 13x multiplication function, 
		function automatic logic [7:0] xd
			 (input logic [7:0]  x);
			 logic [7:0] x3, x6; 
			 assign x3=  (x[7] ? (x<<1) ^(8'h1b) :  x<<1)^x;
			 assign x6 = x3[7] ? (x3<<1)^(8'h1b) : x3<<1;		 
			 return (x6[7] ? (x6<<1)^(8'h1b) : x6<<1)^x; 
		endfunction;

		//This function defines the false 14x multiplication function.
		//It is the same as the 2x function but includes an XOR with the original value 
		function automatic logic [7:0] xe
			(input logic [7:0]  x);
			logic [7:0] x3, x9 ; 
			assign x3 = ( x[7] ? x <<1^8'h1b : {x<<1} )^x;
			assign x9 = (x3[7] ? x3<<1^8'h1b : {x3<<1})^x;			
			return (x9[7] ? (x9<<1)^(8'h1b) : x<<1);
		endfunction;


		/* 	Graphical representation of the Invmixcolumn operation.
		| e b d 9 |       | b15 b11 b7 b3 |				| c15 c11 c7 c3 |
		| 9 e b d |       | b14 b10 b6 b2 |				| c14 c10 c6 c2 |
		| d 9 e b |   *   | b13 b9  b5 b1 |   = 	| c13 c9  c5 c1 |
		| b d 9 e |       | b12 b8  b4 b0 |				| c12 c8  c4 c0 |	
		 */

		logic [15:0][7:0] 	 mixcol_in, mixcol_out; 
		
		assign mixcol_in = invsbox_out;

		assign mixcol_out[15]  =	xe(mixcol_in[15])  ^ xb(mixcol_in[14])  	^ xd(mixcol_in[13])  ^ x9(mixcol_in[12]);
		assign mixcol_out[14]  =	x9(mixcol_in[15])  ^ xe(mixcol_in[14])  	^ xb(mixcol_in[13])  ^ xd(mixcol_in[12]);
		assign mixcol_out[13]  =	xd(mixcol_in[15])  ^ x9(mixcol_in[14])  	^ xe(mixcol_in[13])  ^ xb(mixcol_in[12]);
		assign mixcol_out[12]  =	xb(mixcol_in[15])  ^ xd(mixcol_in[14])  	^ x9(mixcol_in[13])  ^ xe(mixcol_in[12]);

		assign mixcol_out[11]  =  xe(mixcol_in[11])  ^ xb(mixcol_in[10])  	^ xd(mixcol_in[9])  ^ x9(mixcol_in[8]);
		assign mixcol_out[10]  =  x9(mixcol_in[11])  ^ xe(mixcol_in[10])  	^ xb(mixcol_in[9])  ^ xd(mixcol_in[8]);
		assign mixcol_out[9]   =  xd(mixcol_in[11])  ^ x9(mixcol_in[10])  	^ xe(mixcol_in[9])  ^ xb(mixcol_in[8]);
		assign mixcol_out[8]   =  xb(mixcol_in[11])  ^ xd(mixcol_in[10])  	^ x9(mixcol_in[9])  ^ xe(mixcol_in[8]);

		assign mixcol_out[7]	 =	xe(mixcol_in[7])  ^ xb(mixcol_in[6])  	^ xd(mixcol_in[5])  ^ x9(mixcol_in[4]);
		assign mixcol_out[6]   =	x9(mixcol_in[7])  ^ xe(mixcol_in[6])  	^ xb(mixcol_in[5])  ^ xd(mixcol_in[4]);
		assign mixcol_out[5] 	 =	xd(mixcol_in[7])  ^ x9(mixcol_in[6])  	^ xe(mixcol_in[5])  ^ xb(mixcol_in[4]);
		assign mixcol_out[4] 	 =	xb(mixcol_in[7])  ^ xd(mixcol_in[6])  	^ x9(mixcol_in[5])  ^ xe(mixcol_in[4]);

		assign mixcol_out[3]	 =	xe(mixcol_in[3])  ^ xb(mixcol_in[2])  	^ xd(mixcol_in[1])  ^ x9(mixcol_in[0]);
		assign mixcol_out[2]	 =	x9(mixcol_in[3])  ^ xe(mixcol_in[2])  	^ xb(mixcol_in[1])  ^ xd(mixcol_in[0]);
		assign mixcol_out[1] 	 =	xd(mixcol_in[3])  ^ x9(mixcol_in[2])  	^ xe(mixcol_in[1])  ^ xb(mixcol_in[0]);
		assign mixcol_out[0]	 =	xb(mixcol_in[3])  ^ xd(mixcol_in[2])  	^ x9(mixcol_in[1])  ^ xe(mixcol_in[0]);

	
		assign round_out = ( fin_flag ? shiftrows_out : mixcol_out)^round_key; 


//need to define the last round,
//sub bytes, shift rows, add round key.  In that order. 





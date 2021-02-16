`include "aes_hdr.sv"
		`include "aeslib.sv"
		`define SIM  //tick commands are commands to the tools.  Tells the tools that it should go to these files and grab whats in there.  

		//----------------------------------------------
		`timescale 1ns/1ps
		module tb_top ();
 
		//----------------------------------------------
 
	 localparam MAX_CLKS = 15;

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

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////Bit stuffing section - fake inputs///////////////////////////////////////////////////
////////roundkeys and bitstreams generated from Cipher.m and associated files. Cipher('key','data')/////////////////////////////
//The real module will take that round's already expanded RoundKey as an input to key_words, and the round in will be either////
//the output of the plaintext's XOR with the 0th RoundKey or the output from the previous round.////////////////////////////////

		 const logic [127:0] true_key    = '{ //[NUM_BLOCKS] goes in the unpacked segment.
			 128'hAB7F34AFDD7382220E089AFB3D909866 //FAKE for later replacement.  
			};		

		//This is the hard coded  Rijndael S-Box for use in AES.  Indicies are row major.   	
		//AES indexes the S-Box in the opposite manner, so the S-BOX is reversed so it can be referenced more 
		//efficiently using hardware. This SBOX behaves correctly according to the AES standard, with an index input of 8'b0 
		//correctly being looked up as 8'h16. Since SBOX is used in both AESround and in keyexpansion, it should be in tb_top
		//and passed as inputs to aesround and keyepansion.
		const logic [255:0][7:0] SBOX = '{
	//  	xf		xe		 xd			xc		 xb			xa		 x9			x8		 x7			x6		 x5			x4     x3     x2     x1     x0	 		
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
		
/////////////////////////////////////////////////////End fake input section///////////////////////////////////////////////////////	
		

		keyschedule keysked (
		.eph1											(eph1),
		.reset										(reset),										
		.start										(start),

		.SBOX											(SBOX),	
		.true_key									(true_key),	
		
		.ready										(ready),
		.key_words								(key_words) //Four words per round, Four bytes per word, Eight bits per byte.
		);
	
		endmodule: tb_top

		
		module keyschedule (
		// verification software command: KeyExpansion('(key)', 4) 
		input 	logic											eph1,
		input 	logic											reset,
		input 	logic											start,

		input		logic 	[255:0][7:0]			SBOX,	
		input		logic 	[127:0]						true_key,
		
		output	logic											ready,
		output	logic 	[10:0][3:0][31:0]   		key_words //Four words per round, Four bytes per word, Eight bits per byte.
		);

		logic		[3:0][31:0]				key_gen;
	  logic 	[3:0][3:0][7:0]		last_rounds_words;	
		logic		[15:0][7:0]				key_bytes;
		logic		[3:0][7:0]				g_out, g_in, word_sbox, word_shift;
		logic 	[10:0] 						old_constant, new_constant;
		logic 	[7:0] 						round_prefix;
		logic 	[127:0] 					r0k, r1k, r2k, r3k, r4k, r5k, r6k, r7k, r8k, r9k, r10k, r11k, r12k, r13k, r14k;	
	
		//////////////////////////////G function. 
		//This section describes the G function in AES, which takes the least significant 4x32 bit key word from the previous round as an input.
		//The G function only applies after the initial set of key generation (which is just the true key), for every successive key.  
		//The G function performs a left barrel shift on each byte of the input word, then performs an SBOX lookup for each byte.
		//This SBOX lookup is reconcantentated and forms g_out.  
		//One round worth of keys is generated per clock cycle by rregs cons.
	
		assign g_in	= ~|round_prefix[7:1]?  true_key[31:0] : last_rounds_words[0]  ;//whatever the last word is from the last round.

			
		//This section calculates the round constant, which is a 32'b for every round.  The round constant does not algorithmically apply for the 
		//initial round of key generation but in hardware it is expressed as a value of 32'b0, which does not operationally change the results when
		//XOR'd with the original key.  Every successive round is a left shift of the most significant byte, which rolls over to 8'h1b when it overflows.
		//The remaining 24 bits are added by concatenating 24'b0 to every round key.  
		//Since the round_prefix is read from new_constant, the first left shift has already occured at reset.
		//Since the initial round_prefix value has to be zero, that initial shift still can't cause a shift in to the round constant.
		//There were some timing issues with ensuring this initial value endured beyond the first clock cycle, which includes a posedge.
		//As such several bits needed to be added to the RHS of the constants, resulting in an 11' constant value which is 
		//read at the most significant 8 bits.  In total, an 11 bit vector was required to properly time this 8 bit section of the round constant.	
		
		initial old_constant = 11'h001;
	  assign new_constant = old_constant[10] ? 11'h0d8 : {old_constant <<1};  
		assign round_prefix = new_constant[10:3];
		
		rregs  #(11) cons ( old_constant , new_constant , eph1); 
	
		
		//performs the barrel shift per AES spec.
		assign word_shift = {g_in[2:0] , g_in[3]};
		
		//performs the AES table lookup, subject to the index reversals described on the SBOX definition.
		assign word_sbox[3] = SBOX[word_shift[3]];  
		assign word_sbox[2] = SBOX[word_shift[2]];		
		assign word_sbox[1] = SBOX[word_shift[1]];
		assign word_sbox[0] = SBOX[word_shift[0]];
		
		//The actual round constant per the AES standard is a 32' number, and trailing 24' zeroes are concat'd here.   
		assign g_out = word_sbox ^ {round_prefix, 24'b0};
		//////////////////////////////End G function



		 //The individual round key words are the XOR values of the pervious key word element, and the previous round's element.
		 //for the most significant key word in every round, the output of hte g function takes the place of the pervious key word element.
		 //No g function or XOR is performed on the initial round, which instead only reads the true key input.  
		 
			assign key_gen[3] = ~|round_prefix[7:0] ? true_key[127:96]: g_out 		 ^ last_rounds_words[3];
			assign key_gen[2] = ~|round_prefix[7:0] ? true_key[95:64]	: key_gen[3] ^ last_rounds_words[2];
			assign key_gen[1] = ~|round_prefix[7:0] ? true_key[63:32]	: key_gen[2] ^ last_rounds_words[1];
			assign key_gen[0] = ~|round_prefix[7:0] ? true_key[31:0]	: key_gen[1] ^ last_rounds_words[0]; 
			
			//This section registers each successive round in the key generation to be tied up for storage.  
			//A ready flag is sent to the rest of AES when r0k gains a non zero bit.  
			//A true key of 128'b0 would never trigger this flag and render the module inoperable, but all zeroes are 
			//not an advisable key to use.  
			
			initial r0k = 128'b0;
			assign ready = |r0k; //this tells the key expansion that the flag is up and the keys are ready to be used.  

			
			rregs #(128) key14 ( r14k , key_gen , eph1 );
			assign last_rounds_words = r14k;			
			rregs #(128) key13 ( r13k , r14k , eph1 );			
			rregs #(128) key12 ( r12k , r13k , eph1 );			
			rregs #(128) key11 ( r11k , r12k , eph1 );
			rregs #(128) key10 ( r10k , r11k , eph1 );
			rregs #(128) key9  ( r9k  , r10k , eph1 );
			rregs #(128) key8  ( r8k  , r9k  , eph1 );
			rregs #(128) key7  ( r7k  , r8k  , eph1 );
			rregs #(128) key6  ( r6k  , r7k  , eph1 );
			rregs #(128) key5  ( r5k  , r6k  , eph1 );
			rregs #(128) key4  ( r4k  , r5k  , eph1 );
			rregs #(128) key3  ( r3k  , r4k  , eph1 );
			rregs #(128) key2  ( r2k  , r3k  , eph1 );
			rregs #(128) key1  ( r1k  , r2k  , eph1 );
			rregs #(128) key0  ( r0k  , r1k  , eph1 );
			
			//administrative assignment to the output for easier indexing.
			assign key_words = {r14k, r13k, r12k, r11k, r10k, r9k, r8k, r7k, r6k, r5k, r4k, r3k, r2k, r1k, r0k};
			
			endmodule: keyschedule
			
	

	
	
		
		

`include "muxreglib.sv"
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
		logic ready, reset, reset_r;
		initial begin
				reset  = 1;
				$display("Starting Proc Simulation");
				random_num = $random(1);
	 
				repeat(2) @(posedge eph1);
				#1 reset= '0;
		end
		rregs resetr (reset_r, reset , eph1);
		assign ready = ~reset & (reset_r ^ reset);

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////Bit stuffing section - fake inputs///////////////////////////////////////////////////
////////roundkeys and bitstreams generated from Cipher.m and associated files. Cipher('key','data')/////////////////////////////
//The real module will take that round's already expanded RoundKey as an input to key_words, and the round in will be either////
//the output of the plaintext's XOR with the 0th RoundKey or the output from the previous round.////////////////////////////////

		 const logic [255:0] true_key    = '{ //[NUM_BLOCKS] goes in the unpacked segment.
			//256'h603deb1015ca71be2b73aef0857d77811f352c073b6108d72d9810a30914dff4 //256' key from the aes standard
			//256'h8e73b0f7da0e6452c810f32b809079e562f8ead2522c6b7b //192' key from the aes standard.    
	  	256'h2b7e151628aed2a6abf7158809cf4f3c //128' key from the aes standard
		
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
			
	 const logic [1:0] key_size = 2'b00;
		logic [1919:0] key_words;
		logic sm_done;
/////////////////////////////////////////////////////End fake input section///////////////////////////////////////////////////////	
		

		keyexpansion keysked (
		.eph1											(eph1),
		.reset										(reset),										
		.ready										(ready),

		.SBOX											(SBOX),	
		.true_key									(true_key),	
		.key_size									(key_size),
		
		.key_done									(key_done),
		.key_words								(key_words) //Four words per round, Four bytes per word, Eight bits per byte.
		);
	
		endmodule: tb_top


		module keyexpansion (
		// verification software command: KeyExpansion('(key)', 4) 
		input 	logic											eph1,
		input 	logic											reset,
		input 	logic											ready,

		input		logic 	[255:0][7:0]			SBOX,	
		input		logic 	[255:0]						true_key,
		input 	logic 	[1:0]							key_size,
		
		output	logic											key_done,
		output	logic 	[1919:0] 					key_words //Four words per round, Four bytes per word, Eight bits per byte.
		);
		
		logic 	[255:0] 					r0k, r1k, r2k, r3k, r4k, r5k, r6k, r7k, r8k, r9k, r10k;	
		logic [1:0] keyflag_128, keyflag_192, keyflag_256;
		logic [3:0] cycle_ctr, cycle_ctr_pr;
		logic [255:0] key_gen_r, key_gen, true_key_r, reset_long;
		logic [14:0][127:0] voltmeter;
		
		assign voltmeter = key_words; //better lets me view the output vector on the simulation window - no other function
		

assign reset_long = {256{reset}};
rregs_en #(256,1) keys (true_key_r ,true_key, eph1, ready);


logic  sm_idle,  sm_start, sm_run, sm_finish;
logic  sm_idle_next, sm_start_next, sm_run_next, sm_finish_next;


rregs smir (sm_idle,    reset & sm_idle_next,   eph1);
rregs smsr (sm_start,  ~reset & sm_start_next,  eph1);
rregs smrr (sm_run,    ~reset & sm_run_next,    eph1);
rregs smfr (sm_finish, ~reset & sm_finish_next, eph1);

assign sm_start_next        =  ready;        // allow start to blow away existingrun
assign sm_run_next          = (~sm_start_next) & (sm_start | (sm_run & ~key_done));
assign sm_finish_next       = (~sm_start_next) & sm_run & key_done;
assign sm_idle_next     		= (~sm_start_next  & ~sm_run_next & ~sm_finish_next) & sm_finish;

//Sounds like there's a start signal, then you count until you get to the finish,
//Then you ide.

//key_size for counter.  
		assign keyflag_256 =	 key_size[1];								 		//1X
		assign keyflag_192 =  ~key_size[1] & key_size[0];	 		//01
		assign keyflag_128 =  ~|key_size;									  	//00
						
		rmuxdx3_im #(1) finr 	 ( key_done,          //Raises the fin_flag when downcounter cycle_ctr reaches the appropriate value based on the key size.  
					keyflag_256, ( cycle_ctr == 4'h7 ),
					keyflag_192, ( cycle_ctr == 4'h6 ),
					keyflag_128, ( cycle_ctr == 4'h4 ) 	
		);

		 assign  cycle_ctr = reset | sm_start  ? 4'he : (cycle_ctr_pr!='0 ? cycle_ctr_pr - 1'b1 : 4'hf); //also needs a FSM pulse to go along with this.  
		 rregs #(4) cycr (cycle_ctr_pr, cycle_ctr, eph1);	
				

			//This section registers each successive round in the key generation to be tied up for storage.  
			//A ready flag is sent to the rest of AES when r0k gains a non zero bit.  
			//A true key of 128'b0 would never trigger this flag and render the module inoperable, but all zeroes are 
			//not an advisable key to use.  

		//	assign ready = |r0k; //this tells the key expansion that the flag is up and the keys are ready to be used.  
			assign r0k = key_gen_r;
			rregs #(256) key0	 (key_gen_r , key_gen, eph1);	//key_gen is the output from the key generation module.
			rregs #(256) key1  ( r1k  ,  r0k  , eph1 );	
			rregs #(256) key2  ( r2k  ,  r1k  , eph1 );
			rregs #(256) key3  ( r3k  ,  r2k  , eph1 );
			rregs #(256) key4  ( r4k  ,  r3k  , eph1 );
			rregs #(256) key5  ( r5k  ,  r4k  , eph1 );
			rregs #(256) key6  ( r6k  ,  r5k  , eph1 );
			rregs #(256) key7  ( r7k  ,  r6k  , eph1 );			
			rregs #(256) key8  ( r8k  ,  r7k  , eph1 );			
			rregs #(256) key9  ( r9k  ,  r8k  , eph1 );			
			rregs #(256) key10 ( r10k ,   r9k , eph1 );

			
			//administrative assignment to the output for easier indexing.
	//1792 bits in these objects.  
	logic [1919:0] words_128, words_192, words_256, words_write;
	//128'
	assign words_128 = { 512'h0   , r10k[127:0], r9k[127:0], r8k[127:0], r7k[127:0], r6k[127:0], 
											r5k[127:0],	 r4k[127:0], r3k[127:0], r2k[127:0], r1k[127:0], r0k[127:0]};
	//192'
	assign words_192 = { 256'h0   , r8k[191:0], r7k[191:0], r6k[191:0], r5k[191:0 ],
											r4k[191:0], r3k[191:0], r2k[191:0], r1k[191:0], r0k[191:64]};
	//256'
	assign words_256 = {r7k[255:0], r6k[255:0], r5k[255:0],	r4k[255:0  ],
											r3k[255:0], r2k[255:0], r1k[255:0], r0k[255:128]};
	
		rmuxd3_im #(1920) written (words_write,
		keyflag_128								, words_128,
		~keyflag_128 & keyflag_192, words_192,
																words_256
			);
			
		rregs_en #(1920,1) keywrite ( key_words, words_write, eph1, key_done); //writes the words to output when everything's said and done.									
				


				
				keymaker kymker	(
		.eph1											(eph1),
		.reset										(reset),										
		.ready										(ready),

		.sm_start									(sm_start),
		.sm_run										(sm_run),
		.keyflag_128							(keyflag_128),
		.keyflag_192							(keyflag_192),//Keyflag 192 and 128
		.SBOX											(SBOX),	
		.true_key									(true_key_r),	
		.key_gen_r								(key_gen_r),
		
		.key_gen								  (key_gen) //Four words per round, Four bytes per word, Eight bits per byte.
		);
		
		
			endmodule: keyexpansion
			
			module keymaker (
		// verification software command: KeyExpansion('(key)', 4) 
		input 	logic											eph1,
		input 	logic											reset,
		input 	logic											ready,


		input 	logic											sm_start,
		input 	logic											sm_run,
		input 	logic											keyflag_128,
		input		logic											keyflag_192,
		input		logic 	[255:0][7:0]			SBOX,	
		input		logic 	[255:0]						true_key,
		input 	logic 	[7:0][3:0][7:0]		key_gen_r,  
		
		output	logic 	[7:0][31:0] 			key_gen //Six words per round, Four bytes per word, Eight bits per byte.
		);

		logic		[15:0][7:0]				key_bytes;
		logic		[3:0][7:0]				g_out, g_in, word_sbox, word_shift;
		logic 	[7:0] 						old_constant, new_constant;
		logic 	[7:0] 						round_prefix;
	
		//////////////////////////////G function. 
		//This section describes the G function in AES, which takes the least significant 4x32 bit key word from the previous round as an input.
		//The G function only applies after the initial set of key generation (which is just the true key), for every successive key.  
		//The G function performs a left barrel shift on each byte of the input word, then performs an SBOX lookup for each byte.
		//This SBOX lookup is reconcantentated and forms g_out.  
		//One round worth of keys is generated per clock cycle by rregs cons.
		
		assign g_in	= sm_start ?  true_key[31:0] : key_gen_r[0]  ;//whatever the last word is from the last round.

			
		//This section calculates the round constant, which is a 32'b for every round.  The round constant does not algorithmically apply for the 
		//initial round of key generation but in hardware it is expressed as a value of 32'b0, which does not operationally change the results when
		//XOR'd with the original key.  Every successive round is a left shift of the most significant byte, which rolls over to 8'h1b when it overflows.
		//The remaining 24 bits are added by concatenating 24'b0 to every round key.  
		//Since the round_prefix is read from new_constant, the first left shift has already occured at reset.
		//Since the initial round_prefix value has to be zero, that initial shift still can't cause a shift in to the round constant.
		//There were some timing issues with ensuring this initial value endured beyond the first clock cycle, which includes a posedge.
		//As such several bits needed to be added to the RHS of the constants, resulting in an 11' constant value which is 
		//read at the most significant 8 bits.  In total, an 11 bit vector was required to properly time this 8 bit section of the round constant.	
		
	  assign new_constant = (old_constant == 8'h80) ? 8'h1b : {old_constant <<1};  
		assign round_prefix = old_constant;
		
		rregs  #(8) cons ( old_constant , reset | sm_start ? 8'b1 : new_constant , eph1); 
		
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
		 logic [31:0] key_four;
		 logic [3:0][7:0] key_lkup;
		 
		 assign key_lkup[3]=SBOX[key_gen[4][31:24]];
		 assign key_lkup[2]=SBOX[key_gen[4][23:16]];
		 assign key_lkup[1]=SBOX[key_gen[4][15:8 ]];
		 assign key_lkup[0]=SBOX[key_gen[4][7:0  ]];		 
		
		 
		 rmuxd3_im #(32) keyfor (key_four ,
					keyflag_128, g_out , 
					keyflag_192, key_gen[4], 
					key_lkup 
					);
		 
			assign key_gen[7] = sm_start ? true_key[255:224]	: g_out															^ key_gen_r[7];			
			assign key_gen[6] = sm_start ? true_key[223:192] 	: key_gen[7]							 					^ key_gen_r[6];
			assign key_gen[5] = sm_start ? true_key[191:160] 	:(keyflag_192 ? g_out : key_gen[6])	^ key_gen_r[5]; //only the four most sig keys are valid for the last round
			assign key_gen[4] = sm_start ? true_key[159:128]	: key_gen[5] 												^ key_gen_r[4];			
			assign key_gen[3] = sm_start ? true_key[127:96] 	: key_four													^ key_gen_r[3]; //need sub words lookup here
			assign key_gen[2] = sm_start ? true_key[95:64]		: key_gen[3] 												^ key_gen_r[2];
			assign key_gen[1] = sm_start ? true_key[63:32]		: key_gen[2]				 								^ key_gen_r[1];
			assign key_gen[0] = sm_start ? true_key[31:0]	  	: key_gen[1] 												^ key_gen_r[0]; 
			
			endmodule: keymaker	


		
		
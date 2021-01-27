/* 		//i
	assign shiftrows_out[15]  = sbox_out[0] ;
	assign shiftrows_out[14]  = sbox_out[5] ;
	assign shiftrows_out[13]  = sbox_out[10];
	assign shiftrows_out[12]  = sbox_out[15];
		
		//ii
	assign shiftrows_out[11]  = sbox_out[4] ;
	assign shiftrows_out[10]  = sbox_out[9] ;
	assign shiftrows_out[9]   = sbox_out[14];
	assign shiftrows_out[8]   = sbox_out[3] ;

		//iii
	assign shiftrows_out[7]   = sbox_out[8] ;
	assign shiftrows_out[6]   = sbox_out[13];
	assign shiftrows_out[5]   = sbox_out[2] ;
	assign shiftrows_out[4]   = sbox_out[7] ;

		//iv
	assign shiftrows_out[3] 	= sbox_out[12];
	assign shiftrows_out[2] 	= sbox_out[1] ;
	assign shiftrows_out[1] 	= sbox_out[6] ;
	assign shiftrows_out[0] 	= sbox_out[11];
 */
 
 
 /*  
	assign mixcol_out[0]  = x2(mixcol_in[0])  ^ x3(mixcol_in[1])  ^    mixcol_in[2]   ^ 	 mixcol_in[3];
	assign mixcol_out[1]  =    mixcol_in[0]   ^ x2(mixcol_in[1])  ^ x3(mixcol_in[2])  ^    mixcol_in[3];
	assign mixcol_out[2]  =    mixcol_in[0]   ^    mixcol_in[1]   ^ x2(mixcol_in[2])  ^ x3(mixcol_in[3]);
	assign mixcol_out[3]  = x3(mixcol_in[0])  ^    mixcol_in[1]   ^    mixcol_in[2]   ^ x2(mixcol_in[3]);

	assign mixcol_out[4]  = x2(mixcol_in[4])  ^ x3(mixcol_in[5])  ^    mixcol_in[6]	  ^    mixcol_in[7];
	assign mixcol_out[5]  =    mixcol_in[4]   ^ x2(mixcol_in[5])  ^ x3(mixcol_in[6])  ^    mixcol_in[7]; 
	assign mixcol_out[6]  =    mixcol_in[4]   ^    mixcol_in[5]   ^ x2(mixcol_in[6])  ^ x3(mixcol_in[7]); 
	assign mixcol_out[7]  = x3(mixcol_in[4])  ^    mixcol_in[5]   ^    mixcol_in[6]   ^ x2(mixcol_in[7]); 

	assign mixcol_out[8]  = x2(mixcol_in[8])  ^ x3(mixcol_in[9])  ^    mixcol_in[10]  ^    mixcol_in[11];
	assign mixcol_out[9]  =    mixcol_in[8]   ^ x2(mixcol_in[9])  ^ x3(mixcol_in[10]) ^   mixcol_in[11]; 
	assign mixcol_out[10] =    mixcol_in[8]   ^    mixcol_in[9]   ^ x2(mixcol_in[10]) ^ x3(mixcol_in[11]); 
	assign mixcol_out[11] = x3(mixcol_in[8])  ^    mixcol_in[9]   ^    mixcol_in[10]  ^ x2(mixcol_in[11]); 

	assign mixcol_out[12] = x2(mixcol_in[12]) ^ x3(mixcol_in[13]) ^     mixcol_in[14] ^		 mixcol_in[15];
	assign mixcol_out[13] =    mixcol_in[12]  ^ x2(mixcol_in[13]) ^ x3(mixcol_in[14]) ^    mixcol_in[15];
	assign mixcol_out[14] =    mixcol_in[12]  ^    mixcol_in[13]  ^ x2(mixcol_in[14]) ^ x3(mixcol_in[15]); 
	assign mixcol_out[15] = x3(mixcol_in[12]) ^    mixcol_in[13]  ^    mixcol_in[14]  ^ x2(mixcol_in[15]); 


 */
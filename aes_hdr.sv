
localparam R_SZ       = 32;  // 32b data size
localparam PC_SZ_2B   = 11;  // arbitrary = 4KB inst ram

//------------------------------------------
// UOP -- this is the result of decoding an inst
//        it contains the control values needed to execute the inst   
//
typedef struct packed {
      logic                   valid;
      logic [PC_SZ_2B-1:0]     pc;        // addr (2B form) of inst

      //--parts of insts to be used/decoded later
      //  if a part is not used by inst, what goes here is DC, so can just be inst bits
      logic [2:0]             func3;      // primary function selector
      logic                   bit30op;    // secondary ""
      logic [4:0]             rd;         // the three regsiter address fields
      logic [4:0]             r1;         //
      logic [4:0]             r2;         //
      
      //--common decodeccontols across multiple insts
      logic                   wr_en;      // inst write a register with rd addr
      logic                   rd_en1;     // inst reads a regsiter with r1 addr
      logic                   rd_en2;     //   "                        r2
      
      logic                   ld_op;      // a memory load inst
      logic                   st_op;      // "        store
      logic                   add_op;     // any op needing add, selects adder result, see adder in i-unit for details of which ops use
      logic                   sub_op;     // "                 , turns adder into subtracter
      logic                   br_op;      // a conditional branch inst

      //--specific inst decode that do unique things
      logic                   lui;
      logic                   auipc;
      logic                   jal;
      logic                   jalr;
      logic                   fence;
      logic                   fence_i;
      logic                   ecall;
      logic                   ebreak;
 
      //--immediate data from inst, extended as appropriate
      logic                   immed_op_type;  // means use immed for oprnd
      logic [R_SZ-1:0]        immed_full;     // the immed data for this inst
	  

} UOP;

//---------------------------------------------
//--DECODE THINGS-----------------------------
//---------------------------------------------


    //--op2 decodes
    localparam LD_OP        = {2'b00, 3'b000};     // 00 000
		localparam FENCE_OP     = {2'b00, 3'b011};     // 00 011    fence, fence.i
		localparam ALUI_OP      = {2'b00, 3'b100};     // 00 100
		localparam AUIPC_OP 		= {2'b00, 3'b101};	   // 00 101
    localparam ALUI64_OP    = {2'b00, 3'b110};     // 00 110    addiw, slliw. srliw, sraiw 
	
    localparam ST_OP        = {2'b01, 3'b000};     // 01 000
    localparam ALU_OP       = {2'b01, 3'b100};     // 01 100    includes M    (func7 used)
		localparam LUI_OP				= {2'b01, 3'b101};	   // 01 101  	LUI
    localparam ALU64_OP     = {2'b01, 3'b110};     // 01 110    addw, sllw, srlw, sraw (subw using b30)
	
    localparam BR_OP        = {2'b11, 3'b000};     // 11 000
		localparam JALR_OP 			= {2'b11, 3'b001};	   // 11 001
		localparam JAL_OP 			= {2'b11, 3'b011};	   // 11 011	
		localparam SPEC_OP      = {2'b11, 3'b100};     // 11 100    call, break, csr...



const logic [15:0][15:0][7:0] SBOX = {
// 0			1			 2			3 		 4			5			 6			7 		 8			9			 a			b      c      d      e      f 	 
   8'h63, 8'h7c, 8'h77, 8'h7b, 8'hf2, 8'h6b, 8'h6f, 8'hc5, 8'h30, 8'h01, 8'h67, 8'h2b, 8'hfe, 8'hd7, 8'hab, 8'h76,  //0
   8'hca, 8'h82, 8'hc9, 8'h7d, 8'hfa, 8'h59, 8'h47, 8'hf0, 8'had, 8'hd4, 8'ha2, 8'haf, 8'h9c, 8'ha4, 8'h72, 8'hc0,	//1
   8'hb7, 8'hfd, 8'h93, 8'h26, 8'h36, 8'h3f, 8'hf7, 8'hcc, 8'h34, 8'ha5, 8'he5, 8'hf1, 8'h71, 8'hd8, 8'h31, 8'h15,	//2
   8'h04, 8'hc7, 8'h23, 8'hc3, 8'h18, 8'h96, 8'h05, 8'h9a, 8'h07, 8'h12, 8'h80, 8'he2, 8'heb, 8'h27, 8'hb2, 8'h75,	//3
   8'h09, 8'h83, 8'h2c, 8'h1a, 8'h1b, 8'h6e, 8'h5a, 8'ha0, 8'h52, 8'h3b, 8'hd6, 8'hb3, 8'h29, 8'he3, 8'h2f, 8'h84,	//4
   8'h53, 8'hd1, 8'h00, 8'hed, 8'h20, 8'hfc, 8'hb1, 8'h5b, 8'h6a, 8'hcb, 8'hbe, 8'h39, 8'h4a, 8'h4c, 8'h58, 8'hcf,  //5
   8'hd0, 8'hef, 8'haa, 8'hfb, 8'h43, 8'h4d, 8'h33, 8'h85, 8'h45, 8'hf9, 8'h02, 8'h7f, 8'h50, 8'h3c, 8'h9f, 8'ha8,	//6
   8'h51, 8'ha3, 8'h40, 8'h8f, 8'h92, 8'h9d, 8'h38, 8'hf5, 8'hbc, 8'hb6, 8'hda, 8'h21, 8'h10, 8'hff, 8'hf3, 8'hd2,	//7
   8'hcd, 8'h0c, 8'h13, 8'hec, 8'h5f, 8'h97, 8'h44, 8'h17, 8'hc4, 8'ha7, 8'h7e, 8'h3d, 8'h64, 8'h5d, 8'h19, 8'h73,	//8
   8'h60, 8'h81, 8'h4f, 8'hdc, 8'h22, 8'h2a, 8'h90, 8'h88, 8'h46, 8'hee, 8'hb8, 8'h14, 8'hde, 8'h5e, 8'h0b, 8'hdb,	//9
   8'he0, 8'h32, 8'h3a, 8'h0a, 8'h49, 8'h06, 8'h24, 8'h5c, 8'hc2, 8'hd3, 8'hac, 8'h62, 8'h91, 8'h95, 8'he4, 8'h79,	//a
	 8'he7, 8'hc8, 8'h37, 8'h6d, 8'h8d, 8'hd5, 8'h4e, 8'ha9, 8'h6c, 8'h56, 8'hf4, 8'hea, 8'h65, 8'h7a, 8'hae, 8'h08,	//b
   8'hba, 8'h78, 8'h25, 8'h2e, 8'h1c, 8'ha6, 8'hb4, 8'hc6, 8'he8, 8'hdd, 8'h74, 8'h1f, 8'h4b, 8'hbd, 8'h8b, 8'h8a,	//c
   8'h70, 8'h3e, 8'hb5, 8'h66, 8'h48, 8'h03, 8'hf6, 8'h0e, 8'h61, 8'h35, 8'h57, 8'hb9, 8'h86, 8'hc1, 8'h1d, 8'h9e,	//d
   8'he1, 8'hf8, 8'h98, 8'h11, 8'h69, 8'hd9, 8'h8e, 8'h94, 8'h9b, 8'h1e, 8'h87, 8'he9, 8'hce, 8'h55, 8'h28, 8'hdf,	//e
   8'h8c, 8'ha1, 8'h89, 8'h0d, 8'hbf, 8'he6, 8'h42, 8'h68, 8'h41, 8'h99, 8'h2d, 8'h0f, 8'hb0, 8'h54, 8'hbb, 8'h16 }; //f

const logic [255:0][7:0] INVSBOX = {
//0				1			2				3			4				5			6				7			8				9	  	a			 b			c				d			e			 f
	8'h52, 8'h09, 8'h6a, 8'hd5, 8'h30, 8'h36, 8'ha5, 8'h38, 8'hbf, 8'h40, 8'ha3, 8'h9e, 8'h81, 8'hf3, 8'hd7, 8'hfb, //0 
	8'h7c, 8'he3, 8'h39, 8'h82, 8'h9b, 8'h2f, 8'hff, 8'h87, 8'h34, 8'h8e, 8'h43, 8'h44, 8'hc4, 8'hde, 8'he9, 8'hcb, //1
	8'h54, 8'h7b, 8'h94, 8'h32, 8'ha6, 8'hc2, 8'h23, 8'h3d, 8'hee, 8'h4c, 8'h95, 8'h0b, 8'h42, 8'hfa, 8'hc3, 8'h4e, //2
	8'h08, 8'h2e, 8'ha1, 8'h66, 8'h28, 8'hd9, 8'h24, 8'hb2, 8'h76, 8'h5b, 8'ha2, 8'h49, 8'h6d, 8'h8b, 8'hd1, 8'h25, //3
	8'h72, 8'hf8, 8'hf6, 8'h64, 8'h86, 8'h68, 8'h98, 8'h16, 8'hd4, 8'ha4, 8'h5c, 8'hcc, 8'h5d, 8'h65, 8'hb6, 8'h92, //4
	8'h6c, 8'h70, 8'h48, 8'h50, 8'hfd, 8'hed, 8'hb9, 8'hda, 8'h5e, 8'h15, 8'h46, 8'h57, 8'ha7, 8'h8d, 8'h9d, 8'h84, //5
	8'h90, 8'hd8, 8'hab, 8'h00, 8'h8c, 8'hbc, 8'hd3, 8'h0a, 8'hf7, 8'he4, 8'h58, 8'h05, 8'hb8, 8'hb3, 8'h45, 8'h06, //6
	8'hd0, 8'h2c, 8'h1e, 8'h8f, 8'hca, 8'h3f, 8'h0f, 8'h02, 8'hc1, 8'haf, 8'hbd, 8'h03, 8'h01, 8'h13, 8'h8a, 8'h6b, //7
	8'h3a, 8'h91, 8'h11, 8'h41, 8'h4f, 8'h67, 8'hdc, 8'hea, 8'h97, 8'hf2, 8'hcf, 8'hce, 8'hf0, 8'hb4, 8'he6, 8'h73, //8
	8'h96, 8'hac, 8'h74, 8'h22, 8'he7, 8'had, 8'h35, 8'h85, 8'he2, 8'hf9, 8'h37, 8'he8, 8'h1c, 8'h75, 8'hdf, 8'h6e, //9
	8'h47, 8'hf1, 8'h1a, 8'h71, 8'h1d, 8'h29, 8'hc5, 8'h89, 8'h6f, 8'hb7, 8'h62, 8'h0e, 8'haa, 8'h18, 8'hbe, 8'h1b, //a
	8'hfc, 8'h56, 8'h3e, 8'h4b, 8'hc6, 8'hd2, 8'h79, 8'h20, 8'h9a, 8'hdb, 8'hc0, 8'hfe, 8'h78, 8'hcd, 8'h5a, 8'hf4, //b
	8'h1f, 8'hdd, 8'ha8, 8'h33, 8'h88, 8'h07, 8'hc7, 8'h31, 8'hb1, 8'h12, 8'h10, 8'h59, 8'h27, 8'h80, 8'hec, 8'h5f, //c
	8'h60, 8'h51, 8'h7f, 8'ha9, 8'h19, 8'hb5, 8'h4a, 8'h0d, 8'h2d, 8'he5, 8'h7a, 8'h9f, 8'h93, 8'hc9, 8'h9c, 8'hef, //d
	8'ha0, 8'he0, 8'h3b, 8'h4d, 8'hae, 8'h2a, 8'hf5, 8'hb0, 8'hc8, 8'heb, 8'hbb, 8'h3c, 8'h83, 8'h53, 8'h99, 8'h61, //e
	8'h17, 8'h2b, 8'h04, 8'h7e, 8'hba, 8'h77, 8'hd6, 8'h26, 8'he1, 8'h69, 8'h14, 8'h63, 8'h55, 8'h21, 8'h0c, 8'h7d};//f

module mixmult2 {
input logic [7:0] cellcont2,
input logic [1:0] cellrow2, //this input tells me what row and column the cell is located in.
input logic [1:0] cellcol2,
output logic [7:0] cellout2
};

logic [7:0] 	cellint2,
logic 				cy2,
assign {cy2, cellint2} = {cellcont2, 1'b0};
assign cellout = cy2 ? cellint2^(8'h1b) : cellint2;   //probably improper syntax on the hex bit.  

endmodule: mixmult2;


module mixmult3 {
input logic [7:0] cellcont3,
input logic [1:0] cellrow3, //this input tells me what row and column the cell is located in.
input logic [1:0] cellcol3,
output logic [7:0] cellout3
};

logic [7:0] 	cellint3, celladd3,
logic 				cy3,
assign {cy3, cellint3} = {cellcont3, 1'b0};
assign celladd3 = cy3 ? cellint3^(2'h1b) : cellint3;   //probably improper syntax on the hex bit.  
assign cellout3 = cellcount3^celladd3;

endmodule: mixmult3;

//there should be muxes on input that determine the value inputs to the column mixer.  

module mixcolrow1 {

input logic [7:0][3:0]  columninput,

output logic [7:0]       celloutput
};

input 








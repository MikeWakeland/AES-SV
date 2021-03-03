/**********************************
CONTENTS
  registers
  muxes


  rlzenc_x32
  rdecode_4_16

************************************/


//-----------------------------------
//--the most basic register
//-----------------------------------
module rregs #(parameter width=1) (
    output logic [width-1:0] q,
    input  logic [width-1:0] d,
    input  logic clk
);
    always_ff @(posedge clk) q <= d;
endmodule:rregs

//-----------------------------------
//--the most basic register using typedef items
//-----------------------------------
module rregt #(parameter type T=logic) (
    output T q,  //
    input  T d,  //													
    input  logic  clk
);
    logic [$bits(d)-1:0] qtmp;
    rregs #($bits(d))    rg ( qtmp, d, clk );
    assign q = T'(qtmp);
endmodule

//-----------------------------------
//--a clock enabled register, but implemented as a mux-reg since fpga doesn't do clk enable
//-----------------------------------
module rregs_en #(parameter width=1) (
    output logic [width-1:0] q,
    input  logic [width-1:0] d,
    input  logic clk,
    input  logic clk_en
);
    logic  [width-1:0] dt;
    assign dt = clk_en ? d : q;  
    always_ff @(posedge clk) q <= dt;
endmodule:rregs_en

//-----------------------------------
//--set dominate set-reset register
//-----------------------------------
module rregs_sr #(parameter width = 1)
                (output logic [width-1:0] q,
                 input  logic [width-1:0] set,
                 input  logic             rst,
                 input  logic             clk);

rregs #(width) r1 (q, set ? '1 : (rst ? '0 : q), clk);
endmodule:rregs_sr

//-----------------------------------
//--reset dominate set-reset register, note parameter are in same place as rregs_sr
//-----------------------------------
module rregs_rs #(parameter width = 1)
                (output logic [width-1:0] q,
                 input  logic [width-1:0] set,
                 input  logic             rst,
                 input  logic             clk);

rregs #(width) r1 (q, rst ? '0 : (set ? '1 : q), clk);
endmodule:rregs_rs

//-----------------------------------
//--3:1 one-hot mux
//-----------------------------------
module rmuxdx2 #(parameter width=1) (
  output logic [width-1:0] out,
  input  logic             sel0, 
  input  logic [width-1:0] in0,
  input  logic             sel1, 
  input  logic [width-1:0] in1
);
  always_comb begin
  unique casez(1'b1) // synopsys infer_onehot_mux
    sel0 : out = in0;
    sel1 : out = in1;
    default : out = 'X;
  endcase
  end
endmodule:rmuxdx2

module rmuxdx3 #(parameter width=1) (
  output logic [width-1:0] out,
  input  logic             sel0, 
  input  logic [width-1:0] in0,
  input  logic             sel1, 
  input  logic [width-1:0] in1, 
  input  logic             sel2, 
  input  logic [width-1:0] in2
);
  always_comb begin
  unique casez(1'b1) // synopsys infer_onehot_mux
    sel0 : out = in0;
    sel1 : out = in1;
    sel2 : out = in2;
    default : out = 'X;
  endcase
  end
endmodule:rmuxdx3

//-----------------------------------
//--3:1 one-hot mux with default output
//-----------------------------------
module rmuxd3 #(parameter width=1) (
  output logic [width-1:0] out,
  input  logic             sel0, 
  input  logic [width-1:0] in0,
  input  logic             sel1, 
  input  logic [width-1:0] in1, 
  input  logic [width-1:0] in2
);
  always_comb begin
  unique casez(1'b1) // synopsys infer_onehot_mux
    sel0 : out = in0;
    sel1 : out = in1;
    default : out = in2;
  endcase
  end
endmodule:rmuxd3

//--more useful muxes ---------------------------

    //-----------------------------------
    module rmuxdx4 #(parameter width=1) (
      output logic [width-1:0] out,
      input  logic             sel0, 
      input  logic [width-1:0] in0,
      input  logic             sel1, 
      input  logic [width-1:0] in1, 
      input  logic             sel2, 
      input  logic [width-1:0] in2,
      input  logic             sel3, 
      input  logic [width-1:0] in3
    );
      always_comb begin
      unique casez(1'b1) // synopsys infer_onehot_mux
        sel0 : out = in0;
        sel1 : out = in1;
        sel2 : out = in2;
        sel3 : out = in3;
        default : out = 'X;
      endcase
      end
    endmodule:rmuxdx4
    
    //-----------------------------------
    module rmuxd4 #(parameter width=1) (
      output logic [width-1:0] out,
      input  logic             sel0, 
      input  logic [width-1:0] in0,
      input  logic             sel1, 
      input  logic [width-1:0] in1, 
      input  logic             sel2, 
      input  logic [width-1:0] in2,
      input  logic [width-1:0] in3
    );
      always_comb begin
      unique casez(1'b1) // synopsys infer_onehot_mux
        sel0 : out = in0;
        sel1 : out = in1;
        sel2 : out = in2;
        default : out = in3;
      endcase
      end
    endmodule:rmuxd4
    
    //-----------------------------------
    module rmuxdx5 #(parameter width=1) (
      output logic [width-1:0] out,
      input  logic             sel0, 
      input  logic [width-1:0] in0,
      input  logic             sel1, 
      input  logic [width-1:0] in1, 
      input  logic             sel2, 
      input  logic [width-1:0] in2,
      input  logic             sel3, 
      input  logic [width-1:0] in3,
      input  logic             sel4, 
      input  logic [width-1:0] in4
    );
      always_comb begin
      unique casez(1'b1) // synopsys infer_onehot_mux
        sel0 : out = in0;
        sel1 : out = in1;
        sel2 : out = in2;
        sel3 : out = in3;
        sel4 : out = in4;
        default : out = 'X;
      endcase
      end
    endmodule:rmuxdx5
	
    //-----------------------------------	
	
	    module rmuxd5 #(parameter width=1) (
      output logic [width-1:0] out,
      input  logic             sel0, 
      input  logic [width-1:0] in0,
      input  logic             sel1, 
      input  logic [width-1:0] in1, 
      input  logic             sel2, 
      input  logic [width-1:0] in2,
	  input  logic 			   sel3,
      input  logic [width-1:0] in3,
	  input  logic [width-1:0] in4
    );
      always_comb begin
      unique casez(1'b1) // synopsys infer_onehot_mux
        sel0 : out = in0;
        sel1 : out = in1;
        sel2 : out = in2;
		sel3 : out = in3;
        default : out = in4;
      endcase
      end
    endmodule:rmuxd5
	
	
	
	
    //-----------------------------------
    module rmuxdx6 #(parameter width=1) (
      output logic [width-1:0] out,
      input  logic             sel0, 
      input  logic [width-1:0] in0,
      input  logic             sel1, 
      input  logic [width-1:0] in1, 
      input  logic             sel2, 
      input  logic [width-1:0] in2,
      input  logic             sel3, 
      input  logic [width-1:0] in3,
      input  logic             sel4, 
      input  logic [width-1:0] in4,
      input  logic             sel5, 
      input  logic [width-1:0] in5
    );
      always_comb begin
      unique casez(1'b1) // synopsys infer_onehot_mux
        sel0 : out = in0;
        sel1 : out = in1;
        sel2 : out = in2;
        sel3 : out = in3;
        sel4 : out = in4;
        sel5 : out = in5;
        default : out = 'X;
      endcase
      end
    endmodule:rmuxdx6
	
    //-----------------------------------
	
	  module rmuxd6 #(parameter width=1) (
      output logic [width-1:0] out,
      input  logic             sel0, 
      input  logic [width-1:0] in0,
      input  logic             sel1, 
      input  logic [width-1:0] in1, 
      input  logic             sel2, 
      input  logic [width-1:0] in2,
	  input  logic 			   sel3,
      input  logic [width-1:0] in3,
	  input  logic			   sel4,
	  input  logic [width-1:0] in4,
	  input  logic [width-1:0] in5
    );
      always_comb begin
      unique casez(1'b1) // synopsys infer_onehot_mux
        sel0 : out = in0;
        sel1 : out = in1;
        sel2 : out = in2;
		sel3 : out = in3;
		sel4 : out = in4;
        default : out = in5;
      endcase
      end
    endmodule:rmuxd6
	
	
	
	
    //-----------------------------------
	
	

	module rmuxdx7 #(parameter width=1) (
      output logic [width-1:0] out,
      input  logic             sel0, 
      input  logic [width-1:0] in0,
      input  logic             sel1, 
      input  logic [width-1:0] in1, 
      input  logic             sel2, 
      input  logic [width-1:0] in2,
      input  logic             sel3, 
      input  logic [width-1:0] in3,
      input  logic             sel4, 
      input  logic [width-1:0] in4,
      input  logic             sel5, 
      input  logic [width-1:0] in5,
      input  logic             sel6, 
      input  logic [width-1:0] in6	  
    );
      always_comb begin
      unique casez(1'b1) // synopsys infer_onehot_mux
        sel0 : out = in0;
        sel1 : out = in1;
        sel2 : out = in2;
        sel3 : out = in3;
        sel4 : out = in4;
        sel5 : out = in5;
				sel6 : out = in6;
        default : out = 'X;
      endcase
      end
    endmodule:rmuxdx7

    //-----------------------------------
	
    module rmuxd7 #(parameter width=1) (
      output logic [width-1:0] out,
      input  logic             sel0, 
      input  logic [width-1:0] in0,
      input  logic             sel1, 
      input  logic [width-1:0] in1, 
      input  logic             sel2, 
      input  logic [width-1:0] in2,
	  input  logic 			   sel3,
      input  logic [width-1:0] in3,
      input  logic             sel4, 
      input  logic [width-1:0] in4, 
      input  logic             sel5, 
      input  logic [width-1:0] in5,  
	  input  logic [width-1:0] in6
    );
      always_comb begin
      unique casez(1'b1) // synopsys infer_onehot_mux
        sel0 : out = in0;
        sel1 : out = in1;
        sel2 : out = in2;
		sel3 : out = in3;
		sel4 : out = in4;
        sel5 : out = in5;	
        default : out = in6;
      endcase
      end
    endmodule:rmuxd7		
	
    //-----------------------------------
	
	
	
	
	
    module rmuxd32 #(parameter width=1) (
      output logic [width-1:0] out,
      input  logic             sel0, 
      input  logic [width-1:0] in0,
      input  logic             sel1, 
      input  logic [width-1:0] in1, 
      input  logic             sel2, 
      input  logic [width-1:0] in2,
	  input  logic 			   sel3,
      input  logic [width-1:0] in3,
      input  logic             sel4, 
      input  logic [width-1:0] in4, 
      input  logic             sel5, 
      input  logic [width-1:0] in5,  
	  input  logic			   sel6, 
	  input  logic [width-1:0] in6,
	  input  logic             sel7, 
      input  logic [width-1:0] in7,
      input  logic             sel8, 
      input  logic [width-1:0] in8, 
      input  logic             sel9, 
      input  logic [width-1:0] in9,
	  input  logic 			   sela,
      input  logic [width-1:0] ina,
      input  logic             selb, 
      input  logic [width-1:0] inb, 
      input  logic             selc, 
      input  logic [width-1:0] inc,  
	  input  logic			   seld, 
	  input  logic [width-1:0] ind,
	  input  logic             sele, 
      input  logic [width-1:0] ine,
      input  logic             self, 
      input  logic [width-1:0] inf, 
      input  logic             sel10, 
      input  logic [width-1:0] in10,
	  input  logic 			   sel11,
      input  logic [width-1:0] in11,
      input  logic             sel12, 
      input  logic [width-1:0] in12, 
      input  logic             sel13, 
      input  logic [width-1:0] in13,  
	  input  logic			   sel14, 
	  input  logic [width-1:0] in14,
	  input  logic             sel15, 
      input  logic [width-1:0] in15,
      input  logic             sel16, 
      input  logic [width-1:0] in16, 
      input  logic             sel17, 
      input  logic [width-1:0] in17,
	  input  logic 			   sel18,
      input  logic [width-1:0] in18,
      input  logic             sel19, 
      input  logic [width-1:0] in19, 
      input  logic             sel1a, 
      input  logic [width-1:0] in1a,  
	  input  logic			   sel1b, 
	  input  logic [width-1:0] in1b,
	  input  logic             sel1c, 
      input  logic [width-1:0] in1c,
      input  logic             sel1d, 
      input  logic [width-1:0] in1d, 
      input  logic             sel1e, 
      input  logic [width-1:0] in1e,
	  input  logic 			   sel1f,
      input  logic [width-1:0] in1f,
	  
	  input  logic [width-1:0] in20
    );
      always_comb begin
      unique casez(1'b1) // synopsys infer_onehot_mux
        sel0 : out = in0;
        sel1 : out = in1;
        sel2 : out = in2;
		sel3 : out = in3;
		sel4 : out = in4;
        sel5 : out = in5;	
        sel6 : out = in6;
        sel7 : out = in7;
        sel8 : out = in8;
		sel9 : out = in9;
		sela : out = ina;
        selb : out = inb;			
        selc : out = inc;
        seld : out = ind;
        sele : out = ine;
		self : out = inf;
		sel10 : out = in10;
        sel11 : out = in11;	
        sel12 : out = in12;
        sel13 : out = in13;
        sel14 : out = in14;
		sel15 : out = in15;
		sel16 : out = in16;
        sel17 : out = in17;		
        sel18 : out = in18;
        sel19 : out = in19;
        sel1a : out = in1a;
		sel1b : out = in1b;
		sel1c : out = in1c;
        sel1d : out = in1d;	
        sel1e : out = in1e;
        sel1f : out = in1f;		
		
        default : out = in20;
      endcase
      end
    endmodule:rmuxd32	
	
	
//--random examples & useful things---------

    //---------------------------------
    module rdecode_4_16 (
        output logic [15:0]  out,
        input  logic [3:0]   in
    ) ;
        assign out[0] =  ~in[3] & ~in[2] & ~in[1] & ~in[0];
        assign out[1] =  ~in[3] & ~in[2] & ~in[1] &  in[0];
        assign out[2] =  ~in[3] & ~in[2] &  in[1] & ~in[0];
        assign out[3] =  ~in[3] & ~in[2] &  in[1] &  in[0];
        assign out[4] =  ~in[3] &  in[2] & ~in[1] & ~in[0];
        assign out[5] =  ~in[3] &  in[2] & ~in[1] &  in[0];
        assign out[6] =  ~in[3] &  in[2] &  in[1] & ~in[0];
        assign out[7] =  ~in[3] &  in[2] &  in[1] &  in[0];
        assign out[8] =   in[3] & ~in[2] & ~in[1] & ~in[0];
        assign out[9] =   in[3] & ~in[2] & ~in[1] &  in[0];
        assign out[10] =  in[3] & ~in[2] &  in[1] & ~in[0];
        assign out[11] =  in[3] & ~in[2] &  in[1] &  in[0];
        assign out[12] =  in[3] &  in[2] & ~in[1] & ~in[0];
        assign out[13] =  in[3] &  in[2] & ~in[1] &  in[0];
        assign out[14] =  in[3] &  in[2] &  in[1] & ~in[0];
        assign out[15] =  in[3] &  in[2] & 	in[1] &  in[0];
    endmodule: rdecode_4_16
//---------------------------------


    module rdecode_5_32 (
        output logic [31:0]  out,
        input  logic [4:0]   in
    ) ;
        assign out[0]  = ~in[4] & ~in[3] & ~in[2] & ~in[1] & ~in[0];
        assign out[1]  = ~in[4] & ~in[3] & ~in[2] & ~in[1] &  in[0];
        assign out[2]  = ~in[4] & ~in[3] & ~in[2] &  in[1] & ~in[0];
        assign out[3]  = ~in[4] & ~in[3] & ~in[2] &  in[1] &  in[0];
        assign out[4]  = ~in[4] & ~in[3] &  in[2] & ~in[1] & ~in[0];
        assign out[5]  = ~in[4] & ~in[3] &  in[2] & ~in[1] &  in[0];
        assign out[6]  = ~in[4] & ~in[3] &  in[2] &  in[1] & ~in[0];
        assign out[7]  = ~in[4] & ~in[3] &  in[2] &  in[1] &  in[0];
        assign out[8]  = ~in[4] &  in[3] & ~in[2] & ~in[1] & ~in[0];
        assign out[9]  = ~in[4] &  in[3] & ~in[2] & ~in[1] &  in[0];
        assign out[10] = ~in[4] & in[3] & ~in[2] &  in[1] & ~in[0];
        assign out[11] = ~in[4] & in[3] & ~in[2] &  in[1] &  in[0];
        assign out[12] = ~in[4] & in[3] &  in[2] & ~in[1] & ~in[0];
        assign out[13] = ~in[4] & in[3] &  in[2] & ~in[1] &  in[0];
        assign out[14] = ~in[4] & in[3] &  in[2] &  in[1] & ~in[0];
        assign out[15] = ~in[4] & in[3] &  in[2] &  in[1] &  in[0];		
        assign out[16]  = in[4] & ~in[3] & ~in[2] & ~in[1] & ~in[0];
        assign out[17]  = in[4] & ~in[3] & ~in[2] & ~in[1] &  in[0];
        assign out[18]  = in[4] & ~in[3] & ~in[2] &  in[1] & ~in[0];
        assign out[19]  = in[4] & ~in[3] & ~in[2] &  in[1] &  in[0];
        assign out[20]  = in[4] & ~in[3] &  in[2] & ~in[1] & ~in[0];
        assign out[21]  = in[4] & ~in[3] &  in[2] & ~in[1] &  in[0];
        assign out[22]  = in[4] & ~in[3] &  in[2] &  in[1] & ~in[0];
        assign out[23]  = in[4] & ~in[3] &  in[2] &  in[1] &  in[0];
        assign out[24]  = in[4] &  in[3] & ~in[2] & ~in[1] & ~in[0];
        assign out[25]  = in[4] &  in[3] & ~in[2] & ~in[1] &  in[0];
        assign out[26]  = in[4] & in[3] & ~in[2] &  in[1] & ~in[0];
        assign out[27]  = in[4] & in[3] & ~in[2] &  in[1] &  in[0];
        assign out[28]  = in[4] & in[3] &  in[2] & ~in[1] & ~in[0];
        assign out[29]  = in[4] & in[3] &  in[2] & ~in[1] &  in[0];
        assign out[30]  = in[4] & in[3] &  in[2] &  in[1] & ~in[0];
        assign out[31]  = in[4] & in[3] &  in[2] &  in[1] &  in[0];			
    endmodule: rdecode_5_32
	
//---------------------------------






//=====================================
module rf_2r1w_32x32 (

   output logic [31:0]   rddata0_p,
   output logic [31:0]   rddata1_p,
   input  logic [4:0]    rdaddr0_p,
   input  logic          rden0_p,

   input  logic [4:0]    rdaddr1_p,
   input  logic          rden1_p,

   input  logic [31:0]   wrdata0_p,
   input  logic [4:0]    wraddr0_p,
   input  logic          wren0_p,
   input  clk

);

  wire [31:0] ent0_p, wrent0_p ;
  wire [31:0] ent1_p, wrent1_p ;
  wire [31:0] ent2_p, wrent2_p ;
  wire [31:0] ent3_p, wrent3_p ;
  wire [31:0] ent4_p, wrent4_p ;
  wire [31:0] ent5_p, wrent5_p ;
  wire [31:0] ent6_p, wrent6_p ;
  wire [31:0] ent7_p, wrent7_p ;
  wire [31:0] ent8_p, wrent8_p ;
  wire [31:0] ent9_p, wrent9_p ;
  wire [31:0] ent10_p, wrent10_p ;
  wire [31:0] ent11_p, wrent11_p ;
  wire [31:0] ent12_p, wrent12_p ;
  wire [31:0] ent13_p, wrent13_p ;
  wire [31:0] ent14_p, wrent14_p ;
  wire [31:0] ent15_p, wrent15_p ;
  wire [31:0] ent16_p, wrent16_p ;
  wire [31:0] ent17_p, wrent17_p ;
  wire [31:0] ent18_p, wrent18_p ;
  wire [31:0] ent19_p, wrent19_p ;
  wire [31:0] ent20_p, wrent20_p ;
  wire [31:0] ent21_p, wrent21_p ;
  wire [31:0] ent22_p, wrent22_p ;
  wire [31:0] ent23_p, wrent23_p ;
  wire [31:0] ent24_p, wrent24_p ;
  wire [31:0] ent25_p, wrent25_p ;
  wire [31:0] ent26_p, wrent26_p ;
  wire [31:0] ent27_p, wrent27_p ;
  wire [31:0] ent28_p, wrent28_p ;
  wire [31:0] ent29_p, wrent29_p ;
  wire [31:0] ent30_p, wrent30_p ;
  wire [31:0] ent31_p, wrent31_p ;

//--------------------------------------------------------------
//--------------------------------------------------------------

//--------------------------------------------------------------
// Write logic
//--------------------------------------------------------------
wire [31:0] wren_ent_p ;


   wire [31:0] wraddrdec0_p, wraddrdecuq0_p;
         rdecode_5_32 wr0 (wraddrdecuq0_p, wraddr0_p);
   assign wraddrdec0_p = wraddrdecuq0_p & {32{wren0_p}};

assign wren_ent_p =
        wraddrdec0_p              ; 

//--------------------------------------------------------------
// Storage
//--------------------------------------------------------------
      assign wrent0_p = wrdata0_p;
      assign wrent1_p = wrdata0_p;
      assign wrent2_p = wrdata0_p;
      assign wrent3_p = wrdata0_p;
      assign wrent4_p = wrdata0_p;
      assign wrent5_p = wrdata0_p;
      assign wrent6_p = wrdata0_p;
      assign wrent7_p = wrdata0_p;
      assign wrent8_p = wrdata0_p;
      assign wrent9_p = wrdata0_p;
      assign wrent10_p = wrdata0_p;
      assign wrent11_p = wrdata0_p;
      assign wrent12_p = wrdata0_p;
      assign wrent13_p = wrdata0_p;
      assign wrent14_p = wrdata0_p;
      assign wrent15_p = wrdata0_p;
      assign wrent16_p = wrdata0_p;
      assign wrent17_p = wrdata0_p;
      assign wrent18_p = wrdata0_p;
      assign wrent19_p = wrdata0_p;
      assign wrent20_p = wrdata0_p;
      assign wrent21_p = wrdata0_p;
      assign wrent22_p = wrdata0_p;
      assign wrent23_p = wrdata0_p;
      assign wrent24_p = wrdata0_p;
      assign wrent25_p = wrdata0_p;
      assign wrent26_p = wrdata0_p;
      assign wrent27_p = wrdata0_p;
      assign wrent28_p = wrdata0_p;
      assign wrent29_p = wrdata0_p;
      assign wrent30_p = wrdata0_p;
      assign wrent31_p = wrdata0_p;

            rregs_en #(32) ent0 (ent0_p, wrent0_p, clk, wren_ent_p[0]);
            rregs_en #(32) ent1 (ent1_p, wrent1_p, clk, wren_ent_p[1]);
            rregs_en #(32) ent2 (ent2_p, wrent2_p, clk, wren_ent_p[2]);
            rregs_en #(32) ent3 (ent3_p, wrent3_p, clk, wren_ent_p[3]);
            rregs_en #(32) ent4 (ent4_p, wrent4_p, clk, wren_ent_p[4]);
            rregs_en #(32) ent5 (ent5_p, wrent5_p, clk, wren_ent_p[5]);
            rregs_en #(32) ent6 (ent6_p, wrent6_p, clk, wren_ent_p[6]);
            rregs_en #(32) ent7 (ent7_p, wrent7_p, clk, wren_ent_p[7]);
            rregs_en #(32) ent8 (ent8_p, wrent8_p, clk, wren_ent_p[8]);
            rregs_en #(32) ent9 (ent9_p, wrent9_p, clk, wren_ent_p[9]);
            rregs_en #(32) ent10 (ent10_p, wrent10_p, clk, wren_ent_p[10]);
            rregs_en #(32) ent11 (ent11_p, wrent11_p, clk, wren_ent_p[11]);
            rregs_en #(32) ent12 (ent12_p, wrent12_p, clk, wren_ent_p[12]);
            rregs_en #(32) ent13 (ent13_p, wrent13_p, clk, wren_ent_p[13]);
            rregs_en #(32) ent14 (ent14_p, wrent14_p, clk, wren_ent_p[14]);
            rregs_en #(32) ent15 (ent15_p, wrent15_p, clk, wren_ent_p[15]);
            rregs_en #(32) ent16 (ent16_p, wrent16_p, clk, wren_ent_p[16]);
            rregs_en #(32) ent17 (ent17_p, wrent17_p, clk, wren_ent_p[17]);
            rregs_en #(32) ent18 (ent18_p, wrent18_p, clk, wren_ent_p[18]);
            rregs_en #(32) ent19 (ent19_p, wrent19_p, clk, wren_ent_p[19]);
            rregs_en #(32) ent20 (ent20_p, wrent20_p, clk, wren_ent_p[20]);
            rregs_en #(32) ent21 (ent21_p, wrent21_p, clk, wren_ent_p[21]);
            rregs_en #(32) ent22 (ent22_p, wrent22_p, clk, wren_ent_p[22]);
            rregs_en #(32) ent23 (ent23_p, wrent23_p, clk, wren_ent_p[23]);
            rregs_en #(32) ent24 (ent24_p, wrent24_p, clk, wren_ent_p[24]);
            rregs_en #(32) ent25 (ent25_p, wrent25_p, clk, wren_ent_p[25]);
            rregs_en #(32) ent26 (ent26_p, wrent26_p, clk, wren_ent_p[26]);
            rregs_en #(32) ent27 (ent27_p, wrent27_p, clk, wren_ent_p[27]);
            rregs_en #(32) ent28 (ent28_p, wrent28_p, clk, wren_ent_p[28]);
            rregs_en #(32) ent29 (ent29_p, wrent29_p, clk, wren_ent_p[29]);
            rregs_en #(32) ent30 (ent30_p, wrent30_p, clk, wren_ent_p[30]);
            rregs_en #(32) ent31 (ent31_p, wrent31_p, clk, wren_ent_p[31]);

//--------------------------------------------------------------
// Read logic
//--------------------------------------------------------------
   wire [4:0]    rdaddrstg0_p   ,   rdaddrstg1_p  ;
   wire [31:0]    rdsel0_p   ,   rdsel1_p  ;

   rregs_en #(5) ra0 (rdaddrstg0_p, rdaddr0_p, clk, rden0_p);
   rregs_en #(1) re0 (rden0_stg_p, rden0_p, clk, 1'b1);
   rregs_en #(5) ra1 (rdaddrstg1_p, rdaddr1_p, clk, rden1_p);
   rregs_en #(1) re1 (rden1_stg_p, rden1_p, clk, 1'b1);

   rdecode_5_32 rd0 (rdsel0_p, rdaddrstg0_p);
   rdecode_5_32 rd1 (rdsel1_p, rdaddrstg1_p);

    wire [31:0] raw_rddata0_p =
       {32{rdsel0_p[0]}} & ent0_p        | 
       {32{rdsel0_p[1]}} & ent1_p        | 
       {32{rdsel0_p[2]}} & ent2_p        | 
       {32{rdsel0_p[3]}} & ent3_p        | 
       {32{rdsel0_p[4]}} & ent4_p        | 
       {32{rdsel0_p[5]}} & ent5_p        | 
       {32{rdsel0_p[6]}} & ent6_p        | 
       {32{rdsel0_p[7]}} & ent7_p        | 
       {32{rdsel0_p[8]}} & ent8_p        | 
       {32{rdsel0_p[9]}} & ent9_p        | 
       {32{rdsel0_p[10]}} & ent10_p        | 
       {32{rdsel0_p[11]}} & ent11_p        | 
       {32{rdsel0_p[12]}} & ent12_p        | 
       {32{rdsel0_p[13]}} & ent13_p        | 
       {32{rdsel0_p[14]}} & ent14_p        | 
       {32{rdsel0_p[15]}} & ent15_p        | 
       {32{rdsel0_p[16]}} & ent16_p        | 
       {32{rdsel0_p[17]}} & ent17_p        | 
       {32{rdsel0_p[18]}} & ent18_p        | 
       {32{rdsel0_p[19]}} & ent19_p        | 
       {32{rdsel0_p[20]}} & ent20_p        | 
       {32{rdsel0_p[21]}} & ent21_p        | 
       {32{rdsel0_p[22]}} & ent22_p        | 
       {32{rdsel0_p[23]}} & ent23_p        | 
       {32{rdsel0_p[24]}} & ent24_p        | 
       {32{rdsel0_p[25]}} & ent25_p        | 
       {32{rdsel0_p[26]}} & ent26_p        | 
       {32{rdsel0_p[27]}} & ent27_p        | 
       {32{rdsel0_p[28]}} & ent28_p        | 
       {32{rdsel0_p[29]}} & ent29_p        | 
       {32{rdsel0_p[30]}} & ent30_p        | 
       {32{rdsel0_p[31]}} & ent31_p        ; 
    wire [31:0] raw_rddata1_p =
       {32{rdsel1_p[0]}} & ent0_p        | 
       {32{rdsel1_p[1]}} & ent1_p        | 
       {32{rdsel1_p[2]}} & ent2_p        | 
       {32{rdsel1_p[3]}} & ent3_p        | 
       {32{rdsel1_p[4]}} & ent4_p        | 
       {32{rdsel1_p[5]}} & ent5_p        | 
       {32{rdsel1_p[6]}} & ent6_p        | 
       {32{rdsel1_p[7]}} & ent7_p        | 
       {32{rdsel1_p[8]}} & ent8_p        | 
       {32{rdsel1_p[9]}} & ent9_p        | 
       {32{rdsel1_p[10]}} & ent10_p        | 
       {32{rdsel1_p[11]}} & ent11_p        | 
       {32{rdsel1_p[12]}} & ent12_p        | 
       {32{rdsel1_p[13]}} & ent13_p        | 
       {32{rdsel1_p[14]}} & ent14_p        | 
       {32{rdsel1_p[15]}} & ent15_p        | 
       {32{rdsel1_p[16]}} & ent16_p        | 
       {32{rdsel1_p[17]}} & ent17_p        | 
       {32{rdsel1_p[18]}} & ent18_p        | 
       {32{rdsel1_p[19]}} & ent19_p        | 
       {32{rdsel1_p[20]}} & ent20_p        | 
       {32{rdsel1_p[21]}} & ent21_p        | 
       {32{rdsel1_p[22]}} & ent22_p        | 
       {32{rdsel1_p[23]}} & ent23_p        | 
       {32{rdsel1_p[24]}} & ent24_p        | 
       {32{rdsel1_p[25]}} & ent25_p        | 
       {32{rdsel1_p[26]}} & ent26_p        | 
       {32{rdsel1_p[27]}} & ent27_p        | 
       {32{rdsel1_p[28]}} & ent28_p        | 
       {32{rdsel1_p[29]}} & ent29_p        | 
       {32{rdsel1_p[30]}} & ent30_p        | 
       {32{rdsel1_p[31]}} & ent31_p        ; 

    assign rddata0_p = rden0_stg_p ? raw_rddata0_p : {32{1'b1}};
    assign rddata1_p = rden1_stg_p ? raw_rddata1_p : {32{1'b1}};
	


endmodule:rf_2r1w_32x32



//-------------------------------------------------
//--1-read-or-write ram NO byte enables ---------Behavioral, not hardware.
//-------------------------------------------------
module rf_1rw #(parameter DEPTH=8, WIDTH=32) (
     output logic[WIDTH-1:0]         dout,
     input  logic		                 eph1,
     input  logic                    write,
     input  logic[$clog2(DEPTH)-1:0] addr,
     input  logic[WIDTH-1:0]         din );

localparam NBYTES = WIDTH/8;
localparam DLG2   = $clog2(DEPTH);


logic[NBYTES-1:0][7:0] RAM  [DEPTH-1:0]; logic[NBYTES-1:0][7:0] din_bytes;

logic[WIDTH/8-1:0] wben;
assign wben = '1;

assign din_bytes = din;

for (genvar d=0; d<DEPTH; d+=1) begin: g_rf
     for (genvar b=0; b<NBYTES; b+=1) begin : g_bytes
         rregs_en #(8) rgdata ( RAM[d][b], din_bytes[b], eph1, write & wben[b] & addr == d );
     end : g_bytes
end : g_rf

logic[DLG2-1:0] addr_stg;
rregs #(DLG2) rgaddrstg (addr_stg, addr, eph1 );

always_comb begin
     dout = '1;
     for (int i=0; i<DEPTH; i+=1) begin
         dout &= (addr_stg == i) ? RAM[i] : '1;
     end
end

endmodule: rf_1rw


//This is a counter that I ripped off the internet.  Behavioral.  
module counter(
		output logic [3:0] count_out,
    input  logic [3:0] count_in,
		input  logic clk    
);

always @(posedge clk) count_out <= count_in + 1;     //     always_ff @(posedge clk) q <= d;
endmodule: counter

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
		
		logic [127:0] plain_text;
		assign plain_text = 128'h00112233445566778899aabbccddeeff;   //Generated via matlab: binaryVectorToHex(ceil(rand(1,128)-.5))


		// The true key is: 256'hEBA02E379817D636A144551DF49ADE37F01F2E724AC0AB35BE3A20FF7A7D7FCA, for reference purposes only.
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
				128'hEBA02E379817D636A144551DF49ADE37,
				128'hF01F2E724AC0AB35BE3A20FF7A7D7FCA,
				128'h15725AED8D658CDB2C21D9C6D8BB07F1,
				128'h91F5EBD3DB3540E6650F60191F721FD3,
				128'h57B23C2DDAD7B0F6F6F669302E4D6EC1,
				128'hA01674AB7B23344D1E2C5454015E4B87,
				128'h0B012B51D1D69BA72720F297096D9C56,
				128'hA12AAA1ADA099E57C425CA03C57B8184,
				128'h220D74F7F3DBEF50D4FB1DC7DD968191,
				128'h60BAA69BBAB338CC7E96F2CFBBED734B,   
				128'h6782C71D9459284D40A2358A9D34B41B,
				128'h3EA22B34841113F8FA87E137416A927C,
				128'h45CDD79ED194FFD39136CA590C027E42,
				128'hC0D5D81844C4CBE0BE432AD7FF29B8AB,
				128'hA0A1B58871354A5BE0038002EC01FE40};

			logic ready;

			assign ready = ~reset; 
/////////////////////////////////////////////////////End fake input section///////////////////////////////////////////////////////		
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

			aes aesist (  										//This module instantiates all of AES, which takes only fake inputs and spits out only real results.   
				.eph1         					(eph1),
				.reset        					(reset),
				.start 									(start),

				.ready_i 								(ready),
				.plain_text_i						(plain_text),
				.key_size_i							(key_size),  
				.key_words_i   					(key_words),

				.fin_flag_r							(fin_flag_r),
				.aes_out_r  						(aes_out_r)   
		); 


endmodule: tb_top
 
 
		 module aes (
		 
				input logic										eph1,
				input logic										reset,
				input logic										start,

				input logic										ready_i,
				input logic  [127:0]					plain_text_i,
				input logic  [1:0]						key_size_i, 
				input logic  [15:1][127:0] 		key_words_i,
				
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
		 logic										ready, rdy_reg;
		 logic  [127:0]						plain_text;
		 logic  [1:0]							key_size; 
		 logic  [15:1][127:0] 		key_words;
			
		//Register inputs for timing. 	
		rregs #(1) 		rdyi 	(ready, ready_i, eph1);
		rregs #(1) 		rdyreg (rdy_reg, reset ? '0 : ready, eph1); //rdy_reg exists to ensure that start_flag is only up for one c/c, which is the clock immediately after 
																															//AES receives the positive edge of the ready flag input.  
		rregs #(128)	pti 	(plain_text, plain_text_i, eph1);		
		rregs #(2)		ksi 	(key_size, key_size_i, eph1);					
		rregs #(1920) kwi 	(key_words, key_words_i, eph1);


		//Works with ready and rdy_reg to provide the start signal to AES
		rregs #(1) kdked (start_flag , reset ? '0 : ready^rdy_reg, eph1); 
		
		rregs #(128)  rnrec ( round_recycle , round_out , eph1);
		assign round_in = start_flag ? plain_text^key_words[15] : round_recycle ; //selects the plaintext XOR key or previous round's output as the input to the next round.  																																																																			
		assign aes_out_r = fin_flag_r ? round_recycle : '0; 									 		//Captures the registered value of round out as the final output, avoiding another register.    		
		rregs #(1) 		finfl  (fin_flag_r, reset ? '0 : fin_flag | fin_flag_r, eph1);//delays fin_flag by one c/c to match timing with the proper aes output.  
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
		 logic [3:0] cycle_ctr_pr, div_clks, cycle_ctr;
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
	
		
 
 endmodule: aes
 
 
 
 
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





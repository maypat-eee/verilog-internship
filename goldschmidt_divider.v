

module fadder_4bit(
    input [3:0] A, B,
    input cin,
    output [3:0] sum,
    output cout
);
    wire c0, c1, c2;
    
    full_adder_1bit fa0 (.a(A[0]), .b(B[0]), .cin(cin), .sum(sum[0]), .cout(c0));
    full_adder_1bit fa1 (.a(A[1]), .b(B[1]), .cin(c0),  .sum(sum[1]), .cout(c1));
    full_adder_1bit fa2 (.a(A[2]), .b(B[2]), .cin(c1),  .sum(sum[2]), .cout(c2));
    full_adder_1bit fa3 (.a(A[3]), .b(B[3]), .cin(c2),  .sum(sum[3]), .cout(cout));
endmodule

module full_adder_1bit(
    input a, b, cin,
    output sum, cout
);
    wire w1, w2, w3;
    
    xor (w1, a, b);
    xor (sum, w1, cin);
    and (w2, w1, cin);
    and (w3, a, b);
    or  (cout, w2, w3);
endmodule

module adder(
 input A,
 input B,
 input cin,
 output sum,
 output cout
);
wire a1;
wire a3;
wire a4;

xor(a1,A,B);
xor(sum,a1,cin);

and(a3,A,B);
and(a4,a1,cin);

or(cout,a3,a4);
endmodule

module barshiftr(
    input  [15:0] in,
    output [15:0] q,
    input  [3:0] o
);

    wire [15:0] j, j1, j2;
    wire [15:0] sh1, sh2, sh4, sh8;

    
    assign sh1 = {1'b0,        in[15:1]};
    assign sh2 = {2'b00,       j[15:2]};
    assign sh4 = {4'b0000,     j1[15:4]};
    assign sh8 = {8'b00000000, j2[15:8]};

    mux8 m1_top(.a(in[15:8]), .b(sh1[15:8]), .sel(o[0]), .q(j[15:8]));
    mux8 m1_bot(.a(in[7:0]),  .b(sh1[7:0]),  .sel(o[0]), .q(j[7:0]));

    mux8 m2_top(.a(j[15:8]),  .b(sh2[15:8]), .sel(o[1]), .q(j1[15:8]));
    mux8 m2_bot(.a(j[7:0]),   .b(sh2[7:0]),  .sel(o[1]), .q(j1[7:0]));

    mux8 m4_top(.a(j1[15:8]), .b(sh4[15:8]), .sel(o[2]), .q(j2[15:8]));
    mux8 m4_bot(.a(j1[7:0]),  .b(sh4[7:0]),  .sel(o[2]), .q(j2[7:0]));

    mux8 m8_top(.a(j2[15:8]), .b(sh8[15:8]), .sel(o[3]), .q(q[15:8]));
    mux8 m8_bot(.a(j2[7:0]),  .b(sh8[7:0]),  .sel(o[3]), .q(q[7:0]));

endmodule

module barshiftd(
    input [7:0] in,
    output [7:0] q,
    output [2:0] o
);

    wire [7:0] j, j1;
    wire [7:0] sh1, sh2, sh4;

    assign o[2] = (~in[7] & ~in[6] & ~in[5] & ~in[4]);

    assign o[1] = (~in[7] & ~in[6] & (in[5] | in[4])) | 
                  (~in[7] & ~in[6] & ~in[5] & ~in[4] & ~in[3] & ~in[2]);

    assign o[0] = (~in[7] & in[6]) | 
                  (~in[7] & ~in[6] & ~in[5] & in[4]) | 
                  (~in[7] & ~in[6] & ~in[5] & ~in[4] & ~in[3] & in[2]) | 
                  (~in[7] & ~in[6] & ~in[5] & ~in[4] & ~in[3] & ~in[2] & ~in[1]);

    assign sh1 = {in[6:0], 1'b0};
    assign sh2 = {j[5:0], 2'b00};
    assign sh4 = {j1[3:0], 4'b0000};
    
  
    mux8 m1 (
        .a(in),
        .b(sh1),
        .sel(o[0]),
        .q(j)
    );

    mux8 m2 (
        .a(j),
        .b(sh2),
        .sel(o[1]),
        .q(j1)
    );

    mux8 m4 (
        .a(j1),
        .b(sh4),
        .sel(o[2]),
        .q(q)
    );

endmodule

module cla_slice(
    input a,
    input b,
    input cin,
    output sum,
    output p,
    output g
);

    xor g_prop (p, a, b);       
    and g_gen  (g, a, b);       
    xor g_sum  (sum, p, cin);   
endmodule

module cla_adder_16bit(
    input [15:0] a,
    input [15:0] b,
    input cin,
    output [15:0] sum,
    output cout
);
    
    wire [15:0] p, g;
    wire [15:0] c;
    wire [3:0] pg_g, gg_g; 
    wire [3:0] block_carries;
    wire w_bc0, w_bc1, w_bc2, w_cout; 

    cla_slice s0 (a[0], b[0], cin,  sum[0], p[0], g[0]);
    cla_slice s1 (a[1], b[1], c[0], sum[1], p[1], g[1]);
    cla_slice s2 (a[2], b[2], c[1], sum[2], p[2], g[2]);
    cla_slice s3 (a[3], b[3], c[2], sum[3], p[3], g[3]);
    
    cla_logic_4bit logic0 (
        .p(p[3:0]), .g(g[3:0]), .cin(cin),
        .c(c[3:0]), .pg(pg_g[0]), .gg(gg_g[0])
    );
   
    and a_bc0(w_bc0, pg_g[0], cin);
    or  o_bc0(block_carries[0], gg_g[0], w_bc0);

   
    cla_slice s4 (a[4], b[4], block_carries[0], sum[4], p[4], g[4]);
    cla_slice s5 (a[5], b[5], c[4],             sum[5], p[5], g[5]);
    cla_slice s6 (a[6], b[6], c[5],             sum[6], p[6], g[6]);
    cla_slice s7 (a[7], b[7], c[6],             sum[7], p[7], g[7]);
    
    cla_logic_4bit logic1 (
        .p(p[7:4]), .g(g[7:4]), .cin(block_carries[0]),
        .c(c[7:4]), .pg(pg_g[1]), .gg(gg_g[1])
    );
    and a_bc1(w_bc1, pg_g[1], block_carries[0]);
    or  o_bc1(block_carries[1], gg_g[1], w_bc1);

    
    cla_slice s8  (a[8],  b[8],  block_carries[1], sum[8],  p[8],  g[8]);
    cla_slice s9  (a[9],  b[9],  c[8],             sum[9],  p[9],  g[9]);
    cla_slice s10 (a[10], b[10], c[9],             sum[10], p[10], g[10]);
    cla_slice s11 (a[11], b[11], c[10],            sum[11], p[11], g[11]);
    
    cla_logic_4bit logic2 (
        .p(p[11:8]), .g(g[11:8]), .cin(block_carries[1]),
        .c(c[11:8]), .pg(pg_g[2]), .gg(gg_g[2])
    );
    and a_bc2(w_bc2, pg_g[2], block_carries[1]);
    or  o_bc2(block_carries[2], gg_g[2], w_bc2);

 
    cla_slice s12 (a[12], b[12], block_carries[2], sum[12], p[12], g[12]);
    cla_slice s13 (a[13], b[13], c[12],            sum[13], p[13], g[13]);
    cla_slice s14 (a[14], b[14], c[13],            sum[14], p[14], g[14]);
    cla_slice s15 (a[15], b[15], c[14],            sum[15], p[15], g[15]);
    
    cla_logic_4bit logic3 (
        .p(p[15:12]), .g(g[15:12]), .cin(block_carries[2]),
        .c(c[15:12]), .pg(pg_g[3]), .gg(gg_g[3])
    );
    and a_cout(w_cout, pg_g[3], block_carries[2]);
    or  o_cout(cout, gg_g[3], w_cout);

endmodule

module cla_logic_4bit(
    input [3:0] p,  
    input [3:0] g,   
    input cin,      
    output [3:0] c,  
    output pg,       
    output gg        
);
   
    wire w_c1_1;
    wire w_c2_1, w_c2_2;
    wire w_c3_1, w_c3_2, w_c3_3;
    wire w_c4_1, w_c4_2, w_c4_3, w_c4_4;

   
    and a_c1_1 (w_c1_1, p[0], cin);
    or  o_c1   (c[0], g[0], w_c1_1);

    and a_c2_1 (w_c2_1, p[1], g[0]);
    and a_c2_2 (w_c2_2, p[1], p[0], cin);
    or  o_c2   (c[1], g[1], w_c2_1, w_c2_2);

    and a_c3_1 (w_c3_1, p[2], g[1]);
    and a_c3_2 (w_c3_2, p[2], p[1], g[0]);
    and a_c3_3 (w_c3_3, p[2], p[1], p[0], cin);
    or  o_c3   (c[2], g[2], w_c3_1, w_c3_2, w_c3_3);

   
    and a_c4_1 (w_c4_1, p[3], g[2]);
    and a_c4_2 (w_c4_2, p[3], p[2], g[1]);
    and a_c4_3 (w_c4_3, p[3], p[2], p[1], g[0]);
    and a_c4_4 (w_c4_4, p[3], p[2], p[1], p[0], cin);
    or  o_c4   (c[3], g[3], w_c4_1, w_c4_2, w_c4_3, w_c4_4);

    
    and a_pg (pg, p[3], p[2], p[1], p[0]);
    or  o_gg (gg, g[3], w_c4_1, w_c4_2, w_c4_3);

endmodule

module com42 (
    input i1,
    input i2,
    input i3,
    input i4,
    input cin,  
    output sum, 
    output c1,  
    output cout 
);
    
    wire s1;

    
    fa fa1 (
        .a(i1),
        .b(i2),
        .cin(i3),
        .sum(s1),
        .cout(c1)
    );

    
    fa fa2 (
        .a(s1),
        .b(i4),
        .cin(cin),
        .sum(sum),
        .cout(cout)
    );

endmodule

module com52(
    input i1, input i2, input i3, input i4, input i5,
    output sum,    
    output cout1,  
    output cout2   
);

    wire s1;

    
    fa fa1 (
        .a(i1), 
        .b(i2), 
        .cin(i3), 
        .sum(s1), 
        .cout(cout1)
    );

   
    fa fa2 (
        .a(s1), 
        .b(i4), 
        .cin(i5), 
        .sum(sum), 
        .cout(cout2)
    );

endmodule

module com62(
    input i1, input i2, input i3, input i4, input i5, input i6,
    output sum1,   
    output sum2,   
    output cout1, 
    output cout2   
);

    fa fa1 (
        .a(i1), 
        .b(i2), 
        .cin(i3), 
        .sum(sum1), 
        .cout(cout1)
    );

  
    fa fa2 (
        .a(i4), 
        .b(i5), 
        .cin(i6), 
        .sum(sum2), 
        .cout(cout2)
    );

endmodule

module com82(
    
    input i1, input i2, input i3, input i4,
    input i5, input i6, input i7, input i8,
    
    
    input cin42,    
    
    
    output sum,       
    
    
    output coutfa1,  
    output coutfa2,  
    output c142,    
    output cout42   
);

    
    wire w_s1, w_s2;

    
    fa fa1 (
        .a(i1), .b(i2), .cin(i3), 
        .sum(w_s1), .cout(coutfa1)
    );

    fa fa2 (
        .a(i4), .b(i5), .cin(i6), 
        .sum(w_s2), .cout(coutfa2)
    );

    com42 comp42 (
        .i1(w_s1), .i2(w_s2), .i3(i7), .i4(i8),
        .cin(cin42),
        .sum(sum), .c1(c142), .cout(cout42)
    );

endmodule

module counter_2bit (
    input clk,
    input rst,
    input en,
    output [1:0] count
);

    wire qb0, qb1, d1;

    
    dff ff0 (
        .D(qb0),
        .clk(clk),
        .rst(rst),
        .en(en),
        .q(count[0]),
        .qb(qb0)
    );

    
    xor x1 (d1, count[1], count[0]);

    dff ff1 (
        .D(d1),
        .clk(clk),
        .rst(rst),
        .en(en),
        .q(count[1]),
        .qb(qb1)
    );

endmodule

module decoder_4to16(
    input [3:0] in,
    output [15:0] out
);
    wire [3:0] n;
    not inv[3:0] (n, in);
    
    and (out[0],  n[3], n[2], n[1], n[0]);
    and (out[1],  n[3], n[2], n[1], in[0]);
    and (out[2],  n[3], n[2], in[1], n[0]);
    and (out[3],  n[3], n[2], in[1], in[0]);
    and (out[4],  n[3], in[2], n[1], n[0]);
    and (out[5],  n[3], in[2], n[1], in[0]);
    and (out[6],  n[3], in[2], in[1], n[0]);
    and (out[7],  n[3], in[2], in[1], in[0]);
    and (out[8],  in[3], n[2], n[1], n[0]);
    and (out[9],  in[3], n[2], n[1], in[0]);
    and (out[10], in[3], n[2], in[1], n[0]);
    and (out[11], in[3], n[2], in[1], in[0]);
    and (out[12], in[3], in[2], n[1], n[0]);
    and (out[13], in[3], in[2], n[1], in[0]);
    and (out[14], in[3], in[2], in[1], n[0]);
    and (out[15], in[3], in[2], in[1], in[0]);
endmodule

module dff(
    input D, clk, rst, en,
    output reg q,
    output qb
);

    always @(posedge clk) begin
        if (rst)
            q <= 1'b0;
        else if (en)
            q <= D;
    end

    assign qb = ~q;
    
endmodule

module fa (
    input a,
    input b,
    input cin,
    output sum,
    output cout
);
    
    wire x1,x2,x3;

    xor g1 (x1, a, b);
    xor g2 (sum, x1, cin);

    
    and g3 (x2, x1, cin);
    and g4 (x3, a, b);
    or  g5 (cout,x2, x3);

endmodule

module fadder(
input [7:0]A,
input [7:0]B,
input cin,
output [7:0]sum,
output cout
);
wire c1,c2,c3,c4,c5,c6,c7;
adder a0(
.A(A[0]),
.B(B[0]),
.cin(cin),
.sum(sum[0]),
.cout(c1)
);

adder a1(
.A(A[1]),
.B(B[1]),
.cin(c1),
.sum(sum[1]),
.cout(c2)
);

adder a2(
.A(A[2]),
.B(B[2]),
.cin(c2),
.sum(sum[2]),
.cout(c3)
);


adder a3(
.A(A[3]),
.B(B[3]),
.cin(c3),
.sum(sum[3]),
.cout(c4)
);
adder a4(
.A(A[4]),
.B(B[4]),
.cin(c4),
.sum(sum[4]),
.cout(c5)
);


adder a5(
.A(A[5]),
.B(B[5]),
.cin(c5),
.sum(sum[5]),
.cout(c6)
);

adder a6(
.A(A[6]),
.B(B[6]),
.cin(c6),
.sum(sum[6]),
.cout(c7)
);

adder a7(
.A(A[7]),
.B(B[7]),
.cin(c7),
.sum(sum[7]),
.cout(cout)
);

endmodule 

module gdivider(
    input [7:0] dividend,
    input [7:0] divisor,
    output [7:0] quotient, 
    input clk,
    input rst,
    input en
);

  
    wire nen;
    wire [1:0] count;
    
   
    nand (nen, en, count[1]);

    counter_2bit c_counter (
        .clk(clk),
        .rst(rst),
        .en(nen),
        .count(count)
    );

    
    wire [7:0] shiftl;
    wire [2:0] o;

    barshiftd c1 (
        .in(divisor),
        .q(shiftl),
        .o(o)
    );

    wire [3:0] n;
    wire [7:0] lo;
    
    
    assign n = shiftl[6:3];

    lut c2 (
        .index(n),
        .X0(lo)   
    );

    wire en_d1;       
    wire en_n1;       
    wire not_count1;
    wire not_count0;

    not (not_count1, count[1]);
    not (not_count0, count[0]);

    nor (en_d1, count[1], count[0]);

    and (en_n1, not_count1, count[0]);

    wire [7:0] pr; 
    wire [7:0] D1_reg;
    
    dff d_d1_0 (.D(pr[0]), .clk(clk), .rst(rst), .en(en_d1), .q(D1_reg[0]));
    dff d_d1_1 (.D(pr[1]), .clk(clk), .rst(rst), .en(en_d1), .q(D1_reg[1]));
    dff d_d1_2 (.D(pr[2]), .clk(clk), .rst(rst), .en(en_d1), .q(D1_reg[2]));
    dff d_d1_3 (.D(pr[3]), .clk(clk), .rst(rst), .en(en_d1), .q(D1_reg[3]));
    dff d_d1_4 (.D(pr[4]), .clk(clk), .rst(rst), .en(en_d1), .q(D1_reg[4]));
    dff d_d1_5 (.D(pr[5]), .clk(clk), .rst(rst), .en(en_d1), .q(D1_reg[5]));
    dff d_d1_6 (.D(pr[6]), .clk(clk), .rst(rst), .en(en_d1), .q(D1_reg[6]));
    dff d_d1_7 (.D(pr[7]), .clk(clk), .rst(rst), .en(en_d1), .q(D1_reg[7]));

    wire [7:0] N1_reg;

    dff d_n1_0 (.D(pr[0]), .clk(clk), .rst(rst), .en(en_n1), .q(N1_reg[0]));
    dff d_n1_1 (.D(pr[1]), .clk(clk), .rst(rst), .en(en_n1), .q(N1_reg[1]));
    dff d_n1_2 (.D(pr[2]), .clk(clk), .rst(rst), .en(en_n1), .q(N1_reg[2]));
    dff d_n1_3 (.D(pr[3]), .clk(clk), .rst(rst), .en(en_n1), .q(N1_reg[3]));
    dff d_n1_4 (.D(pr[4]), .clk(clk), .rst(rst), .en(en_n1), .q(N1_reg[4]));
    dff d_n1_5 (.D(pr[5]), .clk(clk), .rst(rst), .en(en_n1), .q(N1_reg[5]));
    dff d_n1_6 (.D(pr[6]), .clk(clk), .rst(rst), .en(en_n1), .q(N1_reg[6]));
    dff d_n1_7 (.D(pr[7]), .clk(clk), .rst(rst), .en(en_n1), .q(N1_reg[7]));

    wire [7:0] sub;
    wire [7:0] mo1;
    wire [7:0] mo2;

    mux3to1_8bit c_mux1 (
        .in0(shiftl),
        .in1(dividend),
        .in2(N1_reg),
        .sel(count),
        .out(mo1)
    );

    mux2to1_8bit c_mux2 (
        .in0(lo),
        .in1(sub),
        .sel(count[1]),
        .out(mo2)
    );

    wire [15:0] pro;
    wire final_cout; 

    multiplier_tree_only c3 (
        .a(mo1),
        .b(mo2),
        .product(pro),   
        .final_cout(final_cout) 
    );

    wire pr_cout_unused;
    
    fadder c_static_round (
        .A(pro[15:8]),
        .B(8'b00000000),
        .cin(pro[7]),
        .sum(pr),
        .cout(pr_cout_unused)
    );

    wire [7:0] nD1;
    not n_inst[7:0] (nD1, D1_reg); 

    wire sub_cout; 
    fadder c4 (
        .A(8'b10000000),      
        .B(nD1),
        .cin(1'b1),
        .sum(sub),             
        .cout(sub_cout) 
    );

    wire [7:0] sub1; 
    wire [2:0] no;
    not n2[2:0] (no, o);

    wire adder2_cout; 
    fadder c5 (
        .A(8'b00001100),       
        .B({5'b11111, no}),   
        .cin(1'b1),
        .sum(sub1),
        .cout(adder2_cout)     
    );

    
    wire [3:0] shift_pos;
    wire sub1_cout_unused;
    
    
    fadder_4bit c_sub_one (
        .A(sub1[3:0]),
        .B(4'b1111),
        .cin(1'b0),
        .sum(shift_pos),
        .cout(sub1_cout_unused)
    );

   
    wire [15:0] round_add;
    decoder_4to16 c_shift_dec (
        .in(shift_pos),
        .out(round_add)
    );

    
    wire [15:0] pro_rounded;
    wire round_carry;
    
    fadder c_rnd_low (
        .A(pro[7:0]),
        .B(round_add[7:0]),
        .cin(1'b0),
        .sum(pro_rounded[7:0]),
        .cout(round_carry)
    );

    fadder c_rnd_high (
        .A(pro[15:8]),
        .B(round_add[15:8]),
        .cin(round_carry),
        .sum(pro_rounded[15:8]),
        .cout()
    );

   
    wire [15:0] shift_out; 
    barshiftr c8 (
        .in(pro_rounded),      
        .q(shift_out),
        .o(sub1[3:0])          
    );

  
    assign quotient = shift_out[7:0];

endmodule 

module ha (
    input a,
    input b,
    output sum,
    output carry
);
    
    xor g1 (sum, a, b);
    and g2 (carry, a, b);
    
endmodule

module lut(
    input  [3:0] index,   
    output reg [7:0] X0   
);

    always @(*) begin
        case (index)
            4'd0:  X0 = 8'd126;

            4'd1:  X0 = 8'd119; 
            4'd2:  X0 = 8'd113; 

            4'd3:  X0 = 8'd108; 
            4'd4:  X0 = 8'd103;

            4'd5:  X0 = 8'd98;  
            4'd6:  X0 = 8'd94;  

            4'd7:  X0 = 8'd90; 

            4'd8:  X0 = 8'd86;  
            4'd9:  X0 = 8'd83;  

            4'd10: X0 = 8'd80; 
            4'd11: X0 = 8'd77; 

            4'd12: X0 = 8'd74;  
            4'd13: X0 = 8'd72;  

            4'd14: X0 = 8'd69;  
            4'd15: X0 = 8'd67;  
            default: X0 = 8'd126; 
        endcase
    end

endmodule

module mux2to1_8bit(
    input [7:0] in0, in1,
    input sel,
    output [7:0] out
);
    wire not_sel;
    wire [7:0] w0, w1;
    
    not (not_sel, sel);
    
    and a0[7:0] (w0, in0, {8{not_sel}});
    and a1[7:0] (w1, in1, {8{sel}});
    or  o0[7:0] (out, w0, w1);
endmodule

module mux3to1_8bit(
    input [7:0] in0, in1, in2,
    input [1:0] sel,
    output [7:0] out
);
    wire not_sel0, not_sel1;
    wire sel00, sel01;
    wire [7:0] w0, w1, w2;
    
    not (not_sel0, sel[0]);
    not (not_sel1, sel[1]);
    
    and (sel00, not_sel1, not_sel0); 
    and (sel01, not_sel1, sel[0]); 
  
    and a0[7:0] (w0, in0, {8{sel00}});
    and a1[7:0] (w1, in1, {8{sel01}});
    and a2[7:0] (w2, in2, {8{sel[1]}});
    
    or  o0[7:0] (out, w0, w1, w2);
endmodule

module multiplier_tree_only(
    input [7:0] a,
    input [7:0] b,
    output [15:0] product,   
    output final_cout 
);

    wire c0, c14;
    wire [1:0] c1, c13;
    wire [2:0] c2, c12;
    wire [3:0] c3, c11;
    wire [4:0] c4, c10;
    wire [5:0] c5, c9;
    wire [6:0] c6, c8;
    wire [7:0] c7;

    wire [15:0] final_sum;
    wire [15:0] final_carry;

    pr partial_gen (
        .a(a), .b(b),
        .c0(c0), .c1(c1), .c2(c2), .c3(c3), .c4(c4), .c5(c5), .c6(c6), .c7(c7),
        .c8(c8), .c9(c9), .c10(c10), .c11(c11), .c12(c12), .c13(c13), .c14(c14)
    );

   
    wire s1_1, c1_1;
    ha L1_c1 (.a(c1[0]), .b(c1[1]), .sum(s1_1), .carry(c1_1));

    wire s2_1, c2_1;
    fa L1_c2 (.a(c2[0]), .b(c2[1]), .cin(c2[2]), .sum(s2_1), .cout(c2_1));

    wire s3_1, c3_1a, c3_1b;
    com42 L1_c3 (.i1(c3[0]), .i2(c3[1]), .i3(c3[2]), .i4(c3[3]), .cin(1'b0), .sum(s3_1), .c1(c3_1a), .cout(c3_1b));

    wire s4_1, c4_1a, c4_1b;
    com52 L1_c4 (.i1(c4[0]), .i2(c4[1]), .i3(c4[2]), .i4(c4[3]), .i5(c4[4]), .sum(s4_1), .cout1(c4_1a), .cout2(c4_1b));

    wire s5_1a, s5_1b, c5_1a, c5_1b;
    com62 L1_c5 (.i1(c5[0]), .i2(c5[1]), .i3(c5[2]), .i4(c5[3]), .i5(c5[4]), .i6(c5[5]), .sum1(s5_1a), .sum2(s5_1b), .cout1(c5_1a), .cout2(c5_1b));

    wire s6_1a, s6_1b, c6_1a, c6_1b;
    com62 L1_c6 (.i1(c6[0]), .i2(c6[1]), .i3(c6[2]), .i4(c6[3]), .i5(c6[4]), .i6(c6[5]), .sum1(s6_1a), .sum2(s6_1b), .cout1(c6_1a), .cout2(c6_1b));
    
    wire s7_1, c7_1a, c7_1b, c7_1c, c7_1d;
    com82 L1_c7 (.i1(c7[0]), .i2(c7[1]), .i3(c7[2]), .i4(c7[3]), .i5(c7[4]), .i6(c7[5]), .i7(c7[6]), .i8(c7[7]), .cin42(1'b0), .sum(s7_1), .coutfa1(c7_1a), .coutfa2(c7_1b), .c142(c7_1c), .cout42(c7_1d));

    wire s8_1a, s8_1b, c8_1a, c8_1b;
    com62 L1_c8 (.i1(c8[0]), .i2(c8[1]), .i3(c8[2]), .i4(c8[3]), .i5(c8[4]), .i6(c8[5]), .sum1(s8_1a), .sum2(s8_1b), .cout1(c8_1a), .cout2(c8_1b));
    
    wire s9_1a, s9_1b, c9_1a, c9_1b;
    com62 L1_c9 (.i1(c9[0]), .i2(c9[1]), .i3(c9[2]), .i4(c9[3]), .i5(c9[4]), .i6(c9[5]), .sum1(s9_1a), .sum2(s9_1b), .cout1(c9_1a), .cout2(c9_1b));

    wire s10_1, c10_1a, c10_1b;
    com52 L1_c10 (.i1(c10[0]), .i2(c10[1]), .i3(c10[2]), .i4(c10[3]), .i5(c10[4]), .sum(s10_1), .cout1(c10_1a), .cout2(c10_1b));

    wire s11_1, c11_1a, c11_1b;
    com42 L1_c11 (.i1(c11[0]), .i2(c11[1]), .i3(c11[2]), .i4(c11[3]), .cin(1'b0), .sum(s11_1), .c1(c11_1a), .cout(c11_1b));

    wire s12_1, c12_1;
    fa L1_c12 (.a(c12[0]), .b(c12[1]), .cin(c12[2]), .sum(s12_1), .cout(c12_1));

    wire s13_1, c13_1;
    ha L1_c13 (.a(c13[0]), .b(c13[1]), .sum(s13_1), .carry(c13_1));

   
    wire s4_2, c4_2;
    fa L2_c4 (.a(s4_1), .b(c3_1a), .cin(c3_1b), .sum(s4_2), .cout(c4_2));

    wire s5_2, c5_2a, c5_2b;
    com42 L2_c5 (.i1(s5_1a), .i2(s5_1b), .i3(c4_1a), .i4(c4_1b), .cin(1'b0), .sum(s5_2), .c1(c5_2a), .cout(c5_2b));

    wire s6_2, c6_2a, c6_2b;
    com52 L2_c6 (.i1(s6_1a), .i2(s6_1b), .i3(c6[6]), .i4(c5_1a), .i5(c5_1b), .sum(s6_2), .cout1(c6_2a), .cout2(c6_2b));

    wire s7_2, c7_2;
    fa L2_c7 (.a(s7_1), .b(c6_1a), .cin(c6_1b), .sum(s7_2), .cout(c7_2));

    wire s8_2a, s8_2b, c8_2a, c8_2b;
    com62 L2_c8 (.i1(s8_1a), .i2(s8_1b), .i3(c8[6]), .i4(c7_1a), .i5(c7_1b), .i6(c7_1c), .sum1(s8_2a), .sum2(s8_2b), .cout1(c8_2a), .cout2(c8_2b));

    wire s9_2, c9_2a, c9_2b;
    com42 L2_c9 (.i1(s9_1a), .i2(s9_1b), .i3(c8_1a), .i4(c8_1b), .cin(1'b0), .sum(s9_2), .c1(c9_2a), .cout(c9_2b));

    wire s10_2, c10_2;
    fa L2_c10 (.a(s10_1), .b(c9_1a), .cin(c9_1b), .sum(s10_2), .cout(c10_2));

    wire s11_2, c11_2;
    fa L2_c11 (.a(s11_1), .b(c10_1a), .cin(c10_1b), .sum(s11_2), .cout(c11_2));

    wire s12_2, c12_2;
    fa L2_c12 (.a(s12_1), .b(c11_1a), .cin(c11_1b), .sum(s12_2), .cout(c12_2));

   
    wire s6_3, c6_3;
    fa L3_c6 (.a(s6_2), .b(c5_2a), .cin(c5_2b), .sum(s6_3), .cout(c6_3));

    wire s7_3, c7_3;
    fa L3_c7 (.a(s7_2), .b(c6_2a), .cin(c6_2b), .sum(s7_3), .cout(c7_3));

    wire s8_3, c8_3a, c8_3b;
    com42 L3_c8 (.i1(s8_2a), .i2(s8_2b), .i3(c7_1d), .i4(c7_2), .cin(1'b0), .sum(s8_3), .c1(c8_3a), .cout(c8_3b));

    wire s9_3, c9_3;
    fa L3_c9 (.a(s9_2), .b(c8_2a), .cin(c8_2b), .sum(s9_3), .cout(c9_3));

    wire s10_3, c10_3;
    fa L3_c10 (.a(s10_2), .b(c9_2a), .cin(c9_2b), .sum(s10_3), .cout(c10_3));

    wire s11_3, c11_3;
    fa L3_c11 (.a(s11_2), .b(c10_2), .cin(c10_3), .sum(s11_3), .cout(c11_3));

    wire s12_3, c12_3;
    fa L3_c12 (.a(s12_2), .b(c11_2), .cin(c11_3), .sum(s12_3), .cout(c12_3));

    wire s13_2, c13_2;
    fa L3_c13 (.a(s13_1), .b(c12_1), .cin(c12_2), .sum(s13_2), .cout(c13_2));

    wire s9_4, c9_4;
    fa L4_c9 (.a(s9_3), .b(c8_3a), .cin(c8_3b), .sum(s9_4), .cout(c9_4));

    wire s10_4, c10_4;
    fa L4_c10 (.a(s10_3), .b(c9_3), .cin(c9_4), .sum(s10_4), .cout(c10_4));

    wire s14_1, c14_1;
    fa L4_c14 (.a(c14), .b(c13_1), .cin(c13_2), .sum(s14_1), .cout(c14_1));

  
    assign final_sum[0]  = c0;
    assign final_sum[1]  = s1_1;
    assign final_sum[2]  = s2_1;
    assign final_sum[3]  = s3_1;
    assign final_sum[4]  = s4_2;
    assign final_sum[5]  = s5_2;
    assign final_sum[6]  = s6_3;
    assign final_sum[7]  = s7_3;
    assign final_sum[8]  = s8_3;
    assign final_sum[9]  = s9_4;
    assign final_sum[10] = s10_4; 
    assign final_sum[11] = s11_3; 
    assign final_sum[12] = s12_3; 
    assign final_sum[13] = s13_2; 
    assign final_sum[14] = s14_1; 
    assign final_sum[15] = 1'b0;

    assign final_carry[0]  = 1'b0; 
    assign final_carry[1]  = 1'b0; 
    assign final_carry[2]  = c1_1;
    assign final_carry[3]  = c2_1;
    assign final_carry[4]  = 1'b0;  
    assign final_carry[5]  = c4_2;
    assign final_carry[6]  = 1'b0;  
    assign final_carry[7]  = c6_3;
    assign final_carry[8]  = c7_3;
    assign final_carry[9]  = 1'b0;   
    assign final_carry[10] = 1'b0;
    assign final_carry[11] = c10_4;
    assign final_carry[12] = 1'b0;
    assign final_carry[13] = c12_3;
    assign final_carry[14] = 1'b0;
    assign final_carry[15] = c14_1;

    
    cla_adder_16bit final_adder_inst (
        .a(final_sum),
        .b(final_carry),
        .cin(1'b0),
        .sum(product),
        .cout(final_cout)
    );

endmodule

module mux1(
    input a,b,sel,
    output q
);

wire c,d,selb;
not(selb,sel);
and(c,selb,a);
and(d,sel,b);
or(q,c,d);
endmodule

module mux8(
    input [7:0] a,
    input [7:0] b,
    input sel,
    output [7:0] q
);

mux1 m0(
.a(a[0]),
.b(b[0]),
.sel(sel),
.q(q[0])
);
mux1 m1(
.a(a[1]),
.b(b[1]),
.sel(sel),
.q(q[1])
);
mux1 m2(
.a(a[2]),
.b(b[2]),
.sel(sel),
.q(q[2])
);
mux1 m3(
.a(a[3]),
.b(b[3]),
.sel(sel),
.q(q[3])
);

mux1 m4(
.a(a[4]),
.b(b[4]),
.sel(sel),
.q(q[4])
);

mux1 m5(
.a(a[5]),
.b(b[5]),
.sel(sel),
.q(q[5])
);

mux1 m6(
.a(a[6]),
.b(b[6]),
.sel(sel),
.q(q[6])
);
mux1 m7(
.a(a[7]),
.b(b[7]),
.sel(sel),
.q(q[7])
);

endmodule

module pr(
    input [7:0] a, b,
    output c0, c14,
    output [1:0] c1, c13,
    output [2:0] c2, c12,
    output [3:0] c3, c11,
    output [4:0] c4, c10,
    output [5:0] c5, c9,
    output [6:0] c6, c8,
    output [7:0] c7
);

    wire [7:0] r0, r1, r2, r3, r4, r5, r6, r7;

   
    assign r0 = a & {8{b[0]}};
    assign r1 = a & {8{b[1]}};
    assign r2 = a & {8{b[2]}};
    assign r3 = a & {8{b[3]}};
    assign r4 = a & {8{b[4]}};
    assign r5 = a & {8{b[5]}};
    assign r6 = a & {8{b[6]}};
    assign r7 = a & {8{b[7]}};

   
    assign c0 = r0[0];
    assign c1 = {r0[1], r1[0]};
    assign c2 = {r0[2], r1[1], r2[0]};
    assign c3 = {r0[3], r1[2], r2[1], r3[0]};
    assign c4 = {r0[4], r1[3], r2[2], r3[1], r4[0]};
    assign c5 = {r0[5], r1[4], r2[3], r3[2], r4[1], r5[0]};
    assign c6 = {r0[6], r1[5], r2[4], r3[3], r4[2], r5[1], r6[0]};

    assign c7 = {r0[7], r1[6], r2[5], r3[4], r4[3], r5[2], r6[1], r7[0]};

    
    assign c8  = {r1[7], r2[6], r3[5], r4[4], r5[3], r6[2], r7[1]};
    assign c9  = {r2[7], r3[6], r4[5], r5[4], r6[3], r7[2]};
    assign c10 = {r3[7], r4[6], r5[5], r6[4], r7[3]};
    assign c11 = {r4[7], r5[6], r6[5], r7[4]};
    assign c12 = {r5[7], r6[6], r7[5]};
    assign c13 = {r6[7], r7[6]};
    assign c14 = r7[7];

endmodule
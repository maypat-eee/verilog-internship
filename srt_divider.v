module srt(
    input [7:0] divisor,
    input [7:0] dividend, 
    input load, rst,
    input clk,
    output [7:0] Qu,
    output [7:0] R,
    output e
);

    wire u,y,i,f;

    byp b5(
        .h1(dividend),
        .h2(divisor),
        .h3(u),
        .h4(y)
    );

    wire [7:0] D;
    wire [2:0] o;
    wire [7:0] c, m;
    wire qn, qp;
    wire [7:0] q;
    wire [7:0] cqp, cqn;
    wire [15:0] shifted_div;
    wire [7:0] w_R;
    wire [7:0] w_Qu;
    wire en, x2, x1;
    wire [7:0] raw_R;
    wire [7:0] raw_Qu;

    barshiftd b1 (.in(divisor), .q(D), .o(o));
    barshiftQ10 b2 (.in({8'b00000000, dividend}), .q(shifted_div), .o(o));

    wire d_z1, d_z2, d_z3, d_z4, d_z5, d_z6;
    or(d_z1, divisor[0], divisor[1]);
    or(d_z2, divisor[2], divisor[3]);
    or(d_z3, divisor[4], divisor[5]);
    or(d_z4, divisor[6], divisor[7]);
    or(d_z5, d_z1, d_z2);
    or(d_z6, d_z3, d_z4);
    
    nor(e, d_z5, d_z6); 

    wire run_en, done;
    autostop_ctrl auto_ctrl (
        .clk(clk),
        .rst(rst),
        .load(load),
        .div_zero_e(e),
        .run_en(run_en),
        .done(done)
    );
  
    wire [8:0] pr;

    assign pr = {q[7], q[6], q[5], q[4], q[3], q[2], q[1], q[0], c[7]};

    wire dummy_qsl_q; 
    qsl q1 (.p(pr), .qn(qn), .qp(qp), .q(dummy_qsl_q));
    
    alu alu1 (
        .pin(pr[7:0]), 
        .B(D), 
        .qp(qp), 
        .qn(qn), 
        .sum(m)
    );

    shift5 sq (
        .pin(shifted_div[7:0]), 
        .in(1'b0),
        .rst(rst),
        .load(load),
        .Q(c),
        .clk(clk),
        .en(run_en)
    );

    shift5 sqp (
        .pin(8'b00000000),
        .in(qp),
        .rst(rst),
        .load(load),
        .Q(cqp),
        .clk(clk),
        .en(run_en)
    );

    shift5 sqn (
        .pin(8'b00000000),
        .in(qn),
        .rst(rst),
        .load(load),
        .Q(cqn),
        .clk(clk),
        .en(run_en)
    );

    wire [7:0] cnqn;
    not n[7:0] (cnqn, cqn);

    wire dummy_f1_cout; 
    fadder f1 (.A(cqp), .B(cnqn), .cin(1'b1), .sum(raw_Qu), .cout(dummy_f1_cout));

    wire [7:0] q_next;
    mux8 q_mux(.a(m), .b(shifted_div[15:8]), .sel(load), .q(q_next));

    wire [7:0] dummy_qb_q;
    dff d0 (.D(q_next[0]), .clk(clk), .rst(rst), .q(q[0]), .qb(dummy_qb_q[0]), .en(run_en));
    dff d1 (.D(q_next[1]), .clk(clk), .rst(rst), .q(q[1]), .qb(dummy_qb_q[1]), .en(run_en));
    dff d2 (.D(q_next[2]), .clk(clk), .rst(rst), .q(q[2]), .qb(dummy_qb_q[2]), .en(run_en));
    dff d3 (.D(q_next[3]), .clk(clk), .rst(rst), .q(q[3]), .qb(dummy_qb_q[3]), .en(run_en));
    dff d4 (.D(q_next[4]), .clk(clk), .rst(rst), .q(q[4]), .qb(dummy_qb_q[4]), .en(run_en));
    dff d5 (.D(q_next[5]), .clk(clk), .rst(rst), .q(q[5]), .qb(dummy_qb_q[5]), .en(run_en));
    dff d6 (.D(q_next[6]), .clk(clk), .rst(rst), .q(q[6]), .qb(dummy_qb_q[6]), .en(run_en));
    dff d7 (.D(q_next[7]), .clk(clk), .rst(rst), .q(q[7]), .qb(dummy_qb_q[7]), .en(run_en));

    barshiftr r1 (.in(q), .q(raw_R), .o(o));
      
    corr corr_step (
        .R(raw_R), 
        .divisor(divisor), 
        .Qu(raw_Qu), 
        .True_R(w_R),   
        .True_Qu(w_Qu)  
    );

    not(f, u);
    and(i, f, y);
    
    wire [7:0] Qu1, Qu2, Qu3;
    mux8 q_mux6(.a(w_Qu), .b(8'b00000000), .sel(e), .q(Qu3));
    mux8 q_mux1(.a(Qu3), .b(8'b00000001), .sel(u), .q(Qu1));
    mux8 r_mux1(.a(8'b00000000), .b(w_R), .sel(i), .q(R));
    mux8 r1_mux(.a(8'b00000000), .b(Qu1), .sel(y), .q(Qu));

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

module alu(
    input [7:0]pin,
    input [7:0]B,
    input qp, qn,
    output [7:0]sum
);

    wire [7:0] a, b, c, d;

    wire sel,nqn;
    not(nqn,qn);
    or(sel,nqn,qp);
    not n[7:0] (b, B);

    and a_gate[7:0] (a, B, qn);
    and c_gate[7:0] (c, b, qp);
    or d_gate[7:0] (d, a, c);

    wire dummy_cout_alu; 
    fadder sub(
        .A(d),
        .B(pin),
        .cin(qp),
        .sum(sum),
        .cout(dummy_cout_alu) 
    );

endmodule

module barshiftr(
    input  [7:0] in,
    output [7:0] q,
    input  [2:0] o
);

wire [7:0] j1,j;
    wire [7:0] sh1;
    wire [7:0] sh2,sh4;
    
 assign sh1 = {in[7], in[7:1]};
    assign sh2 = {j[7], j[7], j[7:2]};
    assign sh4={j1[7], j1[7],j1[7],j1[7] ,j1[7:4]};
   
        mux8 m1(
        .a(in),
        .b(sh1),
        .sel(o[0]),
        .q(j)
    );
    
    mux8 m2(
        .a(j),
        .b(sh2),
        .sel(o[1]),
        .q(j1)
    );

     mux8 m4(
        .a(j1),
        .b(sh4),
        .sel(o[2]),
        .q(q)
    );
endmodule

module autostop_ctrl(
    input clk,
    input rst,
    input load,
    input div_zero_e,  
    output run_en,     
    output done        
);

    wire is_zero;
    wire [2:0] count;
    wire busy_d, busy_q, busy_next;
    wire not_is_zero, not_e;

    wire cnt_en;
    or (cnt_en, busy_q, load);

  cnt3_gate counter (
        .clk(clk),
        .rst(rst),
        .load(load),
        .en(cnt_en),    
        .count(count),
        .is_zero(is_zero)
    );
   
    not (not_is_zero, is_zero);
    wire hold_busy;
    and (hold_busy, busy_q, not_is_zero);
    or  (busy_d, load, hold_busy);
   
    wire dummy_qb_busy; 
    dff busy_ff (
        .D(busy_d),
        .clk(clk),
        .rst(rst),
        .q(busy_q),
        .qb(dummy_qb_busy),
        .en(1'b1)
    );
    
    not (not_e, div_zero_e);
    wire active;
    or  (active, busy_q, load);
    and (run_en, active, not_e);
   
    and (done, is_zero, busy_q);

endmodule

module barshiftd(
    input  [7:0] in,
    output [7:0] q,
    output [2:0] o
);
    wire a, b, c;
    wire [7:0] sh1, sh2, j,j1,sh4;
    wire [7:0]notin;
assign o[2] = ~in[6] & ~in[5] & ~in[4] & ~in[3];
assign o[1] = (~in[6] & ~in[5] & (in[4] | in[3])) | 
                  (~in[6] & ~in[5] & ~in[4] & ~in[3] & ~in[2] & ~in[1]);

assign o[0] = (~in[6] & in[5]) | 
                  (~in[6] & ~in[5] & ~in[4] & in[3]) | 
                  (~in[6] & ~in[5] & ~in[4] & ~in[3] & ~in[2] & in[1]) | 
                  (~in[6] & ~in[5] & ~in[4] & ~in[3] & ~in[2] & ~in[1] & ~in[0]);

    assign sh1 = {in[7],in[5:0],1'b0};
    assign sh2 = {j[7], j[4:0], 2'b00};
assign sh4 = {j1[7], j1[2:0], 4'b0000};
    
    mux8 m1(
        .a(in),
        .b(sh1),
        .sel(o[0]),
        .q(j)
    );
    
    mux8 m2(
        .a(j),
        .b(sh2),
        .sel(o[1]),
        .q(j1)
    );

     mux8 m4(
        .a(j1),
        .b(sh4),
        .sel(o[2]),
        .q(q)
    );

endmodule

module barshiftQ10(
    input  [15:0] in,
    output [15:0] q,
    input  [2:0] o
);
    wire [15:0] j, j1,sh4,sh1, sh2;

    assign sh1 = {in[14:0], 1'b0}; 
    assign sh2 = {j[13:0],  2'b00};
    assign sh4 = {j1[11:0],  4'b0000};
   
    mux8 m1_top(.a(in[15:8]), .b(sh1[15:8]), .sel(o[0]), .q(j[15:8]));
    mux8 m1_bot(.a(in[7:0]), .b(sh1[7:0]), .sel(o[0]), .q(j[7:0]));

    mux8 m2_top(.a(j[15:8]), .b(sh2[15:8]), .sel(o[1]), .q(j1[15:8]));
    mux8 m2_bot(.a(j[7:0]), .b(sh2[7:0]), .sel(o[1]), .q(j1[7:0]));
    
    mux8 m4_top(.a(j1[15:8]), .b(sh4[15:8]), .sel(o[2]), .q(q[15:8]));
    mux8 m4_bot(.a(j1[7:0]), .b(sh4[7:0]), .sel(o[2]), .q(q[7:0]));

endmodule

module byp(
input [7:0]h1,h2,
output h3,h4
);
wire a0,a1,a2,a3,a4,a5,a6,a7,g1,g2,g3,g4,g5,g6;
wire b0, b2, b3, b4, c1, c2;
xnor(a0,h1[0],h2[0]);
xnor(a1,h1[1],h2[1]);
xnor(a2,h1[2],h2[2]);
xnor(a3,h1[3],h2[3]);
xnor(a4,h1[4],h2[4]);
xnor(a5,h1[5],h2[5]);
xnor(a6,h1[6],h2[6]);
xnor(a7,h1[7],h2[7]);

and(g1,a0,a1);
and(g2,a2,a3);
and(g3,a5,a4);
and(g4,a7,a6);

and(g5,g1,g2);
and(g6,g4,g3);
and(h3,g5,g6);

or(b0,h1[0],h1[1]);
or(b2,h1[7],h1[2]);
or(b3,h1[5],h1[3]);
or(b4,h1[6],h1[4]);

or(c1,b0,b2);
or(c2,b3,b4);
or(h4,c1,c2);

endmodule 

module cnt3_gate(
    input clk,
    input rst,
    input load,
    input en,
    output [2:0] count,
    output is_zero
);
    wire [2:0] q, d, q_bar;
    wire c0_next, c1_next, c2_next;
    wire load_n, rst_or_load;
    
    // MISSING WIRES DECLARED HERE
    wire d0_next, d1_next, d2_next; 

    not (q_bar[0], q[0]);
    not (q_bar[1], q[1]);
    not (q_bar[2], q[2]);

    assign d0_next = q_bar[0];
    xor (d1_next, q[1], q_bar[0]);
    
    wire dec2_en;
    and (dec2_en, q_bar[0], q_bar[1]);
    xor (d2_next, q[2], dec2_en);

    wire [2:0] next_count;
    not (load_n, load);
    
    or (next_count[0], load, d0_next);
    or (next_count[1], load, d1_next);
    or (next_count[2], load, d2_next);

    wire [2:0] dummy_qb_cnt; 
    dff d_cnt0 (.D(next_count[0]), .clk(clk), .rst(rst), .q(q[0]), .qb(dummy_qb_cnt[0]), .en(en));
    dff d_cnt1 (.D(next_count[1]), .clk(clk), .rst(rst), .q(q[1]), .qb(dummy_qb_cnt[1]), .en(en));
    dff d_cnt2 (.D(next_count[2]), .clk(clk), .rst(rst), .q(q[2]), .qb(dummy_qb_cnt[2]), .en(en));

    assign count = q;
    nor (is_zero, q[0], q[1], q[2]);

endmodule

module corr(
    input [7:0] R,
    input [7:0] divisor,
    input [7:0] Qu,
    output [7:0] True_R,
    output [7:0] True_Qu
);
    wire sign;
    assign sign = R[7];

    wire [7:0] gated_divisor;
    and a[7:0](gated_divisor, divisor, sign);

    wire dummy_cout_r; 
    fadder add_r ( .A(R), .B(gated_divisor), .cin(1'b0), .sum(True_R), .cout(dummy_cout_r) );
   
    wire [7:0] gated_offset;
    and a4[7:0](gated_offset, 1'b1, sign);
    
    wire dummy_cout_q; 
    fadder add_q ( .A(Qu), .B(gated_offset), .cin(1'b0), .sum(True_Qu), .cout(dummy_cout_q) );

endmodule 

module dff(
    input D, clk, rst, en,
    output reg q,
    output qb
);
    
    assign qb = ~q;
    
    always @(posedge clk or posedge rst) begin
        if (rst)
            q <= 1'b0;
        else if (en)
            q <= D;
    end

endmodule

module fadder(
input [7:0]A,
input [7:0]B,
input cin,
output [7:0]sum,
output cout
);
wire c1,c2,c3,c4,c5,c6,c7;
adder a0( .A(A[0]), .B(B[0]), .cin(cin), .sum(sum[0]), .cout(c1) );
adder a1( .A(A[1]), .B(B[1]), .cin(c1),  .sum(sum[1]), .cout(c2) );
adder a2( .A(A[2]), .B(B[2]), .cin(c2),  .sum(sum[2]), .cout(c3) );
adder a3( .A(A[3]), .B(B[3]), .cin(c3),  .sum(sum[3]), .cout(c4) );
adder a4( .A(A[4]), .B(B[4]), .cin(c4),  .sum(sum[4]), .cout(c5) );
adder a5( .A(A[5]), .B(B[5]), .cin(c5),  .sum(sum[5]), .cout(c6) );
adder a6( .A(A[6]), .B(B[6]), .cin(c6),  .sum(sum[6]), .cout(c7) );
adder a7( .A(A[7]), .B(B[7]), .cin(c7),  .sum(sum[7]), .cout(cout) );

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
mux1 m0(.a(a[0]), .b(b[0]), .sel(sel), .q(q[0]));
mux1 m1(.a(a[1]), .b(b[1]), .sel(sel), .q(q[1]));
mux1 m2(.a(a[2]), .b(b[2]), .sel(sel), .q(q[2]));
mux1 m3(.a(a[3]), .b(b[3]), .sel(sel), .q(q[3]));
mux1 m4(.a(a[4]), .b(b[4]), .sel(sel), .q(q[4]));
mux1 m5(.a(a[5]), .b(b[5]), .sel(sel), .q(q[5]));
mux1 m6(.a(a[6]), .b(b[6]), .sel(sel), .q(q[6]));
mux1 m7(.a(a[7]), .b(b[7]), .sel(sel), .q(q[7]));
endmodule

module qsl(
    input [8:0] p,
    output qn, qp, q
);
    wire c1, c2, c3;
    or(c1, p[7], p[6]);
    not(c2, p[8]);
    and(qp, c2, c1);
    nand(c3, p[7], p[6]);
    and(qn, p[8], c3);
    or(q, qp, qn);
endmodule

module shift5(
    input [7:0] pin,
    input clk,en,
    input in,
    input rst,
    output [7:0] Q,
    input load
);
    wire [7:0]mo;
wire   [7:0]qshift;

assign qshift={Q[6],Q[5],Q[4],Q[3],Q[2],Q[1],Q[0],in};
mux8 m1(.a(qshift), .b(pin), .sel(load) , .q(mo));

    wire [7:0] dummy_qb_shift; 
    dff d0 ( .D(mo[0]), .clk(clk), .rst(rst), .q(Q[0]), .qb(dummy_qb_shift[0]), .en(en) );
    dff d1 ( .D(mo[1]), .clk(clk), .rst(rst), .q(Q[1]), .qb(dummy_qb_shift[1]), .en(en) );
    dff d2 ( .D(mo[2]), .clk(clk), .rst(rst), .q(Q[2]), .qb(dummy_qb_shift[2]), .en(en) );
    dff d3 ( .D(mo[3]), .clk(clk), .rst(rst), .q(Q[3]), .qb(dummy_qb_shift[3]), .en(en) );
    dff d4 ( .D(mo[4]), .clk(clk), .rst(rst), .q(Q[4]), .qb(dummy_qb_shift[4]), .en(en) );
    dff d5 ( .D(mo[5]), .clk(clk), .rst(rst), .q(Q[5]), .qb(dummy_qb_shift[5]), .en(en) );
    dff d6 ( .D(mo[6]), .clk(clk), .rst(rst), .q(Q[6]), .qb(dummy_qb_shift[6]), .en(en) );
    dff d7 ( .D(mo[7]), .clk(clk), .rst(rst), .q(Q[7]), .qb(dummy_qb_shift[7]), .en(en) );

endmodule
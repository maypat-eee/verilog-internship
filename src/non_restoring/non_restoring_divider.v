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
    input [7:0]B,pin,
        input en ,clk,rst,
    output [7:0]sum,
    output cout
);
wire [7:0]nb,c;
wire ncin,cin,ncout;
not n[7:0](nb,B);
not(ncout,cout);
    dff d0 (.D(ncout), .clk(clk), .rst(rst), .q(ncin), .en(en));
    not(cin,ncin);
    mux8 q_mux(.a(nb), .b(B), .sel(ncin), .q(c));
    fadder h1(
        .A(pin),
        .B(c),
        .cin(cin),
        .sum(sum),
        .cout(cout)
    );   

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

module corr(
    input [7:0] R,
    input [7:0] divisor,
    input [7:0] Qu,
    output [7:0] True_R,
    output [7:0] True_Qu
);
    wire sign;
    assign sign = R[7]; 
   
    wire [8:0] extended_divisor;
    assign extended_divisor = {1'b0, divisor}; 

   
    wire [8:0] gated_divisor;
    assign gated_divisor = {9{sign}} & extended_divisor;

    
    wire [8:0] extended_R;
    assign extended_R = {1'b0, R};

    
    wire [8:0] corrected_sum;
    fadder_9bit add_r_9bit ( 
        .A(extended_R), 
        .B(gated_divisor), 
        .cin(1'b0), 
        .sum(corrected_sum) 
    );

    
    assign True_R = corrected_sum[7:0];

    
    assign True_Qu = Qu;

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

module NON(
    input [7:0] divisor,
    input [7:0] dividend, 
    input load, 
    input rst,
    input clk,
    output [7:0] Qu,
    output [7:0] R,
    output e,
    output valid      
);

    wire u, y, i, f;

    wire [3:0] count;
    wire timer_rst;
    wire timer_en;
    wire not_c2, not_c1, not_c0;

   
    or r_timer (timer_rst, rst, load);

    not (not_c2, count[2]);
    not (not_c1, count[1]);
    not (not_c0, count[0]);
    and (valid, count[3], not_c2, not_c1, not_c0);

    not (timer_en, valid);

    counter_4bit c_timer (
        .clk(clk),
        .rst(timer_rst),
        .en(timer_en),
        .count(count)
    );

    
    byp b5(
        .h1(dividend),
        .h2(divisor),
        .h3(u),
        .h4(y)
    );

    wire [7:0] D;
    wire [2:0] o;
    wire [7:0] c, m;
    wire [7:0] q;
    wire [7:0] pr;
    wire [7:0] w_R;
    wire [7:0] w_Qu;
    wire en, x2, x1;
    wire [7:0] raw_R;
    wire [7:0] raw_Qu;

    wire d_z1, d_z2, d_z3, d_z4, d_z5, d_z6;
    or(d_z1, divisor[0], divisor[1]);
    or(d_z2, divisor[2], divisor[3]);
    or(d_z3, divisor[4], divisor[5]);
    or(d_z4, divisor[6], divisor[7]);
    or(d_z5, d_z1, d_z2);
    or(d_z6, d_z3, d_z4);
    
    nor(e, d_z5, d_z6); 

 
    wire not_e, not_valid;
    not (not_e, e);
    not (not_valid, valid);
 
    and (en, not_e, not_valid);

    
    assign pr = {q[6:0], c[7]};
    wire cout;
    
    shift5 sq (
        .pin(dividend), 
        .in(cout),
        .rst(rst),
        .load(load),
        .Q(c),
        .clk(clk),
        .en(en)        
    );

    wire [7:0] q_next;
    alu h2(
        .B(divisor),
        .pin(pr),
        .en(en),
        .clk(clk),
        .rst(rst),
        .sum(q_next),
        .cout(cout)
    );

    dff d0 (.D(q_next[0]), .clk(clk), .rst(rst), .q(q[0]), .en(en));
    dff d1 (.D(q_next[1]), .clk(clk), .rst(rst), .q(q[1]), .en(en));
    dff d2 (.D(q_next[2]), .clk(clk), .rst(rst), .q(q[2]), .en(en));
    dff d3 (.D(q_next[3]), .clk(clk), .rst(rst), .q(q[3]), .en(en));
    dff d4 (.D(q_next[4]), .clk(clk), .rst(rst), .q(q[4]), .en(en));
    dff d5 (.D(q_next[5]), .clk(clk), .rst(rst), .q(q[5]), .en(en));
    dff d6 (.D(q_next[6]), .clk(clk), .rst(rst), .q(q[6]), .en(en));
    dff d7 (.D(q_next[7]), .clk(clk), .rst(rst), .q(q[7]), .en(en));

    corr corr_step (
        .R(q), 
        .divisor(divisor), 
        .Qu(c), 
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


module counter_4bit(
    input clk, rst, en,
    output [3:0] count
);
    wire [3:0] next_count;
    wire c0, c1, c2;

    xor (next_count[0], count[0], en);
    and (c0, count[0], en);

    xor (next_count[1], count[1], c0);
    and (c1, count[1], c0);

    xor (next_count[2], count[2], c1);
    and (c2, count[2], c1);

    xor (next_count[3], count[3], c2);

    
    dff ff0 (.D(next_count[0]), .clk(clk), .rst(rst), .q(count[0]), .en(en));
    dff ff1 (.D(next_count[1]), .clk(clk), .rst(rst), .q(count[1]), .en(en));
    dff ff2 (.D(next_count[2]), .clk(clk), .rst(rst), .q(count[2]), .en(en));
    dff ff3 (.D(next_count[3]), .clk(clk), .rst(rst), .q(count[3]), .en(en));
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

module fadder_9bit (
    input [8:0] A,
    input [8:0] B,
    input cin,
    output [8:0] sum,
    output cout
);
    wire c0, c1, c2, c3, c4, c5, c6, c7;

  
    fa bit0 (.a(A[0]), .b(B[0]), .cin(cin),  .sum(sum[0]), .cout(c0));
    fa bit1 (.a(A[1]), .b(B[1]), .cin(c0),   .sum(sum[1]), .cout(c1));
    fa bit2 (.a(A[2]), .b(B[2]), .cin(c1),   .sum(sum[2]), .cout(c2));
    fa bit3 (.a(A[3]), .b(B[3]), .cin(c2),   .sum(sum[3]), .cout(c3));
    fa bit4 (.a(A[4]), .b(B[4]), .cin(c3),   .sum(sum[4]), .cout(c4));
    fa bit5 (.a(A[5]), .b(B[5]), .cin(c4),   .sum(sum[5]), .cout(c5));
    fa bit6 (.a(A[6]), .b(B[6]), .cin(c5),   .sum(sum[6]), .cout(c6));
    fa bit7 (.a(A[7]), .b(B[7]), .cin(c6),   .sum(sum[7]), .cout(c7));
    fa bit8 (.a(A[8]), .b(B[8]), .cin(c7),   .sum(sum[8]), .cout(cout));

endmodule


module fa (
    input a, b, cin,
    output sum, cout
);
    wire w1, w2, w3;
    xor (w1, a, b);
    xor (sum, w1, cin);
    and (w2, a, b);
    and (w3, w1, cin);
    or  (cout, w2, w3);
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

    dff d0 ( .D(mo[0]), .clk(clk), .rst(rst), .q(Q[0]) ,.en(en) );
    dff d1 ( .D(mo[1]), .clk(clk), .rst(rst), .q(Q[1]) ,.en(en));
    dff d2 ( .D(mo[2]), .clk(clk), .rst(rst), .q(Q[2]) ,.en(en));
    dff d3 ( .D(mo[3]), .clk(clk), .rst(rst), .q(Q[3]) ,.en(en));
    dff d4 ( .D(mo[4]), .clk(clk), .rst(rst), .q(Q[4]) ,.en(en));
    dff d5 ( .D(mo[5]), .clk(clk), .rst(rst), .q(Q[5]) ,.en(en));
    dff d6 ( .D(mo[6]), .clk(clk), .rst(rst), .q(Q[6]) ,.en(en));
    dff d7 ( .D(mo[7]), .clk(clk), .rst(rst), .q(Q[7]) ,.en(en));

endmodule

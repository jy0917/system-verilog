`timescale 1ns / 1ps

//logic 처리

module adder (
    input logic [7:0] a,
    input logic [7:0] b,
    input logic mode,
    output logic [7:0] s,
    output logic c
);
    //mode가 1 일때 substractor, 0 일때 adder
    assign {c, s} = {mode} ? a - b : a + b;
    
endmodule

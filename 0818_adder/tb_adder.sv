`timescale 1ns / 1ps
// interface : to connect of object with module. module with module
interface adder_interface;
    logic [7:0] a;
    logic [7:0] b;
    logic    mode;
    logic [7:0] s;
    logic c;
endinterface

// stimulus for generate variable object
// 데이터를 운반하는 역할
class transaction;
    // 2 state : bit
    // s와 c는 rand 하지 않아도 되지만 monitor에서 수집
    rand bit [7:0] a;
    rand bit [7:0] b;
    rand bit       mode;
    logic    [7:0] s;
    logic          c;

    // constraint in_range {
    //     a > 128;
    //     b > 250;
    // }
    // constraint in_ranege {a inside {[1 : 127]};}
    // constraint mode_distribute {
    //     if (mode == 0)
    //     b inside {0, 1, 2, 3, 15, 20, 127};
    //     else
    //     b > 128;
    // }
    constraint mode_dist2 {
        mode dist {
            0 :/ 90,
            1 :/ 10
        };
    }
    function void debug_print(string name);
        $display("%t : [%s] a=%d, b=%d, mode=%d, s=%d, c=%d", $time, name, a,
                 b, mode, s, c);
    endfunction
endclass

// Sequencer : rand값을 생성하고 drive
class generator;
    // transaction을 위한 handler (객체의 메모리에 의한 주소값)
    // tr은 초기화 상태
    transaction tr;
    mailbox #(transaction) gen2drv_mbox;

    function new(mailbox#(transaction) gen2drv_mbox);
        this.gen2drv_mbox = gen2drv_mbox;
    endfunction

    task run();
        tr = new;
        // randomize for tr
        // tr => rand keyword 지시받은 모두 random 값을 생성한다.
        tr.randomize();
        gen2drv_mbox.put(tr);
        // $display("%t : gen tr.a = %d, tr.b = %d, tr.mode = %d", $time, tr.a,
        //          tr.b, tr.mode);
        tr.debug_print("GEN");
    endtask

endclass

class driver;
    transaction tr;  // druver's tr
    mailbox #(transaction) gen2drv_mbox;
    virtual adder_interface adder_vif;

    function new(mailbox#(transaction) gen2drv_mbox,
                 virtual adder_interface adder_vif);
        this.gen2drv_mbox = gen2drv_mbox;
        this.adder_vif = adder_vif;
    endfunction

    task run();
        gen2drv_mbox.get(tr);
        tr.debug_print("DRV");
        adder_vif.a = tr.a;
        adder_vif.b = tr.b;
        adder_vif.mode = tr.mode;
    endtask

endclass

class monitor;
    // 다른 class니까 generator과 이름 같아도 상관없음
    transaction tr;
    mailbox #(transaction) mon2scb_mbox;
    virtual adder_interface adder_mon_vif;

    //2state만 비교
    // bit [7:0] compare_s;
    // bit compare_c;

    function new(mailbox#(transaction) mon2scb_mbox,
                 virtual adder_interface adder_mon_vif);
        // tr = new;
        this.mon2scb_mbox  = mon2scb_mbox;
        this.adder_mon_vif = adder_mon_vif;
    endfunction

    // task run
    task run();
        //repeat (10) begin
        //    #1;
        tr = new;
        tr.a = adder_mon_vif.a;
        tr.b = adder_mon_vif.b;
        tr.mode = adder_mon_vif.mode;
        tr.s = adder_mon_vif.s;
        tr.c = adder_mon_vif.c;
        tr.debug_print("MON");
        mon2scb_mbox.put(tr);

        // if (tr.mode) {compare_c, compare_s} = tr.a - tr.b;
        // else {compare_c, compare_s} = tr.a + tr.b;

        // if (compare_s == tr.s) $display("PASS SUM");
        // else $display("FAIL SUM");

        // if (compare_c == tr.c) $display("PASS Carry");
        // else $display("FAIL Carry");

        //end
    endtask
endclass

class scoreboard;
    transaction tr;
    mailbox #(transaction) mon2scb_mbox;

    bit [7:0] compare_sum;
    bit compare_carry;
    int pass_cnt = 0, fail_cnt = 0, total_cnt = 0;
    function new(mailbox#(transaction) mon2scb_mbox);
        this.mon2scb_mbox = mon2scb_mbox;
    endfunction

    task run();
        mon2scb_mbox.get(tr);
        tr.debug_print("SCB");
        total_cnt++;
        //scoring
        if (!tr.mode) {compare_carry, compare_sum} = tr.a + tr.b;
        else {compare_carry, compare_sum} = tr.a - tr.b;

        if (compare_sum == tr.s && compare_carry == tr.c) begin
            pass_cnt++;
            $display("%t : scb pass", $time);
        end else begin
            fail_cnt++;
            $display("%t : scb fail", $time);
        end
    endtask
endclass

// to management gen and mon task
class environment;

    generator gen;
    driver drv;
    monitor mon;
    scoreboard scb;

    mailbox #(transaction) gen2drv_mbox;
    mailbox #(transaction) mon2scb_mbox;

    function new(virtual adder_interface adder_vif);
        gen2drv_mbox = new;
        mon2scb_mbox = new;
        gen = new(gen2drv_mbox);
        drv = new(gen2drv_mbox, adder_vif);
        mon = new(mon2scb_mbox, adder_vif);
        scb = new(mon2scb_mbox);
    endfunction

    task run();
        repeat (10) begin
            gen.run();
            drv.run();
            #5;
            mon.run();
            scb.run();
            #5;
        end
        #10;
        $display("_____________________");
        $display("**Total test = %d**", scb.total_cnt);
        $display("**PASS  test = %d**", scb.pass_cnt);
        $display("**FAIL  test = %d**", scb.fail_cnt);
        $display("_____________________");
        $finish;
    endtask
endclass

module tb_adder ();

    // logic d;

    // adder_interface instance
    adder_interface adder_if ();

    // handler for generator class
    // generator gen;
    // monitor mon;
    environment env;

    adder dut (
        .a   (adder_if.a),
        .b   (adder_if.b),
        .mode(adder_if.mode),
        .s   (adder_if.s),
        .c   (adder_if.c)
    );

    initial begin
        // adder_if.a = 0;
        // adder_if.b = 0;
        // adder_if.mode = 0;
        // gen = new(adder_if);
        // mon = new(adder_if);
        // gen.run();
        // mon.run();
        env = new(adder_if);
        env.run();
        // #10;
        $stop;
    end
endmodule

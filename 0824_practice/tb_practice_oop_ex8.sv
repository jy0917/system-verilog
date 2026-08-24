`timescale 1ns / 1ps

module tb_practice_oop_ex8 ();

    // parent
    class transaction;
        string name = "transaction";
        virtual function void drive();
            $display(" %s driven : ", name);
        endfunction

        virtual function int cost();
            return 1;
        endfunction

    endclass

    //child
    class read_txn extends transaction;
        function new();
            name = "read_txn";
        endfunction

        virtual function void drive();
            $display(" %s driven ", name);
        endfunction

        virtual function int cost();
            return 10;
        endfunction
    endclass

    // grand child
    class burst_read_txn extends read_txn;
        int len = 0;
        function new(int len);
            super.new();
            this.len = len;
        endfunction
        virtual function void drive();
            $display(" %s driven len = %d", name, len);
        endfunction

        virtual function int cost();
            return super.cost * 10;
        endfunction
    endclass

    transaction list[$];
    transaction t0;
    read_txn    r0;
    burst_read_txn b0;
    int total;

    initial begin
        $display(
            "[ex8] three different children stored in one parent-type queue");

        t0 = new();
        list.push_back(t0);
        r0 = new();
        list.push_back(r0);
        b0 = new(10);
        list.push_back(b0);

        total = 0;
        foreach (list[i]) begin
            list[i].drive();
            total += list[i].cost();
        end

        $display(" total cost = %d", total);
        $finish;
    end
endmodule

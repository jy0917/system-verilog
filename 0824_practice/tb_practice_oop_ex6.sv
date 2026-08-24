`timescale 1ns / 1ps
// virtual function (static binding, dymic binding)

module tb_practice_oop_ex6 ();

    class transaction;
        function void hello_nonvirtual();
            $display(" execute : transaction::hello_nonvirtual()");
        endfunction

        function void hello_virtual();
            $display(" execute : transaction::hello_virtual()");
        endfunction
    endclass

    class read_txn extends transaction;
        function void hello_nonvirtual();
            $display(" execute : read_txn::hello_nonvirtual()");
        endfunction

        function void hello_virtual();
            $display(" execute : read_txn::hello_virtual()");
        endfunction
    endclass

    // handler
    transaction t;
    read_txn    r;

    initial begin
        $display("[ex6] handle is transation, actual object is read_txn");
        r = new();
        t = r;  // t:upcasting, parent handle by child object
        // t는 parent , r은 child

        $display(" A) t.hello_nonvirtual() execute");
        t.hello_nonvirtual();
        $display(" B) r.hello_nonvirtual() execute");
        r.hello_nonvirtual();

        $display(" C) t.hello_virtual() execute");
        t.hello_virtual();
        $finish;
    end

endmodule

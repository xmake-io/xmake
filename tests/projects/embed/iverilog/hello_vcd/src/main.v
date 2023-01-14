module hello;
  initial begin
    $display("hello world!");
    $dumpfile("hello.vcd");
    $dumpvars(0, hello);
    $finish ;
  end
endmodule

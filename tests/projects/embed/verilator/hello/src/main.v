module hello;
  initial begin
    $display("hello world!");
    $dumpvars(0, hello);
    $finish ;
  end
endmodule

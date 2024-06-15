#include "hello.h"
#include "verilated.h"
#include "verilated_vcd_c.h"

double sc_time_stamp() {
    return 0;
}

int main(int argc, char** argv) {
    char const* vcdfile = NULL;
    if (argc == 2) {
        vcdfile = argv[1];
    }
    if (!vcdfile) {
        vcdfile = "hello.vcd";
    }
    VerilatedContext* contextp = new VerilatedContext;
    contextp->commandArgs(argc, argv);
    hello* top = new hello{contextp};
    VerilatedVcdC* tfp = new VerilatedVcdC;
    top->trace(tfp, 99);
    Verilated::traceEverOn(true);
    tfp->open(vcdfile);
    while (!contextp->gotFinish()) { top->eval(); }
    tfp->close();
    delete top;
    delete contextp;
    return 0;
}

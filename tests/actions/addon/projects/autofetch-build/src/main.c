// the addons must provide the option and the toolchain of this project
#ifndef MYOPTION
#   error the option of the custom-include addon is not found!
#endif
#ifndef MY_C6000
#   error the toolchain of the custom-toolchain addon is not used!
#endif
#ifndef MY_C6000_TOOL
#   error the tool module of the custom-toolchain addon is not used!
#endif

int main(int argc, char** argv) {
    return 0;
}

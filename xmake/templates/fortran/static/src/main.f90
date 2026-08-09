program hello
    use test, only: print_hello
    implicit none (type, external)
    call print_hello()
end program hello

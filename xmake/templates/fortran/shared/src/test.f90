module test
    implicit none (type, external)

contains
    subroutine print_hello()
        print *, "Hello World!"
    end subroutine print_hello
end module test

package main

import (
    "fmt"
    "module"
)

func Run() {

    fmt.Printf("add: %d\n", module.Add(1, 2));
    fmt.Printf("sub: %d\n", module.Sub(1, 2));
}

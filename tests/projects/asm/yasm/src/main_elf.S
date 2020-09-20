bits 64

extern puts

section .data

message:
  db 'hello xmake!', 0

section .text

global main
main:
  push rbp
  mov rbp, rsp
  lea rdi, [rel message]
  call puts
  xor rax, rax
  pop rbp
  ret

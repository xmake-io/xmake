bits 64

extern _puts

section .data

message:
  db 'hello xmake!', 0

section .text

global _main
_main:
  push rbp
  mov rbp, rsp
  lea rdi, [rel message]
  call _puts
  xor rax, rax
  pop rbp
  ret

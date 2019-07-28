	.file "buildvm_arm.dasc"
	.text
	.p2align 4

	.globl lj_vm_asm_begin
	.hidden lj_vm_asm_begin
	.type lj_vm_asm_begin, %object
	.size lj_vm_asm_begin, 0
lj_vm_asm_begin:
.Lbegin:
.fnstart
.save {r4, r5, r6, r7, r8, r9, r10, r11, lr}
.pad #28

	.globl lj_BC_ISLT
	.hidden lj_BC_ISLT
	.type lj_BC_ISLT, %function
	.size lj_BC_ISLT, 152
lj_BC_ISLT:
	.long 0xe1a0b18b,0xe1aa00d9,0xe1d6c0b2,0xe1ab20d9
	.long 0xe2866004,0xe086c10c,0xe371000e,0x1a000009
	.long 0xe373000e,0x1a000014,0xe1500002,0xb24c6b80
	.long 0xe5d6c000,0xe496e004,0xe797c10c,0xe004a2ae
	.long 0xe1a0b82e,0xe12fff1c,0x8a000941,0xe373000e
	.long 0x31a0a00c,0x3a00000c,0x8a00093d,0xe1a00002
	.long 0xe1a0b00a,0xe1a0a00c
	bl __aeabi_i2d
	.long 0xe1a02000,0xe1a03001,0xe1cb00d0,0xea000003
	.long 0x8a000934,0xe1a0a00c
	bl __aeabi_i2d
	.long 0xe1cb20d0
	bl __aeabi_cdcmple
	.long 0x324a6b80,0xeaffffe5

	.globl lj_BC_ISGE
	.hidden lj_BC_ISGE
	.type lj_BC_ISGE, %function
	.size lj_BC_ISGE, 152
lj_BC_ISGE:
	.long 0xe1a0b18b,0xe1aa00d9,0xe1d6c0b2,0xe1ab20d9
	.long 0xe2866004,0xe086c10c,0xe371000e,0x1a000009
	.long 0xe373000e,0x1a000014,0xe1500002,0xa24c6b80
	.long 0xe5d6c000,0xe496e004,0xe797c10c,0xe004a2ae
	.long 0xe1a0b82e,0xe12fff1c,0x8a00091b,0xe373000e
	.long 0x31a0a00c,0x3a00000c,0x8a000917,0xe1a00002
	.long 0xe1a0b00a,0xe1a0a00c
	bl __aeabi_i2d
	.long 0xe1a02000,0xe1a03001,0xe1cb00d0,0xea000003
	.long 0x8a00090e,0xe1a0a00c
	bl __aeabi_i2d
	.long 0xe1cb20d0
	bl __aeabi_cdcmple
	.long 0x224a6b80,0xeaffffe5

	.globl lj_BC_ISLE
	.hidden lj_BC_ISLE
	.type lj_BC_ISLE, %function
	.size lj_BC_ISLE, 152
lj_BC_ISLE:
	.long 0xe1a0b18b,0xe1aa00d9,0xe1d6c0b2,0xe1ab20d9
	.long 0xe2866004,0xe086c10c,0xe371000e,0x1a000009
	.long 0xe373000e,0x1a000014,0xe1500002,0xd24c6b80
	.long 0xe5d6c000,0xe496e004,0xe797c10c,0xe004a2ae
	.long 0xe1a0b82e,0xe12fff1c,0x8a0008f5,0xe373000e
	.long 0x31a0a00c,0x3a00000c,0x8a0008f1,0xe1a00002
	.long 0xe1a0b00a,0xe1a0a00c
	bl __aeabi_i2d
	.long 0xe1a02000,0xe1a03001,0xe1cb00d0,0xea000003
	.long 0x8a0008e8,0xe1a0a00c
	bl __aeabi_i2d
	.long 0xe1cb20d0
	bl __aeabi_cdcmple
	.long 0x924a6b80,0xeaffffe5

	.globl lj_BC_ISGT
	.hidden lj_BC_ISGT
	.type lj_BC_ISGT, %function
	.size lj_BC_ISGT, 152
lj_BC_ISGT:
	.long 0xe1a0b18b,0xe1aa00d9,0xe1d6c0b2,0xe1ab20d9
	.long 0xe2866004,0xe086c10c,0xe371000e,0x1a000009
	.long 0xe373000e,0x1a000014,0xe1500002,0xc24c6b80
	.long 0xe5d6c000,0xe496e004,0xe797c10c,0xe004a2ae
	.long 0xe1a0b82e,0xe12fff1c,0x8a0008cf,0xe373000e
	.long 0x31a0a00c,0x3a00000c,0x8a0008cb,0xe1a00002
	.long 0xe1a0b00a,0xe1a0a00c
	bl __aeabi_i2d
	.long 0xe1a02000,0xe1a03001,0xe1cb00d0,0xea000003
	.long 0x8a0008c2,0xe1a0a00c
	bl __aeabi_i2d
	.long 0xe1cb20d0
	bl __aeabi_cdcmple
	.long 0x824a6b80,0xeaffffe5

	.globl lj_BC_ISEQV
	.hidden lj_BC_ISEQV
	.type lj_BC_ISEQV, %function
	.size lj_BC_ISEQV, 144
lj_BC_ISEQV:
	.long 0xe1a0b18b,0xe1aa00d9,0xe1d6c0b2,0xe1ab20d9
	.long 0xe2866004,0xe086c10c,0xe371000e,0x9373000e
	.long 0x9a000069,0xe371000b,0x1373000b,0x0a0008d6
	.long 0xe1510003,0x1a000004,0xe3710003,0x2a000001
	.long 0xe1500002,0x1a000006,0xe24c6b80,0xe5d6c000
	.long 0xe496e004,0xe797c10c,0xe004a2ae,0xe1a0b82e
	.long 0xe12fff1c,0xe371000c,0x8afffff7,0xe590a010
	.long 0xe35a0000,0x0afffff4,0xe5daa006,0xe3a03000
	.long 0xe1a01000,0xe31a0010,0x0a0008b9,0xeaffffee

	.globl lj_BC_ISNEV
	.hidden lj_BC_ISNEV
	.type lj_BC_ISNEV, %function
	.size lj_BC_ISNEV, 140
lj_BC_ISNEV:
	.long 0xe1a0b18b,0xe1aa00d9,0xe1d6c0b2,0xe1ab20d9
	.long 0xe2866004,0xe086c10c,0xe371000e,0x9373000e
	.long 0x9a000066,0xe371000b,0x1373000b,0x0a0008b2
	.long 0xe1510003,0x1a00000d,0xe3710003,0x2a00000c
	.long 0xe1500002,0x0a00000a,0xe371000c,0x8a000007
	.long 0xe590a010,0xe35a0000,0x0a000004,0xe5daa006
	.long 0xe3a03001,0xe1a01000,0xe31a0010,0x0a00089c
	.long 0xe24c6b80,0xe5d6c000,0xe496e004,0xe797c10c
	.long 0xe004a2ae,0xe1a0b82e,0xe12fff1c

	.globl lj_BC_ISEQS
	.hidden lj_BC_ISEQS
	.type lj_BC_ISEQS, %function
	.size lj_BC_ISEQS, 76
lj_BC_ISEQS:
	.long 0xe1e0b00b,0xe18900da,0xe1d6c0b2,0xe795210b
	.long 0xe2866004,0xe086c10c,0xe3710005,0x1a000007
	.long 0xe1500002,0x024c6b80,0xe5d6c000,0xe496e004
	.long 0xe797c10c,0xe004a2ae,0xe1a0b82e,0xe12fff1c
	.long 0xe371000b,0x1afffff7,0xea000888

	.globl lj_BC_ISNES
	.hidden lj_BC_ISNES
	.type lj_BC_ISNES, %function
	.size lj_BC_ISNES, 76
lj_BC_ISNES:
	.long 0xe1e0b00b,0xe18900da,0xe1d6c0b2,0xe795210b
	.long 0xe2866004,0xe086c10c,0xe3710005,0x1a000007
	.long 0xe1500002,0x124c6b80,0xe5d6c000,0xe496e004
	.long 0xe797c10c,0xe004a2ae,0xe1a0b82e,0xe12fff1c
	.long 0xe371000b,0x1afffff6,0xea000875

	.globl lj_BC_ISEQN
	.hidden lj_BC_ISEQN
	.type lj_BC_ISEQN, %function
	.size lj_BC_ISEQN, 132
lj_BC_ISEQN:
	.long 0xe1a0b18b,0xe1aa00d9,0xe1d6c0b2,0xe1ab20d5
	.long 0xe2866004,0xe086c10c,0xe371000e,0x1a000009
	.long 0xe373000e,0x1a00000d,0xe1500002,0x024c6b80
	.long 0xe5d6c000,0xe496e004,0xe797c10c,0xe004a2ae
	.long 0xe1a0b82e,0xe12fff1c,0x8a00000a,0xe373000e
	.long 0x31a0a00c,0x3a000004,0xe1a00002,0xe1a0b00a
	.long 0xe1a0a00c
	bl __aeabi_i2d
	.long 0xe1cb20d0
	bl __aeabi_cdcmpeq
	.long 0x024a6b80,0xeaffffed,0xe371000b,0x1affffeb
	.long 0xea000854

	.globl lj_BC_ISNEN
	.hidden lj_BC_ISNEN
	.type lj_BC_ISNEN, %function
	.size lj_BC_ISNEN, 132
lj_BC_ISNEN:
	.long 0xe1a0b18b,0xe1aa00d9,0xe1d6c0b2,0xe1ab20d5
	.long 0xe2866004,0xe086c10c,0xe371000e,0x1a000009
	.long 0xe373000e,0x1a00000d,0xe1500002,0x124c6b80
	.long 0xe5d6c000,0xe496e004,0xe797c10c,0xe004a2ae
	.long 0xe1a0b82e,0xe12fff1c,0x8a00000a,0xe373000e
	.long 0x31a0a00c,0x3a000004,0xe1a00002,0xe1a0b00a
	.long 0xe1a0a00c
	bl __aeabi_i2d
	.long 0xe1cb20d0
	bl __aeabi_cdcmpeq
	.long 0x124a6b80,0xeaffffed,0xe371000b,0x1affffea
	.long 0xea000833

	.globl lj_BC_ISEQP
	.hidden lj_BC_ISEQP
	.type lj_BC_ISEQP, %function
	.size lj_BC_ISEQP, 60
lj_BC_ISEQP:
	.long 0xe18900da,0xe1d6c0b2,0xe2866004,0xe1e0b00b
	.long 0xe086c10c,0xe371000b,0x0a00082c,0xe151000b
	.long 0x024c6b80,0xe5d6c000,0xe496e004,0xe797c10c
	.long 0xe004a2ae,0xe1a0b82e,0xe12fff1c

	.globl lj_BC_ISNEP
	.hidden lj_BC_ISNEP
	.type lj_BC_ISNEP, %function
	.size lj_BC_ISNEP, 60
lj_BC_ISNEP:
	.long 0xe18900da,0xe1d6c0b2,0xe2866004,0xe1e0b00b
	.long 0xe086c10c,0xe371000b,0x0a00081d,0xe151000b
	.long 0x124c6b80,0xe5d6c000,0xe496e004,0xe797c10c
	.long 0xe004a2ae,0xe1a0b82e,0xe12fff1c

	.globl lj_BC_ISTC
	.hidden lj_BC_ISTC
	.type lj_BC_ISTC, %function
	.size lj_BC_ISTC, 56
lj_BC_ISTC:
	.long 0xe089b18b,0xe1d6c0b2,0xe1cb00d0,0xe2866004
	.long 0xe086c10c,0xe3710003,0x924c6b80,0x918900fa
	.long 0xe5d6c000,0xe496e004,0xe797c10c,0xe004a2ae
	.long 0xe1a0b82e,0xe12fff1c

	.globl lj_BC_ISFC
	.hidden lj_BC_ISFC
	.type lj_BC_ISFC, %function
	.size lj_BC_ISFC, 56
lj_BC_ISFC:
	.long 0xe089b18b,0xe1d6c0b2,0xe1cb00d0,0xe2866004
	.long 0xe086c10c,0xe3710003,0x824c6b80,0x818900fa
	.long 0xe5d6c000,0xe496e004,0xe797c10c,0xe004a2ae
	.long 0xe1a0b82e,0xe12fff1c

	.globl lj_BC_IST
	.hidden lj_BC_IST
	.type lj_BC_IST, %function
	.size lj_BC_IST, 52
lj_BC_IST:
	.long 0xe089b18b,0xe1d6c0b2,0xe1cb00d0,0xe2866004
	.long 0xe086c10c,0xe3710003,0x924c6b80,0xe5d6c000
	.long 0xe496e004,0xe797c10c,0xe004a2ae,0xe1a0b82e
	.long 0xe12fff1c

	.globl lj_BC_ISF
	.hidden lj_BC_ISF
	.type lj_BC_ISF, %function
	.size lj_BC_ISF, 52
lj_BC_ISF:
	.long 0xe089b18b,0xe1d6c0b2,0xe1cb00d0,0xe2866004
	.long 0xe086c10c,0xe3710003,0x824c6b80,0xe5d6c000
	.long 0xe496e004,0xe797c10c,0xe004a2ae,0xe1a0b82e
	.long 0xe12fff1c

	.globl lj_BC_ISTYPE
	.hidden lj_BC_ISTYPE
	.type lj_BC_ISTYPE, %function
	.size lj_BC_ISTYPE, 36
lj_BC_ISTYPE:
	.long 0xe18900da,0xe5d6c000,0xe171000b,0xe496e004
	.long 0x1a0007e1,0xe797c10c,0xe004a2ae,0xe1a0b82e
	.long 0xe12fff1c

	.globl lj_BC_ISNUM
	.hidden lj_BC_ISNUM
	.type lj_BC_ISNUM, %function
	.size lj_BC_ISNUM, 36
lj_BC_ISNUM:
	.long 0xe18900da,0xe5d6c000,0xe371000e,0xe496e004
	.long 0x2a0007d8,0xe797c10c,0xe004a2ae,0xe1a0b82e
	.long 0xe12fff1c

	.globl lj_BC_MOV
	.hidden lj_BC_MOV
	.type lj_BC_MOV, %function
	.size lj_BC_MOV, 36
lj_BC_MOV:
	.long 0xe1a0b18b,0xe5d6c000,0xe18900db,0xe496e004
	.long 0xe18900fa,0xe797c10c,0xe004a2ae,0xe1a0b82e
	.long 0xe12fff1c

	.globl lj_BC_NOT
	.hidden lj_BC_NOT
	.type lj_BC_NOT, %function
	.size lj_BC_NOT, 52
lj_BC_NOT:
	.long 0xe089b18b,0xe5d6c000,0xe59b0004,0xe089a00a
	.long 0xe496e004,0xe3700003,0x93e01001,0x83e01002
	.long 0xe58a1004,0xe797c10c,0xe004a2ae,0xe1a0b82e
	.long 0xe12fff1c

	.globl lj_BC_UNM
	.hidden lj_BC_UNM
	.type lj_BC_UNM, %function
	.size lj_BC_UNM, 68
lj_BC_UNM:
	.long 0xe1a0b18b,0xe18900db,0xe5d6c000,0xe496e004
	.long 0xe371000e,0x8a0007ca,0x12211480,0x1a000001
	.long 0x02700000,0x61cf01d0,0xe18900fa,0xe797c10c
	.long 0xe004a2ae,0xe1a0b82e,0xe12fff1c,0x00000000
	.long 0x41e00000

	.globl lj_BC_LEN
	.hidden lj_BC_LEN
	.type lj_BC_LEN, %function
	.size lj_BC_LEN, 68
lj_BC_LEN:
	.long 0xe1a0b18b,0xe18900db,0xe3710005,0x1a000008
	.long 0xe590000c,0xe3e0100d,0xe5d6c000,0xe496e004
	.long 0xe18900fa,0xe797c10c,0xe004a2ae,0xe1a0b82e
	.long 0xe12fff1c,0xe371000c,0x1a0007c8
	bl lj_tab_len
	.long 0xeafffff3

	.globl lj_BC_ADDVN
	.hidden lj_BC_ADDVN
	.type lj_BC_ADDVN, %function
	.size lj_BC_ADDVN, 88
lj_BC_ADDVN:
	.long 0xe004caae,0xe004b6ae,0xe18900dc,0xe18520db
	.long 0xe5d6c000,0xe371000e,0x0373000e,0x1a000007
	.long 0xe0900002,0x6a00079a,0xe496e004,0xe18900fa
	.long 0xe797c10c,0xe004a2ae,0xe1a0b82e,0xe12fff1c
	.long 0xe371000e,0x3373000e,0x2a000791
	bl __aeabi_dadd
	.long 0xe5d6c000,0xeafffff3

	.globl lj_BC_SUBVN
	.hidden lj_BC_SUBVN
	.type lj_BC_SUBVN, %function
	.size lj_BC_SUBVN, 88
lj_BC_SUBVN:
	.long 0xe004caae,0xe004b6ae,0xe18900dc,0xe18520db
	.long 0xe5d6c000,0xe371000e,0x0373000e,0x1a000007
	.long 0xe0500002,0x6a000784,0xe496e004,0xe18900fa
	.long 0xe797c10c,0xe004a2ae,0xe1a0b82e,0xe12fff1c
	.long 0xe371000e,0x3373000e,0x2a00077b
	bl __aeabi_dsub
	.long 0xe5d6c000,0xeafffff3

	.globl lj_BC_MULVN
	.hidden lj_BC_MULVN
	.type lj_BC_MULVN, %function
	.size lj_BC_MULVN, 92
lj_BC_MULVN:
	.long 0xe004caae,0xe004b6ae,0xe18900dc,0xe18520db
	.long 0xe5d6c000,0xe371000e,0x0373000e,0x1a000008
	.long 0xe0cb0092,0xe15b0fc0,0x1a00076d,0xe496e004
	.long 0xe18900fa,0xe797c10c,0xe004a2ae,0xe1a0b82e
	.long 0xe12fff1c,0xe371000e,0x3373000e,0x2a000764
	bl __aeabi_dmul
	.long 0xe5d6c000,0xeafffff3

	.globl lj_BC_DIVVN
	.hidden lj_BC_DIVVN
	.type lj_BC_DIVVN, %function
	.size lj_BC_DIVVN, 60
lj_BC_DIVVN:
	.long 0xe004caae,0xe004b6ae,0xe18900dc,0xe18520db
	.long 0xe371000e,0x3373000e,0x2a00075a
	bl __aeabi_ddiv
	.long 0xe5d6c000,0xe496e004,0xe18900fa,0xe797c10c
	.long 0xe004a2ae,0xe1a0b82e,0xe12fff1c

	.globl lj_BC_MODVN
	.hidden lj_BC_MODVN
	.type lj_BC_MODVN, %function
	.size lj_BC_MODVN, 92
lj_BC_MODVN:
	.long 0xe004caae,0xe004b6ae,0xe18900dc,0xe18520db
	.long 0xe371000e,0x0373000e,0x1a00000a,0xe1b01002
	.long 0x0a000749,0xeb000cc3,0xe3e0100d,0xe5d6c000
	.long 0xe496e004,0xe18900fa,0xe797c10c,0xe004a2ae
	.long 0xe1a0b82e,0xe12fff1c,0xe371000e,0x3373000e
	.long 0x2a00073d,0xeb000cad,0xeafffff3

	.globl lj_BC_ADDNV
	.hidden lj_BC_ADDNV
	.type lj_BC_ADDNV, %function
	.size lj_BC_ADDNV, 88
lj_BC_ADDNV:
	.long 0xe004caae,0xe004b6ae,0xe18920dc,0xe18500db
	.long 0xe5d6c000,0xe373000e,0x0371000e,0x1a000007
	.long 0xe0900002,0x6a000736,0xe496e004,0xe18900fa
	.long 0xe797c10c,0xe004a2ae,0xe1a0b82e,0xe12fff1c
	.long 0xe373000e,0x3371000e,0x2a00072d
	bl __aeabi_dadd
	.long 0xe5d6c000,0xeafffff3

	.globl lj_BC_SUBNV
	.hidden lj_BC_SUBNV
	.type lj_BC_SUBNV, %function
	.size lj_BC_SUBNV, 88
lj_BC_SUBNV:
	.long 0xe004caae,0xe004b6ae,0xe18920dc,0xe18500db
	.long 0xe5d6c000,0xe373000e,0x0371000e,0x1a000007
	.long 0xe0500002,0x6a000720,0xe496e004,0xe18900fa
	.long 0xe797c10c,0xe004a2ae,0xe1a0b82e,0xe12fff1c
	.long 0xe373000e,0x3371000e,0x2a000717
	bl __aeabi_dsub
	.long 0xe5d6c000,0xeafffff3

	.globl lj_BC_MULNV
	.hidden lj_BC_MULNV
	.type lj_BC_MULNV, %function
	.size lj_BC_MULNV, 92
lj_BC_MULNV:
	.long 0xe004caae,0xe004b6ae,0xe18920dc,0xe18500db
	.long 0xe5d6c000,0xe373000e,0x0371000e,0x1a000008
	.long 0xe0cb0092,0xe15b0fc0,0x1a000709,0xe496e004
	.long 0xe18900fa,0xe797c10c,0xe004a2ae,0xe1a0b82e
	.long 0xe12fff1c,0xe373000e,0x3371000e,0x2a000700
	bl __aeabi_dmul
	.long 0xe5d6c000,0xeafffff3

	.globl lj_BC_DIVNV
	.hidden lj_BC_DIVNV
	.type lj_BC_DIVNV, %function
	.size lj_BC_DIVNV, 60
lj_BC_DIVNV:
	.long 0xe004caae,0xe004b6ae,0xe18920dc,0xe18500db
	.long 0xe373000e,0x3371000e,0x2a0006f6
	bl __aeabi_ddiv
	.long 0xe5d6c000,0xe496e004,0xe18900fa,0xe797c10c
	.long 0xe004a2ae,0xe1a0b82e,0xe12fff1c

	.globl lj_BC_MODNV
	.hidden lj_BC_MODNV
	.type lj_BC_MODNV, %function
	.size lj_BC_MODNV, 92
lj_BC_MODNV:
	.long 0xe004caae,0xe004b6ae,0xe18920dc,0xe18500db
	.long 0xe373000e,0x0371000e,0x1a00000a,0xe1b01002
	.long 0x0a0006e5,0xeb000c5a,0xe3e0100d,0xe5d6c000
	.long 0xe496e004,0xe18900fa,0xe797c10c,0xe004a2ae
	.long 0xe1a0b82e,0xe12fff1c,0xe373000e,0x3371000e
	.long 0x2a0006d9,0xeb000c44,0xeafffff3

	.globl lj_BC_ADDVV
	.hidden lj_BC_ADDVV
	.type lj_BC_ADDVV, %function
	.size lj_BC_ADDVV, 88
lj_BC_ADDVV:
	.long 0xe004caae,0xe004b6ae,0xe18900dc,0xe18920db
	.long 0xe5d6c000,0xe371000e,0x0373000e,0x1a000007
	.long 0xe0900002,0x6a0006d7,0xe496e004,0xe18900fa
	.long 0xe797c10c,0xe004a2ae,0xe1a0b82e,0xe12fff1c
	.long 0xe371000e,0x3373000e,0x2a0006ce
	bl __aeabi_dadd
	.long 0xe5d6c000,0xeafffff3

	.globl lj_BC_SUBVV
	.hidden lj_BC_SUBVV
	.type lj_BC_SUBVV, %function
	.size lj_BC_SUBVV, 88
lj_BC_SUBVV:
	.long 0xe004caae,0xe004b6ae,0xe18900dc,0xe18920db
	.long 0xe5d6c000,0xe371000e,0x0373000e,0x1a000007
	.long 0xe0500002,0x6a0006c1,0xe496e004,0xe18900fa
	.long 0xe797c10c,0xe004a2ae,0xe1a0b82e,0xe12fff1c
	.long 0xe371000e,0x3373000e,0x2a0006b8
	bl __aeabi_dsub
	.long 0xe5d6c000,0xeafffff3

	.globl lj_BC_MULVV
	.hidden lj_BC_MULVV
	.type lj_BC_MULVV, %function
	.size lj_BC_MULVV, 92
lj_BC_MULVV:
	.long 0xe004caae,0xe004b6ae,0xe18900dc,0xe18920db
	.long 0xe5d6c000,0xe371000e,0x0373000e,0x1a000008
	.long 0xe0cb0092,0xe15b0fc0,0x1a0006aa,0xe496e004
	.long 0xe18900fa,0xe797c10c,0xe004a2ae,0xe1a0b82e
	.long 0xe12fff1c,0xe371000e,0x3373000e,0x2a0006a1
	bl __aeabi_dmul
	.long 0xe5d6c000,0xeafffff3

	.globl lj_BC_DIVVV
	.hidden lj_BC_DIVVV
	.type lj_BC_DIVVV, %function
	.size lj_BC_DIVVV, 60
lj_BC_DIVVV:
	.long 0xe004caae,0xe004b6ae,0xe18900dc,0xe18920db
	.long 0xe371000e,0x3373000e,0x2a000697
	bl __aeabi_ddiv
	.long 0xe5d6c000,0xe496e004,0xe18900fa,0xe797c10c
	.long 0xe004a2ae,0xe1a0b82e,0xe12fff1c

	.globl lj_BC_MODVV
	.hidden lj_BC_MODVV
	.type lj_BC_MODVV, %function
	.size lj_BC_MODVV, 92
lj_BC_MODVV:
	.long 0xe004caae,0xe004b6ae,0xe18900dc,0xe18920db
	.long 0xe371000e,0x0373000e,0x1a00000a,0xe1b01002
	.long 0x0a000686,0xeb000bf1,0xe3e0100d,0xe5d6c000
	.long 0xe496e004,0xe18900fa,0xe797c10c,0xe004a2ae
	.long 0xe1a0b82e,0xe12fff1c,0xe371000e,0x3373000e
	.long 0x2a00067a,0xeb000bdb,0xeafffff3

	.globl lj_BC_POW
	.hidden lj_BC_POW
	.type lj_BC_POW, %function
	.size lj_BC_POW, 60
lj_BC_POW:
	.long 0xe004caae,0xe004b6ae,0xe18900dc,0xe18920db
	.long 0xe371000e,0x3373000e,0x2a000671
	bl pow
	.long 0xe5d6c000,0xe496e004,0xe18900fa,0xe797c10c
	.long 0xe004a2ae,0xe1a0b82e,0xe12fff1c

	.globl lj_BC_CAT
	.hidden lj_BC_CAT
	.type lj_BC_CAT, %function
	.size lj_BC_CAT, 80
lj_BC_CAT:
	.long 0xe004baae,0xe004c6ae,0xe04c200b,0xe5889010
	.long 0xe089100c,0xe1a00008,0xe58d6008,0xe1a021a2
	bl lj_meta_cat
	.long 0xe5989010,0xe3500000,0x1a00066a,0xe18920db
	.long 0xe5d6c000,0xe496e004,0xe18920fa,0xe797c10c
	.long 0xe004a2ae,0xe1a0b82e,0xe12fff1c

	.globl lj_BC_KSTR
	.hidden lj_BC_KSTR
	.type lj_BC_KSTR, %function
	.size lj_BC_KSTR, 40
lj_BC_KSTR:
	.long 0xe1e0b00b,0xe5d6c000,0xe795010b,0xe3e01004
	.long 0xe496e004,0xe18900fa,0xe797c10c,0xe004a2ae
	.long 0xe1a0b82e,0xe12fff1c

	.globl lj_BC_KCDATA
	.hidden lj_BC_KCDATA
	.type lj_BC_KCDATA, %function
	.size lj_BC_KCDATA, 40
lj_BC_KCDATA:
	.long 0xe1e0b00b,0xe5d6c000,0xe795010b,0xe3e0100a
	.long 0xe496e004,0xe18900fa,0xe797c10c,0xe004a2ae
	.long 0xe1a0b82e,0xe12fff1c

	.globl lj_BC_KSHORT
	.hidden lj_BC_KSHORT
	.type lj_BC_KSHORT, %function
	.size lj_BC_KSHORT, 36
lj_BC_KSHORT:
	.long 0xe1a0084e,0xe3e0100d,0xe5d6c000,0xe496e004
	.long 0xe18900fa,0xe797c10c,0xe004a2ae,0xe1a0b82e
	.long 0xe12fff1c

	.globl lj_BC_KNUM
	.hidden lj_BC_KNUM
	.type lj_BC_KNUM, %function
	.size lj_BC_KNUM, 36
lj_BC_KNUM:
	.long 0xe1a0b18b,0xe5d6c000,0xe18500db,0xe496e004
	.long 0xe18900fa,0xe797c10c,0xe004a2ae,0xe1a0b82e
	.long 0xe12fff1c

	.globl lj_BC_KPRI
	.hidden lj_BC_KPRI
	.type lj_BC_KPRI, %function
	.size lj_BC_KPRI, 36
lj_BC_KPRI:
	.long 0xe089a00a,0xe1e0b00b,0xe5d6c000,0xe496e004
	.long 0xe58ab004,0xe797c10c,0xe004a2ae,0xe1a0b82e
	.long 0xe12fff1c

	.globl lj_BC_KNIL
	.hidden lj_BC_KNIL
	.type lj_BC_KNIL, %function
	.size lj_BC_KNIL, 60
lj_BC_KNIL:
	.long 0xe089a00a,0xe089b18b,0xe3e00000,0xe58a0004
	.long 0xe28aa008,0xe58a0004,0xe15a000b,0xe28aa008
	.long 0xbafffffb,0xe5d6c000,0xe496e004,0xe797c10c
	.long 0xe004a2ae,0xe1a0b82e,0xe12fff1c

	.globl lj_BC_UGET
	.hidden lj_BC_UGET
	.type lj_BC_UGET, %function
	.size lj_BC_UGET, 52
lj_BC_UGET:
	.long 0xe5191008,0xe1a0b10b,0xe28bb014,0xe791100b
	.long 0xe5911010,0xe1c120d0,0xe5d6c000,0xe496e004
	.long 0xe18920fa,0xe797c10c,0xe004a2ae,0xe1a0b82e
	.long 0xe12fff1c

	.globl lj_BC_USETV
	.hidden lj_BC_USETV
	.type lj_BC_USETV, %function
	.size lj_BC_USETV, 108
lj_BC_USETV:
	.long 0xe5191008,0xe1a0a0aa,0xe28aa014,0xe1a0b18b
	.long 0xe791100a,0xe18920db,0xe5d1c004,0xe5d1b006
	.long 0xe5911010,0xe31c0004,0xe283c004,0x135b0000
	.long 0xe1c120f0,0x1a000005,0xe5d6c000,0xe496e004
	.long 0xe797c10c,0xe004a2ae,0xe1a0b82e,0xe12fff1c
	.long 0xe37c000a,0x85d2b004,0x9afffff6,0xe2470eb3
	.long 0xe31b0003
	blne lj_gc_barrieruv
	.long 0xeafffff2

	.globl lj_BC_USETS
	.hidden lj_BC_USETS
	.type lj_BC_USETS, %function
	.size lj_BC_USETS, 100
lj_BC_USETS:
	.long 0xe5191008,0xe1a0a0aa,0xe28aa014,0xe1e0b00b
	.long 0xe791100a,0xe795210b,0xe5d1c004,0xe5d1b006
	.long 0xe5911010,0xe3e03004,0xe31c0004,0xe5d2c004
	.long 0xe1c120f0,0x1a000005,0xe5d6c000,0xe496e004
	.long 0xe797c10c,0xe004a2ae,0xe1a0b82e,0xe12fff1c
	.long 0xe31c0003,0x135b0000,0xe2470eb3
	blne lj_gc_barrieruv
	.long 0xeafffff4

	.globl lj_BC_USETN
	.hidden lj_BC_USETN
	.type lj_BC_USETN, %function
	.size lj_BC_USETN, 56
lj_BC_USETN:
	.long 0xe5191008,0xe1a0a0aa,0xe28aa014,0xe1a0b18b
	.long 0xe791100a,0xe18520db,0xe5911010,0xe5d6c000
	.long 0xe496e004,0xe1c120f0,0xe797c10c,0xe004a2ae
	.long 0xe1a0b82e,0xe12fff1c

	.globl lj_BC_USETP
	.hidden lj_BC_USETP
	.type lj_BC_USETP, %function
	.size lj_BC_USETP, 52
lj_BC_USETP:
	.long 0xe5191008,0xe1a0a0aa,0xe28aa014,0xe791100a
	.long 0xe1e0b00b,0xe5911010,0xe5d6c000,0xe496e004
	.long 0xe581b004,0xe797c10c,0xe004a2ae,0xe1a0b82e
	.long 0xe12fff1c

	.globl lj_BC_UCLO
	.hidden lj_BC_UCLO
	.type lj_BC_UCLO, %function
	.size lj_BC_UCLO, 64
lj_BC_UCLO:
	.long 0xe5982020,0xe086b10b,0xe5889010,0xe3520000
	.long 0xe24b6b80,0x0a000003,0xe1a00008,0xe089100a
	bl lj_func_closeuv
	.long 0xe5989010,0xe5d6c000,0xe496e004,0xe797c10c
	.long 0xe004a2ae,0xe1a0b82e,0xe12fff1c

	.globl lj_BC_FNEW
	.hidden lj_BC_FNEW
	.type lj_BC_FNEW, %function
	.size lj_BC_FNEW, 64
lj_BC_FNEW:
	.long 0xe1e0b00b,0xe5889010,0xe795110b,0xe58d6008
	.long 0xe5192008,0xe1a00008
	bl lj_func_newL_gc
	.long 0xe5989010,0xe3e01008,0xe5d6c000,0xe496e004
	.long 0xe18900fa,0xe797c10c,0xe004a2ae,0xe1a0b82e
	.long 0xe12fff1c

	.globl lj_BC_TNEW
	.hidden lj_BC_TNEW
	.type lj_BC_TNEW, %function
	.size lj_BC_TNEW, 104
lj_BC_TNEW:
	.long 0xe5172b1c,0xe5173b18,0xe5889010,0xe58d6008
	.long 0xe1520003,0xe1a00008,0x2a00000f,0xe1a01a8b
	.long 0xe1a025ab,0xe1a0bac1,0xe1a01aa1,0xe37b0001
	.long 0x02811002
	bl lj_tab_new
	.long 0xe5989010,0xe3e0100b,0xe5d6c000,0xe496e004
	.long 0xe18900fa,0xe797c10c,0xe004a2ae,0xe1a0b82e
	.long 0xe12fff1c
	bl lj_gc_step_fixtop
	.long 0xe1a00008,0xeaffffec

	.globl lj_BC_TDUP
	.hidden lj_BC_TDUP
	.type lj_BC_TDUP, %function
	.size lj_BC_TDUP, 88
lj_BC_TDUP:
	.long 0xe1e0b00b,0xe5172b1c,0xe5173b18,0xe5889010
	.long 0xe58d6008,0xe1520003,0xe1a00008,0x2a00000a
	.long 0xe795110b
	bl lj_tab_dup
	.long 0xe5989010,0xe3e0100b,0xe5d6c000,0xe496e004
	.long 0xe18900fa,0xe797c10c,0xe004a2ae,0xe1a0b82e
	.long 0xe12fff1c
	bl lj_gc_step_fixtop
	.long 0xe1a00008,0xeafffff1

	.globl lj_BC_GGET
	.hidden lj_BC_GGET
	.type lj_BC_GGET, %function
	.size lj_BC_GGET, 20
lj_BC_GGET:
	.long 0xe5191008,0xe1e0b00b,0xe5910008,0xe795b10b
	.long 0xea00002e

	.globl lj_BC_GSET
	.hidden lj_BC_GSET
	.type lj_BC_GSET, %function
	.size lj_BC_GSET, 20
lj_BC_GSET:
	.long 0xe5191008,0xe1e0b00b,0xe5910008,0xe795b10b
	.long 0xea0000ac

	.globl lj_BC_TGETV
	.hidden lj_BC_TGETV
	.type lj_BC_TGETV, %function
	.size lj_BC_TGETV, 140
lj_BC_TGETV:
	.long 0xe004caae,0xe004b6ae,0xe18900dc,0xe18920db
	.long 0xe371000c,0x1a0004cd,0xe373000e,0x05903008
	.long 0x05901018,0x1a000014,0xe0833182,0xe1520001
	.long 0x31c320d0,0x2a0004c5,0xe5d6c000,0xe3730001
	.long 0x0a000005,0xe496e004,0xe18920fa,0xe797c10c
	.long 0xe004a2ae,0xe1a0b82e,0xe12fff1c,0xe5901010
	.long 0xe3510000,0x0afffff6,0xe5d11006,0xe3110001
	.long 0x1afffff3,0xe004caae,0xea0004b4,0xe3730005
	.long 0x01a0b002,0x0a000007,0xea0004b0

	.globl lj_BC_TGETS
	.hidden lj_BC_TGETS
	.type lj_BC_TGETS, %function
	.size lj_BC_TGETS, 160
lj_BC_TGETS:
	.long 0xe004caae,0xe20bb0ff,0xe18900dc,0xe1e0b00b
	.long 0xe795b10b,0xe371000c,0x1a000497,0xe590201c
	.long 0xe59b3008,0xe590e014,0xe1a0c000,0xe0022003
	.long 0xe0822082,0xe08ee182,0xe1ce00d8,0xe1ce20d0
	.long 0xe59ee010,0xe3710005,0x0150000b,0x1a000008
	.long 0xe3730001,0x0a000008,0xe5d6c000,0xe496e004
	.long 0xe18920fa,0xe797c10c,0xe004a2ae,0xe1a0b82e
	.long 0xe12fff1c,0xe35e0000,0x1affffee,0xe59c0010
	.long 0xe3a02000,0xe3e03000,0xe3500000,0x0afffff1
	.long 0xe5d01006,0xe3110001,0x1affffee,0xea000478

	.globl lj_BC_TGETB
	.hidden lj_BC_TGETB
	.type lj_BC_TGETB, %function
	.size lj_BC_TGETB, 108
lj_BC_TGETB:
	.long 0xe004caae,0xe20bb0ff,0xe18900dc,0xe371000c
	.long 0x1a00047c,0xe5902018,0xe5903008,0xe1a0118b
	.long 0xe15b0002,0x318320d1,0x2a000476,0xe5d6c000
	.long 0xe3730001,0x0a000005,0xe496e004,0xe18920fa
	.long 0xe797c10c,0xe004a2ae,0xe1a0b82e,0xe12fff1c
	.long 0xe5901010,0xe3510000,0x0afffff6,0xe5d11006
	.long 0xe3110001,0x1afffff3,0xea000466

	.globl lj_BC_TGETR
	.hidden lj_BC_TGETR
	.type lj_BC_TGETR, %function
	.size lj_BC_TGETR, 68
lj_BC_TGETR:
	.long 0xe004caae,0xe004b6ae,0xe799000c,0xe799100b
	.long 0xe5903008,0xe5902018,0xe0833181,0xe1510002
	.long 0x2a00047b,0xe1c300d0,0xe5d6c000,0xe496e004
	.long 0xe18900fa,0xe797c10c,0xe004a2ae,0xe1a0b82e
	.long 0xe12fff1c

	.globl lj_BC_TSETV
	.hidden lj_BC_TSETV
	.type lj_BC_TSETV, %function
	.size lj_BC_TSETV, 188
lj_BC_TSETV:
	.long 0xe004caae,0xe004b6ae,0xe18900dc,0xe18920db
	.long 0xe371000c,0x1a000484,0xe373000e,0x05901008
	.long 0x05903018,0x1a000020,0xe0811182,0xe1520003
	.long 0x3591e004,0x2a00047c,0xe5d6c000,0xe37e0001
	.long 0xe5d0e004,0xe18920da,0x0a000007,0xe31e0004
	.long 0xe1c120f0,0x1a00000e,0xe496e004,0xe797c10c
	.long 0xe004a2ae,0xe1a0b82e,0xe12fff1c,0xe590a010
	.long 0xe35a0000,0x0afffff4,0xe5daa006,0xe31a0002
	.long 0x1afffff1,0xe516e004,0xe004caae,0xe004a2ae
	.long 0xea000465,0xe5172b00,0xe3cee004,0xe5070b00
	.long 0xe5c0e004,0xe580200c,0xeaffffea,0xe3730005
	.long 0x01a0b002,0x0a000007,0xea00045b

	.globl lj_BC_TSETS
	.hidden lj_BC_TSETS
	.type lj_BC_TSETS, %function
	.size lj_BC_TSETS, 276
lj_BC_TSETS:
	.long 0xe004caae,0xe20bb0ff,0xe18900dc,0xe1e0b00b
	.long 0xe795b10b,0xe371000c,0x1a000442,0xe590201c
	.long 0xe59b3008,0xe590e014,0xe1a0c000,0xe0022003
	.long 0xe0822082,0xe3a03000,0xe08ee182,0xe5cc3006
	.long 0xe1ce00d8,0xe59e3004,0xe59e2010,0xe3710005
	.long 0x0150000b,0x1a000013,0xe5dc1004,0xe3730001
	.long 0xe18920da,0x0a000008,0xe3110004,0xe1ce20f0
	.long 0x1a000021,0xe5d6c000,0xe496e004,0xe797c10c
	.long 0xe004a2ae,0xe1a0b82e,0xe12fff1c,0xe59c0010
	.long 0xe3500000,0x0afffff3,0xe5d00006,0xe3100002
	.long 0x1afffff0,0xea000421,0xe1b0e002,0x1affffe3
	.long 0xe59c0010,0xe1a0200d,0xe58d6008,0xe3500000
	.long 0xe5889010,0x15d01006,0xe1a00008,0x0a000001
	.long 0xe3110002,0x0a000415,0xe3e03004,0xe58db000
	.long 0xe1a0100c,0xe58d3004
	bl lj_tab_newkey
	.long 0xe5989010,0xe18920da,0xe1c020f0,0xeaffffdd
	.long 0xe5172b00,0xe3c11004,0xe507cb00,0xe5cc1004
	.long 0xe58c200c,0xeaffffd7

	.globl lj_BC_TSETB
	.hidden lj_BC_TSETB
	.type lj_BC_TSETB, %function
	.size lj_BC_TSETB, 156
lj_BC_TSETB:
	.long 0xe004caae,0xe20bb0ff,0xe18900dc,0xe371000c
	.long 0x1a00040a,0xe5902018,0xe590c008,0xe1a0118b
	.long 0xe15b0002,0x31a120dc,0x2a000404,0xe5d6c000
	.long 0xe3730001,0xe5d0e004,0xe18920da,0x0a000007
	.long 0xe31e0004,0xe1c120f0,0x1a00000d,0xe496e004
	.long 0xe797c10c,0xe004a2ae,0xe1a0b82e,0xe12fff1c
	.long 0xe590a010,0xe35a0000,0x0afffff4,0xe5daa006
	.long 0xe31a0002,0x1afffff1,0xe516e004,0xe004a2ae
	.long 0xea0003ee,0xe5172b00,0xe3cee004,0xe5070b00
	.long 0xe5c0e004,0xe580200c,0xeaffffeb

	.globl lj_BC_TSETM
	.hidden lj_BC_TSETM
	.type lj_BC_TSETM, %function
	.size lj_BC_TSETM, 148
lj_BC_TSETM:
	.long 0xe089a00a,0xe59dc004,0xe51a1008,0xe795018b
	.long 0xe25cc008,0xe5913018,0x0a00000c,0xe08021ac
	.long 0xe1520003,0xe5913008,0xe08ac00c,0x8a00000d
	.long 0xe083e180,0xe5d10004,0xe0ca20d8,0xe0ce20f8
	.long 0xe15a000c,0x3afffffb,0xe3100004,0x1a00000a
	.long 0xe5d6c000,0xe496e004,0xe797c10c,0xe004a2ae
	.long 0xe1a0b82e,0xe12fff1c,0xe5889010,0xe1a00008
	.long 0xe58d6008
	bl lj_tab_reasize
	.long 0xeaffffe1,0xe5172b00,0xe3c00004,0xe5071b00
	.long 0xe5c10004,0xe581200c,0xeaffffee

	.globl lj_BC_TSETR
	.hidden lj_BC_TSETR
	.type lj_BC_TSETR, %function
	.size lj_BC_TSETR, 104
lj_BC_TSETR:
	.long 0xe004caae,0xe004b6ae,0xe799100c,0xe799200b
	.long 0xe5d1e004,0xe5910008,0xe5913018,0xe31e0004
	.long 0xe0800182,0x1a000009,0xe1520003,0x2a0003d6
	.long 0xe18920da,0xe5d6c000,0xe496e004,0xe1c020f0
	.long 0xe797c10c,0xe004a2ae,0xe1a0b82e,0xe12fff1c
	.long 0xe517cb00,0xe3cee004,0xe5071b00,0xe5c1e004
	.long 0xe581c00c,0xeaffffef

	.globl lj_BC_CALLM
	.hidden lj_BC_CALLM
	.type lj_BC_CALLM, %function
	.size lj_BC_CALLM, 16
lj_BC_CALLM:
	.long 0xe59d0004,0xe004b6ae,0xe08bb000,0xea000000

	.globl lj_BC_CALL
	.hidden lj_BC_CALL
	.type lj_BC_CALL, %function
	.size lj_BC_CALL, 60
lj_BC_CALL:
	.long 0xe004b6ae,0xe1a0c009,0xe1a920da,0xe24bb008
	.long 0xe2899008,0xe3730009,0x1a00041e,0xe5096004
	.long 0xe5926010,0xe5d6c000,0xe496e004,0xe797c10c
	.long 0xe004a2ae,0xe08aa009,0xe12fff1c

	.globl lj_BC_CALLMT
	.hidden lj_BC_CALLMT
	.type lj_BC_CALLMT, %function
	.size lj_BC_CALLMT, 12
lj_BC_CALLMT:
	.long 0xe59d0004,0xe080b18b,0xea000000

	.globl lj_BC_CALLT
	.hidden lj_BC_CALLT
	.type lj_BC_CALLT, %function
	.size lj_BC_CALLT, 180
lj_BC_CALLT:
	.long 0xe1a0b18b,0xe1aa20d9,0xe24bb008,0xe28aa008
	.long 0xe3730009,0x1a00041d,0xe5196004,0xe3a0c000
	.long 0xe5d23006,0xe3160003,0x1a000018,0xe5092008
	.long 0xe35b0000,0x0a000005,0xe18a00dc,0xe28ce008
	.long 0xe15e000b,0xe18900fc,0xe1a0c00e,0x1afffff9
	.long 0xe3530001,0x8a000006,0xe5926010,0xe5d6c000
	.long 0xe496e004,0xe797c10c,0xe004a2ae,0xe08aa009
	.long 0xe12fff1c,0xe516e004,0xe004a2ae,0xe049000a
	.long 0xe5100010,0xe5900010,0xe5105030,0xeafffff1
	.long 0xe2266003,0xe3160007,0x13a03000,0x1affffe2
	.long 0xe0499006,0xe5196004,0xe3160003,0x13a03000
	.long 0xeaffffdd

	.globl lj_BC_ITERC
	.hidden lj_BC_ITERC
	.type lj_BC_ITERC, %function
	.size lj_BC_ITERC, 80
lj_BC_ITERC:
	.long 0xe089a00a,0xe1a0c009,0xe14a21d0,0xe14a00d8
	.long 0xe28a9008,0xe1ca20f8,0xe1ca01f0,0xe14a21d8
	.long 0xe3a0b010,0xe1ca20f0,0xe3730009,0x1a0003da
	.long 0xe5096004,0xe5926010,0xe5d6c000,0xe496e004
	.long 0xe797c10c,0xe004a2ae,0xe08aa009,0xe12fff1c

	.globl lj_BC_ITERN
	.hidden lj_BC_ITERN
	.type lj_BC_ITERN, %function
	.size lj_BC_ITERN, 184
lj_BC_ITERN:
	.long 0xe089a00a,0xe51ac010,0xe51a0008,0xe59ce018
	.long 0xe59c1008,0xe2866004,0xe050b00e,0xe0812180
	.long 0x2a000011,0xe1c220d0,0xe3730001,0x02800001
	.long 0x0afffff8,0xe156b0b2,0xe3e0100d,0xe1ca20f8
	.long 0xe086b10b,0xe280c001,0xe1ca00f0,0xe24b6b80
	.long 0xe50ac008,0xe5d6c000,0xe496e004,0xe797c10c
	.long 0xe004a2ae,0xe1a0b82e,0xe12fff1c,0xe59c301c
	.long 0xe59cc014,0xe08b008b,0xe15b0003,0xe08c2180
	.long 0x8afffff3,0xe1c200d0,0xe3710001,0xe28bb001
	.long 0x0afffff7,0xe156c0b2,0xe08bb00e,0xe1c220d8
	.long 0xe50ab008,0xe1ca00f8,0xe086b10c,0xe24b6b80
	.long 0xe1ca20f0,0xeaffffe6

	.globl lj_BC_VARG
	.hidden lj_BC_VARG
	.type lj_BC_VARG, %function
	.size lj_BC_VARG, 208
lj_BC_VARG:
	.long 0xe004caae,0xe004b6ae,0xe5190004,0xe089b00b
	.long 0xe089a00a,0xe28bb003,0xe08a300c,0xe2492008
	.long 0xe04bb000,0xe35c0000,0xe042000b,0x0a00000c
	.long 0xe2433010,0xe15b0002,0x30cb00d8,0x23e01000
	.long 0xe15a0003,0xe0ca00f8,0x3afffff9,0xe5d6c000
	.long 0xe496e004,0xe797c10c,0xe004a2ae,0xe1a0b82e
	.long 0xe12fff1c,0xe5983018,0xe3500000,0xd3a0c008
	.long 0xc280c008,0xe08a1000,0xe58dc004,0xdafffff2
	.long 0xe1510003,0x8a000004,0xe0cb00d8,0xe0ca00f8
	.long 0xe15b0002,0x3afffffb,0xeaffffeb,0xe1a011a0
	.long 0xe588a014,0xe1a00008,0xe5889010,0xe04bb009
	.long 0xe58d6008,0xe04aa009
	bl lj_state_growstack
	.long 0xe5989010,0xe089a00a,0xe089b00b,0xe2492008
	.long 0xeaffffed

	.globl lj_BC_ISNEXT
	.hidden lj_BC_ISNEXT
	.type lj_BC_ISNEXT, %function
	.size lj_BC_ISNEXT, 112
lj_BC_ISNEXT:
	.long 0xe089a00a,0xe086b10b,0xe14a01d8,0xe51a200c
	.long 0xe51a3004,0xe3710009,0x05d00006,0x0372000c
	.long 0x03730001,0x03500004,0x024b6b80,0x1a000008
	.long 0xe5d6c000,0xe496e004,0xe3a00000,0xe3e01b60
	.long 0xe14a00f8,0xe797c10c,0xe004a2ae,0xe1a0b82e
	.long 0xe12fff1c,0xe3a00058,0xe3a0c045,0xe5460004
	.long 0xe24b6b80,0xe5c6c000,0xe496e004,0xeafffff4

	.globl lj_BC_RETM
	.hidden lj_BC_RETM
	.type lj_BC_RETM, %function
	.size lj_BC_RETM, 20
lj_BC_RETM:
	.long 0xe59d0004,0xe5196004,0xe089a00a,0xe080b18b
	.long 0xea000002

	.globl lj_BC_RET
	.hidden lj_BC_RET
	.type lj_BC_RET, %function
	.size lj_BC_RET, 168
lj_BC_RET:
	.long 0xe5196004,0xe1a0b18b,0xe089a00a,0xe58db004
	.long 0xe2160003,0xe2261003,0x1a00001d,0xe516e004
	.long 0xe25b3008,0xe2492008,0x0a000004,0xe0ca00d8
	.long 0xe2899008,0xe2533008,0xe14901f0,0x1afffffa
	.long 0xe004a2ae,0xe042300a,0xe004caae,0xe5130008
	.long 0xe15c000b,0x8a000008,0xe1a09003,0xe5901010
	.long 0xe5d6c000,0xe496e004,0xe5115030,0xe797c10c
	.long 0xe004a2ae,0xe1a0b82e,0xe12fff1c,0xe3e01000
	.long 0xe2899008,0xe28bb008,0xe509100c,0xeaffffef
	.long 0xe089a00a,0xe3110007,0x1a000194,0xe0499001
	.long 0xe5196004,0xeaffffd9

	.globl lj_BC_RET0
	.hidden lj_BC_RET0
	.type lj_BC_RET0, %function
	.size lj_BC_RET0, 108
lj_BC_RET0:
	.long 0xe5196004,0xe1a0b18b,0xe58db004,0xe2160003
	.long 0xe2261003,0x0516e004,0x1afffff2,0xe2493008
	.long 0xe004a2ae,0xe043900a,0xe004caae,0xe5190008
	.long 0xe15c000b,0x8a000007,0xe5901010,0xe5d6c000
	.long 0xe496e004,0xe5115030,0xe797c10c,0xe004a2ae
	.long 0xe1a0b82e,0xe12fff1c,0xe2431004,0xe3e02000
	.long 0xe781200b,0xe28bb008,0xeafffff0

	.globl lj_BC_RET1
	.hidden lj_BC_RET1
	.type lj_BC_RET1, %function
	.size lj_BC_RET1, 116
lj_BC_RET1:
	.long 0xe5196004,0xe1a0b18b,0xe58db004,0xe2160003
	.long 0xe2261003,0x0516e004,0x1affffd7,0xe18900da
	.long 0xe2493008,0xe004a2ae,0xe1c300f0,0xe043900a
	.long 0xe004caae,0xe5190008,0xe15c000b,0x8a000007
	.long 0xe5901010,0xe5d6c000,0xe496e004,0xe5115030
	.long 0xe797c10c,0xe004a2ae,0xe1a0b82e,0xe12fff1c
	.long 0xe2431004,0xe3e02000,0xe781200b,0xe28bb008
	.long 0xeafffff0

	.globl lj_BC_FORI
	.hidden lj_BC_FORI
	.type lj_BC_FORI, %function
	.size lj_BC_FORI, 152
lj_BC_FORI:
	.long 0xe1aa00d9,0xe086b10b,0xe1ca20d8,0xe371000e
	.long 0xe59ac014,0x1a000010,0xe373000e,0xe59a3010
	.long 0x037c000e,0x1a0002fd,0xe3530000,0xba000008
	.long 0xe1500002,0xc24b6b80,0xe5d6c000,0xe496e004
	.long 0xe1ca01f8,0xe797c10c,0xe004a2ae,0xe1a0b82e
	.long 0xe12fff1c,0xe1520000,0xeafffff5,0x3373000e
	.long 0x337c000e,0x2a0002ed,0xe35c0000,0xe1ca01f8
	.long 0xba000004
	bl __aeabi_cdcmple
	.long 0x824b6b80,0xe5d6c000,0xe496e004,0xeaffffee
	.long 0xe1a02000,0xe1a03001,0xe1ca00d8,0xeafffff6

	.globl lj_BC_JFORI
	.hidden lj_BC_JFORI
	.type lj_BC_JFORI, %function
	.size lj_BC_JFORI, 168
lj_BC_JFORI:
	.long 0xe1aa00d9,0xe086b10b,0xe1ca20d8,0xe371000e
	.long 0xe59ac014,0x1a000012,0xe373000e,0xe59a3010
	.long 0x037c000e,0x1a0002d7,0xe3530000,0xba00000a
	.long 0xe1500002,0xe24b6b80,0xd156b0b2,0xe5d6c000
	.long 0xe496e004,0xe1ca01f8,0xda000095,0xe797c10c
	.long 0xe004a2ae,0xe1a0b82e,0xe12fff1c,0xe1520000
	.long 0xeafffff3,0x3373000e,0x337c000e,0x2a0002c5
	.long 0xe35c0000,0xe1ca01f8,0xba000006
	bl __aeabi_cdcmple
	.long 0xe24b6b80,0x9156b0b2,0x9a000085,0xe5d6c000
	.long 0xe496e004,0xeaffffec,0xe1a02000,0xe1a03001
	.long 0xe1ca00d8,0xeafffff4

	.globl lj_BC_FORL
	.hidden lj_BC_FORL
	.type lj_BC_FORL, %function
	.size lj_BC_FORL, 28
lj_BC_FORL:
	.long 0xe1a000a6,0xe200007e,0xe2400080,0xe19710b0
	.long 0xe2511002,0xe18710b0,0x3a000706

	.globl lj_BC_IFORL
	.hidden lj_BC_IFORL
	.type lj_BC_IFORL, %function
	.size lj_BC_IFORL, 160
lj_BC_IFORL:
	.long 0xe1aa00d9,0xe086b10b,0xe1ca21d0,0xe371000e
	.long 0x1a000010,0xe0900002,0xe59a3008,0x6286bb80
	.long 0xe3520000,0xba000009,0xe1500003,0xd24b6b80
	.long 0xe1ca00f0,0xe5d6c000,0xe496e004,0xe1ca01f8
	.long 0xe797c10c,0xe004a2ae,0xe1a0b82e,0xe12fff1c
	.long 0xe1530000,0xeafffff4,0xe3530000,0xba000008
	bl __aeabi_dadd
	.long 0xe1ca00f0,0xe1ca20d8,0xe1ca01f8
	bl __aeabi_cdcmple
	.long 0x924b6b80,0xe5d6c000,0xe496e004,0xeaffffee
	bl __aeabi_dadd
	.long 0xe1ca00f0,0xe1ca01f8,0xe1a02000,0xe1a03001
	.long 0xe1ca00d8,0xeafffff3

	.globl lj_BC_JFORL
	.hidden lj_BC_JFORL
	.type lj_BC_JFORL, %function
	.size lj_BC_JFORL, 156
lj_BC_JFORL:
	.long 0xe1aa00d9,0xe1ca21d0,0xe371000e,0x1a000010
	.long 0xe0900002,0xe59a3008,0x6a000003,0xe3520000
	.long 0xba000009,0xe1500003,0xe1ca00f0,0xe5d6c000
	.long 0xe496e004,0xe1ca01f8,0xda000040,0xe797c10c
	.long 0xe004a2ae,0xe1a0b82e,0xe12fff1c,0xe1530000
	.long 0xeafffff4,0xe3530000,0xba000008
	bl __aeabi_dadd
	.long 0xe1ca00f0,0xe1ca20d8,0xe1ca01f8
	bl __aeabi_cdcmple
	.long 0x9a000032,0xe5d6c000,0xe496e004,0xeaffffee
	bl __aeabi_dadd
	.long 0xe1ca00f0,0xe1ca01f8,0xe1a02000,0xe1a03001
	.long 0xe1ca00d8,0xeafffff3

	.globl lj_BC_ITERL
	.hidden lj_BC_ITERL
	.type lj_BC_ITERL, %function
	.size lj_BC_ITERL, 28
lj_BC_ITERL:
	.long 0xe1a000a6,0xe200007e,0xe2400080,0xe19710b0
	.long 0xe2511002,0xe18710b0,0x3a0006b0

	.globl lj_BC_IITERL
	.hidden lj_BC_IITERL
	.type lj_BC_IITERL, %function
	.size lj_BC_IITERL, 44
lj_BC_IITERL:
	.long 0xe1aa00d9,0xe086b10b,0xe3710001,0x124b6b80
	.long 0x114a00f8,0xe5d6c000,0xe496e004,0xe797c10c
	.long 0xe004a2ae,0xe1a0b82e,0xe12fff1c

	.globl lj_BC_JITERL
	.hidden lj_BC_JITERL
	.type lj_BC_JITERL, %function
	.size lj_BC_JITERL, 40
lj_BC_JITERL:
	.long 0xe1aa00d9,0xe3710001,0x114a00f8,0x1a000012
	.long 0xe5d6c000,0xe496e004,0xe797c10c,0xe004a2ae
	.long 0xe1a0b82e,0xe12fff1c

	.globl lj_BC_LOOP
	.hidden lj_BC_LOOP
	.type lj_BC_LOOP, %function
	.size lj_BC_LOOP, 28
lj_BC_LOOP:
	.long 0xe1a000a6,0xe200007e,0xe2400080,0xe19710b0
	.long 0xe2511002,0xe18710b0,0x3a000694

	.globl lj_BC_ILOOP
	.hidden lj_BC_ILOOP
	.type lj_BC_ILOOP, %function
	.size lj_BC_ILOOP, 24
lj_BC_ILOOP:
	.long 0xe5d6c000,0xe496e004,0xe797c10c,0xe004a2ae
	.long 0xe1a0b82e,0xe12fff1c

	.globl lj_BC_JLOOP
	.hidden lj_BC_JLOOP
	.type lj_BC_JLOOP, %function
	.size lj_BC_JLOOP, 32
lj_BC_JLOOP:
	.long 0xe51708a0,0xe3a01000,0xe790b10b,0xe5071ae4
	.long 0xe59ba034,0xe5079a50,0xe5078ad4,0xe12fff1a

	.globl lj_BC_JMP
	.hidden lj_BC_JMP
	.type lj_BC_JMP, %function
	.size lj_BC_JMP, 32
lj_BC_JMP:
	.long 0xe086b10b,0xe24b6b80,0xe5d6c000,0xe496e004
	.long 0xe797c10c,0xe004a2ae,0xe1a0b82e,0xe12fff1c

	.globl lj_BC_FUNCF
	.hidden lj_BC_FUNCF
	.type lj_BC_FUNCF, %function
	.size lj_BC_FUNCF, 28
lj_BC_FUNCF:
	.long 0xe1a000a6,0xe200007e,0xe2400080,0xe19710b0
	.long 0xe2511001,0xe18710b0,0x3a000685

	.globl lj_BC_IFUNCF
	.hidden lj_BC_IFUNCF
	.type lj_BC_IFUNCF, %function
	.size lj_BC_IFUNCF, 68
lj_BC_IFUNCF:
	.long 0xe5980018,0xe556103e,0xe5165034,0xe15a0000
	.long 0x8a0000b9,0xe5d6c000,0xe496e004,0xe15b0181
	.long 0xe3e03000,0x3a000003,0xe797c10c,0xe004a2ae
	.long 0xe1a0b82e,0xe12fff1c,0xe18920fb,0xe28bb008
	.long 0xeafffff5

	.globl lj_BC_JFUNCF
	.hidden lj_BC_JFUNCF
	.type lj_BC_JFUNCF, %function
	.size lj_BC_JFUNCF, 52
lj_BC_JFUNCF:
	.long 0xe5980018,0xe556103e,0xe5165034,0xe15a0000
	.long 0x8a0000a8,0xe15b0181,0xe3e03000,0x3a000001
	.long 0xe1a0b82e,0xeaffffcd,0xe18920fb,0xe28bb008
	.long 0xeafffff7

	.globl lj_BC_FUNCV
	.hidden lj_BC_FUNCV
	.type lj_BC_FUNCV, %function
	.size lj_BC_FUNCV, 0
lj_BC_FUNCV:

	.globl lj_BC_IFUNCV
	.hidden lj_BC_IFUNCV
	.type lj_BC_IFUNCV, %function
	.size lj_BC_IFUNCV, 116
lj_BC_IFUNCV:
	.long 0xe5980018,0xe089300b,0xe08aa00b,0xe5832000
	.long 0xe28b100b,0xe5165034,0xe15a0000,0xe5831004
	.long 0x2a000097,0xe556c03e,0xe1a0a009,0xe1a0b003
	.long 0xe35c0000,0xe2839008,0x0a000007,0xe3e02000
	.long 0xe15a000b,0x30ca00d8,0x21a01002,0x350a2004
	.long 0xe25cc001,0xe1e300f8,0x1afffff8,0xe5d6c000
	.long 0xe496e004,0xe797c10c,0xe004a2ae,0xe1a0b82e
	.long 0xe12fff1c

	.globl lj_BC_JFUNCV
	.hidden lj_BC_JFUNCV
	.type lj_BC_JFUNCV, %function
	.size lj_BC_JFUNCV, 4
lj_BC_JFUNCV:
	.long 0xe7f001f0

	.globl lj_BC_FUNCC
	.hidden lj_BC_FUNCC
	.type lj_BC_FUNCC, %function
	.size lj_BC_FUNCC, 84
lj_BC_FUNCC:
	.long 0xe5923014,0xe08a100b,0xe5980018,0xe089b00b
	.long 0xe5889010,0xe1510000,0xe588b014,0xe3e02001
	.long 0xe1a00008,0x8a000076,0xe5072ae4,0xe12fff33
	.long 0xe5989010,0xe3e02000,0xe5981014,0xe5078a54
	.long 0xe1a0b180,0xe5072ae4,0xe5196004,0xe041a00b
	.long 0xea00001c

	.globl lj_BC_FUNCCW
	.hidden lj_BC_FUNCCW
	.type lj_BC_FUNCCW, %function
	.size lj_BC_FUNCCW, 88
lj_BC_FUNCCW:
	.long 0xe5173a64,0xe08a100b,0xe5980018,0xe089b00b
	.long 0xe5889010,0xe1510000,0xe588b014,0xe5921014
	.long 0xe3e02001,0xe1a00008,0x8a000060,0xe5072ae4
	.long 0xe12fff33,0xe5989010,0xe3e02000,0xe5981014
	.long 0xe5078a54,0xe1a0b180,0xe5072ae4,0xe5196004
	.long 0xe041a00b,0xea000006

	.globl lj_vm_returnp
	.hidden lj_vm_returnp
	.type lj_vm_returnp, %function
	.size lj_vm_returnp, 28
lj_vm_returnp:
	.long 0xe3160004,0x0a0000c7,0xe51c6004,0xe3e01002
	.long 0xe1a0900c,0xe50a1004,0xe24aa008

	.globl lj_vm_returnc
	.hidden lj_vm_returnc
	.type lj_vm_returnc, %function
	.size lj_vm_returnc, 24
lj_vm_returnc:
	.long 0xe29bb008,0xe3a00001,0x0a00002f,0xe58db004
	.long 0xe2160003,0x0afffe4a

	.globl lj_vm_return
	.hidden lj_vm_return
	.type lj_vm_return, %function
	.size lj_vm_return, 76
lj_vm_return:
	.long 0xe3c6c007,0xe3500001,0xe049c00c,0x1affffee
	.long 0xe588c010,0xe59d5014,0xe3e03001,0xe2499008
	.long 0xe25b2008,0xe1a05185,0xe5073ae4,0x0a000003
	.long 0xe2522008,0xe0ca00d8,0xe0c900f8,0x1afffffb
	.long 0xe155000b,0x1a000005,0xe5889014

	.globl lj_vm_leave_cp
	.hidden lj_vm_leave_cp
	.type lj_vm_leave_cp, %function
	.size lj_vm_leave_cp, 12
lj_vm_leave_cp:
	.long 0xe59db010,0xe3a00000,0xe588b028

	.globl lj_vm_leave_unw
	.hidden lj_vm_leave_unw
	.type lj_vm_leave_unw, %function
	.size lj_vm_leave_unw, 84
lj_vm_leave_unw:
	.long 0xe28dd01c,0xe8bd8ff0,0xba000007,0xe5982018
	.long 0xe3e01000,0xe1590002,0x2a000007,0xe5891004
	.long 0xe28bb008,0xe2899008,0xeaffffee,0xe04b0005
	.long 0xe3550000,0x10499000,0xeaffffec,0xe5889014
	.long 0xe1a011a5,0xe1a00008
	bl lj_state_growstack
	.long 0xe5989014,0xeaffffe4

	.globl lj_vm_unwind_c
	.hidden lj_vm_unwind_c
	.type lj_vm_unwind_c, %function
	.size lj_vm_unwind_c, 8
lj_vm_unwind_c:
	.long 0xe1a0d000,0xe1a00001

	.globl lj_vm_unwind_c_eh
	.hidden lj_vm_unwind_c_eh
	.type lj_vm_unwind_c_eh, %function
	.size lj_vm_unwind_c_eh, 20
lj_vm_unwind_c_eh:
	.long 0xe59d800c,0xe3e03001,0xe5982008,0xe582304c
	.long 0xeaffffe3

	.globl lj_vm_unwind_ff
	.hidden lj_vm_unwind_ff
	.type lj_vm_unwind_ff, %function
	.size lj_vm_unwind_ff, 8
lj_vm_unwind_ff:
	.long 0xe3c00003,0xe1a0d000

	.globl lj_vm_unwind_ff_eh
	.hidden lj_vm_unwind_ff_eh
	.type lj_vm_unwind_ff_eh, %function
	.size lj_vm_unwind_ff_eh, 56
lj_vm_unwind_ff_eh:
	.long 0xe59d800c,0xe3a040ff,0xe3a0b010,0xe1a04184
	.long 0xe5989010,0xe5987008,0xe3e00001,0xe249a008
	.long 0xe5196004,0xe2877eb3,0xe3e01000,0xe5090004
	.long 0xe5071ae4,0xeaffffb7

	.globl lj_vm_unwind_ext
	.hidden lj_vm_unwind_ext
	.type lj_vm_unwind_ext, %function
	.size lj_vm_unwind_ext, 28
lj_vm_unwind_ext:
	.long 0xe92d4007
	bl _Unwind_Complete
	.long 0xe59d0000
	bl _Unwind_DeleteException
	.long 0xe8bd4007,0xe1a00001,0xe12fff12

	.globl lj_vm_growstack_c
	.hidden lj_vm_growstack_c
	.type lj_vm_growstack_c, %function
	.size lj_vm_growstack_c, 8
lj_vm_growstack_c:
	.long 0xe3a01014,0xea000006

	.globl lj_vm_growstack_l
	.hidden lj_vm_growstack_l
	.type lj_vm_growstack_l, %function
	.size lj_vm_growstack_l, 80
lj_vm_growstack_l:
	.long 0xe089b00b,0xe04aa009,0xe1a00008,0xe5889010
	.long 0xe2866004,0xe588b014,0xe1a011aa,0xe58d6008
	bl lj_state_growstack
	.long 0xe5989010,0xe598b014,0xe5192008,0xe04bb009
	.long 0xe5926010,0xe5d6c000,0xe496e004,0xe797c10c
	.long 0xe004a2ae,0xe08aa009,0xe12fff1c

	.globl lj_vm_resume
	.hidden lj_vm_resume
	.type lj_vm_resume, %function
	.size lj_vm_resume, 132
lj_vm_resume:
	.long 0xe92d4ff0,0xe24dd01c,0xe1a08000,0xe5907008
	.long 0xe1a09001,0xe2877eb3,0xe58d800c,0xe3a06005
	.long 0xe58d2014,0xe28d1001,0xe5d80007,0xe58d2018
	.long 0xe58d8008,0xe58d2010,0xe3500000,0xe5881028
	.long 0x0a000021,0xe5078a54,0xe1a0a009,0xe5989010
	.long 0xe5980014,0xe3a040ff,0xe5c82007,0xe040b009
	.long 0xe5196004,0xe1a04184,0xe3e01000,0xe28bb008
	.long 0xe2160003,0xe5071ae4,0xe58db004,0x0afffdcb
	.long 0xeaffff7f

	.globl lj_vm_pcall
	.hidden lj_vm_pcall
	.type lj_vm_pcall, %function
	.size lj_vm_pcall, 20
lj_vm_pcall:
	.long 0xe92d4ff0,0xe24dd01c,0xe3a06005,0xe58d3018
	.long 0xea000002

	.globl lj_vm_call
	.hidden lj_vm_call
	.type lj_vm_call, %function
	.size lj_vm_call, 92
lj_vm_call:
	.long 0xe92d4ff0,0xe24dd01c,0xe3a06001,0xe590b028
	.long 0xe58d2014,0xe1a08000,0xe58d000c,0xe5987008
	.long 0xe1a09001,0xe58d0008,0xe58db010,0xe2877eb3
	.long 0xe588d028,0xe5078a54,0xe598c010,0xe5980014
	.long 0xe3a040ff,0xe0866009,0xe1a04184,0xe046600c
	.long 0xe3e01000,0xe040b009,0xe5071ae4

	.globl lj_vm_call_dispatch
	.hidden lj_vm_call_dispatch
	.type lj_vm_call_dispatch, %function
	.size lj_vm_call_dispatch, 12
lj_vm_call_dispatch:
	.long 0xe14920d8,0xe3730009,0x1a0000f4

	.globl lj_vm_call_dispatch_f
	.hidden lj_vm_call_dispatch_f
	.type lj_vm_call_dispatch_f, %function
	.size lj_vm_call_dispatch_f, 32
lj_vm_call_dispatch_f:
	.long 0xe5096004,0xe5926010,0xe5d6c000,0xe496e004
	.long 0xe797c10c,0xe004a2ae,0xe08aa009,0xe12fff1c

	.globl lj_vm_cpcall
	.hidden lj_vm_cpcall
	.type lj_vm_cpcall, %function
	.size lj_vm_cpcall, 88
lj_vm_cpcall:
	.long 0xe92d4ff0,0xe24dd01c,0xe1a08000,0xe590a01c
	.long 0xe58d000c,0xe5987008,0xe598c014,0xe58d0008
	.long 0xe598b028,0xe2877eb3,0xe04aa00c,0xe3a0c000
	.long 0xe58da014,0xe58dc018,0xe58db010,0xe588d028
	.long 0xe5078a54,0xe12fff33,0xe1b09000,0xe3a06005
	.long 0x1affffd5,0xeaffff55

	.globl lj_cont_dispatch
	.hidden lj_cont_dispatch
	.type lj_cont_dispatch, %function
	.size lj_cont_dispatch, 68
lj_cont_dispatch:
	.long 0xe51c2008,0xe5190010,0xe1a03009,0xe1a0900c
	.long 0xe3500001,0xe513600c,0xe5922010,0xe3e0e000
	.long 0xe08a100b,0xe501e004,0x9a000001,0xe5125030
	.long 0xe12fff10,0x0a00068f,0xe2433010,0xe043b009
	.long 0xea0004f3

	.globl lj_cont_cat
	.hidden lj_cont_cat
	.type lj_cont_cat, %function
	.size lj_cont_cat, 52
lj_cont_cat:
	.long 0xe516e004,0xe2431010,0xe1ca20d0,0xe5889010
	.long 0xe004baae,0xe004a2ae,0xe089000b,0xe0510000
	.long 0x11c120f0,0x11a02000,0x1afffa3c,0xe18920fa
	.long 0xea000069

	.globl lj_vmeta_tgets1
	.hidden lj_vmeta_tgets1
	.type lj_vmeta_tgets1, %function
	.size lj_vmeta_tgets1, 8
lj_vmeta_tgets1:
	.long 0xe089100c,0xea000003

	.globl lj_vmeta_tgets
	.hidden lj_vmeta_tgets
	.type lj_vmeta_tgets, %function
	.size lj_vmeta_tgets, 36
lj_vmeta_tgets:
	.long 0xe2471eab,0xe3e0300b,0xe581c000,0xe5813004
	.long 0xe3e03004,0xe58db000,0xe58d3004,0xe1a0200d
	.long 0xea000008

	.globl lj_vmeta_tgetb
	.hidden lj_vmeta_tgetb
	.type lj_vmeta_tgetb, %function
	.size lj_vmeta_tgetb, 28
lj_vmeta_tgetb:
	.long 0xe004caae,0xe58db000,0xe3e0300d,0xe089100c
	.long 0xe58d3004,0xe1a0200d,0xea000001

	.globl lj_vmeta_tgetv
	.hidden lj_vmeta_tgetv
	.type lj_vmeta_tgetv, %function
	.size lj_vmeta_tgetv, 92
lj_vmeta_tgetv:
	.long 0xe089100c,0xe089200b,0xe5889010,0xe1a00008
	.long 0xe58d6008
	bl lj_meta_tget
	.long 0xe3500000,0x0a000007,0xe1c020d0,0xe5d6c000
	.long 0xe496e004,0xe18920fa,0xe797c10c,0xe004a2ae
	.long 0xe1a0b82e,0xe12fff1c,0xe2690002,0xe5989014
	.long 0xe3a0b010,0xe509600c,0xe0806009,0xe5192008
	.long 0xeaffff9a

	.globl lj_vmeta_tgetr
	.hidden lj_vmeta_tgetr
	.type lj_vmeta_tgetr, %function
	.size lj_vmeta_tgetr, 20
lj_vmeta_tgetr:
	bl lj_tab_getinth
	.long 0xe3500000,0x11c000d0,0x03e01000,0xeafffb7f

	.globl lj_vmeta_tsets1
	.hidden lj_vmeta_tsets1
	.type lj_vmeta_tsets1, %function
	.size lj_vmeta_tsets1, 8
lj_vmeta_tsets1:
	.long 0xe089100c,0xea000003

	.globl lj_vmeta_tsets
	.hidden lj_vmeta_tsets
	.type lj_vmeta_tsets, %function
	.size lj_vmeta_tsets, 36
lj_vmeta_tsets:
	.long 0xe2471eab,0xe3e0300b,0xe581c000,0xe5813004
	.long 0xe3e03004,0xe58db000,0xe58d3004,0xe1a0200d
	.long 0xea000008

	.globl lj_vmeta_tsetb
	.hidden lj_vmeta_tsetb
	.type lj_vmeta_tsetb, %function
	.size lj_vmeta_tsetb, 28
lj_vmeta_tsetb:
	.long 0xe004caae,0xe58db000,0xe3e0300d,0xe089100c
	.long 0xe58d3004,0xe1a0200d,0xea000001

	.globl lj_vmeta_tsetv
	.hidden lj_vmeta_tsetv
	.type lj_vmeta_tsetv, %function
	.size lj_vmeta_tsetv, 96
lj_vmeta_tsetv:
	.long 0xe089100c,0xe089200b,0xe5889010,0xe1a00008
	.long 0xe58d6008
	bl lj_meta_tset
	.long 0xe3500000,0xe18920da,0x0a000006,0xe5d6c000
	.long 0xe1c020f0,0xe496e004,0xe797c10c,0xe004a2ae
	.long 0xe1a0b82e,0xe12fff1c,0xe2690002,0xe5989014
	.long 0xe3a0b018,0xe1c921f0,0xe509600c,0xe0806009
	.long 0xe5192008,0xeaffff6b

	.globl lj_vmeta_tsetr
	.hidden lj_vmeta_tsetr
	.type lj_vmeta_tsetr, %function
	.size lj_vmeta_tsetr, 16
lj_vmeta_tsetr:
	.long 0xe5889010,0xe58d6008
	bl lj_tab_setinth
	.long 0xeafffc24

	.globl lj_vmeta_comp
	.hidden lj_vmeta_comp
	.type lj_vmeta_comp, %function
	.size lj_vmeta_comp, 56
lj_vmeta_comp:
	.long 0xe1a00008,0xe2466004,0xe1a0100a,0xe5889010
	.long 0xe1a0200b,0xe58d6008,0xe20e30ff
	bl lj_meta_comp
	.long 0xe3500001,0x8a000046,0xe1d6c0b2,0xe2866004
	.long 0xe086c10c,0x224c6b80

	.globl lj_cont_nop
	.hidden lj_cont_nop
	.type lj_cont_nop, %function
	.size lj_cont_nop, 24
lj_cont_nop:
	.long 0xe5d6c000,0xe496e004,0xe797c10c,0xe004a2ae
	.long 0xe1a0b82e,0xe12fff1c

	.globl lj_cont_ra
	.hidden lj_cont_ra
	.type lj_cont_ra, %function
	.size lj_cont_ra, 20
lj_cont_ra:
	.long 0xe516e004,0xe1ca00d0,0xe00422ae,0xe18900f2
	.long 0xeafffff4

	.globl lj_cont_condt
	.hidden lj_cont_condt
	.type lj_cont_condt, %function
	.size lj_cont_condt, 16
lj_cont_condt:
	.long 0xe59a1004,0xe3e00002,0xe1500001,0xeaffffec

	.globl lj_cont_condf
	.hidden lj_cont_condf
	.type lj_cont_condf, %function
	.size lj_cont_condf, 12
lj_cont_condf:
	.long 0xe59a1004,0xe3710002,0xeaffffe9

	.globl lj_vmeta_equal
	.hidden lj_vmeta_equal
	.type lj_vmeta_equal, %function
	.size lj_vmeta_equal, 24
lj_vmeta_equal:
	.long 0xe2466004,0xe5889010,0xe1a00008,0xe58d6008
	bl lj_meta_equal
	.long 0xeaffffe1

	.globl lj_vmeta_equal_cd
	.hidden lj_vmeta_equal_cd
	.type lj_vmeta_equal_cd, %function
	.size lj_vmeta_equal_cd, 28
lj_vmeta_equal_cd:
	.long 0xe2466004,0xe5889010,0xe1a00008,0xe1a0100e
	.long 0xe58d6008
	bl lj_meta_equal_cd
	.long 0xeaffffda

	.globl lj_vmeta_istype
	.hidden lj_vmeta_istype
	.type lj_vmeta_istype, %function
	.size lj_vmeta_istype, 32
lj_vmeta_istype:
	.long 0xe2466004,0xe5889010,0xe1a00008,0xe1a011aa
	.long 0xe1a0200b,0xe58d6008
	bl lj_meta_istype
	.long 0xeaffffd8

	.globl lj_vmeta_arith_vn
	.hidden lj_vmeta_arith_vn
	.type lj_vmeta_arith_vn, %function
	.size lj_vmeta_arith_vn, 20
lj_vmeta_arith_vn:
	.long 0xe004caae,0xe004b6ae,0xe089200c,0xe085300b
	.long 0xea00000d

	.globl lj_vmeta_arith_nv
	.hidden lj_vmeta_arith_nv
	.type lj_vmeta_arith_nv, %function
	.size lj_vmeta_arith_nv, 20
lj_vmeta_arith_nv:
	.long 0xe004caae,0xe004b6ae,0xe089300c,0xe085200b
	.long 0xea000008

	.globl lj_vmeta_unm
	.hidden lj_vmeta_unm
	.type lj_vmeta_unm, %function
	.size lj_vmeta_unm, 20
lj_vmeta_unm:
	.long 0xe516e008,0xe2466004,0xe089200b,0xe089300b
	.long 0xea000003

	.globl lj_vmeta_arith_vv
	.hidden lj_vmeta_arith_vv
	.type lj_vmeta_arith_vv, %function
	.size lj_vmeta_arith_vv, 52
lj_vmeta_arith_vv:
	.long 0xe004caae,0xe004b6ae,0xe089200c,0xe089300b
	.long 0xe20ec0ff,0xe089100a,0xe5889010,0xe1a00008
	.long 0xe58d6008,0xe58dc000
	bl lj_meta_arith
	.long 0xe3500000,0x0affffbc

	.globl lj_vmeta_binop
	.hidden lj_vmeta_binop
	.type lj_vmeta_binop, %function
	.size lj_vmeta_binop, 24
lj_vmeta_binop:
	.long 0xe0401009,0xe500600c,0xe2816002,0xe1a09000
	.long 0xe3a0b010,0xeaffff0d

	.globl lj_vmeta_len
	.hidden lj_vmeta_len
	.type lj_vmeta_len, %function
	.size lj_vmeta_len, 24
lj_vmeta_len:
	.long 0xe089100b,0xe5889010,0xe1a00008,0xe58d6008
	bl lj_meta_len
	.long 0xeafffff3

	.globl lj_vmeta_call
	.hidden lj_vmeta_call
	.type lj_vmeta_call, %function
	.size lj_vmeta_call, 64
lj_vmeta_call:
	.long 0xe1a00008,0xe588c010,0xe2491008,0xe58d6008
	.long 0xe089200b
	bl lj_meta_call
	.long 0xe5192008,0xe28bb008,0xe5096004,0xe5926010
	.long 0xe5d6c000,0xe496e004,0xe797c10c,0xe004a2ae
	.long 0xe08aa009,0xe12fff1c

	.globl lj_vmeta_callt
	.hidden lj_vmeta_callt
	.type lj_vmeta_callt, %function
	.size lj_vmeta_callt, 40
lj_vmeta_callt:
	.long 0xe1a00008,0xe5889010,0xe24a1008,0xe58d6008
	.long 0xe08a200b
	bl lj_meta_call
	.long 0xe51a2008,0xe5196004,0xe28bb008,0xeafffbd8

	.globl lj_vmeta_for
	.hidden lj_vmeta_for
	.type lj_vmeta_for, %function
	.size lj_vmeta_for, 48
lj_vmeta_for:
	.long 0xe1a00008,0xe5889010,0xe1a0100a,0xe58d6008
	bl lj_meta_for
	.long 0xe556c004,0xe516e004,0xe35c004e,0xe004a2ae
	.long 0xe1a0b82e,0x0afffd12,0xeafffceb

	.globl lj_ff_assert
	.hidden lj_ff_assert
	.type lj_ff_assert, %function
	.size lj_ff_assert, 64
lj_ff_assert:
	.long 0xe1c900d0,0xe35b0008,0x3a0003e7,0xe3710003
	.long 0x8a0003e5,0xe5196004,0xe14900f8,0xe1a0c009
	.long 0xe25ba008,0xe28bb008,0x0a0001cd,0xe1cc00d8
	.long 0xe25aa008,0xe0cc00f8,0x1afffffb,0xea0001c8

	.globl lj_ff_type
	.hidden lj_ff_type
	.type lj_ff_type, %function
	.size lj_ff_type, 36
lj_ff_type:
	.long 0xe5991004,0xe35b0008,0x3a0003d7,0xe371000e
	.long 0x33e0100d,0xe2613002,0xe1a03183,0xe18200d3
	.long 0xea0001bc

	.globl lj_ff_getmetatable
	.hidden lj_ff_getmetatable
	.type lj_ff_getmetatable, %function
	.size lj_ff_getmetatable, 148
lj_ff_getmetatable:
	.long 0xe1c900d0,0xe35b0008,0x3a0003ce,0xe371000c
	.long 0x1371000d,0x1a000018,0xe590c010,0xe3e01000
	.long 0xe517ba04,0xe35c0000,0x0a0001b1,0xe59c201c
	.long 0xe59b3008,0xe59ce014,0xe0022003,0xe0822082
	.long 0xe08ee182,0xe1ce20d8,0xe1ce00d0,0xe59ee010
	.long 0xe3730005,0x0152000b,0x0a000004,0xe35e0000
	.long 0x1afffff7,0xe1a0000c,0xe3e0100b,0xea0001a0
	.long 0xe3710001,0x1a00019e,0xeafffff9,0xe371000e
	.long 0x21e01001,0x33a0100d,0xe0873101,0xe513c9f0
	.long 0xeaffffe1

	.globl lj_ff_setmetatable
	.hidden lj_ff_setmetatable
	.type lj_ff_setmetatable, %function
	.size lj_ff_setmetatable, 76
lj_ff_setmetatable:
	.long 0xe1c900d0,0xe1c920d8,0xe35b0010,0x3a0003a8
	.long 0xe371000c,0x0590c010,0x0373000c,0x05d03004
	.long 0x035c0000,0x1a0003a2,0xe3130004,0xe5802010
	.long 0x0a00018a,0xe5172b00,0xe3c33004,0xe5070b00
	.long 0xe5c03004,0xe580200c,0xea000184

	.globl lj_ff_rawget
	.hidden lj_ff_rawget
	.type lj_ff_rawget, %function
	.size lj_ff_rawget, 44
lj_ff_rawget:
	.long 0xe1c920d0,0xe35b0010,0x3a000396,0xe1a01002
	.long 0xe373000c,0x1a000393,0xe1a00008,0xe2892008
	bl lj_tab_get
	.long 0xe1c000d0,0xea000179

	.globl lj_ff_tonumber
	.hidden lj_ff_tonumber
	.type lj_ff_tonumber, %function
	.size lj_ff_tonumber, 24
lj_ff_tonumber:
	.long 0xe1c900d0,0xe35b0008,0x1a00038b,0xe371000e
	.long 0x9a000174,0xea000388

	.globl lj_ff_tostring
	.hidden lj_ff_tostring
	.type lj_ff_tostring, %function
	.size lj_ff_tostring, 84
lj_ff_tostring:
	.long 0xe1c900d0,0xe35b0008,0x3a000385,0xe3710005
	.long 0x0a00016e,0xe51739bc,0xe5889010,0xe371000e
	.long 0x93530000,0xe58d6008,0x8a00037d,0xe5170b1c
	.long 0xe5171b18,0xe1500001,0xab0003a2,0xe1a00008
	.long 0xe1a01009
	bl lj_strfmt_number
	.long 0xe5989010,0xe3e01004,0xea00015e

	.globl lj_ff_next
	.hidden lj_ff_next
	.type lj_ff_next, %function
	.size lj_ff_next, 96
lj_ff_next:
	.long 0xe1c900d0,0xe35b0008,0x3a000370,0xe3e03000
	.long 0xe371000c,0x1a00036d,0xe18920fb,0xe5196004
	.long 0xe1a01000,0xe5889010,0xe1a00008,0xe5889014
	.long 0xe2892008,0xe58d6008
	bl lj_tab_next
	.long 0xe3500000,0x03e01000,0x0a00014c,0xe1c900d8
	.long 0xe1c921d0,0xe3a0b018,0xe14900f8,0xe1c920f0
	.long 0xea000149

	.globl lj_ff_pairs
	.hidden lj_ff_pairs
	.type lj_ff_pairs, %function
	.size lj_ff_pairs, 48
lj_ff_pairs:
	.long 0xe1c900d0,0xe35b0008,0x3a000358,0xe371000c
	.long 0x1a000356,0xe1c221d8,0xe5196004,0xe3e01000
	.long 0xe3a0b020,0xe14920f8,0xe589100c,0xea00013d

	.globl lj_ff_ipairs_aux
	.hidden lj_ff_ipairs_aux
	.type lj_ff_ipairs_aux, %function
	.size lj_ff_ipairs_aux, 120
lj_ff_ipairs_aux:
	.long 0xe1c900d0,0xe1c920d8,0xe35b0010,0x3a00034b
	.long 0xe371000c,0x0373000e,0x1a000348,0xe590c018
	.long 0xe590b008,0xe2822001,0xe5196004,0xe152000c
	.long 0xe08bb182,0xe14920f8,0x31cb00d0,0xe3a0b008
	.long 0x2a000003,0xe3710001,0x13a0b018,0x11c900f0
	.long 0xea000128,0xe590c01c,0xe1a01002,0xe35c0000
	.long 0x0a000124
	bl lj_tab_getinth
	.long 0xe3500000,0x0a000121,0xe1c000d0,0xeafffff2

	.globl lj_ff_ipairs
	.hidden lj_ff_ipairs
	.type lj_ff_ipairs, %function
	.size lj_ff_ipairs, 52
lj_ff_ipairs:
	.long 0xe1c900d0,0xe35b0008,0x3a00032e,0xe371000c
	.long 0x1a00032c,0xe1c221d8,0xe5196004,0xe3a00000
	.long 0xe3e0100d,0xe3a0b020,0xe14920f8,0xe1c900f8
	.long 0xea000112

	.globl lj_ff_pcall
	.hidden lj_ff_pcall
	.type lj_ff_pcall, %function
	.size lj_ff_pcall, 40
lj_ff_pcall:
	.long 0xe557aabf,0xe35b0008,0x3a000321,0xe31a0010
	.long 0xe1a0c009,0xe2899008,0x03a0600e,0x13a0600f
	.long 0xe24bb008,0xeafffe11

	.globl lj_ff_xpcall
	.hidden lj_ff_xpcall
	.type lj_ff_xpcall, %function
	.size lj_ff_xpcall, 64
lj_ff_xpcall:
	.long 0xe1c900d0,0xe1c920d8,0xe35b0010,0x3a000316
	.long 0xe557aabf,0xe3730009,0x1a000313,0xe1a0c009
	.long 0xe1c900f8,0xe1c920f0,0xe31a0010,0xe2899010
	.long 0x03a06016,0x13a06017,0xe24bb010,0xeafffe01

	.globl lj_ff_coroutine_resume
	.hidden lj_ff_coroutine_resume
	.type lj_ff_coroutine_resume, %function
	.size lj_ff_coroutine_resume, 308
lj_ff_coroutine_resume:
	.long 0xe1c900d0,0xe35b0008,0x3a000307,0xe3710007
	.long 0x1a000305,0xe5196004,0xe5889010,0xe5901014
	.long 0xe5d0a007,0xe590c010,0xe081200b,0xe081300a
	.long 0xe58d6008,0xe153000c,0x0a0002fb,0xe5903018
	.long 0xe590c028,0xe35a0001,0x91520003,0x935c0000
	.long 0x8a0002f5,0xe2422008,0xe2899008,0xe24bb008
	.long 0xe5802014,0xe5889014,0xe18920dc,0xe15c000b
	.long 0x118120fc,0xe28cc008,0x1afffffa,0xe3a02000
	.long 0xe1a0a000,0xe3a03000,0xebfffda1,0xe59a2010
	.long 0xe3e01000,0xe59a3014,0xe3500001,0xe5989010
	.long 0xe5078a54,0xe5071ae4,0x8a000016,0xe053b002
	.long 0xe5980018,0xe089100b,0x0a000009,0xe1510000
	.long 0xe3a0c000,0x8a000015,0xe24b3008,0xe58a2014
	.long 0xe18200dc,0xe15c0003,0xe18900fc,0xe28cc008
	.long 0x1afffffa,0xe3e02002,0xe28bb010,0xe5092004
	.long 0xe249a008,0xe2160003,0xe58d6008,0xe58db004
	.long 0x0afffb6f,0xeafffd23,0xe16300d8,0xe3e02001
	.long 0xe3a0b018,0xe58a3014,0xe1c900f0,0xeafffff2
	.long 0xe1a00008,0xe1a011ab
	bl lj_state_growstack
	.long 0xe3a00000,0xeaffffd5

	.globl lj_ff_coroutine_wrap_aux
	.hidden lj_ff_coroutine_wrap_aux
	.type lj_ff_coroutine_wrap_aux, %function
	.size lj_ff_coroutine_wrap_aux, 260
lj_ff_coroutine_wrap_aux:
	.long 0xe5920018,0xe5196004,0xe5889010,0xe5901014
	.long 0xe5d0a007,0xe590c010,0xe081200b,0xe081300a
	.long 0xe58d6008,0xe153000c,0x0a0002b2,0xe5903018
	.long 0xe590c028,0xe35a0001,0x91520003,0x935c0000
	.long 0x8a0002ac,0xe5802014,0xe5889014,0xe18920dc
	.long 0xe15c000b,0x118120fc,0xe28cc008,0x1afffffa
	.long 0xe3a02000,0xe1a0a000,0xe3a03000,0xebfffd5b
	.long 0xe59a2010,0xe3e01000,0xe59a3014,0xe3500001
	.long 0xe5989010,0xe5078a54,0xe5071ae4,0x8a000014
	.long 0xe053b002,0xe5980018,0xe089100b,0x0a000009
	.long 0xe1510000,0xe3a0c000,0x8a000010,0xe24b3008
	.long 0xe58a2014,0xe18200dc,0xe15c0003,0xe18900fc
	.long 0xe28cc008,0x1afffffa,0xe1a0a009,0xe28bb008
	.long 0xe2160003,0xe58d6008,0xe58db004,0x0afffb2b
	.long 0xeafffcdf,0xe1a00008,0xe1a0100a
	bl lj_ffh_coroutine_wrap_err
	.long 0xe1a00008,0xe1a011ab
	bl lj_state_growstack
	.long 0xe3a00000,0xeaffffda

	.globl lj_ff_coroutine_yield
	.hidden lj_ff_coroutine_yield
	.type lj_ff_coroutine_yield, %function
	.size lj_ff_coroutine_yield, 44
lj_ff_coroutine_yield:
	.long 0xe5980028,0xe089100b,0xe5889010,0xe3100001
	.long 0xe5881014,0xe3a00001,0xe3a02000,0x0a000274
	.long 0xe5882028,0xe5c80007,0xeafffce2

	.globl lj_ff_math_floor
	.hidden lj_ff_math_floor
	.type lj_ff_math_floor, %function
	.size lj_ff_math_floor, 160
lj_ff_math_floor:
	.long 0xe1c900d0,0xe35b0008,0x3a00026e,0xe371000e
	.long 0x0a000057,0x8a00026b,0xe1a02081,0xe292c980
	.long 0x5a00000f,0xe3e03ff8,0xe053cacc,0xe1a03581
	.long 0xe1a02580,0xe3833480,0xe26ce020,0xe1833aa0
	.long 0x9a00000e,0xe1822e13,0xe1a00c33,0xe1120fc1
	.long 0x12800001,0xe3510000,0xb2600000,0xe3e0100d
	.long 0xea000043,0x2a000042,0xe1822000,0xe1120fc1
	.long 0x03a00000,0x13e00000,0xe3e0100d,0xea00003c
	.long 0x03530480,0x03520000,0x1a000002,0xe3510000
	.long 0x43a00480,0x4afffff0,0xeb000335,0xea000034

	.globl lj_ff_math_ceil
	.hidden lj_ff_math_ceil
	.type lj_ff_math_ceil, %function
	.size lj_ff_math_ceil, 172
lj_ff_math_ceil:
	.long 0xe1c900d0,0xe35b0008,0x3a000246,0xe371000e
	.long 0x0a00002f,0x8a000243,0xe1a02081,0xe292c980
	.long 0x5a000011,0xe3e03ff8,0xe053cacc,0xe1a03581
	.long 0xe1a02580,0xe3833480,0xe26ce020,0xe1833aa0
	.long 0x9a000010,0xe1822e13,0xe1a00c33,0xe1d22fc1
	.long 0x12900001,0x61cf04d8,0x6a00001d,0xe3510000
	.long 0xb2600000,0xe3e0100d,0xea000019,0x2a000018
	.long 0xe1822000,0xe1d22fc1,0x03a00000,0x13a00001
	.long 0xe3e0100d,0xea000012,0x03530480,0x1a000002
	.long 0xe3510000,0x43a00480,0x4afffff1,0xeb00032c
	.long 0xea00000b,0x00000000,0x41e00000

	.globl lj_ff_math_abs
	.hidden lj_ff_math_abs
	.type lj_ff_math_abs, %function
	.size lj_ff_math_abs, 40
lj_ff_math_abs:
	.long 0xe1c900d0,0xe35b0008,0x3a00021b,0xe371000e
	.long 0x8a000219,0x13c11480,0x1a000002,0xe3500000
	.long 0xb2700000,0x614f03d4

	.globl lj_fff_restv
	.hidden lj_fff_restv
	.type lj_fff_restv, %function
	.size lj_fff_restv, 8
lj_fff_restv:
	.long 0xe5196004,0xe14900f8

	.globl lj_fff_res1
	.hidden lj_fff_res1
	.type lj_fff_res1, %function
	.size lj_fff_res1, 4
lj_fff_res1:
	.long 0xe3a0b010

	.globl lj_fff_res
	.hidden lj_fff_res
	.type lj_fff_res, %function
	.size lj_fff_res, 84
lj_fff_res:
	.long 0xe2160003,0x0516e004,0xe58db004,0xe249a008
	.long 0x1afffc67,0xe004caae,0xe15c000b,0x8a000007
	.long 0xe00402ae,0xe5d6c000,0xe496e004,0xe04a9000
	.long 0xe797c10c,0xe004a2ae,0xe1a0b82e,0xe12fff1c
	.long 0xe08a100b,0xe3e00000,0xe28bb008,0xe5010004
	.long 0xeafffff0

	.globl lj_ff_math_sqrt
	.hidden lj_ff_math_sqrt
	.type lj_ff_math_sqrt, %function
	.size lj_ff_math_sqrt, 28
lj_ff_math_sqrt:
	.long 0xe1c900d0,0xe35b0008,0x3a0001f9,0xe371000e
	.long 0x2a0001f7
	bl sqrt
	.long 0xeaffffe0

	.globl lj_ff_math_log
	.hidden lj_ff_math_log
	.type lj_ff_math_log, %function
	.size lj_ff_math_log, 28
lj_ff_math_log:
	.long 0xe1c900d0,0xe35b0008,0x1a0001f2,0xe371000e
	.long 0x2a0001f0
	bl log
	.long 0xeaffffd9

	.globl lj_ff_math_log10
	.hidden lj_ff_math_log10
	.type lj_ff_math_log10, %function
	.size lj_ff_math_log10, 28
lj_ff_math_log10:
	.long 0xe1c900d0,0xe35b0008,0x3a0001eb,0xe371000e
	.long 0x2a0001e9
	bl log10
	.long 0xeaffffd2

	.globl lj_ff_math_exp
	.hidden lj_ff_math_exp
	.type lj_ff_math_exp, %function
	.size lj_ff_math_exp, 28
lj_ff_math_exp:
	.long 0xe1c900d0,0xe35b0008,0x3a0001e4,0xe371000e
	.long 0x2a0001e2
	bl exp
	.long 0xeaffffcb

	.globl lj_ff_math_sin
	.hidden lj_ff_math_sin
	.type lj_ff_math_sin, %function
	.size lj_ff_math_sin, 28
lj_ff_math_sin:
	.long 0xe1c900d0,0xe35b0008,0x3a0001dd,0xe371000e
	.long 0x2a0001db
	bl sin
	.long 0xeaffffc4

	.globl lj_ff_math_cos
	.hidden lj_ff_math_cos
	.type lj_ff_math_cos, %function
	.size lj_ff_math_cos, 28
lj_ff_math_cos:
	.long 0xe1c900d0,0xe35b0008,0x3a0001d6,0xe371000e
	.long 0x2a0001d4
	bl cos
	.long 0xeaffffbd

	.globl lj_ff_math_tan
	.hidden lj_ff_math_tan
	.type lj_ff_math_tan, %function
	.size lj_ff_math_tan, 28
lj_ff_math_tan:
	.long 0xe1c900d0,0xe35b0008,0x3a0001cf,0xe371000e
	.long 0x2a0001cd
	bl tan
	.long 0xeaffffb6

	.globl lj_ff_math_asin
	.hidden lj_ff_math_asin
	.type lj_ff_math_asin, %function
	.size lj_ff_math_asin, 28
lj_ff_math_asin:
	.long 0xe1c900d0,0xe35b0008,0x3a0001c8,0xe371000e
	.long 0x2a0001c6
	bl asin
	.long 0xeaffffaf

	.globl lj_ff_math_acos
	.hidden lj_ff_math_acos
	.type lj_ff_math_acos, %function
	.size lj_ff_math_acos, 28
lj_ff_math_acos:
	.long 0xe1c900d0,0xe35b0008,0x3a0001c1,0xe371000e
	.long 0x2a0001bf
	bl acos
	.long 0xeaffffa8

	.globl lj_ff_math_atan
	.hidden lj_ff_math_atan
	.type lj_ff_math_atan, %function
	.size lj_ff_math_atan, 28
lj_ff_math_atan:
	.long 0xe1c900d0,0xe35b0008,0x3a0001ba,0xe371000e
	.long 0x2a0001b8
	bl atan
	.long 0xeaffffa1

	.globl lj_ff_math_sinh
	.hidden lj_ff_math_sinh
	.type lj_ff_math_sinh, %function
	.size lj_ff_math_sinh, 28
lj_ff_math_sinh:
	.long 0xe1c900d0,0xe35b0008,0x3a0001b3,0xe371000e
	.long 0x2a0001b1
	bl sinh
	.long 0xeaffff9a

	.globl lj_ff_math_cosh
	.hidden lj_ff_math_cosh
	.type lj_ff_math_cosh, %function
	.size lj_ff_math_cosh, 28
lj_ff_math_cosh:
	.long 0xe1c900d0,0xe35b0008,0x3a0001ac,0xe371000e
	.long 0x2a0001aa
	bl cosh
	.long 0xeaffff93

	.globl lj_ff_math_tanh
	.hidden lj_ff_math_tanh
	.type lj_ff_math_tanh, %function
	.size lj_ff_math_tanh, 28
lj_ff_math_tanh:
	.long 0xe1c900d0,0xe35b0008,0x3a0001a5,0xe371000e
	.long 0x2a0001a3
	bl tanh
	.long 0xeaffff8c

	.globl lj_ff_math_pow
	.hidden lj_ff_math_pow
	.type lj_ff_math_pow, %function
	.size lj_ff_math_pow, 36
lj_ff_math_pow:
	.long 0xe1c900d0,0xe1c920d8,0xe35b0010,0x3a00019d
	.long 0xe371000e,0x3373000e,0x2a00019a
	bl pow
	.long 0xeaffff83

	.globl lj_ff_math_atan2
	.hidden lj_ff_math_atan2
	.type lj_ff_math_atan2, %function
	.size lj_ff_math_atan2, 36
lj_ff_math_atan2:
	.long 0xe1c900d0,0xe1c920d8,0xe35b0010,0x3a000194
	.long 0xe371000e,0x3373000e,0x2a000191
	bl atan2
	.long 0xeaffff7a

	.globl lj_ff_math_fmod
	.hidden lj_ff_math_fmod
	.type lj_ff_math_fmod, %function
	.size lj_ff_math_fmod, 36
lj_ff_math_fmod:
	.long 0xe1c900d0,0xe1c920d8,0xe35b0010,0x3a00018b
	.long 0xe371000e,0x3373000e,0x2a000188
	bl fmod
	.long 0xeaffff71

	.globl lj_ff_math_ldexp
	.hidden lj_ff_math_ldexp
	.type lj_ff_math_ldexp, %function
	.size lj_ff_math_ldexp, 40
lj_ff_math_ldexp:
	.long 0xe1c900d0,0xe1c920d8,0xe35b0010,0x3a000182
	.long 0xe371000e,0x2a000180,0xe373000e,0x1a00017e
	bl ldexp
	.long 0xeaffff67

	.globl lj_ff_math_frexp
	.hidden lj_ff_math_frexp
	.type lj_ff_math_frexp, %function
	.size lj_ff_math_frexp, 56
lj_ff_math_frexp:
	.long 0xe1c900d0,0xe35b0008,0x3a000179,0xe371000e
	.long 0x2a000177,0xe1a0200d
	bl frexp
	.long 0xe59d2000,0xe3e0300d,0xe5196004,0xe14900f8
	.long 0xe3a0b018,0xe1c920f0,0xeaffff5c

	.globl lj_ff_math_modf
	.hidden lj_ff_math_modf
	.type lj_ff_math_modf, %function
	.size lj_ff_math_modf, 44
lj_ff_math_modf:
	.long 0xe1c900d0,0xe35b0008,0x3a00016b,0xe371000e
	.long 0x2a000169,0xe2492008,0xe5196004
	bl modf
	.long 0xe3a0b018,0xe1c900f0,0xeaffff51

	.globl lj_ff_math_min
	.hidden lj_ff_math_min
	.type lj_ff_math_min, %function
	.size lj_ff_math_min, 144
lj_ff_math_min:
	.long 0xe1c900d0,0xe35b0008,0x3a000160,0xe371000e
	.long 0xe3a0a008,0x1a00000c,0xe18920da,0xe15a000b
	.long 0x2affff45,0xe373000e,0x1a000003,0xe1500002
	.long 0xe28aa008,0xc1a00002,0xeafffff6,0x8a000153
	bl __aeabi_i2d
	.long 0xe18920da,0xea000005,0x8a00014f,0xe18920da
	.long 0xe15a000b,0x2affff37,0xe373000e,0x2a000004
	bl __aeabi_cdcmple
	.long 0xe28aa008,0x81a00002,0x81a01003,0xeafffff5
	.long 0x8a000144,0xe1cd00f0,0xe1a00002
	bl __aeabi_i2d
	.long 0xe1cd20d0,0xeafffff4

	.globl lj_ff_math_max
	.hidden lj_ff_math_max
	.type lj_ff_math_max, %function
	.size lj_ff_math_max, 144
lj_ff_math_max:
	.long 0xe1c900d0,0xe35b0008,0x3a00013c,0xe371000e
	.long 0xe3a0a008,0x1a00000c,0xe18920da,0xe15a000b
	.long 0x2affff21,0xe373000e,0x1a000003,0xe1500002
	.long 0xe28aa008,0xb1a00002,0xeafffff6,0x8a00012f
	bl __aeabi_i2d
	.long 0xe18920da,0xea000005,0x8a00012b,0xe18920da
	.long 0xe15a000b,0x2affff13,0xe373000e,0x2a000004
	bl __aeabi_cdcmple
	.long 0xe28aa008,0x31a00002,0x31a01003,0xeafffff5
	.long 0x8a000120,0xe1cd00f0,0xe1a00002
	bl __aeabi_i2d
	.long 0xe1cd20d0,0xeafffff4

	.globl lj_ff_string_byte
	.hidden lj_ff_string_byte
	.type lj_ff_string_byte, %function
	.size lj_ff_string_byte, 52
lj_ff_string_byte:
	.long 0xe1c900d0,0xe5196004,0xe35b0008,0x03710005
	.long 0x1a000116,0xe590200c,0xe5d00010,0xe3e0100d
	.long 0xe3520000,0x03a0b008,0x13a0b010,0xe14900f8
	.long 0xeafffefc

	.globl lj_ff_string_char
	.hidden lj_ff_string_char
	.type lj_ff_string_char, %function
	.size lj_ff_string_char, 52
lj_ff_string_char:
	.long 0xe5170b1c,0xe5171b18,0xe1500001,0xab000133
	.long 0xe1c900d0,0xe5196004,0xe35b0008,0x0371000e
	.long 0x03d030ff,0xe3a02001,0x1a000103,0xe58d0000
	.long 0xe1a0100d

	.globl lj_fff_newstr
	.hidden lj_fff_newstr
	.type lj_fff_newstr, %function
	.size lj_fff_newstr, 16
lj_fff_newstr:
	.long 0xe5889010,0xe1a00008,0xe58d6008
	bl lj_str_new

	.globl lj_fff_resstr
	.hidden lj_fff_resstr
	.type lj_fff_resstr, %function
	.size lj_fff_resstr, 12
lj_fff_resstr:
	.long 0xe5989010,0xe3e01004,0xeafffee5

	.globl lj_ff_string_sub
	.hidden lj_ff_string_sub
	.type lj_ff_string_sub, %function
	.size lj_ff_string_sub, 132
lj_ff_string_sub:
	.long 0xe5170b1c,0xe5171b18,0xe1500001,0xab00011f
	.long 0xe1c900d0,0xe1c921d0,0xe35b0010,0xe3e0c000
	.long 0x0a000003,0x3a0000f0,0xe373000e,0xe1a0c002
	.long 0x1a0000ed,0xe1c920d8,0xe3710005,0x0590100c
	.long 0x0373000e,0x1a0000e8,0xe2813001,0xe3520000
	.long 0xb0822003,0xe3520001,0xb3a02001,0xe35c0000
	.long 0xb08cc003,0xe1cccfcc,0xe15c0001,0xe280000f
	.long 0xc1a0c001,0xe0801002,0xe05c2002,0xe2822001
	.long 0xaaffffd7

	.globl lj_fff_emptystr
	.hidden lj_fff_emptystr
	.type lj_fff_emptystr, %function
	.size lj_fff_emptystr, 12
lj_fff_emptystr:
	.long 0xe2470ead,0xe3e01004,0xeafffec1

	.globl lj_ff_string_reverse
	.hidden lj_ff_string_reverse
	.type lj_ff_string_reverse, %function
	.size lj_ff_string_reverse, 76
lj_ff_string_reverse:
	.long 0xe5170b1c,0xe5171b18,0xe1500001,0xab0000fb
	.long 0xe5992004,0xe35b0008,0xe5991000,0x3a0000ce
	.long 0xe2470eae,0xe3720005,0x1a0000cb,0xe5903008
	.long 0xe5889010,0xe58d6008,0xe580800c,0xe5803000
	bl lj_buf_putstr_reverse
	bl lj_buf_tostr
	.long 0xeaffffc5

	.globl lj_ff_string_lower
	.hidden lj_ff_string_lower
	.type lj_ff_string_lower, %function
	.size lj_ff_string_lower, 76
lj_ff_string_lower:
	.long 0xe5170b1c,0xe5171b18,0xe1500001,0xab0000e8
	.long 0xe5992004,0xe35b0008,0xe5991000,0x3a0000bb
	.long 0xe2470eae,0xe3720005,0x1a0000b8,0xe5903008
	.long 0xe5889010,0xe58d6008,0xe580800c,0xe5803000
	bl lj_buf_putstr_lower
	bl lj_buf_tostr
	.long 0xeaffffb2

	.globl lj_ff_string_upper
	.hidden lj_ff_string_upper
	.type lj_ff_string_upper, %function
	.size lj_ff_string_upper, 76
lj_ff_string_upper:
	.long 0xe5170b1c,0xe5171b18,0xe1500001,0xab0000d5
	.long 0xe5992004,0xe35b0008,0xe5991000,0x3a0000a8
	.long 0xe2470eae,0xe3720005,0x1a0000a5,0xe5903008
	.long 0xe5889010,0xe58d6008,0xe580800c,0xe5803000
	bl lj_buf_putstr_upper
	bl lj_buf_tostr
	.long 0xeaffff9f

	.globl lj_vm_tobit_fb
	.hidden lj_vm_tobit_fb
	.type lj_vm_tobit_fb, %function
	.size lj_vm_tobit_fb, 4
lj_vm_tobit_fb:
	.long 0x8a00009c

	.globl lj_vm_tobit
	.hidden lj_vm_tobit
	.type lj_vm_tobit, %function
	.size lj_vm_tobit, 88
lj_vm_tobit:
	.long 0xe1a0c081,0xe29cc980,0x53a00000,0x512fff1e
	.long 0xe3e03ff8,0xe053cacc,0x4a000006,0xe1a03581
	.long 0xe3833480,0xe1833aa0,0xe3510000,0xe1a00c33
	.long 0xb2600000,0xe12fff1e,0xe28cc015,0xe1a03c30
	.long 0xe26cc014,0xe1a00601,0xe3510000,0xe1830c10
	.long 0xb2600000,0xe12fff1e

	.globl lj_ff_bit_tobit
	.hidden lj_ff_bit_tobit
	.type lj_ff_bit_tobit, %function
	.size lj_ff_bit_tobit, 28
lj_ff_bit_tobit:
	.long 0xe1c900d0,0xe35b0008,0x3a000083,0xe371000e
	.long 0x1bffffe3,0xe3e0100d,0xeafffe6a

	.globl lj_ff_bit_band
	.hidden lj_ff_bit_band
	.type lj_ff_bit_band, %function
	.size lj_ff_bit_band, 60
lj_ff_bit_band:
	.long 0xe1c900d0,0xe35b0008,0x3a00007c,0xe371000e
	.long 0x1bffffdc,0xe1a02000,0xe3a0a008,0xe18900da
	.long 0xe15a000b,0xe28aa008,0xaa000021,0xe371000e
	.long 0x1bffffd4,0xe0022000,0xeafffff7

	.globl lj_ff_bit_bor
	.hidden lj_ff_bit_bor
	.type lj_ff_bit_bor, %function
	.size lj_ff_bit_bor, 60
lj_ff_bit_bor:
	.long 0xe1c900d0,0xe35b0008,0x3a00006d,0xe371000e
	.long 0x1bffffcd,0xe1a02000,0xe3a0a008,0xe18900da
	.long 0xe15a000b,0xe28aa008,0xaa000012,0xe371000e
	.long 0x1bffffc5,0xe1822000,0xeafffff7

	.globl lj_ff_bit_bxor
	.hidden lj_ff_bit_bxor
	.type lj_ff_bit_bxor, %function
	.size lj_ff_bit_bxor, 76
lj_ff_bit_bxor:
	.long 0xe1c900d0,0xe35b0008,0x3a00005e,0xe371000e
	.long 0x1bffffbe,0xe1a02000,0xe3a0a008,0xe18900da
	.long 0xe15a000b,0xe28aa008,0xaa000003,0xe371000e
	.long 0x1bffffb6,0xe0222000,0xeafffff7,0xe3e0300d
	.long 0xe5196004,0xe14920f8,0xeafffe3b

	.globl lj_ff_bit_bswap
	.hidden lj_ff_bit_bswap
	.type lj_ff_bit_bswap, %function
	.size lj_ff_bit_bswap, 44
lj_ff_bit_bswap:
	.long 0xe1c900d0,0xe35b0008,0x3a00004b,0xe371000e
	.long 0x1bffffab,0xe0202860,0xe3c228ff,0xe1a00460
	.long 0xe3e0100d,0xe0200422,0xeafffe2e

	.globl lj_ff_bit_bnot
	.hidden lj_ff_bit_bnot
	.type lj_ff_bit_bnot, %function
	.size lj_ff_bit_bnot, 32
lj_ff_bit_bnot:
	.long 0xe1c900d0,0xe35b0008,0x3a000040,0xe371000e
	.long 0x1bffffa0,0xe1e00000,0xe3e0100d,0xeafffe26

	.globl lj_ff_bit_lshift
	.hidden lj_ff_bit_lshift
	.type lj_ff_bit_lshift, %function
	.size lj_ff_bit_lshift, 48
lj_ff_bit_lshift:
	.long 0xe1c900d8,0xe35b0010,0x3a000038,0xe371000e
	.long 0x1bffff98,0xe200a01f,0xe1c900d0,0xe371000e
	.long 0x1bffff94,0xe1a00a10,0xe3e0100d,0xeafffe1a

	.globl lj_ff_bit_rshift
	.hidden lj_ff_bit_rshift
	.type lj_ff_bit_rshift, %function
	.size lj_ff_bit_rshift, 48
lj_ff_bit_rshift:
	.long 0xe1c900d8,0xe35b0010,0x3a00002c,0xe371000e
	.long 0x1bffff8c,0xe200a01f,0xe1c900d0,0xe371000e
	.long 0x1bffff88,0xe1a00a30,0xe3e0100d,0xeafffe0e

	.globl lj_ff_bit_arshift
	.hidden lj_ff_bit_arshift
	.type lj_ff_bit_arshift, %function
	.size lj_ff_bit_arshift, 48
lj_ff_bit_arshift:
	.long 0xe1c900d8,0xe35b0010,0x3a000020,0xe371000e
	.long 0x1bffff80,0xe200a01f,0xe1c900d0,0xe371000e
	.long 0x1bffff7c,0xe1a00a50,0xe3e0100d,0xeafffe02

	.globl lj_ff_bit_rol
	.hidden lj_ff_bit_rol
	.type lj_ff_bit_rol, %function
	.size lj_ff_bit_rol, 48
lj_ff_bit_rol:
	.long 0xe1c900d8,0xe35b0010,0x3a000014,0xe371000e
	.long 0x1bffff74,0xe260a000,0xe1c900d0,0xe371000e
	.long 0x1bffff70,0xe1a00a70,0xe3e0100d,0xeafffdf6

	.globl lj_ff_bit_ror
	.hidden lj_ff_bit_ror
	.type lj_ff_bit_ror, %function
	.size lj_ff_bit_ror, 48
lj_ff_bit_ror:
	.long 0xe1c900d8,0xe35b0010,0x3a000008,0xe371000e
	.long 0x1bffff68,0xe200a01f,0xe1c900d0,0xe371000e
	.long 0x1bffff64,0xe1a00a70,0xe3e0100d,0xeafffdea

	.globl lj_fff_fallback
	.hidden lj_fff_fallback
	.type lj_fff_fallback, %function
	.size lj_fff_fallback, 116
lj_fff_fallback:
	.long 0xe5192008,0xe5981018,0xe089000b,0xe5196004
	.long 0xe5880014,0xe5922014,0xe5889010,0xe28000a0
	.long 0xe58d6008,0xe1500001,0xe1a00008,0x8a000017
	.long 0xe12fff32,0xe5989010,0xe3500000,0xe1a0b180
	.long 0xe249a008,0xcafffddb,0xe5980014,0xe5192008
	.long 0xe040b009,0x1a000006,0xe5926010,0xe5d6c000
	.long 0xe496e004,0xe797c10c,0xe004a2ae,0xe08aa009
	.long 0xe12fff1c

	.globl lj_vm_call_tail
	.hidden lj_vm_call_tail
	.type lj_vm_call_tail, %function
	.size lj_vm_call_tail, 48
lj_vm_call_tail:
	.long 0xe2160003,0xe3c61007,0x0516e004,0x000412ae
	.long 0x02811008,0xe049c001,0xeafffad2,0xe3a01014
	bl lj_state_growstack
	.long 0xe5989010,0xe1500000,0xeaffffe8

	.globl lj_fff_gcstep
	.hidden lj_fff_gcstep
	.type lj_fff_gcstep, %function
	.size lj_fff_gcstep, 44
lj_fff_gcstep:
	.long 0xe1a0a00e,0xe5889010,0xe089100b,0xe58d6008
	.long 0xe5881014,0xe1a00008
	bl lj_gc_step
	.long 0xe5989010,0xe1a0e00a,0xe5192008,0xe12fff1e

	.globl lj_vm_record
	.hidden lj_vm_record
	.type lj_vm_record, %function
	.size lj_vm_record, 40
lj_vm_record:
	.long 0xe5570abf,0xe3100020,0x1a000009,0xe5171a70
	.long 0xe3100010,0x1a000014,0xe2411001,0xe310000c
	.long 0x15071a70,0xea000010

	.globl lj_vm_rethook
	.hidden lj_vm_rethook
	.type lj_vm_rethook, %function
	.size lj_vm_rethook, 24
lj_vm_rethook:
	.long 0xe5570abf,0xe3100010,0x0a00000d,0xe20ec0ff
	.long 0xe087c10c,0xe59cf268

	.globl lj_vm_inshook
	.hidden lj_vm_inshook
	.type lj_vm_inshook, %function
	.size lj_vm_inshook, 92
lj_vm_inshook:
	.long 0xe5570abf,0xe5171a70,0xe3100010,0x1afffff8
	.long 0xe310000c,0x0afffff6,0xe2511001,0xe5071a70
	.long 0x0a000001,0xe3100004,0x0afffff1,0xe1a00008
	.long 0xe5889010,0xe1a01006
	bl lj_dispatch_ins
	.long 0xe5989010,0xe556c004,0xe516e004,0xe087c10c
	.long 0xe59cc268,0xe004a2ae,0xe1a0b82e,0xe12fff1c

	.globl lj_cont_hook
	.hidden lj_cont_hook
	.type lj_cont_hook, %function
	.size lj_cont_hook, 16
lj_cont_hook:
	.long 0xe5130018,0xe2866004,0xe58d0004,0xeafffff4

	.globl lj_vm_hotloop
	.hidden lj_vm_hotloop
	.type lj_vm_hotloop, %function
	.size lj_vm_hotloop, 48
lj_vm_hotloop:
	.long 0xe5192008,0xe2470e9b,0xe58d6008,0xe5922010
	.long 0xe1a01006,0xe5078960,0xe5522039,0xe5889010
	.long 0xe0892182,0xe5882014
	bl lj_trace_hot
	.long 0xeaffffe7

	.globl lj_vm_callhook
	.hidden lj_vm_callhook
	.type lj_vm_callhook, %function
	.size lj_vm_callhook, 8
lj_vm_callhook:
	.long 0xe1a01006,0xea000000

	.globl lj_vm_hotcall
	.hidden lj_vm_hotcall
	.type lj_vm_hotcall, %function
	.size lj_vm_hotcall, 68
lj_vm_hotcall:
	.long 0xe3861001,0xe089300b,0xe58d6008,0xe1a00008
	.long 0xe5889010,0xe04aa009,0xe5883014
	bl lj_dispatch_call
	.long 0xe5989010,0xe5983014,0xe3a01000,0xe089a00a
	.long 0xe043b009,0xe58d1008,0xe5192008,0xe516e004
	.long 0xe12fff10

	.globl lj_cont_stitch
	.hidden lj_cont_stitch
	.type lj_cont_stitch, %function
	.size lj_cont_stitch, 140
lj_cont_stitch:
	.long 0xe59dc004,0xe516e004,0xe5132018,0xe25cc008
	.long 0xe004b2ae,0x0a000005,0xe1ca00d0,0xe28aa008
	.long 0xe25cc008,0xe18900fb,0xe28bb008,0x1afffff9
	.long 0xe004a2ae,0xe004caae,0xe08aa00c,0xe15a000b
	.long 0xe3e01000,0x8a00000d,0xe1d2a4b0,0xe1d2b4b2
	.long 0xe15b000a,0x0afffb0b,0xe35b0000,0x1afff939
	.long 0xe507a0ac,0xe5078960,0xe5889010,0xe2470e9b
	.long 0xe1a01006
	bl lj_dispatch_stitch
	.long 0xe5989010,0xeafffb01,0xe18900fb,0xe28bb008
	.long 0xeaffffeb

	.globl lj_vm_profhook
	.hidden lj_vm_profhook
	.type lj_vm_profhook, %function
	.size lj_vm_profhook, 0
lj_vm_profhook:

	.globl lj_vm_exit_handler
	.hidden lj_vm_exit_handler
	.type lj_vm_exit_handler, %function
	.size lj_vm_exit_handler, 132
lj_vm_exit_handler:
	.long 0xe24dd00c,0xe92d1fff,0xe59d0040,0xe59e7000
	.long 0xe28d2040,0xe3e03003,0xe58d2034,0xe5073ae4
	.long 0xe5301004,0xe58d0038,0xe58d003c,0xe1a01401
	.long 0xe0800341,0xe59e1004,0xe040000e,0xe5178a54
	.long 0xe0810120,0xe5179a50,0xe50700ac,0xe3a03000
	.long 0xe5889010,0xe5078960,0xe5073a50,0xe2470e9b
	.long 0xe1a0100d
	bl lj_trace_exit
	.long 0xe5981028,0xe5989010,0xe3c11003,0xe1a0d001
	.long 0xe59d6008,0xe58d800c,0xea000000

	.globl lj_vm_exit_interp
	.hidden lj_vm_exit_interp
	.type lj_vm_exit_interp, %function
	.size lj_vm_exit_interp, 164
lj_vm_exit_interp:
	.long 0xe59d800c,0xe3500000,0xba000021,0xe1a0b180
	.long 0xe5191008,0xe58db004,0xe3a02000,0xe5889010
	.long 0xe5911010,0xe5072a50,0xe3e03000,0xe5115030
	.long 0xe5d6c000,0xe3a040ff,0xe496e004,0xe1a04184
	.long 0xe5073ae4,0xe35c0061,0x2a000007,0xe35c0059
	.long 0xe797c10c,0xe004a2ae,0x31a0b82e,0x224bb008
	.long 0x208aa009,0x25192008,0xe12fff1c,0xe5190004
	.long 0xe2101003,0x1afffff4,0xe5102004,0xe00402a2
	.long 0xe0491000,0xe5112010,0xe5922010,0xe5125030
	.long 0xeaffffed,0xe2601000,0xe1a00008
	bl lj_err_throw
	.long 0x3ff00000

	.globl lj_vm_floor_sf
	.hidden lj_vm_floor_sf
	.type lj_vm_floor_sf, %function
	.size lj_vm_floor_sf, 0
lj_vm_floor_sf:

	.globl lj_vm_floor
	.hidden lj_vm_floor
	.type lj_vm_floor, %function
	.size lj_vm_floor, 128
lj_vm_floor:
	.long 0xe1a02081,0xe292c980,0x5a000014,0xe3e03ff3
	.long 0xe053cacc,0x312fff1e,0xe3e03001,0xe1c02c13
	.long 0xe0000c13,0xe25cc020,0x51c13c13,0x51822003
	.long 0x53e03001,0x50011c13,0xe1120fc1,0x012fff1e
	.long 0xe3e03001,0xe35c0000,0x51a02c13,0x43e02000
	.long 0xe28cc020,0xe0500c13,0xe0c11002,0xe12fff1e
	.long 0x212fff1e,0xe1822000,0xe1120fc1,0xe3a00000
	.long 0xe2011480,0x151f3080,0x11811003,0xe12fff1e

	.globl lj_vm_ceil_sf
	.hidden lj_vm_ceil_sf
	.type lj_vm_ceil_sf, %function
	.size lj_vm_ceil_sf, 0
lj_vm_ceil_sf:

	.globl lj_vm_ceil
	.hidden lj_vm_ceil
	.type lj_vm_ceil, %function
	.size lj_vm_ceil, 128
lj_vm_ceil:
	.long 0xe1a02081,0xe292c980,0x5a000014,0xe3e03ff3
	.long 0xe053cacc,0x312fff1e,0xe3e03001,0xe1c02c13
	.long 0xe0000c13,0xe25cc020,0x51c13c13,0x51822003
	.long 0x53e03001,0x50011c13,0xe1d22fc1,0x012fff1e
	.long 0xe3e03001,0xe35c0000,0x51a02c13,0x43e02000
	.long 0xe28cc020,0xe0500c13,0xe0c11002,0xe12fff1e
	.long 0x212fff1e,0xe1822000,0xe1d22fc1,0xe3a00000
	.long 0xe2011480,0x151f3100,0x11811003,0xe12fff1e

	.globl lj_vm_trunc
	.hidden lj_vm_trunc
	.type lj_vm_trunc, %function
	.size lj_vm_trunc, 0
lj_vm_trunc:

	.globl lj_vm_trunc_sf
	.hidden lj_vm_trunc_sf
	.type lj_vm_trunc_sf, %function
	.size lj_vm_trunc_sf, 52
lj_vm_trunc_sf:
	.long 0xe1a02081,0xe292c980,0x52011480,0x53a00000
	.long 0x512fff1e,0xe3e03ff3,0xe053cacc,0x312fff1e
	.long 0xe3e03001,0xe0000c13,0xe25cc020,0x50011c13
	.long 0xe12fff1e

	.globl lj_vm_mod
	.hidden lj_vm_mod
	.type lj_vm_mod, %function
	.size lj_vm_mod, 40
lj_vm_mod:
	.long 0xe92d401f
	bl __aeabi_ddiv
	.long 0xebffffaf,0xe1cd20d8
	bl __aeabi_dmul
	.long 0xe1cd20d0,0xe2211480
	bl __aeabi_dadd
	.long 0xe28dd014,0xe8bd8000

	.globl lj_vm_modi
	.hidden lj_vm_modi
	.type lj_vm_modi, %function
	.size lj_vm_modi, 348
lj_vm_modi:
	.long 0xe210c480,0x42600000,0xe02cc0c1,0xe3510000
	.long 0x42611000,0xe2513001,0x11500001,0x03a00000
	.long 0x81110003,0x00000003,0x9a000045,0xe16f2f10
	.long 0xe16f3f11,0xe0433002,0xe273201f,0x108ff182
	.long 0xe1a00000,0xe1500f81,0x20400f81,0xe1500f01
	.long 0x20400f01,0xe1500e81,0x20400e81,0xe1500e01
	.long 0x20400e01,0xe1500d81,0x20400d81,0xe1500d01
	.long 0x20400d01,0xe1500c81,0x20400c81,0xe1500c01
	.long 0x20400c01,0xe1500b81,0x20400b81,0xe1500b01
	.long 0x20400b01,0xe1500a81,0x20400a81,0xe1500a01
	.long 0x20400a01,0xe1500981,0x20400981,0xe1500901
	.long 0x20400901,0xe1500881,0x20400881,0xe1500801
	.long 0x20400801,0xe1500781,0x20400781,0xe1500701
	.long 0x20400701,0xe1500681,0x20400681,0xe1500601
	.long 0x20400601,0xe1500581,0x20400581,0xe1500501
	.long 0x20400501,0xe1500481,0x20400481,0xe1500401
	.long 0x20400401,0xe1500381,0x20400381,0xe1500301
	.long 0x20400301,0xe1500281,0x20400281,0xe1500201
	.long 0x20400201,0xe1500181,0x20400181,0xe1500101
	.long 0x20400101,0xe1500081,0x20400081,0xe1500001
	.long 0x20400001,0xe3500000,0x135c0000,0x40400001
	.long 0xe030108c,0x42600000,0xe12fff1e

	.globl lj_vm_ffi_callback
	.hidden lj_vm_ffi_callback
	.type lj_vm_ffi_callback, %function
	.size lj_vm_ffi_callback, 116
lj_vm_ffi_callback:
	.long 0xe59c60e4,0xe28c7eb3,0xe1c626f8,0xe1c606f0
	.long 0xe59d3000,0xe28d2040,0xe1a00006,0xe1a031a3
	.long 0xe5862080,0xe1a0100d,0xe5863094,0xe58d6008
	bl lj_ccallback_enter
	.long 0xe5909010,0xe3e01000,0xe590b014,0xe3a040ff
	.long 0xe5192008,0xe1a08000,0xe04bb009,0xe1a04184
	.long 0xe5071ae4,0xe5926010,0xe5d6c000,0xe496e004
	.long 0xe797c10c,0xe004a2ae,0xe08aa009,0xe12fff1c

	.globl lj_cont_ffi_callback
	.hidden lj_cont_ffi_callback
	.type lj_cont_ffi_callback, %function
	.size lj_cont_ffi_callback, 36
lj_cont_ffi_callback:
	.long 0xe5176a4c,0xe5889010,0xe5883014,0xe586800c
	.long 0xe1a00006,0xe1a0100a
	bl lj_ccallback_leave
	.long 0xe1c606d0,0xeafff8b1
.globl lj_err_unwind_arm
.personality lj_err_unwind_arm
.fnend
.fnstart
.save {r4, r5, r11, lr}
.setfp r11, sp

	.globl lj_vm_ffi_call
	.hidden lj_vm_ffi_call
	.type lj_vm_ffi_call, %function
	.size lj_vm_ffi_call, 80
lj_vm_ffi_call:
	.long 0xe92d4830,0xe1a04000,0xe5900004,0xe5d41008
	.long 0xe2842020,0xe1a0b00d,0xe04dd000,0xe2511001
	.long 0xe594c000,0x4a000003,0xe7923101,0xe78d3101
	.long 0xe2511001,0x5afffffb,0xe1c401d0,0xe1c421d8
	.long 0xe12fff3c,0xe1a0d00b,0xe1c401f0,0xe8bd8830
.fnend

	.section .note.GNU-stack,"",%progbits
	.ident "DynASM 1.4.0"

	.section .debug_frame,"",%progbits
.Lframe0:
	.long .LECIE0-.LSCIE0
.LSCIE0:
	.long 0xffffffff
	.byte 0x1
	.string ""
	.uleb128 0x1
	.sleb128 -4
	.byte 0xe
	.byte 0xc
	.uleb128 0xd
	.uleb128 0
	.align 2
.LECIE0:

.LSFDE0:
	.long .LEFDE0-.LASFDE0
.LASFDE0:
	.long .Lframe0
	.long .Lbegin
	.long 15880
	.byte 0xe
	.uleb128 64
	.byte 0x8e
	.uleb128 1
	.byte 139
	.uleb128 2
	.byte 138
	.uleb128 3
	.byte 137
	.uleb128 4
	.byte 136
	.uleb128 5
	.byte 135
	.uleb128 6
	.byte 134
	.uleb128 7
	.byte 133
	.uleb128 8
	.byte 132
	.uleb128 9
	.align 2
.LEFDE0:

.LSFDE1:
	.long .LEFDE1-.LASFDE1
.LASFDE1:
	.long .Lframe0
	.long lj_vm_ffi_call
	.long 80
	.byte 0xe
	.uleb128 16
	.byte 0x8e
	.uleb128 1
	.byte 0x8b
	.uleb128 2
	.byte 0x85
	.uleb128 3
	.byte 0x84
	.uleb128 4
	.byte 0xd
	.uleb128 0xb
	.align 2
.LEFDE1:


	.file "buildvm_arm64.dasc"
	.text
	.p2align 4

	.globl lj_vm_asm_begin
	.hidden lj_vm_asm_begin
	.type lj_vm_asm_begin, @object
	.size lj_vm_asm_begin, 0
lj_vm_asm_begin:
.Lbegin:

	.globl lj_BC_ISLT
	.hidden lj_BC_ISLT
	.type lj_BC_ISLT, @function
	.size lj_BC_ISLT, 128
lj_BC_ISLT:
	.long 0xf87b7a60,0x794006b1,0xf87c7a61,0x910012b5
	.long 0x8b110ab1,0xd1408231,0xeb40833f,0x54000161
	.long 0xeb41833f,0x54000221,0x6b01001f,0x9a95b235
	.long 0xb84046b0,0x8b300ec9,0xd3483e1b,0xf947b128
	.long 0xd3507e1c,0xd61f0100,0xfc7b7a60,0x54012e63
	.long 0xfc7c7a61,0xeb41833f,0x540000e8,0x54012de1
	.long 0x1e620021,0x14000004,0xfc7c7a61,0x54012d63
	.long 0x1e620000,0x1e612000,0x9a953235,0x17ffffed

	.globl lj_BC_ISGE
	.hidden lj_BC_ISGE
	.type lj_BC_ISGE, @function
	.size lj_BC_ISGE, 128
lj_BC_ISGE:
	.long 0xf87b7a60,0x794006b1,0xf87c7a61,0x910012b5
	.long 0x8b110ab1,0xd1408231,0xeb40833f,0x54000161
	.long 0xeb41833f,0x54000221,0x6b01001f,0x9a95a235
	.long 0xb84046b0,0x8b300ec9,0xd3483e1b,0xf947b128
	.long 0xd3507e1c,0xd61f0100,0xfc7b7a60,0x54012a63
	.long 0xfc7c7a61,0xeb41833f,0x540000e8,0x540129e1
	.long 0x1e620021,0x14000004,0xfc7c7a61,0x54012963
	.long 0x1e620000,0x1e612000,0x9a952235,0x17ffffed

	.globl lj_BC_ISLE
	.hidden lj_BC_ISLE
	.type lj_BC_ISLE, @function
	.size lj_BC_ISLE, 128
lj_BC_ISLE:
	.long 0xf87b7a60,0x794006b1,0xf87c7a61,0x910012b5
	.long 0x8b110ab1,0xd1408231,0xeb40833f,0x54000161
	.long 0xeb41833f,0x54000221,0x6b01001f,0x9a95d235
	.long 0xb84046b0,0x8b300ec9,0xd3483e1b,0xf947b128
	.long 0xd3507e1c,0xd61f0100,0xfc7b7a60,0x54012663
	.long 0xfc7c7a61,0xeb41833f,0x540000e8,0x540125e1
	.long 0x1e620021,0x14000004,0xfc7c7a61,0x54012563
	.long 0x1e620000,0x1e612000,0x9a959235,0x17ffffed

	.globl lj_BC_ISGT
	.hidden lj_BC_ISGT
	.type lj_BC_ISGT, @function
	.size lj_BC_ISGT, 128
lj_BC_ISGT:
	.long 0xf87b7a60,0x794006b1,0xf87c7a61,0x910012b5
	.long 0x8b110ab1,0xd1408231,0xeb40833f,0x54000161
	.long 0xeb41833f,0x54000221,0x6b01001f,0x9a95c235
	.long 0xb84046b0,0x8b300ec9,0xd3483e1b,0xf947b128
	.long 0xd3507e1c,0xd61f0100,0xfc7b7a60,0x54012263
	.long 0xfc7c7a61,0xeb41833f,0x540000e8,0x540121e1
	.long 0x1e620021,0x14000004,0xfc7c7a61,0x54012163
	.long 0x1e620000,0x1e612000,0x9a958235,0x17ffffed

	.globl lj_BC_ISEQV
	.hidden lj_BC_ISEQV
	.type lj_BC_ISEQV, @function
	.size lj_BC_ISEQV, 132
lj_BC_ISEQV:
	.long 0xf87b7a60,0x8b1c0e7c,0x794006b1,0xf9400382
	.long 0x910012b5,0x8b110ab1,0xd1408231,0x936ffc4f
	.long 0xb10039ff,0x54000ce9,0x936ffc08,0xb1002dff
	.long 0xba4b1904,0x54012440,0xeb02001f,0x54000101
	.long 0xaa1103f5,0xb84046b0,0x8b300ec9,0xd3483e1b
	.long 0xf947b128,0xd3507e1c,0xd61f0100,0xeb0801ff
	.long 0xba4c09e2,0x54ffff08,0x9240b801,0xf940102a
	.long 0xb4fffeaa,0x39402949,0x52800003,0x3727fe49
	.long 0x14000908

	.globl lj_BC_ISNEV
	.hidden lj_BC_ISNEV
	.type lj_BC_ISNEV, @function
	.size lj_BC_ISNEV, 128
lj_BC_ISNEV:
	.long 0xf87b7a60,0x8b1c0e7c,0x794006b1,0xf9400382
	.long 0x910012b5,0x8b110ab1,0xd1408231,0x936ffc4f
	.long 0xb10039ff,0x54000d29,0x936ffc08,0xb1002dff
	.long 0xba4b1904,0x54012020,0xeb02001f,0x540000e1
	.long 0xb84046b0,0x8b300ec9,0xd3483e1b,0xf947b128
	.long 0xd3507e1c,0xd61f0100,0xeb0801ff,0xba4c09e2
	.long 0x54fffae8,0x9240b801,0xf940102a,0xb4fffa8a
	.long 0x39402949,0x52800023,0x3727fa29,0x140008e8

	.globl lj_BC_ISEQS
	.hidden lj_BC_ISEQS
	.type lj_BC_ISEQS, @function
	.size lj_BC_ISEQS, 80
lj_BC_ISEQS:
	.long 0xf87b7a60,0xaa3c03fc,0x794006b1,0xf87c7a81
	.long 0x910012b5,0x92800088,0x936ffc0f,0x8b110ab1
	.long 0x8b08bc21,0xd1408231,0xb1002dff,0x54011c60
	.long 0xeb01001f,0x9a950235,0xb84046b0,0x8b300ec9
	.long 0xd3483e1b,0xf947b128,0xd3507e1c,0xd61f0100

	.globl lj_BC_ISNES
	.hidden lj_BC_ISNES
	.type lj_BC_ISNES, @function
	.size lj_BC_ISNES, 80
lj_BC_ISNES:
	.long 0xf87b7a60,0xaa3c03fc,0x794006b1,0xf87c7a81
	.long 0x910012b5,0x92800088,0x936ffc0f,0x8b110ab1
	.long 0x8b08bc21,0xd1408231,0xb1002dff,0x540119e0
	.long 0xeb01001f,0x9a951235,0xb84046b0,0x8b300ec9
	.long 0xd3483e1b,0xf947b128,0xd3507e1c,0xd61f0100

	.globl lj_BC_ISEQN
	.hidden lj_BC_ISEQN
	.type lj_BC_ISEQN, @function
	.size lj_BC_ISEQN, 140
lj_BC_ISEQN:
	.long 0xf87b7a60,0x8b1c0e9c,0x794006b1,0xf9400382
	.long 0x910012b5,0x8b110ab1,0xd1408231,0xeb40833f
	.long 0x54000161,0xeb42833f,0x54000221,0x6b02001f
	.long 0x9a950235,0xb84046b0,0x8b300ec9,0xd3483e1b
	.long 0xf947b128,0xd3507e1c,0xd61f0100,0x54000183
	.long 0xfc7b7a60,0xfd400381,0xeb42833f,0x54000041
	.long 0x1e620041,0x1e612000,0x17fffff2,0xfd400381
	.long 0x1e620000,0x1e612000,0x17ffffee,0x936ffc0f
	.long 0xb1002dff,0x54fffd81,0x140008a4

	.globl lj_BC_ISNEN
	.hidden lj_BC_ISNEN
	.type lj_BC_ISNEN, @function
	.size lj_BC_ISNEN, 140
lj_BC_ISNEN:
	.long 0xf87b7a60,0x8b1c0e9c,0x794006b1,0xf9400382
	.long 0x910012b5,0x8b110ab1,0xd1408231,0xeb40833f
	.long 0x54000161,0xeb42833f,0x54000221,0x6b02001f
	.long 0x9a951235,0xb84046b0,0x8b300ec9,0xd3483e1b
	.long 0xf947b128,0xd3507e1c,0xd61f0100,0x54000183
	.long 0xfc7b7a60,0xfd400381,0xeb42833f,0x54000041
	.long 0x1e620041,0x1e612000,0x17fffff2,0xfd400381
	.long 0x1e620000,0x1e612000,0x17ffffee,0x936ffc0f
	.long 0xb1002dff,0x54fffd61,0x14000881

	.globl lj_BC_ISEQP
	.hidden lj_BC_ISEQP
	.type lj_BC_ISEQP, @function
	.size lj_BC_ISEQP, 68
lj_BC_ISEQP:
	.long 0xf87b7a68,0x794006b1,0x910012b5,0x9100079c
	.long 0x8b110ab1,0x936ffd0f,0xb1002dff,0x54010f20
	.long 0xab0f039f,0xd1408231,0x9a950235,0xb84046b0
	.long 0x8b300ec9,0xd3483e1b,0xf947b128,0xd3507e1c
	.long 0xd61f0100

	.globl lj_BC_ISNEP
	.hidden lj_BC_ISNEP
	.type lj_BC_ISNEP, @function
	.size lj_BC_ISNEP, 68
lj_BC_ISNEP:
	.long 0xf87b7a68,0x794006b1,0x910012b5,0x9100079c
	.long 0x8b110ab1,0x936ffd0f,0xb1002dff,0x54010d00
	.long 0xab0f039f,0xd1408231,0x9a951235,0xb84046b0
	.long 0x8b300ec9,0xd3483e1b,0xf947b128,0xd3507e1c
	.long 0xd61f0100

	.globl lj_BC_ISTC
	.hidden lj_BC_ISTC
	.type lj_BC_ISTC, @function
	.size lj_BC_ISTC, 64
lj_BC_ISTC:
	.long 0x794006b1,0xf87c7a68,0x910012b5,0x92d00009
	.long 0x8b110ab1,0xeb09011f,0xd1408231,0x9a9c337b
	.long 0x9a953235,0xf83b7a68,0xb84046b0,0x8b300ec9
	.long 0xd3483e1b,0xf947b128,0xd3507e1c,0xd61f0100

	.globl lj_BC_ISFC
	.hidden lj_BC_ISFC
	.type lj_BC_ISFC, @function
	.size lj_BC_ISFC, 64
lj_BC_ISFC:
	.long 0x794006b1,0xf87c7a68,0x910012b5,0x92d00009
	.long 0x8b110ab1,0xeb09011f,0xd1408231,0x9a9c237b
	.long 0x9a952235,0xf83b7a68,0xb84046b0,0x8b300ec9
	.long 0xd3483e1b,0xf947b128,0xd3507e1c,0xd61f0100

	.globl lj_BC_IST
	.hidden lj_BC_IST
	.type lj_BC_IST, @function
	.size lj_BC_IST, 56
lj_BC_IST:
	.long 0x794006b1,0xf87c7a68,0x910012b5,0x92d00009
	.long 0x8b110ab1,0xeb09011f,0xd1408231,0x9a953235
	.long 0xb84046b0,0x8b300ec9,0xd3483e1b,0xf947b128
	.long 0xd3507e1c,0xd61f0100

	.globl lj_BC_ISF
	.hidden lj_BC_ISF
	.type lj_BC_ISF, @function
	.size lj_BC_ISF, 56
lj_BC_ISF:
	.long 0x794006b1,0xf87c7a68,0x910012b5,0x92d00009
	.long 0x8b110ab1,0xeb09011f,0xd1408231,0x9a952235
	.long 0xb84046b0,0x8b300ec9,0xd3483e1b,0xf947b128
	.long 0xd3507e1c,0xd61f0100

	.globl lj_BC_ISTYPE
	.hidden lj_BC_ISTYPE
	.type lj_BC_ISTYPE, @function
	.size lj_BC_ISTYPE, 36
lj_BC_ISTYPE:
	.long 0xf87b7a68,0xab88bf9f,0x540104e1,0xb84046b0
	.long 0x8b300ec9,0xd3483e1b,0xf947b128,0xd3507e1c
	.long 0xd61f0100

	.globl lj_BC_ISNUM
	.hidden lj_BC_ISNUM
	.type lj_BC_ISNUM, @function
	.size lj_BC_ISNUM, 36
lj_BC_ISNUM:
	.long 0xf87b6a68,0xeb48833f,0x540103c9,0xb84046b0
	.long 0x8b300ec9,0xd3483e1b,0xf947b128,0xd3507e1c
	.long 0xd61f0100

	.globl lj_BC_MOV
	.hidden lj_BC_MOV
	.type lj_BC_MOV, @function
	.size lj_BC_MOV, 32
lj_BC_MOV:
	.long 0xf87c7a68,0xf83b7a68,0xb84046b0,0x8b300ec9
	.long 0xd3483e1b,0xf947b128,0xd3507e1c,0xd61f0100

	.globl lj_BC_NOT
	.hidden lj_BC_NOT
	.type lj_BC_NOT, @function
	.size lj_BC_NOT, 48
lj_BC_NOT:
	.long 0xf87c7a68,0x92d00009,0x92e0002a,0xeb09011f
	.long 0x9a8a3128,0xf83b7a68,0xb84046b0,0x8b300ec9
	.long 0xd3483e1b,0xf947b128,0xd3507e1c,0xd61f0100

	.globl lj_BC_UNM
	.hidden lj_BC_UNM
	.type lj_BC_UNM, @function
	.size lj_BC_UNM, 68
lj_BC_UNM:
	.long 0xf87c7a68,0x936ffd0f,0xb10039ff,0x540101c8
	.long 0xd2410108,0x540000a1,0x6b0803e8,0xd2e83c02
	.long 0x8b180108,0x9a827108,0xf83b7a68,0xb84046b0
	.long 0x8b300ec9,0xd3483e1b,0xf947b128,0xd3507e1c
	.long 0xd61f0100

	.globl lj_BC_LEN
	.hidden lj_BC_LEN
	.type lj_BC_LEN, @function
	.size lj_BC_LEN, 72
lj_BC_LEN:
	.long 0xf87c7a60,0x936ffc0f,0xb10015ff,0x9240b800
	.long 0x54000141,0xb9401400,0x8b180000,0xf83b7a60
	.long 0xb84046b0,0x8b300ec9,0xd3483e1b,0xf947b128
	.long 0xd3507e1c,0xd61f0100,0xb10031ff,0x54010061
	bl lj_tab_len
	.long 0x17fffff5

	.globl lj_BC_ADDVN
	.hidden lj_BC_ADDVN
	.type lj_BC_ADDVN, @function
	.size lj_BC_ADDVN, 108
lj_BC_ADDVN:
	.long 0xd3587e11,0x92401f9c,0xf8717a60,0xf87c7a81
	.long 0xeb40833f,0x540001a1,0xeb41833f,0x54000161
	.long 0x2b010000,0x5400fbe6,0x8b180000,0xf83b7a60
	.long 0xb84046b0,0x8b300ec9,0xd3483e1b,0xf947b128
	.long 0xd3507e1c,0xd61f0100,0xfc717a60,0xfc7c7a81
	.long 0xeb40833f,0x5400fa69,0xeb41833f,0x5400fa29
	.long 0x1e612800,0xfc3b7a60,0x17fffff2

	.globl lj_BC_SUBVN
	.hidden lj_BC_SUBVN
	.type lj_BC_SUBVN, @function
	.size lj_BC_SUBVN, 108
lj_BC_SUBVN:
	.long 0xd3587e11,0x92401f9c,0xf8717a60,0xf87c7a81
	.long 0xeb40833f,0x540001a1,0xeb41833f,0x54000161
	.long 0x6b010000,0x5400f886,0x8b180000,0xf83b7a60
	.long 0xb84046b0,0x8b300ec9,0xd3483e1b,0xf947b128
	.long 0xd3507e1c,0xd61f0100,0xfc717a60,0xfc7c7a81
	.long 0xeb40833f,0x5400f709,0xeb41833f,0x5400f6c9
	.long 0x1e613800,0xfc3b7a60,0x17fffff2

	.globl lj_BC_MULVN
	.hidden lj_BC_MULVN
	.type lj_BC_MULVN, @function
	.size lj_BC_MULVN, 116
lj_BC_MULVN:
	.long 0xd3587e11,0x92401f9c,0xf8717a60,0xf87c7a81
	.long 0xeb40833f,0x540001e1,0xeb41833f,0x540001a1
	.long 0x9b217c00,0xeb20c01f,0x2a0003e0,0x5400f4e1
	.long 0x8b180000,0xf83b7a60,0xb84046b0,0x8b300ec9
	.long 0xd3483e1b,0xf947b128,0xd3507e1c,0xd61f0100
	.long 0xfc717a60,0xfc7c7a81,0xeb40833f,0x5400f369
	.long 0xeb41833f,0x5400f329,0x1e610800,0xfc3b7a60
	.long 0x17fffff2

	.globl lj_BC_DIVVN
	.hidden lj_BC_DIVVN
	.type lj_BC_DIVVN, @function
	.size lj_BC_DIVVN, 72
lj_BC_DIVVN:
	.long 0xd3587e11,0x92401f9c,0xf8717a60,0xf87c7a81
	.long 0xfc717a60,0xfc7c7a81,0xeb40833f,0x5400f1c9
	.long 0xeb41833f,0x5400f189,0x1e611800,0xfc3b7a60
	.long 0xb84046b0,0x8b300ec9,0xd3483e1b,0xf947b128
	.long 0xd3507e1c,0xd61f0100

	.globl lj_BC_MODVN
	.hidden lj_BC_MODVN
	.type lj_BC_MODVN, @function
	.size lj_BC_MODVN, 116
lj_BC_MODVN:
	.long 0xd3587e11,0x92401f9c,0xf8717a60,0xf87c7a81
	.long 0xeb40833f,0x540001a1,0xeb41833f,0x54000161
	.long 0x3400ef61,0x94000ca0,0x8b180000,0xf83b7a60
	.long 0xb84046b0,0x8b300ec9,0xd3483e1b,0xf947b128
	.long 0xd3507e1c,0xd61f0100,0xfc717a60,0xfc7c7a81
	.long 0xeb40833f,0x5400edc9,0xeb41833f,0x5400ed89
	.long 0x1e611802,0x1e654042,0x1f418040,0xfc3b7a60
	.long 0x17fffff0

	.globl lj_BC_ADDNV
	.hidden lj_BC_ADDNV
	.type lj_BC_ADDNV, @function
	.size lj_BC_ADDNV, 108
lj_BC_ADDNV:
	.long 0x92401f9c,0xd3587e11,0xf87c7a80,0xf8717a61
	.long 0xeb40833f,0x540001a1,0xeb41833f,0x54000161
	.long 0x2b010000,0x5400ec06,0x8b180000,0xf83b7a60
	.long 0xb84046b0,0x8b300ec9,0xd3483e1b,0xf947b128
	.long 0xd3507e1c,0xd61f0100,0xfc7c7a80,0xfc717a61
	.long 0xeb40833f,0x5400ea89,0xeb41833f,0x5400ea49
	.long 0x1e612800,0xfc3b7a60,0x17fffff2

	.globl lj_BC_SUBNV
	.hidden lj_BC_SUBNV
	.type lj_BC_SUBNV, @function
	.size lj_BC_SUBNV, 108
lj_BC_SUBNV:
	.long 0x92401f9c,0xd3587e11,0xf87c7a80,0xf8717a61
	.long 0xeb40833f,0x540001a1,0xeb41833f,0x54000161
	.long 0x6b010000,0x5400e8a6,0x8b180000,0xf83b7a60
	.long 0xb84046b0,0x8b300ec9,0xd3483e1b,0xf947b128
	.long 0xd3507e1c,0xd61f0100,0xfc7c7a80,0xfc717a61
	.long 0xeb40833f,0x5400e729,0xeb41833f,0x5400e6e9
	.long 0x1e613800,0xfc3b7a60,0x17fffff2

	.globl lj_BC_MULNV
	.hidden lj_BC_MULNV
	.type lj_BC_MULNV, @function
	.size lj_BC_MULNV, 116
lj_BC_MULNV:
	.long 0x92401f9c,0xd3587e11,0xf87c7a80,0xf8717a61
	.long 0xeb40833f,0x540001e1,0xeb41833f,0x540001a1
	.long 0x9b217c00,0xeb20c01f,0x2a0003e0,0x5400e501
	.long 0x8b180000,0xf83b7a60,0xb84046b0,0x8b300ec9
	.long 0xd3483e1b,0xf947b128,0xd3507e1c,0xd61f0100
	.long 0xfc7c7a80,0xfc717a61,0xeb40833f,0x5400e389
	.long 0xeb41833f,0x5400e349,0x1e610800,0xfc3b7a60
	.long 0x17fffff2

	.globl lj_BC_DIVNV
	.hidden lj_BC_DIVNV
	.type lj_BC_DIVNV, @function
	.size lj_BC_DIVNV, 72
lj_BC_DIVNV:
	.long 0x92401f9c,0xd3587e11,0xf87c7a80,0xf8717a61
	.long 0xfc7c7a80,0xfc717a61,0xeb40833f,0x5400e1e9
	.long 0xeb41833f,0x5400e1a9,0x1e611800,0xfc3b7a60
	.long 0xb84046b0,0x8b300ec9,0xd3483e1b,0xf947b128
	.long 0xd3507e1c,0xd61f0100

	.globl lj_BC_MODNV
	.hidden lj_BC_MODNV
	.type lj_BC_MODNV, @function
	.size lj_BC_MODNV, 116
lj_BC_MODNV:
	.long 0x92401f9c,0xd3587e11,0xf87c7a80,0xf8717a61
	.long 0xeb40833f,0x540001a1,0xeb41833f,0x54000161
	.long 0x3400df81,0x94000c1e,0x8b180000,0xf83b7a60
	.long 0xb84046b0,0x8b300ec9,0xd3483e1b,0xf947b128
	.long 0xd3507e1c,0xd61f0100,0xfc7c7a80,0xfc717a61
	.long 0xeb40833f,0x5400dde9,0xeb41833f,0x5400dda9
	.long 0x1e611802,0x1e654042,0x1f418040,0xfc3b7a60
	.long 0x17fffff0

	.globl lj_BC_ADDVV
	.hidden lj_BC_ADDVV
	.type lj_BC_ADDVV, @function
	.size lj_BC_ADDVV, 108
lj_BC_ADDVV:
	.long 0xd3587e11,0x92401f9c,0xf8717a60,0xf87c7a61
	.long 0xeb40833f,0x540001a1,0xeb41833f,0x54000161
	.long 0x2b010000,0x5400dc86,0x8b180000,0xf83b7a60
	.long 0xb84046b0,0x8b300ec9,0xd3483e1b,0xf947b128
	.long 0xd3507e1c,0xd61f0100,0xfc717a60,0xfc7c7a61
	.long 0xeb40833f,0x5400db09,0xeb41833f,0x5400dac9
	.long 0x1e612800,0xfc3b7a60,0x17fffff2

	.globl lj_BC_SUBVV
	.hidden lj_BC_SUBVV
	.type lj_BC_SUBVV, @function
	.size lj_BC_SUBVV, 108
lj_BC_SUBVV:
	.long 0xd3587e11,0x92401f9c,0xf8717a60,0xf87c7a61
	.long 0xeb40833f,0x540001a1,0xeb41833f,0x54000161
	.long 0x6b010000,0x5400d926,0x8b180000,0xf83b7a60
	.long 0xb84046b0,0x8b300ec9,0xd3483e1b,0xf947b128
	.long 0xd3507e1c,0xd61f0100,0xfc717a60,0xfc7c7a61
	.long 0xeb40833f,0x5400d7a9,0xeb41833f,0x5400d769
	.long 0x1e613800,0xfc3b7a60,0x17fffff2

	.globl lj_BC_MULVV
	.hidden lj_BC_MULVV
	.type lj_BC_MULVV, @function
	.size lj_BC_MULVV, 116
lj_BC_MULVV:
	.long 0xd3587e11,0x92401f9c,0xf8717a60,0xf87c7a61
	.long 0xeb40833f,0x540001e1,0xeb41833f,0x540001a1
	.long 0x9b217c00,0xeb20c01f,0x2a0003e0,0x5400d581
	.long 0x8b180000,0xf83b7a60,0xb84046b0,0x8b300ec9
	.long 0xd3483e1b,0xf947b128,0xd3507e1c,0xd61f0100
	.long 0xfc717a60,0xfc7c7a61,0xeb40833f,0x5400d409
	.long 0xeb41833f,0x5400d3c9,0x1e610800,0xfc3b7a60
	.long 0x17fffff2

	.globl lj_BC_DIVVV
	.hidden lj_BC_DIVVV
	.type lj_BC_DIVVV, @function
	.size lj_BC_DIVVV, 72
lj_BC_DIVVV:
	.long 0xd3587e11,0x92401f9c,0xf8717a60,0xf87c7a61
	.long 0xfc717a60,0xfc7c7a61,0xeb40833f,0x5400d269
	.long 0xeb41833f,0x5400d229,0x1e611800,0xfc3b7a60
	.long 0xb84046b0,0x8b300ec9,0xd3483e1b,0xf947b128
	.long 0xd3507e1c,0xd61f0100

	.globl lj_BC_MODVV
	.hidden lj_BC_MODVV
	.type lj_BC_MODVV, @function
	.size lj_BC_MODVV, 116
lj_BC_MODVV:
	.long 0xd3587e11,0x92401f9c,0xf8717a60,0xf87c7a61
	.long 0xeb40833f,0x540001a1,0xeb41833f,0x54000161
	.long 0x3400d001,0x94000b9c,0x8b180000,0xf83b7a60
	.long 0xb84046b0,0x8b300ec9,0xd3483e1b,0xf947b128
	.long 0xd3507e1c,0xd61f0100,0xfc717a60,0xfc7c7a61
	.long 0xeb40833f,0x5400ce69,0xeb41833f,0x5400ce29
	.long 0x1e611802,0x1e654042,0x1f418040,0xfc3b7a60
	.long 0x17fffff0

	.globl lj_BC_POW
	.hidden lj_BC_POW
	.type lj_BC_POW, @function
	.size lj_BC_POW, 72
lj_BC_POW:
	.long 0xd3587e11,0x92401f9c,0xf8717a60,0xf87c7a61
	.long 0xfc717a60,0xfc7c7a61,0xeb40833f,0x5400cc89
	.long 0xeb41833f,0x5400cc49
	bl pow
	.long 0xfc3b7a60,0xb84046b0,0x8b300ec9,0xd3483e1b
	.long 0xf947b128,0xd3507e1c,0xd61f0100

	.globl lj_BC_CAT
	.hidden lj_BC_CAT
	.type lj_BC_CAT, @function
	.size lj_BC_CAT, 76
lj_BC_CAT:
	.long 0xd3587e11,0x92401f9c,0xf90012f3,0xcb110382
	.long 0x8b1c0e61,0xaa1703e0,0xf90057f5
	bl lj_meta_cat
	.long 0x385ff2b1,0xf94012f3,0xb500cb00,0xf8717a68
	.long 0xf83b7a68,0xb84046b0,0x8b300ec9,0xd3483e1b
	.long 0xf947b128,0xd3507e1c,0xd61f0100

	.globl lj_BC_KSTR
	.hidden lj_BC_KSTR
	.type lj_BC_KSTR, @function
	.size lj_BC_KSTR, 44
lj_BC_KSTR:
	.long 0xaa3c03fc,0xf87c7a88,0x92800089,0x8b09bd08
	.long 0xf83b7a68,0xb84046b0,0x8b300ec9,0xd3483e1b
	.long 0xf947b128,0xd3507e1c,0xd61f0100

	.globl lj_BC_KCDATA
	.hidden lj_BC_KCDATA
	.type lj_BC_KCDATA, @function
	.size lj_BC_KCDATA, 44
lj_BC_KCDATA:
	.long 0xaa3c03fc,0xf87c7a88,0x92800149,0x8b09bd08
	.long 0xf83b7a68,0xb84046b0,0x8b300ec9,0xd3483e1b
	.long 0xf947b128,0xd3507e1c,0xd61f0100

	.globl lj_BC_KSHORT
	.hidden lj_BC_KSHORT
	.type lj_BC_KSHORT, @function
	.size lj_BC_KSHORT, 36
lj_BC_KSHORT:
	.long 0x13003f9c,0x8b180388,0xf83b7a68,0xb84046b0
	.long 0x8b300ec9,0xd3483e1b,0xf947b128,0xd3507e1c
	.long 0xd61f0100

	.globl lj_BC_KNUM
	.hidden lj_BC_KNUM
	.type lj_BC_KNUM, @function
	.size lj_BC_KNUM, 32
lj_BC_KNUM:
	.long 0xf87c7a88,0xf83b7a68,0xb84046b0,0x8b300ec9
	.long 0xd3483e1b,0xf947b128,0xd3507e1c,0xd61f0100

	.globl lj_BC_KPRI
	.hidden lj_BC_KPRI
	.type lj_BC_KPRI, @function
	.size lj_BC_KPRI, 32
lj_BC_KPRI:
	.long 0xaa3cbfe8,0xf83b7a68,0xb84046b0,0x8b300ec9
	.long 0xd3483e1b,0xf947b128,0xd3507e1c,0xd61f0100

	.globl lj_BC_KNIL
	.hidden lj_BC_KNIL
	.type lj_BC_KNIL, @function
	.size lj_BC_KNIL, 48
lj_BC_KNIL:
	.long 0x8b1b0e7b,0x8b1c0e7c,0xf800877a,0xeb1c037f
	.long 0xf800877a,0x54ffffcb,0xb84046b0,0x8b300ec9
	.long 0xd3483e1b,0xf947b128,0xd3507e1c,0xd61f0100

	.globl lj_BC_UGET
	.hidden lj_BC_UGET
	.type lj_BC_UGET, @function
	.size lj_BC_UGET, 52
lj_BC_UGET:
	.long 0xf85f0261,0x9100179c,0x9240b821,0xf87c7821
	.long 0xf9401021,0xf9400028,0xf83b7a68,0xb84046b0
	.long 0x8b300ec9,0xd3483e1b,0xf947b128,0xd3507e1c
	.long 0xd61f0100

	.globl lj_BC_USETV
	.hidden lj_BC_USETV
	.type lj_BC_USETV, @function
	.size lj_BC_USETV, 112
lj_BC_USETV:
	.long 0xf85f0261,0x9100177b,0x9240b821,0xf87b7820
	.long 0xf87c7a62,0xf9401001,0x3940200a,0x39402808
	.long 0x936ffc4f,0xf9000022,0x910011ef,0x721e015f
	.long 0x7a401904,0xba4a19e0,0x540000e8,0xb84046b0
	.long 0x8b300ec9,0xd3483e1b,0xf947b128,0xd3507e1c
	.long 0xd61f0100,0x9240b842,0x39402049,0x7200053f
	.long 0x54fffee0,0xaa1603e0
	bl lj_gc_barrieruv
	.long 0x17fffff4

	.globl lj_BC_USETS
	.hidden lj_BC_USETS
	.type lj_BC_USETS, @function
	.size lj_BC_USETS, 104
lj_BC_USETS:
	.long 0xf85f0261,0x9100177b,0xaa3c03fc,0x9240b821
	.long 0xf87b7820,0xf87c7a82,0x92800088,0xf9401001
	.long 0x3940200a,0x8b08bc48,0x39402049,0xf9000028
	.long 0x371000ea,0xb84046b0,0x8b300ec9,0xd3483e1b
	.long 0xf947b128,0xd3507e1c,0xd61f0100,0x39402808
	.long 0x7200053f,0x7a401904,0x54fffee0,0xaa1603e0
	bl lj_gc_barrieruv
	.long 0x17fffff4

	.globl lj_BC_USETN
	.hidden lj_BC_USETN
	.type lj_BC_USETN, @function
	.size lj_BC_USETN, 52
lj_BC_USETN:
	.long 0xf85f0261,0x9100177b,0x9240b821,0xf87b7821
	.long 0xf87c7a88,0xf9401021,0xf9000028,0xb84046b0
	.long 0x8b300ec9,0xd3483e1b,0xf947b128,0xd3507e1c
	.long 0xd61f0100

	.globl lj_BC_USETP
	.hidden lj_BC_USETP
	.type lj_BC_USETP, @function
	.size lj_BC_USETP, 52
lj_BC_USETP:
	.long 0xf85f0261,0x9100177b,0x9240b821,0xf87b7821
	.long 0xaa3cbfe8,0xf9401021,0xf9000028,0xb84046b0
	.long 0x8b300ec9,0xd3483e1b,0xf947b128,0xd3507e1c
	.long 0xd61f0100

	.globl lj_BC_UCLO
	.hidden lj_BC_UCLO
	.type lj_BC_UCLO, @function
	.size lj_BC_UCLO, 60
lj_BC_UCLO:
	.long 0xf94022e2,0x8b1c0abc,0xf90012f3,0xd1408395
	.long 0xb40000a2,0xaa1703e0,0x8b1b0e61
	bl lj_func_closeuv
	.long 0xf94012f3,0xb84046b0,0x8b300ec9,0xd3483e1b
	.long 0xf947b128,0xd3507e1c,0xd61f0100

	.globl lj_BC_FNEW
	.hidden lj_BC_FNEW
	.type lj_BC_FNEW, @function
	.size lj_BC_FNEW, 72
lj_BC_FNEW:
	.long 0xaa3c03fc,0xf90012f3,0xf85f0262,0xf90057f5
	.long 0xf87c7a81,0xaa1703e0,0x9240b842
	bl lj_func_newL_gc
	.long 0xf94012f3,0x92800108,0x8b08bc00,0xf83b7a60
	.long 0xb84046b0,0x8b300ec9,0xd3483e1b,0xf947b128
	.long 0xd3507e1c,0xd61f0100

	.globl lj_BC_TNEW
	.hidden lj_BC_TNEW
	.type lj_BC_TNEW, @function
	.size lj_BC_TNEW, 96
lj_BC_TNEW:
	.long 0xa9410ec2,0xf90012f3,0xf90057f5,0xaa1703e0
	.long 0xeb03005f,0x54000202,0x92402b81,0xd34bff82
	.long 0xf11ffc3f,0x52810028,0x9a881021
	bl lj_tab_new
	.long 0xf94012f3,0xf2ffff40,0xf83b7a60,0xb84046b0
	.long 0x8b300ec9,0xd3483e1b,0xf947b128,0xd3507e1c
	.long 0xd61f0100
	bl lj_gc_step_fixtop
	.long 0xaa1703e0,0x17ffffef

	.globl lj_BC_TDUP
	.hidden lj_BC_TDUP
	.type lj_BC_TDUP, @function
	.size lj_BC_TDUP, 84
lj_BC_TDUP:
	.long 0xa9410ec2,0xf90012f3,0xf90057f5,0xaa1703e0
	.long 0xeb03005f,0x540001a2,0xaa3c03fc,0xf87c7a81
	bl lj_tab_dup
	.long 0xf94012f3,0xf2ffff40,0xf83b7a60,0xb84046b0
	.long 0x8b300ec9,0xd3483e1b,0xf947b128,0xd3507e1c
	.long 0xd61f0100
	bl lj_gc_step_fixtop
	.long 0xaa1703e0,0x17fffff2

	.globl lj_BC_GGET
	.hidden lj_BC_GGET
	.type lj_BC_GGET, @function
	.size lj_BC_GGET, 24
lj_BC_GGET:
	.long 0xf85f0260,0xaa3c03fc,0x9240b800,0xf9400801
	.long 0xf87c7a9c,0x14000033

	.globl lj_BC_GSET
	.hidden lj_BC_GSET
	.type lj_BC_GSET, @function
	.size lj_BC_GSET, 24
lj_BC_GSET:
	.long 0xf85f0260,0xaa3c03fc,0x9240b800,0xf9400801
	.long 0xf87c7a9c,0x140000ab

	.globl lj_BC_TGETV
	.hidden lj_BC_TGETV
	.type lj_BC_TGETV, @function
	.size lj_BC_TGETV, 140
lj_BC_TGETV:
	.long 0xd3587e11,0x92401f9c,0xf8717a61,0xf87c7a69
	.long 0x936ffc2f,0xb10031ff,0x9240b821,0x54009841
	.long 0xeb49833f,0x540002a1,0xf9400822,0xb9403020
	.long 0x8b294c42,0x6b00013f,0x54009762,0xf9400048
	.long 0xeb1a011f,0x54000100,0xf83b7a68,0xb84046b0
	.long 0x8b300ec9,0xd3483e1b,0xf947b128,0xd3507e1c
	.long 0xd61f0100,0xf9401020,0xb4ffff00,0x39402809
	.long 0x3707fec9,0x140004ac,0x936ffd2f,0xb10015ff
	.long 0x54009521,0x9240b93c,0x1400000a

	.globl lj_BC_TGETS
	.hidden lj_BC_TGETS
	.type lj_BC_TGETS, @function
	.size lj_BC_TGETS, 148
lj_BC_TGETS:
	.long 0xd3587e11,0x92401f9c,0xf8717a61,0xaa3c03fc
	.long 0xf87c7a9c,0x936ffc2f,0xb10031ff,0x9240b821
	.long 0x540091e1,0xb9403429,0xb9400f8a,0xf9401422
	.long 0x0a0a0129,0x8b090529,0x92800083,0x8b090c42
	.long 0x8b03bf83,0xa9400048,0xf9400842,0xeb03001f
	.long 0x54000141,0xeb1a011f,0x54000140,0xf83b7a68
	.long 0xb84046b0,0x8b300ec9,0xd3483e1b,0xf947b128
	.long 0xd3507e1c,0xd61f0100,0xb5fffe62,0xaa1a03e8
	.long 0xf9401020,0xb4fffec0,0x39402809,0x3707fe89
	.long 0x14000477

	.globl lj_BC_TGETB
	.hidden lj_BC_TGETB
	.type lj_BC_TGETB, @function
	.size lj_BC_TGETB, 108
lj_BC_TGETB:
	.long 0xd3587e11,0x92401f9c,0xf8717a61,0x936ffc2f
	.long 0xb10031ff,0x9240b821,0x54008ec1,0xf9400822
	.long 0xb9403020,0x8b1c0c42,0x6b00039f,0x54008e22
	.long 0xf9400048,0xeb1a011f,0x54000100,0xf83b7a68
	.long 0xb84046b0,0x8b300ec9,0xd3483e1b,0xf947b128
	.long 0xd3507e1c,0xd61f0100,0xf9401020,0xb4ffff00
	.long 0x39402809,0x3707fec9,0x14000462

	.globl lj_BC_TGETR
	.hidden lj_BC_TGETR
	.type lj_BC_TGETR, @function
	.size lj_BC_TGETR, 72
lj_BC_TGETR:
	.long 0xd3587e11,0x92401f9c,0xf8717a60,0xf87c7a69
	.long 0x9240b800,0xf9400802,0xb940300a,0x8b294c42
	.long 0x6b0a013f,0x54008e82,0xf9400048,0xf83b7a68
	.long 0xb84046b0,0x8b300ec9,0xd3483e1b,0xf947b128
	.long 0xd3507e1c,0xd61f0100

	.globl lj_BC_TSETV
	.hidden lj_BC_TSETV
	.type lj_BC_TSETV, @function
	.size lj_BC_TSETV, 176
lj_BC_TSETV:
	.long 0xd3587e11,0x92401f9c,0xf8717a61,0xf87c7a69
	.long 0x936ffc2f,0xb10031ff,0x9240b821,0x54008f21
	.long 0xeb49833f,0x540003c1,0xf9400822,0xb9403020
	.long 0x8b294c42,0x6b00013f,0x54008e42,0xf9400049
	.long 0xf87b7a68,0x3940202a,0xeb1a013f,0x54000120
	.long 0xf9000048,0x3710018a,0xb84046b0,0x8b300ec9
	.long 0xd3483e1b,0xf947b128,0xd3507e1c,0xd61f0100
	.long 0xf9401020,0xb4fffee0,0x39402809,0x370ffea9
	.long 0x14000460,0xf94022c9,0x121d794a,0xf90022c1
	.long 0x3900202a,0xf9000c29,0x17fffff0,0x936ffd2f
	.long 0xb10015ff,0x54008ae1,0x9240b93c,0x1400000a

	.globl lj_BC_TSETS
	.hidden lj_BC_TSETS
	.type lj_BC_TSETS, @function
	.size lj_BC_TSETS, 252
lj_BC_TSETS:
	.long 0xd3587e11,0x92401f9c,0xf8717a61,0xaa3c03fc
	.long 0xf87c7a9c,0x936ffc2f,0xb10031ff,0x9240b821
	.long 0x540087a1,0xb9403429,0xb9400f8a,0xf9401422
	.long 0x0a0a0129,0x8b090529,0x92800083,0x8b090c42
	.long 0x8b03bf83,0x3900283f,0xa9400049,0xf940084b
	.long 0x3940202a,0xeb03001f,0x54000221,0xf87b7a68
	.long 0xeb1a013f,0x54000120,0xf9000048,0x371003ca
	.long 0xb84046b0,0x8b300ec9,0xd3483e1b,0xf947b128
	.long 0xd3507e1c,0xd61f0100,0xf9401020,0xb4fffee0
	.long 0x39402809,0x370ffea9,0x14000423,0xaa0b03e2
	.long 0xb5fffd4b,0xf9401020,0xb4000060,0x39402809
	.long 0x360883a9,0x92800089,0xf90057f5,0x8b09bf88
	.long 0xf90012f3,0xaa1703e0,0xf9005fe8,0x9102e3e2
	bl lj_tab_newkey
	.long 0xf94012f3,0xf87b7a68,0xf9000008,0x17ffffe4
	.long 0xf94022c9,0x121d794a,0xf90022c1,0x3900202a
	.long 0xf9000c29,0x17ffffde

	.globl lj_BC_TSETB
	.hidden lj_BC_TSETB
	.type lj_BC_TSETB, @function
	.size lj_BC_TSETB, 144
lj_BC_TSETB:
	.long 0xd3587e11,0x92401f9c,0xf8717a61,0x936ffc2f
	.long 0xb10031ff,0x9240b821,0x54008141,0xf9400822
	.long 0xb9403020,0x8b1c0c42,0x6b00039f,0x540080a2
	.long 0xf9400049,0xf87b7a68,0x3940202a,0xeb1a013f
	.long 0x54000120,0xf9000048,0x3710018a,0xb84046b0
	.long 0x8b300ec9,0xd3483e1b,0xf947b128,0xd3507e1c
	.long 0xd61f0100,0xf9401020,0xb4fffee0,0x39402809
	.long 0x370ffea9,0x140003f3,0xf94022c9,0x121d794a
	.long 0xf90022c1,0x3900202a,0xf9000c29,0x17fffff0

	.globl lj_BC_TSETM
	.hidden lj_BC_TSETM
	.type lj_BC_TSETM, @function
	.size lj_BC_TSETM, 148
lj_BC_TSETM:
	.long 0x8b1b0e7b,0xb940c3f1,0xf85f8361,0xf87c7a89
	.long 0xd1002231,0xb40001f1,0x9240b821,0xb9403020
	.long 0x0b510d22,0xf9400823,0xeb00005f,0x8b110371
	.long 0x540001c8,0x8b294c69,0x3940202a,0xf8408768
	.long 0xf8008528,0xeb11037f,0x54ffffa3,0x3710018a
	.long 0xb84046b0,0x8b300ec9,0xd3483e1b,0xf947b128
	.long 0xd3507e1c,0xd61f0100,0xf90012f3,0xaa1703e0
	.long 0xf90057f5
	bl lj_tab_reasize
	.long 0x17ffffe3,0xf94022c9,0x121d794a,0xf90022c1
	.long 0x3900202a,0xf9000c29,0x17fffff0

	.globl lj_BC_TSETR
	.hidden lj_BC_TSETR
	.type lj_BC_TSETR, @function
	.size lj_BC_TSETR, 104
lj_BC_TSETR:
	.long 0xd3587e11,0x92401f9c,0xf8717a61,0xf87c7a69
	.long 0x9240b821,0xf9400820,0x3940202a,0xb9403023
	.long 0x8b294c00,0x3710016a,0x6b03013f,0x54007b22
	.long 0xf87b7a68,0xf9000008,0xb84046b0,0x8b300ec9
	.long 0xd3483e1b,0xf947b128,0xd3507e1c,0xd61f0100
	.long 0xf94022c8,0x121d794a,0xf90022c1,0x3900202a
	.long 0xf9000c28,0x17fffff1

	.globl lj_BC_CALLM
	.hidden lj_BC_CALLM
	.type lj_BC_CALLM, @function
	.size lj_BC_CALLM, 16
lj_BC_CALLM:
	.long 0xb940c3e8,0xd37d1f9c,0x8b08039c,0x14000002

	.globl lj_BC_CALL
	.hidden lj_BC_CALL
	.type lj_BC_CALL, @function
	.size lj_BC_CALL, 72
lj_BC_CALL:
	.long 0xd37d1f9c,0xaa1303f1,0x8b1b0e73,0xf9400262
	.long 0xd100239c,0x91004273,0x936ffc4f,0xb10025ff
	.long 0x9240b842,0x54008321,0xf81f8275,0xf9401055
	.long 0xb84046b0,0x8b300ec9,0xd3483e1b,0xf947b128
	.long 0x8b1b0e7b,0xd61f0100

	.globl lj_BC_CALLMT
	.hidden lj_BC_CALLMT
	.type lj_BC_CALLMT, @function
	.size lj_BC_CALLMT, 12
lj_BC_CALLMT:
	.long 0xb940c3e8,0x8b1c0d1c,0x14000002

	.globl lj_BC_CALLT
	.hidden lj_BC_CALLT
	.type lj_BC_CALLT, @function
	.size lj_BC_CALLT, 188
lj_BC_CALLT:
	.long 0xd37df39c,0x8b1b0e7b,0xf9400369,0xd100239c
	.long 0x9100437b,0x936ffd2f,0xb10025ff,0x9240b922
	.long 0x540082c1,0xf85f8275,0x52800011,0x3940284a
	.long 0xf24006bf,0x54000321,0xf81f0269,0xb40000fc
	.long 0xf8716b68,0x91002229,0xeb1c013f,0xf8316a68
	.long 0xaa0903f1,0x54ffff61,0xf100055f,0x54000108
	.long 0xf9401055,0xb84046b0,0x8b300ec9,0xd3483e1b
	.long 0xf947b128,0x8b1b0e7b,0xd61f0100,0x385fd2bb
	.long 0xcb1b0e60,0xf85e0000,0x9240b800,0xf9401000
	.long 0xf85b8014,0x17fffff3,0xd24006b5,0xf2400abf
	.long 0x9a8a122a,0x54fffca1,0xcb150273,0xf85f8275
	.long 0xf24006bf,0x9a8a122a,0x17ffffe0

	.globl lj_BC_ITERC
	.hidden lj_BC_ITERC
	.type lj_BC_ITERC, @function
	.size lj_BC_ITERC, 80
lj_BC_ITERC:
	.long 0x8b1b0e7b,0xf85e8362,0xaa1303f1,0xa97f0760
	.long 0x91004373,0x5280021c,0xf9000362,0xa9010760
	.long 0x936ffc4f,0xb10025ff,0x9240b842,0x54007a61
	.long 0xf81f8275,0xf9401055,0xb84046b0,0x8b300ec9
	.long 0xd3483e1b,0xf947b128,0x8b1b0e7b,0xd61f0100

	.globl lj_BC_ITERN
	.hidden lj_BC_ITERN
	.type lj_BC_ITERN, @function
	.size lj_BC_ITERN, 164
lj_BC_ITERN:
	.long 0x8b1b0e7b,0xf85f0371,0x794006ab,0xb85f8360
	.long 0x910012b5,0x8b0b0aab,0x9240ba31,0xd140816b
	.long 0xb9403229,0xf9400a21,0xeb09001c,0x8b000c22
	.long 0x54000202,0xf9400048,0xeb1a011f,0x9a801400
	.long 0x54ffff40,0x8b180000,0xa9002360,0x91000400
	.long 0xb81f8360,0xaa0b03f5,0xb84046b0,0x8b300ec9
	.long 0xd3483e1b,0xf947b128,0xd3507e1c,0xd61f0100
	.long 0xb940362a,0xf9401631,0x8b1c0780,0xeb0a039f
	.long 0x8b000e22,0x54fffea8,0xa9400048,0xeb1a011f
	.long 0x9100079c,0x54ffff20,0xa9002360,0x8b090380
	.long 0x17ffffec

	.globl lj_BC_VARG
	.hidden lj_BC_VARG
	.type lj_BC_VARG, @function
	.size lj_BC_VARG, 188
lj_BC_VARG:
	.long 0xd3587e11,0x92401f9c,0xf85f8269,0x8b1c0e7c
	.long 0x8b1b0e7b,0x91000f9c,0x8b110f6a,0xcb09039c
	.long 0xd100426b,0xb40001d1,0xd100414a,0xeb0b039f
	.long 0xf8408788,0x9a9a3108,0xeb0a037f,0xf8008768
	.long 0x54ffff63,0xb84046b0,0x8b300ec9,0xd3483e1b
	.long 0xf947b128,0xd3507e1c,0xd61f0100,0xf9401ae8
	.long 0xeb1c016a,0x9a8ad3f1,0x91002231,0x8b0a0369
	.long 0xb900c3f1,0x54fffe8d,0xeb08013f,0x540000c8
	.long 0xf8408788,0xf8008768,0xeb0b039f,0x54ffffa3
	.long 0x17ffffed,0xd343fd41,0xa9026ef3,0xaa1703e0
	.long 0xcb13039c,0xf90057f5
	bl lj_state_growstack
	.long 0xa9426ef3,0x8b1c027c,0xd100426b,0x17fffff2

	.globl lj_BC_ISNEXT
	.hidden lj_BC_ISNEXT
	.type lj_BC_ISNEXT, @function
	.size lj_BC_ISNEXT, 120
lj_BC_ISNEXT:
	.long 0x8b1b0e7b,0xf85e8360,0x8b1c0abc,0xa97f0f62
	.long 0xd140839c,0x936ffc0f,0xb10025ff,0x9240b800
	.long 0x54000221,0x936ffc48,0x39402809,0xb100311f
	.long 0xfa5a0060,0x7a440920,0x54000161,0x320f77e8
	.long 0xd3607d08,0xf81f8368,0xaa1c03f5,0xb84046b0
	.long 0x8b300ec9,0xd3483e1b,0xf947b128,0xd3507e1c
	.long 0xd61f0100,0x52800b08,0x528008a9,0x381fc2a8
	.long 0x39000389,0x17fffff5

	.globl lj_BC_RETM
	.hidden lj_BC_RETM
	.type lj_BC_RETM, @function
	.size lj_BC_RETM, 20
lj_BC_RETM:
	.long 0xb940c3e8,0xf85f8275,0x8b1b0e7b,0x8b1c0d1c
	.long 0x14000004

	.globl lj_BC_RET
	.hidden lj_BC_RET
	.type lj_BC_RET, @function
	.size lj_BC_RET, 168
lj_BC_RET:
	.long 0xf85f8275,0xd37df39c,0x8b1b0e7b,0xb900c3fc
	.long 0xf24006a0,0xd24006a1,0x540003e1,0xb85fc2b0
	.long 0xf1002389,0xd1004262,0x540000c0,0xf8408768
	.long 0x91002273,0xd1002129,0xf81e8268,0xb5ffff89
	.long 0xd3483e1b,0xcb1b0c43,0xd3587e11,0xf85f0060
	.long 0xeb110f9f,0x54000163,0x9240b800,0xaa0303f3
	.long 0xf9401001,0xf85b8034,0xb84046b0,0x8b300ec9
	.long 0xd3483e1b,0xf947b128,0xd3507e1c,0xd61f0100
	.long 0x91002273,0x9100239c,0xf81e827a,0x17fffff1
	.long 0x8b1b0e7b,0xf240083f,0x54003061,0xcb010273
	.long 0xf85f8275,0x17ffffdb

	.globl lj_BC_RET0
	.hidden lj_BC_RET0
	.type lj_BC_RET0, @function
	.size lj_BC_RET0, 104
lj_BC_RET0:
	.long 0xf85f8275,0xd37df39c,0xb900c3fc,0xf24006a0
	.long 0xd24006a1,0x54fffea1,0xb85fc2b0,0xd1004263
	.long 0xd3483e1b,0xcb1b0c73,0xd3587e11,0xf85f0260
	.long 0xeb110f9f,0x54000143,0x9240b800,0xf9401001
	.long 0xf85b8034,0xb84046b0,0x8b300ec9,0xd3483e1b
	.long 0xf947b128,0xd3507e1c,0xd61f0100,0x9100239c
	.long 0xf800847a,0x17fffff3

	.globl lj_BC_RET1
	.hidden lj_BC_RET1
	.type lj_BC_RET1, @function
	.size lj_BC_RET1, 112
lj_BC_RET1:
	.long 0xf85f8275,0xd37df39c,0xb900c3fc,0xf24006a0
	.long 0xd24006a1,0x54fffb61,0xb85fc2b0,0xf87b7a68
	.long 0xd1004263,0xd3483e1b,0xcb1b0c73,0xf8008468
	.long 0xd3587e11,0xf85f0260,0xeb110f9f,0x54000143
	.long 0x9240b800,0xf9401001,0xf85b8034,0xb84046b0
	.long 0x8b300ec9,0xd3483e1b,0xf947b128,0xd3507e1c
	.long 0xd61f0100,0x9100239c,0xf800847a,0x17fffff3

	.globl lj_BC_FORI
	.hidden lj_BC_FORI
	.type lj_BC_FORI, @function
	.size lj_BC_FORI, 144
lj_BC_FORI:
	.long 0x8b1b0e7b,0xa9400760,0xf9400b62,0x8b1c0abc
	.long 0xd140839c,0xeb40833f,0x54000221,0xeb41833f
	.long 0x54006061,0xeb42833f,0x54006021,0x37f80142
	.long 0x6b01001f,0x9a95c395,0xf9000f60,0xb84046b0
	.long 0x8b300ec9,0xd3483e1b,0xf947b128,0xd3507e1c
	.long 0xd61f0100,0x6b00003f,0x17fffff7,0x6d400760
	.long 0x54005e63,0xeb41833f,0x54005e29,0xeb42833f
	.long 0x54005de9,0xfd000f60,0xb7f80082,0x1e612000
	.long 0x9a958395,0x17ffffee,0x1e602020,0x17fffffd

	.globl lj_BC_JFORI
	.hidden lj_BC_JFORI
	.type lj_BC_JFORI, @function
	.size lj_BC_JFORI, 156
lj_BC_JFORI:
	.long 0x8b1b0e7b,0xa9400760,0xf9400b62,0x8b1c0abc
	.long 0xd140839c,0xeb40833f,0x54000261,0xeb41833f
	.long 0x54005be1,0xeb42833f,0x54005ba1,0x37f80182
	.long 0x6b01001f,0xaa1c03f5,0x785fe39c,0xf9000f60
	.long 0x540011ed,0xb84046b0,0x8b300ec9,0xd3483e1b
	.long 0xf947b128,0xd3507e1c,0xd61f0100,0x6b00003f
	.long 0x17fffff5,0x6d400760,0x540059a3,0xeb41833f
	.long 0x54005969,0xeb42833f,0x54005929,0xfd000f60
	.long 0xb7f800a2,0x1e612000,0x785fe39c,0x54000f89
	.long 0x17ffffed,0x1e602020,0x17fffffc

	.globl lj_BC_FORL
	.hidden lj_BC_FORL
	.type lj_BC_FORL, @function
	.size lj_BC_FORL, 28
lj_BC_FORL:
	.long 0xd341fea0,0x927f1400,0x913b8000,0x78606ac1
	.long 0xf1000821,0x78206ac1,0x5400de83

	.globl lj_BC_IFORL
	.hidden lj_BC_IFORL
	.type lj_BC_IFORL, @function
	.size lj_BC_IFORL, 140
lj_BC_IFORL:
	.long 0x8b1b0e7b,0xa9400760,0xf9400b62,0x8b1c0abc
	.long 0xd140839c,0xeb40833f,0x54000221,0x2b020000
	.long 0x540000e6,0x8b180008,0x37f80162,0x6b01001f
	.long 0x9a95d395,0xf9000368,0xf9000f68,0xb84046b0
	.long 0x8b300ec9,0xd3483e1b,0xf947b128,0xd3507e1c
	.long 0xd61f0100,0x6b00003f,0x17fffff6,0x6d400760
	.long 0x54005423,0xfd400b62,0x1e622800,0xb7f800c2
	.long 0x1e612000,0xfd000360,0xfd000f60,0x9a959395
	.long 0x17ffffef,0x1e602020,0x17fffffb

	.globl lj_BC_JFORL
	.hidden lj_BC_JFORL
	.type lj_BC_JFORL, @function
	.size lj_BC_JFORL, 132
lj_BC_JFORL:
	.long 0x8b1b0e7b,0xa9400760,0xf9400b62,0xeb40833f
	.long 0x54000221,0x2b020000,0x540000e6,0x8b180008
	.long 0x37f80162,0x6b01001f,0xf9000368,0xf9000f68
	.long 0x5400084d,0xb84046b0,0x8b300ec9,0xd3483e1b
	.long 0xf947b128,0xd3507e1c,0xd61f0100,0x6b00003f
	.long 0x17fffff6,0x6d400760,0x54005003,0xfd400b62
	.long 0x1e622800,0xb7f800c2,0x1e612000,0xfd000360
	.long 0xfd000f60,0x54000629,0x17ffffef,0x1e602020
	.long 0x17fffffb

	.globl lj_BC_ITERL
	.hidden lj_BC_ITERL
	.type lj_BC_ITERL, @function
	.size lj_BC_ITERL, 28
lj_BC_ITERL:
	.long 0xd341fea0,0x927f1400,0x913b8000,0x78606ac1
	.long 0xf1000821,0x78206ac1,0x5400d523

	.globl lj_BC_IITERL
	.hidden lj_BC_IITERL
	.type lj_BC_IITERL, @function
	.size lj_BC_IITERL, 52
lj_BC_IITERL:
	.long 0xf87b7a60,0x8b1b0e69,0xeb1a001f,0x54000080
	.long 0x8b1c0aa8,0xd1408115,0xf81f8120,0xb84046b0
	.long 0x8b300ec9,0xd3483e1b,0xf947b128,0xd3507e1c
	.long 0xd61f0100

	.globl lj_BC_JITERL
	.hidden lj_BC_JITERL
	.type lj_BC_JITERL, @function
	.size lj_BC_JITERL, 48
lj_BC_JITERL:
	.long 0xf87b7a60,0x8b1b0e69,0xeb1a001f,0x54000060
	.long 0xf81f8120,0x14000014,0xb84046b0,0x8b300ec9
	.long 0xd3483e1b,0xf947b128,0xd3507e1c,0xd61f0100

	.globl lj_BC_LOOP
	.hidden lj_BC_LOOP
	.type lj_BC_LOOP, @function
	.size lj_BC_LOOP, 28
lj_BC_LOOP:
	.long 0xd341fea0,0x927f1400,0x913b8000,0x78606ac1
	.long 0xf1000821,0x78206ac1,0x5400d123

	.globl lj_BC_ILOOP
	.hidden lj_BC_ILOOP
	.type lj_BC_ILOOP, @function
	.size lj_BC_ILOOP, 24
lj_BC_ILOOP:
	.long 0xb84046b0,0x8b300ec9,0xd3483e1b,0xf947b128
	.long 0xd3507e1c,0xd61f0100

	.globl lj_BC_JLOOP
	.hidden lj_BC_JLOOP
	.type lj_BC_JLOOP, @function
	.size lj_BC_JLOOP, 36
lj_BC_JLOOP:
	.long 0xf94222c0,0x52800001,0xf87c781c,0xb900bac1
	.long 0xf9402f9b,0xf900bed3,0xf90072d7,0xd10043ff
	.long 0xd61f0360

	.globl lj_BC_JMP
	.hidden lj_BC_JMP
	.type lj_BC_JMP, @function
	.size lj_BC_JMP, 32
lj_BC_JMP:
	.long 0x8b1c0abc,0xd1408395,0xb84046b0,0x8b300ec9
	.long 0xd3483e1b,0xf947b128,0xd3507e1c,0xd61f0100

	.globl lj_BC_FUNCF
	.hidden lj_BC_FUNCF
	.type lj_BC_FUNCF, @function
	.size lj_BC_FUNCF, 28
lj_BC_FUNCF:
	.long 0xd341fea0,0x927f1400,0x913b8000,0x78606ac1
	.long 0xf1000421,0x78206ac1,0x5400cf43

	.globl lj_BC_IFUNCF
	.hidden lj_BC_IFUNCF
	.type lj_BC_IFUNCF, @function
	.size lj_BC_IFUNCF, 64
lj_BC_IFUNCF:
	.long 0xf9401ae0,0x3859e2a9,0xf85b42b4,0xeb00037f
	.long 0x54001648,0xeb090f9f,0x540000e3,0xb84046b0
	.long 0x8b300ec9,0xd3483e1b,0xf947b128,0xd3507e1c
	.long 0xd61f0100,0xf83c6a7a,0x9100239c,0x17fffff6

	.globl lj_BC_JFUNCF
	.hidden lj_BC_JFUNCF
	.type lj_BC_JFUNCF, @function
	.size lj_BC_JFUNCF, 48
lj_BC_JFUNCF:
	.long 0xf9401ae0,0x3859e2a9,0xf85b42b4,0xeb00037f
	.long 0x54001448,0xeb090f9f,0x54000063,0xd3507e1c
	.long 0x17ffffd0,0xf83c6a7a,0x9100239c,0x17fffffa

	.globl lj_BC_FUNCV
	.hidden lj_BC_FUNCV
	.type lj_BC_FUNCV, @function
	.size lj_BC_FUNCV, 0
lj_BC_FUNCV:

	.globl lj_BC_IFUNCV
	.hidden lj_BC_IFUNCV
	.type lj_BC_IFUNCV, @function
	.size lj_BC_IFUNCV, 132
lj_BC_IFUNCV:
	.long 0xf9401ae0,0x92800108,0x8b1c026a,0x8b08bc42
	.long 0x8b1c037b,0x91004f88,0xf8008542,0xf85b42b4
	.long 0xeb00037f,0xf8008548,0x54001202,0xd100415c
	.long 0x3859e2a9,0xaa1303fb,0xaa0a03f3,0xb4000109
	.long 0xeb1c037f,0x54000182,0xf9400368,0xd1000529
	.long 0xf800877a,0xf8008548,0xb5ffff49,0xb84046b0
	.long 0x8b300ec9,0xd3483e1b,0xf947b128,0xd3507e1c
	.long 0xd61f0100,0xd1000529,0xf800855a,0xb4ffff09
	.long 0x17fffffd

	.globl lj_BC_JFUNCV
	.hidden lj_BC_JFUNCV
	.type lj_BC_JFUNCV, @function
	.size lj_BC_JFUNCV, 4
lj_BC_JFUNCV:
	.long 0xd4200000

	.globl lj_BC_FUNCC
	.hidden lj_BC_FUNCC
	.type lj_BC_FUNCC, @function
	.size lj_BC_FUNCC, 72
lj_BC_FUNCC:
	.long 0xf9401443,0x8b1c0361,0xf9401ae0,0x8b1c027c
	.long 0xeb00003f,0xa90272f3,0x12800028,0xaa1703e0
	.long 0x54000dc8,0xb900bac8,0xd63f0060,0xa94226f3
	.long 0xf900bad7,0x937d7c1c,0xb900bada,0xf85f8275
	.long 0xcb1c013b,0x14000019

	.globl lj_BC_FUNCCW
	.hidden lj_BC_FUNCCW
	.type lj_BC_FUNCCW, @function
	.size lj_BC_FUNCCW, 76
lj_BC_FUNCCW:
	.long 0xf940aec3,0x8b1c0361,0xf9401ae0,0x8b1c027c
	.long 0xeb00003f,0xa90272f3,0xf9401441,0x12800028
	.long 0xaa1703e0,0x54000b68,0xb900bac8,0xd63f0060
	.long 0xa94226f3,0xf900bad7,0x937d7c1c,0xb900bada
	.long 0xf85f8275,0xcb1c013b,0x14000006

	.globl lj_vm_returnp
	.hidden lj_vm_returnp
	.type lj_vm_returnp, @function
	.size lj_vm_returnp, 20
lj_vm_returnp:
	.long 0x36101c75,0xf85f8235,0x92e00028,0xaa1103f3
	.long 0xf81f8f68

	.globl lj_vm_returnc
	.hidden lj_vm_returnc
	.type lj_vm_returnc, @function
	.size lj_vm_returnc, 24
lj_vm_returnc:
	.long 0xb100239c,0x52800020,0x540006e0,0xb900c3fc
	.long 0xf24006a0,0x54ffcbe0

	.globl lj_vm_return
	.hidden lj_vm_return
	.type lj_vm_return, @function
	.size lj_vm_return, 72
lj_vm_return:
	.long 0x927df2b1,0xf100041f,0xcb110271,0x54fffe41
	.long 0xf90012f1,0xb980cbe1,0x12800028,0xd1004273
	.long 0xf100238a,0xb900bac8,0x540000a0,0xf100214a
	.long 0xf8408768,0xf8008668,0x54ffffa1,0xeb010f9f
	.long 0x54000201,0xf90016f3

	.globl lj_vm_leave_cp
	.hidden lj_vm_leave_cp
	.type lj_vm_leave_cp, @function
	.size lj_vm_leave_cp, 12
lj_vm_leave_cp:
	.long 0xf94053fc,0x52800000,0xf9002afc

	.globl lj_vm_leave_unw
	.hidden lj_vm_leave_unw
	.type lj_vm_leave_unw, @function
	.size lj_vm_leave_unw, 112
lj_vm_leave_unw:
	.long 0xa94153f3,0x6d4627e8,0xa9425bf5,0x6d472fea
	.long 0xa94363f7,0x6d4837ec,0xa9446bf9,0x6d493fee
	.long 0xa94573fb,0xa8cd7bfd,0xd65f03c0,0x540000ec
	.long 0xf9401ae2,0xeb02027f,0x54000102,0xf800867a
	.long 0x9100239c,0x17ffffe9,0xb4fffd41,0xcb010f80
	.long 0xcb000273,0x17ffffe7,0xf90016f3,0xaa1703e0
	bl lj_state_growstack
	.long 0xf94016f3,0xb980cbe1,0x17ffffdf

	.globl lj_vm_unwind_c
	.hidden lj_vm_unwind_c
	.type lj_vm_unwind_c, @function
	.size lj_vm_unwind_c, 8
lj_vm_unwind_c:
	.long 0x9100001f,0xaa0103e0

	.globl lj_vm_unwind_c_eh
	.hidden lj_vm_unwind_c_eh
	.type lj_vm_unwind_c_eh, @function
	.size lj_vm_unwind_c_eh, 20
lj_vm_unwind_c_eh:
	.long 0xf9405bf7,0x12800028,0xf9400af6,0xb900bac8
	.long 0x17ffffde

	.globl lj_vm_unwind_ff
	.hidden lj_vm_unwind_ff
	.type lj_vm_unwind_ff, @function
	.size lj_vm_unwind_ff, 4
lj_vm_unwind_ff:
	.long 0x927ef41f

	.globl lj_vm_unwind_ff_eh
	.hidden lj_vm_unwind_ff_eh
	.type lj_vm_unwind_ff_eh, @function
	.size lj_vm_unwind_ff_eh, 52
lj_vm_unwind_ff_eh:
	.long 0xf9405bf7,0xd2ffff38,0xd2bfff39,0x9280001a
	.long 0x5280021c,0xf94012f3,0xf9400af6,0x92d00008
	.long 0xd100227b,0xf85f8275,0xf81f8268,0xb900bada
	.long 0x17ffffb5

	.globl lj_vm_growstack_c
	.hidden lj_vm_growstack_c
	.type lj_vm_growstack_c, @function
	.size lj_vm_growstack_c, 8
lj_vm_growstack_c:
	.long 0x52800281,0x14000007

	.globl lj_vm_growstack_l
	.hidden lj_vm_growstack_l
	.type lj_vm_growstack_l, @function
	.size lj_vm_growstack_l, 76
lj_vm_growstack_l:
	.long 0x8b1c027c,0xcb13037b,0xaa1703e0,0xa90272f3
	.long 0x910012b5,0xd343ff61,0xf90057f5
	bl lj_state_growstack
	.long 0xa94272f3,0xf85f0262,0xcb13039c,0x9240b842
	.long 0xf9401055,0xb84046b0,0x8b300ec9,0xd3483e1b
	.long 0xf947b128,0x8b1b0e7b,0xd61f0100

	.globl lj_vm_resume
	.hidden lj_vm_resume
	.type lj_vm_resume, @function
	.size lj_vm_resume, 156
lj_vm_resume:
	.long 0xa9b37bfd,0x910003fd,0xa90153f3,0x6d0627e8
	.long 0xa9025bf5,0x6d072fea,0xa90363f7,0x6d0837ec
	.long 0xa9046bf9,0x6d093fee,0xa90573fb,0xaa0003f7
	.long 0xf9400af6,0xaa0103f3,0xf9005bf7,0x528000b5
	.long 0xb900cbff,0x910007e8,0x39402ee9,0xb900c7ff
	.long 0xf90057f7,0xf90053ff,0xf9002ae8,0x34000669
	.long 0xf900bad7,0xaa1303fb,0xa94202f3,0xd2ffff38
	.long 0xd2bfff39,0xf85f8275,0x39002eff,0x9280001a
	.long 0xcb13001c,0xf24006a0,0x9100239c,0xb900bada
	.long 0xb900c3fc,0x54ffbbc0,0x17ffff7f

	.globl lj_vm_pcall
	.hidden lj_vm_pcall
	.type lj_vm_pcall, @function
	.size lj_vm_pcall, 56
lj_vm_pcall:
	.long 0xa9b37bfd,0x910003fd,0xa90153f3,0x6d0627e8
	.long 0xa9025bf5,0x6d072fea,0xa90363f7,0x6d0837ec
	.long 0xa9046bf9,0x6d093fee,0xa90573fb,0x528000b5
	.long 0xb900c7e3,0x1400000d

	.globl lj_vm_call
	.hidden lj_vm_call
	.type lj_vm_call, @function
	.size lj_vm_call, 120
lj_vm_call:
	.long 0xa9b37bfd,0x910003fd,0xa90153f3,0x6d0627e8
	.long 0xa9025bf5,0x6d072fea,0xa90363f7,0x6d0837ec
	.long 0xa9046bf9,0x6d093fee,0xa90573fb,0x52800035
	.long 0xf940281c,0xb900cbe2,0xaa0003f7,0xf9005be0
	.long 0xf9400af6,0xaa0103f3,0xf90057e0,0xf90053fc
	.long 0xf9002afd,0xf900bad7,0xa94202f1,0xd2ffff38
	.long 0xd2bfff39,0x8b1302b5,0x9280001a,0xcb1102b5
	.long 0xcb13001c,0xb900bada

	.globl lj_vm_call_dispatch
	.hidden lj_vm_call_dispatch
	.type lj_vm_call_dispatch, @function
	.size lj_vm_call_dispatch, 20
lj_vm_call_dispatch:
	.long 0xf85f0262,0x936ffc4f,0xb10025ff,0x9240b842
	.long 0x54001e81

	.globl lj_vm_call_dispatch_f
	.hidden lj_vm_call_dispatch_f
	.type lj_vm_call_dispatch_f, @function
	.size lj_vm_call_dispatch_f, 32
lj_vm_call_dispatch_f:
	.long 0xf81f8275,0xf9401055,0xb84046b0,0x8b300ec9
	.long 0xd3483e1b,0xf947b128,0x8b1b0e7b,0xd61f0100

	.globl lj_vm_cpcall
	.hidden lj_vm_cpcall
	.type lj_vm_cpcall, @function
	.size lj_vm_cpcall, 116
lj_vm_cpcall:
	.long 0xa9b37bfd,0x910003fd,0xa90153f3,0x6d0627e8
	.long 0xa9025bf5,0x6d072fea,0xa90363f7,0x6d0837ec
	.long 0xa9046bf9,0x6d093fee,0xa90573fb,0xaa0003f7
	.long 0xf9401c1b,0xf9005be0,0xf9400af6,0xf94016f1
	.long 0xf90057e0,0xf9402afc,0xcb11037b,0xb900cbfb
	.long 0xb900c7ff,0xf90053fc,0xf9002afd,0xf900bad7
	.long 0xd63f0060,0xaa0003f3,0x528000b5,0xb5fff9f3
	.long 0x17ffff3b

	.globl lj_cont_dispatch
	.hidden lj_cont_dispatch
	.type lj_cont_dispatch, @function
	.size lj_cont_dispatch, 68
lj_cont_dispatch:
	.long 0xf85f0222,0xf85e0260,0xaa1303e3,0xaa1103f3
	.long 0x9240b842,0xf100041f,0xf85e8075,0xf9401042
	.long 0x8b1c0368,0xf81f811a,0x54000069,0xf85b8054
	.long 0xd61f0000,0x5400c080,0xd1008063,0xcb13007c
	.long 0x140004d4

	.globl lj_cont_cat
	.hidden lj_cont_cat
	.type lj_cont_cat, @function
	.size lj_cont_cat, 56
lj_cont_cat:
	.long 0xb85fc2b0,0xd1008061,0xf9400368,0xf90012f3
	.long 0xd3587e11,0xd3483e1b,0x8b110e69,0xeb090029
	.long 0x54000080,0xf9000028,0xd343fd22,0x17fffa49
	.long 0xf83b7a68,0x14000069

	.globl lj_vmeta_tgets1
	.hidden lj_vmeta_tgets1
	.type lj_vmeta_tgets1, @function
	.size lj_vmeta_tgets1, 16
lj_vmeta_tgets1:
	.long 0x92800083,0x8b110e61,0x8b03bf83,0x14000004

	.globl lj_vmeta_tgets
	.hidden lj_vmeta_tgets
	.type lj_vmeta_tgets, @function
	.size lj_vmeta_tgets, 24
lj_vmeta_tgets:
	.long 0xf2ffff41,0xf90076c1,0x9103a2c1,0x9102e3e2
	.long 0xf9005fe3,0x14000008

	.globl lj_vmeta_tgetb
	.hidden lj_vmeta_tgetb
	.type lj_vmeta_tgetb, @function
	.size lj_vmeta_tgetb, 20
lj_vmeta_tgetb:
	.long 0x8b18039c,0x8b110e61,0x9102e3e2,0xf9005ffc
	.long 0x14000003

	.globl lj_vmeta_tgetv
	.hidden lj_vmeta_tgetv
	.type lj_vmeta_tgetv, @function
	.size lj_vmeta_tgetv, 92
lj_vmeta_tgetv:
	.long 0x8b110e61,0x8b1c0e62,0xf90012f3,0xaa1703e0
	.long 0xf90057f5
	bl lj_meta_tget
	.long 0xb4000120,0xf9400008,0xf83b7a68,0xb84046b0
	.long 0x8b300ec9,0xd3483e1b,0xf947b128,0xd3507e1c
	.long 0xd61f0100,0xd1000a69,0xf94016f3,0x5280021c
	.long 0xf85f0262,0xf81e8275,0xcb090275,0x9240b842
	.long 0x17ffff97

	.globl lj_vmeta_tgetr
	.hidden lj_vmeta_tgetr
	.type lj_vmeta_tgetr, @function
	.size lj_vmeta_tgetr, 24
lj_vmeta_tgetr:
	.long 0x93407d21
	bl lj_tab_getinth
	.long 0xaa1a03e8,0xb4ff7160,0xf9400008,0x17fffb89

	.globl lj_vmeta_tsets1
	.hidden lj_vmeta_tsets1
	.type lj_vmeta_tsets1, @function
	.size lj_vmeta_tsets1, 16
lj_vmeta_tsets1:
	.long 0x92800083,0x8b110e61,0x8b03bf83,0x14000004

	.globl lj_vmeta_tsets
	.hidden lj_vmeta_tsets
	.type lj_vmeta_tsets, @function
	.size lj_vmeta_tsets, 24
lj_vmeta_tsets:
	.long 0xf2ffff41,0xf90076c1,0x9103a2c1,0x9102e3e2
	.long 0xf9005fe3,0x14000008

	.globl lj_vmeta_tsetb
	.hidden lj_vmeta_tsetb
	.type lj_vmeta_tsetb, @function
	.size lj_vmeta_tsetb, 20
lj_vmeta_tsetb:
	.long 0x8b18039c,0x8b110e61,0x9102e3e2,0xf9005ffc
	.long 0x14000003

	.globl lj_vmeta_tsetv
	.hidden lj_vmeta_tsetv
	.type lj_vmeta_tsetv, @function
	.size lj_vmeta_tsetv, 96
lj_vmeta_tsetv:
	.long 0x8b110e61,0x8b1c0e62,0xf90012f3,0xaa1703e0
	.long 0xf90057f5
	bl lj_meta_tset
	.long 0xf87b7a68,0xb4000100,0xf9000008,0xb84046b0
	.long 0x8b300ec9,0xd3483e1b,0xf947b128,0xd3507e1c
	.long 0xd61f0100,0xd1000a69,0xf94016f3,0x5280031c
	.long 0xf85f0262,0xf9000a68,0xf81e8275,0xcb090275
	.long 0x9240b842,0x17ffff6a

	.globl lj_vmeta_tsetr
	.hidden lj_vmeta_tsetr
	.type lj_vmeta_tsetr, @function
	.size lj_vmeta_tsetr, 24
lj_vmeta_tsetr:
	.long 0x93407d22,0xf90012f3,0xaa1703e0,0xf90057f5
	bl lj_tab_setinth
	.long 0x17fffc23

	.globl lj_vmeta_comp
	.hidden lj_vmeta_comp
	.type lj_vmeta_comp, @function
	.size lj_vmeta_comp, 60
lj_vmeta_comp:
	.long 0x8b1b0e61,0xd10012b5,0x8b1c0e62,0xf90012f3
	.long 0xaa1703e0,0xf90057f5,0x53001e03
	bl lj_meta_comp
	.long 0xf100041f,0x54000828,0x794006b1,0x910012b5
	.long 0x8b110ab1,0xd1408231,0x9a9132b5

	.globl lj_cont_nop
	.hidden lj_cont_nop
	.type lj_cont_nop, @function
	.size lj_cont_nop, 24
lj_cont_nop:
	.long 0xb84046b0,0x8b300ec9,0xd3483e1b,0xf947b128
	.long 0xd3507e1c,0xd61f0100

	.globl lj_cont_ra
	.hidden lj_cont_ra
	.type lj_cont_ra, @function
	.size lj_cont_ra, 20
lj_cont_ra:
	.long 0xb85fc2b0,0xf9400368,0xd3483e09,0xf8297a68
	.long 0x17fffff6

	.globl lj_cont_condt
	.hidden lj_cont_condt
	.type lj_cont_condt, @function
	.size lj_cont_condt, 16
lj_cont_condt:
	.long 0xf9400368,0x92e00029,0xeb08013f,0x17ffffed

	.globl lj_cont_condf
	.hidden lj_cont_condf
	.type lj_cont_condf, @function
	.size lj_cont_condf, 16
lj_cont_condf:
	.long 0xf9400368,0x92d00009,0xeb09011f,0x17ffffe9

	.globl lj_vmeta_equal
	.hidden lj_vmeta_equal
	.type lj_vmeta_equal, @function
	.size lj_vmeta_equal, 28
lj_vmeta_equal:
	.long 0x9240b842,0xd10012b5,0xf90012f3,0xaa1703e0
	.long 0xf90057f5
	bl lj_meta_equal
	.long 0x17ffffe0

	.globl lj_vmeta_equal_cd
	.hidden lj_vmeta_equal_cd
	.type lj_vmeta_equal_cd, @function
	.size lj_vmeta_equal_cd, 28
lj_vmeta_equal_cd:
	.long 0xd10012b5,0xf90012f3,0xaa1703e0,0xaa1003e1
	.long 0xf90057f5
	bl lj_meta_equal_cd
	.long 0x17ffffd9

	.globl lj_vmeta_istype
	.hidden lj_vmeta_istype
	.type lj_vmeta_istype, @function
	.size lj_vmeta_istype, 32
lj_vmeta_istype:
	.long 0xd10012b5,0xf90012f3,0xaa1703e0,0xaa1b03e1
	.long 0xaa1c03e2,0xf90057f5
	bl lj_meta_istype
	.long 0x17ffffd8

	.globl lj_vmeta_arith_vn
	.hidden lj_vmeta_arith_vn
	.type lj_vmeta_arith_vn, @function
	.size lj_vmeta_arith_vn, 12
lj_vmeta_arith_vn:
	.long 0x8b110e62,0x8b1c0e83,0x14000009

	.globl lj_vmeta_arith_nv
	.hidden lj_vmeta_arith_nv
	.type lj_vmeta_arith_nv, @function
	.size lj_vmeta_arith_nv, 12
lj_vmeta_arith_nv:
	.long 0x8b110e63,0x8b1c0e82,0x14000006

	.globl lj_vmeta_unm
	.hidden lj_vmeta_unm
	.type lj_vmeta_unm, @function
	.size lj_vmeta_unm, 12
lj_vmeta_unm:
	.long 0x8b1c0e62,0xaa0203e3,0x14000003

	.globl lj_vmeta_arith_vv
	.hidden lj_vmeta_arith_vv
	.type lj_vmeta_arith_vv, @function
	.size lj_vmeta_arith_vv, 36
lj_vmeta_arith_vv:
	.long 0x8b110e62,0x8b1c0e63,0x53001e04,0x8b1b0e61
	.long 0xf90012f3,0xaa1703e0,0xf90057f5
	bl lj_meta_arith
	.long 0xb4fff8c0

	.globl lj_vmeta_binop
	.hidden lj_vmeta_binop
	.type lj_vmeta_binop, @function
	.size lj_vmeta_binop, 24
lj_vmeta_binop:
	.long 0xcb130009,0xf81e8015,0x91000935,0xaa0003f3
	.long 0x5280021c,0x17ffff0f

	.globl lj_vmeta_len
	.hidden lj_vmeta_len
	.type lj_vmeta_len, @function
	.size lj_vmeta_len, 24
lj_vmeta_len:
	.long 0x8b1c0e61,0xf90012f3,0xaa1703e0,0xf90057f5
	bl lj_meta_len
	.long 0x17fffff5

	.globl lj_vmeta_call
	.hidden lj_vmeta_call
	.type lj_vmeta_call, @function
	.size lj_vmeta_call, 68
lj_vmeta_call:
	.long 0xaa1703e0,0xf90012f1,0xd1004261,0xf90057f5
	.long 0x8b1c0262
	bl lj_meta_call
	.long 0xf85f0262,0x9100239c,0x9240b842,0xf81f8275
	.long 0xf9401055,0xb84046b0,0x8b300ec9,0xd3483e1b
	.long 0xf947b128,0x8b1b0e7b,0xd61f0100

	.globl lj_vmeta_callt
	.hidden lj_vmeta_callt
	.type lj_vmeta_callt, @function
	.size lj_vmeta_callt, 44
lj_vmeta_callt:
	.long 0xaa1703e0,0xf90012f3,0xd1004361,0xf90057f5
	.long 0x8b1c0362
	bl lj_meta_call
	.long 0xf85f0369,0xf85f8275,0x9100239c,0x9240b922
	.long 0x17fffbe2

	.globl lj_vmeta_for
	.hidden lj_vmeta_for
	.type lj_vmeta_for, @function
	.size lj_vmeta_for, 48
lj_vmeta_for:
	.long 0xaa1703e0,0xf90012f3,0xaa1b03e1,0xf90057f5
	bl lj_meta_for
	.long 0xb85fc2b0,0x53001e08,0xd3483e1b,0xd3507e1c
	.long 0xf101391f,0x54ffa1e0,0x17fffcea

	.globl lj_ff_assert
	.hidden lj_ff_assert
	.type lj_ff_assert, @function
	.size lj_ff_assert, 68
lj_ff_assert:
	.long 0xf9400260,0xf100239f,0x540079e3,0xf85f8275
	.long 0x92d00009,0xeb09001f,0x54007962,0xf81f0260
	.long 0xd1002271,0xf100239b,0x9100239c,0xb40032fb
	.long 0xf9400a20,0xd100237b,0xf8008620,0xb5ffffbb
	.long 0x14000192

	.globl lj_ff_type
	.hidden lj_ff_type
	.type lj_ff_type, @function
	.size lj_ff_type, 40
lj_ff_type:
	.long 0xf9400260,0xf100239f,0x540077c3,0x528001a8
	.long 0x936ffc0f,0xb10035ff,0xda8f3109,0x91001929
	.long 0xf8697840,0x14000185

	.globl lj_ff_getmetatable
	.hidden lj_ff_getmetatable
	.type lj_ff_getmetatable, @function
	.size lj_ff_getmetatable, 148
lj_ff_getmetatable:
	.long 0xf9400260,0xf100239f,0x54007683,0x936ffc0f
	.long 0xb10031ff,0xba4d19e4,0x9240b800,0x54000301
	.long 0xf9401011,0xaa1a03e0,0xf9411adc,0xb4002f31
	.long 0xb9403629,0xb9400f8a,0xf9401622,0x0a0a0129
	.long 0x8b090529,0x92800083,0x8b090c42,0x8b03bf83
	.long 0xa9402040,0xf9400842,0xeb03011f,0x540000a0
	.long 0xb5ffff82,0xaa1103e0,0xf2ffff40,0x14000169
	.long 0xeb1a011f,0x54002ce1,0x17fffffb,0x928001a8
	.long 0xeb0801ff,0x9a8821ef,0xcb0f0ec9,0xf9412931
	.long 0x17ffffe5

	.globl lj_ff_setmetatable
	.hidden lj_ff_setmetatable
	.type lj_ff_setmetatable, @function
	.size lj_ff_setmetatable, 88
lj_ff_setmetatable:
	.long 0xa9400660,0xf100439f,0x540071e3,0x936ffc0f
	.long 0xb10031ff,0x9240b809,0x54007161,0xf9401128
	.long 0x936ffc2f,0x3940212a,0xb10031ff,0x9240b821
	.long 0xfa400900,0x54007081,0xf9001121,0x36102a0a
	.long 0xf94022c8,0x121d794a,0xf90022c9,0x3900212a
	.long 0xf9000d28,0x1400014a

	.globl lj_ff_rawget
	.hidden lj_ff_rawget
	.type lj_ff_rawget, @function
	.size lj_ff_rawget, 48
lj_ff_rawget:
	.long 0xf9400261,0xf100439f,0x54006f23,0x936ffc2f
	.long 0xb10031ff,0x9240b821,0x54006ea1,0xaa1703e0
	.long 0x91002262
	bl lj_tab_get
	.long 0xf9400000,0x1400013e

	.globl lj_ff_tonumber
	.hidden lj_ff_tonumber
	.type lj_ff_tonumber, @function
	.size lj_ff_tonumber, 24
lj_ff_tonumber:
	.long 0xf9400260,0xf100239f,0x54006da1,0xeb40833f
	.long 0x54006d63,0x14000138

	.globl lj_ff_tostring
	.hidden lj_ff_tostring
	.type lj_ff_tostring, @function
	.size lj_ff_tostring, 92
lj_ff_tostring:
	.long 0xf9400260,0xf100239f,0x54006ce3,0x936ffc0f
	.long 0xb10015ff,0x54002640,0xf94162c9,0xf90012f3
	.long 0xb10039ff,0xfa409920,0xf90057f5,0x54006bc1
	.long 0xa94106c0,0xeb01001f,0x5400004b,0x94000384
	.long 0xaa1703e0,0xaa1303e1
	bl lj_strfmt_number
	.long 0x92800089,0xf94012f3,0x8b09bc00,0x14000121

	.globl lj_ff_next
	.hidden lj_ff_next
	.type lj_ff_next, @function
	.size lj_ff_next, 80
lj_ff_next:
	.long 0xf9400260,0xf100239f,0x54006a03,0x936ffc0f
	.long 0xb10031ff,0x9240b801,0x54006981,0xf83c6a7a
	.long 0xf85f8275,0xa9024ef3,0xaa1703e0,0x91002262
	.long 0xf90057f5
	bl lj_tab_next
	.long 0xf81f027a,0xb4002260,0xa9408660,0x5280031c
	.long 0xa93f0660,0x14000110

	.globl lj_ff_pairs
	.hidden lj_ff_pairs
	.type lj_ff_pairs, @function
	.size lj_ff_pairs, 52
lj_ff_pairs:
	.long 0xf9400260,0xf100239f,0x54006783,0x936ffc0f
	.long 0xb10031ff,0x9240b809,0x54006701,0xf9401843
	.long 0xf85f8275,0x5280041c,0xa93fea60,0xf81f0263
	.long 0x14000103

	.globl lj_ff_ipairs_aux
	.hidden lj_ff_ipairs_aux
	.type lj_ff_ipairs_aux, @function
	.size lj_ff_ipairs_aux, 120
lj_ff_ipairs_aux:
	.long 0xa9400660,0xf100439f,0x540065e3,0x936ffc0f
	.long 0xb10031ff,0x9240b800,0x54006561,0xeb41833f
	.long 0x54006521,0xb9403009,0xf9400802,0xb9403408
	.long 0x11000421,0x6b09003f,0xf85f8275,0x8b18002a
	.long 0x5280011c,0xf81f026a,0x540000e2,0xf8617848
	.long 0x52800309,0xeb1a011f,0xf81f8268,0x9a89039c
	.long 0x140000ea,0x34001d28
	bl lj_tab_getinth
	.long 0xb4001ce0,0xf9400008,0x17fffff7

	.globl lj_ff_ipairs
	.hidden lj_ff_ipairs
	.type lj_ff_ipairs, @function
	.size lj_ff_ipairs, 52
lj_ff_ipairs:
	.long 0xf9400260,0xf100239f,0x54006223,0x936ffc0f
	.long 0xb10031ff,0x9240b809,0x540061a1,0xf9401843
	.long 0xf85f8275,0x5280041c,0xa93fe260,0xf81f0263
	.long 0x140000d8

	.globl lj_ff_pcall
	.hidden lj_ff_pcall
	.type lj_ff_pcall, @function
	.size lj_ff_pcall, 56
lj_ff_pcall:
	.long 0x394246c8,0xf100239c,0x54006083,0xaa1303f1
	.long 0x91004273,0x53041108,0x91005915,0x54ffc1c0
	.long 0x8b1c026a,0xf85f0148,0xf81f8d48,0xeb13015f
	.long 0x54ffffa1,0x17fffe08

	.globl lj_ff_xpcall
	.hidden lj_ff_xpcall
	.type lj_ff_xpcall, @function
	.size lj_ff_xpcall, 60
lj_ff_xpcall:
	.long 0xa9400660,0x394246c8,0xf1004389,0x54005ea3
	.long 0xaa1303f1,0x936ffc2f,0x53041108,0xb10025ff
	.long 0x91007915,0x54005de1,0xaa0903fc,0x91006273
	.long 0xa9000221,0xb4ffbf5c,0x17ffffec

	.globl lj_ff_coroutine_resume
	.hidden lj_ff_coroutine_resume
	.type lj_ff_coroutine_resume, @function
	.size lj_ff_coroutine_resume, 316
lj_ff_coroutine_resume:
	.long 0xf9400260,0xf100239f,0x54005ce3,0x936ffc0f
	.long 0xb1001dff,0x9240b800,0x54005c61,0xf85f8275
	.long 0xf90012f3,0xa9420411,0x39402c09,0x8b090028
	.long 0xf90057f5,0xeb11011f,0x54005b60,0xf100053f
	.long 0x91002028,0x9a882021,0xf9401803,0x8b1c0022
	.long 0xf9402811,0xfa439042,0xfa409a22,0x54005a48
	.long 0xd1002042,0x91002273,0xd100239c,0xf9001402
	.long 0xf90016f3,0xb40000dc,0xf8716a68,0xeb1c023f
	.long 0xf8316828,0x91002231,0x54ffff81,0x52800002
	.long 0xaa0003fb,0x52800003,0x97fffd7f,0xa9420f62
	.long 0xf100041f,0xf94012f3,0xf900bad7,0xb900bada
	.long 0x54000308,0xcb02007c,0xf9401ae0,0x8b1c0261
	.long 0xb400017c,0xeb00003f,0x52800011,0x540002e8
	.long 0xd1002383,0xf9001762,0xf8716848,0xeb03023f
	.long 0xf8316a68,0x91002231,0x54ffff81,0x92e00029
	.long 0x9100439c,0xf81f8269,0xd100227b,0xf24006a0
	.long 0xf90057f5,0xb900c3fc,0x54ff6cc0,0x17fffd07
	.long 0xf85f8c68,0x92d00009,0x5280031c,0xf9001763
	.long 0xf9000268,0x17fffff4,0xaa1703e0,0xd343ff81
	bl lj_state_growstack
	.long 0x52800000,0x17ffffd9

	.globl lj_ff_coroutine_wrap_aux
	.hidden lj_ff_coroutine_wrap_aux
	.type lj_ff_coroutine_wrap_aux, @function
	.size lj_ff_coroutine_wrap_aux, 264
lj_ff_coroutine_wrap_aux:
	.long 0xf9401840,0x9240b800,0xf85f8275,0xf90012f3
	.long 0xa9420411,0x39402c09,0x8b090028,0xf90057f5
	.long 0xeb11011f,0x54005220,0xf100053f,0x91002028
	.long 0x9a882021,0xf9401803,0x8b1c0022,0xf9402811
	.long 0xfa439042,0xfa409a22,0x54005108,0xf9001402
	.long 0xf90016f3,0xb40000dc,0xf8716a68,0xeb1c023f
	.long 0xf8316828,0x91002231,0x54ffff81,0x52800002
	.long 0xaa0003fb,0x52800003,0x97fffd38,0xa9420f62
	.long 0xf100041f,0xf94012f3,0xf900bad7,0xb900bada
	.long 0x540002c8,0xcb02007c,0xf9401ae0,0x8b1c0261
	.long 0xb400017c,0xeb00003f,0x52800011,0x54000248
	.long 0xd1002383,0xf9001762,0xf8716848,0xeb03023f
	.long 0xf8316a68,0x91002231,0x54ffff81,0xaa1303fb
	.long 0x9100239c,0xf24006a0,0xf90057f5,0xb900c3fc
	.long 0x54ff6420,0x17fffcc2,0xaa1703e0,0xaa1b03e1
	bl lj_ffh_coroutine_wrap_err
	.long 0xaa1703e0,0xd343ff81
	bl lj_state_growstack
	.long 0x52800000,0x17ffffde

	.globl lj_ff_coroutine_yield
	.hidden lj_ff_coroutine_yield
	.type lj_ff_coroutine_yield, @function
	.size lj_ff_coroutine_yield, 32
lj_ff_coroutine_yield:
	.long 0xf9402ae8,0x8b1c0269,0x52800020,0xa90226f3
	.long 0x36004a88,0xf9002aff,0x39002ee0,0x17fffcc7

	.globl lj_ff_math_floor
	.hidden lj_ff_math_floor
	.type lj_ff_math_floor, @function
	.size lj_ff_math_floor, 36
lj_ff_math_floor:
	.long 0xf9400260,0xf100239f,0xfd400260,0x540049a3
	.long 0xeb40833f,0x54000320,0x54004943,0x1e654000
	.long 0x14000034

	.globl lj_ff_math_ceil
	.hidden lj_ff_math_ceil
	.type lj_ff_math_ceil, @function
	.size lj_ff_math_ceil, 36
lj_ff_math_ceil:
	.long 0xf9400260,0xf100239f,0xfd400260,0x54004883
	.long 0xeb40833f,0x54000200,0x54004823,0x1e64c000
	.long 0x1400002b

	.globl lj_ff_math_abs
	.hidden lj_ff_math_abs
	.type lj_ff_math_abs, @function
	.size lj_ff_math_abs, 48
lj_ff_math_abs:
	.long 0xf9400260,0xf100239f,0x54004783,0xeb40833f
	.long 0x54004743,0x9240f800,0x540000c1,0x4a807c01
	.long 0xd2e83c02,0x6b807c20,0x8b180000,0x9a825000

	.globl lj_fff_restv
	.hidden lj_fff_restv
	.type lj_fff_restv, @function
	.size lj_fff_restv, 8
lj_fff_restv:
	.long 0xf85f8275,0xf81f0260

	.globl lj_fff_res1
	.hidden lj_fff_res1
	.type lj_fff_res1, @function
	.size lj_fff_res1, 4
lj_fff_res1:
	.long 0x5280021c

	.globl lj_fff_res
	.hidden lj_fff_res
	.type lj_fff_res, @function
	.size lj_fff_res, 80
lj_fff_res:
	.long 0xf24006a0,0xb900c3fc,0xd100427b,0x54ff91a1
	.long 0xb85fc2b0,0xd3587e11,0xeb110f9f,0x54000123
	.long 0xd3483e09,0xcb090f73,0xb84046b0,0x8b300ec9
	.long 0xd3483e1b,0xf947b128,0xd3507e1c,0xd61f0100
	.long 0x8b1c0369,0x9100239c,0xf81f813a,0x17fffff3

	.globl lj_ff_math_sqrt
	.hidden lj_ff_math_sqrt
	.type lj_ff_math_sqrt, @function
	.size lj_ff_math_sqrt, 28
lj_ff_math_sqrt:
	.long 0xf9400260,0xf100239f,0xfd400260,0x54004303
	.long 0xeb40833f,0x540042c9,0x1e61c000

	.globl lj_fff_resn
	.hidden lj_fff_resn
	.type lj_fff_resn, @function
	.size lj_fff_resn, 12
lj_fff_resn:
	.long 0xf85f8275,0xfc1f0260,0x17ffffe2

	.globl lj_ff_math_log
	.hidden lj_ff_math_log
	.type lj_ff_math_log, @function
	.size lj_ff_math_log, 32
lj_ff_math_log:
	.long 0xf9400260,0xf100239f,0xfd400260,0x540041c1
	.long 0xeb40833f,0x54004189
	bl log
	.long 0x17fffff6

	.globl lj_ff_math_log10
	.hidden lj_ff_math_log10
	.type lj_ff_math_log10, @function
	.size lj_ff_math_log10, 32
lj_ff_math_log10:
	.long 0xf9400260,0xf100239f,0xfd400260,0x540040c3
	.long 0xeb40833f,0x54004089
	bl log10
	.long 0x17ffffee

	.globl lj_ff_math_exp
	.hidden lj_ff_math_exp
	.type lj_ff_math_exp, @function
	.size lj_ff_math_exp, 32
lj_ff_math_exp:
	.long 0xf9400260,0xf100239f,0xfd400260,0x54003fc3
	.long 0xeb40833f,0x54003f89
	bl exp
	.long 0x17ffffe6

	.globl lj_ff_math_sin
	.hidden lj_ff_math_sin
	.type lj_ff_math_sin, @function
	.size lj_ff_math_sin, 32
lj_ff_math_sin:
	.long 0xf9400260,0xf100239f,0xfd400260,0x54003ec3
	.long 0xeb40833f,0x54003e89
	bl sin
	.long 0x17ffffde

	.globl lj_ff_math_cos
	.hidden lj_ff_math_cos
	.type lj_ff_math_cos, @function
	.size lj_ff_math_cos, 32
lj_ff_math_cos:
	.long 0xf9400260,0xf100239f,0xfd400260,0x54003dc3
	.long 0xeb40833f,0x54003d89
	bl cos
	.long 0x17ffffd6

	.globl lj_ff_math_tan
	.hidden lj_ff_math_tan
	.type lj_ff_math_tan, @function
	.size lj_ff_math_tan, 32
lj_ff_math_tan:
	.long 0xf9400260,0xf100239f,0xfd400260,0x54003cc3
	.long 0xeb40833f,0x54003c89
	bl tan
	.long 0x17ffffce

	.globl lj_ff_math_asin
	.hidden lj_ff_math_asin
	.type lj_ff_math_asin, @function
	.size lj_ff_math_asin, 32
lj_ff_math_asin:
	.long 0xf9400260,0xf100239f,0xfd400260,0x54003bc3
	.long 0xeb40833f,0x54003b89
	bl asin
	.long 0x17ffffc6

	.globl lj_ff_math_acos
	.hidden lj_ff_math_acos
	.type lj_ff_math_acos, @function
	.size lj_ff_math_acos, 32
lj_ff_math_acos:
	.long 0xf9400260,0xf100239f,0xfd400260,0x54003ac3
	.long 0xeb40833f,0x54003a89
	bl acos
	.long 0x17ffffbe

	.globl lj_ff_math_atan
	.hidden lj_ff_math_atan
	.type lj_ff_math_atan, @function
	.size lj_ff_math_atan, 32
lj_ff_math_atan:
	.long 0xf9400260,0xf100239f,0xfd400260,0x540039c3
	.long 0xeb40833f,0x54003989
	bl atan
	.long 0x17ffffb6

	.globl lj_ff_math_sinh
	.hidden lj_ff_math_sinh
	.type lj_ff_math_sinh, @function
	.size lj_ff_math_sinh, 32
lj_ff_math_sinh:
	.long 0xf9400260,0xf100239f,0xfd400260,0x540038c3
	.long 0xeb40833f,0x54003889
	bl sinh
	.long 0x17ffffae

	.globl lj_ff_math_cosh
	.hidden lj_ff_math_cosh
	.type lj_ff_math_cosh, @function
	.size lj_ff_math_cosh, 32
lj_ff_math_cosh:
	.long 0xf9400260,0xf100239f,0xfd400260,0x540037c3
	.long 0xeb40833f,0x54003789
	bl cosh
	.long 0x17ffffa6

	.globl lj_ff_math_tanh
	.hidden lj_ff_math_tanh
	.type lj_ff_math_tanh, @function
	.size lj_ff_math_tanh, 32
lj_ff_math_tanh:
	.long 0xf9400260,0xf100239f,0xfd400260,0x540036c3
	.long 0xeb40833f,0x54003689
	bl tanh
	.long 0x17ffff9e

	.globl lj_ff_math_pow
	.hidden lj_ff_math_pow
	.type lj_ff_math_pow, @function
	.size lj_ff_math_pow, 40
lj_ff_math_pow:
	.long 0xa9400660,0xf100439f,0x6d400660,0x540035c3
	.long 0xeb40833f,0x54003589,0xeb41833f,0x54003549
	bl pow
	.long 0x17ffff94

	.globl lj_ff_math_atan2
	.hidden lj_ff_math_atan2
	.type lj_ff_math_atan2, @function
	.size lj_ff_math_atan2, 40
lj_ff_math_atan2:
	.long 0xa9400660,0xf100439f,0x6d400660,0x54003483
	.long 0xeb40833f,0x54003449,0xeb41833f,0x54003409
	bl atan2
	.long 0x17ffff8a

	.globl lj_ff_math_fmod
	.hidden lj_ff_math_fmod
	.type lj_ff_math_fmod, @function
	.size lj_ff_math_fmod, 40
lj_ff_math_fmod:
	.long 0xa9400660,0xf100439f,0x6d400660,0x54003343
	.long 0xeb40833f,0x54003309,0xeb41833f,0x540032c9
	bl fmod
	.long 0x17ffff80

	.globl lj_ff_math_ldexp
	.hidden lj_ff_math_ldexp
	.type lj_ff_math_ldexp, @function
	.size lj_ff_math_ldexp, 44
lj_ff_math_ldexp:
	.long 0xa9400660,0xf100439f,0x54003223,0xfd400260
	.long 0xeb40833f,0x540031c9,0xeb41833f,0x54003181
	.long 0x93407c20
	bl ldexp
	.long 0x17ffff75

	.globl lj_ff_math_frexp
	.hidden lj_ff_math_frexp
	.type lj_ff_math_frexp, @function
	.size lj_ff_math_frexp, 60
lj_ff_math_frexp:
	.long 0xf9400260,0xf100239f,0xfd400260,0x540030a3
	.long 0xeb40833f,0x54003069,0x9102e3e0
	bl frexp
	.long 0xb940bbe1,0xf85f8275,0xfc1f0260,0x5280031c
	.long 0x8b180021,0xf81f8261,0x17ffff4b

	.globl lj_ff_math_modf
	.hidden lj_ff_math_modf
	.type lj_ff_math_modf, @function
	.size lj_ff_math_modf, 48
lj_ff_math_modf:
	.long 0xf9400260,0xf100239f,0xfd400260,0x54002ec3
	.long 0xeb40833f,0x54002e89,0xd1004260,0xf85f8275
	bl modf
	.long 0x5280031c,0xfc1f8260,0x17ffff3f

	.globl lj_ff_math_min
	.hidden lj_ff_math_min
	.type lj_ff_math_min, @function
	.size lj_ff_math_min, 140
lj_ff_math_min:
	.long 0xf9400260,0xf100239f,0x54002d63,0x8b1c0271
	.long 0x9100227b,0xeb40833f,0x540001c1,0xf9400361
	.long 0xeb11037f,0x54ffe642,0xeb41833f,0x540000a1
	.long 0x6b01001f,0x9100237b,0x9a80c020,0x17fffff8
	.long 0x1e620000,0x54002b83,0xfd400361,0x14000009
	.long 0xfd400260,0x54002b03,0xf9400361,0xfd400361
	.long 0xeb11037f,0x54ffe802,0xeb41833f,0x540000a9
	.long 0x1e612000,0x9100237b,0x1e605c20,0x17fffff7
	.long 0x1e620021,0x54002983,0x17fffffa

	.globl lj_ff_math_max
	.hidden lj_ff_math_max
	.type lj_ff_math_max, @function
	.size lj_ff_math_max, 140
lj_ff_math_max:
	.long 0xf9400260,0xf100239f,0x54002903,0x8b1c0271
	.long 0x9100227b,0xeb40833f,0x540001c1,0xf9400361
	.long 0xeb11037f,0x54ffe1e2,0xeb41833f,0x540000a1
	.long 0x6b01001f,0x9100237b,0x9a80b020,0x17fffff8
	.long 0x1e620000,0x54002723,0xfd400361,0x14000009
	.long 0xfd400260,0x540026a3,0xf9400361,0xfd400361
	.long 0xeb11037f,0x54ffe3a2,0xeb41833f,0x540000a9
	.long 0x1e612000,0x9100237b,0x1e60dc20,0x17fffff7
	.long 0x1e620021,0x54002523,0x17fffffa

	.globl lj_ff_string_byte
	.hidden lj_ff_string_byte
	.type lj_ff_string_byte, @function
	.size lj_ff_string_byte, 52
lj_ff_string_byte:
	.long 0xa97f8275,0xf100239f,0x936ffc0f,0xba4509e0
	.long 0x9240b800,0x54002441,0x39406008,0xb9401402
	.long 0x8b180108,0xf81f0268,0x5280011c,0xb4ffdda2
	.long 0x17fffeeb

	.globl lj_ff_string_char
	.hidden lj_ff_string_char
	.type lj_ff_string_char, @function
	.size lj_ff_string_char, 48
lj_ff_string_char:
	.long 0xa94106c0,0xeb01001f,0x5400004b,0x94000141
	.long 0xa97f8275,0x7103fc1f,0xfa489b80,0x54002261
	.long 0xeb40833f,0x54002221,0x52800022,0xaa1303e1

	.globl lj_fff_newstr
	.hidden lj_fff_newstr
	.type lj_fff_newstr, @function
	.size lj_fff_newstr, 16
lj_fff_newstr:
	.long 0xf90012f3,0xaa1703e0,0xf90057f5
	bl lj_str_new

	.globl lj_fff_resstr
	.hidden lj_fff_resstr
	.type lj_fff_resstr, @function
	.size lj_fff_resstr, 16
lj_fff_resstr:
	.long 0xf94012f3,0x92800089,0x8b09bc00,0x17fffed5

	.globl lj_ff_string_sub
	.hidden lj_ff_string_sub
	.type lj_ff_string_sub, @function
	.size lj_ff_string_sub, 172
lj_ff_string_sub:
	.long 0xa94106c0,0xeb01001f,0x5400004b,0x9400012d
	.long 0xf9400260,0xf9400a62,0xf100439f,0x92800011
	.long 0x540000a0,0x54001fa3,0xeb42833f,0x54001f61
	.long 0x93407c51,0xf9400661,0x936ffc0f,0xb10015ff
	.long 0x9240b800,0x54001ea1,0xb9401409,0xeb41833f
	.long 0x54001e41,0x93407c21,0x8b09022a,0xf100023f
	.long 0x8b090028,0x9a8aa631,0xf100003f,0x9a88a421
	.long 0xf100023f,0x9a9fa231,0xf100043f,0x9a9fa421
	.long 0xeb09023f,0x9a89d231,0x91005c00,0xeb010222
	.long 0x8b010001,0x91000442,0x54fffa4a,0x9101e2c0
	.long 0x92800089,0x8b09bc00,0x17fffeaa

	.globl lj_ff_string_reverse
	.hidden lj_ff_string_reverse
	.type lj_ff_string_reverse, @function
	.size lj_ff_string_reverse, 76
lj_ff_string_reverse:
	.long 0xa94106c0,0xeb01001f,0x5400004b,0x94000102
	.long 0xf9400261,0xf100239f,0x936ffc2f,0xba4529e0
	.long 0x9240b821,0x54001a41,0xf9406ec8,0x910322c0
	.long 0xf90012f3,0xf90057f5,0xf90072d7,0xf90066c8
	bl lj_buf_putstr_reverse
	bl lj_buf_tostr
	.long 0x17ffffbf

	.globl lj_ff_string_lower
	.hidden lj_ff_string_lower
	.type lj_ff_string_lower, @function
	.size lj_ff_string_lower, 76
lj_ff_string_lower:
	.long 0xa94106c0,0xeb01001f,0x5400004b,0x940000ef
	.long 0xf9400261,0xf100239f,0x936ffc2f,0xba4529e0
	.long 0x9240b821,0x540017e1,0xf9406ec8,0x910322c0
	.long 0xf90012f3,0xf90057f5,0xf90072d7,0xf90066c8
	bl lj_buf_putstr_lower
	bl lj_buf_tostr
	.long 0x17ffffac

	.globl lj_ff_string_upper
	.hidden lj_ff_string_upper
	.type lj_ff_string_upper, @function
	.size lj_ff_string_upper, 76
lj_ff_string_upper:
	.long 0xa94106c0,0xeb01001f,0x5400004b,0x940000dc
	.long 0xf9400261,0xf100239f,0x936ffc2f,0xba4529e0
	.long 0x9240b821,0x54001581,0xf9406ec8,0x910322c0
	.long 0xf90012f3,0xf90057f5,0xf90072d7,0xf90066c8
	bl lj_buf_putstr_upper
	bl lj_buf_tostr
	.long 0x17ffff99

	.globl lj_vm_tobit_fb
	.hidden lj_vm_tobit_fb
	.type lj_vm_tobit_fb, @function
	.size lj_vm_tobit_fb, 56
lj_vm_tobit_fb:
	.long 0x54001449,0x8b000001,0x52808682,0xcb41d442
	.long 0xf100d45f,0x540000e8,0x9240d021,0xb24b0021
	.long 0xf100001f,0x9ac22421,0x5a815420,0xd61f03c0
	.long 0x52800000,0xd61f03c0

	.globl lj_ff_bit_band
	.hidden lj_ff_bit_band
	.type lj_ff_bit_band, @function
	.size lj_ff_bit_band, 68
lj_ff_bit_band:
	.long 0xf9400260,0xf100239f,0x54001243,0x1000007e
	.long 0xeb40833f,0x54fffda1,0x5280011b,0x2a0003e8
	.long 0x100000fe,0xf87b6a60,0xeb1c037f,0x9100237b
	.long 0x540005ca,0xeb40833f,0x54fffc81,0x0a000108
	.long 0x17fffff9

	.globl lj_ff_bit_bor
	.hidden lj_ff_bit_bor
	.type lj_ff_bit_bor, @function
	.size lj_ff_bit_bor, 68
lj_ff_bit_bor:
	.long 0xf9400260,0xf100239f,0x54001023,0x1000007e
	.long 0xeb40833f,0x54fffb81,0x5280011b,0x2a0003e8
	.long 0x100000fe,0xf87b6a60,0xeb1c037f,0x9100237b
	.long 0x540003aa,0xeb40833f,0x54fffa61,0x2a000108
	.long 0x17fffff9

	.globl lj_ff_bit_bxor
	.hidden lj_ff_bit_bxor
	.type lj_ff_bit_bxor, @function
	.size lj_ff_bit_bxor, 68
lj_ff_bit_bxor:
	.long 0xf9400260,0xf100239f,0x54000e03,0x1000007e
	.long 0xeb40833f,0x54fff961,0x5280011b,0x2a0003e8
	.long 0x100000fe,0xf87b6a60,0xeb1c037f,0x9100237b
	.long 0x5400018a,0xeb40833f,0x54fff841,0x4a000108
	.long 0x17fffff9

	.globl lj_ff_bit_tobit
	.hidden lj_ff_bit_tobit
	.type lj_ff_bit_tobit, @function
	.size lj_ff_bit_tobit, 36
lj_ff_bit_tobit:
	.long 0xf9400260,0xf100239f,0x54000be3,0x1000007e
	.long 0xeb40833f,0x54fff741,0x2a0003e8,0x8b180100
	.long 0x17fffe27

	.globl lj_ff_bit_bswap
	.hidden lj_ff_bit_bswap
	.type lj_ff_bit_bswap, @function
	.size lj_ff_bit_bswap, 36
lj_ff_bit_bswap:
	.long 0xf9400260,0xf100239f,0x54000ac3,0x1000007e
	.long 0xeb40833f,0x54fff621,0x5ac00808,0x8b180100
	.long 0x17fffe1e

	.globl lj_ff_bit_bnot
	.hidden lj_ff_bit_bnot
	.type lj_ff_bit_bnot, @function
	.size lj_ff_bit_bnot, 36
lj_ff_bit_bnot:
	.long 0xf9400260,0xf100239f,0x540009a3,0x1000007e
	.long 0xeb40833f,0x54fff501,0x2a2003e8,0x8b180100
	.long 0x17fffe15

	.globl lj_ff_bit_lshift
	.hidden lj_ff_bit_lshift
	.type lj_ff_bit_lshift, @function
	.size lj_ff_bit_lshift, 56
lj_ff_bit_lshift:
	.long 0xa9400268,0xf100439f,0x54000883,0x1000007e
	.long 0xeb40833f,0x54fff3e1,0xaa0003e9,0xaa0803e0
	.long 0x1000007e,0xeb40833f,0x54fff341,0x1ac92008
	.long 0x8b180100,0x17fffe07

	.globl lj_ff_bit_rshift
	.hidden lj_ff_bit_rshift
	.type lj_ff_bit_rshift, @function
	.size lj_ff_bit_rshift, 56
lj_ff_bit_rshift:
	.long 0xa9400268,0xf100439f,0x540006c3,0x1000007e
	.long 0xeb40833f,0x54fff221,0xaa0003e9,0xaa0803e0
	.long 0x1000007e,0xeb40833f,0x54fff181,0x1ac92408
	.long 0x8b180100,0x17fffdf9

	.globl lj_ff_bit_arshift
	.hidden lj_ff_bit_arshift
	.type lj_ff_bit_arshift, @function
	.size lj_ff_bit_arshift, 56
lj_ff_bit_arshift:
	.long 0xa9400268,0xf100439f,0x54000503,0x1000007e
	.long 0xeb40833f,0x54fff061,0xaa0003e9,0xaa0803e0
	.long 0x1000007e,0xeb40833f,0x54ffefc1,0x1ac92808
	.long 0x8b180100,0x17fffdeb

	.globl lj_ff_bit_rol
	.hidden lj_ff_bit_rol
	.type lj_ff_bit_rol, @function
	.size lj_ff_bit_rol, 56
lj_ff_bit_rol:
	.long 0xa9400268,0xf100439f,0x54000343,0x1000007e
	.long 0xeb40833f,0x54ffeea1,0xcb0003e9,0xaa0803e0
	.long 0x1000007e,0xeb40833f,0x54ffee01,0x1ac92c08
	.long 0x8b180100,0x17fffddd

	.globl lj_ff_bit_ror
	.hidden lj_ff_bit_ror
	.type lj_ff_bit_ror, @function
	.size lj_ff_bit_ror, 56
lj_ff_bit_ror:
	.long 0xa9400268,0xf100439f,0x54000183,0x1000007e
	.long 0xeb40833f,0x54ffece1,0xaa0003e9,0xaa0803e0
	.long 0x1000007e,0xeb40833f,0x54ffec41,0x1ac92c08
	.long 0x8b180100,0x17fffdcf

	.globl lj_fff_fallback
	.hidden lj_fff_fallback
	.type lj_fff_fallback, @function
	.size lj_fff_fallback, 116
lj_fff_fallback:
	.long 0xa97f5662,0xf9401aea,0x8b1c0269,0xa90226f3
	.long 0x9240b842,0x91028129,0xf9401442,0xf90057f5
	.long 0xeb0a013f,0xaa1703e0,0x54000368,0xd63f0040
	.long 0xf94012f3,0x7100001f,0xd37df01c,0xd100427b
	.long 0x54ffb82c,0xf94016e0,0xf85f0262,0xcb13001c
	.long 0x54000121,0x9240b842,0xf9401055,0xb84046b0
	.long 0x8b300ec9,0xd3483e1b,0xf947b128,0x8b1b0e7b
	.long 0xd61f0100

	.globl lj_vm_call_tail
	.hidden lj_vm_call_tail
	.type lj_vm_call_tail, @function
	.size lj_vm_call_tail, 52
lj_vm_call_tail:
	.long 0xf24006a8,0x927df2a9,0x54000081,0x385fd2bb
	.long 0xd37df37b,0x91004369,0xcb090271,0x17fffaeb
	.long 0x52800281
	bl lj_state_growstack
	.long 0xf94012f3,0xeb00001f,0x17ffffe8

	.globl lj_fff_gcstep
	.hidden lj_fff_gcstep
	.type lj_fff_gcstep, @function
	.size lj_fff_gcstep, 48
lj_fff_gcstep:
	.long 0x8b1c0261,0xaa1e03fb,0xa90206f3,0xf90057f5
	.long 0xaa1703e0
	bl lj_gc_step
	.long 0xa94206f3,0xf85f0262,0xaa1b03fe,0xcb13003c
	.long 0x9240b842,0xd65f03c0

	.globl lj_vm_record
	.hidden lj_vm_record
	.type lj_vm_record, @function
	.size lj_vm_record, 44
lj_vm_record:
	.long 0x394246c0,0xf27b001f,0x54000161,0xb9414ac1
	.long 0xf27c001f,0x54000261,0x51000421,0xf27e041f
	.long 0x54000200,0xb9014ac1,0x1400000e

	.globl lj_vm_rethook
	.hidden lj_vm_rethook
	.type lj_vm_rethook, @function
	.size lj_vm_rethook, 16
lj_vm_rethook:
	.long 0x394246ca,0x3620018a,0xf94a1928,0xd61f0100

	.globl lj_vm_inshook
	.hidden lj_vm_inshook
	.type lj_vm_inshook, @function
	.size lj_vm_inshook, 80
lj_vm_inshook:
	.long 0x394246ca,0xb9414acb,0x3727ff8a,0x721e055f
	.long 0x54ffff40,0x5100056b,0xb9014acb,0x3400004b
	.long 0x3617feca,0xaa1703e0,0xf90012f3,0xaa1503e1
	bl lj_dispatch_ins
	.long 0xf94012f3,0xb85fc2b0,0x8b300ec9,0xd3483e1b
	.long 0xf94a1928,0xd3507e1c,0xd61f0100

	.globl lj_cont_hook
	.hidden lj_cont_hook
	.type lj_cont_hook, @function
	.size lj_cont_hook, 16
lj_cont_hook:
	.long 0xf85d8060,0x910012b5,0xb900c3e0,0x17fffff7

	.globl lj_vm_hotloop
	.hidden lj_vm_hotloop
	.type lj_vm_hotloop, @function
	.size lj_vm_hotloop, 52
lj_vm_hotloop:
	.long 0xf85f0262,0x910b62c0,0x9240b842,0xf90057f5
	.long 0xf9401042,0xaa1503e1,0xf901aed7,0x385a3042
	.long 0xf90012f3,0x8b020e62,0xf90016e2
	bl lj_trace_hot
	.long 0x17ffffe9

	.globl lj_vm_callhook
	.hidden lj_vm_callhook
	.type lj_vm_callhook, @function
	.size lj_vm_callhook, 8
lj_vm_callhook:
	.long 0xaa1503e1,0x14000002

	.globl lj_vm_hotcall
	.hidden lj_vm_hotcall
	.type lj_vm_hotcall, @function
	.size lj_vm_hotcall, 60
lj_vm_hotcall:
	.long 0xb24002a1,0x8b1c0269,0xf90057f5,0xaa1703e0
	.long 0xcb13037b,0xa90226f3
	bl lj_dispatch_call
	.long 0xa94226f3,0xf90057ff,0xf85f0262,0x8b1b027b
	.long 0xcb13013c,0xb85fc2b0,0x9240b842,0xd61f0000

	.globl lj_cont_stitch
	.hidden lj_cont_stitch
	.type lj_cont_stitch, @function
	.size lj_cont_stitch, 148
lj_cont_stitch:
	.long 0xb940c3f1,0xb85fc2b0,0xf85d8062,0xf1002231
	.long 0xd3483e1c,0x9240b842,0x540000e0,0xf9400360
	.long 0x9100237b,0xf1002231,0xf83c7a60,0x9100079c
	.long 0x54ffff61,0xd3483e1b,0xd3587e11,0x8b11037b
	.long 0xeb1c037f,0x54000228,0x7940d05b,0x7940d45c
	.long 0x6b1b039f,0x54ff6600,0x7100039f,0x54ff2921
	.long 0x5281d180,0xb8206adb,0x52806b00,0xf8206ad7
	.long 0xf90012f3,0x910b62c0,0xaa1503e1
	bl lj_dispatch_stitch
	.long 0xf94012f3,0x17fffb24,0xf83c7a7a,0x9100079c
	.long 0x17ffffec

	.globl lj_vm_profhook
	.hidden lj_vm_profhook
	.type lj_vm_profhook, @function
	.size lj_vm_profhook, 28
lj_vm_profhook:
	.long 0xaa1703e0,0xf90012f3,0xaa1503e1
	bl lj_dispatch_profile
	.long 0xf94012f3,0xd10012b5,0x17fffb1a

	.globl lj_vm_exit_handler
	.hidden lj_vm_exit_handler
	.type lj_vm_exit_handler, @function
	.size lj_vm_exit_handler, 232
lj_vm_exit_handler:
	.long 0xd10803ff,0x6d0007e0,0xa91007e0,0x6d010fe2
	.long 0xa9110fe2,0x6d0217e4,0xa91217e4,0x6d031fe6
	.long 0xa9131fe6,0x6d0427e8,0xa91427e8,0x6d052fea
	.long 0xa9152fea,0x6d0637ec,0xa91637ec,0x6d073fee
	.long 0xa9173fee,0x6d0847f0,0xa91847f0,0x6d094ff2
	.long 0xa9194ff2,0x6d0a57f4,0xa91a57f4,0x6d0b5ff6
	.long 0xa91b5ff6,0x6d0c67f8,0xa91c67f8,0x6d0d6ffa
	.long 0xa91d6ffa,0x6d0e77fc,0xa91e77fc,0x6d0f7ffe
	.long 0xf94103e0,0x910803e2,0x12800063,0xa91f0bff
	.long 0xcb1e0000,0xf940bad7,0xd342fc00,0xf940bed3
	.long 0xd1000800,0xb94003c1,0xb900bac3,0xf90012f3
	.long 0x53055021,0xb90e8ec0,0xb90e8ac1,0xf901aed7
	.long 0xf900bedf,0x910b62c0,0x910003e1
	bl lj_trace_exit
	.long 0xf9402ae1,0xf94012f3,0x927ef43f,0xf94057f5
	.long 0xf9005bf7,0x14000002

	.globl lj_vm_exit_interp
	.hidden lj_vm_exit_interp
	.type lj_vm_exit_interp, @function
	.size lj_vm_exit_interp, 184
lj_vm_exit_interp:
	.long 0xf9405bf7,0x7100001f,0x5400054b,0xd37df01c
	.long 0xf85f0261,0xd2ffff38,0xd2bfff39,0x9280001a
	.long 0x9240b821,0xb900c3fc,0xf90012f3,0xf9401021
	.long 0xf900bedf,0x12800003,0xf85b8034,0x394002b1
	.long 0xb84046b0,0xb900bac3,0x7101863f,0x8b300ec9
	.long 0x540001a2,0x7101663f,0x8b310ec8,0xf947b111
	.long 0xd3483e1b,0xd350fe08,0x9a9c311c,0x540000a3
	.long 0xf85f0262,0xd100239c,0x8b1b0e7b,0x9240b842
	.long 0xd61f0220,0xf85f8260,0xf2400401,0x54fffe41
	.long 0xb85fc002,0xd3483c40,0xcb000e61,0xf85e0022
	.long 0x9240b842,0xf9401042,0xf85b8054,0x17ffffea
	.long 0xaa1703e0
	bl lj_err_run

	.globl lj_vm_modi
	.hidden lj_vm_modi
	.type lj_vm_modi, @function
	.size lj_vm_modi, 60
lj_vm_modi:
	.long 0x4a010003,0x7100007f,0x4a807c02,0x4a817c23
	.long 0x4b807c42,0x4b817c63,0x1ac30840,0x1b038800
	.long 0x7a404804,0x4b030002,0x1a820000,0x4a010002
	.long 0x7100005f,0x5a805400,0xd65f03c0

	.globl lj_vm_ffi_callback
	.hidden lj_vm_ffi_callback
	.type lj_vm_ffi_callback, @function
	.size lj_vm_ffi_callback, 176
lj_vm_ffi_callback:
	.long 0xa9b37bfd,0x910003fd,0xa90153f3,0x6d0627e8
	.long 0xa9025bf5,0x6d072fea,0xa90363f7,0x6d0837ec
	.long 0xa9046bf9,0x6d093fee,0xa90573fb,0xf940c155
	.long 0xaa0a03f6,0x910343ea,0xb900d2a9,0xa90706a0
	.long 0x6d0306a0,0xa9080ea2,0x6d040ea2,0xa90916a4
	.long 0x6d0516a4,0xa90a1ea6,0x6d061ea6,0xf9005aaa
	.long 0xaa1503e0,0xf90057f5,0x910003e1
	bl lj_ccallback_enter
	.long 0xa9427013,0xd2ffff38,0xd2bfff39,0x9280001a
	.long 0xaa0003f7,0xf85f0262,0xcb13039c,0xb900bada
	.long 0x9240b842,0xf9401055,0xb84046b0,0x8b300ec9
	.long 0xd3483e1b,0xf947b128,0x8b1b0e7b,0xd61f0100

	.globl lj_cont_ffi_callback
	.hidden lj_cont_ffi_callback
	.type lj_cont_ffi_callback, @function
	.size lj_cont_ffi_callback, 36
lj_cont_ffi_callback:
	.long 0xf940c2d5,0xa9020ef3,0xf9000ab7,0xaa1503e0
	.long 0xaa1b03e1
	bl lj_ccallback_leave
	.long 0xa94706a0,0x6d4306a0,0x17fff924

	.globl lj_vm_ffi_call
	.hidden lj_vm_ffi_call
	.type lj_vm_ffi_call, @function
	.size lj_vm_ffi_call, 128
lj_vm_ffi_call:
	.long 0xa9be7bfd,0x910003fd,0xf9000bf3,0xaa0003f3
	.long 0xb9400808,0x39403269,0x9102626a,0xf1000529
	.long 0xf940026b,0xcb2863bf,0x540000a4,0xf8697948
	.long 0xf8297be8,0xf1000529,0x54ffffa5,0xa9458660
	.long 0x6d418660,0xa9468e62,0x6d428e62,0xa9479664
	.long 0x6d439664,0xa9489e66,0x6d449e66,0xf9400a68
	.long 0xd63f0160,0x910003bf,0xa9058660,0x6d018660
	.long 0x6d028e62,0xf9400bf3,0xa8c27bfd,0xd65f03c0

	.section .note.GNU-stack,"",@progbits
	.ident "DynASM 1.4.0"

	.section .debug_frame,"",%progbits
.Lframe0:
	.long .LECIE0-.LSCIE0
.LSCIE0:
	.long 0xffffffff
	.byte 0x1
	.string ""
	.uleb128 0x1
	.sleb128 -8
	.byte 30
	.byte 0xc
	.uleb128 31
	.uleb128 0
	.align 3
.LECIE0:

.LSFDE0:
	.long .LEFDE0-.LASFDE0
.LASFDE0:
	.long .Lframe0
	.quad .Lbegin
	.quad 15520
	.byte 0xe
	.uleb128 208
	.byte 0x9d
	.uleb128 26
	.byte 0x9e
	.uleb128 25
	.byte 0x93
	.uleb128 24
	.byte 0x94
	.uleb128 23
	.byte 0x95
	.uleb128 22
	.byte 0x96
	.uleb128 21
	.byte 0x97
	.uleb128 20
	.byte 0x98
	.uleb128 19
	.byte 0x99
	.uleb128 18
	.byte 0x9a
	.uleb128 17
	.byte 0x9b
	.uleb128 16
	.byte 0x9c
	.uleb128 15
	.byte 5
	.uleb128 0x48
	.uleb128 14
	.byte 5
	.uleb128 0x49
	.uleb128 13
	.byte 5
	.uleb128 0x4a
	.uleb128 12
	.byte 5
	.uleb128 0x4b
	.uleb128 11
	.byte 5
	.uleb128 0x4c
	.uleb128 10
	.byte 5
	.uleb128 0x4d
	.uleb128 9
	.byte 5
	.uleb128 0x4e
	.uleb128 8
	.byte 5
	.uleb128 0x4f
	.uleb128 7
	.align 3
.LEFDE0:

.LSFDE1:
	.long .LEFDE1-.LASFDE1
.LASFDE1:
	.long .Lframe0
	.quad lj_vm_ffi_call
	.quad 128
	.byte 0xe
	.uleb128 32
	.byte 0x9d
	.uleb128 4
	.byte 0x9e
	.uleb128 3
	.byte 0x93
	.uleb128 2
	.align 3
.LEFDE1:

	.section .eh_frame,"a",%progbits
.Lframe1:
	.long .LECIE1-.LSCIE1
.LSCIE1:
	.long 0
	.byte 0x1
	.string "zPR"
	.uleb128 0x1
	.sleb128 -8
	.byte 30
	.uleb128 6
	.byte 0x1b
	.long lj_err_unwind_dwarf-.
	.byte 0x1b
	.byte 0xc
	.uleb128 31
	.uleb128 0
	.align 3
.LECIE1:

.LSFDE2:
	.long .LEFDE2-.LASFDE2
.LASFDE2:
	.long .LASFDE2-.Lframe1
	.long .Lbegin-.
	.long 15520
	.uleb128 0
	.byte 0xe
	.uleb128 208
	.byte 0x9d
	.uleb128 26
	.byte 0x9e
	.uleb128 25
	.byte 0x93
	.uleb128 24
	.byte 0x94
	.uleb128 23
	.byte 0x95
	.uleb128 22
	.byte 0x96
	.uleb128 21
	.byte 0x97
	.uleb128 20
	.byte 0x98
	.uleb128 19
	.byte 0x99
	.uleb128 18
	.byte 0x9a
	.uleb128 17
	.byte 0x9b
	.uleb128 16
	.byte 0x9c
	.uleb128 15
	.byte 5
	.uleb128 0x48
	.uleb128 14
	.byte 5
	.uleb128 0x49
	.uleb128 13
	.byte 5
	.uleb128 0x4a
	.uleb128 12
	.byte 5
	.uleb128 0x4b
	.uleb128 11
	.byte 5
	.uleb128 0x4c
	.uleb128 10
	.byte 5
	.uleb128 0x4d
	.uleb128 9
	.byte 5
	.uleb128 0x4e
	.uleb128 8
	.byte 5
	.uleb128 0x4f
	.uleb128 7
	.align 3
.LEFDE2:

.Lframe2:
	.long .LECIE2-.LSCIE2
.LSCIE2:
	.long 0
	.byte 0x1
	.string "zR"
	.uleb128 0x1
	.sleb128 -8
	.byte 30
	.uleb128 1
	.byte 0x1b
	.byte 0xc
	.uleb128 31
	.uleb128 0
	.align 3
.LECIE2:

.LSFDE3:
	.long .LEFDE3-.LASFDE3
.LASFDE3:
	.long .LASFDE3-.Lframe2
	.long lj_vm_ffi_call-.
	.long 128
	.uleb128 0
	.byte 0xe
	.uleb128 32
	.byte 0x9d
	.uleb128 4
	.byte 0x9e
	.uleb128 3
	.byte 0x93
	.uleb128 2
	.align 3
.LEFDE3:


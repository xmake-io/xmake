	.file "buildvm_x86.dasc"
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
	.size lj_BC_ISLT, 65
lj_BC_ISLT:
	.byte 131,124,202,4,242,15,131,66,27,0,0,131,124,194,4,242
	.byte 15,131,55,27,0,0,221,4,202,221,4,194,131,198,4,223
	.byte 233,221,216,118,11,15,183,70,254,141,180,134,0,0,254,255
	.byte 139,6,15,182,204,15,182,232,131,198,4,193,232,16,255,36
	.byte 171

	.globl lj_BC_ISGE
	.hidden lj_BC_ISGE
	.type lj_BC_ISGE, @function
	.size lj_BC_ISGE, 65
lj_BC_ISGE:
	.byte 131,124,202,4,242,15,131,1,27,0,0,131,124,194,4,242
	.byte 15,131,246,26,0,0,221,4,202,221,4,194,131,198,4,223
	.byte 233,221,216,119,11,15,183,70,254,141,180,134,0,0,254,255
	.byte 139,6,15,182,204,15,182,232,131,198,4,193,232,16,255,36
	.byte 171

	.globl lj_BC_ISLE
	.hidden lj_BC_ISLE
	.type lj_BC_ISLE, @function
	.size lj_BC_ISLE, 65
lj_BC_ISLE:
	.byte 131,124,202,4,242,15,131,192,26,0,0,131,124,194,4,242
	.byte 15,131,181,26,0,0,221,4,202,221,4,194,131,198,4,223
	.byte 233,221,216,114,11,15,183,70,254,141,180,134,0,0,254,255
	.byte 139,6,15,182,204,15,182,232,131,198,4,193,232,16,255,36
	.byte 171

	.globl lj_BC_ISGT
	.hidden lj_BC_ISGT
	.type lj_BC_ISGT, @function
	.size lj_BC_ISGT, 65
lj_BC_ISGT:
	.byte 131,124,202,4,242,15,131,127,26,0,0,131,124,194,4,242
	.byte 15,131,116,26,0,0,221,4,202,221,4,194,131,198,4,223
	.byte 233,221,216,115,11,15,183,70,254,141,180,134,0,0,254,255
	.byte 139,6,15,182,204,15,182,232,131,198,4,193,232,16,255,36
	.byte 171

	.globl lj_BC_ISEQV
	.hidden lj_BC_ISEQV
	.type lj_BC_ISEQV, @function
	.size lj_BC_ISEQV, 127
lj_BC_ISEQV:
	.byte 139,108,194,4,131,198,4,131,253,242,115,49,131,124,202,4
	.byte 242,115,42,221,4,202,221,4,194,223,233,221,216,122,13,117
	.byte 11,15,183,70,254,141,180,134,0,0,254,255,139,6,15,182
	.byte 204,15,182,232,131,198,4,193,232,16,255,36,171,131,253,245
	.byte 15,132,142,26,0,0,131,124,202,4,245,15,132,131,26,0
	.byte 0,57,108,202,4,117,213,131,253,253,115,197,139,12,202,139
	.byte 4,194,57,193,116,187,131,253,244,119,193,139,105,16,133,237
	.byte 116,186,246,69,6,16,117,180,49,237,233,49,26,0,0

	.globl lj_BC_ISNEV
	.hidden lj_BC_ISNEV
	.type lj_BC_ISNEV, @function
	.size lj_BC_ISNEV, 130
lj_BC_ISNEV:
	.byte 139,108,194,4,131,198,4,131,253,242,115,49,131,124,202,4
	.byte 242,115,42,221,4,202,221,4,194,223,233,221,216,122,2,116
	.byte 11,15,183,70,254,141,180,134,0,0,254,255,139,6,15,182
	.byte 204,15,182,232,131,198,4,193,232,16,255,36,171,131,253,245
	.byte 15,132,15,26,0,0,131,124,202,4,245,15,132,4,26,0
	.byte 0,57,108,202,4,117,202,131,253,253,115,208,139,12,202,139
	.byte 4,194,57,193,116,198,131,253,244,119,182,139,105,16,133,237
	.byte 116,175,246,69,6,16,117,169,189,1,0,0,0,233,175,25
	.byte 0,0

	.globl lj_BC_ISEQS
	.hidden lj_BC_ISEQS
	.type lj_BC_ISEQS, @function
	.size lj_BC_ISEQS, 60
lj_BC_ISEQS:
	.byte 247,208,139,108,202,4,131,198,4,131,253,251,117,36,139,12
	.byte 202,59,12,135,117,11,15,183,70,254,141,180,134,0,0,254
	.byte 255,139,6,15,182,204,15,182,232,131,198,4,193,232,16,255
	.byte 36,171,131,253,245,117,234,233,151,25,0,0

	.globl lj_BC_ISNES
	.hidden lj_BC_ISNES
	.type lj_BC_ISNES, @function
	.size lj_BC_ISNES, 60
lj_BC_ISNES:
	.byte 247,208,139,108,202,4,131,198,4,131,253,251,117,36,139,12
	.byte 202,59,12,135,116,11,15,183,70,254,141,180,134,0,0,254
	.byte 255,139,6,15,182,204,15,182,232,131,198,4,193,232,16,255
	.byte 36,171,131,253,245,117,223,233,91,25,0,0

	.globl lj_BC_ISEQN
	.hidden lj_BC_ISEQN
	.type lj_BC_ISEQN, @function
	.size lj_BC_ISEQN, 64
lj_BC_ISEQN:
	.byte 139,108,202,4,131,198,4,131,253,242,115,42,221,4,199,221
	.byte 4,202,223,233,221,216,122,13,117,11,15,183,70,254,141,180
	.byte 134,0,0,254,255,139,6,15,182,204,15,182,232,131,198,4
	.byte 193,232,16,255,36,171,131,253,245,117,234,233,27,25,0,0

	.globl lj_BC_ISNEN
	.hidden lj_BC_ISNEN
	.type lj_BC_ISNEN, @function
	.size lj_BC_ISNEN, 64
lj_BC_ISNEN:
	.byte 139,108,202,4,131,198,4,131,253,242,115,42,221,4,199,221
	.byte 4,202,223,233,221,216,122,2,116,11,15,183,70,254,141,180
	.byte 134,0,0,254,255,139,6,15,182,204,15,182,232,131,198,4
	.byte 193,232,16,255,36,171,131,253,245,117,223,233,219,24,0,0

	.globl lj_BC_ISEQP
	.hidden lj_BC_ISEQP
	.type lj_BC_ISEQP, @function
	.size lj_BC_ISEQP, 51
lj_BC_ISEQP:
	.byte 247,208,139,108,202,4,131,198,4,57,197,117,28,15,183,70
	.byte 254,141,180,134,0,0,254,255,139,6,15,182,204,15,182,232
	.byte 131,198,4,193,232,16,255,36,171,131,253,245,117,234,233,168
	.byte 24,0,0

	.globl lj_BC_ISNEP
	.hidden lj_BC_ISNEP
	.type lj_BC_ISNEP, @function
	.size lj_BC_ISNEP, 50
lj_BC_ISNEP:
	.byte 247,208,139,108,202,4,131,198,4,57,197,116,20,131,253,245
	.byte 15,132,146,24,0,0,15,183,70,254,141,180,134,0,0,254
	.byte 255,139,6,15,182,204,15,182,232,131,198,4,193,232,16,255
	.byte 36,171

	.globl lj_BC_ISTC
	.hidden lj_BC_ISTC
	.type lj_BC_ISTC, @function
	.size lj_BC_ISTC, 50
lj_BC_ISTC:
	.byte 139,108,194,4,131,198,4,131,253,254,115,21,137,108,202,4
	.byte 139,44,194,137,44,202,15,183,70,254,141,180,134,0,0,254
	.byte 255,139,6,15,182,204,15,182,232,131,198,4,193,232,16,255
	.byte 36,171

	.globl lj_BC_ISFC
	.hidden lj_BC_ISFC
	.type lj_BC_ISFC, @function
	.size lj_BC_ISFC, 50
lj_BC_ISFC:
	.byte 139,108,194,4,131,198,4,131,253,254,114,21,137,108,202,4
	.byte 139,44,194,137,44,202,15,183,70,254,141,180,134,0,0,254
	.byte 255,139,6,15,182,204,15,182,232,131,198,4,193,232,16,255
	.byte 36,171

	.globl lj_BC_IST
	.hidden lj_BC_IST
	.type lj_BC_IST, @function
	.size lj_BC_IST, 40
lj_BC_IST:
	.byte 139,108,194,4,131,198,4,131,253,254,115,11,15,183,70,254
	.byte 141,180,134,0,0,254,255,139,6,15,182,204,15,182,232,131
	.byte 198,4,193,232,16,255,36,171

	.globl lj_BC_ISF
	.hidden lj_BC_ISF
	.type lj_BC_ISF, @function
	.size lj_BC_ISF, 40
lj_BC_ISF:
	.byte 139,108,194,4,131,198,4,131,253,254,114,11,15,183,70,254
	.byte 141,180,134,0,0,254,255,139,6,15,182,204,15,182,232,131
	.byte 198,4,193,232,16,255,36,171

	.globl lj_BC_MOV
	.hidden lj_BC_MOV
	.type lj_BC_MOV, @function
	.size lj_BC_MOV, 31
lj_BC_MOV:
	.byte 139,108,194,4,139,4,194,137,108,202,4,137,4,202,139,6
	.byte 15,182,204,15,182,232,131,198,4,193,232,16,255,36,171

	.globl lj_BC_NOT
	.hidden lj_BC_NOT
	.type lj_BC_NOT, @function
	.size lj_BC_NOT, 31
lj_BC_NOT:
	.byte 49,237,131,124,194,4,254,131,213,253,137,108,202,4,139,6
	.byte 15,182,204,15,182,232,131,198,4,193,232,16,255,36,171

	.globl lj_BC_UNM
	.hidden lj_BC_UNM
	.type lj_BC_UNM, @function
	.size lj_BC_UNM, 36
lj_BC_UNM:
	.byte 131,124,194,4,242,15,131,161,23,0,0,221,4,194,217,224
	.byte 221,28,202,139,6,15,182,204,15,182,232,131,198,4,193,232
	.byte 16,255,36,171

	.globl lj_BC_LEN
	.hidden lj_BC_LEN
	.type lj_BC_LEN, @function
	.size lj_BC_LEN, 68
lj_BC_LEN:
	.byte 131,124,194,4,251,117,26,139,4,194,219,64,12,221,28,202
	.byte 139,6,15,182,204,15,182,232,131,198,4,193,232,16,255,36
	.byte 171,131,124,194,4,244,15,133,178,23,0,0,139,12,194,137
	.byte 213,232
	.long lj_tab_len-.-4
	.byte 137,4,36,219,4,36,137,234,15,182,78,253,235,201

	.globl lj_BC_ADDVN
	.hidden lj_BC_ADDVN
	.type lj_BC_ADDVN, @function
	.size lj_BC_ADDVN, 43
lj_BC_ADDVN:
	.byte 15,182,236,15,182,192,131,124,234,4,242,15,131,37,23,0
	.byte 0,221,4,234,220,4,199,221,28,202,139,6,15,182,204,15
	.byte 182,232,131,198,4,193,232,16,255,36,171

	.globl lj_BC_SUBVN
	.hidden lj_BC_SUBVN
	.type lj_BC_SUBVN, @function
	.size lj_BC_SUBVN, 43
lj_BC_SUBVN:
	.byte 15,182,236,15,182,192,131,124,234,4,242,15,131,250,22,0
	.byte 0,221,4,234,220,36,199,221,28,202,139,6,15,182,204,15
	.byte 182,232,131,198,4,193,232,16,255,36,171

	.globl lj_BC_MULVN
	.hidden lj_BC_MULVN
	.type lj_BC_MULVN, @function
	.size lj_BC_MULVN, 43
lj_BC_MULVN:
	.byte 15,182,236,15,182,192,131,124,234,4,242,15,131,207,22,0
	.byte 0,221,4,234,220,12,199,221,28,202,139,6,15,182,204,15
	.byte 182,232,131,198,4,193,232,16,255,36,171

	.globl lj_BC_DIVVN
	.hidden lj_BC_DIVVN
	.type lj_BC_DIVVN, @function
	.size lj_BC_DIVVN, 43
lj_BC_DIVVN:
	.byte 15,182,236,15,182,192,131,124,234,4,242,15,131,164,22,0
	.byte 0,221,4,234,220,52,199,221,28,202,139,6,15,182,204,15
	.byte 182,232,131,198,4,193,232,16,255,36,171

	.globl lj_BC_MODVN
	.hidden lj_BC_MODVN
	.type lj_BC_MODVN, @function
	.size lj_BC_MODVN, 48
lj_BC_MODVN:
	.byte 15,182,236,15,182,192,131,124,234,4,242,15,131,121,22,0
	.byte 0,221,4,234,221,4,199,232,80,44,0,0,221,28,202,139
	.byte 6,15,182,204,15,182,232,131,198,4,193,232,16,255,36,171

	.globl lj_BC_ADDNV
	.hidden lj_BC_ADDNV
	.type lj_BC_ADDNV, @function
	.size lj_BC_ADDNV, 43
lj_BC_ADDNV:
	.byte 15,182,236,15,182,192,131,124,234,4,242,15,131,78,22,0
	.byte 0,221,4,199,220,4,234,221,28,202,139,6,15,182,204,15
	.byte 182,232,131,198,4,193,232,16,255,36,171

	.globl lj_BC_SUBNV
	.hidden lj_BC_SUBNV
	.type lj_BC_SUBNV, @function
	.size lj_BC_SUBNV, 43
lj_BC_SUBNV:
	.byte 15,182,236,15,182,192,131,124,234,4,242,15,131,35,22,0
	.byte 0,221,4,199,220,36,234,221,28,202,139,6,15,182,204,15
	.byte 182,232,131,198,4,193,232,16,255,36,171

	.globl lj_BC_MULNV
	.hidden lj_BC_MULNV
	.type lj_BC_MULNV, @function
	.size lj_BC_MULNV, 43
lj_BC_MULNV:
	.byte 15,182,236,15,182,192,131,124,234,4,242,15,131,248,21,0
	.byte 0,221,4,199,220,12,234,221,28,202,139,6,15,182,204,15
	.byte 182,232,131,198,4,193,232,16,255,36,171

	.globl lj_BC_DIVNV
	.hidden lj_BC_DIVNV
	.type lj_BC_DIVNV, @function
	.size lj_BC_DIVNV, 43
lj_BC_DIVNV:
	.byte 15,182,236,15,182,192,131,124,234,4,242,15,131,205,21,0
	.byte 0,221,4,199,220,52,234,221,28,202,139,6,15,182,204,15
	.byte 182,232,131,198,4,193,232,16,255,36,171

	.globl lj_BC_MODNV
	.hidden lj_BC_MODNV
	.type lj_BC_MODNV, @function
	.size lj_BC_MODNV, 28
lj_BC_MODNV:
	.byte 15,182,236,15,182,192,131,124,234,4,242,15,131,162,21,0
	.byte 0,221,4,199,221,4,234,233,31,255,255,255

	.globl lj_BC_ADDVV
	.hidden lj_BC_ADDVV
	.type lj_BC_ADDVV, @function
	.size lj_BC_ADDVV, 54
lj_BC_ADDVV:
	.byte 15,182,236,15,182,192,131,124,234,4,242,15,131,150,21,0
	.byte 0,131,124,194,4,242,15,131,139,21,0,0,221,4,234,220
	.byte 4,194,221,28,202,139,6,15,182,204,15,182,232,131,198,4
	.byte 193,232,16,255,36,171

	.globl lj_BC_SUBVV
	.hidden lj_BC_SUBVV
	.type lj_BC_SUBVV, @function
	.size lj_BC_SUBVV, 54
lj_BC_SUBVV:
	.byte 15,182,236,15,182,192,131,124,234,4,242,15,131,96,21,0
	.byte 0,131,124,194,4,242,15,131,85,21,0,0,221,4,234,220
	.byte 36,194,221,28,202,139,6,15,182,204,15,182,232,131,198,4
	.byte 193,232,16,255,36,171

	.globl lj_BC_MULVV
	.hidden lj_BC_MULVV
	.type lj_BC_MULVV, @function
	.size lj_BC_MULVV, 54
lj_BC_MULVV:
	.byte 15,182,236,15,182,192,131,124,234,4,242,15,131,42,21,0
	.byte 0,131,124,194,4,242,15,131,31,21,0,0,221,4,234,220
	.byte 12,194,221,28,202,139,6,15,182,204,15,182,232,131,198,4
	.byte 193,232,16,255,36,171

	.globl lj_BC_DIVVV
	.hidden lj_BC_DIVVV
	.type lj_BC_DIVVV, @function
	.size lj_BC_DIVVV, 54
lj_BC_DIVVV:
	.byte 15,182,236,15,182,192,131,124,234,4,242,15,131,244,20,0
	.byte 0,131,124,194,4,242,15,131,233,20,0,0,221,4,234,220
	.byte 52,194,221,28,202,139,6,15,182,204,15,182,232,131,198,4
	.byte 193,232,16,255,36,171

	.globl lj_BC_MODVV
	.hidden lj_BC_MODVV
	.type lj_BC_MODVV, @function
	.size lj_BC_MODVV, 39
lj_BC_MODVV:
	.byte 15,182,236,15,182,192,131,124,234,4,242,15,131,190,20,0
	.byte 0,131,124,194,4,242,15,131,179,20,0,0,221,4,234,221
	.byte 4,194,233,32,254,255,255

	.globl lj_BC_POW
	.hidden lj_BC_POW
	.type lj_BC_POW, @function
	.size lj_BC_POW, 59
lj_BC_POW:
	.byte 15,182,236,15,182,192,131,124,234,4,242,15,131,151,20,0
	.byte 0,131,124,194,4,242,15,131,140,20,0,0,221,4,234,221
	.byte 4,194,232,180,42,0,0,221,28,202,139,6,15,182,204,15
	.byte 182,232,131,198,4,193,232,16,255,36,171

	.globl lj_BC_CAT
	.hidden lj_BC_CAT
	.type lj_BC_CAT, @function
	.size lj_BC_CAT, 88
lj_BC_CAT:
	.byte 15,182,236,15,182,192,141,12,194,41,232,137,76,36,4,137
	.byte 68,36,8,139,108,36,48,137,44,36,137,85,16,137,116,36
	.byte 24,232
	.long lj_meta_cat-.-4
	.byte 139,85,16,133,192,15,133,119,20,0,0,15,182,110,255,15
	.byte 182,78,253,139,68,234,4,139,44,234,137,68,202,4,137,44
	.byte 202,139,6,15,182,204,15,182,232,131,198,4,193,232,16,255
	.byte 36,171

	.globl lj_BC_KSTR
	.hidden lj_BC_KSTR
	.type lj_BC_KSTR, @function
	.size lj_BC_KSTR, 33
lj_BC_KSTR:
	.byte 247,208,139,4,135,199,68,202,4,251,255,255,255,137,4,202
	.byte 139,6,15,182,204,15,182,232,131,198,4,193,232,16,255,36
	.byte 171

	.globl lj_BC_KCDATA
	.hidden lj_BC_KCDATA
	.type lj_BC_KCDATA, @function
	.size lj_BC_KCDATA, 33
lj_BC_KCDATA:
	.byte 247,208,139,4,135,199,68,202,4,245,255,255,255,137,4,202
	.byte 139,6,15,182,204,15,182,232,131,198,4,193,232,16,255,36
	.byte 171

	.globl lj_BC_KSHORT
	.hidden lj_BC_KSHORT
	.type lj_BC_KSHORT, @function
	.size lj_BC_KSHORT, 23
lj_BC_KSHORT:
	.byte 223,70,254,221,28,202,139,6,15,182,204,15,182,232,131,198
	.byte 4,193,232,16,255,36,171

	.globl lj_BC_KNUM
	.hidden lj_BC_KNUM
	.type lj_BC_KNUM, @function
	.size lj_BC_KNUM, 23
lj_BC_KNUM:
	.byte 221,4,199,221,28,202,139,6,15,182,204,15,182,232,131,198
	.byte 4,193,232,16,255,36,171

	.globl lj_BC_KPRI
	.hidden lj_BC_KPRI
	.type lj_BC_KPRI, @function
	.size lj_BC_KPRI, 23
lj_BC_KPRI:
	.byte 247,208,137,68,202,4,139,6,15,182,204,15,182,232,131,198
	.byte 4,193,232,16,255,36,171

	.globl lj_BC_KNIL
	.hidden lj_BC_KNIL
	.type lj_BC_KNIL, @function
	.size lj_BC_KNIL, 42
lj_BC_KNIL:
	.byte 141,76,202,12,141,68,194,4,189,255,255,255,255,137,105,248
	.byte 137,41,131,193,8,57,193,118,247,139,6,15,182,204,15,182
	.byte 232,131,198,4,193,232,16,255,36,171

	.globl lj_BC_UGET
	.hidden lj_BC_UGET
	.type lj_BC_UGET, @function
	.size lj_BC_UGET, 40
lj_BC_UGET:
	.byte 139,106,248,139,108,133,20,139,109,16,139,69,4,139,109,0
	.byte 137,68,202,4,137,44,202,139,6,15,182,204,15,182,232,131
	.byte 198,4,193,232,16,255,36,171

	.globl lj_BC_USETV
	.hidden lj_BC_USETV
	.type lj_BC_USETV, @function
	.size lj_BC_USETV, 83
lj_BC_USETV:
	.byte 139,106,248,139,108,141,20,128,125,6,0,139,109,16,139,12
	.byte 194,139,68,194,4,137,77,0,137,69,4,116,6,246,69,252
	.byte 4,117,17,139,6,15,182,204,15,182,232,131,198,4,193,232
	.byte 16,255,36,171,131,232,252,131,248,246,118,231,246,65,4,3
	.byte 116,225,135,213,141,139,240,244,255,255,232
	.long lj_gc_barrieruv-.-4
	.byte 137,234,235,208

	.globl lj_BC_USETS
	.hidden lj_BC_USETS
	.type lj_BC_USETS, @function
	.size lj_BC_USETS, 78
lj_BC_USETS:
	.byte 247,208,139,106,248,139,108,141,20,139,12,135,139,69,16,137
	.byte 8,199,64,4,251,255,255,255,246,69,4,4,117,17,139,6
	.byte 15,182,204,15,182,232,131,198,4,193,232,16,255,36,171,246
	.byte 65,4,3,116,233,128,125,6,0,116,227,137,213,137,194,141
	.byte 139,240,244,255,255,232
	.long lj_gc_barrieruv-.-4
	.byte 137,234,235,208

	.globl lj_BC_USETN
	.hidden lj_BC_USETN
	.type lj_BC_USETN, @function
	.size lj_BC_USETN, 32
lj_BC_USETN:
	.byte 139,106,248,221,4,199,139,108,141,20,139,77,16,221,25,139
	.byte 6,15,182,204,15,182,232,131,198,4,193,232,16,255,36,171

	.globl lj_BC_USETP
	.hidden lj_BC_USETP
	.type lj_BC_USETP, @function
	.size lj_BC_USETP, 32
lj_BC_USETP:
	.byte 247,208,139,106,248,139,108,141,20,139,77,16,137,65,4,139
	.byte 6,15,182,204,15,182,232,131,198,4,193,232,16,255,36,171

	.globl lj_BC_UCLO
	.hidden lj_BC_UCLO
	.type lj_BC_UCLO, @function
	.size lj_BC_UCLO, 50
lj_BC_UCLO:
	.byte 141,180,134,0,0,254,255,139,108,36,48,131,125,32,0,116
	.byte 16,137,85,16,141,20,202,137,233,232
	.long lj_func_closeuv-.-4
	.byte 139,85,16,139,6,15,182,204,15,182,232,131,198,4,193,232
	.byte 16,255,36,171

	.globl lj_BC_FNEW
	.hidden lj_BC_FNEW
	.type lj_BC_FNEW, @function
	.size lj_BC_FNEW, 70
lj_BC_FNEW:
	.byte 247,208,139,74,248,139,4,135,139,108,36,48,137,76,36,8
	.byte 137,68,36,4,137,44,36,137,85,16,137,116,36,24,232
	.long lj_func_newL_gc-.-4
	.byte 139,85,16,15,182,78,253,137,4,202,199,68,202,4,247,255
	.byte 255,255,139,6,15,182,204,15,182,232,131,198,4,193,232,16
	.byte 255,36,171

	.globl lj_BC_TNEW
	.hidden lj_BC_TNEW
	.type lj_BC_TNEW, @function
	.size lj_BC_TNEW, 113
lj_BC_TNEW:
	.byte 139,108,36,48,137,85,16,139,139,4,245,255,255,59,139,8
	.byte 245,255,255,137,116,36,24,115,75,137,193,37,255,7,0,0
	.byte 193,233,11,137,76,36,8,61,255,7,0,0,116,47,137,44
	.byte 36,137,68,36,4,232
	.long lj_tab_new-.-4
	.byte 139,85,16,15,182,78,253,137,4,202,199,68,202,4,244,255
	.byte 255,255,139,6,15,182,204,15,182,232,131,198,4,193,232,16
	.byte 255,36,171,184,1,8,0,0,235,202,137,233,232
	.long lj_gc_step_fixtop-.-4
	.byte 15,183,70,254,235,168

	.globl lj_BC_TDUP
	.hidden lj_BC_TDUP
	.type lj_BC_TDUP, @function
	.size lj_BC_TDUP, 87
lj_BC_TDUP:
	.byte 247,208,139,108,36,48,139,139,4,245,255,255,137,116,36,24
	.byte 59,139,8,245,255,255,137,85,16,115,45,139,20,135,137,233
	.byte 232
	.long lj_tab_dup-.-4
	.byte 139,85,16,15,182,78,253,137,4,202,199,68,202,4,244,255
	.byte 255,255,139,6,15,182,204,15,182,232,131,198,4,193,232,16
	.byte 255,36,171,137,233,232
	.long lj_gc_step_fixtop-.-4
	.byte 15,183,70,254,247,208,235,196

	.globl lj_BC_GGET
	.hidden lj_BC_GGET
	.type lj_BC_GGET, @function
	.size lj_BC_GGET, 16
lj_BC_GGET:
	.byte 247,208,139,106,248,139,109,8,139,4,135,233,189,0,0,0

	.globl lj_BC_GSET
	.hidden lj_BC_GSET
	.type lj_BC_GSET, @function
	.size lj_BC_GSET, 16
lj_BC_GSET:
	.byte 247,208,139,106,248,139,109,8,139,4,135,233,61,2,0,0

	.globl lj_BC_TGETV
	.hidden lj_BC_TGETV
	.type lj_BC_TGETV, @function
	.size lj_BC_TGETV, 148
lj_BC_TGETV:
	.byte 15,182,236,15,182,192,131,124,234,4,244,15,133,14,15,0
	.byte 0,139,44,234,131,124,194,4,242,115,105,221,4,194,219,20
	.byte 36,219,4,36,223,233,221,216,139,4,36,15,133,238,14,0
	.byte 0,59,69,24,15,131,229,14,0,0,193,224,3,3,69,8
	.byte 131,120,4,255,116,29,139,40,139,64,4,137,44,202,137,68
	.byte 202,4,139,6,15,182,204,15,182,232,131,198,4,193,232,16
	.byte 255,36,171,131,125,16,0,116,17,139,77,16,246,65,6,1
	.byte 15,132,169,14,0,0,15,182,78,253,199,68,202,4,255,255
	.byte 255,255,235,206,131,124,194,4,251,15,133,144,14,0,0,139
	.byte 4,194,235,25

	.globl lj_BC_TGETS
	.hidden lj_BC_TGETS
	.type lj_BC_TGETS, @function
	.size lj_BC_TGETS, 126
lj_BC_TGETS:
	.byte 15,182,236,15,182,192,247,208,139,4,135,131,124,234,4,244
	.byte 15,133,54,14,0,0,139,44,234,139,77,28,35,72,8,107
	.byte 201,24,3,77,20,131,121,12,251,117,58,57,65,8,117,53
	.byte 131,121,4,255,116,54,15,182,70,253,139,41,139,73,4,137
	.byte 44,194,137,76,194,4,139,6,15,182,204,15,182,232,131,198
	.byte 4,193,232,16,255,36,171,15,182,70,253,199,68,194,4,255
	.byte 255,255,255,235,225,139,73,16,133,201,117,185,139,77,16,133
	.byte 201,116,228,246,65,6,1,117,222,233,206,13,0,0

	.globl lj_BC_TGETB
	.hidden lj_BC_TGETB
	.type lj_BC_TGETB, @function
	.size lj_BC_TGETB, 103
lj_BC_TGETB:
	.byte 15,182,236,15,182,192,131,124,234,4,244,15,133,230,13,0
	.byte 0,139,44,234,59,69,24,15,131,218,13,0,0,193,224,3
	.byte 3,69,8,131,120,4,255,116,29,139,40,139,64,4,137,44
	.byte 202,137,68,202,4,139,6,15,182,204,15,182,232,131,198,4
	.byte 193,232,16,255,36,171,131,125,16,0,116,17,139,77,16,246
	.byte 65,6,1,15,132,158,13,0,0,15,182,78,253,199,68,202
	.byte 4,255,255,255,255,235,206

	.globl lj_BC_TSETV
	.hidden lj_BC_TSETV
	.type lj_BC_TSETV, @function
	.size lj_BC_TSETV, 171
lj_BC_TSETV:
	.byte 15,182,236,15,182,192,131,124,234,4,244,15,133,61,14,0
	.byte 0,139,44,234,131,124,194,4,242,115,103,221,4,194,219,20
	.byte 36,219,4,36,223,233,221,216,139,4,36,15,133,29,14,0
	.byte 0,59,69,24,15,131,20,14,0,0,193,224,3,3,69,8
	.byte 131,120,4,255,116,35,246,69,4,4,117,70,139,108,202,4
	.byte 139,12,202,137,104,4,137,8,139,6,15,182,204,15,182,232
	.byte 131,198,4,193,232,16,255,36,171,131,125,16,0,116,215,139
	.byte 77,16,246,65,6,2,15,132,210,13,0,0,15,182,78,253
	.byte 235,196,131,124,194,4,251,15,133,193,13,0,0,139,4,194
	.byte 235,50,128,101,4,251,139,139,32,245,255,255,137,171,32,245
	.byte 255,255,137,77,12,15,182,78,253,235,161

	.globl lj_BC_TSETS
	.hidden lj_BC_TSETS
	.type lj_BC_TSETS, @function
	.size lj_BC_TSETS, 239
lj_BC_TSETS:
	.byte 15,182,236,15,182,192,247,208,139,4,135,131,124,234,4,244
	.byte 15,133,78,13,0,0,139,44,234,139,77,28,35,72,8,107
	.byte 201,24,198,69,6,0,3,77,20,131,121,12,251,117,83,57
	.byte 65,8,117,78,131,121,4,255,116,43,246,69,4,4,15,133
	.byte 147,0,0,0,15,182,70,253,139,108,194,4,139,4,194,137
	.byte 105,4,137,1,139,6,15,182,204,15,182,232,131,198,4,193
	.byte 232,16,255,36,171,131,125,16,0,116,207,137,76,36,16,139
	.byte 77,16,246,65,6,2,15,132,232,12,0,0,139,76,36,16
	.byte 235,184,139,73,16,133,201,117,160,139,77,16,133,201,116,10
	.byte 246,65,6,2,15,132,202,12,0,0,137,68,36,16,199,68
	.byte 36,20,251,255,255,255,137,108,36,12,141,68,36,16,137,108
	.byte 36,4,139,108,36,48,137,68,36,8,137,44,36,137,85,16
	.byte 137,116,36,24,232
	.long lj_tab_newkey-.-4
	.byte 139,85,16,139,108,36,12,137,193,233,99,255,255,255,128,101
	.byte 4,251,139,131,32,245,255,255,137,171,32,245,255,255,137,69
	.byte 12,233,85,255,255,255

	.globl lj_BC_TSETB
	.hidden lj_BC_TSETB
	.type lj_BC_TSETB, @function
	.size lj_BC_TSETB, 126
lj_BC_TSETB:
	.byte 15,182,236,15,182,192,131,124,234,4,244,15,133,141,12,0
	.byte 0,139,44,234,59,69,24,15,131,129,12,0,0,193,224,3
	.byte 3,69,8,131,120,4,255,116,35,246,69,4,4,117,54,139
	.byte 108,202,4,139,12,202,137,104,4,137,8,139,6,15,182,204
	.byte 15,182,232,131,198,4,193,232,16,255,36,171,131,125,16,0
	.byte 116,215,139,77,16,246,65,6,2,15,132,63,12,0,0,15
	.byte 182,78,253,235,196,128,101,4,251,139,139,32,245,255,255,137
	.byte 171,32,245,255,255,137,77,12,15,182,78,253,235,177

	.globl lj_BC_TSETM
	.hidden lj_BC_TSETM
	.type lj_BC_TSETM, @function
	.size lj_BC_TSETM, 142
lj_BC_TSETM:
	.byte 137,124,36,16,139,60,199,141,12,202,139,105,248,246,69,4
	.byte 4,117,102,139,68,36,20,131,232,1,116,36,1,248,59,69
	.byte 24,119,50,41,248,193,231,3,3,125,8,139,41,137,47,139
	.byte 105,4,131,193,8,137,111,4,131,199,8,131,232,1,117,235
	.byte 139,124,36,16,139,6,15,182,204,15,182,232,131,198,4,193
	.byte 232,16,255,36,171,137,108,36,4,139,108,36,48,137,85,16
	.byte 137,68,36,8,137,44,36,137,116,36,24,232
	.long lj_tab_reasize-.-4
	.byte 139,85,16,15,182,78,253,235,142,128,101,4,251,139,131,32
	.byte 245,255,255,137,171,32,245,255,255,137,69,12,235,133

	.globl lj_BC_CALLM
	.hidden lj_BC_CALLM
	.type lj_BC_CALLM, @function
	.size lj_BC_CALLM, 45
lj_BC_CALLM:
	.byte 15,182,192,3,68,36,20,131,124,202,4,247,139,44,202,15
	.byte 133,48,13,0,0,141,84,202,8,137,114,252,139,117,16,139
	.byte 14,15,182,233,15,182,205,131,198,4,255,36,171

	.globl lj_BC_CALL
	.hidden lj_BC_CALL
	.type lj_BC_CALL, @function
	.size lj_BC_CALL, 41
lj_BC_CALL:
	.byte 15,182,192,131,124,202,4,247,139,44,202,15,133,7,13,0
	.byte 0,141,84,202,8,137,114,252,139,117,16,139,14,15,182,233
	.byte 15,182,205,131,198,4,255,36,171

	.globl lj_BC_CALLMT
	.hidden lj_BC_CALLMT
	.type lj_BC_CALLMT, @function
	.size lj_BC_CALLMT, 4
lj_BC_CALLMT:
	.byte 3,68,36,20

	.globl lj_BC_CALLT
	.hidden lj_BC_CALLT
	.type lj_BC_CALLT, @function
	.size lj_BC_CALLT, 144
lj_BC_CALLT:
	.byte 141,76,202,8,137,215,139,105,248,131,121,252,247,15,133,220
	.byte 12,0,0,139,114,252,247,198,3,0,0,0,117,89,137,106
	.byte 248,137,68,36,20,131,232,1,116,24,139,41,137,47,139,105
	.byte 4,131,193,8,137,111,4,131,199,8,131,232,1,117,235,139
	.byte 106,248,139,68,36,20,128,125,6,1,119,17,139,117,16,139
	.byte 14,15,182,233,15,182,205,131,198,4,255,36,171,247,198,3
	.byte 0,0,0,117,231,15,182,78,253,247,209,139,124,202,248,139
	.byte 127,16,139,127,208,235,213,131,238,3,247,198,7,0,0,0
	.byte 117,9,41,242,137,215,139,114,252,235,147,131,198,3,235,142

	.globl lj_BC_ITERC
	.hidden lj_BC_ITERC
	.type lj_BC_ITERC, @function
	.size lj_BC_ITERC, 75
lj_BC_ITERC:
	.byte 141,76,202,8,139,105,232,139,65,236,137,41,137,65,4,139
	.byte 105,240,139,65,244,137,105,8,137,65,12,139,105,224,139,65
	.byte 228,137,105,248,137,65,252,131,248,247,184,3,0,0,0,15
	.byte 133,42,12,0,0,137,202,137,114,252,139,117,16,139,14,15
	.byte 182,233,15,182,205,131,198,4,255,36,171

	.globl lj_BC_ITERN
	.hidden lj_BC_ITERN
	.type lj_BC_ITERN, @function
	.size lj_BC_ITERN, 170
lj_BC_ITERN:
	.byte 137,124,36,16,137,92,36,20,139,108,202,240,139,68,202,248
	.byte 139,93,24,131,198,4,139,125,8,57,216,115,81,131,124,199
	.byte 4,255,116,65,219,68,202,248,139,108,199,4,137,108,202,12
	.byte 139,44,199,137,108,202,8,131,192,1,221,28,202,137,68,202
	.byte 248,15,183,70,254,141,180,134,0,0,254,255,139,92,36,20
	.byte 139,124,36,16,139,6,15,182,204,15,182,232,131,198,4,193
	.byte 232,16,255,36,171,131,192,1,137,68,202,248,235,171,41,216
	.byte 59,69,28,119,215,107,248,24,3,125,20,131,127,4,255,116
	.byte 36,141,92,24,1,139,111,8,139,71,12,137,44,202,137,68
	.byte 202,4,139,47,139,71,4,137,108,202,8,137,68,202,12,137
	.byte 92,202,248,235,156,131,192,1,235,198

	.globl lj_BC_VARG
	.hidden lj_BC_VARG
	.type lj_BC_VARG, @function
	.size lj_BC_VARG, 188
lj_BC_VARG:
	.byte 15,182,236,15,182,192,137,124,36,16,141,124,194,11,141,12
	.byte 202,43,122,252,133,237,116,68,141,108,233,248,57,215,115,25
	.byte 139,71,248,137,1,139,71,252,131,199,8,137,65,4,131,193
	.byte 8,57,233,115,18,57,215,114,231,199,65,4,255,255,255,255
	.byte 131,193,8,57,233,114,242,139,124,36,16,139,6,15,182,204
	.byte 15,182,232,131,198,4,193,232,16,255,36,171,199,68,36,20
	.byte 1,0,0,0,137,208,41,248,118,221,137,197,193,237,3,131
	.byte 197,1,137,108,36,20,139,108,36,48,1,200,59,69,24,119
	.byte 23,139,71,248,137,1,139,71,252,131,199,8,137,65,4,131
	.byte 193,8,57,215,114,235,235,175,137,85,16,137,77,20,137,116
	.byte 36,24,41,215,139,84,36,20,131,234,1,137,233,232
	.long lj_state_growstack-.-4
	.byte 139,85,16,139,77,20,1,215,235,197

	.globl lj_BC_ISNEXT
	.hidden lj_BC_ISNEXT
	.type lj_BC_ISNEXT, @function
	.size lj_BC_ISNEXT, 87
lj_BC_ISNEXT:
	.byte 131,124,202,236,247,117,64,139,108,202,232,131,124,202,244,244
	.byte 117,53,131,124,202,252,255,117,46,128,125,6,4,117,40,141
	.byte 180,134,0,0,254,255,199,68,202,248,0,0,0,0,199,68
	.byte 202,252,255,127,254,255,139,6,15,182,204,15,182,232,131,198
	.byte 4,193,232,16,255,36,171,198,70,252,84,141,180,134,0,0
	.byte 254,255,198,6,65,235,223

	.globl lj_BC_RETM
	.hidden lj_BC_RETM
	.type lj_BC_RETM, @function
	.size lj_BC_RETM, 4
lj_BC_RETM:
	.byte 3,68,36,20

	.globl lj_BC_RET
	.hidden lj_BC_RET
	.type lj_BC_RET, @function
	.size lj_BC_RET, 129
lj_BC_RET:
	.byte 193,225,3,139,114,252,137,68,36,20,247,198,3,0,0,0
	.byte 117,90,137,215,131,232,1,116,21,139,44,15,137,111,248,139
	.byte 108,15,4,137,111,252,131,199,8,131,232,1,117,235,139,68
	.byte 36,20,15,182,110,255,57,197,119,35,15,182,78,253,247,209
	.byte 141,20,202,139,122,248,139,127,16,139,127,208,139,6,15,182
	.byte 204,15,182,232,131,198,4,193,232,16,255,36,171,199,71,252
	.byte 255,255,255,255,131,199,8,131,192,1,235,202,141,110,253,247
	.byte 197,7,0,0,0,15,133,120,4,0,0,41,234,1,233,235
	.byte 130

	.globl lj_BC_RET0
	.hidden lj_BC_RET0
	.type lj_BC_RET0, @function
	.size lj_BC_RET0, 87
lj_BC_RET0:
	.byte 139,114,252,137,68,36,20,247,198,3,0,0,0,117,53,56
	.byte 70,255,119,35,15,182,78,253,247,209,141,20,202,139,122,248
	.byte 139,127,16,139,127,208,139,6,15,182,204,15,182,232,131,198
	.byte 4,193,232,16,255,36,171,199,68,194,244,255,255,255,255,131
	.byte 192,1,235,203,141,110,253,247,197,7,0,0,0,15,133,31
	.byte 4,0,0,41,234,235,169

	.globl lj_BC_RET1
	.hidden lj_BC_RET1
	.type lj_BC_RET1, @function
	.size lj_BC_RET1, 105
lj_BC_RET1:
	.byte 193,225,3,139,114,252,137,68,36,20,247,198,3,0,0,0
	.byte 117,66,139,108,10,4,137,106,252,139,44,10,137,106,248,56
	.byte 70,255,119,35,15,182,78,253,247,209,141,20,202,139,122,248
	.byte 139,127,16,139,127,208,139,6,15,182,204,15,182,232,131,198
	.byte 4,193,232,16,255,36,171,199,68,194,244,255,255,255,255,131
	.byte 192,1,235,203,141,110,253,247,197,7,0,0,0,15,133,184
	.byte 3,0,0,41,234,1,233,235,154

	.globl lj_BC_FORI
	.hidden lj_BC_FORI
	.type lj_BC_FORI, @function
	.size lj_BC_FORI, 77
lj_BC_FORI:
	.byte 141,12,202,131,121,4,242,15,131,93,9,0,0,131,121,12
	.byte 242,15,131,83,9,0,0,139,105,20,131,253,242,15,131,71
	.byte 9,0,0,221,65,8,221,1,221,81,24,124,2,217,201,223
	.byte 233,221,216,115,7,141,180,134,0,0,254,255,139,6,15,182
	.byte 204,15,182,232,131,198,4,193,232,16,255,36,171

	.globl lj_BC_JFORI
	.hidden lj_BC_JFORI
	.type lj_BC_JFORI, @function
	.size lj_BC_JFORI, 85
lj_BC_JFORI:
	.byte 141,12,202,131,121,4,242,15,131,16,9,0,0,131,121,12
	.byte 242,15,131,6,9,0,0,139,105,20,131,253,242,15,131,250
	.byte 8,0,0,221,65,8,221,1,221,81,24,124,2,217,201,223
	.byte 233,221,216,141,180,134,0,0,254,255,15,183,70,254,15,131
	.byte 23,1,0,0,139,6,15,182,204,15,182,232,131,198,4,193
	.byte 232,16,255,36,171

	.globl lj_BC_FORL
	.hidden lj_BC_FORL
	.type lj_BC_FORL, @function
	.size lj_BC_FORL, 19
lj_BC_FORL:
	.byte 137,245,209,237,131,229,126,102,131,108,43,128,2,15,130,221
	.byte 26,0,0

	.globl lj_BC_IFORL
	.hidden lj_BC_IFORL
	.type lj_BC_IFORL, @function
	.size lj_BC_IFORL, 55
lj_BC_IFORL:
	.byte 141,12,202,139,105,20,221,65,8,221,1,220,65,16,221,17
	.byte 221,81,24,133,237,120,2,217,201,223,233,221,216,114,7,141
	.byte 180,134,0,0,254,255,139,6,15,182,204,15,182,232,131,198
	.byte 4,193,232,16,255,36,171

	.globl lj_BC_JFORL
	.hidden lj_BC_JFORL
	.type lj_BC_JFORL, @function
	.size lj_BC_JFORL, 52
lj_BC_JFORL:
	.byte 141,12,202,139,105,20,221,65,8,221,1,220,65,16,221,17
	.byte 221,81,24,133,237,120,2,217,201,223,233,221,216,15,131,153
	.byte 0,0,0,139,6,15,182,204,15,182,232,131,198,4,193,232
	.byte 16,255,36,171

	.globl lj_BC_ITERL
	.hidden lj_BC_ITERL
	.type lj_BC_ITERL, @function
	.size lj_BC_ITERL, 19
lj_BC_ITERL:
	.byte 137,245,209,237,131,229,126,102,131,108,43,128,2,15,130,95
	.byte 26,0,0

	.globl lj_BC_IITERL
	.hidden lj_BC_IITERL
	.type lj_BC_IITERL, @function
	.size lj_BC_IITERL, 43
lj_BC_IITERL:
	.byte 141,12,202,139,105,4,131,253,255,116,15,141,180,134,0,0
	.byte 254,255,139,1,137,105,252,137,65,248,139,6,15,182,204,15
	.byte 182,232,131,198,4,193,232,16,255,36,171

	.globl lj_BC_JITERL
	.hidden lj_BC_JITERL
	.type lj_BC_JITERL, @function
	.size lj_BC_JITERL, 38
lj_BC_JITERL:
	.byte 141,12,202,139,105,4,131,253,255,116,10,137,105,252,139,41
	.byte 137,105,248,235,53,139,6,15,182,204,15,182,232,131,198,4
	.byte 193,232,16,255,36,171

	.globl lj_BC_LOOP
	.hidden lj_BC_LOOP
	.type lj_BC_LOOP, @function
	.size lj_BC_LOOP, 19
lj_BC_LOOP:
	.byte 137,245,209,237,131,229,126,102,131,108,43,128,2,15,130,251
	.byte 25,0,0

	.globl lj_BC_ILOOP
	.hidden lj_BC_ILOOP
	.type lj_BC_ILOOP, @function
	.size lj_BC_ILOOP, 17
lj_BC_ILOOP:
	.byte 139,6,15,182,204,15,182,232,131,198,4,193,232,16,255,36
	.byte 171

	.globl lj_BC_JLOOP
	.hidden lj_BC_JLOOP
	.type lj_BC_JLOOP, @function
	.size lj_BC_JLOOP, 30
lj_BC_JLOOP:
	.byte 139,139,112,247,255,255,139,4,129,139,64,52,139,108,36,48
	.byte 137,147,204,245,255,255,137,171,200,245,255,255,255,224

	.globl lj_BC_JMP
	.hidden lj_BC_JMP
	.type lj_BC_JMP, @function
	.size lj_BC_JMP, 24
lj_BC_JMP:
	.byte 141,180,134,0,0,254,255,139,6,15,182,204,15,182,232,131
	.byte 198,4,193,232,16,255,36,171

	.globl lj_BC_FUNCF
	.hidden lj_BC_FUNCF
	.type lj_BC_FUNCF, @function
	.size lj_BC_FUNCF, 19
lj_BC_FUNCF:
	.byte 137,245,209,237,131,229,126,102,131,108,43,128,1,15,130,215
	.byte 25,0,0

	.globl lj_BC_IFUNCF
	.hidden lj_BC_IFUNCF
	.type lj_BC_IFUNCF, @function
	.size lj_BC_IFUNCF, 61
lj_BC_IFUNCF:
	.byte 139,126,204,139,108,36,48,141,12,202,59,77,24,15,135,163
	.byte 2,0,0,15,182,78,194,57,200,118,17,139,6,15,182,204
	.byte 15,182,232,131,198,4,193,232,16,255,36,171,199,68,194,252
	.byte 255,255,255,255,131,192,1,57,200,118,241,235,222

	.globl lj_BC_JFUNCF
	.hidden lj_BC_JFUNCF
	.type lj_BC_JFUNCF, @function
	.size lj_BC_JFUNCF, 53
lj_BC_JFUNCF:
	.byte 139,126,204,139,108,36,48,141,12,202,59,77,24,15,135,102
	.byte 2,0,0,15,182,78,194,57,200,118,9,15,183,70,254,233
	.byte 86,255,255,255,199,68,194,252,255,255,255,255,131,192,1,57
	.byte 200,118,241,235,230

	.globl lj_BC_FUNCV
	.hidden lj_BC_FUNCV
	.type lj_BC_FUNCV, @function
	.size lj_BC_FUNCV, 0
lj_BC_FUNCV:

	.globl lj_BC_IFUNCV
	.hidden lj_BC_IFUNCV
	.type lj_BC_IFUNCV, @function
	.size lj_BC_IFUNCV, 117
lj_BC_IFUNCV:
	.byte 141,44,197,3,0,0,0,141,4,194,139,122,248,137,104,252
	.byte 137,120,248,139,108,36,48,141,12,200,59,77,24,15,135,28
	.byte 2,0,0,137,209,137,194,15,182,110,194,133,237,116,33,131
	.byte 193,8,57,209,115,46,139,121,248,137,56,139,121,252,137,120
	.byte 4,131,192,8,199,65,252,255,255,255,255,131,237,1,117,223
	.byte 139,126,204,139,6,15,182,204,15,182,232,131,198,4,193,232
	.byte 16,255,36,171,199,64,4,255,255,255,255,131,192,8,131,237
	.byte 1,117,241,235,219

	.globl lj_BC_JFUNCV
	.hidden lj_BC_JFUNCV
	.type lj_BC_JFUNCV, @function
	.size lj_BC_JFUNCV, 1
lj_BC_JFUNCV:
	.byte 204

	.globl lj_BC_FUNCC
	.hidden lj_BC_FUNCC
	.type lj_BC_FUNCC, @function
	.size lj_BC_FUNCC, 76
lj_BC_FUNCC:
	.byte 139,106,248,139,125,20,139,108,36,48,141,68,194,248,137,85
	.byte 16,141,136,160,0,0,0,59,77,24,137,69,20,137,44,36
	.byte 15,135,156,1,0,0,199,131,188,245,255,255,254,255,255,255
	.byte 255,215,199,131,188,245,255,255,255,255,255,255,139,85,16,141
	.byte 12,194,247,217,3,77,20,139,114,252,235,116

	.globl lj_BC_FUNCCW
	.hidden lj_BC_FUNCCW
	.type lj_BC_FUNCCW, @function
	.size lj_BC_FUNCCW, 84
lj_BC_FUNCCW:
	.byte 139,106,248,139,125,20,139,108,36,48,141,68,194,248,137,85
	.byte 16,141,136,160,0,0,0,59,77,24,137,69,20,137,124,36
	.byte 4,137,44,36,15,135,76,1,0,0,199,131,188,245,255,255
	.byte 254,255,255,255,255,147,180,245,255,255,199,131,188,245,255,255
	.byte 255,255,255,255,139,85,16,141,12,194,247,217,3,77,20,139
	.byte 114,252,235,32

	.globl lj_vm_returnp
	.hidden lj_vm_returnp
	.type lj_vm_returnp, @function
	.size lj_vm_returnp, 32
lj_vm_returnp:
	.byte 247,198,4,0,0,0,15,132,154,2,0,0,131,230,248,41
	.byte 242,141,76,49,248,139,114,252,199,68,10,4,253,255,255,255

	.globl lj_vm_returnc
	.hidden lj_vm_returnc
	.type lj_vm_returnc, @function
	.size lj_vm_returnc, 25
lj_vm_returnc:
	.byte 131,192,1,15,132,166,0,0,0,137,68,36,20,247,198,3
	.byte 0,0,0,15,132,31,251,255,255

	.globl lj_vm_return
	.hidden lj_vm_return
	.type lj_vm_return, @function
	.size lj_vm_return, 79
lj_vm_return:
	.byte 131,246,1,247,198,3,0,0,0,117,188,199,131,188,245,255
	.byte 255,254,255,255,255,131,230,248,41,214,247,222,131,232,1,116
	.byte 21,139,44,10,137,106,248,139,108,10,4,137,106,252,131,194
	.byte 8,131,232,1,117,235,139,108,36,48,137,117,16,139,68,36
	.byte 20,139,76,36,56,57,193,117,23,131,234,8,137,85,20

	.globl lj_vm_leave_cp
	.hidden lj_vm_leave_cp
	.type lj_vm_leave_cp, @function
	.size lj_vm_leave_cp, 9
lj_vm_leave_cp:
	.byte 139,76,36,52,137,77,40,49,192

	.globl lj_vm_leave_unw
	.hidden lj_vm_leave_unw
	.type lj_vm_leave_unw, @function
	.size lj_vm_leave_unw, 62
lj_vm_leave_unw:
	.byte 131,196,28,91,94,95,93,195,114,20,59,85,24,119,26,199
	.byte 66,252,255,255,255,255,131,194,8,131,192,1,235,207,133,201
	.byte 116,207,41,193,141,20,202,235,200,137,85,20,137,68,36,20
	.byte 137,202,137,233,232
	.long lj_state_growstack-.-4
	.byte 139,85,20,235,167

	.globl lj_vm_unwind_yield
	.hidden lj_vm_unwind_yield
	.type lj_vm_unwind_yield, @function
	.size lj_vm_unwind_yield, 4
lj_vm_unwind_yield:
	.byte 176,1,235,4

	.globl lj_vm_unwind_c
	.hidden lj_vm_unwind_c
	.type lj_vm_unwind_c, @function
	.size lj_vm_unwind_c, 4
lj_vm_unwind_c:
	.byte 137,208,137,204

	.globl lj_vm_unwind_c_eh
	.hidden lj_vm_unwind_c_eh
	.type lj_vm_unwind_c_eh, @function
	.size lj_vm_unwind_c_eh, 19
lj_vm_unwind_c_eh:
	.byte 139,108,36,48,139,109,8,199,133,204,0,0,0,254,255,255
	.byte 255,235,167

	.globl lj_vm_unwind_rethrow
	.hidden lj_vm_unwind_rethrow
	.type lj_vm_unwind_rethrow, @function
	.size lj_vm_unwind_rethrow, 0
lj_vm_unwind_rethrow:

	.globl lj_vm_unwind_ff
	.hidden lj_vm_unwind_ff
	.type lj_vm_unwind_ff, @function
	.size lj_vm_unwind_ff, 5
lj_vm_unwind_ff:
	.byte 131,225,252,137,204

	.globl lj_vm_unwind_ff_eh
	.hidden lj_vm_unwind_ff_eh
	.type lj_vm_unwind_ff_eh, @function
	.size lj_vm_unwind_ff_eh, 51
lj_vm_unwind_ff_eh:
	.byte 139,108,36,48,185,248,255,255,255,184,2,0,0,0,139,85
	.byte 16,139,93,8,129,195,16,11,0,0,139,114,252,199,66,252
	.byte 254,255,255,255,199,131,188,245,255,255,255,255,255,255,233,254
	.byte 254,255,255

	.globl lj_vm_growstack_c
	.hidden lj_vm_growstack_c
	.type lj_vm_growstack_c, @function
	.size lj_vm_growstack_c, 7
lj_vm_growstack_c:
	.byte 186,20,0,0,0,235,28

	.globl lj_vm_growstack_v
	.hidden lj_vm_growstack_v
	.type lj_vm_growstack_v, @function
	.size lj_vm_growstack_v, 5
lj_vm_growstack_v:
	.byte 131,232,8,235,4

	.globl lj_vm_growstack_f
	.hidden lj_vm_growstack_f
	.type lj_vm_growstack_f, @function
	.size lj_vm_growstack_f, 64
lj_vm_growstack_f:
	.byte 141,68,194,248,15,182,78,195,131,198,4,137,85,16,137,69
	.byte 20,137,116,36,24,137,202,137,233,232
	.long lj_state_growstack-.-4
	.byte 139,85,16,139,69,20,139,106,248,41,208,193,232,3,131,192
	.byte 1,139,117,16,139,14,15,182,233,15,182,205,131,198,4,255
	.byte 36,171

	.globl lj_vm_resume
	.hidden lj_vm_resume
	.type lj_vm_resume, @function
	.size lj_vm_resume, 104
lj_vm_resume:
	.byte 85,87,86,83,131,236,28,139,108,36,48,139,76,36,52,190
	.byte 5,0,0,0,49,192,141,124,36,1,139,93,8,129,195,16
	.byte 11,0,0,137,125,40,137,68,36,24,137,68,36,52,56,69
	.byte 7,116,110,199,131,188,245,255,255,255,255,255,255,136,69,7
	.byte 139,85,16,139,69,20,41,200,193,232,3,131,192,1,41,209
	.byte 139,114,252,137,68,36,20,247,198,3,0,0,0,15,132,135
	.byte 249,255,255,233,99,254,255,255

	.globl lj_vm_pcall
	.hidden lj_vm_pcall
	.type lj_vm_pcall, @function
	.size lj_vm_pcall, 14
lj_vm_pcall:
	.byte 85,87,86,83,131,236,28,190,5,0,0,0,235,12

	.globl lj_vm_call
	.hidden lj_vm_call
	.type lj_vm_call, @function
	.size lj_vm_call, 71
lj_vm_call:
	.byte 85,87,86,83,131,236,28,190,1,0,0,0,139,108,36,48
	.byte 139,76,36,52,139,125,40,137,124,36,52,137,108,36,24,137
	.byte 101,40,139,93,8,129,195,16,11,0,0,199,131,188,245,255
	.byte 255,255,255,255,255,139,85,16,1,206,41,214,139,69,20,41
	.byte 200,193,232,3,131,192,1

	.globl lj_vm_call_dispatch
	.hidden lj_vm_call_dispatch
	.type lj_vm_call_dispatch, @function
	.size lj_vm_call_dispatch, 13
lj_vm_call_dispatch:
	.byte 139,105,248,131,121,252,247,15,133,97,3,0,0

	.globl lj_vm_call_dispatch_f
	.hidden lj_vm_call_dispatch_f
	.type lj_vm_call_dispatch_f, @function
	.size lj_vm_call_dispatch_f, 22
lj_vm_call_dispatch_f:
	.byte 137,202,137,114,252,139,117,16,139,14,15,182,233,15,182,205
	.byte 131,198,4,255,36,171

	.globl lj_vm_cpcall
	.hidden lj_vm_cpcall
	.type lj_vm_cpcall, @function
	.size lj_vm_cpcall, 88
lj_vm_cpcall:
	.byte 85,87,86,83,131,236,28,139,108,36,48,139,68,36,56,139
	.byte 76,36,52,139,84,36,60,137,108,36,24,139,125,28,43,125
	.byte 20,199,68,36,60,0,0,0,0,137,124,36,56,137,68,36
	.byte 8,137,76,36,4,137,44,36,139,125,40,137,124,36,52,137
	.byte 101,40,255,210,133,192,15,132,238,253,255,255,137,193,190,5
	.byte 0,0,0,233,96,255,255,255

	.globl lj_cont_dispatch
	.hidden lj_cont_dispatch
	.type lj_cont_dispatch, @function
	.size lj_cont_dispatch, 60
lj_cont_dispatch:
	.byte 1,209,131,230,248,137,213,41,242,199,68,193,252,255,255,255
	.byte 255,137,200,139,117,244,139,77,240,131,249,1,118,11,139,122
	.byte 248,139,127,16,139,127,208,255,225,15,132,41,28,0,0,41
	.byte 213,193,237,3,141,69,255,233,89,20,0,0

	.globl lj_cont_cat
	.hidden lj_cont_cat
	.type lj_cont_cat, @function
	.size lj_cont_cat, 47
lj_cont_cat:
	.byte 15,182,78,255,131,237,16,141,12,202,41,233,15,132,140,0
	.byte 0,0,247,217,193,233,3,137,76,36,8,139,72,4,139,0
	.byte 137,77,4,137,69,0,137,108,36,4,233,193,237,255,255

	.globl lj_vmeta_tgets
	.hidden lj_vmeta_tgets
	.type lj_vmeta_tgets, @function
	.size lj_vmeta_tgets, 41
lj_vmeta_tgets:
	.byte 137,68,36,16,199,68,36,20,251,255,255,255,141,68,36,16
	.byte 128,126,252,52,117,48,141,139,128,245,255,255,137,41,199,65
	.byte 4,244,255,255,255,137,205,235,36

	.globl lj_vmeta_tgetb
	.hidden lj_vmeta_tgetb
	.type lj_vmeta_tgetb, @function
	.size lj_vmeta_tgetb, 22
lj_vmeta_tgetb:
	.byte 15,182,70,254,137,68,36,12,219,68,36,12,221,92,36,16
	.byte 141,68,36,16,235,7

	.globl lj_vmeta_tgetv
	.hidden lj_vmeta_tgetv
	.type lj_vmeta_tgetv, @function
	.size lj_vmeta_tgetv, 48
lj_vmeta_tgetv:
	.byte 15,182,70,254,141,4,194,15,182,110,255,141,44,234,137,108
	.byte 36,4,139,108,36,48,137,68,36,8,137,44,36,137,85,16
	.byte 137,116,36,24,232
	.long lj_meta_tget-.-4
	.byte 139,85,16,133,192,116,33

	.globl lj_cont_ra
	.hidden lj_cont_ra
	.type lj_cont_ra, @function
	.size lj_cont_ra, 57
lj_cont_ra:
	.byte 15,182,78,253,139,104,4,139,0,137,108,202,4,137,4,202
	.byte 139,6,15,182,204,15,182,232,131,198,4,193,232,16,255,36
	.byte 171,139,77,20,137,113,244,141,113,2,41,214,139,105,248,184
	.byte 3,0,0,0,233,127,254,255,255

	.globl lj_vmeta_tsets
	.hidden lj_vmeta_tsets
	.type lj_vmeta_tsets, @function
	.size lj_vmeta_tsets, 41
lj_vmeta_tsets:
	.byte 137,68,36,16,199,68,36,20,251,255,255,255,141,68,36,16
	.byte 128,126,252,53,117,48,141,139,128,245,255,255,137,41,199,65
	.byte 4,244,255,255,255,137,205,235,36

	.globl lj_vmeta_tsetb
	.hidden lj_vmeta_tsetb
	.type lj_vmeta_tsetb, @function
	.size lj_vmeta_tsetb, 22
lj_vmeta_tsetb:
	.byte 15,182,70,254,137,68,36,12,219,68,36,12,221,92,36,16
	.byte 141,68,36,16,235,7

	.globl lj_vmeta_tsetv
	.hidden lj_vmeta_tsetv
	.type lj_vmeta_tsetv, @function
	.size lj_vmeta_tsetv, 64
lj_vmeta_tsetv:
	.byte 15,182,70,254,141,4,194,15,182,110,255,141,44,234,137,108
	.byte 36,4,139,108,36,48,137,68,36,8,137,44,36,137,85,16
	.byte 137,116,36,24,232
	.long lj_meta_tset-.-4
	.byte 139,85,16,133,192,116,33,15,182,78,253,139,108,202,4,139
	.byte 12,202,137,104,4,137,8

	.globl lj_cont_nop
	.hidden lj_cont_nop
	.type lj_cont_nop, @function
	.size lj_cont_nop, 58
lj_cont_nop:
	.byte 139,6,15,182,204,15,182,232,131,198,4,193,232,16,255,36
	.byte 171,139,77,20,137,113,244,15,182,70,253,139,108,194,4,139
	.byte 4,194,137,105,20,137,65,16,141,113,2,41,214,139,105,248
	.byte 184,4,0,0,0,233,198,253,255,255

	.globl lj_vmeta_comp
	.hidden lj_vmeta_comp
	.type lj_vmeta_comp, @function
	.size lj_vmeta_comp, 86
lj_vmeta_comp:
	.byte 15,182,110,252,141,4,194,141,12,202,137,108,36,12,139,108
	.byte 36,48,137,68,36,8,137,76,36,4,137,44,36,137,85,16
	.byte 137,116,36,24,232
	.long lj_meta_comp-.-4
	.byte 139,85,16,131,248,1,15,135,192,0,0,0,141,118,4,114
	.byte 11,15,183,70,254,141,180,134,0,0,254,255,139,6,15,182
	.byte 204,15,182,232,131,198,4,193,232,16,255,36,171

	.globl lj_cont_condt
	.hidden lj_cont_condt
	.type lj_cont_condt, @function
	.size lj_cont_condt, 11
lj_cont_condt:
	.byte 131,198,4,131,120,4,254,114,219,235,228

	.globl lj_cont_condf
	.hidden lj_cont_condf
	.type lj_cont_condf, @function
	.size lj_cont_condf, 6
lj_cont_condf:
	.byte 131,120,4,254,235,206

	.globl lj_vmeta_equal
	.hidden lj_vmeta_equal
	.type lj_vmeta_equal, @function
	.size lj_vmeta_equal, 36
lj_vmeta_equal:
	.byte 131,238,4,137,108,36,12,139,108,36,48,137,68,36,8,137
	.byte 76,36,4,137,44,36,137,85,16,137,116,36,24,232
	.long lj_meta_equal-.-4
	.byte 235,158

	.globl lj_vmeta_equal_cd
	.hidden lj_vmeta_equal_cd
	.type lj_vmeta_equal_cd, @function
	.size lj_vmeta_equal_cd, 26
lj_vmeta_equal_cd:
	.byte 131,238,4,139,108,36,48,137,85,16,137,233,139,86,252,137
	.byte 116,36,24,232
	.long lj_meta_equal_cd-.-4
	.byte 235,132

	.globl lj_vmeta_arith_vno
	.hidden lj_vmeta_arith_vno
	.type lj_vmeta_arith_vno, @function
	.size lj_vmeta_arith_vno, 0
lj_vmeta_arith_vno:

	.globl lj_vmeta_arith_vn
	.hidden lj_vmeta_arith_vn
	.type lj_vmeta_arith_vn, @function
	.size lj_vmeta_arith_vn, 5
lj_vmeta_arith_vn:
	.byte 141,4,199,235,19

	.globl lj_vmeta_arith_nvo
	.hidden lj_vmeta_arith_nvo
	.type lj_vmeta_arith_nvo, @function
	.size lj_vmeta_arith_nvo, 0
lj_vmeta_arith_nvo:

	.globl lj_vmeta_arith_nv
	.hidden lj_vmeta_arith_nv
	.type lj_vmeta_arith_nv, @function
	.size lj_vmeta_arith_nv, 9
lj_vmeta_arith_nv:
	.byte 141,4,199,141,44,234,149,235,13

	.globl lj_vmeta_unm
	.hidden lj_vmeta_unm
	.type lj_vmeta_unm, @function
	.size lj_vmeta_unm, 7
lj_vmeta_unm:
	.byte 141,4,194,137,197,235,6

	.globl lj_vmeta_arith_vvo
	.hidden lj_vmeta_arith_vvo
	.type lj_vmeta_arith_vvo, @function
	.size lj_vmeta_arith_vvo, 0
lj_vmeta_arith_vvo:

	.globl lj_vmeta_arith_vv
	.hidden lj_vmeta_arith_vv
	.type lj_vmeta_arith_vv, @function
	.size lj_vmeta_arith_vv, 59
lj_vmeta_arith_vv:
	.byte 141,4,194,141,44,234,141,12,202,137,108,36,8,139,108,36
	.byte 48,137,68,36,12,15,182,70,252,137,76,36,4,137,68,36
	.byte 16,137,44,36,137,85,16,137,116,36,24,232
	.long lj_meta_arith-.-4
	.byte 139,85,16,133,192,15,132,209,254,255,255

	.globl lj_vmeta_binop
	.hidden lj_vmeta_binop
	.type lj_vmeta_binop, @function
	.size lj_vmeta_binop, 20
lj_vmeta_binop:
	.byte 137,193,41,208,137,113,244,141,112,2,184,3,0,0,0,233
	.byte 176,252,255,255

	.globl lj_vmeta_len
	.hidden lj_vmeta_len
	.type lj_vmeta_len, @function
	.size lj_vmeta_len, 26
lj_vmeta_len:
	.byte 139,108,36,48,137,85,16,141,20,194,137,233,137,116,36,24
	.byte 232
	.long lj_meta_len-.-4
	.byte 139,85,16,235,210

	.globl lj_vmeta_call_ra
	.hidden lj_vmeta_call_ra
	.type lj_vmeta_call_ra, @function
	.size lj_vmeta_call_ra, 4
lj_vmeta_call_ra:
	.byte 141,76,202,8

	.globl lj_vmeta_call
	.hidden lj_vmeta_call
	.type lj_vmeta_call, @function
	.size lj_vmeta_call, 88
lj_vmeta_call:
	.byte 137,76,36,20,137,68,36,16,131,233,8,141,4,193,139,108
	.byte 36,48,137,76,36,4,137,68,36,8,137,44,36,137,85,16
	.byte 137,116,36,24,232
	.long lj_meta_call-.-4
	.byte 139,85,16,139,76,36,20,139,68,36,16,139,105,248,131,192
	.byte 1,57,215,15,132,226,242,255,255,137,202,137,114,252,139,117
	.byte 16,139,14,15,182,233,15,182,205,131,198,4,255,36,171

	.globl lj_vmeta_for
	.hidden lj_vmeta_for
	.type lj_vmeta_for, @function
	.size lj_vmeta_for, 42
lj_vmeta_for:
	.byte 139,108,36,48,137,85,16,137,202,137,233,137,116,36,24,232
	.long lj_meta_for-.-4
	.byte 139,85,16,139,70,252,15,182,204,15,182,232,193,232,16,255
	.byte 164,171,108,2,0,0

	.globl lj_ff_assert
	.hidden lj_ff_assert
	.type lj_ff_assert, @function
	.size lj_ff_assert, 71
lj_ff_assert:
	.byte 131,248,2,15,130,192,16,0,0,139,106,4,131,253,254,15
	.byte 131,180,16,0,0,139,114,252,137,68,36,20,137,106,252,139
	.byte 42,137,106,248,131,232,2,116,21,137,209,131,193,8,139,105
	.byte 4,137,105,252,139,41,137,105,248,131,232,1,117,237,139,68
	.byte 36,20,233,37,6,0,0

	.globl lj_ff_type
	.hidden lj_ff_type
	.type lj_ff_type, @function
	.size lj_ff_type, 49
lj_ff_type:
	.byte 131,248,2,15,130,121,16,0,0,139,106,4,184,13,0,0
	.byte 0,247,213,57,232,15,71,197,139,106,248,139,68,197,24,139
	.byte 114,252,199,66,252,251,255,255,255,137,66,248,233,235,5,0
	.byte 0

	.globl lj_ff_getmetatable
	.hidden lj_ff_getmetatable
	.type lj_ff_getmetatable, @function
	.size lj_ff_getmetatable, 142
lj_ff_getmetatable:
	.byte 131,248,2,15,130,72,16,0,0,139,106,4,139,114,252,131
	.byte 253,244,117,96,139,42,139,109,16,133,237,199,66,252,255,255
	.byte 255,255,15,132,195,5,0,0,139,131,24,246,255,255,199,66
	.byte 252,244,255,255,255,137,106,248,139,77,28,35,72,8,107,201
	.byte 24,3,77,20,131,121,12,251,117,5,57,65,8,116,12,139
	.byte 73,16,133,201,117,238,233,144,5,0,0,139,105,4,131,253
	.byte 255,15,132,132,5,0,0,139,1,137,106,252,137,66,248,233
	.byte 119,5,0,0,131,253,243,116,155,131,253,242,119,5,189,242
	.byte 255,255,255,247,213,139,172,171,44,246,255,255,235,139

	.globl lj_ff_setmetatable
	.hidden lj_ff_setmetatable
	.type lj_ff_setmetatable, @function
	.size lj_ff_setmetatable, 90
lj_ff_setmetatable:
	.byte 131,248,3,15,130,186,15,0,0,131,122,4,244,15,133,176
	.byte 15,0,0,139,42,131,125,16,0,15,133,164,15,0,0,131
	.byte 122,12,244,15,133,154,15,0,0,139,66,8,137,69,16,139
	.byte 114,252,199,66,252,244,255,255,255,137,106,248,246,69,4,4
	.byte 116,19,128,101,4,251,139,131,32,245,255,255,137,171,32,245
	.byte 255,255,137,69,12,233,3,5,0,0

	.globl lj_ff_rawget
	.hidden lj_ff_rawget
	.type lj_ff_rawget, @function
	.size lj_ff_rawget, 67
lj_ff_rawget:
	.byte 131,248,3,15,130,96,15,0,0,131,122,4,244,15,133,86
	.byte 15,0,0,139,2,139,108,36,48,137,68,36,4,137,44,36
	.byte 137,213,131,194,8,137,84,36,8,232
	.long lj_tab_get-.-4
	.byte 137,234,139,40,139,64,4,139,114,252,137,106,248,137,66,252
	.byte 233,192,4,0,0

	.globl lj_ff_tonumber
	.hidden lj_ff_tonumber
	.type lj_ff_tonumber, @function
	.size lj_ff_tonumber, 26
lj_ff_tonumber:
	.byte 131,248,2,15,133,29,15,0,0,131,122,4,242,15,131,19
	.byte 15,0,0,221,2,233,160,4,0,0

	.globl lj_ff_tostring
	.hidden lj_ff_tostring
	.type lj_ff_tostring, @function
	.size lj_ff_tostring, 100
lj_ff_tostring:
	.byte 131,248,2,15,130,3,15,0,0,139,114,252,131,122,4,251
	.byte 117,17,139,2,199,66,252,251,255,255,255,137,66,248,233,131
	.byte 4,0,0,131,122,4,242,15,135,223,14,0,0,131,187,96
	.byte 246,255,255,0,15,133,210,14,0,0,139,171,4,245,255,255
	.byte 59,171,8,245,255,255,114,5,232,77,15,0,0,139,108,36
	.byte 48,137,85,16,137,116,36,24,137,233,232
	.long lj_str_fromnum-.-4
	.byte 139,85,16,235,176

	.globl lj_ff_next
	.hidden lj_ff_next
	.type lj_ff_next, @function
	.size lj_ff_next, 89
lj_ff_next:
	.byte 131,248,2,15,130,159,14,0,0,116,88,131,122,4,244,15
	.byte 133,147,14,0,0,139,108,36,48,137,85,16,137,85,20,139
	.byte 114,252,139,2,137,68,36,4,137,44,36,131,194,8,137,84
	.byte 36,8,137,116,36,24,232
	.long lj_tab_next-.-4
	.byte 139,85,16,133,192,116,42,139,106,8,139,66,12,137,106,248
	.byte 137,66,252,139,106,16,139,66,20,137,42,137,66,4

	.globl lj_fff_res2
	.hidden lj_fff_res2
	.type lj_fff_res2, @function
	.size lj_fff_res2, 31
lj_fff_res2:
	.byte 184,3,0,0,0,233,228,3,0,0,199,66,12,255,255,255
	.byte 255,235,159,199,66,252,255,255,255,255,233,202,3,0,0

	.globl lj_ff_pairs
	.hidden lj_ff_pairs
	.type lj_ff_pairs, @function
	.size lj_ff_pairs, 57
lj_ff_pairs:
	.byte 131,248,2,15,130,39,14,0,0,139,42,131,122,4,244,15
	.byte 133,27,14,0,0,139,106,248,139,69,24,139,114,252,199,66
	.byte 252,247,255,255,255,137,66,248,199,66,12,255,255,255,255,184
	.byte 4,0,0,0,233,150,3,0,0

	.globl lj_ff_ipairs_aux
	.hidden lj_ff_ipairs_aux
	.type lj_ff_ipairs_aux, @function
	.size lj_ff_ipairs_aux, 105
lj_ff_ipairs_aux:
	.byte 131,248,3,15,130,238,13,0,0,131,122,4,244,15,133,228
	.byte 13,0,0,131,122,12,242,15,131,218,13,0,0,139,114,252
	.byte 221,66,8,217,232,222,193,219,20,36,221,90,248,139,4,36
	.byte 139,42,59,69,24,115,27,193,224,3,3,69,8,131,120,4
	.byte 255,116,38,139,40,139,64,4,137,42,137,66,4,233,86,255
	.byte 255,255,131,125,28,0,116,17,137,233,137,213,137,194,232
	.long lj_tab_getinth-.-4
	.byte 137,234,133,192,117,212

	.globl lj_fff_res0
	.hidden lj_fff_res0
	.type lj_fff_res0, @function
	.size lj_fff_res0, 10
lj_fff_res0:
	.byte 184,1,0,0,0,233,35,3,0,0

	.globl lj_ff_ipairs
	.hidden lj_ff_ipairs
	.type lj_ff_ipairs, @function
	.size lj_ff_ipairs, 55
lj_ff_ipairs:
	.byte 131,248,2,15,130,123,13,0,0,139,42,131,122,4,244,15
	.byte 133,111,13,0,0,139,106,248,139,69,24,139,114,252,199,66
	.byte 252,247,255,255,255,137,66,248,217,238,221,90,8,184,4,0
	.byte 0,0,233,236,2,0,0

	.globl lj_ff_pcall
	.hidden lj_ff_pcall
	.type lj_ff_pcall, @function
	.size lj_ff_pcall, 40
lj_ff_pcall:
	.byte 131,248,2,15,130,68,13,0,0,141,74,8,131,232,1,190
	.byte 14,0,0,0,15,182,171,113,245,255,255,193,237,4,131,229
	.byte 1,1,238,233,108,248,255,255

	.globl lj_ff_xpcall
	.hidden lj_ff_xpcall
	.type lj_ff_xpcall, @function
	.size lj_ff_xpcall, 55
lj_ff_xpcall:
	.byte 131,248,3,15,130,28,13,0,0,131,122,12,247,15,133,18
	.byte 13,0,0,139,106,4,137,106,12,199,66,4,247,255,255,255
	.byte 139,42,139,114,8,137,106,8,137,50,141,74,16,131,232,2
	.byte 190,22,0,0,0,235,181

	.globl lj_ff_coroutine_resume
	.hidden lj_ff_coroutine_resume
	.type lj_ff_coroutine_resume, @function
	.size lj_ff_coroutine_resume, 316
lj_ff_coroutine_resume:
	.byte 131,248,2,15,130,229,12,0,0,139,42,139,114,252,137,116
	.byte 36,24,137,44,36,131,122,4,249,15,133,207,12,0,0,131
	.byte 125,40,0,15,133,197,12,0,0,128,125,7,1,15,135,187
	.byte 12,0,0,139,77,20,116,9,59,77,16,15,132,173,12,0
	.byte 0,141,116,193,240,59,117,24,15,135,160,12,0,0,137,117
	.byte 20,139,108,36,48,137,85,16,131,194,8,137,85,20,141,108
	.byte 194,232,41,245,57,206,116,20,139,68,46,4,137,70,252,139
	.byte 4,46,137,70,248,131,238,8,57,206,117,236,137,76,36,4
	.byte 49,201,137,76,36,12,137,76,36,8,232,233,246,255,255,199
	.byte 131,188,245,255,255,255,255,255,255,139,108,36,48,139,52,36
	.byte 139,85,16,131,248,1,119,89,139,78,16,139,126,20,137,78
	.byte 20,137,254,41,206,116,34,141,4,50,193,238,3,59,69,24
	.byte 119,96,137,213,41,205,139,1,137,4,41,139,65,4,137,68
	.byte 41,4,131,193,8,57,249,117,237,141,70,2,199,66,252,253
	.byte 255,255,255,139,116,36,24,137,68,36,20,185,248,255,255,255
	.byte 247,198,3,0,0,0,15,132,102,240,255,255,233,66,245,255
	.byte 255,199,66,252,254,255,255,255,139,78,20,131,233,8,137,78
	.byte 20,139,1,137,2,139,65,4,137,66,4,184,3,0,0,0
	.byte 235,193,139,12,36,137,121,20,137,242,137,233,232
	.long lj_state_growstack-.-4
	.byte 139,52,36,139,85,16,233,108,255,255,255

	.globl lj_ff_coroutine_wrap_aux
	.hidden lj_ff_coroutine_wrap_aux
	.type lj_ff_coroutine_wrap_aux, @function
	.size lj_ff_coroutine_wrap_aux, 261
lj_ff_coroutine_wrap_aux:
	.byte 139,106,248,139,109,24,139,114,252,137,116,36,24,137,44,36
	.byte 131,125,40,0,15,133,152,11,0,0,128,125,7,1,15,135
	.byte 142,11,0,0,139,77,20,116,9,59,77,16,15,132,128,11
	.byte 0,0,141,116,193,248,59,117,24,15,135,115,11,0,0,137
	.byte 117,20,139,108,36,48,137,85,16,137,85,20,141,108,194,240
	.byte 41,245,57,206,116,20,139,68,46,4,137,70,252,139,4,46
	.byte 137,70,248,131,238,8,57,206,117,236,137,76,36,4,49,201
	.byte 137,76,36,12,137,76,36,8,232,191,245,255,255,199,131,188
	.byte 245,255,255,255,255,255,255,139,108,36,48,139,52,36,139,85
	.byte 16,131,248,1,119,79,139,78,16,139,126,20,137,78,20,137
	.byte 254,41,206,116,34,141,4,50,193,238,3,59,69,24,119,62
	.byte 137,213,41,205,139,1,137,4,41,139,65,4,137,68,41,4
	.byte 131,193,8,57,249,117,237,141,70,1,139,116,36,24,137,68
	.byte 36,20,49,201,247,198,3,0,0,0,15,132,70,239,255,255
	.byte 233,34,244,255,255,137,242,137,233,232
	.long lj_ffh_coroutine_wrap_err-.-4
	.byte 139,12,36,137,121,20,137,242,137,233,232
	.long lj_state_growstack-.-4
	.byte 139,52,36,139,85,16,235,145

	.globl lj_ff_coroutine_yield
	.hidden lj_ff_coroutine_yield
	.type lj_ff_coroutine_yield, @function
	.size lj_ff_coroutine_yield, 42
lj_ff_coroutine_yield:
	.byte 139,108,36,48,247,69,40,1,0,0,0,15,132,156,10,0
	.byte 0,137,85,16,141,68,194,248,137,69,20,49,192,137,69,40
	.byte 176,1,136,69,7,233,48,244,255,255

	.globl lj_fff_resi
	.hidden lj_fff_resi
	.type lj_fff_resi, @function
	.size lj_fff_resi, 0
lj_fff_resi:

	.globl lj_ff_math_abs
	.hidden lj_ff_math_abs
	.type lj_ff_math_abs, @function
	.size lj_ff_math_abs, 23
lj_ff_math_abs:
	.byte 131,248,2,15,130,122,10,0,0,131,122,4,242,15,131,112
	.byte 10,0,0,221,2,217,225

	.globl lj_fff_resn
	.hidden lj_fff_resn
	.type lj_fff_resn, @function
	.size lj_fff_resn, 0
lj_fff_resn:

	.globl lj_fff_resxmm0
	.hidden lj_fff_resxmm0
	.type lj_fff_resxmm0, @function
	.size lj_fff_resxmm0, 6
lj_fff_resxmm0:
	.byte 139,114,252,221,90,248

	.globl lj_fff_res1
	.hidden lj_fff_res1
	.type lj_fff_res1, @function
	.size lj_fff_res1, 5
lj_fff_res1:
	.byte 184,2,0,0,0

	.globl lj_fff_res
	.hidden lj_fff_res
	.type lj_fff_res, @function
	.size lj_fff_res, 4
lj_fff_res:
	.byte 137,68,36,20

	.globl lj_fff_res_
	.hidden lj_fff_res_
	.type lj_fff_res_, @function
	.size lj_fff_res_, 62
lj_fff_res_:
	.byte 247,198,3,0,0,0,117,44,56,70,255,119,26,15,182,78
	.byte 253,247,209,141,20,202,139,6,15,182,204,15,182,232,131,198
	.byte 4,193,232,16,255,36,171,199,68,194,244,255,255,255,255,131
	.byte 192,1,235,212,185,248,255,255,255,233,116,243,255,255

	.globl lj_ff_math_floor
	.hidden lj_ff_math_floor
	.type lj_ff_math_floor, @function
	.size lj_ff_math_floor, 19
lj_ff_math_floor:
	.byte 131,122,4,242,15,131,21,10,0,0,221,2,232,164,12,0
	.byte 0,235,160

	.globl lj_ff_math_ceil
	.hidden lj_ff_math_ceil
	.type lj_ff_math_ceil, @function
	.size lj_ff_math_ceil, 19
lj_ff_math_ceil:
	.byte 131,122,4,242,15,131,2,10,0,0,221,2,232,17,13,0
	.byte 0,235,141

	.globl lj_ff_math_sqrt
	.hidden lj_ff_math_sqrt
	.type lj_ff_math_sqrt, @function
	.size lj_ff_math_sqrt, 28
lj_ff_math_sqrt:
	.byte 131,248,2,15,130,240,9,0,0,131,122,4,242,15,131,230
	.byte 9,0,0,221,2,217,250,233,113,255,255,255

	.globl lj_ff_math_log
	.hidden lj_ff_math_log
	.type lj_ff_math_log, @function
	.size lj_ff_math_log, 30
lj_ff_math_log:
	.byte 131,248,2,15,133,212,9,0,0,131,122,4,242,15,131,202
	.byte 9,0,0,217,237,221,2,217,241,233,83,255,255,255

	.globl lj_ff_math_log10
	.hidden lj_ff_math_log10
	.type lj_ff_math_log10, @function
	.size lj_ff_math_log10, 30
lj_ff_math_log10:
	.byte 131,248,2,15,130,182,9,0,0,131,122,4,242,15,131,172
	.byte 9,0,0,217,236,221,2,217,241,233,53,255,255,255

	.globl lj_ff_math_exp
	.hidden lj_ff_math_exp
	.type lj_ff_math_exp, @function
	.size lj_ff_math_exp, 31
lj_ff_math_exp:
	.byte 131,248,2,15,130,152,9,0,0,131,122,4,242,15,131,142
	.byte 9,0,0,221,2,232,206,13,0,0,233,22,255,255,255

	.globl lj_ff_math_sin
	.hidden lj_ff_math_sin
	.type lj_ff_math_sin, @function
	.size lj_ff_math_sin, 28
lj_ff_math_sin:
	.byte 131,248,2,15,130,121,9,0,0,131,122,4,242,15,131,111
	.byte 9,0,0,221,2,217,254,233,250,254,255,255

	.globl lj_ff_math_cos
	.hidden lj_ff_math_cos
	.type lj_ff_math_cos, @function
	.size lj_ff_math_cos, 28
lj_ff_math_cos:
	.byte 131,248,2,15,130,93,9,0,0,131,122,4,242,15,131,83
	.byte 9,0,0,221,2,217,255,233,222,254,255,255

	.globl lj_ff_math_tan
	.hidden lj_ff_math_tan
	.type lj_ff_math_tan, @function
	.size lj_ff_math_tan, 30
lj_ff_math_tan:
	.byte 131,248,2,15,130,65,9,0,0,131,122,4,242,15,131,55
	.byte 9,0,0,221,2,217,242,221,216,233,192,254,255,255

	.globl lj_ff_math_asin
	.hidden lj_ff_math_asin
	.type lj_ff_math_asin, @function
	.size lj_ff_math_asin, 38
lj_ff_math_asin:
	.byte 131,248,2,15,130,35,9,0,0,131,122,4,242,15,131,25
	.byte 9,0,0,221,2,217,192,216,200,217,232,222,225,217,250,217
	.byte 243,233,154,254,255,255

	.globl lj_ff_math_acos
	.hidden lj_ff_math_acos
	.type lj_ff_math_acos, @function
	.size lj_ff_math_acos, 40
lj_ff_math_acos:
	.byte 131,248,2,15,130,253,8,0,0,131,122,4,242,15,131,243
	.byte 8,0,0,221,2,217,192,216,200,217,232,222,225,217,250,217
	.byte 201,217,243,233,114,254,255,255

	.globl lj_ff_math_atan
	.hidden lj_ff_math_atan
	.type lj_ff_math_atan, @function
	.size lj_ff_math_atan, 30
lj_ff_math_atan:
	.byte 131,248,2,15,130,213,8,0,0,131,122,4,242,15,131,203
	.byte 8,0,0,221,2,217,232,217,243,233,84,254,255,255

	.globl lj_ff_math_sinh
	.hidden lj_ff_math_sinh
	.type lj_ff_math_sinh, @function
	.size lj_ff_math_sinh, 38
lj_ff_math_sinh:
	.byte 131,248,2,15,130,183,8,0,0,131,122,4,242,15,131,173
	.byte 8,0,0,221,2,221,28,36,137,213,232
	.long lj_vm_sinh-.-4
	.byte 137,234,233,46,254,255,255

	.globl lj_ff_math_cosh
	.hidden lj_ff_math_cosh
	.type lj_ff_math_cosh, @function
	.size lj_ff_math_cosh, 38
lj_ff_math_cosh:
	.byte 131,248,2,15,130,145,8,0,0,131,122,4,242,15,131,135
	.byte 8,0,0,221,2,221,28,36,137,213,232
	.long lj_vm_cosh-.-4
	.byte 137,234,233,8,254,255,255

	.globl lj_ff_math_tanh
	.hidden lj_ff_math_tanh
	.type lj_ff_math_tanh, @function
	.size lj_ff_math_tanh, 38
lj_ff_math_tanh:
	.byte 131,248,2,15,130,107,8,0,0,131,122,4,242,15,131,97
	.byte 8,0,0,221,2,221,28,36,137,213,232
	.long lj_vm_tanh-.-4
	.byte 137,234,233,226,253,255,255

	.globl lj_ff_math_deg
	.hidden lj_ff_math_deg
	.type lj_ff_math_deg, @function
	.size lj_ff_math_deg, 0
lj_ff_math_deg:

	.globl lj_ff_math_rad
	.hidden lj_ff_math_rad
	.type lj_ff_math_rad, @function
	.size lj_ff_math_rad, 32
lj_ff_math_rad:
	.byte 131,248,2,15,130,69,8,0,0,131,122,4,242,15,131,59
	.byte 8,0,0,221,2,139,106,248,220,77,24,233,194,253,255,255

	.globl lj_ff_math_atan2
	.hidden lj_ff_math_atan2
	.type lj_ff_math_atan2, @function
	.size lj_ff_math_atan2, 41
lj_ff_math_atan2:
	.byte 131,248,3,15,130,37,8,0,0,131,122,4,242,15,131,27
	.byte 8,0,0,131,122,12,242,15,131,17,8,0,0,221,2,221
	.byte 66,8,217,243,233,153,253,255,255

	.globl lj_ff_math_ldexp
	.hidden lj_ff_math_ldexp
	.type lj_ff_math_ldexp, @function
	.size lj_ff_math_ldexp, 43
lj_ff_math_ldexp:
	.byte 131,248,3,15,130,252,7,0,0,131,122,4,242,15,131,242
	.byte 7,0,0,131,122,12,242,15,131,232,7,0,0,221,66,8
	.byte 221,2,217,253,221,217,233,110,253,255,255

	.globl lj_ff_math_frexp
	.hidden lj_ff_math_frexp
	.type lj_ff_math_frexp, @function
	.size lj_ff_math_frexp, 135
lj_ff_math_frexp:
	.byte 131,248,2,15,130,209,7,0,0,139,106,4,131,253,242,15
	.byte 131,197,7,0,0,139,114,252,139,2,137,106,252,137,66,248
	.byte 209,229,129,253,0,0,224,255,115,60,9,232,116,56,184,254
	.byte 3,0,0,129,253,0,0,32,0,114,47,193,237,21,41,197
	.byte 137,108,36,16,219,68,36,16,139,106,252,129,229,255,255,15
	.byte 128,129,205,0,0,224,63,137,106,252,221,26,184,3,0,0
	.byte 0,233,19,253,255,255,217,238,235,240,221,2,199,68,36,16
	.byte 0,0,128,90,216,76,36,16,221,90,248,139,106,252,184,52
	.byte 4,0,0,209,229,235,180

	.globl lj_ff_math_modf
	.hidden lj_ff_math_modf
	.type lj_ff_math_modf, @function
	.size lj_ff_math_modf, 88
lj_ff_math_modf:
	.byte 131,248,2,15,130,74,7,0,0,131,122,4,242,15,131,64
	.byte 7,0,0,221,2,139,106,4,139,114,252,209,229,129,253,0
	.byte 0,224,255,116,45,217,192,232,189,10,0,0,220,233,221,90
	.byte 248,221,26,139,66,252,139,106,4,49,232,120,10,184,3,0
	.byte 0,0,233,171,252,255,255,129,245,0,0,0,128,137,106,4
	.byte 235,235,217,238,217,201,235,214

	.globl lj_ff_math_fmod
	.hidden lj_ff_math_fmod
	.type lj_ff_math_fmod, @function
	.size lj_ff_math_fmod, 51
lj_ff_math_fmod:
	.byte 131,248,3,15,130,242,6,0,0,131,122,4,242,15,131,232
	.byte 6,0,0,131,122,12,242,15,131,222,6,0,0,221,66,8
	.byte 221,2,217,248,223,224,102,37,0,4,117,246,221,217,233,92
	.byte 252,255,255

	.globl lj_ff_math_pow
	.hidden lj_ff_math_pow
	.type lj_ff_math_pow, @function
	.size lj_ff_math_pow, 44
lj_ff_math_pow:
	.byte 131,248,3,15,130,191,6,0,0,131,122,4,242,15,131,181
	.byte 6,0,0,131,122,12,242,15,131,171,6,0,0,221,2,221
	.byte 66,8,232,28,11,0,0,233,48,252,255,255

	.globl lj_ff_math_min
	.hidden lj_ff_math_min
	.type lj_ff_math_min, @function
	.size lj_ff_math_min, 47
lj_ff_math_min:
	.byte 185,2,0,0,0,131,122,4,242,15,131,141,6,0,0,221
	.byte 2,57,193,15,131,23,252,255,255,131,124,202,252,242,115,62
	.byte 221,68,202,248,219,233,219,209,221,217,131,193,1,235,226

	.globl lj_ff_math_max
	.hidden lj_ff_math_max
	.type lj_ff_math_max, @function
	.size lj_ff_math_max, 54
lj_ff_math_max:
	.byte 185,2,0,0,0,131,122,4,242,15,131,94,6,0,0,221
	.byte 2,57,193,15,131,232,251,255,255,131,124,202,252,242,115,15
	.byte 221,68,202,248,219,233,218,209,221,217,131,193,1,235,226,221
	.byte 216,233,55,6,0,0

	.globl lj_ff_string_len
	.hidden lj_ff_string_len
	.type lj_ff_string_len, @function
	.size lj_ff_string_len, 29
lj_ff_string_len:
	.byte 131,248,2,15,130,46,6,0,0,131,122,4,251,15,133,36
	.byte 6,0,0,139,42,219,69,12,233,174,251,255,255

	.globl lj_ff_string_byte
	.hidden lj_ff_string_byte
	.type lj_ff_string_byte, @function
	.size lj_ff_string_byte, 51
lj_ff_string_byte:
	.byte 131,248,2,15,133,17,6,0,0,131,122,4,251,15,133,7
	.byte 6,0,0,139,42,139,114,252,131,125,12,1,15,130,106,248
	.byte 255,255,15,182,109,16,137,108,36,16,219,68,36,16,233,123
	.byte 251,255,255

	.globl lj_ff_string_char
	.hidden lj_ff_string_char
	.type lj_ff_string_char, @function
	.size lj_ff_string_char, 70
lj_ff_string_char:
	.byte 139,171,4,245,255,255,59,171,8,245,255,255,114,5,232,98
	.byte 6,0,0,131,248,2,15,133,203,5,0,0,131,122,4,242
	.byte 15,131,193,5,0,0,221,2,219,92,36,20,129,124,36,20
	.byte 255,0,0,0,15,135,173,5,0,0,199,68,36,8,1,0
	.byte 0,0,141,68,36,20

	.globl lj_fff_newstr
	.hidden lj_fff_newstr
	.type lj_fff_newstr, @function
	.size lj_fff_newstr, 44
lj_fff_newstr:
	.byte 139,108,36,48,137,85,16,137,68,36,4,137,44,36,137,116
	.byte 36,24,232
	.long lj_str_new-.-4
	.byte 139,85,16,139,114,252,199,66,252,251,255,255,255,137,66,248
	.byte 233,15,251,255,255

	.globl lj_ff_string_sub
	.hidden lj_ff_string_sub
	.type lj_ff_string_sub, @function
	.size lj_ff_string_sub, 161
lj_ff_string_sub:
	.byte 139,171,4,245,255,255,59,171,8,245,255,255,114,5,232,240
	.byte 5,0,0,199,68,36,20,255,255,255,255,131,248,3,15,130
	.byte 81,5,0,0,118,17,131,122,20,242,15,131,69,5,0,0
	.byte 221,66,16,219,92,36,20,131,122,4,251,15,133,52,5,0
	.byte 0,131,122,12,242,15,131,42,5,0,0,139,42,137,108,36
	.byte 12,139,109,12,221,66,8,219,92,36,8,139,76,36,8,139
	.byte 68,36,20,57,197,114,30,133,201,126,38,139,108,36,12,41
	.byte 200,124,46,141,108,13,15,131,192,1,137,68,36,8,137,232
	.byte 233,79,255,255,255,124,6,141,68,40,1,235,218,137,232,235
	.byte 214,116,7,1,233,131,193,1,127,209,185,1,0,0,0,235
	.byte 202

	.globl lj_fff_emptystr
	.hidden lj_fff_emptystr
	.type lj_fff_emptystr, @function
	.size lj_fff_emptystr, 4
lj_fff_emptystr:
	.byte 49,192,235,213

	.globl lj_ff_string_rep
	.hidden lj_ff_string_rep
	.type lj_ff_string_rep, @function
	.size lj_ff_string_rep, 125
lj_ff_string_rep:
	.byte 139,171,4,245,255,255,59,171,8,245,255,255,114,5,232,75
	.byte 5,0,0,131,248,3,15,133,180,4,0,0,131,122,4,251
	.byte 15,133,170,4,0,0,131,122,12,242,139,42,15,131,158,4
	.byte 0,0,221,66,8,219,92,36,20,139,68,36,20,133,192,126
	.byte 187,131,125,12,1,114,181,15,133,119,4,0,0,57,131,68
	.byte 245,255,255,15,130,107,4,0,0,15,182,77,16,139,171,60
	.byte 245,255,255,137,68,36,8,136,77,0,131,197,1,131,232,1
	.byte 117,245,139,131,60,245,255,255,233,178,254,255,255

	.globl lj_ff_string_reverse
	.hidden lj_ff_string_reverse
	.type lj_ff_string_reverse, @function
	.size lj_ff_string_reverse, 106
lj_ff_string_reverse:
	.byte 131,248,2,15,130,74,4,0,0,139,171,4,245,255,255,59
	.byte 171,8,245,255,255,114,5,232,197,4,0,0,131,122,4,251
	.byte 15,133,45,4,0,0,139,42,139,69,12,133,192,15,132,76
	.byte 255,255,255,57,131,68,245,255,255,15,130,15,4,0,0,131
	.byte 197,16,137,116,36,20,137,68,36,8,139,179,60,245,255,255
	.byte 15,182,77,0,131,197,1,131,232,1,136,12,6,117,241,137
	.byte 240,139,116,36,20,233,72,254,255,255

	.globl lj_ff_string_lower
	.hidden lj_ff_string_lower
	.type lj_ff_string_lower, @function
	.size lj_ff_string_lower, 111
lj_ff_string_lower:
	.byte 131,248,2,15,130,224,3,0,0,139,171,4,245,255,255,59
	.byte 171,8,245,255,255,114,5,232,91,4,0,0,131,122,4,251
	.byte 15,133,195,3,0,0,139,42,139,69,12,57,131,68,245,255
	.byte 255,15,130,173,3,0,0,131,197,16,137,116,36,20,137,68
	.byte 36,8,139,179,60,245,255,255,235,21,15,182,76,5,0,131
	.byte 249,65,114,8,131,249,90,119,3,131,241,32,136,12,6,131
	.byte 232,1,121,230,137,240,139,116,36,20,233,217,253,255,255

	.globl lj_ff_string_upper
	.hidden lj_ff_string_upper
	.type lj_ff_string_upper, @function
	.size lj_ff_string_upper, 111
lj_ff_string_upper:
	.byte 131,248,2,15,130,113,3,0,0,139,171,4,245,255,255,59
	.byte 171,8,245,255,255,114,5,232,236,3,0,0,131,122,4,251
	.byte 15,133,84,3,0,0,139,42,139,69,12,57,131,68,245,255
	.byte 255,15,130,62,3,0,0,131,197,16,137,116,36,20,137,68
	.byte 36,8,139,179,60,245,255,255,235,21,15,182,76,5,0,131
	.byte 249,97,114,8,131,249,122,119,3,131,241,32,136,12,6,131
	.byte 232,1,121,230,137,240,139,116,36,20,233,106,253,255,255

	.globl lj_ff_table_getn
	.hidden lj_ff_table_getn
	.type lj_ff_table_getn, @function
	.size lj_ff_table_getn, 41
lj_ff_table_getn:
	.byte 131,248,2,15,130,2,3,0,0,131,122,4,244,15,133,248
	.byte 2,0,0,137,213,139,10,232
	.long lj_tab_len-.-4
	.byte 137,234,137,4,36,219,4,36,233,118,248,255,255

	.globl lj_ff_bit_tobit
	.hidden lj_ff_bit_tobit
	.type lj_ff_bit_tobit, @function
	.size lj_ff_bit_tobit, 44
lj_ff_bit_tobit:
	.byte 131,248,2,15,130,217,2,0,0,131,122,4,242,15,131,207
	.byte 2,0,0,221,2,199,68,36,16,0,0,192,89,216,68,36
	.byte 16,221,28,36,219,4,36,233,74,248,255,255

	.globl lj_ff_bit_band
	.hidden lj_ff_bit_band
	.type lj_ff_bit_band, @function
	.size lj_ff_bit_band, 82
lj_ff_bit_band:
	.byte 131,248,2,15,130,173,2,0,0,199,68,36,16,0,0,192
	.byte 89,131,122,4,242,15,131,155,2,0,0,221,2,216,68,36
	.byte 16,221,28,36,139,44,36,137,68,36,20,141,68,194,240,57
	.byte 208,15,134,11,1,0,0,131,120,4,242,15,131,12,1,0
	.byte 0,221,0,216,68,36,16,221,28,36,35,44,36,131,232,8
	.byte 235,221

	.globl lj_ff_bit_bor
	.hidden lj_ff_bit_bor
	.type lj_ff_bit_bor, @function
	.size lj_ff_bit_bor, 82
lj_ff_bit_bor:
	.byte 131,248,2,15,130,91,2,0,0,199,68,36,16,0,0,192
	.byte 89,131,122,4,242,15,131,73,2,0,0,221,2,216,68,36
	.byte 16,221,28,36,139,44,36,137,68,36,20,141,68,194,240,57
	.byte 208,15,134,185,0,0,0,131,120,4,242,15,131,186,0,0
	.byte 0,221,0,216,68,36,16,221,28,36,11,44,36,131,232,8
	.byte 235,221

	.globl lj_ff_bit_bxor
	.hidden lj_ff_bit_bxor
	.type lj_ff_bit_bxor, @function
	.size lj_ff_bit_bxor, 74
lj_ff_bit_bxor:
	.byte 131,248,2,15,130,9,2,0,0,199,68,36,16,0,0,192
	.byte 89,131,122,4,242,15,131,247,1,0,0,221,2,216,68,36
	.byte 16,221,28,36,139,44,36,137,68,36,20,141,68,194,240,57
	.byte 208,118,107,131,120,4,242,115,112,221,0,216,68,36,16,221
	.byte 28,36,51,44,36,131,232,8,235,229

	.globl lj_ff_bit_bswap
	.hidden lj_ff_bit_bswap
	.type lj_ff_bit_bswap, @function
	.size lj_ff_bit_bswap, 43
lj_ff_bit_bswap:
	.byte 131,248,2,15,130,191,1,0,0,131,122,4,242,15,131,181
	.byte 1,0,0,221,2,199,68,36,16,0,0,192,89,216,68,36
	.byte 16,221,28,36,139,44,36,15,205,235,41

	.globl lj_ff_bit_bnot
	.hidden lj_ff_bit_bnot
	.type lj_ff_bit_bnot, @function
	.size lj_ff_bit_bnot, 41
lj_ff_bit_bnot:
	.byte 131,248,2,15,130,148,1,0,0,131,122,4,242,15,131,138
	.byte 1,0,0,221,2,199,68,36,16,0,0,192,89,216,68,36
	.byte 16,221,28,36,139,44,36,247,213

	.globl lj_fff_resbit
	.hidden lj_fff_resbit
	.type lj_fff_resbit, @function
	.size lj_fff_resbit, 11
lj_fff_resbit:
	.byte 137,44,36,219,4,36,233,253,246,255,255

	.globl lj_fff_fallback_bit_op
	.hidden lj_fff_fallback_bit_op
	.type lj_fff_fallback_bit_op, @function
	.size lj_fff_fallback_bit_op, 9
lj_fff_fallback_bit_op:
	.byte 139,68,36,20,233,96,1,0,0

	.globl lj_ff_bit_lshift
	.hidden lj_ff_bit_lshift
	.type lj_ff_bit_lshift, @function
	.size lj_ff_bit_lshift, 68
lj_ff_bit_lshift:
	.byte 131,248,3,15,130,87,1,0,0,131,122,4,242,15,131,77
	.byte 1,0,0,131,122,12,242,15,131,67,1,0,0,221,2,221
	.byte 66,8,199,68,36,16,0,0,192,89,216,68,36,16,221,92
	.byte 36,8,216,68,36,16,221,28,36,139,76,36,8,139,44,36
	.byte 211,229,235,168

	.globl lj_ff_bit_rshift
	.hidden lj_ff_bit_rshift
	.type lj_ff_bit_rshift, @function
	.size lj_ff_bit_rshift, 71
lj_ff_bit_rshift:
	.byte 131,248,3,15,130,19,1,0,0,131,122,4,242,15,131,9
	.byte 1,0,0,131,122,12,242,15,131,255,0,0,0,221,2,221
	.byte 66,8,199,68,36,16,0,0,192,89,216,68,36,16,221,92
	.byte 36,8,216,68,36,16,221,28,36,139,76,36,8,139,44,36
	.byte 211,237,233,97,255,255,255

	.globl lj_ff_bit_arshift
	.hidden lj_ff_bit_arshift
	.type lj_ff_bit_arshift, @function
	.size lj_ff_bit_arshift, 71
lj_ff_bit_arshift:
	.byte 131,248,3,15,130,204,0,0,0,131,122,4,242,15,131,194
	.byte 0,0,0,131,122,12,242,15,131,184,0,0,0,221,2,221
	.byte 66,8,199,68,36,16,0,0,192,89,216,68,36,16,221,92
	.byte 36,8,216,68,36,16,221,28,36,139,76,36,8,139,44,36
	.byte 211,253,233,26,255,255,255

	.globl lj_ff_bit_rol
	.hidden lj_ff_bit_rol
	.type lj_ff_bit_rol, @function
	.size lj_ff_bit_rol, 71
lj_ff_bit_rol:
	.byte 131,248,3,15,130,133,0,0,0,131,122,4,242,15,131,123
	.byte 0,0,0,131,122,12,242,15,131,113,0,0,0,221,2,221
	.byte 66,8,199,68,36,16,0,0,192,89,216,68,36,16,221,92
	.byte 36,8,216,68,36,16,221,28,36,139,76,36,8,139,44,36
	.byte 211,197,233,211,254,255,255

	.globl lj_ff_bit_ror
	.hidden lj_ff_bit_ror
	.type lj_ff_bit_ror, @function
	.size lj_ff_bit_ror, 59
lj_ff_bit_ror:
	.byte 131,248,3,114,66,131,122,4,242,115,60,131,122,12,242,115
	.byte 54,221,2,221,66,8,199,68,36,16,0,0,192,89,216,68
	.byte 36,16,221,92,36,8,216,68,36,16,221,28,36,139,76,36
	.byte 8,139,44,36,211,205,233,152,254,255,255

	.globl lj_fff_fallback_2
	.hidden lj_fff_fallback_2
	.type lj_fff_fallback_2, @function
	.size lj_fff_fallback_2, 7
lj_fff_fallback_2:
	.byte 184,3,0,0,0,235,5

	.globl lj_fff_fallback_1
	.hidden lj_fff_fallback_1
	.type lj_fff_fallback_1, @function
	.size lj_fff_fallback_1, 5
lj_fff_fallback_1:
	.byte 184,2,0,0,0

	.globl lj_fff_fallback
	.hidden lj_fff_fallback
	.type lj_fff_fallback, @function
	.size lj_fff_fallback, 87
lj_fff_fallback:
	.byte 139,108,36,48,139,114,252,137,116,36,24,137,85,16,141,68
	.byte 194,248,141,136,160,0,0,0,137,69,20,139,66,248,59,77
	.byte 24,119,88,137,44,36,255,80,20,139,85,16,133,192,15,143
	.byte 107,245,255,255,139,77,20,41,209,193,233,3,133,192,141,65
	.byte 1,139,106,248,117,17,139,117,16,139,14,15,182,233,15,182
	.byte 205,131,198,4,255,36,171

	.globl lj_vm_call_tail
	.hidden lj_vm_call_tail
	.type lj_vm_call_tail, @function
	.size lj_vm_call_tail, 55
lj_vm_call_tail:
	.byte 137,209,247,198,3,0,0,0,117,14,15,182,110,253,247,213
	.byte 141,20,234,233,216,234,255,255,137,245,131,229,248,41,234,233
	.byte 204,234,255,255,186,20,0,0,0,137,233,232
	.long lj_state_growstack-.-4
	.byte 139,85,16,49,192,235,166

	.globl lj_fff_gcstep
	.hidden lj_fff_gcstep
	.type lj_fff_gcstep, @function
	.size lj_fff_gcstep, 50
lj_fff_gcstep:
	.byte 93,137,108,36,16,139,108,36,48,137,116,36,24,137,85,16
	.byte 141,68,194,248,137,233,137,69,20,232
	.long lj_gc_step-.-4
	.byte 139,85,16,139,69,20,41,208,193,232,3,131,192,1,139,108
	.byte 36,16,85,195

	.globl lj_vm_record
	.hidden lj_vm_record
	.type lj_vm_record, @function
	.size lj_vm_record, 27
lj_vm_record:
	.byte 15,182,131,113,245,255,255,168,32,117,79,168,16,117,52,168
	.byte 12,116,48,255,139,168,245,255,255,235,40

	.globl lj_vm_rethook
	.hidden lj_vm_rethook
	.type lj_vm_rethook, @function
	.size lj_vm_rethook, 13
lj_vm_rethook:
	.byte 15,182,131,113,245,255,255,168,16,117,52,235,27

	.globl lj_vm_inshook
	.hidden lj_vm_inshook
	.type lj_vm_inshook, @function
	.size lj_vm_inshook, 65
lj_vm_inshook:
	.byte 15,182,131,113,245,255,255,168,16,117,39,168,12,116,35,255
	.byte 139,168,245,255,255,116,4,168,4,116,23,139,108,36,48,137
	.byte 85,16,137,242,137,233,232
	.long lj_dispatch_ins-.-4
	.byte 139,85,16,15,182,78,253,15,182,110,252,15,183,70,254,255
	.byte 164,171,108,2,0,0

	.globl lj_cont_hook
	.hidden lj_cont_hook
	.type lj_cont_hook, @function
	.size lj_cont_hook, 12
lj_cont_hook:
	.byte 131,198,4,139,77,232,137,76,36,20,235,225

	.globl lj_vm_hotloop
	.hidden lj_vm_hotloop
	.type lj_vm_hotloop, @function
	.size lj_vm_hotloop, 48
lj_vm_hotloop:
	.byte 139,106,248,139,109,16,15,182,69,199,141,4,194,139,108,36
	.byte 48,137,85,16,137,69,20,137,242,141,139,112,246,255,255,137
	.byte 171,188,246,255,255,137,116,36,24,232
	.long lj_trace_hot-.-4
	.byte 235,174

	.globl lj_vm_callhook
	.hidden lj_vm_callhook
	.type lj_vm_callhook, @function
	.size lj_vm_callhook, 6
lj_vm_callhook:
	.byte 137,116,36,24,235,7

	.globl lj_vm_hotcall
	.hidden lj_vm_hotcall
	.type lj_vm_hotcall, @function
	.size lj_vm_hotcall, 65
lj_vm_hotcall:
	.byte 137,116,36,24,131,206,1,141,68,194,248,139,108,36,48,137
	.byte 85,16,137,69,20,137,242,137,233,232
	.long lj_dispatch_call-.-4
	.byte 199,68,36,24,0,0,0,0,131,230,254,139,85,16,137,193
	.byte 139,69,20,41,208,137,205,15,182,78,253,193,232,3,131,192
	.byte 1,255,229

	.globl lj_vm_exit_handler
	.hidden lj_vm_exit_handler
	.type lj_vm_exit_handler, @function
	.size lj_vm_exit_handler, 160
lj_vm_exit_handler:
	.byte 85,141,108,36,12,85,83,82,81,80,15,182,69,252,138,101
	.byte 248,137,125,252,137,117,248,139,93,0,139,139,188,245,255,255
	.byte 199,131,188,245,255,255,252,255,255,255,137,131,80,255,255,255
	.byte 137,139,76,255,255,255,131,236,80,242,15,17,125,216,242,15
	.byte 17,117,208,242,15,17,109,200,242,15,17,101,192,242,15,17
	.byte 93,184,242,15,17,85,176,242,15,17,77,168,242,15,17,69
	.byte 160,139,171,200,245,255,255,139,147,204,245,255,255,137,171,188
	.byte 246,255,255,199,131,200,245,255,255,0,0,0,0,137,85,16
	.byte 141,84,36,16,141,139,112,246,255,255,232
	.long lj_trace_exit-.-4
	.byte 139,77,40,131,225,252,137,204,137,105,48,139,85,16,139,113
	.byte 24

	.globl lj_vm_exit_interp
	.hidden lj_vm_exit_interp
	.type lj_vm_exit_interp, @function
	.size lj_vm_exit_interp, 74
lj_vm_exit_interp:
	.byte 133,192,120,59,137,68,36,20,139,122,248,139,127,16,139,127
	.byte 208,199,131,200,245,255,255,0,0,0,0,199,131,188,245,255
	.byte 255,255,255,255,255,139,6,15,182,204,15,182,232,131,198,4
	.byte 193,232,16,131,253,85,114,4,139,68,36,20,255,36,171,247
	.byte 216,137,233,137,194,232
	.long lj_err_throw-.-4

	.globl lj_vm_floor
	.hidden lj_vm_floor
	.type lj_vm_floor, @function
	.size lj_vm_floor, 41
lj_vm_floor:
	.byte 217,124,36,4,137,68,36,8,102,184,0,4,102,11,68,36
	.byte 4,102,37,255,247,102,137,68,36,6,217,108,36,6,217,252
	.byte 217,108,36,4,139,68,36,8,195

	.globl lj_vm_floor_sse
	.hidden lj_vm_floor_sse
	.type lj_vm_floor_sse, @function
	.size lj_vm_floor_sse, 87
lj_vm_floor_sse:
	.byte 102,15,239,210,102,15,118,210,102,15,115,210,1,184,0,0
	.byte 48,67,102,15,110,216,102,15,112,219,81,15,40,200,102,15
	.byte 84,202,102,15,46,217,118,46,102,15,85,208,242,15,88,203
	.byte 242,15,92,203,102,15,86,202,184,0,0,240,63,102,15,110
	.byte 208,102,15,112,210,81,242,15,194,193,1,102,15,84,194,242
	.byte 15,92,200,15,40,193,195

	.globl lj_vm_ceil
	.hidden lj_vm_ceil
	.type lj_vm_ceil, @function
	.size lj_vm_ceil, 41
lj_vm_ceil:
	.byte 217,124,36,4,137,68,36,8,102,184,0,8,102,11,68,36
	.byte 4,102,37,255,251,102,137,68,36,6,217,108,36,6,217,252
	.byte 217,108,36,4,139,68,36,8,195

	.globl lj_vm_ceil_sse
	.hidden lj_vm_ceil_sse
	.type lj_vm_ceil_sse, @function
	.size lj_vm_ceil_sse, 87
lj_vm_ceil_sse:
	.byte 102,15,239,210,102,15,118,210,102,15,115,210,1,184,0,0
	.byte 48,67,102,15,110,216,102,15,112,219,81,15,40,200,102,15
	.byte 84,202,102,15,46,217,118,46,102,15,85,208,242,15,88,203
	.byte 242,15,92,203,102,15,86,202,184,0,0,240,191,102,15,110
	.byte 208,102,15,112,210,81,242,15,194,193,6,102,15,84,194,242
	.byte 15,92,200,15,40,193,195

	.globl lj_vm_trunc
	.hidden lj_vm_trunc
	.type lj_vm_trunc, @function
	.size lj_vm_trunc, 37
lj_vm_trunc:
	.byte 217,124,36,4,137,68,36,8,102,184,0,12,102,11,68,36
	.byte 4,102,137,68,36,6,217,108,36,6,217,252,217,108,36,4
	.byte 139,68,36,8,195

	.globl lj_vm_trunc_sse
	.hidden lj_vm_trunc_sse
	.type lj_vm_trunc_sse, @function
	.size lj_vm_trunc_sse, 90
lj_vm_trunc_sse:
	.byte 102,15,239,210,102,15,118,210,102,15,115,210,1,184,0,0
	.byte 48,67,102,15,110,216,102,15,112,219,81,15,40,200,102,15
	.byte 84,202,102,15,46,217,118,49,102,15,85,208,15,40,193,242
	.byte 15,88,203,242,15,92,203,184,0,0,240,63,102,15,110,216
	.byte 102,15,112,219,81,242,15,194,193,1,102,15,84,195,242,15
	.byte 92,200,102,15,86,202,15,40,193,195

	.globl lj_vm_mod
	.hidden lj_vm_mod
	.type lj_vm_mod, @function
	.size lj_vm_mod, 41
lj_vm_mod:
	.byte 217,193,216,241,217,124,36,4,102,184,0,4,102,11,68,36
	.byte 4,102,37,255,247,102,137,68,36,6,217,108,36,6,217,252
	.byte 217,108,36,4,222,201,222,233,195

	.globl lj_vm_log2
	.hidden lj_vm_log2
	.type lj_vm_log2, @function
	.size lj_vm_log2, 9
lj_vm_log2:
	.byte 217,232,221,68,36,4,217,241,195

	.globl lj_vm_exp_x87
	.hidden lj_vm_exp_x87
	.type lj_vm_exp_x87, @function
	.size lj_vm_exp_x87, 4
lj_vm_exp_x87:
	.byte 217,234,222,201

	.globl lj_vm_exp2_x87
	.hidden lj_vm_exp2_x87
	.type lj_vm_exp2_x87, @function
	.size lj_vm_exp2_x87, 24
lj_vm_exp2_x87:
	.byte 217,84,36,4,129,124,36,4,0,0,128,127,116,28,129,124
	.byte 36,4,0,0,128,255,116,19

	.globl lj_vm_exp2raw
	.hidden lj_vm_exp2raw
	.type lj_vm_exp2raw, @function
	.size lj_vm_exp2raw, 24
lj_vm_exp2raw:
	.byte 217,192,217,252,220,233,217,201,217,240,217,232,222,193,217,253
	.byte 221,217,195,221,216,217,238,195

	.globl lj_vm_pow
	.hidden lj_vm_pow
	.type lj_vm_pow, @function
	.size lj_vm_pow, 209
lj_vm_pow:
	.byte 219,84,36,4,219,68,36,4,223,233,117,73,15,138,112,0
	.byte 0,0,221,216,139,68,36,4,131,248,1,126,34,169,1,0
	.byte 0,0,117,6,216,200,209,232,235,243,209,232,116,16,217,192
	.byte 216,200,209,232,116,6,115,248,220,201,235,244,222,201,195,116
	.byte 253,114,13,217,232,222,241,247,216,131,248,1,116,240,235,205
	.byte 221,216,217,232,195,217,84,36,4,217,201,217,84,36,8,139
	.byte 68,36,4,209,224,61,0,0,0,255,116,33,139,68,36,8
	.byte 209,224,116,62,61,0,0,0,255,116,55,217,241,233,102,255
	.byte 255,255,217,232,223,234,116,2,217,201,221,216,195,217,225,217
	.byte 232,223,233,116,24,221,216,217,225,217,238,184,0,0,0,0
	.byte 15,146,208,209,200,51,68,36,4,121,2,217,201,221,217,217
	.byte 225,195,131,124,36,4,0,125,244,221,216,221,216,133,192,116
	.byte 3,217,238,195,199,68,36,4,0,0,128,127,217,68,36,4
	.byte 195

	.globl lj_vm_pow_sse
	.hidden lj_vm_pow_sse
	.type lj_vm_pow_sse, @function
	.size lj_vm_pow_sse, 24
lj_vm_pow_sse:
	.byte 242,15,45,193,242,15,42,208,102,15,46,202,15,133,102,0
	.byte 0,0,15,138,197,0,0,0

	.globl lj_vm_powi_sse
	.hidden lj_vm_powi_sse
	.type lj_vm_powi_sse, @function
	.size lj_vm_powi_sse, 313
lj_vm_powi_sse:
	.byte 131,248,1,126,43,169,1,0,0,0,117,8,242,15,89,192
	.byte 209,232,235,241,209,232,116,23,15,40,200,242,15,89,192,209
	.byte 232,116,8,115,246,242,15,89,200,235,240,242,15,89,193,195
	.byte 116,253,114,29,247,216,232,202,255,255,255,184,0,0,240,63
	.byte 102,15,110,200,102,15,112,201,81,242,15,94,200,15,40,193
	.byte 195,184,0,0,240,63,102,15,110,192,102,15,112,192,81,195
	.byte 242,15,17,76,36,12,242,15,17,68,36,4,131,124,36,12
	.byte 0,117,13,139,68,36,16,209,224,61,0,0,224,255,116,93
	.byte 131,124,36,4,0,117,23,139,68,36,8,209,224,15,132,142
	.byte 0,0,0,61,0,0,224,255,15,132,143,0,0,0,221,68
	.byte 36,12,221,68,36,4,217,241,217,192,217,252,220,233,217,201
	.byte 217,240,217,232,222,193,217,253,221,217,221,92,36,4,242,15
	.byte 16,68,36,4,195,184,0,0,240,63,102,15,110,208,102,15
	.byte 112,210,81,102,15,46,194,116,3,15,40,193,195,102,15,239
	.byte 210,102,15,118,210,102,15,115,210,1,102,15,84,194,184,0
	.byte 0,240,63,102,15,110,208,102,15,112,210,81,102,15,46,194
	.byte 116,218,102,15,80,193,15,87,192,136,196,15,146,208,48,224
	.byte 117,202,184,0,0,240,127,102,15,110,192,102,15,112,192,81
	.byte 195,102,15,80,193,133,192,117,233,15,87,192,195,102,15,80
	.byte 193,133,192,116,221,15,87,192,195

	.globl lj_vm_foldfpm
	.hidden lj_vm_foldfpm
	.type lj_vm_foldfpm, @function
	.size lj_vm_foldfpm, 106
lj_vm_foldfpm:
	.byte 139,68,36,12,221,68,36,4,131,248,1,15,130,232,251,255
	.byte 255,15,132,98,252,255,255,131,248,3,15,130,217,252,255,255
	.byte 119,3,217,250,195,131,248,5,15,130,124,253,255,255,15,132
	.byte 122,253,255,255,131,248,7,116,9,119,14,217,237,217,201,217
	.byte 241,195,217,232,217,201,217,241,195,131,248,9,116,9,119,10
	.byte 217,236,217,201,217,241,195,217,254,195,131,248,11,116,5,119
	.byte 8,217,255,195,217,242,221,216,195,204

	.globl lj_vm_foldarith
	.hidden lj_vm_foldarith
	.type lj_vm_foldarith, @function
	.size lj_vm_foldarith, 109
lj_vm_foldarith:
	.byte 139,68,36,20,221,68,36,4,221,68,36,12,131,248,1,116
	.byte 5,119,6,222,193,195,222,233,195,131,248,3,116,5,119,6
	.byte 222,201,195,222,249,195,131,248,5,15,130,223,252,255,255,15
	.byte 132,63,253,255,255,131,248,7,116,7,119,10,221,216,217,224
	.byte 195,221,216,217,225,195,131,248,9,116,5,119,10,217,243,195
	.byte 217,201,217,253,221,217,195,131,248,11,116,9,119,14,219,233
	.byte 219,209,221,217,195,219,233,218,209,221,217,195,204

	.globl lj_vm_cpuid
	.hidden lj_vm_cpuid
	.type lj_vm_cpuid, @function
	.size lj_vm_cpuid, 46
lj_vm_cpuid:
	.byte 156,90,137,209,129,242,0,0,32,0,82,157,156,90,49,192
	.byte 57,209,116,25,139,68,36,4,87,83,15,162,139,124,36,16
	.byte 137,7,137,95,4,137,79,8,137,87,12,91,95,195

	.globl lj_assert_bad_for_arg_type
	.hidden lj_assert_bad_for_arg_type
	.type lj_assert_bad_for_arg_type, @function
	.size lj_assert_bad_for_arg_type, 1
lj_assert_bad_for_arg_type:
	.byte 204

	.globl lj_vm_ffi_callback
	.hidden lj_vm_ffi_callback
	.type lj_vm_ffi_callback, @function
	.size lj_vm_ffi_callback, 119
lj_vm_ffi_callback:
	.byte 131,236,16,87,86,83,131,236,28,141,157,16,11,0,0,139
	.byte 181,224,0,0,0,15,183,192,137,134,148,0,0,0,141,68
	.byte 36,64,137,78,96,137,86,100,137,134,128,0,0,0,139,76
	.byte 36,60,139,84,36,56,137,76,36,44,137,84,36,40,137,226
	.byte 137,116,36,24,137,241,232
	.long lj_ccallback_enter-.-4
	.byte 199,131,188,245,255,255,255,255,255,255,139,80,16,139,64,20
	.byte 41,208,139,106,248,193,232,3,131,192,1,139,117,16,139,14
	.byte 15,182,233,15,182,205,131,198,4,255,36,171

	.globl lj_cont_ffi_callback
	.hidden lj_cont_ffi_callback
	.type lj_cont_ffi_callback, @function
	.size lj_cont_ffi_callback, 81
lj_cont_ffi_callback:
	.byte 139,76,36,48,139,179,208,245,255,255,137,78,12,137,81,16
	.byte 137,105,20,137,241,137,194,232
	.long lj_ccallback_leave-.-4
	.byte 139,108,36,48,139,70,96,139,86,100,131,126,104,1,114,10
	.byte 116,5,221,70,32,235,3,217,70,32,139,77,20,15,183,73
	.byte 6,137,76,36,48,131,196,28,91,94,95,93,89,3,36,36
	.byte 131,196,16,81,195

	.globl lj_vm_ffi_call
	.hidden lj_vm_ffi_call
	.type lj_vm_ffi_call, @function
	.size lj_vm_ffi_call, 65
lj_vm_ffi_call:
	.byte 85,137,229,83,137,203,43,99,4,15,182,75,8,131,233,1
	.byte 120,12,139,68,139,40,137,4,140,131,233,1,121,244,139,75
	.byte 32,139,83,36,255,19,137,67,32,137,83,36,128,123,10,1
	.byte 114,10,116,5,221,91,16,235,3,217,91,16,139,93,252,201
	.byte 195

	.section .note.GNU-stack,"",@progbits
	.ident "DynASM 1.3.0"

	.section .debug_frame,"",@progbits
.Lframe0:
	.long .LECIE0-.LSCIE0
.LSCIE0:
	.long 0xffffffff
	.byte 0x1
	.string ""
	.uleb128 0x1
	.sleb128 -4
	.byte 0x8
	.byte 0xc
	.uleb128 0x4
	.uleb128 4
	.byte 0x80+0x8
	.uleb128 0x1
	.align 4
.LECIE0:

.LSFDE0:
	.long .LEFDE0-.LASFDE0
.LASFDE0:
	.long .Lframe0
	.long .Lbegin
	.long 13866
	.byte 0xe
	.uleb128 48
	.byte 0x85
	.uleb128 0x2
	.byte 0x87
	.uleb128 0x3
	.byte 0x86
	.uleb128 0x4
	.byte 0x83
	.uleb128 0x5
	.align 4
.LEFDE0:

.LSFDE1:
	.long .LEFDE1-.LASFDE1
.LASFDE1:
	.long .Lframe0
	.long lj_vm_ffi_call
	.long 65
	.byte 0xe
	.uleb128 8
	.byte 0x85
	.uleb128 0x2
	.byte 0xd
	.uleb128 0x5
	.byte 0x83
	.uleb128 0x3
	.align 4
.LEFDE1:

	.section .eh_frame,"a",@progbits
.Lframe1:
	.long .LECIE1-.LSCIE1
.LSCIE1:
	.long 0
	.byte 0x1
	.string "zPR"
	.uleb128 0x1
	.sleb128 -4
	.byte 0x8
	.uleb128 6
	.byte 0x1b
	.long lj_err_unwind_dwarf-.
	.byte 0x1b
	.byte 0xc
	.uleb128 0x4
	.uleb128 4
	.byte 0x80+0x8
	.uleb128 0x1
	.align 4
.LECIE1:

.LSFDE2:
	.long .LEFDE2-.LASFDE2
.LASFDE2:
	.long .LASFDE2-.Lframe1
	.long .Lbegin-.
	.long 13866
	.uleb128 0
	.byte 0xe
	.uleb128 48
	.byte 0x85
	.uleb128 0x2
	.byte 0x87
	.uleb128 0x3
	.byte 0x86
	.uleb128 0x4
	.byte 0x83
	.uleb128 0x5
	.align 4
.LEFDE2:

.Lframe2:
	.long .LECIE2-.LSCIE2
.LSCIE2:
	.long 0
	.byte 0x1
	.string "zR"
	.uleb128 0x1
	.sleb128 -4
	.byte 0x8
	.uleb128 1
	.byte 0x1b
	.byte 0xc
	.uleb128 0x4
	.uleb128 4
	.byte 0x80+0x8
	.uleb128 0x1
	.align 4
.LECIE2:

.LSFDE3:
	.long .LEFDE3-.LASFDE3
.LASFDE3:
	.long .LASFDE3-.Lframe2
	.long lj_vm_ffi_call-.
	.long 65
	.uleb128 0
	.byte 0xe
	.uleb128 8
	.byte 0x85
	.uleb128 0x2
	.byte 0xd
	.uleb128 0x5
	.byte 0x83
	.uleb128 0x3
	.align 4
.LEFDE3:


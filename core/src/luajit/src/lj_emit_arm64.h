/*
** ARM64 instruction emitter.
** Copyright (C) 2005-2017 Mike Pall. See Copyright Notice in luajit.h
**
** Contributed by Djordje Kovacevic and Stefan Pejic from RT-RK.com.
** Sponsored by Cisco Systems, Inc.
*/

/* -- Constant encoding --------------------------------------------------- */

static uint64_t get_k64val(IRIns *ir)
{
  if (ir->o == IR_KINT64) {
    return ir_kint64(ir)->u64;
  } else if (ir->o == IR_KGC) {
    return (uint64_t)ir_kgc(ir);
  } else if (ir->o == IR_KPTR || ir->o == IR_KKPTR) {
    return (uint64_t)ir_kptr(ir);
  } else {
    lua_assert(ir->o == IR_KINT || ir->o == IR_KNULL);
    return ir->i;  /* Sign-extended. */
  }
}

/* Encode constant in K12 format for data processing instructions. */
static uint32_t emit_isk12(int64_t n)
{
  uint64_t k = (n < 0) ? -n : n;
  uint32_t m = (n < 0) ? 0x40000000 : 0;
  if (k < 0x1000) {
    return A64I_K12|m|A64F_U12(k);
  } else if ((k & 0xfff000) == k) {
    return A64I_K12|m|0x400000|A64F_U12(k>>12);
  }
  return 0;
}

#define emit_clz64(n)	__builtin_clzll(n)
#define emit_ctz64(n)	__builtin_ctzll(n)

/* Encode constant in K13 format for logical data processing instructions. */
static uint32_t emit_isk13(uint64_t n, int is64)
{
  int inv = 0, w = 128, lz, tz;
  if (n & 1) { n = ~n; w = 64; inv = 1; }  /* Avoid wrap-around of ones. */
  if (!n) return 0;  /* Neither all-zero nor all-ones are allowed. */
  do {  /* Find the repeat width. */
    if (is64 && (uint32_t)(n^(n>>32))) break;
    n = (uint32_t)n;
    if (!n) return 0;  /* Ditto when passing n=0xffffffff and is64=0. */
    w = 32; if ((n^(n>>16)) & 0xffff) break;
    n = n & 0xffff; w = 16; if ((n^(n>>8)) & 0xff) break;
    n = n & 0xff; w = 8; if ((n^(n>>4)) & 0xf) break;
    n = n & 0xf; w = 4; if ((n^(n>>2)) & 0x3) break;
    n = n & 0x3; w = 2;
  } while (0);
  lz = emit_clz64(n);
  tz = emit_ctz64(n);
  if ((int64_t)(n << lz) >> (lz+tz) != -1ll) return 0; /* Non-contiguous? */
  if (inv)
    return A64I_K13 | (((lz-w) & 127) << 16) | (((lz+tz-w-1) & 63) << 10);
  else
    return A64I_K13 | ((w-tz) << 16) | (((63-lz-tz-w-w) & 63) << 10);
}

static uint32_t emit_isfpk64(uint64_t n)
{
  uint64_t etop9 = ((n >> 54) & 0x1ff);
  if ((n << 16) == 0 && (etop9 == 0x100 || etop9 == 0x0ff)) {
    return (uint32_t)(((n >> 48) & 0x7f) | ((n >> 56) & 0x80));
  }
  return ~0u;
}

/* -- Emit basic instructions --------------------------------------------- */

static void emit_dnma(ASMState *as, A64Ins ai, Reg rd, Reg rn, Reg rm, Reg ra)
{
  *--as->mcp = ai | A64F_D(rd) | A64F_N(rn) | A64F_M(rm) | A64F_A(ra);
}

static void emit_dnm(ASMState *as, A64Ins ai, Reg rd, Reg rn, Reg rm)
{
  *--as->mcp = ai | A64F_D(rd) | A64F_N(rn) | A64F_M(rm);
}

static void emit_dm(ASMState *as, A64Ins ai, Reg rd, Reg rm)
{
  *--as->mcp = ai | A64F_D(rd) | A64F_M(rm);
}

static void emit_dn(ASMState *as, A64Ins ai, Reg rd, Reg rn)
{
  *--as->mcp = ai | A64F_D(rd) | A64F_N(rn);
}

static void emit_nm(ASMState *as, A64Ins ai, Reg rn, Reg rm)
{
  *--as->mcp = ai | A64F_N(rn) | A64F_M(rm);
}

static void emit_d(ASMState *as, A64Ins ai, Reg rd)
{
  *--as->mcp = ai | A64F_D(rd);
}

static void emit_n(ASMState *as, A64Ins ai, Reg rn)
{
  *--as->mcp = ai | A64F_N(rn);
}

static int emit_checkofs(A64Ins ai, int64_t ofs)
{
  int scale = (ai >> 30) & 3;
  if (ofs < 0 || (ofs & ((1<<scale)-1))) {
    return (ofs >= -256 && ofs <= 255) ? -1 : 0;
  } else {
    return (ofs < (4096<<scale)) ? 1 : 0;
  }
}

static void emit_lso(ASMState *as, A64Ins ai, Reg rd, Reg rn, int64_t ofs)
{
  int ot = emit_checkofs(ai, ofs), sc = (ai >> 30) & 3;
  lua_assert(ot);
  /* Combine LDR/STR pairs to LDP/STP. */
  if ((sc == 2 || sc == 3) &&
      (!(ai & 0x400000) || rd != rn) &&
      as->mcp != as->mcloop) {
    uint32_t prev = *as->mcp & ~A64F_D(31);
    int ofsm = ofs - (1<<sc), ofsp = ofs + (1<<sc);
    A64Ins aip;
    if (prev == (ai | A64F_N(rn) | A64F_U12(ofsm>>sc)) ||
	prev == ((ai^A64I_LS_U) | A64F_N(rn) | A64F_S9(ofsm&0x1ff))) {
      aip = (A64F_A(rd) | A64F_D(*as->mcp & 31));
    } else if (prev == (ai | A64F_N(rn) | A64F_U12(ofsp>>sc)) ||
	       prev == ((ai^A64I_LS_U) | A64F_N(rn) | A64F_S9(ofsp&0x1ff))) {
      aip = (A64F_D(rd) | A64F_A(*as->mcp & 31));
      ofsm = ofs;
    } else {
      goto nopair;
    }
    if (ofsm >= (int)((unsigned int)-64<<sc) && ofsm <= (63<<sc)) {
      *as->mcp = aip | A64F_N(rn) | ((ofsm >> sc) << 15) |
	(ai ^ ((ai == A64I_LDRx || ai == A64I_STRx) ? 0x50000000 : 0x90000000));
      return;
    }
  }
nopair:
  if (ot == 1)
    *--as->mcp = ai | A64F_D(rd) | A64F_N(rn) | A64F_U12(ofs >> sc);
  else
    *--as->mcp = (ai^A64I_LS_U) | A64F_D(rd) | A64F_N(rn) | A64F_S9(ofs & 0x1ff);
}

/* -- Emit loads/stores --------------------------------------------------- */

/* Prefer rematerialization of BASE/L from global_State over spills. */
#define emit_canremat(ref)	((ref) <= ASMREF_L)

/* Try to find an N-step delta relative to other consts with N < lim. */
static int emit_kdelta(ASMState *as, Reg rd, uint64_t k, int lim)
{
  RegSet work = ~as->freeset & RSET_GPR;
  if (lim <= 1) return 0;  /* Can't beat that. */
  while (work) {
    Reg r = rset_picktop(work);
    IRRef ref = regcost_ref(as->cost[r]);
    lua_assert(r != rd);
    if (ref < REF_TRUE) {
      uint64_t kx = ra_iskref(ref) ? (uint64_t)ra_krefk(as, ref) :
				     get_k64val(IR(ref));
      int64_t delta = (int64_t)(k - kx);
      if (delta == 0) {
	emit_dm(as, A64I_MOVx, rd, r);
	return 1;
      } else {
	uint32_t k12 = emit_isk12(delta < 0 ? -delta : delta);
	if (k12) {
	  emit_dn(as, (delta < 0 ? A64I_SUBx : A64I_ADDx)^k12, rd, r);
	  return 1;
	}
	/* Do other ops or multi-step deltas pay off? Probably not.
	** E.g. XOR rarely helps with pointer consts.
	*/
      }
    }
    rset_clear(work, r);
  }
  return 0;  /* Failed. */
}

static void emit_loadk(ASMState *as, Reg rd, uint64_t u64, int is64)
{
  uint32_t k13 = emit_isk13(u64, is64);
  if (k13) {  /* Can the constant be represented as a bitmask immediate? */
    emit_dn(as, (is64|A64I_ORRw)^k13, rd, RID_ZERO);
  } else {
    int i, zeros = 0, ones = 0, neg;
    if (!is64) u64 = (int64_t)(int32_t)u64;  /* Sign-extend. */
    /* Count homogeneous 16 bit fragments. */
    for (i = 0; i < 4; i++) {
      uint64_t frag = (u64 >> i*16) & 0xffff;
      zeros += (frag == 0);
      ones += (frag == 0xffff);
    }
    neg = ones > zeros;  /* Use MOVN if it pays off. */
    if (!emit_kdelta(as, rd, u64, 4 - (neg ? ones : zeros))) {
      int shift = 0, lshift = 0;
      uint64_t n64 = neg ? ~u64 : u64;
      if (n64 != 0) {
	/* Find first/last fragment to be filled. */
	shift = (63-emit_clz64(n64)) & ~15;
	lshift = emit_ctz64(n64) & ~15;
      }
      /* MOVK requires the original value (u64). */
      while (shift > lshift) {
	uint32_t u16 = (u64 >> shift) & 0xffff;
	/* Skip fragments that are correctly filled by MOVN/MOVZ. */
	if (u16 != (neg ? 0xffff : 0))
	  emit_d(as, is64 | A64I_MOVKw | A64F_U16(u16) | A64F_LSL16(shift), rd);
	shift -= 16;
      }
      /* But MOVN needs an inverted value (n64). */
      emit_d(as, (neg ? A64I_MOVNx : A64I_MOVZx) |
		 A64F_U16((n64 >> lshift) & 0xffff) | A64F_LSL16(lshift), rd);
    }
  }
}

/* Load a 32 bit constant into a GPR. */
#define emit_loadi(as, rd, i)	emit_loadk(as, rd, i, 0)

/* Load a 64 bit constant into a GPR. */
#define emit_loadu64(as, rd, i)	emit_loadk(as, rd, i, A64I_X)

#define emit_loada(as, r, addr)	emit_loadu64(as, (r), (uintptr_t)(addr))

#define glofs(as, k) \
  ((intptr_t)((uintptr_t)(k) - (uintptr_t)&J2GG(as->J)->g))
#define mcpofs(as, k) \
  ((intptr_t)((uintptr_t)(k) - (uintptr_t)(as->mcp - 1)))
#define checkmcpofs(as, k) \
  ((((mcpofs(as, k)>>2) + 0x00040000) >> 19) == 0)

static Reg ra_allock(ASMState *as, intptr_t k, RegSet allow);

/* Get/set from constant pointer. */
static void emit_lsptr(ASMState *as, A64Ins ai, Reg r, void *p)
{
  /* First, check if ip + offset is in range. */
  if ((ai & 0x00400000) && checkmcpofs(as, p)) {
    emit_d(as, A64I_LDRLx | A64F_S19(mcpofs(as, p)>>2), r);
  } else {
    Reg base = RID_GL;  /* Next, try GL + offset. */
    int64_t ofs = glofs(as, p);
    if (!emit_checkofs(ai, ofs)) {  /* Else split up into base reg + offset. */
      int64_t i64 = i64ptr(p);
      base = ra_allock(as, (i64 & ~0x7fffull), rset_exclude(RSET_GPR, r));
      ofs = i64 & 0x7fffull;
    }
    emit_lso(as, ai, r, base, ofs);
  }
}

/* Load 64 bit IR constant into register. */
static void emit_loadk64(ASMState *as, Reg r, IRIns *ir)
{
  const uint64_t *k = &ir_k64(ir)->u64;
  int64_t ofs;
  if (r >= RID_MAX_GPR) {
    uint32_t fpk = emit_isfpk64(*k);
    if (fpk != ~0u) {
      emit_d(as, A64I_FMOV_DI | A64F_FP8(fpk), (r & 31));
      return;
    }
  }
  ofs = glofs(as, k);
  if (emit_checkofs(A64I_LDRx, ofs)) {
    emit_lso(as, r >= RID_MAX_GPR ? A64I_LDRd : A64I_LDRx,
	     (r & 31), RID_GL, ofs);
  } else {
    if (r >= RID_MAX_GPR) {
      emit_dn(as, A64I_FMOV_D_R, (r & 31), RID_TMP);
      r = RID_TMP;
    }
    if (checkmcpofs(as, k))
      emit_d(as, A64I_LDRLx | A64F_S19(mcpofs(as, k)>>2), r);
    else
      emit_loadu64(as, r, *k);
  }
}

/* Get/set global_State fields. */
#define emit_getgl(as, r, field) \
  emit_lsptr(as, A64I_LDRx, (r), (void *)&J2G(as->J)->field)
#define emit_setgl(as, r, field) \
  emit_lsptr(as, A64I_STRx, (r), (void *)&J2G(as->J)->field)

/* Trace number is determined from pc of exit instruction. */
#define emit_setvmstate(as, i)	UNUSED(i)

/* -- Emit control-flow instructions -------------------------------------- */

/* Label for internal jumps. */
typedef MCode *MCLabel;

/* Return label pointing to current PC. */
#define emit_label(as)		((as)->mcp)

static void emit_cond_branch(ASMState *as, A64CC cond, MCode *target)
{
  MCode *p = --as->mcp;
  ptrdiff_t delta = target - p;
  lua_assert(((delta + 0x40000) >> 19) == 0);
  *p = A64I_BCC | A64F_S19(delta) | cond;
}

static void emit_branch(ASMState *as, A64Ins ai, MCode *target)
{
  MCode *p = --as->mcp;
  ptrdiff_t delta = target - p;
  lua_assert(((delta + 0x02000000) >> 26) == 0);
  *p = ai | ((uint32_t)delta & 0x03ffffffu);
}

static void emit_tnb(ASMState *as, A64Ins ai, Reg r, uint32_t bit, MCode *target)
{
  MCode *p = --as->mcp;
  ptrdiff_t delta = target - p;
  lua_assert(bit < 63 && ((delta + 0x2000) >> 14) == 0);
  if (bit > 31) ai |= A64I_X;
  *p = ai | A64F_BIT(bit & 31) | A64F_S14((uint32_t)delta & 0x3fffu) | r;
}

static void emit_cnb(ASMState *as, A64Ins ai, Reg r, MCode *target)
{
  MCode *p = --as->mcp;
  ptrdiff_t delta = target - p;
  lua_assert(((delta + 0x40000) >> 19) == 0);
  *p = ai | A64F_S19(delta) | r;
}

#define emit_jmp(as, target)	emit_branch(as, A64I_B, (target))

static void emit_call(ASMState *as, void *target)
{
  MCode *p = --as->mcp;
  ptrdiff_t delta = (char *)target - (char *)p;
  if ((((delta>>2) + 0x02000000) >> 26) == 0) {
    *p = A64I_BL | ((uint32_t)(delta>>2) & 0x03ffffffu);
  } else {  /* Target out of range: need indirect call. But don't use R0-R7. */
    Reg r = ra_allock(as, i64ptr(target),
		      RSET_RANGE(RID_X8, RID_MAX_GPR)-RSET_FIXED);
    *p = A64I_BLR | A64F_N(r);
  }
}

/* -- Emit generic operations --------------------------------------------- */

/* Generic move between two regs. */
static void emit_movrr(ASMState *as, IRIns *ir, Reg dst, Reg src)
{
  if (dst >= RID_MAX_GPR) {
    emit_dn(as, irt_isnum(ir->t) ? A64I_FMOV_D : A64I_FMOV_S,
	    (dst & 31), (src & 31));
    return;
  }
  if (as->mcp != as->mcloop) {  /* Swap early registers for loads/stores. */
    MCode ins = *as->mcp, swp = (src^dst);
    if ((ins & 0xbf800000) == 0xb9000000) {
      if (!((ins ^ (dst << 5)) & 0x000003e0))
	*as->mcp = ins ^ (swp << 5);  /* Swap N in load/store. */
      if (!(ins & 0x00400000) && !((ins ^ dst) & 0x0000001f))
	*as->mcp = ins ^ swp;  /* Swap D in store. */
    }
  }
  emit_dm(as, A64I_MOVx, dst, src);
}

/* Generic load of register with base and (small) offset address. */
static void emit_loadofs(ASMState *as, IRIns *ir, Reg r, Reg base, int32_t ofs)
{
  if (r >= RID_MAX_GPR)
    emit_lso(as, irt_isnum(ir->t) ? A64I_LDRd : A64I_LDRs, (r & 31), base, ofs);
  else
    emit_lso(as, irt_is64(ir->t) ? A64I_LDRx : A64I_LDRw, r, base, ofs);
}

/* Generic store of register with base and (small) offset address. */
static void emit_storeofs(ASMState *as, IRIns *ir, Reg r, Reg base, int32_t ofs)
{
  if (r >= RID_MAX_GPR)
    emit_lso(as, irt_isnum(ir->t) ? A64I_STRd : A64I_STRs, (r & 31), base, ofs);
  else
    emit_lso(as, irt_is64(ir->t) ? A64I_STRx : A64I_STRw, r, base, ofs);
}

/* Emit an arithmetic operation with a constant operand. */
static void emit_opk(ASMState *as, A64Ins ai, Reg dest, Reg src,
		     int32_t i, RegSet allow)
{
  uint32_t k = emit_isk12(i);
  if (k)
    emit_dn(as, ai^k, dest, src);
  else
    emit_dnm(as, ai, dest, src, ra_allock(as, i, allow));
}

/* Add offset to pointer. */
static void emit_addptr(ASMState *as, Reg r, int32_t ofs)
{
  if (ofs)
    emit_opk(as, ofs < 0 ? A64I_SUBx : A64I_ADDx, r, r,
		 ofs < 0 ? -ofs : ofs, rset_exclude(RSET_GPR, r));
}

#define emit_spsub(as, ofs)	emit_addptr(as, RID_SP, -(ofs))


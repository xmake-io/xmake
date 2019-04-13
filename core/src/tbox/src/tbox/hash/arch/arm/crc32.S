/*!The Treasure Box Library
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * 
 * Copyright (C) 2009 - 2019, TBOOX Open Source Group.
 *
 * @author      ruki
 * @file        crc32.S
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
/* tb_uint32_t tb_crc32_make_asm(tb_uint32_t crc, tb_byte_t const* data, tb_size_t size, tb_uint32_t const* table);
 * 
 * @param crc   r0
 * @param data  r1
 * @param size  r2
 * @param table r3
 *
 * @return      crc, r0
 */
function tb_crc32_make_asm, export=1

    // enter
    mov ip, sp
    stmfd sp!, {r4-r9, sl, fp, ip, lr, pc}
    sub fp, ip, #4

    // calc crc for the odd address
label odd                               // while (1) { 
    ands r4, r1, #3                     // if (!(ib & 0x3)) goto even; 
    beq even
    subs r2, r2, #1                     // if (--in < 0) goto end; 
    blt end
                                        // calc: crc = table[(*ib++ ^ crc) & 0xff] ^ (crc >> 8) 
    ldrb r4, [r1], #1                   // r4 = *ib++ 
    eor r4, r0, r4                      // r4 ^= crc 
    and r4, r4, #255                    // r4 &= 0xff 
    ldr r4, [r3, r4, lsl #2]            // r4 = table[r4] 
    eor r0, r4, r0, lsr #8              // crc = r4 ^ (crc >> 8) 
    b odd                               // } 

label evenloop
    // ib[0-7] => r4-r9, sl, ip, ib += 8 * sizeof(uint32) 
    ldmia r1!, {r4 - r9, sl, ip}        

    // calc: for r4
    eor lr, r0, r4                      // calc: crc = table[((r4 >> 0) ^ crc) & 0xff] ^ (crc >> 8) 
    and lr, lr, #255    
    ldr lr, [r3, lr, lsl #2] 
    eor r0, lr, r0, lsr #8  

    eor lr, r0, r4, lsr #8              // calc: crc = table[((r4 >> 8) ^ crc) & 0xff] ^ (crc >> 8) 
    and lr, lr, #255
    ldr lr, [r3, lr, lsl #2]
    eor r0, lr, r0, lsr #8

    eor lr, r0, r4, lsr #16             // calc: crc = table[((r4 >> 16) ^ crc) & 0xff] ^ (crc >> 8) 
    and lr, lr, #255
    ldr lr, [r3, lr, lsl #2]
    eor r0, lr, r0, lsr #8

    eor lr, r0, r4, lsr #24             // calc: crc = table[((r4 >> 24) ^ crc) & 0xff] ^ (crc >> 8) 
    and lr, lr, #255
    ldr lr, [r3, lr, lsl #2]
    eor r0, lr, r0, lsr #8

    // calc: for r5 
    eor lr, r0, r5                      
    and lr, lr, #255
    ldr lr, [r3, lr, lsl #2]
    eor r0, lr, r0, lsr #8

    eor lr, r0, r5, lsr #8
    and lr, lr, #255
    ldr lr, [r3, lr, lsl #2]
    eor r0, lr, r0, lsr #8

    eor lr, r0, r5, lsr #16
    and lr, lr, #255
    ldr lr, [r3, lr, lsl #2]
    eor r0, lr, r0, lsr #8

    eor lr, r0, r5, lsr #24
    and lr, lr, #255
    ldr lr, [r3, lr, lsl #2]
    eor r0, lr, r0, lsr #8

    // calc: for r6 
    eor lr, r0, r6                      
    and lr, lr, #255
    ldr lr, [r3, lr, lsl #2]
    eor r0, lr, r0, lsr #8

    eor lr, r0, r6, lsr #8
    and lr, lr, #255
    ldr lr, [r3, lr, lsl #2]
    eor r0, lr, r0, lsr #8

    eor lr, r0, r6, lsr #16
    and lr, lr, #255
    ldr lr, [r3, lr, lsl #2]
    eor r0, lr, r0, lsr #8

    eor lr, r0, r6, lsr #24
    and lr, lr, #255
    ldr lr, [r3, lr, lsl #2]
    eor r0, lr, r0, lsr #8

    // calc: for r7 
    eor lr, r0, r7                      
    and lr, lr, #255
    ldr lr, [r3, lr, lsl #2]
    eor r0, lr, r0, lsr #8

    eor lr, r0, r7, lsr #8
    and lr, lr, #255
    ldr lr, [r3, lr, lsl #2]
    eor r0, lr, r0, lsr #8

    eor lr, r0, r7, lsr #16
    and lr, lr, #255
    ldr lr, [r3, lr, lsl #2]
    eor r0, lr, r0, lsr #8

    eor lr, r0, r7, lsr #24
    and lr, lr, #255
    ldr lr, [r3, lr, lsl #2]
    eor r0, lr, r0, lsr #8

    // calc: for r8 
    eor lr, r0 ,r8                      
    and lr, lr, #255    
    ldr lr, [r3, lr, lsl #2]
    eor r0, lr, r0, lsr #8

    eor lr, r0 ,r8, lsr #8  
    and lr, lr, #255    
    ldr lr, [r3, lr, lsl #2]
    eor r0, lr, r0, lsr #8

    eor lr, r0 ,r8, lsr #16 
    and lr, lr, #255    
    ldr lr, [r3, lr, lsl #2]
    eor r0, lr, r0, lsr #8

    eor lr, r0 ,r8, lsr #24 
    and lr, lr, #255    
    ldr lr, [r3, lr, lsl #2]
    eor r0, lr, r0, lsr #8

    // calc: for r9 
    eor lr, r0 ,r9                      
    and lr, lr, #255    
    ldr lr, [r3, lr, lsl #2]
    eor r0, lr, r0, lsr #8

    eor lr, r0 ,r9, lsr #8  
    and lr, lr, #255    
    ldr lr, [r3, lr, lsl #2]
    eor r0, lr, r0, lsr #8

    eor lr, r0 ,r9, lsr #16 
    and lr, lr, #255    
    ldr lr, [r3, lr, lsl #2]
    eor r0, lr, r0, lsr #8

    eor lr, r0 ,r9, lsr #24 
    and lr, lr, #255    
    ldr lr, [r3, lr, lsl #2]
    eor r0, lr, r0, lsr #8

    // calc: for sl 
    eor lr, r0, sl                      
    and lr, lr, #255    
    ldr lr, [r3, lr, lsl #2]
    eor r0, lr, r0, lsr #8

    eor lr, r0, sl, lsr #8  
    and lr, lr, #255    
    ldr lr, [r3, lr, lsl #2]
    eor r0, lr, r0, lsr #8

    eor lr, r0, sl, lsr #16 
    and lr, lr, #255    
    ldr lr, [r3, lr, lsl #2]
    eor r0, lr, r0, lsr #8

    eor lr, r0, sl, lsr #24 
    and lr, lr, #255    
    ldr lr, [r3, lr, lsl #2]
    eor r0, lr, r0, lsr #8

    // calc: for ip 
    eor lr, r0, ip                      
    and lr, lr, #255    
    ldr lr, [r3, lr, lsl #2]
    eor r0, lr, r0, lsr #8

    eor lr, r0, ip, lsr #8  
    and lr, lr, #255    
    ldr lr, [r3, lr, lsl #2]
    eor r0, lr, r0, lsr #8

    eor lr, r0, ip, lsr #16 
    and lr, lr, #255    
    ldr lr, [r3, lr, lsl #2]
    eor r0, lr, r0, lsr #8

    eor lr, r0, ip, lsr #24 
    and lr, lr, #255    
    ldr lr, [r3, lr, lsl #2]
    eor r0, lr, r0, lsr #8

label even
    // in -= 32; if (in >= 0) goto evenloop; 
    subs r2, r2, #32                    
    bge evenloop

    // left: in += 32; if (in < 0) goto end; 
    adds r2, r2, #32                    
    ble end

    // calc: the left data crc 
label left                              // do { 
    ldrb r4, [r1], #1                   // calc: crc = table[(*ib++ ^ crc) & 0xff] ^ (crc >> 8) 
    eor r4, r0, r4                  
    and r4, r4, #255    
    ldr r4, [r3, r4, lsl #2]
    eor r0, r4, r0, lsr #8

    subs r2, r2, #1                     // } while (--in) 
    bne left

label end
    // leave
    ldmea fp, {r4 - r9, sl, fp, sp, pc}

endfunc


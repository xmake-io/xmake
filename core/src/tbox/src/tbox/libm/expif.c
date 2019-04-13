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
 * @file        expif.c
 * @ingroup     libm
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "math.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_float_t tb_expif(tb_long_t x)
{
    tb_assert(x >= -31 && x <= 31);

    // x = [-31, 31]
    static tb_float_t table[47] = 
    {
        // [-15, -1]
        0.000000f
    ,   0.000001f
    ,   0.000002f
    ,   0.000006f
    ,   0.000017f
    ,   0.000045f
    ,   0.000123f
    ,   0.000335f
    ,   0.000912f
    ,   0.002479f
    ,   0.006738f
    ,   0.018316f
    ,   0.049787f
    ,   0.135335f
    ,   0.367879f

        // 0
    ,   1.000000f

        // [1, 31]
    ,   2.718282f
    ,   7.389056f
    ,   20.085537f
    ,   54.598150f
    ,   148.413159f
    ,   403.428793f
    ,   1096.633158f
    ,   2980.957987f
    ,   8103.083928f
    ,   22026.465795f
    ,   59874.141715f
    ,   162754.791419f
    ,   442413.392009f
    ,   1202604.284165f
    ,   3269017.372472f
    ,   8886110.520508f
    ,   24154952.753575f
    ,   65659969.137331f
    ,   178482300.963187f
    ,   485165195.409790f
    ,   1318815734.483215f
    ,   3584912846.131592f
    ,   9744803446.248903f
    ,   26489122129.843472f
    ,   72004899337.385880f
    ,   195729609428.838776f
    ,   532048240601.798645f
    ,   1446257064291.475098f
    ,   3931334297144.041992f
    ,   10686474581524.462891f
    ,   29048849665247.425781f

    };
    return table[((x) + 15) & 0x3f];
}

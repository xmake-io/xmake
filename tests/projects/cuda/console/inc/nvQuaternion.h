/*
 * Copyright 1993-2013 NVIDIA Corporation.  All rights reserved.
 *
 * Please refer to the NVIDIA end user license agreement (EULA) associated
 * with this source code for terms and conditions that govern your use of
 * this software. Any use, reproduction, disclosure, or distribution of
 * this software and related documentation outside the terms of the EULA
 * is strictly prohibited.
 *
 */

//
// Template math library for common 3D functionality
//
// nvQuaterion.h - quaternion template and utility functions
//
// This code is in part deriver from glh, a cross platform glut helper library.
// The copyright for glh follows this notice.
//
// Copyright (c) NVIDIA Corporation. All rights reserved.
////////////////////////////////////////////////////////////////////////////////

/*
    Copyright (c) 2000 Cass Everitt
    Copyright (c) 2000 NVIDIA Corporation
    All rights reserved.

    Redistribution and use in source and binary forms, with or
    without modification, are permitted provided that the following
    conditions are met:

     * Redistributions of source code must retain the above
       copyright notice, this list of conditions and the following
       disclaimer.

     * Redistributions in binary form must reproduce the above
       copyright notice, this list of conditions and the following
       disclaimer in the documentation and/or other materials
       provided with the distribution.

     * The names of contributors to this software may not be used
       to endorse or promote products derived from this software
       without specific prior written permission.

       THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
       ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
       LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
       FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
       REGENTS OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
       INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
       BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
       LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
       CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
       LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
       ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
       POSSIBILITY OF SUCH DAMAGE.


    Cass Everitt - cass@r3.nu
*/
#ifndef NV_QUATERNION_H
#define NV_QUATERNION_H

namespace nv
{

    template <class T> class vec2;
    template <class T> class vec3;
    template <class T> class vec4;

    ////////////////////////////////////////////////////////////////////////////////
    //
    //  Quaternion
    //
    ////////////////////////////////////////////////////////////////////////////////

    template< class T>
    class quaternion
    {
        public:

            quaternion() : x(0.0), y(0.0), z(0.0), w(0.0)
            {
            }

            quaternion(const T v[4])
            {
                set_value(v);
            }


            quaternion(T q0, T q1, T q2, T q3)
            {
                set_value(q0, q1, q2, q3);
            }


            quaternion(const matrix4<T> &m)
            {
                set_value(m);
            }


            quaternion(const vec3<T> &axis, T radians)
            {
                set_value(axis, radians);
            }


            quaternion(const vec3<T> &rotateFrom, const vec3<T> &rotateTo)
            {
                set_value(rotateFrom, rotateTo);
            }

            quaternion(const vec3<T> &from_look, const vec3<T> &from_up,
                       const vec3<T> &to_look, const vec3<T> &to_up)
            {
                set_value(from_look, from_up, to_look, to_up);
            }

            const T *get_value() const
            {
                return  &_array[0];
            }

            void get_value(T &q0, T &q1, T &q2, T &q3) const
            {
                q0 = _array[0];
                q1 = _array[1];
                q2 = _array[2];
                q3 = _array[3];
            }

            quaternion &set_value(T q0, T q1, T q2, T q3)
            {
                _array[0] = q0;
                _array[1] = q1;
                _array[2] = q2;
                _array[3] = q3;
                return *this;
            }

            void get_value(vec3<T> &axis, T &radians) const
            {
                radians = T(acos(_array[3]) * T(2.0));

                if (radians == T(0.0))
                {
                    axis = vec3<T>(0.0, 0.0, 1.0);
                }
                else
                {
                    axis[0] = _array[0];
                    axis[1] = _array[1];
                    axis[2] = _array[2];
                    axis = normalize(axis);
                }
            }

            void get_value(matrix4<T> &m) const
            {
                T s, xs, ys, zs, wx, wy, wz, xx, xy, xz, yy, yz, zz;

                T norm = _array[0] * _array[0] + _array[1] * _array[1] + _array[2] * _array[2] + _array[3] * _array[3];

                s = (norm == T(0.0)) ? T(0.0) : (T(2.0) / norm);

                xs = _array[0] * s;
                ys = _array[1] * s;
                zs = _array[2] * s;

                wx = _array[3] * xs;
                wy = _array[3] * ys;
                wz = _array[3] * zs;

                xx = _array[0] * xs;
                xy = _array[0] * ys;
                xz = _array[0] * zs;

                yy = _array[1] * ys;
                yz = _array[1] * zs;
                zz = _array[2] * zs;

                m(0,0) = T(T(1.0) - (yy + zz));
                m(1,0) = T(xy + wz);
                m(2,0) = T(xz - wy);

                m(0,1) = T(xy - wz);
                m(1,1) = T(T(1.0) - (xx + zz));
                m(2,1) = T(yz + wx);

                m(0,2) = T(xz + wy);
                m(1,2) = T(yz - wx);
                m(2,2) = T(T(1.0) - (xx + yy));

                m(3,0) = m(3,1) = m(3,2) = m(0,3) = m(1,3) = m(2,3) = T(0.0);
                m(3,3) = T(1.0);
            }

            quaternion &set_value(const T *qp)
            {
                for (int i = 0; i < 4; i++)
                {
                    _array[i] = qp[i];
                }

                return *this;
            }

            quaternion &set_value(const matrix4<T> &m)
            {
                T tr, s;
                int i, j, k;
                const int nxt[3] = { 1, 2, 0 };

                tr = m(0,0) + m(1,1) + m(2,2);

                if (tr > T(0))
                {
                    s = T(sqrt(tr + m(3,3)));
                    _array[3] = T(s * 0.5);
                    s = T(0.5) / s;

                    _array[0] = T((m(1,2) - m(2,1)) * s);
                    _array[1] = T((m(2,0) - m(0,2)) * s);
                    _array[2] = T((m(0,1) - m(1,0)) * s);
                }
                else
                {
                    i = 0;

                    if (m(1,1) > m(0,0))
                    {
                        i = 1;
                    }

                    if (m(2,2) > m(i,i))
                    {
                        i = 2;
                    }

                    j = nxt[i];
                    k = nxt[j];

                    s = T(sqrt((m(i,j) - (m(j,j) + m(k,k))) + T(1.0)));

                    _array[i] = T(s * 0.5);
                    s = T(0.5 / s);

                    _array[3] = T((m(j,k) - m(k,j)) * s);
                    _array[j] = T((m(i,j) + m(j,i)) * s);
                    _array[k] = T((m(i,k) + m(k,i)) * s);
                }

                return *this;
            }

            quaternion &set_value(const vec3<T> &axis, T theta)
            {
                T sqnorm = square_norm(axis);

                if (sqnorm == T(0.0))
                {
                    // axis too small.
                    x = y = z = T(0.0);
                    w = T(1.0);
                }
                else
                {
                    theta *= T(0.5);
                    T sin_theta = T(sin(theta));

                    if (sqnorm != T(1))
                    {
                        sin_theta /= T(sqrt(sqnorm));
                    }

                    x = sin_theta * axis[0];
                    y = sin_theta * axis[1];
                    z = sin_theta * axis[2];
                    w = T(cos(theta));
                }

                return *this;
            }

            quaternion &set_value(const vec3<T> &rotateFrom, const vec3<T> &rotateTo)
            {
                vec3<T> p1, p2;
                T alpha;

                p1 = normalize(rotateFrom);
                p2 = normalize(rotateTo);

                alpha = dot(p1, p2);

                if (alpha == T(1.0))
                {
                    *this = quaternion();
                    return *this;
                }

                // ensures that the anti-parallel case leads to a positive dot
                if (alpha == T(-1.0))
                {
                    vec3<T> v;

                    if (p1[0] != p1[1] || p1[0] != p1[2])
                    {
                        v = vec3<T>(p1[1], p1[2], p1[0]);
                    }
                    else
                    {
                        v = vec3<T>(-p1[0], p1[1], p1[2]);
                    }

                    v -= p1 * dot(p1, v);
                    v = normalize(v);

                    set_value(v, T(3.1415926));
                    return *this;
                }

                p1 = normalize(cross(p1, p2));

                set_value(p1,T(acos(alpha)));

                return *this;
            }

            quaternion &set_value(const vec3<T> &from_look, const vec3<T> &from_up,
                                  const vec3<T> &to_look, const vec3<T> &to_up)
            {
                quaternion r_look = quaternion(from_look, to_look);

                vec3<T> rotated_from_up(from_up);
                r_look.mult_vec(rotated_from_up);

                quaternion r_twist = quaternion(rotated_from_up, to_up);

                *this = r_twist;
                *this *= r_look;
                return *this;
            }

            quaternion &operator *= (const quaternion<T> &qr)
            {
                quaternion ql(*this);

                w = ql.w * qr.w - ql.x * qr.x - ql.y * qr.y - ql.z * qr.z;
                x = ql.w * qr.x + ql.x * qr.w + ql.y * qr.z - ql.z * qr.y;
                y = ql.w * qr.y + ql.y * qr.w + ql.z * qr.x - ql.x * qr.z;
                z = ql.w * qr.z + ql.z * qr.w + ql.x * qr.y - ql.y * qr.x;

                return *this;
            }

            friend quaternion normalize(const quaternion<T> &q)
            {
                quaternion r(q);
                T rnorm = T(1.0) / T(sqrt(q.w * q.w + q.x * q.x + q.y * q.y + q.z * q.z));

                r.x *= rnorm;
                r.y *= rnorm;
                r.z *= rnorm;
                r.w *= rnorm;
            }

            friend quaternion<T> conjugate(const quaternion<T> &q)
            {
                quaternion<T> r(q);
                r._array[0] *= T(-1.0);
                r._array[1] *= T(-1.0);
                r._array[2] *= T(-1.0);
                return r;
            }

            friend quaternion<T> inverse(const quaternion<T> &q)
            {
                return conjugate(q);
            }

            //
            // Quaternion multiplication with cartesian vector
            // v' = q*v*q(star)
            //
            void mult_vec(const vec3<T> &src, vec3<T> &dst) const
            {
                T v_coef = w * w - x * x - y * y - z * z;
                T u_coef = T(2.0) * (src[0] * x + src[1] * y + src[2] * z);
                T c_coef = T(2.0) * w;

                dst.v[0] = v_coef * src.v[0] + u_coef * x + c_coef * (y * src.v[2] - z * src.v[1]);
                dst.v[1] = v_coef * src.v[1] + u_coef * y + c_coef * (z * src.v[0] - x * src.v[2]);
                dst.v[2] = v_coef * src.v[2] + u_coef * z + c_coef * (x * src.v[1] - y * src.v[0]);
            }

            void mult_vec(vec3<T> &src_and_dst) const
            {
                mult_vec(vec3<T>(src_and_dst), src_and_dst);
            }

            void scale_angle(T scaleFactor)
            {
                vec3<T> axis;
                T radians;

                get_value(axis, radians);
                radians *= scaleFactor;
                set_value(axis, radians);
            }

            friend quaternion<T> slerp(const quaternion<T> &p, const quaternion<T> &q, T alpha)
            {
                quaternion r;

                T cos_omega = p.x * q.x + p.y * q.y + p.z * q.z + p.w * q.w;
                // if B is on opposite hemisphere from A, use -B instead

                int bflip;

                if ((bflip = (cos_omega < T(0))))
                {
                    cos_omega = -cos_omega;
                }

                // complementary interpolation parameter
                T beta = T(1) - alpha;

                if (cos_omega >= T(1))
                {
                    return p;
                }

                T omega = T(acos(cos_omega));
                T one_over_sin_omega = T(1.0) / T(sin(omega));

                beta    = T(sin(omega*beta)  * one_over_sin_omega);
                alpha   = T(sin(omega*alpha) * one_over_sin_omega);

                if (bflip)
                {
                    alpha = -alpha;
                }

                r.x = beta * p._array[0]+ alpha * q._array[0];
                r.y = beta * p._array[1]+ alpha * q._array[1];
                r.z = beta * p._array[2]+ alpha * q._array[2];
                r.w = beta * p._array[3]+ alpha * q._array[3];
                return r;
            }

            T &operator [](int i)
            {
                return _array[i];
            }

            const T &operator [](int i) const
            {
                return _array[i];
            }


            friend bool operator == (const quaternion<T> &lhs, const quaternion<T> &rhs)
            {
                bool r = true;

                for (int i = 0; i < 4; i++)
                {
                    r &= lhs._array[i] == rhs._array[i];
                }

                return r;
            }

            friend bool operator != (const quaternion<T> &lhs, const quaternion<T> &rhs)
            {
                bool r = true;

                for (int i = 0; i < 4; i++)
                {
                    r &= lhs._array[i] == rhs._array[i];
                }

                return r;
            }

            friend quaternion<T> operator * (const quaternion<T> &lhs, const quaternion<T> &rhs)
            {
                quaternion r(lhs);
                r *= rhs;
                return r;
            }


            union
            {
                struct
                {
                    T x;
                    T y;
                    T z;
                    T w;
                };
                T _array[4];
            };

    };



};

#endif

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
// nvVector.h - 2-vector, 3-vector, and 4-vector templates and utilities
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
#ifndef NV_VECTOR_H
#define NV_VECTOR_H

namespace nv
{

    template <class T> class vec2;
    template <class T> class vec3;
    template <class T> class vec4;

    //////////////////////////////////////////////////////////////////////
    //
    // vec2 - template class for 2-tuple vector
    //
    //////////////////////////////////////////////////////////////////////
    template <class T>
    class vec2
    {
        public:

            typedef T value_type;
            int size() const
            {
                return 2;
            }

            ////////////////////////////////////////////////////////
            //
            //  Constructors
            //
            ////////////////////////////////////////////////////////

            // Default/scalar constructor
            vec2(const T &t = T())
            {
                for (int i = 0; i < size(); i++)
                {
                    _array[i] = t;
                }
            }

            // Construct from array
            vec2(const T *tp)
            {
                for (int i = 0; i < size(); i++)
                {
                    _array[i] = tp[i];
                }
            }

            // Construct from explicit values
            vec2(const T v0, const T v1)
            {
                x = v0;
                y = v1;
            }

            explicit vec2(const vec3<T> &u)
            {
                for (int i = 0; i < size(); i++)
                {
                    _array[i] = u._array[i];
                }
            }

            explicit vec2(const vec4<T> &u)
            {
                for (int i = 0; i < size(); i++)
                {
                    _array[i] = u._array[i];
                }
            }

            const T *get_value() const
            {
                return _array;
            }

            vec2<T> &set_value(const T *rhs)
            {
                for (int i = 0; i < size(); i++)
                {
                    _array[i] = rhs[i];
                }

                return *this;
            }

            // indexing operators
            T &operator [](int i)
            {
                return _array[i];
            }

            const T &operator [](int i) const
            {
                return _array[i];
            }

            // type-cast operators
            operator T *()
            {
                return _array;
            }

            operator const T *() const
            {
                return _array;
            }

            ////////////////////////////////////////////////////////
            //
            //  Math operators
            //
            ////////////////////////////////////////////////////////

            // scalar multiply assign
            friend vec2<T> &operator *= (vec2<T> &lhs, T d)
            {
                for (int i = 0; i < lhs.size(); i++)
                {
                    lhs._array[i] *= d;
                }

                return lhs;
            }

            // component-wise vector multiply assign
            friend vec2<T> &operator *= (vec2<T> &lhs, const vec2<T> &rhs)
            {
                for (int i = 0; i < lhs.size(); i++)
                {
                    lhs._array[i] *= rhs[i];
                }

                return lhs;
            }

            // scalar divide assign
            friend vec2<T> &operator /= (vec2<T> &lhs, T d)
            {
                if (d == 0)
                {
                    return lhs;
                }

                for (int i = 0; i < lhs.size(); i++)
                {
                    lhs._array[i] /= d;
                }

                return lhs;
            }

            // component-wise vector divide assign
            friend vec2<T> &operator /= (vec2<T> &lhs, const vec2<T> &rhs)
            {
                for (int i = 0; i < lhs.size(); i++)
                {
                    lhs._array[i] /= rhs._array[i];
                }

                return lhs;
            }

            // component-wise vector add assign
            friend vec2<T> &operator += (vec2<T> &lhs, const vec2<T> &rhs)
            {
                for (int i = 0; i < lhs.size(); i++)
                {
                    lhs._array[i] += rhs._array[i];
                }

                return lhs;
            }

            // component-wise vector subtract assign
            friend vec2<T> &operator -= (vec2<T> &lhs, const vec2<T> &rhs)
            {
                for (int i = 0; i < lhs.size(); i++)
                {
                    lhs._array[i] -= rhs._array[i];
                }

                return lhs;
            }

            // unary negate
            friend vec2<T> operator - (const vec2<T> &rhs)
            {
                vec2<T> rv;

                for (int i = 0; i < rhs.size(); i++)
                {
                    rv._array[i] = -rhs._array[i];
                }

                return rv;
            }

            // vector add
            friend vec2<T> operator + (const vec2<T> &lhs, const vec2<T> &rhs)
            {
                vec2<T> rt(lhs);
                return rt += rhs;
            }

            // vector subtract
            friend vec2<T> operator - (const vec2<T> &lhs, const vec2<T> &rhs)
            {
                vec2<T> rt(lhs);
                return rt -= rhs;
            }

            // scalar multiply
            friend vec2<T> operator * (const vec2<T> &lhs, T rhs)
            {
                vec2<T> rt(lhs);
                return rt *= rhs;
            }

            // scalar multiply
            friend vec2<T> operator * (T lhs, const vec2<T> &rhs)
            {
                vec2<T> rt(lhs);
                return rt *= rhs;
            }

            // vector component-wise multiply
            friend vec2<T> operator * (const vec2<T> &lhs, const vec2<T> &rhs)
            {
                vec2<T> rt(lhs);
                return rt *= rhs;
            }

            // scalar multiply
            friend vec2<T> operator / (const vec2<T> &lhs, T rhs)
            {
                vec2<T> rt(lhs);
                return rt /= rhs;
            }

            // vector component-wise multiply
            friend vec2<T> operator / (const vec2<T> &lhs, const vec2<T> &rhs)
            {
                vec2<T> rt(lhs);
                return rt /= rhs;
            }

            ////////////////////////////////////////////////////////
            //
            //  Comparison operators
            //
            ////////////////////////////////////////////////////////

            // equality
            friend bool operator == (const vec2<T> &lhs, const vec2<T> &rhs)
            {
                bool r = true;

                for (int i = 0; i < lhs.size(); i++)
                {
                    r &= lhs._array[i] == rhs._array[i];
                }

                return r;
            }

            // inequality
            friend bool operator != (const vec2<T> &lhs, const vec2<T> &rhs)
            {
                bool r = true;

                for (int i = 0; i < lhs.size(); i++)
                {
                    r &= lhs._array[i] != rhs._array[i];
                }

                return r;
            }

            //data intentionally left public to allow vec2.x
            union
            {
                struct
                {
                    T x,y;          // standard names for components
                };
                struct
                {
                    T s,t;          // standard names for components
                };
                T _array[2];     // array access
            };
    };

    //////////////////////////////////////////////////////////////////////
    //
    // vec3 - template class for 3-tuple vector
    //
    //////////////////////////////////////////////////////////////////////
    template <class T>
    class vec3
    {
        public:

            typedef T value_type;
            int size() const
            {
                return 3;
            }

            ////////////////////////////////////////////////////////
            //
            //  Constructors
            //
            ////////////////////////////////////////////////////////

            // Default/scalar constructor
            vec3(const T &t = T())
            {
                for (int i = 0; i < size(); i++)
                {
                    _array[i] = t;
                }
            }

            // Construct from array
            vec3(const T *tp)
            {
                for (int i = 0; i < size(); i++)
                {
                    _array[i] = tp[i];
                }
            }

            // Construct from explicit values
            vec3(const T v0, const T v1, const T v2)
            {
                x = v0;
                y = v1;
                z = v2;
            }

            explicit vec3(const vec4<T> &u)
            {
                for (int i = 0; i < size(); i++)
                {
                    _array[i] = u._array[i];
                }
            }

            explicit vec3(const vec2<T> &u, T v0)
            {
                x = u.x;
                y = u.y;
                z = v0;
            }

            const T *get_value() const
            {
                return _array;
            }

            vec3<T> &set_value(const T *rhs)
            {
                for (int i = 0; i < size(); i++)
                {
                    _array[i] = rhs[i];
                }

                return *this;
            }

            // indexing operators
            T &operator [](int i)
            {
                return _array[i];
            }

            const T &operator [](int i) const
            {
                return _array[i];
            }

            // type-cast operators
            operator T *()
            {
                return _array;
            }

            operator const T *() const
            {
                return _array;
            }

            ////////////////////////////////////////////////////////
            //
            //  Math operators
            //
            ////////////////////////////////////////////////////////

            // scalar multiply assign
            friend vec3<T> &operator *= (vec3<T> &lhs, T d)
            {
                for (int i = 0; i < lhs.size(); i++)
                {
                    lhs._array[i] *= d;
                }

                return lhs;
            }

            // component-wise vector multiply assign
            friend vec3<T> &operator *= (vec3<T> &lhs, const vec3<T> &rhs)
            {
                for (int i = 0; i < lhs.size(); i++)
                {
                    lhs._array[i] *= rhs[i];
                }

                return lhs;
            }

            // scalar divide assign
            friend vec3<T> &operator /= (vec3<T> &lhs, T d)
            {
                if (d == 0)
                {
                    return lhs;
                }

                for (int i = 0; i < lhs.size(); i++)
                {
                    lhs._array[i] /= d;
                }

                return lhs;
            }

            // component-wise vector divide assign
            friend vec3<T> &operator /= (vec3<T> &lhs, const vec3<T> &rhs)
            {
                for (int i = 0; i < lhs.size(); i++)
                {
                    lhs._array[i] /= rhs._array[i];
                }

                return lhs;
            }

            // component-wise vector add assign
            friend vec3<T> &operator += (vec3<T> &lhs, const vec3<T> &rhs)
            {
                for (int i = 0; i < lhs.size(); i++)
                {
                    lhs._array[i] += rhs._array[i];
                }

                return lhs;
            }

            // component-wise vector subtract assign
            friend vec3<T> &operator -= (vec3<T> &lhs, const vec3<T> &rhs)
            {
                for (int i = 0; i < lhs.size(); i++)
                {
                    lhs._array[i] -= rhs._array[i];
                }

                return lhs;
            }

            // unary negate
            friend vec3<T> operator - (const vec3<T> &rhs)
            {
                vec3<T> rv;

                for (int i = 0; i < rhs.size(); i++)
                {
                    rv._array[i] = -rhs._array[i];
                }

                return rv;
            }

            // vector add
            friend vec3<T> operator + (const vec3<T> &lhs, const vec3<T> &rhs)
            {
                vec3<T> rt(lhs);
                return rt += rhs;
            }

            // vector subtract
            friend vec3<T> operator - (const vec3<T> &lhs, const vec3<T> &rhs)
            {
                vec3<T> rt(lhs);
                return rt -= rhs;
            }

            // scalar multiply
            friend vec3<T> operator * (const vec3<T> &lhs, T rhs)
            {
                vec3<T> rt(lhs);
                return rt *= rhs;
            }

            // scalar multiply
            friend vec3<T> operator * (T lhs, const vec3<T> &rhs)
            {
                vec3<T> rt(lhs);
                return rt *= rhs;
            }

            // vector component-wise multiply
            friend vec3<T> operator * (const vec3<T> &lhs, const vec3<T> &rhs)
            {
                vec3<T> rt(lhs);
                return rt *= rhs;
            }

            // scalar multiply
            friend vec3<T> operator / (const vec3<T> &lhs, T rhs)
            {
                vec3<T> rt(lhs);
                return rt /= rhs;
            }

            // vector component-wise multiply
            friend vec3<T> operator / (const vec3<T> &lhs, const vec3<T> &rhs)
            {
                vec3<T> rt(lhs);
                return rt /= rhs;
            }

            ////////////////////////////////////////////////////////
            //
            //  Comparison operators
            //
            ////////////////////////////////////////////////////////

            // equality
            friend bool operator == (const vec3<T> &lhs, const vec3<T> &rhs)
            {
                bool r = true;

                for (int i = 0; i < lhs.size(); i++)
                {
                    r &= lhs._array[i] == rhs._array[i];
                }

                return r;
            }

            // inequality
            friend bool operator != (const vec3<T> &lhs, const vec3<T> &rhs)
            {
                bool r = true;

                for (int i = 0; i < lhs.size(); i++)
                {
                    r &= lhs._array[i] != rhs._array[i];
                }

                return r;
            }

            ////////////////////////////////////////////////////////////////////////////////
            //
            // dimension specific operations
            //
            ////////////////////////////////////////////////////////////////////////////////

            // cross product
            friend vec3<T> cross(const vec3<T> &lhs, const vec3<T> &rhs)
            {
                vec3<T> r;

                r.x = lhs.y * rhs.z - lhs.z * rhs.y;
                r.y = lhs.z * rhs.x - lhs.x * rhs.z;
                r.z = lhs.x * rhs.y - lhs.y * rhs.x;

                return r;
            }

            //data intentionally left public to allow vec2.x
            union
            {
                struct
                {
                    T x, y, z;          // standard names for components
                };
                struct
                {
                    T s, t, r;          // standard names for components
                };
                T _array[3];     // array access
            };
    };

    //////////////////////////////////////////////////////////////////////
    //
    // vec4 - template class for 4-tuple vector
    //
    //////////////////////////////////////////////////////////////////////
    template <class T>
    class vec4
    {
        public:

            typedef T value_type;
            int size() const
            {
                return 4;
            }

            ////////////////////////////////////////////////////////
            //
            //  Constructors
            //
            ////////////////////////////////////////////////////////

            // Default/scalar constructor
            vec4(const T &t = T())
            {
                for (int i = 0; i < size(); i++)
                {
                    _array[i] = t;
                }
            }

            // Construct from array
            vec4(const T *tp)
            {
                for (int i = 0; i < size(); i++)
                {
                    _array[i] = tp[i];
                }
            }

            // Construct from explicit values
            vec4(const T v0, const T v1, const T v2, const T v3)
            {
                x = v0;
                y = v1;
                z = v2;
                w = v3;
            }

            explicit vec4(const vec3<T> &u, T v0)
            {
                x = u.x;
                y = u.y;
                z = u.z;
                w = v0;
            }

            explicit vec4(const vec2<T> &u, T v0, T v1)
            {
                x = u.x;
                y = u.y;
                z = v0;
                w = v1;
            }

            const T *get_value() const
            {
                return _array;
            }

            vec4<T> &set_value(const T *rhs)
            {
                for (int i = 0; i < size(); i++)
                {
                    _array[i] = rhs[i];
                }

                return *this;
            }

            // indexing operators
            T &operator [](int i)
            {
                return _array[i];
            }

            const T &operator [](int i) const
            {
                return _array[i];
            }

            // type-cast operators
            operator T *()
            {
                return _array;
            }

            operator const T *() const
            {
                return _array;
            }

            ////////////////////////////////////////////////////////
            //
            //  Math operators
            //
            ////////////////////////////////////////////////////////

            // scalar multiply assign
            friend vec4<T> &operator *= (vec4<T> &lhs, T d)
            {
                for (int i = 0; i < lhs.size(); i++)
                {
                    lhs._array[i] *= d;
                }

                return lhs;
            }

            // component-wise vector multiply assign
            friend vec4<T> &operator *= (vec4<T> &lhs, const vec4<T> &rhs)
            {
                for (int i = 0; i < lhs.size(); i++)
                {
                    lhs._array[i] *= rhs[i];
                }

                return lhs;
            }

            // scalar divide assign
            friend vec4<T> &operator /= (vec4<T> &lhs, T d)
            {
                if (d == 0)
                {
                    return lhs;
                }

                for (int i = 0; i < lhs.size(); i++)
                {
                    lhs._array[i] /= d;
                }

                return lhs;
            }

            // component-wise vector divide assign
            friend vec4<T> &operator /= (vec4<T> &lhs, const vec4<T> &rhs)
            {
                for (int i = 0; i < lhs.size(); i++)
                {
                    lhs._array[i] /= rhs._array[i];
                }

                return lhs;
            }

            // component-wise vector add assign
            friend vec4<T> &operator += (vec4<T> &lhs, const vec4<T> &rhs)
            {
                for (int i = 0; i < lhs.size(); i++)
                {
                    lhs._array[i] += rhs._array[i];
                }

                return lhs;
            }

            // component-wise vector subtract assign
            friend vec4<T> &operator -= (vec4<T> &lhs, const vec4<T> &rhs)
            {
                for (int i = 0; i < lhs.size(); i++)
                {
                    lhs._array[i] -= rhs._array[i];
                }

                return lhs;
            }

            // unary negate
            friend vec4<T> operator - (const vec4<T> &rhs)
            {
                vec4<T> rv;

                for (int i = 0; i < rhs.size(); i++)
                {
                    rv._array[i] = -rhs._array[i];
                }

                return rv;
            }

            // vector add
            friend vec4<T> operator + (const vec4<T> &lhs, const vec4<T> &rhs)
            {
                vec4<T> rt(lhs);
                return rt += rhs;
            }

            // vector subtract
            friend vec4<T> operator - (const vec4<T> &lhs, const vec4<T> &rhs)
            {
                vec4<T> rt(lhs);
                return rt -= rhs;
            }

            // scalar multiply
            friend vec4<T> operator * (const vec4<T> &lhs, T rhs)
            {
                vec4<T> rt(lhs);
                return rt *= rhs;
            }

            // scalar multiply
            friend vec4<T> operator * (T lhs, const vec4<T> &rhs)
            {
                vec4<T> rt(lhs);
                return rt *= rhs;
            }

            // vector component-wise multiply
            friend vec4<T> operator * (const vec4<T> &lhs, const vec4<T> &rhs)
            {
                vec4<T> rt(lhs);
                return rt *= rhs;
            }

            // scalar multiply
            friend vec4<T> operator / (const vec4<T> &lhs, T rhs)
            {
                vec4<T> rt(lhs);
                return rt /= rhs;
            }

            // vector component-wise multiply
            friend vec4<T> operator / (const vec4<T> &lhs, const vec4<T> &rhs)
            {
                vec4<T> rt(lhs);
                return rt /= rhs;
            }

            ////////////////////////////////////////////////////////
            //
            //  Comparison operators
            //
            ////////////////////////////////////////////////////////

            // equality
            friend bool operator == (const vec4<T> &lhs, const vec4<T> &rhs)
            {
                bool r = true;

                for (int i = 0; i < lhs.size(); i++)
                {
                    r &= lhs._array[i] == rhs._array[i];
                }

                return r;
            }

            // inequality
            friend bool operator != (const vec4<T> &lhs, const vec4<T> &rhs)
            {
                bool r = true;

                for (int i = 0; i < lhs.size(); i++)
                {
                    r &= lhs._array[i] != rhs._array[i];
                }

                return r;
            }

            //data intentionally left public to allow vec2.x
            union
            {
                struct
                {
                    T x, y, z, w;          // standard names for components
                };
                struct
                {
                    T s, t, r, q;          // standard names for components
                };
                T _array[4];     // array access
            };
    };

    ////////////////////////////////////////////////////////////////////////////////
    //
    // Generic vector operations
    //
    ////////////////////////////////////////////////////////////////////////////////

    // compute the dot product of two vectors
    template<class T>
    inline typename T::value_type dot(const T &lhs, const T &rhs)
    {
        typename T::value_type r = 0;

        for (int i = 0; i < lhs.size(); i++)
        {
            r += lhs._array[i] * rhs._array[i];
        }

        return r;
    }

    // return the length of the provided vector
    template< class T>
    inline typename T::value_type length(const T &vec)
    {
        typename T::value_type r = 0;

        for (int i = 0; i < vec.size(); i++)
        {
            r += vec._array[i]*vec._array[i];
        }

        return typename T::value_type(sqrt(r));
    }

    // return the squared norm
    template< class T>
    inline typename T::value_type square_norm(const T &vec)
    {
        typename T::value_type r = 0;

        for (int i = 0; i < vec.size(); i++)
        {
            r += vec._array[i]*vec._array[i];
        }

        return r;
    }

    // return the normalized version of the vector
    template< class T>
    inline T normalize(const T &vec)
    {
        typename T::value_type sum(0);
        T r;

        for (int i = 0; i < vec.size(); i++)
        {
            sum += vec._array[i] * vec._array[i];
        }

        sum = typename T::value_type(sqrt(sum));

        if (sum > 0)
            for (int i = 0; i < vec.size(); i++)
            {
                r._array[i] = vec._array[i] / sum;
            }

        return r;
    }

    // In VC8 : min and max are already defined by a #define...
#ifdef min
#undef min
#endif
#ifdef max
#undef max
#endif
    //componentwise min
    template< class T>
    inline T min(const T &lhs, const T &rhs)
    {
        T rt;

        for (int i = 0; i < lhs.size(); i++)
        {
            rt._array[i] = std::min(lhs._array[i], rhs._array[i]);
        }

        return rt;
    }

    // componentwise max
    template< class T>
    inline T max(const T &lhs, const T &rhs)
    {
        T rt;

        for (int i = 0; i < lhs.size(); i++)
        {
            rt._array[i] = std::max(lhs._array[i], rhs._array[i]);
        }

        return rt;
    }


};

#endif

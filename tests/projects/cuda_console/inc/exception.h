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

/* CUda UTility Library */
#ifndef _EXCEPTION_H_
#define _EXCEPTION_H_

// includes, system
#include <exception>
#include <stdexcept>
#include <iostream>
#include <stdlib.h>

//! Exception wrapper.
//! @param Std_Exception Exception out of namespace std for easy typing.
template<class Std_Exception>
class Exception : public Std_Exception
{
    public:

        //! @brief Static construction interface
        //! @return Alwayss throws ( Located_Exception<Exception>)
        //! @param file file in which the Exception occurs
        //! @param line line in which the Exception occurs
        //! @param detailed details on the code fragment causing the Exception
        static void throw_it(const char *file,
                             const int line,
                             const char *detailed = "-");

        //! Static construction interface
        //! @return Alwayss throws ( Located_Exception<Exception>)
        //! @param file file in which the Exception occurs
        //! @param line line in which the Exception occurs
        //! @param detailed details on the code fragment causing the Exception
        static void throw_it(const char *file,
                             const int line,
                             const std::string &detailed);

        //! Destructor
        virtual ~Exception() throw();

    private:

        //! Constructor, default (private)
        Exception();

        //! Constructor, standard
        //! @param str string returned by what()
        Exception(const std::string &str);

};

////////////////////////////////////////////////////////////////////////////////
//! Exception handler function for arbitrary exceptions
//! @param ex exception to handle
////////////////////////////////////////////////////////////////////////////////
template<class Exception_Typ>
inline void
handleException(const Exception_Typ &ex)
{
    std::cerr << ex.what() << std::endl;

    exit(EXIT_FAILURE);
}

//! Convenience macros

//! Exception caused by dynamic program behavior, e.g. file does not exist
#define RUNTIME_EXCEPTION( msg) \
    Exception<std::runtime_error>::throw_it( __FILE__, __LINE__, msg)

//! Logic exception in program, e.g. an assert failed
#define LOGIC_EXCEPTION( msg) \
    Exception<std::logic_error>::throw_it( __FILE__, __LINE__, msg)

//! Out of range exception
#define RANGE_EXCEPTION( msg) \
    Exception<std::range_error>::throw_it( __FILE__, __LINE__, msg)

////////////////////////////////////////////////////////////////////////////////
//! Implementation

// includes, system
#include <sstream>

////////////////////////////////////////////////////////////////////////////////
//! Static construction interface.
//! @param  Exception causing code fragment (file and line) and detailed infos.
////////////////////////////////////////////////////////////////////////////////
/*static*/ template<class Std_Exception>
void
Exception<Std_Exception>::
throw_it(const char *file, const int line, const char *detailed)
{
    std::stringstream s;

    // Quiet heavy-weight but exceptions are not for
    // performance / release versions
    s << "Exception in file '" << file << "' in line " << line << "\n"
      << "Detailed description: " << detailed << "\n";

    throw Exception(s.str());
}

////////////////////////////////////////////////////////////////////////////////
//! Static construction interface.
//! @param  Exception causing code fragment (file and line) and detailed infos.
////////////////////////////////////////////////////////////////////////////////
/*static*/ template<class Std_Exception>
void
Exception<Std_Exception>::
throw_it(const char *file, const int line, const std::string &msg)
{
    throw_it(file, line, msg.c_str());
}

////////////////////////////////////////////////////////////////////////////////
//! Constructor, default (private).
////////////////////////////////////////////////////////////////////////////////
template<class Std_Exception>
Exception<Std_Exception>::Exception() :
    Std_Exception("Unknown Exception.\n")
{ }

////////////////////////////////////////////////////////////////////////////////
//! Constructor, standard (private).
//! String returned by what().
////////////////////////////////////////////////////////////////////////////////
template<class Std_Exception>
Exception<Std_Exception>::Exception(const std::string &s) :
    Std_Exception(s)
{ }

////////////////////////////////////////////////////////////////////////////////
//! Destructor
////////////////////////////////////////////////////////////////////////////////
template<class Std_Exception>
Exception<Std_Exception>::~Exception() throw() { }

// functions, exported

#endif // #ifndef _EXCEPTION_H_


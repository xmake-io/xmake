
#ifndef CMARK_EXPORT_H
#define CMARK_EXPORT_H

#ifdef CMARK_STATIC_DEFINE
#  define CMARK_EXPORT
#  define CMARK_NO_EXPORT
#else
#  ifndef CMARK_EXPORT
#    ifdef cmark_EXPORTS
        /* We are building this library */
#      define CMARK_EXPORT 
#    else
        /* We are using this library */
#      define CMARK_EXPORT 
#    endif
#  endif

#  ifndef CMARK_NO_EXPORT
#    define CMARK_NO_EXPORT 
#  endif
#endif

#ifndef CMARK_DEPRECATED
#  define CMARK_DEPRECATED __declspec(deprecated)
#endif

#ifndef CMARK_DEPRECATED_EXPORT
#  define CMARK_DEPRECATED_EXPORT CMARK_EXPORT CMARK_DEPRECATED
#endif

#ifndef CMARK_DEPRECATED_NO_EXPORT
#  define CMARK_DEPRECATED_NO_EXPORT CMARK_NO_EXPORT CMARK_DEPRECATED
#endif

#if 0 /* DEFINE_NO_DEPRECATED */
#  ifndef CMARK_NO_DEPRECATED
#    define CMARK_NO_DEPRECATED
#  endif
#endif

#endif /* CMARK_EXPORT_H */

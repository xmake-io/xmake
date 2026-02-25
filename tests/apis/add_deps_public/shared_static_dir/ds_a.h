#ifndef DS_A_H
#define DS_A_H

#if defined(_WIN32)
#define DS_A_EXPORT __declspec(dllexport)
#define DS_A_IMPORT __declspec(dllimport)
#elif defined(__GNUC__) && ((__GNUC__ >= 4) || (__GNUC__ == 3 && __GNUC_MINOR__ >= 3))
#define DS_A_EXPORT __attribute__((visibility("default")))
#define DS_A_IMPORT
#else
#define DS_A_EXPORT
#define DS_A_IMPORT
#endif

#ifdef DS_A_BUILD
#define DS_A_API DS_A_EXPORT
#else
#define DS_A_API DS_A_IMPORT
#endif

DS_A_API int ds_get_a(void);

#endif

#ifndef ROSETTABOY_COMMON_H
#define ROSETTABOY_COMMON_H

#ifdef __cplusplus
#define BEGIN_EXTERN_C() extern "C" {
#define END_EXTERN_C() }
#else
#define BEGIN_EXTERN_C()
#define END_EXTERN_C()
#endif

#if defined(__GNUC__) && __GNUC__ >= 3
#define HAVE_NORETURN
#define NORETURN __attribute__((noreturn))
#else
#define NORETURN
#endif

#endif

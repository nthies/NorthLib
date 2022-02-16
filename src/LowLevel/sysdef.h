//
//  sysdef.h
//

#ifndef sysdef_h
#define sysdef_h

#ifdef __cplusplus

// C++ definitions
# define BeginCLinkage extern "C" {
# define EndCLinkage }

template<class C> C min(C a, C b) { return (a < b)? a : b; } 
template<class C> C max(C a, C b) { return (a > b)? a : b; } 

#else

// C definitions
# define BeginCLinkage 
# define EndCLinkage

#endif /* __cplusplus */

#ifdef NIL
# undef NIL
#endif

#define NIL ((void *)0)

#endif /* sysdef_h */

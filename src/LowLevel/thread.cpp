//
//  thread.cpp
//  NorthLib
//
//  Created by Norbert Thies on 30.06.21.
//  Copyright © 2021 Norbert Thies. All rights reserved.
//

#include "thread.h"

static pthread_t _thread_main = thread_current();
static unsigned long _thread_main_id = thread_id(thread_current());

pthread_t thread_main() { return _thread_main; }
unsigned long thread_main_id() { return _thread_main_id; }

unsigned long thread_id(pthread_t thread) {
# if defined(__APPLE__)
    mach_port_t mtid = pthread_mach_thread_np(pthread_self());
    return (unsigned long) mtid;
# else
    pthread_id_np_t ptid;
    pthread_getunique_np(&thread, &ptid);
    return (unsigned long) ptid;
# endif
}

pthread_t thread_current() {
  return pthread_self();
}

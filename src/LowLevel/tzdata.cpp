//
//  tzdata.cpp
//
//  Created by Norbert Thies on 07.02.2022
//  Copyright © 2022 Norbert Thies. All rights reserved.
//

#include  <time.h>
#include  <sys/time.h>
#include  "tzdata.h"

// Return daylight saving difference in February or August of the current year
static int diff(bool is_august = false) {
  time_t now;
  time(&now);
  struct tm t;
  localtime_r(&now, &t);
  t.tm_mday = 1;
  t.tm_mon = is_august? 7 : 1;
  t.tm_hour = 12;
  t.tm_min = t.tm_sec = 0;
  t.tm_isdst = 0;
  time_t std = mktime(&t);
  t.tm_isdst = 1;
  time_t dst = mktime(&t);
  return (int)(dst-std);
}

/// Return some data about the local timezone
const tzdata_t *tz_get() {
  static tzdata_t tzdata;
  if (!(tzdata.tz_std_name)) {
    tzset();
    tzdata.tz_std_name = tzname[0];
    tzdata.tz_dst_name = tzname[1];
    tzdata.tz_std_offset = (int)timezone;
    int tmp = diff();
    if (!tmp) tmp = diff(true);
    tzdata.tz_dst_offset = (int)timezone + tmp;
  }
  return &tzdata;
}


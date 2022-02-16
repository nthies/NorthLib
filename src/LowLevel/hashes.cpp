//
//  hashes.c
//
//  Created by Norbert Thies on 05.09.19.
//  Copyright © 2019 Norbert Thies. All rights reserved.
//

#include <CommonCrypto/CommonDigest.h>
#include <stdlib.h>
#include "hashes.h"

static const char *hexdigits = "0123456789abcdef";

/// Converts a byte stream into an allocated string of hex digits.
char *data_toHex(const void *data, size_t len) {
  const unsigned char *p = (unsigned char *) data;
  int i, n = (int) len;
  unsigned char *ret = (unsigned char *) malloc( 2*n + 1 ), *d = ret;
  for ( i = 0; i < n; i++, p++ ) {
    unsigned low = *p & 0x0f, high = (*p & 0xf0) >> 4;
    *d++ = hexdigits[high];
    *d++ = hexdigits[low];
  }
  *d = 0;
  return (char *)ret;
}

/// Returns the md5 sum of the passed byte array in hex representation
/// as allocated string.
char *hash_md5(const void *data, size_t len) {
  unsigned l = CC_MD5_DIGEST_LENGTH;
  unsigned char buff[l];
  CC_MD5( data, (CC_LONG)len, buff );
  return data_toHex(buff, l);
}

/// Returns the sha1 sum of the passed byte array in hex representation
/// as allocated string.
char *hash_sha1(const void *data, size_t len) {
  unsigned l = CC_SHA1_DIGEST_LENGTH;
  unsigned char buff[l];
  CC_SHA1( data, (CC_LONG)len, buff );
  return data_toHex(buff, l);
}

/// Returns the sha256 sum of the passed byte array in hex representation
/// as allocated string.
char *hash_sha256(const void *data, size_t len) {
  unsigned l = CC_SHA256_DIGEST_LENGTH;
  unsigned char buff[l];
  CC_SHA256( data, (CC_LONG)len, buff );
  return data_toHex(buff, l);
}

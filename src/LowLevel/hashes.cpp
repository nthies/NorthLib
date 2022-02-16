//
//  hashes.c
//
//  Created by Norbert Thies on 05.09.19.
//  Copyright © 2019 Norbert Thies. All rights reserved.
//

#if defined(__APPLE__)
#  include <CommonCrypto/CommonDigest.h>
#  define MD5_DIGEST_LENGTH    CC_MD5_DIGEST_LENGTH
#  define SHA1_DIGEST_LENGTH   CC_SHA1_DIGEST_LENGTH
#  define SHA256_DIGEST_LENGTH CC_SHA256_DIGEST_LENGTH
#  define MD5    CC_MD5
#  define SHA1   CC_SHA1
#  define SHA256 CC_SHA256
#else
#  include <openssl/sha.h>
#  include <openssl/md5.h>
#endif /* __APPLE__ */

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
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
char *hash_md5(const void *data, size_t len) {
  unsigned l = MD5_DIGEST_LENGTH;
  unsigned char buff[l];
  MD5( data, (CC_LONG)len, buff );
  return data_toHex(buff, l);
}
#pragma clang diagnostic pop

/// Returns the sha1 sum of the passed byte array in hex representation
/// as allocated string.
char *hash_sha1(const void *data, size_t len) {
  unsigned l = SHA1_DIGEST_LENGTH;
  unsigned char buff[l];
  SHA1( data, (CC_LONG)len, buff );
  return data_toHex(buff, l);
}

/// Returns the sha256 sum of the passed byte array in hex representation
/// as allocated string.
char *hash_sha256(const void *data, size_t len) {
  unsigned l = SHA256_DIGEST_LENGTH;
  unsigned char buff[l];
  SHA256( data, (CC_LONG)len, buff );
  return data_toHex(buff, l);
}

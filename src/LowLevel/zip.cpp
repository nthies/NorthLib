#include <zlib.h>
#include "zip.hh"

#undef DEBUG

// a simple debug macro
#ifdef DEBUG

#  define debug(fmt,...) \
     printf("%s(%d): ", __FUNCTION__, __LINE__); \
     printf(fmt, __VA_ARGS__);

#  define pbytes(data,len) { \
     tByte *ptr = data; \
     int l = (len>16)? 16 : len; \
     while (l-- > 0) printf( "%02x ", (unsigned)(*ptr++) ); \
     printf( "\n" ); \
    }

#else

#  define debug(fmt,...)
#  define pbytes(ptr,len)

#endif

namespace zip {

typedef unsigned char tByte;
typedef struct { tByte low, high; } tByte2;
typedef struct { tByte2 low, high; } tByte4;

unsigned bytes2number( tByte2 val ) 
  { return val.low | (val.high << 8); }
unsigned bytes2number( tByte4 val )
  { return bytes2number(val.low) | (bytes2number(val.high) << 16); }


/**
 *  DataDescriptor of a file in a zip archive (trailing the file data)
 */

class DataDescriptor {

  friend class Header;
  private:
  tByte4 _signature;	// 0x08074b50 
  tByte4 _crc32;	// CRC-32 checksum
  tByte4 _csize;	// compressed file size
  tByte4 _size;		// uncompressed file size

  public:
  static const tByte signature[4];

  unsigned crc32(void) const { return bytes2number(_crc32); }
  unsigned csize(void) const { return bytes2number(_csize); }
  unsigned size(void) const { return bytes2number(_size); }

};  // class DataDescriptor


/**
 *  Header of a file stored in a zip archive
 *  (local file header)
 *  A zip file header consists of a fixed length part, a variable file name
 *  (wthout trailing zero-byte) and a variable length "extra field".
 */

class Header {

  private:
  tByte4 _signature;	// 0x04034b50 
  tByte2 _version;	// version of PKZIP specification needed to extract
  tByte2 _flags;	// bit flags
  tByte2 _compression;	// compression method used
  tByte2 _mtime;	// DOS modification time
  tByte2 _mdate;	// DOS modification date
  tByte4 _crc32;	// CRC-32 checksum
  tByte4 _csize;	// compressed file size
  tByte4 _size;		// uncompressed file size
  tByte2 _fnlength;	// length of file name
  tByte2 _extralength;	// length of extra field

  public:
  static const tByte signature[4];

  // flags values and bit masks
  enum {
    Encrypted		= 1,	// encrypted file
    Imploded8k		= 2,	// imploding: 8k sliding dictionary
    Imploded3sf		= 4,	// imploding: 3 Shannon-Fano trees
    DeflateMask		= 6,	// bit mask for deflate mode
    DeflateNormal	= 0,	// normal deflation
    DeflateMax		= 2,	// maximum compression
    DeflateFast		= 4,	// fast compression
    DeflateSFast	= 6,	// super fast compression
    LzmaEOSused		= 2,	// LZMA compression EOS used
    DescriptorUsed	= 8,	// crc32 and sizes after file in data descriptor
    PatchedData		= 32,	// file is compressed patched data
    StrongEncryption	= 64,	// strong encryption used
    Utf8Encoded		= 2048	// UTF-8 encoding used for file name
  };

  // Compression values
  enum {
    Stored		= 0,	// no compression
    Shrunk		= 1,	// file is shrunk
    Reduced1		= 2,	// reduced with compression factor 1
    Reduced2		= 3,	// reduced with compression factor 2
    Reduced3		= 4,	// reduced with compression factor 3
    Reduced4		= 5,	// reduced with compression factor 4
    Imploded		= 6,	// file is imploded
    Deflated		= 8,	// file is deflated
    Deflated64		= 9,	// enhanced deflating
    LibImploded		= 10,	// data compression library imploding
    Bzip2		= 12,	// bzip2 data compression
    Lzma		= 14,	// LZMA data compression
    IbmTerse		= 18,	// IBM Terse data compression
    Lz77		= 19,	// IBM LZ77 data compression
    WavPack		= 97,	// WavPack compression
    PPMd		= 98	// PPMd compression
  };

  unsigned flags(void) const { return bytes2number(_flags); }
  unsigned compression(void) const { return bytes2number(_compression); }
  unsigned crc32(void) const { return bytes2number(_crc32); }
  unsigned csize(void) const { return bytes2number(_csize); }
  unsigned size(void) const { return bytes2number(_size); }
  unsigned fnlength(void) const { return bytes2number(_fnlength); }
  unsigned extralength(void) const { return bytes2number(_extralength); }
  unsigned hsize(void) const
    { return sizeof(Header) + fnlength() + extralength(); }

  void setDataDescriptor( DataDescriptor *dd )
    { _size = dd -> _size; _csize = dd -> _csize; _crc32 = dd -> _crc32; }

  int hasSize(void) const { return !(flags() & DescriptorUsed); }

  int toAscii( char *buff, int len );

};  // class Header


// zip Header and DataDescriptor signatures:
const tByte Header::signature[] = { 0x50, 0x4b, 0x03, 0x04 };
const tByte DataDescriptor::signature[] = { 0x50, 0x4b, 0x07, 0x08 };


/**
 *  A Buffer is used to store data read and to scan for the signature
 *  of a zip file in a zip archive.
 */

class Buffer {

  public:
  tByte		*_buffer;	// allocated storage
  int		 _size;		// current buffer size
  int		 _len;		// #bytes copied to _buffer
  tByte		*_dd;		// data descriptor if != 0
  int		 _flags;	// operation flags
  const tByte	*_data;		// pointer to data to read
  int		 _dlen;		// remainig #byte in data buffer
  const tByte	*_signature;	// 4 byte signature to check against
  int		 _slen;		// #bytes of signature checked

  // _flags values:
  enum {
    Skiping	=	1,	// skip to signature
    Copying	=	2,	// copy until signature
    FileFound	= 	1024	// file has been successfully read
  };

  // resets the buffer
  void reset() { _len = 0; _flags = 0; _dd = 0; }

  // initializes empty buffer
  Buffer( void ) { _buffer = 0; _size = 0; reset(); }

  // ~Buffer releases allocated data
  ~Buffer() { if ( _buffer ) free( _buffer ); _buffer = 0; _size = 0; reset(); }

  // Header read?
  int isHeader( void ) const { return (_len >= sizeof(Header)); }

  // #bytes needed to complete file
  int needed( void ) const {
    return ( isHeader()? ( header()->hsize() + 
                           ( header()->hasSize()? header()->csize() : 0 ) )
	                 : sizeof(Header) ) - _len;
  }

  // returns Pointer to Header
  Header *header( void ) const { return (Header *) _buffer; }

  // returns Pointer to DataDescriptor
  DataDescriptor *dataDescriptor( void ) const
    { return (DataDescriptor *) _dd; }

  // returns Pointer to file contents
  tByte *contents( void ) const {
    return _buffer + header()->hsize();
  }

  // returns true if zip file was found and stored
  int fileFound( void ) const { return _flags & FileFound; }

  // increases buffer
  void reserveSpace( int size = 20*1024 );

  // skip until a signature has been found
  void skip ( void );

  // define signature to skip to
  void skipUntil( const tByte *signature );

  // copy bytes until a signature has been found
  void copy ( void );

  // define signature to copy to
  void copyUntil( const tByte *signature );

  // search for Header signature
  void scanForHeader( void );

  // adds data to the buffer and scans for zip file
  void addData( const char **data, int *len );

  // copies bytes to the buffer
  int copyBytes( int nbytes = -1 );

  // copies data of a zip file with known size
  void copySized( void );

  // copies data of a zip file with unknown size
  void copyUnsized( void );

  // allocated file name
  char *heapFilename( void ) const;

}; // class Buffer

void Buffer::reserveSpace( int size ) {
  if ( size < 4 ) size += 4;
  if ( _buffer ) {
    if ( (_size - _len) < (size + 4) ) {
      int dd_offset = 0;
      if ( _dd ) dd_offset = (int)(_dd - _buffer);
      _size = _size + size * 2;
      _buffer = (tByte *) realloc( _buffer, _size * sizeof(tByte) );
      if ( _dd ) _dd = _buffer + dd_offset;
  } }
  else _buffer = (tByte *) malloc( (_size = size + 4) * sizeof(tByte) );
  if ( !_buffer ) throw Exception();
}

void Buffer::skip( void ) {
  while ( _dlen > 0 ) {
    if ( _signature[_slen] == *_data++ ) _slen++;
    else _slen = 0;
    _dlen--;
    if ( _slen == 4 ) {
      // signature found, copy it to _buffer
      memcpy( _buffer + _len, _signature, 4 );
      _len += 4;
      _flags &= ~Skiping;
      return;
} } }

void Buffer::skipUntil( const tByte *signature ) {
  _signature = signature;
  _slen = 0;
  _flags |= Skiping;
}

void Buffer::copy( void ) {
  while ( _dlen > 0 ) {
    _buffer[_len++] = *_data;
    _dlen--;
    if ( _signature[_slen] == *_data++ ) _slen++;
    else _slen = 0;
    if ( _slen == 4 ) {
      // signature found, terminate copying
      _flags &= ~Copying;
      return;
} } }

void Buffer::copyUntil( const tByte *signature ) {
  _signature = signature;
  _slen = 0;
  _flags |= Copying;
}

void Buffer::scanForHeader( void ) {
  if ( _len == 0 ) skipUntil( Header::signature );
  if ( _flags & Skiping ) skip();
  if ( _dlen > 0 ) {
    int to_copy = sizeof(Header) - _len;
    if ( to_copy > _dlen ) to_copy = _dlen;
    memcpy( _buffer + _len, _data, to_copy );
    _len += to_copy;
    _data += to_copy;
    _dlen -= to_copy;
} }

void Buffer::addData( const char **buff, int *blen ) {
  if ( (*blen <= 0) || fileFound() ) return;
  reserveSpace( *blen );
  _data = (const tByte *) *buff;
  _dlen = *blen;
  if ( !isHeader() ) scanForHeader();
  if ( _dlen > 0 ) {
    if ( header() -> hasSize() ) copySized();
    else copyUnsized();
  }
  *buff = (const char *) _data;
  *blen = _dlen;
}

int Buffer::copyBytes( int need ) {
  int to_copy = 0;
  if ( need < 0 ) need = needed();
  if ( need > 0 ) {
    to_copy = (need < _dlen)? need : _dlen;
    memcpy( _buffer + _len, _data, to_copy );
    _data += to_copy;
    _dlen -= to_copy;
    _len += to_copy;
  }
  return to_copy;
}

void Buffer::copySized( void ) {
  copyBytes();
  if ( needed() == 0 ) _flags |= FileFound;
}

void Buffer::copyUnsized( void ) {
  if ( !_dd && !(_flags & Copying) ) copyUntil( DataDescriptor::signature );
  if ( _flags & Copying ) copy();
  if ( _dlen > 0 ) {
    if( !_dd ) _dd = _buffer + _len - 4;
    int to_copy = (int)( sizeof(DataDescriptor) - (_len - (_dd - _buffer)) );
    if ( to_copy == copyBytes( to_copy ) ) {
      header() -> setDataDescriptor( dataDescriptor() );
      _flags |= FileFound;
} } }

char *Buffer::heapFilename( void ) const {
  char *ret = 0;
  if ( isHeader() ) {
    int l = header() -> fnlength();
    ret = (char *) malloc( (l+1) * sizeof(char) );
    if ( ret ) {
      memcpy( ret, _buffer + sizeof(Header), l * sizeof(char) );
      ret[l] = '\0';
  } }
  return ret;
}


/**
 *  Header::toAscii writes an ascii representation of a zip Header to 
 *  the given buffer.
 */

int Header::toAscii( char *buff, int olen ) {
  const char *compr = "";
  int len = olen;
  switch ( compression() ) {
    case Stored:	compr = "Stored"; break;
    case Shrunk:	compr = "Shrunk"; break;
    case Reduced1:	compr = "Reduced1"; break;
    case Reduced2:	compr = "Reduced2"; break;
    case Reduced3:	compr = "Reduced3"; break;
    case Reduced4:	compr = "Reduced4"; break;
    case Imploded:	compr = "Imploded"; break;
    case Deflated:	compr = "Deflated"; break;
    case Deflated64:	compr = "Deflated64"; break;
    case LibImploded:	compr = "LibImploded"; break;
    case Bzip2:		compr = "Bzip2"; break;
    case Lzma:		compr = "Lzma"; break;
    case IbmTerse:	compr = "IbmTerse"; break;
    case Lz77:		compr = "Lz77"; break;
    case WavPack:	compr = "WavPack"; break;
    case PPMd:		compr = "PPMd"; break;
  }
  int l = snprintf( buff, len, "%s", compr );
  buff += l; len -= l;
  if ( flags() & Encrypted ) {
    l = snprintf( buff, len, ", encrypted" );
    buff += l; len -= l;
  }
  if ( flags() & Utf8Encoded ) {
    l = snprintf( buff, len, ", utf8" );
    buff += l; len -= l;
  }
  if ( flags() & DescriptorUsed ) {
    l = snprintf( buff, len, ", +DataDescriptor" );
    buff += l; len -= l;
  }
  l = snprintf( buff, len, " (size=%u, %u compressed, crc32=0x%x)",
    size(), csize(), crc32() );
  buff += l; len -= l;
  return olen - len;
}


/**
 *  File::inflate decompresses a file stored in a zip archive.
 */

void File::inflate( void *buffer ) {
  Buffer *b = (Buffer *) buffer;
  Header *h = b -> header();
  int ret;
  z_stream zs;
  memset( &zs, 0, sizeof zs );
  if ( inflateInit2( &zs, -MAX_WBITS ) != Z_OK )
    throw Exception( "libz: inflateInit2 failed" );
  zs.next_in = b->contents();
  zs.next_out = (tByte *) _data;
  zs.avail_in = h->csize();
  zs.avail_out = h->size() + 4;
  switch ( ret = ::inflate( &zs, Z_FINISH ) ) {
    case Z_OK :
      throw Exception( "libz: incomplete deflated stream" );
    case Z_NEED_DICT :
      throw Exception( "libz: preset dictionary needed for inflate" );
    case Z_DATA_ERROR :
      throw Exception( "libz: corrupt inflate input" );
    case Z_MEM_ERROR :
      throw Exception( "libz: not enough memory for inflate" );
    case Z_BUF_ERROR :
      throw Exception( "libz: not enough space for inflate output" );
    case Z_STREAM_ERROR :
      throw Exception( "libz: argument error" );
    case Z_STREAM_END : {
      inflateEnd( &zs );
      // handle CRC32
      unsigned long crc = crc32( 0L, (tByte *) _data, h->size() );
      if ( crc != h->crc32() )
	throw Exception( "zip archive corrupt (CRC32 error)" );
      break;
    }
    default:
      debug( "inflate: %d\n", ret );
      throw Exception( "libz: unknown inflate error" );
} }


/**
 *  File::File takes a Buffer* (opaque) and uses libz-functions to 
 *  decompress the file in the Buffer-object.
 */

File::File( void *buffer ) {
  Buffer *b = (Buffer *) buffer;
  Header *h = b -> header();
  int datasize = h->hsize() + h->size() + 4;
  if ( !(_header = malloc( datasize )) ) throw Exception();
  memcpy( _header, h, h->hsize() );
  _name = b->heapFilename();
  if ( h->size() > 0 ) {
    // decompress file contents
    _data = ((tByte*) _header) + h->hsize();
    switch ( h->compression() ) {
      case Header::Stored : memcpy( _data, b->contents(), h->size() ); break;
      case Header::Deflated : inflate( buffer ); break;
      default: throw Exception( "unsupported compression" );
    }
  }
  else _data = 0;
}


/**
 *  The File::~File destructor releases all allocated data.
 */

File::~File() {
  if ( _header ) free( _header );
  if ( _name ) free( _name );
  _header = _data = 0;
  _name = 0;
}


/**
 *  File::size returns the file's size (uncompressed).
 */

int File::size( void ) const {
  return ((Header *)_header) -> size();
}


/**
 *  The default implementation of StreamDelegate::handleFile prints the file 
 *  name and some header data to stdout.
 */

void StreamDelegate::handleFile( File *file ) {
  char buff[1024];
  Header *h = (Header*)(file->header());
  h -> toAscii( buff, 1024 );
  printf( "%s: %s\n", file->name(), buff );
  fflush( stdout );
}


/**
 *  The Stream constructor allocates a Buffer object to store the read data 
 */

Stream::Stream( StreamDelegate &delegate ) {
  _delegate = &delegate;
  _buffer = new Buffer;
  _bytes_read = 0;
}


/**
 *  The Stream destructor releases all allocated structures.
 */

Stream::~Stream() {
  Buffer *b = (Buffer *) _buffer;
  _delegate = 0;
  if ( b ) delete b;
  _buffer = 0;
}


/**
 *  Stream::scan scans the given data for a zip file in a zip archive. If
 *  a complete file could be found, the File is passed to the StreamDelegate.
 */

void Stream::scan( const char *buff, int blen ) {
  Buffer *b = (Buffer *) _buffer;
  int bufflen = blen;
  while ( bufflen > 0 ) {
    b->addData( &buff, &bufflen );
    _bytes_read += (blen - bufflen);
    blen = bufflen;
    if ( b->fileFound() ) {
      File *f = new File( b );
      _delegate -> handleFile( f );
      b->reset();
} } }


} // namespace zip

#ifdef DEBUG

int main() {
  using namespace zip;
  try {
    StreamDelegate delegate;
    Stream stream( delegate );
    char buff[1024];
    int len;
    while ( (len = (int) fread( buff, 1, 1024, stdin)) > 0 ) {
      stream.scan( buff, len );
  } }
  catch ( Exception e ) {
    printf( "Exception: %s\n", e.what() );
    return 1;
  }
  return 0;
}

#endif

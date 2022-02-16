/** zip.hh
 *
 *  Defines some classes to scan and extract files from zip archives.
 *  Zip archives are defined in:
 *    http://www.pkware.com/documents/casestudies/APPNOTE.TXT
 *
 *  Every files in a zip archive is preceeded by a file header and
 *  is optionally succeeded by a data descriptor.
 *  A data descriptor has to be used if the file size and/or CRC hash sum are
 *  not defined in the header.
 *
 *  The main class defined here is a zip::Stream. A Stream object is given data
 *  from some byte stream representing a zip archive. When zip:Stream reads a 
 *  complete file from the data given to it, a method 'handleFile' of a class
 *  derived from the pure virtual class zip::StreamDelegate is called.
 *  This method is used to consume the file (e.g. in a different thread).
 *
 *  Typically zip::Stream is used as follows:
 *
 *    class MyDelegate : public zip::StreamDelegate {
 *      public:
 *      void handleFile( zip::File *file );
 *    };
 *
 *    MyDelegate delegate;
 *    zip::File file;
 *    zip::Stream zipstream( delegate );
 *    ...
 *    while ( !eof ) {
 *      // read data into buff (length bufflen)
 *      zipstream.scan( buff, bufflen );
 *    }
 *
 *  The zip::File *file parameter passed to MyDelegate::handleFile is allocated
 *  and must be deleted after use.
 *  Typically a 3-thread model may be used to receive, decompress and handle
 *  zipped files:
 *   
 *    - Thread 1 simply receives data and passes it to thread 2
 *    - Thread 2 processes the data via zip::Stream::scan, a file found
 *      is passed to zip::StreamDelegate::handleFile also in thread 2
 *    - handleFile passes the file for further processing to thread 3.
 *
 *  A zip file is structured as follows:
 *
 *    file header 1
 *    encryption header 1 (optional)
 *    file data 1
 *    data descriptor 1
 *    ------------------------------
 *      ...
 *    ------------------------------
 *    file header n
 *    encryption header n (optional)
 *    file data n
 *    data descriptor n
 *    ------------------------------
 *    archive decryption header
 *    archive extra data record
 *    ------------------------------
 *    central directory header 1
 *      ...
 *    central directory header n
 *    ------------------------------
 *    zip64 end of central directory record
 *    zip64 end of central directory locator
 *    end of central directory record
 *
 *  Encrypted zip files are currently not supported.
 */

#ifndef __zipfile_h
#define __zipfile_h

#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include <iostream>
#include <exception>

namespace zip {

// zip::Exception is thrown in case of errors:

class Exception : public std::exception {
  private:
  const char *_message;	// constant error message
  public:
  Exception( const char *msg = "Zipfile Error" ) { _message = msg; }
  const char *what( void ) const throw() { return _message; }
};


/**
 *  A file stored in a zip archive
 */

class File {
  friend class Stream;
  private:
  void		*_header;	// complete Header
  void		*_data;		// uncompressed data
  char		*_name;		// file name
  public:
  File( void *buffer );
  ~File();
  void inflate( void *buffer );
  void *data( void ) const { return _data; }
  void *header( void ) const { return _header; }
  int size( void ) const;
  const char *name( void ) const { return _name; }
}; // class File


/**
 * The virtual StreamDelegate class for handling scanned zip::File's.
 */

class StreamDelegate {
  public:
  // handleFile is called by zip::Stream when a file has been found
  virtual void handleFile( File *file );
};


/**
 *  The Stream class
 */

class Stream {
  private:
  void			*_buffer;	// opaque buffer for stream data
  long       _bytes_read; // bytes read so far
  StreamDelegate	*_delegate;	// delegate to inform
  public:
  Stream( StreamDelegate &delegate );
  ~Stream();
  void scan( const char *buff, int bufflen );
  long bytesRead ( void ) const { return _bytes_read; }
};


}; // namespace zip

#endif // __zipfile_h

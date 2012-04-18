require 'ffi'
require 'rbconfig'

module Curl
  # this does not implement the full curl lib. just what is needed for typhoeus

  def Curl.windows?
    !(RbConfig::CONFIG['host_os'] !~ /mingw|mswin|bccwin/)
  end

  extend FFI::Library

  VERSION_NOW			= 3

  GLOBAL_SSL			= 0x01
  GLOBAL_WIN32			= 0x02
  GLOBAL_ALL			= (GLOBAL_SSL | GLOBAL_WIN32)

  TYPE_LONG				= 0
  TYPE_OBJECTPOINT		= 10000
  TYPE_FUNCTIONPOINT	= 20000
  TYPE_OFF_T		 	= 30000

  # options
  OPT_FILE                        = TYPE_OBJECTPOINT		+ 1
  OPT_URL                         = TYPE_OBJECTPOINT		+ 2
  OPT_PORT                        = TYPE_LONG				+ 3
  OPT_PROXY                       = TYPE_OBJECTPOINT		+ 4
  OPT_USERPWD                     = TYPE_OBJECTPOINT		+ 5
  OPT_PROXYUSERPWD                = TYPE_OBJECTPOINT		+ 6
  OPT_RANGE                       = TYPE_OBJECTPOINT		+ 7
  OPT_INFILE                      = TYPE_OBJECTPOINT		+ 9
  OPT_ERRORBUFFER                 = TYPE_OBJECTPOINT		+ 10
  OPT_WRITEFUNCTION               = TYPE_FUNCTIONPOINT		+ 11
  OPT_READFUNCTION                = TYPE_FUNCTIONPOINT		+ 12
  OPT_TIMEOUT                     = TYPE_LONG				+ 13
  OPT_INFILESIZE                  = TYPE_LONG				+ 14
  OPT_POSTFIELDS                  = TYPE_OBJECTPOINT		+ 15
  OPT_REFERER                     = TYPE_OBJECTPOINT		+ 16
  OPT_FTPPORT                     = TYPE_OBJECTPOINT		+ 17
  OPT_USERAGENT                   = TYPE_OBJECTPOINT		+ 18
  OPT_LOW_SPEED_TIME              = TYPE_LONG				+ 20
  OPT_RESUME_FROM                 = TYPE_LONG				+ 21
  OPT_COOKIE                      = TYPE_OBJECTPOINT		+ 22
  OPT_HTTPHEADER                  = TYPE_OBJECTPOINT		+ 23
  OPT_HTTPPOST                    = TYPE_OBJECTPOINT		+ 24
  OPT_SSLCERT                     = TYPE_OBJECTPOINT		+ 25
  OPT_SSLCERTPASSWD               = TYPE_OBJECTPOINT		+ 26
  OPT_SSLKEYPASSWD                = TYPE_OBJECTPOINT		+ 26
  OPT_CRLF                        = TYPE_LONG				+ 27
  OPT_QUOTE                       = TYPE_OBJECTPOINT		+ 28
  OPT_WRITEHEADER                 = TYPE_OBJECTPOINT		+ 29
  OPT_COOKIEFILE                  = TYPE_OBJECTPOINT		+ 31
  OPT_SSLVERSION                  = TYPE_LONG				+ 32
  OPT_TIMECONDITION               = TYPE_LONG				+ 33
  OPT_TIMEVALUE                   = TYPE_LONG				+ 34
  OPT_CUSTOMREQUEST               = TYPE_OBJECTPOINT		+ 36
  OPT_STDERR                      = TYPE_OBJECTPOINT		+ 37
  OPT_POSTQUOTE                   = TYPE_OBJECTPOINT		+ 39
  OPT_WRITEINFO                   = TYPE_OBJECTPOINT		+ 40
  OPT_VERBOSE                     = TYPE_LONG				+ 41
  OPT_HEADER                      = TYPE_LONG				+ 42
  OPT_NOPROGRESS                  = TYPE_LONG				+ 43
  OPT_NOBODY                      = TYPE_LONG				+ 44
  OPT_FAILONERROR                 = TYPE_LONG				+ 45
  OPT_UPLOAD                      = TYPE_LONG				+ 46
  OPT_POST                        = TYPE_LONG				+ 47
  OPT_FTPLISTONLY                 = TYPE_LONG				+ 48
  OPT_FTPAPPEND                   = TYPE_LONG				+ 50
  OPT_NETRC                       = TYPE_LONG				+ 51
  OPT_FOLLOWLOCATION              = TYPE_LONG				+ 52
  OPT_TRANSFERTEXT                = TYPE_LONG				+ 53
  OPT_PUT                         = TYPE_LONG				+ 54
  OPT_PROGRESSFUNCTION            = TYPE_FUNCTIONPOINT		+ 56
  OPT_PROGRESSDATA                = TYPE_OBJECTPOINT		+ 57
  OPT_AUTOREFERER                 = TYPE_LONG				+ 58
  OPT_PROXYPORT                   = TYPE_LONG				+ 59
  OPT_POSTFIELDSIZE               = TYPE_LONG				+ 60
  OPT_HTTPPROXYTUNNEL             = TYPE_LONG				+ 61
  OPT_INTERFACE                   = TYPE_OBJECTPOINT		+ 62
  OPT_SSL_VERIFYPEER              = TYPE_LONG				+ 64
  OPT_CAINFO                      = TYPE_OBJECTPOINT		+ 65
  OPT_MAXREDIRS                   = TYPE_LONG				+ 68
  OPT_FILETIME                    = TYPE_LONG				+ 69
  OPT_TELNETOPTIONS               = TYPE_OBJECTPOINT		+ 70
  OPT_MAXCONNECTS                 = TYPE_LONG				+ 71
  OPT_CLOSEPOLICY                 = TYPE_LONG				+ 72
  OPT_FRESH_CONNECT               = TYPE_LONG				+ 74
  OPT_FORBID_REUSE                = TYPE_LONG				+ 75
  OPT_RANDOM_FILE                 = TYPE_OBJECTPOINT		+ 76
  OPT_EGDSOCKET                   = TYPE_OBJECTPOINT		+ 77
  OPT_CONNECTTIMEOUT              = TYPE_LONG				+ 78
  OPT_HEADERFUNCTION              = TYPE_FUNCTIONPOINT		+ 79
  OPT_HTTPGET                     = TYPE_LONG				+ 80
  OPT_SSL_VERIFYHOST              = TYPE_LONG				+ 81
  OPT_COOKIEJAR                   = TYPE_OBJECTPOINT		+ 82
  OPT_SSL_CIPHER_LIST             = TYPE_OBJECTPOINT		+ 83
  OPT_HTTP_VERSION                = TYPE_LONG				+ 84
  OPT_FTP_USE_EPSV                = TYPE_LONG				+ 85
  OPT_SSLCERTTYPE                 = TYPE_OBJECTPOINT		+ 86
  OPT_SSLKEY                      = TYPE_OBJECTPOINT		+ 87
  OPT_SSLKEYTYPE                  = TYPE_OBJECTPOINT		+ 88
  OPT_SSLENGINE                   = TYPE_OBJECTPOINT		+ 89
  OPT_SSLENGINE_DEFAULT           = TYPE_LONG				+ 90
  OPT_DNS_USE_GLOBAL_CACHE        = TYPE_LONG				+ 91
  OPT_DNS_CACHE_TIMEOUT           = TYPE_LONG				+ 92
  OPT_PREQUOTE                    = TYPE_OBJECTPOINT		+ 93
  OPT_DEBUGFUNCTION               = TYPE_FUNCTIONPOINT		+ 94
  OPT_DEBUGDATA                   = TYPE_OBJECTPOINT		+ 95
  OPT_COOKIESESSION               = TYPE_LONG				+ 96
  OPT_CAPATH                      = TYPE_OBJECTPOINT		+ 97
  OPT_BUFFERSIZE                  = TYPE_LONG				+ 98
  OPT_NOSIGNAL                    = TYPE_LONG				+ 99
  OPT_SHARE                       = TYPE_OBJECTPOINT		+ 100
  OPT_PROXYTYPE                   = TYPE_LONG				+ 101
  OPT_ENCODING                    = TYPE_OBJECTPOINT		+ 102
  OPT_PRIVATE                     = TYPE_OBJECTPOINT		+ 103
  OPT_UNRESTRICTED_AUTH           = TYPE_LONG				+ 105
  OPT_FTP_USE_EPRT                = TYPE_LONG				+ 106
  OPT_HTTPAUTH                    = TYPE_LONG				+ 107
  OPT_SSL_CTX_FUNCTION            = TYPE_FUNCTIONPOINT		+ 108
  OPT_SSL_CTX_DATA                = TYPE_OBJECTPOINT		+ 109
  OPT_FTP_CREATE_MISSING_DIRS     = TYPE_LONG				+ 110
  OPT_PROXYAUTH                   = TYPE_LONG				+ 111
  OPT_IPRESOLVE                   = TYPE_LONG				+ 113
  OPT_MAXFILESIZE                 = TYPE_LONG				+ 114
  OPT_INFILESIZE_LARGE            = TYPE_OFF_T				+ 115
  OPT_RESUME_FROM_LARGE           = TYPE_OFF_T				+ 116
  OPT_MAXFILESIZE_LARGE           = TYPE_OFF_T				+ 117
  OPT_NETRC_FILE                  = TYPE_OBJECTPOINT		+ 118
  OPT_FTP_SSL                     = TYPE_LONG				+ 119
  OPT_POSTFIELDSIZE_LARGE         = TYPE_OFF_T				+ 120
  OPT_TCP_NODELAY                 = TYPE_LONG				+ 121
  OPT_FTPSSLAUTH                  = TYPE_LONG				+ 129
  OPT_IOCTLFUNCTION               = TYPE_FUNCTIONPOINT		+ 130
  OPT_IOCTLDATA                   = TYPE_OBJECTPOINT		+ 131
  OPT_FTP_ACCOUNT                 = TYPE_OBJECTPOINT		+ 134
  OPT_COOKIELIST                  = TYPE_OBJECTPOINT		+ 135
  OPT_IGNORE_CONTENT_LENGTH       = TYPE_LONG				+ 136
  OPT_FTP_SKIP_PASV_IP            = TYPE_LONG				+ 137
  OPT_FTP_FILEMETHOD              = TYPE_LONG				+ 138
  OPT_LOCALPORT                   = TYPE_LONG				+ 139
  OPT_LOCALPORTRANGE              = TYPE_LONG				+ 140
  OPT_CONNECT_ONLY                = TYPE_LONG				+ 141
  OPT_CONV_FROM_NETWORK_FUNCTION  = TYPE_FUNCTIONPOINT  	+ 142
  OPT_CONV_TO_NETWORK_FUNCTION    = TYPE_FUNCTIONPOINT   	+ 143
  OPT_MAX_SEND_SPEED_LARGE        = TYPE_OFF_T			    + 145
  OPT_MAX_RECV_SPEED_LARGE        = TYPE_OFF_T			    + 146
  OPT_FTP_ALTERNATIVE_TO_USER     = TYPE_OBJECTPOINT		+ 147
  OPT_SOCKOPTFUNCTION             = TYPE_FUNCTIONPOINT	    + 148
  OPT_SOCKOPTDATA                 = TYPE_OBJECTPOINT		+ 149
  OPT_SSL_SESSIONID_CACHE         = TYPE_LONG				+ 150
  OPT_SSH_AUTH_TYPES              = TYPE_LONG				+ 151
  OPT_SSH_PUBLIC_KEYFILE          = TYPE_OBJECTPOINT		+ 152
  OPT_SSH_PRIVATE_KEYFILE         = TYPE_OBJECTPOINT		+ 153
  OPT_FTP_SSL_CCC                 = TYPE_LONG				+ 154
  OPT_TIMEOUT_MS                  = TYPE_LONG				+ 155
  OPT_CONNECTTIMEOUT_MS           = TYPE_LONG				+ 156
  OPT_HTTP_TRANSFER_DECODING      = TYPE_LONG				+ 157
  OPT_HTTP_CONTENT_DECODING       = TYPE_LONG				+ 158

  OPT_WRITEDATA                   = OPT_FILE
  OPT_READDATA                    = OPT_INFILE
  OPT_HEADERDATA                  = OPT_WRITEHEADER

  FormOption = enum [
    :none,
    :copy_name,
    :ptr_name,
    :name_length,
    :ptr_contents,
    :contents_length,
    :file_content,
    :array,
    :obsolete,
    :file,
    :buffer,
    :buffer_ptr,
    :buffer_length,
    :content_type,
    :content_header,
    :filename,
    :end,
    :obsolete2,
    :stream,
    :last]

  enum :easy_code, [:ok]

  enum :multi_code, [
    :call_multi_perform, -1,
    :ok,
    :bad_handle,
    :bad_easy_handle,
    :out_of_memory,
    :internal_error,
    :bad_socket,
    :unknown_option,
    :last]

  enum :msg_code, [:none, :done, :last]

  class FDSet < FFI::Struct
    FD_SETSIZE = 524288 # set a higher maximum number of fds. this has never applied to windows, so just use the default there

    if Curl.windows?
      layout :fd_count, :u_int,
             :fd_array, [:u_int, 64] # 2048 FDs
    else
      layout :fds_bits, [:long, FD_SETSIZE / FFI::Type::LONG.size]
    end
  end

  class MsgData < FFI::Union
    layout :whatever, :pointer,
           :code, :easy_code
  end

=begin
struct CURLMsg {
  CURLMSG msg; /* what this message means */  
  CURL *easy_handle; /* the handle it concerns */  
  union {   
    void *whatever; /* message-specific data */   
    CURLcode result; /* return code for transfer */  
  } data; 
};
=end
  class Msg < FFI::Struct
    layout :code, :msg_code,
           :easy_handle, :pointer,
           :data, MsgData
  end

  class Slist < FFI::Struct
    layout :data, :string,
           :next, :pointer
  end

  class Timeval < FFI::Struct
    layout :sec, :time_t,
           :usec, :suseconds_t
  end

  callback :callback, [:pointer, :size_t, :size_t, :pointer], :size_t

  ffi_lib 'libcurl'

  attach_function :global_init, :curl_global_init, [:long], :int

  attach_function :easy_init, :curl_easy_init, [], :pointer
  attach_function :easy_cleanup, :curl_easy_cleanup, [:pointer], :void
  attach_function :easy_getinfo, :curl_easy_getinfo, [:pointer, :int, :pointer], :easy_code
  attach_function :easy_setopt, :curl_easy_setopt, [:pointer, :int, :pointer], :easy_code
  attach_function :easy_setopt_string, :curl_easy_setopt, [:pointer, :int, :string], :easy_code
  attach_function :easy_setopt_long, :curl_easy_setopt, [:pointer, :int, :long], :easy_code
  attach_function :easy_setopt_callback, :curl_easy_setopt, [:pointer, :int, :callback], :easy_code
  attach_function :easy_perform, :curl_easy_perform, [:pointer], :easy_code
  attach_function :easy_strerror, :curl_easy_strerror, [:int], :string
  attach_function :easy_escape, :curl_easy_escape, [:pointer, :pointer, :int], :string
  attach_function :easy_reset, :curl_easy_reset, [:pointer], :void

  attach_function :formadd, :curl_formadd, [:pointer, :pointer, :varargs], :int

  attach_function :multi_init, :curl_multi_init, [], :pointer
  attach_function :multi_add_handle, :curl_multi_add_handle, [:pointer, :pointer], :multi_code
  attach_function :multi_remove_handle, :curl_multi_remove_handle, [:pointer, :pointer], :multi_code
  attach_function :multi_info_read, :curl_multi_info_read, [:pointer, :pointer], Msg.ptr
  attach_function :multi_perform, :curl_multi_perform, [:pointer, :pointer], :multi_code
  attach_function :multi_timeout, :curl_multi_timeout, [:pointer, :pointer], :multi_code
  attach_function :multi_fdset, :curl_multi_fdset, [:pointer, FDSet.ptr, FDSet.ptr, FDSet.ptr, :pointer], :multi_code
  attach_function :multi_strerror, :curl_multi_strerror, [:int], :string

  attach_function :version, :curl_version, [], :string
  attach_function :slist_append, :curl_slist_append, [Slist, :string], Slist.ptr
  attach_function :slist_free_all, :curl_slist_free_all, [Slist], :void

  ffi_lib (windows? ? 'ws2_32' : FFI::Library::LIBC)
  @blocking = true
  attach_function :select, [:int, FDSet.ptr, FDSet.ptr, FDSet.ptr, Timeval.ptr], :int

  class Exception; end

  @@initialized = false
  @@init_mutex = Mutex.new

  def Curl.init
    # ensure curl lib is initialised. not thread-safe so must be wrapped in a mutex
    @@init_mutex.synchronize {
      if not @@initialized
        raise Exception.new('curl failed to initialise') if Curl.global_init(GLOBAL_ALL) != 0
        @@initialized = true
      end
    }
  end
end
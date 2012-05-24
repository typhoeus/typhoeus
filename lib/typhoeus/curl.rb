require 'ffi'
require 'rbconfig'
require 'thread'

module Typhoeus
  module Curl
    # this does not implement the full curl lib. just what is needed for typhoeus

    def Curl.windows?
      !(RbConfig::CONFIG['host_os'] !~ /mingw|mswin|bccwin/)
    end

    extend ::FFI::Library

    VERSION_NOW = 3

    GLOBAL_SSL     = 0x01
    GLOBAL_WIN32   = 0x02
    GLOBAL_ALL     = (GLOBAL_SSL | GLOBAL_WIN32)
    GLOBAL_DEFAULT = GLOBAL_ALL

    EasyCode = enum :easy_code, [
      :ok,
      :unsupported_protocol,
      :failed_init,
      :url_malformat,
      :not_built_in,
      :couldnt_resolve_proxy,
      :couldnt_resolve_host,
      :couldnt_connect,
      :ftp_weird_server_reply,
      :remote_access_denied,
      :ftp_accept_failed,
      :ftp_weird_pass_reply,
      :ftp_accept_timeout,
      :ftp_weird_pasv_reply,
      :ftp_weird_227_format,
      :ftp_cant_get_host,
      :obsolete16,
      :ftp_couldnt_set_type,
      :partial_file,
      :ftp_couldnt_retr_file,
      :obsolete20,
      :quote_error,
      :http_returned_error,
      :write_error,
      :obsolete24,
      :upload_failed,
      :read_error,
      :out_of_memory,
      :operation_timedout,
      :obsolete29,
      :ftp_port_failed,
      :ftp_couldnt_use_rest,
      :obsolete32,
      :range_error,
      :http_post_error,
      :ssl_connect_error,
      :bad_download_resume,
      :file_couldnt_read_file,
      :ldap_cannot_bind,
      :ldap_search_failed,
      :obsolete40,
      :function_not_found,
      :aborted_by_callback,
      :bad_function_argument,
      :obsolete44,
      :interface_failed,
      :obsolete46,
      :too_many_redirects ,
      :unknown_option,
      :telnet_option_syntax ,
      :obsolete50,
      :peer_failed_verification,
      :got_nothing,
      :ssl_engine_notfound,
      :ssl_engine_setfailed,
      :send_error,
      :recv_error,
      :obsolete57,
      :ssl_certproblem,
      :ssl_cipher,
      :ssl_cacert,
      :bad_content_encoding,
      :ldap_invalid_url,
      :filesize_exceeded,
      :use_ssl_failed,
      :send_fail_rewind,
      :ssl_engine_initfailed,
      :login_denied,
      :tftp_notfound,
      :tftp_perm,
      :remote_disk_full,
      :tftp_illegal,
      :tftp_unknownid,
      :remote_file_exists,
      :tftp_nosuchuser,
      :conv_failed,
      :conv_reqd,
      :ssl_cacert_badfile,
      :remote_file_not_found,
      :ssh,
      :ssl_shutdown_failed,
      :again,
      :ssl_crl_badfile,
      :ssl_issuer_error,
      :ftp_pret_failed,
      :rtsp_cseq_error,
      :rtsp_session_error,
      :ftp_bad_file_list,
      :chunk_failed,
      :last]

    MultiCode = enum :multi_code, [
      :call_multi_perform, -1,
      :ok,
      :bad_handle,
      :bad_easy_handle,
      :out_of_memory,
      :internal_error,
      :bad_socket,
      :unknown_option,
      :last]

    OptionType = enum [
      :long,           0,
      :object_point,   10000,
      :function_point, 20000,
      :off_t,          30000]

    Option = enum :option, [
      :file,                         OptionType[:object_point]   + 1,
      :writedata,                    OptionType[:object_point]   + 1,
      :url,                          OptionType[:object_point]   + 2,
      :port,                         OptionType[:long]           + 3,
      :proxy,                        OptionType[:object_point]   + 4,
      :userpwd,                      OptionType[:object_point]   + 5,
      :proxyuserpwd,                 OptionType[:object_point]   + 6,
      :range,                        OptionType[:object_point]   + 7,
      :infile,                       OptionType[:object_point]   + 9,
      :readdata,                     OptionType[:object_point]   + 9,
      :errorbuffer,                  OptionType[:object_point]   + 10,
      :writefunction,                OptionType[:function_point] + 11,
      :readfunction,                 OptionType[:function_point] + 12,
      :timeout,                      OptionType[:long]           + 13,
      :infilesize,                   OptionType[:long]           + 14,
      :postfields,                   OptionType[:object_point]   + 15,
      :referer,                      OptionType[:object_point]   + 16,
      :ftpport,                      OptionType[:object_point]   + 17,
      :useragent,                    OptionType[:object_point]   + 18,
      :low_speed_time,               OptionType[:long]           + 20,
      :resume_from,                  OptionType[:long]           + 21,
      :cookie,                       OptionType[:object_point]   + 22,
      :httpheader,                   OptionType[:object_point]   + 23,
      :httppost,                     OptionType[:object_point]   + 24,
      :sslcert,                      OptionType[:object_point]   + 25,
      :sslcertpasswd,                OptionType[:object_point]   + 26,
      :sslkeypasswd,                 OptionType[:object_point]   + 26,
      :crlf,                         OptionType[:long]           + 27,
      :quote,                        OptionType[:object_point]   + 28,
      :writeheader,                  OptionType[:object_point]   + 29,
      :headerdata,                   OptionType[:object_point]   + 29,
      :cookiefile,                   OptionType[:object_point]   + 31,
      :sslversion,                   OptionType[:long]           + 32,
      :timecondition,                OptionType[:long]           + 33,
      :timevalue,                    OptionType[:long]           + 34,
      :customrequest,                OptionType[:object_point]   + 36,
      :stderr,                       OptionType[:object_point]   + 37,
      :postquote,                    OptionType[:object_point]   + 39,
      :writeinfo,                    OptionType[:object_point]   + 40,
      :verbose,                      OptionType[:long]           + 41,
      :header,                       OptionType[:long]           + 42,
      :noprogress,                   OptionType[:long]           + 43,
      :nobody,                       OptionType[:long]           + 44,
      :failonerror,                  OptionType[:long]           + 45,
      :upload,                       OptionType[:long]           + 46,
      :post,                         OptionType[:long]           + 47,
      :ftplistonly,                  OptionType[:long]           + 48,
      :ftpappend,                    OptionType[:long]           + 50,
      :netrc,                        OptionType[:long]           + 51,
      :followlocation,               OptionType[:long]           + 52,
      :transfertext,                 OptionType[:long]           + 53,
      :put,                          OptionType[:long]           + 54,
      :progressfunction,             OptionType[:function_point] + 56,
      :progressdata,                 OptionType[:object_point]   + 57,
      :autoreferer,                  OptionType[:long]           + 58,
      :proxyport,                    OptionType[:long]           + 59,
      :postfieldsize,                OptionType[:long]           + 60,
      :httpproxytunnel,              OptionType[:long]           + 61,
      :interface,                    OptionType[:object_point]   + 62,
      :ssl_verifypeer,               OptionType[:long]           + 64,
      :cainfo,                       OptionType[:object_point]   + 65,
      :maxredirs,                    OptionType[:long]           + 68,
      :filetime,                     OptionType[:long]           + 69,
      :telnetoptions,                OptionType[:object_point]   + 70,
      :maxconnects,                  OptionType[:long]           + 71,
      :closepolicy,                  OptionType[:long]           + 72,
      :fresh_connect,                OptionType[:long]           + 74,
      :forbid_reuse,                 OptionType[:long]           + 75,
      :random_file,                  OptionType[:object_point]   + 76,
      :egdsocket,                    OptionType[:object_point]   + 77,
      :connecttimeout,               OptionType[:long]           + 78,
      :headerfunction,               OptionType[:function_point] + 79,
      :httpget,                      OptionType[:long]           + 80,
      :ssl_verifyhost,               OptionType[:long]           + 81,
      :cookiejar,                    OptionType[:object_point]   + 82,
      :ssl_cipher_list,              OptionType[:object_point]   + 83,
      :http_version,                 OptionType[:long]           + 84,
      :ftp_use_epsv,                 OptionType[:long]           + 85,
      :sslcerttype,                  OptionType[:object_point]   + 86,
      :sslkey,                       OptionType[:object_point]   + 87,
      :sslkeytype,                   OptionType[:object_point]   + 88,
      :sslengine,                    OptionType[:object_point]   + 89,
      :sslengine_default,            OptionType[:long]           + 90,
      :dns_use_global_cache,         OptionType[:long]           + 91,
      :dns_cache_timeout,            OptionType[:long]           + 92,
      :prequote,                     OptionType[:object_point]   + 93,
      :debugfunction,                OptionType[:function_point] + 94,
      :debugdata,                    OptionType[:object_point]   + 95,
      :cookiesession,                OptionType[:long]           + 96,
      :capath,                       OptionType[:object_point]   + 97,
      :buffersize,                   OptionType[:long]           + 98,
      :nosignal,                     OptionType[:long]           + 99,
      :share,                        OptionType[:object_point]   + 100,
      :proxytype,                    OptionType[:long]           + 101,
      :encoding,                     OptionType[:object_point]   + 102,
      :private,                      OptionType[:object_point]   + 103,
      :unrestricted_auth,            OptionType[:long]           + 105,
      :ftp_use_eprt,                 OptionType[:long]           + 106,
      :httpauth,                     OptionType[:long]           + 107,
      :ssl_ctx_function,             OptionType[:function_point] + 108,
      :ssl_ctx_data,                 OptionType[:object_point]   + 109,
      :ftp_create_missing_dirs,      OptionType[:long]           + 110,
      :proxyauth,                    OptionType[:long]           + 111,
      :ipresolve,                    OptionType[:long]           + 113,
      :maxfilesize,                  OptionType[:long]           + 114,
      :infilesize_large,             OptionType[:off_t]          + 115,
      :resume_from_large,            OptionType[:off_t]          + 116,
      :maxfilesize_large,            OptionType[:off_t]          + 117,
      :netrc_file,                   OptionType[:object_point]   + 118,
      :ftp_ssl,                      OptionType[:long]           + 119,
      :postfieldsize_large,          OptionType[:off_t]          + 120,
      :tcp_nodelay,                  OptionType[:long]           + 121,
      :ftpsslauth,                   OptionType[:long]           + 129,
      :ioctlfunction,                OptionType[:function_point] + 130,
      :ioctldata,                    OptionType[:object_point]   + 131,
      :ftp_account,                  OptionType[:object_point]   + 134,
      :cookielist,                   OptionType[:object_point]   + 135,
      :ignore_content_length,        OptionType[:long]           + 136,
      :ftp_skip_pasv_ip,             OptionType[:long]           + 137,
      :ftp_filemethod,               OptionType[:long]           + 138,
      :localport,                    OptionType[:long]           + 139,
      :localportrange,               OptionType[:long]           + 140,
      :connect_only,                 OptionType[:long]           + 141,
      :conv_from_network_function,   OptionType[:function_point] + 142,
      :conv_to_network_function,     OptionType[:function_point] + 143,
      :max_send_speed_large,         OptionType[:off_t]          + 145,
      :max_recv_speed_large,         OptionType[:off_t]          + 146,
      :ftp_alternative_to_user,      OptionType[:object_point]   + 147,
      :sockoptfunction,              OptionType[:function_point] + 148,
      :sockoptdata,                  OptionType[:object_point]   + 149,
      :ssl_sessionid_cache,          OptionType[:long]           + 150,
      :ssh_auth_types,               OptionType[:long]           + 151,
      :ssh_public_keyfile,           OptionType[:object_point]   + 152,
      :ssh_private_keyfile,          OptionType[:object_point]   + 153,
      :ftp_ssl_ccc,                  OptionType[:long]           + 154,
      :timeout_ms,                   OptionType[:long]           + 155,
      :connecttimeout_ms,            OptionType[:long]           + 156,
      :http_transfer_decoding,       OptionType[:long]           + 157,
      :http_content_decoding,        OptionType[:long]           + 158,
      :copypostfields,               OptionType[:object_point]   + 165]

    InfoType = enum [
      :string, 0x100000,
      :long,   0x200000,
      :double, 0x300000,
      :slist,  0x400000]

    Info = enum :info, [
      :effective_url,           InfoType[:string] + 1,
      :response_code,           InfoType[:long]   + 2,
      :total_time,              InfoType[:double] + 3,
      :namelookup_time,         InfoType[:double] + 4,
      :connect_time,            InfoType[:double] + 5,
      :pretransfer_time,        InfoType[:double] + 6,
      :size_upload,             InfoType[:double] + 7,
      :size_download,           InfoType[:double] + 8,
      :speed_download,          InfoType[:double] + 9,
      :speed_upload,            InfoType[:double] + 10,
      :header_size,             InfoType[:long]   + 11,
      :request_size,            InfoType[:long]   + 12,
      :ssl_verifyresult,        InfoType[:long]   + 13,
      :filetime,                InfoType[:long]   + 14,
      :content_length_download, InfoType[:double] + 15,
      :content_length_upload,   InfoType[:double] + 16,
      :starttransfer_time,      InfoType[:double] + 17,
      :content_type,            InfoType[:string] + 18,
      :redirect_time,           InfoType[:double] + 19,
      :redirect_count,          InfoType[:long]   + 20,
      :private,                 InfoType[:string] + 21,
      :http_connectcode,        InfoType[:long]   + 22,
      :httpauth_avail,          InfoType[:long]   + 23,
      :proxyauth_avail,         InfoType[:long]   + 24,
      :os_errno,                InfoType[:long]   + 25,
      :num_connects,            InfoType[:long]   + 26,
      :ssl_engines,             InfoType[:slist]  + 27,
      :cookielist,              InfoType[:slist]  + 28,
      :lastsocket,              InfoType[:long]   + 29,
      :ftp_entry_path,          InfoType[:string] + 30,
      :redirect_url,            InfoType[:string] + 31,
      :primary_ip,              InfoType[:string] + 32,
      :appconnect_time,         InfoType[:double] + 33,
      :certinfo,                InfoType[:slist]  + 34,
      :condition_unmet,         InfoType[:long]   + 35,
      :rtsp_session_id,         InfoType[:string] + 36,
      :rtsp_client_cseq,        InfoType[:long]   + 37,
      :rtsp_server_cseq,        InfoType[:long]   + 38,
      :rtsp_cseq_recv,          InfoType[:long]   + 39,
      :primary_port,            InfoType[:long]   + 40,
      :local_ip,                InfoType[:string] + 41,
      :local_port,              InfoType[:long]   + 42,
      :last, 42]

    FormOption = enum :form_option, [
      :none,
      :copyname,
      :ptrname,
      :namelength,
      :copycontents,
      :ptrcontents,
      :contentslength,
      :filecontent,
      :array,
      :obsolete,
      :file,
      :buffer,
      :bufferptr,
      :bufferlength,
      :contenttype,
      :contentheader,
      :filename,
      :end,
      :obsolete2,
      :stream,
      :last]

    Auth = enum [
      :basic,        0x01,
      :digest,       0x02,
      :gssnegotiate, 0x04,
      :ntlm,         0x08,
      :digest_ie,    0x10,
      :auto,         0x1f] # all options or'd together

    Proxy = enum [
      :http,     0,
      :http_1_0, 1,
      :socks4,   4,
      :socks5,   5,
      :socks4a,  6]

    SSLVersion = enum [
      :default, 0,
      :tlsv1,   1,
      :sslv2,   2,
      :sslv3,   3]

    MsgCode = enum :msg_code, [:none, :done, :last]

    class MsgData < ::FFI::Union
      layout :whatever, :pointer,
             :code, :easy_code
    end

    class Msg < ::FFI::Struct
      layout :code, :msg_code,
             :easy_handle, :pointer,
             :data, MsgData
    end

    class FDSet < ::FFI::Struct
      # XXX how does this work on non-windows? how can curl know the new size...
      FD_SETSIZE = 524288 # set a higher maximum number of fds. this has never applied to windows, so just use the default there

      if Curl.windows?
        layout :fd_count, :u_int,
               :fd_array, [:u_int, 64] # 2048 FDs

        def clear; self[:fd_count] = 0; end
      else
        layout :fds_bits, [:long, FD_SETSIZE / ::FFI::Type::LONG.size]

        def clear; super; end
      end
    end

    class Timeval < ::FFI::Struct
      layout :sec, :time_t,
             :usec, :suseconds_t
    end

    callback :callback, [:pointer, :size_t, :size_t, :pointer], :size_t

    ffi_lib_flags :now, :global
    ffi_lib 'libcurl'

    attach_function :global_init, :curl_global_init, [:long], :int

    attach_function :easy_init, :curl_easy_init, [], :pointer
    attach_function :easy_cleanup, :curl_easy_cleanup, [:pointer], :void
    attach_function :easy_getinfo, :curl_easy_getinfo, [:pointer, :info, :pointer], :easy_code
    attach_function :easy_setopt, :curl_easy_setopt, [:pointer, :option, :pointer], :easy_code
    attach_function :easy_setopt_string, :curl_easy_setopt, [:pointer, :option, :string], :easy_code
    attach_function :easy_setopt_long, :curl_easy_setopt, [:pointer, :option, :long], :easy_code
    attach_function :easy_setopt_callback, :curl_easy_setopt, [:pointer, :option, :callback], :easy_code
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
    attach_function :slist_append, :curl_slist_append, [:pointer, :string], :pointer
    attach_function :slist_free_all, :curl_slist_free_all, [:pointer], :void

    ffi_lib (windows? ? 'ws2_32' :  ::FFI::Library::LIBC)
    @blocking = true
    attach_function :select, [:int, FDSet.ptr, FDSet.ptr, FDSet.ptr, Timeval.ptr], :int

    @@initialized = false
    @@init_mutex = Mutex.new

    def Curl.init
      # ensure curl lib is initialised. not thread-safe so must be wrapped in a mutex
      @@init_mutex.synchronize {
        if not @@initialized
          raise RuntimeError.new('curl failed to initialise') if Curl.global_init(GLOBAL_ALL) != 0
          @@initialized = true
        end
      }
    end
  end
end

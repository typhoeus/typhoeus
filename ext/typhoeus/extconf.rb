ENV['RC_ARCHS'] = '' if RUBY_PLATFORM =~ /darwin/

# :stopdoc:

require 'mkmf'

ROOT = File.expand_path(File.join(File.dirname(__FILE__), '..', '..'))
specified_curl = ARGV[0] =~ /^--with-curl/ ? ARGV[0].split("=")[1] : nil
LIBDIR = specified_curl ? "#{specified_curl}/lib": Config::CONFIG['libdir']
INCLUDEDIR = specified_curl ? "#{specified_curl}/include" : Config::CONFIG['includedir']

if defined?(RUBY_ENGINE) && RUBY_ENGINE == 'macruby'
  $LIBRUBYARG_STATIC.gsub!(/-static/, '')
end

$CFLAGS << " #{ENV["CFLAGS"]}"
if Config::CONFIG['target_os'] == 'mingw32'
  $CFLAGS << " -DXP_WIN -DXP_WIN32 -DUSE_INCLUDED_VASPRINTF"
elsif Config::CONFIG['target_os'] == 'solaris2'
  $CFLAGS << " -DUSE_INCLUDED_VASPRINTF"
else
  $CFLAGS << " -g -DXP_UNIX"
end

use_macports = !(defined?(RUBY_ENGINE) && RUBY_ENGINE != 'ruby')
$LIBPATH << "/opt/local/lib" if use_macports

$CFLAGS << " -O3 -Wall -Wcast-qual -Wwrite-strings -Wconversion -Wmissing-noreturn -Winline"

HEADER_DIRS = [
  File.join(INCLUDEDIR, "curl"),
  INCLUDEDIR,
  '/usr/include/curl',
  '/usr/local/include/curl'
]

[
  '/opt/local/include/curl',
  '/opt/local/include',
].each { |x| HEADER_DIRS.unshift(x) } if use_macports

unless find_header('curl/curl.h', *HEADER_DIRS)
  abort "need libcurl"
end

find_library(Config::CONFIG['target_os'] == 'mingw32' ? 'curldll' : 'curl', 'curl_easy_init',
             LIBDIR,
             '/opt/local/lib',
             '/usr/local/lib',
             '/usr/lib'
  )

create_makefile("typhoeus/native")

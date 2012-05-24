#  Typhoeus [![Build Status](https://secure.travis-ci.org/typhoeus/typhoeus.png?branch=master)](http://travis-ci.org/typhoeus/typhoeus)

[the mailing list](http://groups.google.com/group/typhoeus)

##  Summary

Like a modern code version of the mythical beast with 100 serpent heads,
Typhoeus runs HTTP requests in parallel while cleanly encapsulating handling
logic. To be a little more specific, it’s a library for accessing web services
in Ruby. It’s specifically designed for building RESTful service oriented
architectures in Ruby that need to be fast enough to process calls to multiple
services within the client’s HTTP request/response life cycle.

Some of the awesome features are parallel request execution, memoization of
request responses (so you don’t make the same request multiple times in a
single group), built in support for caching responses to memcached (or
whatever), and mocking capability baked in. It uses libcurl and libcurl-multi
to work this speedy magic. I wrote the bindings myself so it’s yet another
Ruby libcurl library, but with some extra awesomeness added in. FFI is used to
interface with the library so it works with any Ruby implementation.

##  Installation

Typhoeus requires you to have a current version of libcurl installed. The
easiest solution is to use your system’s package manager to install it. If
that doesn’t work, you can grab a package off of [the curl
website](http://curl.haxx.se/download.html) and manually install it following
the instructions given there. Typhoeus will work with version 7.19.4 or higher
(earlier versions might work but no guarantees are provided).

To install Typhoeus, simply run:

    gem install typhoeus

If you’re on Debian or Ubuntu and getting errors while trying to install, it
could be because you don’t have the latest version of libcurl installed. Do
this to fix:

    sudo apt-get install libcurl4-gnutls-dev

If you’re still having issues, please let me know on [the mailing
list](http://groups.google.com/group/typhoeus).

There’s one other thing you should know. The Easy object (which is just a
libcurl thing) allows you to set timeout values in milliseconds. However, for
this to work you need to build libcurl with c-ares support built in.

##  Windows Support

Typhoeus runs perfectly on Windows. The tricky part is knowing how to install
libcurl in the absence of a package manager.

To install libcurl, simply grab [the latest libcurl
package](http://curl.haxx.se/download.html#Win32) off of the curl website,
extract the bin directory, and then add the path to the bin directory into the
PATH environment variable. Ruby with then be able to find libcurl properly and
everything will just work.

##  Usage

The primary interface for Typhoeus is comprised of three classes: Request,
Response, and Hydra. Request represents an HTTP request object, response
represents an HTTP response, and Hydra manages making parallel HTTP
connections.

    require 'rubygems'
    require 'typhoeus'
    require 'json'

    # the request object
    request = Typhoeus::Request.new("http://www.pauldix.net",
                                    :body          => "this is a request body",
                                    :method        => :post,
                                    :headers       => {:Accept => "text/html"},
                                    :timeout       => 100, # milliseconds
                                    :cache_timeout => 60, # seconds
                                    :params        => {:field1 => "a field"})
    # we can see from this that the first argument is the url. the second is a set of options.
    # the options are all optional. The default for :method is :get. Timeout is measured in milliseconds.
    # cache_timeout is measured in seconds.

    # Run the request via Hydra.
    hydra = Typhoeus::Hydra.new
    hydra.queue(request)
    hydra.run

    # the response object will be set after the request is run
    response = request.response
    response.code    # http status code
    response.time    # time in seconds the request took
    response.headers # the http headers
    response.headers_hash # http headers put into a hash
    response.body    # the response body

**Making Quick Requests**

The request object has some convenience methods for performing single HTTP
requests. The arguments are the same as those you pass into the request
constructor.

    response = Typhoeus::Request.get("http://www.pauldix.net")
    response = Typhoeus::Request.head("http://www.pauldix.net")
    response = Typhoeus::Request.put("http://localhost:3000/posts/1", :body => "whoo, a body")
    response = Typhoeus::Request.post("http://localhost:3000/posts", :params => {:title => "test post", :content => "this is my test"})
    response = Typhoeus::Request.delete("http://localhost:3000/posts/1")

**Handling HTTP errors**

You can query the response object to figure out if you had a successful
request or not. Here’s some example code that you might use to handle errors.

    request.on_complete do |response|
      if response.success?
        # hell yeah
      elsif response.timed_out?
        # aw hell no
        log("got a time out")
      elsif response.code == 0
        # Could not get an http response, something's wrong.
        log(response.curl_error_message)
      else
        # Received a non-successful http response.
        log("HTTP request failed: " + response.code.to_s)
      end
    end

This also works with serial (blocking) requests in the same fashion. Both
serial and parallel requests return a Response object.

**Handling file uploads**

A File object can be passed as a param for a POST request to handle uploading
files to the server. Typhoeus will upload the file as the original file name
and use Mime::Types to set the content type.

    response = Typhoeus::Request.post("http://localhost:3000/posts",
      :params => {
        :title => "test post", :content => "this is my test",
        :file => File.open("thesis.txt","r")
      }
    )

**Making Parallel Requests**

    # Generally, you should be running requests through hydra. Here is how that looks
    hydra = Typhoeus::Hydra.new

    first_request = Typhoeus::Request.new("http://localhost:3000/posts/1.json")
    first_request.on_complete do |response|
      post = JSON.parse(response.body)
      third_request = Typhoeus::Request.new(post.links.first) # get the first url in the post
      third_request.on_complete do |response|
        # do something with that
      end
      hydra.queue third_request
      return post
    end
    second_request = Typhoeus::Request.new("http://localhost:3000/users/1.json")
    second_request.on_complete do |response|
      JSON.parse(response.body)
    end
    hydra.queue first_request
    hydra.queue second_request
    hydra.run # this is a blocking call that returns once all requests are complete

    first_request.handled_response # the value returned from the on_complete block
    second_request.handled_response # the value returned from the on_complete block (parsed JSON)

The execution of that code goes something like this. The first and second
requests are built and queued. When hydra is run the first and second requests
run in parallel. When the first request completes, the third request is then
built and queued up. The moment it is queued Hydra starts executing it.
Meanwhile the second request would continue to run (or it could have completed
before the first). Once the third request is done, hydra.run returns.

**Specifying Max Concurrency**

Hydra will also handle how many requests you can make in parallel. Things will
get flakey if you try to make too many requests at the same time. The built in
limit is 200. When more requests than that are queued up, hydra will save them
for later and start the requests as others are finished. You can raise or
lower the concurrency limit through the Hydra constructor.

    hydra = Typhoeus::Hydra.new(:max_concurrency => 20) # keep from killing some servers

**Memoization**

Hydra memoizes requests within a single run call. You can also disable
memoization.

    hydra = Typhoeus::Hydra.new
    2.times do
      r = Typhoeus::Request.new("http://localhost/3000/users/1")
      hydra.queue r
    end
    hydra.run # this will result in a single request being issued. However, the on_complete handlers of both will be called.
    hydra.disable_memoization
    2.times do
      r = Typhoeus::Request.new("http://localhost/3000/users/1")
      hydra.queue r
    end
    hydra.run # this will result in a two requests.

**Caching**

Hydra includes built in support for creating cache getters and setters. In the
following example, if there is a cache hit, the cached object is passed to the
on\_complete handler of the request object.

    hydra = Typhoeus::Hydra.new
    hydra.cache_setter do |request|
      @cache.set(request.cache_key, request.response, request.cache_timeout)
    end

    hydra.cache_getter do |request|
      @cache.get(request.cache_key) rescue nil
    end

**Direct Stubbing**

Hydra allows you to stub out specific urls and patterns to avoid hitting
remote servers while testing.

    hydra = Typhoeus::Hydra.new
    response = Response.new(:code => 200, :headers => "", :body => "{'name' : 'paul'}", :time => 0.3)
    hydra.stub(:get, "http://localhost:3000/users/1").and_return(response)

    request = Typhoeus::Request.new("http://localhost:3000/users/1")
    request.on_complete do |response|
      JSON.parse(response.body)
    end
    hydra.queue request
    hydra.run

The queued request will hit the stub. The on\_complete handler will be called
and will be passed the response object. You can also specify a regex to match
urls.

    hydra.stub(:get, /http\:\/\/localhost\:3000\/users\/.*/).and_return(response)
    # any requests for a user will be stubbed out with the pre built response.

**The Singleton**

All of the quick requests are done using the singleton hydra object. If you
want to enable caching or stubbing on the quick requests, set those options on
the singleton.

    hydra = Typhoeus::Hydra.hydra
    hydra.stub(:get, "http://localhost:3000/users")

**Timeouts**

No exceptions are raised on HTTP timeouts. You can check whether a request
timed out with the following methods:

    easy.timed_out?  # for a raw Easy handle
    response.timed_out?  # for a Response handle

**Following Redirections**

Use `:follow_location => true`, eg:

    Typhoeus::Request.new(“www.example.com”, :follow_location => true)

**Basic Authentication**

    response = Typhoeus::Request.get("http://twitter.com/statuses/followers.json",
                                     :username => username, :password => password)

**SSL**

SSL comes built in to libcurl so it’s in Typhoeus as well. If you pass in a
url with “https” it should just work assuming that you have your [cert
bundle](http://curl.haxx.se/docs/caextract.html) in order and the server is
verifiable. You must also have libcurl built with SSL support enabled. You can
check that by doing this:

    Typhoeus::Easy.new.curl_version # output should include OpenSSL/...

Now, even if you have libcurl built with OpenSSL you may still have a messed
up cert bundle or if you’re hitting a non-verifiable SSL server then you’ll
have to disable peer verification to make SSL work. Like this:

    Typhoeus::Request.get("https://mail.google.com/mail", :disable_ssl_peer_verification => true)

If you are getting “SSL: certificate subject name does not match target host
name” from curl (ex:- you are trying to access to b.c.host.com when the
certificate subject is \*.host.com). You can disable host verification. Like
this:

    Typhoeus::Request.get("https://mail.google.com/mail", :disable_ssl_host_verification => true)

**LibCurl**

Typhoeus also has a more raw libcurl interface. These are the Easy and Multi
objects. If you’re into accessing just the raw libcurl style, those are your
best bet.

However, by using this raw interface, you do not get access to Hydra-specific
features, such as stubbing/mocking.

SSL Certs can be provided to the Easy interface:

    e = Typhoeus::Easy.new
    e.url = "https://example.com/action"
    s.ssl_cacert = "ca_file.cer"
    e.ssl_cert = "acert.crt"
    e.ssl_key = "akey.key"
    [...]
    e.perform

or directly to a Typhoeus::Request :

    e = Typhoeus::Request.get("https://example.com/action",
      :ssl_cacert => "ca_file.cer",
      :ssl_cert => "acert.crt",
      :ssl_key => "akey.key",
      [...]
    end

##  Advanced authentication

Thanks for the authentication piece and this description go to Oleg Ivanov
(morhekil). The major reason to start this fork was the need to perform NTLM
authentication in Ruby, and other libcurl’s authentications method were made
possible as a result. Now you can do it via Typhoeus::Easy interface using the
following API.

    e = Typhoeus::Easy.new
    e.auth = {
      :username => 'username',
      :password => 'password',
      :method => Typhoeus::Easy::AUTH_TYPES[:CURLAUTH_NTLM]
    }
    e.url = "http://example.com/auth_ntlm"
    e.method = :get
    e.perform

**Other authentication types**

The following authentication types are available:

  * CURLAUTH\_BASIC
  * CURLAUTH\_DIGEST
  * CURLAUTH\_GSSNEGOTIATE
  * CURLAUTH\_NTLM
  * CURLAUTH\_DIGEST\_IE
  * CURLAUTH\_AUTO

The last one (CURLAUTH\_AUTO) is really a combination of all previous methods
and is provided by Typhoeus for convenience. When you set authentication to
auto, Typhoeus will retrieve the given URL first and examine it’s headers to
confirm what auth types are supported by the server. The it will select the
strongest of available auth methods and will send the second request using the
selected authentication method.

**Authentication via the quick request interface**

There’s also an easy way to perform any kind of authentication via the quick
request interface:

    e = Typhoeus::Request.get("http://example.com",
      :username => 'username',
      :password => 'password',
      :auth_method => :ntlm)

All methods listed above is available in a shorter form – :basic, :digest,
:gssnegotiate, :ntlm, :digest\_ie, :auto.

**Query of available auth types**

After the initial request you can get the authentication types available on
the server via Typhoues::Easy#auth\_methods call. It will return a number

that you’ll need to decode yourself, please refer to easy.rb source code to
see the numeric values of different auth types.

##  Verbose debug output

Sometime it’s useful to see verbose output from curl. You may now enable it:

    e = Typhoeus::Easy.new
    e.verbose = 1

or using the quick request:

    e = Typhoeus::Request.get("http://example.com", :verbose => true)

Just remember that libcurl prints it’s debug output to the console (to
STDERR), so you’ll need to run your scripts from the console to see it.

##  Benchmarks

I set up a benchmark to test how the parallel performance works vs Ruby’s
built in NET::HTTP. The setup was a local evented HTTP server that would take
a request, sleep for 500 milliseconds and then issued a blank response. I set
up the client to call this 20 times. Here are the results:

      net::http  0.030000   0.010000   0.040000 ( 10.054327)
      typhoeus   0.020000   0.070000   0.090000 (  0.508817)

We can see from this that NET::HTTP performs as expected, taking 10 seconds to
run 20 500ms requests. Typhoeus only takes 500ms (the time of the response
that took the longest.) One other thing to note is that Typhoeus keeps a pool
of libcurl Easy handles to use. For this benchmark I warmed the pool first. So
if you test this out it may be a bit slower until the Easy handle pool has
enough in it to run all the simultaneous requests. For some reason the easy
handles can take quite some time to allocate.

##  Running the specs

Running the specs requires a couple of Sinatra servers to be booted. rake spec
will do this for you, but if you’re needing to run the specs a lot, spinning
up the servers manually and leaving them running should speed things up a bit.
Do this:

      # Start up the test servers (in another terminal)
      rake start_test_servers

      # Run the specs
      rake spec


##  Next Steps

  * Add in ability to keep-alive requests and reuse them within hydra.
  * Add support for automatic retry, exponential back-off, and queuing for later.

##  LICENSE

(The MIT License)

Copyright © 2009-2010 Paul Dix

Copyright © 2011 David Balatero

Copyright © 2012 [Hans Hasselberg](http://www.hans.io)

Permission is hereby granted, free of charge, to any person obtaining a
copy of this software and associated documentation files (the "Software"),
to deal in the Software without restriction, including without
limitation the rights to use, copy, modify, merge, publish, distribute,
sublicense, and/or sell copies of the Software, and to permit persons
to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR
OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.

# Typhoeus [![Gem Version](https://badge.fury.io/rb/typhoeus.svg)](https://badge.fury.io/rb/typhoeus) [![CI](https://github.com/typhoeus/typhoeus/actions/workflows/ci.yml/badge.svg)](https://github.com/typhoeus/typhoeus/actions/workflows/ci.yml) [![Experimental](https://github.com/typhoeus/typhoeus/actions/workflows/experimental.yml/badge.svg)](https://github.com/typhoeus/typhoeus/actions/workflows/experimental.yml)

Typhoeus is a Ruby HTTP client built on [libcurl](https://curl.se/libcurl/).
Run individual requests, or queue many on `Typhoeus::Hydra` to execute them in
parallel. It supports redirects, timeouts, streaming, caching, memoization,
stubbing, and callbacks while still exposing libcurl's options.

- `Typhoeus::Request` and `Typhoeus::Response` model a single transfer.
- `Typhoeus::Hydra` queues requests and runs them concurrently.
- `Typhoeus.get`, `.post`, and the other shortcuts cover common cases.

## Example

A single request:

```ruby
Typhoeus.get("www.example.com", followlocation: true)
```

Parallel requests:

```ruby
hydra = Typhoeus::Hydra.new
10.times do
  hydra.queue(Typhoeus::Request.new("www.example.com", followlocation: true))
end
hydra.run
```

## Installation

Add the gem to your bundle:

```sh
bundle add typhoeus
```

Or install it directly:

```sh
gem install typhoeus
```

## Documentation

- [API documentation](https://rubydoc.info/github/typhoeus/typhoeus) (master)
- [Changelog](https://github.com/typhoeus/typhoeus/blob/master/CHANGELOG.md)

## Usage

### Introduction

Typhoeus's primary interface consists of three classes: `Request`, `Response`,
and `Hydra`. A request describes an HTTP call, a response exposes its result,
and a hydra runs requests in parallel.

```ruby
request = Typhoeus::Request.new(
  "www.example.com",
  method: :post,
  body: "this is a request body",
  params: { field1: "a field" },
  headers: { Accept: "text/html" }
)
```

The first argument is the URL and the second is an options hash. All options
are optional, and the method defaults to `:get`.

URL parameters go in `:params`. Form-encoded body parameters go in `:body`.
`:params` are appended to the URL; `:body` becomes the request body.

#### Sending requests through the proxy

Add `proxy` to the options:

```ruby
options = { proxy: "http://myproxy.org" }
request = Typhoeus::Request.new(url, options)
```

If the proxy requires authentication, set `proxyuserpwd` to `user:password`,
just like the basic-auth `userpwd` option:

```ruby
options = { proxy: "http://proxyurl.com", proxyuserpwd: "user:password" }
request = Typhoeus::Request.new(url, options)
```

Run the request directly or queue it on a hydra:

```ruby
request.run
#=> <Typhoeus::Response ... >
```

```ruby
hydra = Typhoeus::Hydra.hydra
hydra.queue(request)
hydra.run
```

After the request finishes, read the response:

```ruby
response = request.response
response.code
response.total_time
response.headers
response.body
```

### Making Quick Requests

Typhoeus provides convenience methods for single requests. They take the same
URL and options as `Request.new`.

```ruby
Typhoeus.get("www.example.com")
Typhoeus.head("www.example.com")
Typhoeus.put("www.example.com/posts/1", body: "a body")
Typhoeus.patch("www.example.com/posts/1", body: "a new body")
Typhoeus.post("www.example.com/posts", body: { title: "test post", content: "this is my test" })
Typhoeus.delete("www.example.com/posts/1")
Typhoeus.options("www.example.com")
```

#### Sending params in the body with PUT

POST sets `Content-Type` to `application/x-www-form-urlencoded` when the body
is a hash. Other methods, including PUT, PATCH, and HEAD, do not. To receive a
PUT hash as form parameters, set the header yourself:

```ruby
Typhoeus.put(
  "www.example.com/posts/1",
  headers: { "Content-Type" => "application/x-www-form-urlencoded" },
  body: { title: "test post updated title", content: "this is my updated content" }
)
```

### Before callbacks

Use `Typhoeus.before` for every request, or `request.before` for a single
request. Callbacks receive the request, run before it is performed, and can
modify it. Returning `nil` or `false` skips the request and returns its current
response; returning a `Typhoeus::Response` skips the request and returns that
response.

```ruby
Typhoeus.before { |request| request.options[:timeout] ||= 5 }

request = Typhoeus::Request.new("www.example.com")
request.before { |request| request.options[:headers] ||= {} }
```

To skip before callbacks globally, for example when your application does not
use them:

```ruby
Typhoeus::Config.exclude_features = [:before]
```

### Handling HTTP errors

After the request completes, inspect the response. `success?` covers both
transport and HTTP failures, `timed_out?` identifies timeouts, and a zero code
means no HTTP response was received. Define callbacks before running the
request.

```ruby
request = Typhoeus::Request.new("www.example.com", followlocation: true)

request.on_complete do |response|
  if response.success?
    # Request succeeded
  elsif response.timed_out?
    log("request timed out")
  elsif response.code == 0
    log(response.return_message)
  else
    log("HTTP request failed: #{response.code}")
  end
end

request.run
```

This works for blocking and parallel requests; both return a `Response`.

### Handling file uploads

Pass a `File` in the body to upload a file with a POST request. Typhoeus sends
the original file name and detects the content type with Mime::Types when the
optional `mime-types` gem is installed. Without that gem, it uses
`application/octet-stream`.

```ruby
Typhoeus.post(
  "http://localhost:3000/posts",
  body: {
    title: "test post",
    content: "this is my test",
    file: File.open("thesis.txt", "r")
  }
)
```

### Streaming the response body

Set `on_body` to receive response chunks as they arrive. This is useful for
large responses, and Typhoeus does not retain the complete body.

```ruby
downloaded_file = File.open("huge.iso", "wb")
request = Typhoeus::Request.new("www.example.com/huge.iso")
request.on_headers do |response|
  raise "Request failed" if response.code != 200
end
request.on_body do |chunk|
  downloaded_file.write(chunk)
end
request.on_complete do |response|
  downloaded_file.close
  # response.body is empty
end
request.run
```

Return `:abort` from the `on_body` block to stop the transfer cleanly:

```ruby
request.on_body do |chunk|
  buffer << chunk
  :abort if buffer.size > 1024 * 1024
end
```

Returning `:abort` stops the transfer without buffering the rest of the
response. Leaving the block with `return`, `throw`, or `raise` can leave the
transfer in an inconsistent state.

### Progress callbacks

Set `on_progress` to observe the transfer. The callback receives the total and
current number of downloaded and uploaded bytes:

```ruby
request = Typhoeus::Request.new("www.example.com/huge.iso")
request.on_progress do |dltotal, dlnow, ultotal, ulnow|
  puts "#{dlnow}/#{dltotal} bytes"
end
request.run
```

Progress callbacks run during the transfer. Use `on_complete` for completion.

### Making Parallel Requests

Use `Hydra` to run requests in parallel. `hydra.run` blocks until all queued
requests finish.

```ruby
hydra = Typhoeus::Hydra.hydra

first_request = Typhoeus::Request.new("http://example.com/posts/1")
first_request.on_complete do |response|
  third_request = Typhoeus::Request.new(response.body)
  hydra.queue(third_request)
end
second_request = Typhoeus::Request.new("http://example.com/posts/2")

hydra.queue(first_request)
hydra.queue(second_request)
hydra.run # blocks until all requests are complete
```

`hydra.run` starts the first two requests. When the first completes, its
`on_complete` callback queues a third request, which starts immediately while
the second request continues. `hydra.run` returns when all three finish.

Collect responses from the requests after the run:

```ruby
hydra = Typhoeus::Hydra.new
requests = 10.times.map do
  request = Typhoeus::Request.new("www.example.com", followlocation: true)
  hydra.queue(request)
  request
end
hydra.run

responses = requests.map { |request| request.response.body }
```

To handle responses as they complete, use `on_complete` instead:

```ruby
hydra = Typhoeus::Hydra.new
10.times do
  request = Typhoeus::Request.new("www.example.com", followlocation: true)
  request.on_complete do |response|
    # handle response
  end
  hydra.queue(request)
end
hydra.run
```

### Making Parallel Requests with Faraday + Typhoeus

Typhoeus ships a Faraday adapter that supports Faraday 1.x and 2.x.

```ruby
require "faraday"

conn = Faraday.new(url: "http://httppage.com") do |builder|
  builder.request  :url_encoded
  builder.response :logger
  builder.adapter  :typhoeus
end

conn.in_parallel do
  response1 = conn.get("/first")
  response2 = conn.get("/second")

  # Inside in_parallel, the responses are not complete yet.
  response1.body
  response2.body
end

# After in_parallel returns, the responses are populated.
response1.body
response2.body
```

### Specifying Max Concurrency

Hydra runs at most 200 requests concurrently by default. Additional queued
requests wait until a running request finishes. Set a lower or higher limit on
the constructor:

```ruby
Typhoeus::Hydra.new(max_concurrency: 20)
```

### Memoization

With memoization enabled, Hydra sends a single request for identical GET
requests in a run and executes each request's `on_complete` callback.
Memoization is disabled by default:

```ruby
Typhoeus::Config.memoize = true

hydra = Typhoeus::Hydra.new(max_concurrency: 1)
2.times do
  hydra.queue(Typhoeus::Request.new("www.example.com"))
end
hydra.run
```

With memoization disabled, Hydra sends both requests:

```ruby
Typhoeus::Config.memoize = false

hydra = Typhoeus::Hydra.new(max_concurrency: 1)
2.times do
  hydra.queue(Typhoeus::Request.new("www.example.com"))
end
hydra.run
```

### Caching

Typhoeus can cache responses. A cache store implements `get(request)` and
`set(request, response)`, and a cache hit is delivered through the request's
`on_complete` callback.

```ruby
class Cache
  def initialize
    @memory = {}
  end

  def get(request)
    @memory[request]
  end

  def set(request, response)
    @memory[request] = response
  end
end

Typhoeus::Config.cache = Cache.new

Typhoeus.get("www.example.com").cached?
#=> false
Typhoeus.get("www.example.com").cached?
#=> true
```

Typhoeus ships adapters for [Dalli](https://github.com/mperham/dalli), Rails,
and [Redis](https://github.com/redis/redis-rb):

```ruby
require "typhoeus/cache/dalli"

dalli = Dalli::Client.new(...)
Typhoeus::Config.cache = Typhoeus::Cache::Dalli.new(dalli)
```

```ruby
require "typhoeus/cache/rails"

Typhoeus::Config.cache = Typhoeus::Cache::Rails.new
```

```ruby
require "typhoeus/cache/redis"

redis = Redis.new(...)
Typhoeus::Config.cache = Typhoeus::Cache::Redis.new(redis)
```

Each adapter accepts a `default_ttl` in seconds for requests without a
`cache_ttl`:

```ruby
Typhoeus::Config.cache = Typhoeus::Cache::Dalli.new(dalli, default_ttl: 3600)
```

Disable caching for one request with `cache: false`, or pass a different store:

```ruby
Typhoeus.get("www.example.com", cache: false)
Typhoeus.get("www.example.com", cache: Cache.new)
```

The cache key includes the URL and all request options except the cache store
and `cache_ttl`. The store decides where a response is cached and the TTL
decides how long it is cached; neither changes which response is cached.

### Stubbing

Stub URLs or patterns to keep tests off the network. A stub matches the
request's base URL.

```ruby
response = Typhoeus::Response.new(code: 200, body: "{'name' : 'paul'}")
Typhoeus.stub("www.example.com").and_return(response)

Typhoeus.get("www.example.com") == response
#=> true
```

Pass a regexp to match multiple URLs:

```ruby
response = Typhoeus::Response.new(code: 200, body: "{'name' : 'paul'}")
Typhoeus.stub(/example/).and_return(response)

Typhoeus.get("www.example.com") == response
#=> true
```

Pass an array to return responses in sequence:

```ruby
Typhoeus.stub("www.example.com").and_return([response1, response2])

Typhoeus.get("www.example.com") == response1 #=> true
Typhoeus.get("www.example.com") == response2 #=> true
```

To make a real request while `Typhoeus::Config.block_connection` is enabled,
wrap it in `Typhoeus.with_connection`. Stubs are bypassed inside the block,
which lets a stub forward to a real service:

```ruby
Typhoeus::Config.block_connection = true
Typhoeus.stub("http://elastic:9200") do |request|
  Typhoeus.with_connection { request.run }
end
```

Clear expectations between tests, or stubs will leak into later examples:

```ruby
RSpec.configure do |config|
  config.before :each do
    Typhoeus::Expectation.clear
  end
end
```

### Timeouts

Typhoeus does not raise on HTTP timeouts. Check the response instead:

```ruby
response = Typhoeus.get("www.example.com", timeout: 1)
response.timed_out? #=> true
response.success?   #=> false
```

Two timeouts are available: [`timeout`](http://curl.haxx.se/libcurl/c/curl_easy_setopt.html#CURLOPTTIMEOUT)
and [`connecttimeout`](http://curl.haxx.se/libcurl/c/curl_easy_setopt.html#CURLOPTCONNECTTIMEOUT).
`timeout` limits the entire request, while `connecttimeout` limits only the
connection phase. Both are in seconds.

`timeout_ms` and `connecttimeout_ms` offer millisecond precision, but are not
available on every platform (for example, Linux without `nosignal: true`).
When a timeout is a float, Typhoeus also sets the corresponding `*_ms` option
and rounds the seconds value up.

DNS timeouts under one second require libcurl built with an asynchronous
resolver.

`timeout` defaults to 0, which means no transfer timeout. `connecttimeout`
defaults to 300 seconds; passing 0 also uses 300 seconds.

### Threads and forking

Typhoeus delegates handle management to Ethon. Ethon raises
`Ethon::Errors::ForkSafety` for `Ethon::Easy` and `Ethon::Multi` handles
inherited across `fork`. Typhoeus clears its easy pool in the child process and
creates a hydra's native multi handle lazily, so creating or memoizing a hydra
during boot does not initialize libcurl. Typhoeus cannot reset libcurl's
process-global state. If libcurl is initialized before forking, for example by
making a request during boot, use `fork` followed by `exec`, or fork before the
first request.

On macOS, libcurl's global initialization can touch Objective-C and crash a
forked child with `objc_initializeAfterForkError`. Initialize libcurl in the
parent before the workers fork:

```ruby
# config/initializers/ethon.rb in Rails, or before_fork in Puma
require "ethon"
Ethon::Curl.init
```

If you cannot initialize libcurl before forking, set
`OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES` in the environment. It skips the
safety check in the child, so prefer initializing libcurl before the fork.

Typhoeus keeps at most `Typhoeus::Config.max_idle_easies` idle easy handles in
the pool (20 by default). Handles beyond that limit are cleaned up instead of
pooled. Set it to `nil` to keep every handle or `0` to disable pooling.

Exceptions raised by `on_body` and `on_complete` callbacks are propagated by
Ethon. Typhoeus releases the underlying easy handle before re-raising.

### Ethon 0.19

Typhoeus requires Ethon 0.19 or later. Ethon 0.19 makes several previously
silent errors visible:

- Unknown enum and bitmask option values raise `Ethon::Errors::InvalidValue`,
  and options the loaded libcurl does not know raise
  `Ethon::Errors::UnsupportedOption`. Guard optional options with
  `Ethon::Curl.supports_option?` when you need to support older libcurl builds.
- Exceptions raised by `on_body` and `on_complete` callbacks are re-raised.
- Multipart PUT requests are sent as `multipart/form-data`.
- Pass `errorbuffer: true` to expose libcurl's detailed error as
  `response.error_message`.

### Following Redirections

Enable redirects with `followlocation: true`:

```ruby
Typhoeus.get("www.example.com", followlocation: true)
```

### Basic Authentication

Pass `userpwd` as `username:password`:

```ruby
Typhoeus::Request.get("www.example.com", userpwd: "user:password")
```

### Compression

Use `accept_encoding` to request and decompress a compressed response:

```ruby
Typhoeus.get("www.example.com", accept_encoding: "gzip")
```

Setting the `Accept-Encoding` header directly does not add libcurl's automatic
decompression, so the response stays compressed:

```ruby
Typhoeus.get("www.example.com", headers: { "Accept-Encoding" => "gzip" })
```

### Cookies

Pass a file to read cookies from and a file to write them to:

```ruby
Typhoeus::Request.get(
  "www.example.com",
  cookiefile: "/path/to/file",
  cookiejar: "/path/to/file"
)
```

`cookiefile` is read before the request and `cookiejar` is written after it.
Use the same path for both if you want one file for reading and writing.

### Other curl options

Any libcurl option can be passed as a request option. See the
[Ethon option documentation](http://rubydoc.info/github/typhoeus/ethon/Ethon/Easy/Options).

An empty header value suppresses libcurl's default header. To send a header
with an empty value, end the key with a semicolon:

```ruby
Typhoeus.get("www.example.com", headers: { "X-Empty;" => "" })
```

Typhoeus sends an empty `Expect` header by default to suppress the
`100-continue` handshake. Pass `nil` to leave the decision to libcurl, which
adds the header for uploads with an unknown size and for multipart bodies:

```ruby
Typhoeus.post("www.example.com", headers: { "Expect" => nil }, body: data)
```

### SSL

SSL is handled by libcurl. HTTPS URLs work when libcurl was built with SSL
support and the [CA bundle](http://curl.haxx.se/docs/caextract.html) is valid.
If `SSL_CERT_FILE` or `SSL_CERT_DIR` is set, Typhoeus uses it as the default CA
bundle or directory; explicit `:cainfo` and `:capath` options take precedence.
Check libcurl's build with:

```sh
curl --version
```

If a certificate cannot be verified, disable peer verification:

```ruby
Typhoeus.get("https://www.example.com", ssl_verifypeer: false)
```

If the certificate does not match the host, disable host verification:

```ruby
# Verify the host name (default)
Typhoeus.get("https://www.example.com", ssl_verifyhost: 2)
# Do not verify the host name
Typhoeus.get("https://www.example.com", ssl_verifyhost: 0)
```

Only disable these checks in controlled environments.

### Verbose debug output

Enable verbose output per request:

```ruby
Typhoeus.get("http://example.com", verbose: true)
```

Or globally:

```ruby
Typhoeus::Config.verbose = true
```

Ethon routes libcurl's verbose output through `Ethon.logger` at the debug
level, so it no longer prints to STDERR directly. Enable debug logging to see
it:

```ruby
require "logger"
Ethon.logger = Logger.new(STDERR)
Ethon.logger.level = Logger::DEBUG
```

### Thread safety

`Typhoeus::Request` and `Typhoeus::Hydra` instances are not thread-safe. An
`Ethon::Easy` handle is checked out of the process-wide pool for the duration
of a request and checked back in when it completes, so create requests and
hydras per thread. `Typhoeus::Hydra.hydra` is memoized per thread.
`Typhoeus.with_connection` only changes the setting for the current thread.

These are process-wide and should be configured during boot rather than while
requests are running:

- `Typhoeus::Config` (`block_connection`, `cache`, `exclude_features`,
  `max_idle_easies`, `memoize`, timeouts, `proxy`, `user_agent`, `verbose`)
- `Typhoeus.before`, `Typhoeus.on_complete`, `Typhoeus.on_success`,
  `Typhoeus.on_failure`, `Typhoeus.on_progress`, and `Typhoeus.on_headers`
- `Typhoeus.stub` and `Typhoeus::Expectation.all`
- the easy pool used by `Typhoeus::Pool`

The easy pool belongs to the process that created it. It keeps at most
`Typhoeus::Config.max_idle_easies` idle handles (20 by default) and is cleared
after `fork`.

### Default User Agent Header

Set a User-Agent for every request:

```ruby
Typhoeus::Config.user_agent = "custom user agent"
```

### Running the specs

Install dependencies and run the suite:

```sh
bundle install
bundle exec rake
```

Run `COVERAGE=true bundle exec rake` to write an HTML report to `coverage/`.

Run `bundle exec rake perf` to benchmark the request hot path. It reports
throughput, allocations, and retained memory for building, queueing, adding,
and performing requests.

## Semantic Versioning

This project conforms to [semver](http://semver.org/).

## License

(The MIT License)

Copyright © 2009-2010 [Paul Dix](http://www.pauldix.net/)

Copyright © 2011-2012 [David Balatero](https://github.com/dbalatero/)

Copyright © 2012-2016 [Hans Hasselberg](http://github.com/i0rek/)

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

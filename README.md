# Typhoeus [![Build Status](https://img.shields.io/travis/typhoeus/typhoeus/master.svg)](https://travis-ci.org/typhoeus/typhoeus) [![Code Climate](https://img.shields.io/codeclimate/github/typhoeus/typhoeus.svg)](https://codeclimate.com/github/typhoeus/typhoeus) [![Gem Version](https://img.shields.io/gem/v/typhoeus.svg)](https://rubygems.org/gems/typhoeus)

Like a modern code version of the mythical beast with 100 serpent heads, Typhoeus runs HTTP requests in parallel while cleanly encapsulating handling logic.

## Example

A single request:

```ruby
Typhoeus.get("www.example.com", followlocation: true)
```

Parallel requests:

```ruby
hydra = Typhoeus::Hydra.new
10.times.map{ hydra.queue(Typhoeus::Request.new("www.example.com", followlocation: true)) }
hydra.run
```

## Installation

```
gem install typhoeus
```

```
gem "typhoeus"
```

## Project Tracking

* [Documentation](http://rubydoc.info/github/typhoeus/typhoeus/frames/Typhoeus) (GitHub master)
* [Mailing list](http://groups.google.com/group/typhoeus)

## Usage

### Introduction

The primary interface for Typhoeus is comprised of three classes: Request, Response, and Hydra. Request represents an HTTP request object, response represents an HTTP response, and Hydra manages making parallel HTTP connections.

```ruby
request = Typhoeus::Request.new(
  "www.example.com",
  method: :post,
  body: "this is a request body",
  params: { field1: "a field" },
  headers: { Accept: "text/html" }
)
```

We can see from this that the first argument is the url. The second is a set of options.
The options are all optional. The default for `:method` is `:get`.

When you want to send URL parameters, you can use `:params` hash to do so. Please note that in case of you should send a request via `x-www-form-urlencoded` parameters, you need to use `:body` hash instead. `params` are for URL parameters and `:body` is for the request body.


You can run the query either on its own or through the hydra:

``` ruby
request.run
#=> <Typhoeus::Response ... >
```

```ruby
hydra = Typhoeus::Hydra.hydra
hydra.queue(request)
hydra.run
```

The response object will be set after the request is run.

```ruby
response = request.response
response.code
response.total_time
response.headers_hash
response.body
```

### Making Quick Requests

Typhoeus has some convenience methods for performing single HTTP requests. The arguments are the same as those you pass into the request constructor.

```ruby
Typhoeus.get("www.example.com")
Typhoeus.head("www.example.com")
Typhoeus.put("www.example.com/posts/1", body: "whoo, a body")
Typhoeus.post("www.example.com/posts", body: { title: "test post", content: "this is my test"})
Typhoeus.delete("www.example.com/posts/1")
```

### Handling HTTP errors

You can query the response object to figure out if you had a successful
request or not. Here’s some example code that you might use to handle errors.
The callbacks are executed right after the request is finished, make sure to define
them before running the request.

```ruby
request = Typhoeus::Request.new("www.example.com", followlocation: true)

request.on_complete do |response|
  if response.success?
    # hell yeah
  elsif response.timed_out?
    # aw hell no
    log("got a time out")
  elsif response.code == 0
    # Could not get an http response, something's wrong.
    log(response.return_message)
  else
    # Received a non-successful http response.
    log("HTTP request failed: " + response.code.to_s)
  end
end

request.run
```

This also works with serial (blocking) requests in the same fashion. Both
serial and parallel requests return a Response object.

### Handling file uploads

A File object can be passed as a param for a POST request to handle uploading
files to the server. Typhoeus will upload the file as the original file name
and use Mime::Types to set the content type.

```ruby
Typhoeus.post(
  "http://localhost:3000/posts",
  body: {
    title: "test post",
    content: "this is my test",
    file: File.open("thesis.txt","r")
  }
)
```

### Streaming the response body

Typhoeus can stream responses. When you're expecting a large response,
set the `on_body` callback on a request. Typhoeus will yield to the callback
with chunks of the response, as they're read. When you set an `on_body` callback,
Typhoeus will not store the complete response.

```ruby
downloaded_file = File.open 'huge.iso', 'wb'
request = Typhoeus::Request.new("www.example.com/huge.iso")
request.on_headers do |response|
  if ! response.success?
    raise "Request failed"
  end
end
request.on_body do |chunk|
  downloaded_file.write(chunk)
end
request.on_complete do |response|
  downloaded_file.close
  # Note that response.body is ""
end
request.run
```

### Making Parallel Requests

Generally, you should be running requests through hydra. Here is how that looks

```ruby
hydra = Typhoeus::Hydra.hydra

first_request = Typhoeus::Request.new("www.example.com/posts/1.json")
first_request.on_complete do |response|
  third_request = Typhoeus::Request.new("www.example.com/posts/3.json")
  hydra.queue third_request
end
second_request = Typhoeus::Request.new("www.example.com/posts/2.json")

hydra.queue first_request
hydra.queue second_request
# this is a blocking call that returns once all requests are complete
hydra.run
```

The execution of that code goes something like this. The first and second requests are built and queued. When hydra is run the first and second requests run in parallel. When the first request completes, the third request is then built and queued up. The moment it is queued Hydra starts executing it.  Meanwhile the second request would continue to run (or it could have completed before the first). Once the third request is done, `hydra.run` returns.

### Specifying Max Concurrency

Hydra will also handle how many requests you can make in parallel. Things will get flakey if you try to make too many requests at the same time. The built in limit is 200. When more requests than that are queued up, hydra will save them for later and start the requests as others are finished. You can raise or lower the concurrency limit through the Hydra constructor.

```ruby
Typhoeus::Hydra.new(max_concurrency: 20)
```

### Memoization

Hydra memoizes requests within a single run call. You have to enable memoization.
This will result in a single request being issued. However, the on_complete handlers of both will be called.

```ruby
Typhoeus::Config.memoize = true

hydra = Typhoeus::Hydra.new(max_concurrency: 1)
2.times do
  hydra.queue Typhoeus::Request.new("www.example.com")
end
hydra.run
```

This will result in two requests.

```ruby
Typhoeus::Config.memoize = false

hydra = Typhoeus::Hydra.new(max_concurrency: 1)
2.times do
  hydra.queue Typhoeus::Request.new("www.example.com")
end
hydra.run
```

### Caching

Typhoeus includes built in support for caching. In the following example, if there is a cache hit, the cached object is passed to the on_complete handler of the request object.

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

For use with [Dalli](https://github.com/mperham/dalli):

```ruby
class Cache
  def initialize
    @client = Dalli::Client.new
  end

  def get(request)
    @client.get(request.cache_key)
  end

  def set(request, response)
    @client.set(request.cache_key, response)
  end
end

Typhoeus::Config.cache = Cache.new
```

For use with Rails:

```ruby
class Cache
  def get(request)
    Rails.cache.read(request)
  end

  def set(request, response)
    Rails.cache.write(request, response)
  end
end

Typhoeus::Config.cache = Cache.new
```

### Direct Stubbing

Hydra allows you to stub out specific urls and patterns to avoid hitting
remote servers while testing.

```ruby
response = Typhoeus::Response.new(code: 200, body: "{'name' : 'paul'}")
Typhoeus.stub('www.example.com').and_return(response)

Typhoeus.get("www.example.com") == response
#=> true
```

The queued request will hit the stub. You can also specify a regex to match urls.

```ruby
response = Typhoeus::Response.new(code: 200, body: "{'name' : 'paul'}")
Typhoeus.stub(/example/).and_return(response)

Typhoeus.get("www.example.com") == response
#=> true
```

When testing make sure to clear your expectations or the stubs will persist between tests. The following can be included in your spec_helper.rb file to do this automatically.

```ruby
RSpec.configure do |config|
  config.before :each do
    Typhoeus::Expectation.clear
  end
end
```

### Timeouts

No exceptions are raised on HTTP timeouts. You can check whether a request timed out with the following methods:

```ruby
Typhoeus.get("www.example.com").timed_out?
```

There are two different timeouts available: [`timeout`](http://curl.haxx.se/libcurl/c/curl_easy_setopt.html#CURLOPTTIMEOUT)
and [`connecttimeout`](http://curl.haxx.se/libcurl/c/curl_easy_setopt.html#CURLOPTCONNECTTIMEOUT). `timeout` is the
maximum time in seconds that you allow the libcurl transfer operation to take and `connecttimeout` is the maximum
time in seconds that you allow the connection to the server to take. These two are always available, while `timeout_ms` ond
`connecttimeout_ms` accept milliseconds but only an option when curl is build with `c-ares`, it will use `timout` or `connecttimeout` otherwise.

### Following Redirections

Use `followlocation: true`, eg:

```ruby
Typhoeus.get("www.example.com", followlocation: true)
```

### Basic Authentication

```ruby
Typhoeus::Request.get("www.example.com", userpwd: "user:password")
```

### Cookies

```ruby
Typhoeus::Request.get("www.example.com", cookiefile: "/path/to/file", cookiejar: "/path/to/file")
```

Here, `cookiefile` is a file to read cookies from, and `cookiejar` is a file to write received cookies to.
If you just want cookies enabled, you need to pass the same filename for both options.

### Other CURL options

Are available and documented [here](http://rubydoc.info/github/typhoeus/ethon/Ethon/Easy/Options)

### SSL

SSL comes built in to libcurl so it’s in Typhoeus as well. If you pass in a
url with "https" it should just work assuming that you have your [cert
bundle](http://curl.haxx.se/docs/caextract.html) in order and the server is
verifiable. You must also have libcurl built with SSL support enabled. You can
check that by doing this:

```
curl --version
```

Now, even if you have libcurl built with OpenSSL you may still have a messed
up cert bundle or if you’re hitting a non-verifiable SSL server then you’ll
have to disable peer verification to make SSL work. Like this:

```ruby
Typhoeus.get("https://www.example.com", ssl_verifypeer: false)
```

If you are getting "SSL: certificate subject name does not match target host
name" from curl (ex:- you are trying to access to b.c.host.com when the
certificate subject is \*.host.com). You can disable host verification. Like
this:

```ruby
Typhoeus.get("https://www.example.com", ssl_verifyhost: 2)
```

### Verbose debug output

It’s sometimes useful to see verbose output from curl. You can enable it on a per-request basis:

```ruby
Typhoeus.get("http://example.com", verbose: true)
```

or globally:

```ruby
Typhoeus::Config.verbose = true
```

Just remember that libcurl prints it’s debug output to the console (to
STDERR), so you’ll need to run your scripts from the console to see it.

### Running the specs

Running the specs should be as easy as:

```
bundle install
bundle exec rake
```

## LICENSE

(The MIT License)

Copyright © 2009-2010 [Paul Dix](http://www.pauldix.net/)

Copyright © 2011-2012 [David Balatero](https://github.com/dbalatero/)

Copyright © 2012-2014 [Hans Hasselberg](http://github.com/i0rek/)

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


[![Bitdeli Badge](https://d2weczhvl823v0.cloudfront.net/typhoeus/typhoeus/trend.png)](https://bitdeli.com/free "Bitdeli Badge")


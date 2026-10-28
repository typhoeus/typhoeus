# Upgrade guide

## 1.7

### Ethon 0.19

Typhoeus 1.7 requires Ethon 0.19 (`>= 0.19.0`, `< 0.20.0`). Several conditions
that earlier versions ignored now surface:

- Exceptions raised by `on_body` and `on_complete` callbacks are re-raised.
- `Ethon::Easy` and `Ethon::Multi` handles cannot be inherited across `fork`.
- Unknown enum options and options the loaded libcurl does not support raise
  `Ethon::Errors::InvalidValue` and `Ethon::Errors::UnsupportedOption`.
- Multipart PUT requests are sent as `multipart/form-data`.
- An empty header value suppresses libcurl's default. End the key with a
  semicolon to send an empty value, for example `"X-Empty;" => ""`.
- Verbose output is written through `Ethon.logger` instead of STDERR.

### Progress callbacks

`on_progress` callbacks run only while data is transferred. They are no longer
called with a `Response` when the request completes, and they receive only the
four transfer counters. A block written for five parameters now gets `nil` as
the fifth value.

### Before callbacks

A `before` callback that returns a `Typhoeus::Response` short-circuits the
request. The response is treated as a mock, so it is not cached and `success?`
works for it.

## 0.5

### Options

Fix the option names, because some were renamed. The errors should point you in the right direction:

```ruby
Typhoeus.get("www.example.com", follow_location: true)
# Ethon::Errors::InvalidOption: The option: follow_location is invalid.
# Please try followlocation instead of follow_location.
# ... [Backtrace]

Typhoeus.get("www.example.com", followlocation: true).code
#=> 200
```

### Headers

`Response#headers` returns a hash now and replaces `Response#headers_hash`, use `Response#response_headers` for the raw string:

```ruby
Typhoeus.get("www.example.com", followlocation: true).headers
#=> {
#      "date"=>"Tue, 06 Nov 2012 09:07:27 GMT",
#      "server"=>"Apache/2.2.3 (CentOS)",
#      "last-modified"=>"Wed, 09 Feb 2011 17:13:15 GMT",
#      "vary"=>"Accept-Encoding",
#      "connection"=>"close",
#      "content-type"=>"text/html; charset=UTF-8"
#   }

Typhoeus.get("www.example.com", followlocation: true).response_headers
#=> "HTTP/1.0 302 Found\r\nLocation: http://www.iana.org/domains/example/ [...]"
```

### Params vs body

Make sure every request sends proper params and body (especially POST/PUT). `:params` becomes url parameter and `:body` request body. Before params for POST was smashed into the body.

### Configuration

Create a global configuration in case you want to turn on verbose, memoize or block_connection:

```ruby
Typhoeus.configure do |config|
  config.verbose = true
  config.memoize = true
end
```

### Docs

When in doubt, read the [docs](http://rubydoc.info/github/typhoeus/typhoeus/frames/Typhoeus) or the [code](https://www.github.com/typhoeus).

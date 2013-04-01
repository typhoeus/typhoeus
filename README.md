# Typhoeus [![Build Status](https://secure.travis-ci.org/typhoeus/typhoeus.png)](http://travis-ci.org/typhoeus/typhoeus) [![Code Climate](https://codeclimate.com/github/typhoeus/typhoeus.png)](https://codeclimate.com/github/typhoeus/typhoeus)

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
* [Website](http://typhoeus.github.com/) (v0.4.2)
* [Mailing list](http://groups.google.com/group/typhoeus)

## LICENSE

(The MIT License)

Copyright © 2009-2010 [Paul Dix](http://www.pauldix.net/)

Copyright © 2011-2012 [David Balatero](https://github.com/dbalatero/)

Copyright © 2012-2013 [Hans Hasselberg](http://github.com/i0rek/)

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

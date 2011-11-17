0.3.3
--------------
* Make sure to call the Easy::failure callback on all non-success http response codes, even invalid ones. [balexis]
* Use bytesize instead of length to determine Content-Length [dlamacchia]
* Added SSL version option to Easy/Request [michelbarbosa/dbalatero]

0.3.2
-----
* Fix array params to be consistent with HTTP spec [gridaphobe]
* traversal_to_params_hash should use the escape option [itsmeduncan]
* Fix > 1024 open file descriptors [mschulkind]
* Fixed a bug with internally queued requests being dropped [mschulkind]
* Use gemspec in bundler to avoid duplication [mschulkind]
* Run internally queued requests in FIFO order [mschulkind]
* Moved Typhoeus::VERSION to a separate file, to fix rake build_native [mschulkind]
* Fixed problems related to put requests with empty bodies [skaes, GH-84]
* Added CURLOPT_INTERFACE option via Request#interface=. [spiegela]
* Added Tempfile support to Form#process! [richievos]
* Hydra won't forget to accept gzip/deflate encoding [codesnik]
* Accept and convert strings to integers in Typhoeus::Request#initialize for timeout/cache_timeout/connect_timeout values when using ruby 1.9.x. [djnawara]
* Added interface for registering stub finders [myronmarston]
* Fixed header stubbing [myronmarston]
* Added PKCS12 support [jodell]
* Make a request with handlers marshallable [bernerdschaefer]
* Upgraded to RSpec 2 [bernerdschaefer]
* Fix HTTP status edge-case [balexis]
* Expose primary_ip to easy object [balexis]

0.2.4
-----
* Fix form POSTs to only use multipart for file uploads, otherwise use application/x-www-form-urlencoded [dbalatero]

0.2.3
-----
* Code duplication in Typhoeus::Form led to nested URL param errors on POST only. Fixed [dbalatero]

0.2.2
-----
* Fixed a problem with nested URL params encoding incorrectly [dbalatero]

0.2.1
-----
* Added extended proxy support [Zapotek, GH-46]
* eliminated compile time warnings by using proper type declarations [skaes, GH-54]
* fixed broken calls to rb_raise [skaes, GH-54]
* prevent leaking of curl easy handles when exceptions are raised (either from typhoeus itself or user callbacks) [skaes, GH-54]
* fixed Easy#timed_out? using curl return codes [skaes, GH-54]
* provide curl return codes and corresponding curl error messages on classes Easy and Request [skaes, GH-54]
* allow VCR to whitelist hosts in Typhoeus stubbing/mocking [myronmarston, GH-57]
* added timed_out? documentation, method to Response [dbalatero, GH-34]
* added abort to Hydra to prematurely stop a hydra.run [Zapotek]
* added file upload support for POST requests [jtarchie, GH-59]

0.2.0
------
* Fix warning in Request#headers from attr_accessor
* Params with array values were not parsing into the format that rack expects
[GH-39, smartocci]
* Removed Rack as a dependency [GH-45]
* Added integration hooks for VCR!

0.1.31
------
* Fixed bug in setting compression encoding [morhekil]
* Exposed authentication control methods through Request interface [morhekil]

0.1.30
-----------
* Exposed CURLOPT_CONNECTTIMEOUT_MS to Requests [balexis]

0.1.29
------
* Fixed a memory corruption with using CURLOPT_POSTFIELDS [gravis,
32531d0821aecc4]

0.1.28
----------------
* Added SSL cert options for Typhoeus::Easy [GH-25, gravis]
* Ported SSL cert options to Typhoeus::Request interface [gravis]
* Added support for any HTTP method (purge for Varnish) [ryana]

0.1.27
------
* Added rack as dependency, added dev dependencies to Rakefile [GH-21]

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

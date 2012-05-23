require File.dirname(__FILE__) + '/../lib/typhoeus.rb'
require 'rubygems'
require 'ruby-prof'

calls = 50
url = "http://127.0.0.1:3000/"
Typhoeus.init_easy_object_pool

RubyProf.start
calls.times do |i|
  Typhoeus::Request.get(url+i.to_s)
end
result = RubyProf.stop

printer = RubyProf::FlatPrinter.new(result)
printer.print(STDOUT)

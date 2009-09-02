require 'rubygems'
require 'sinatra'

get '/**' do
  sleep params["delay"].to_i if params.has_key?("delay")
  params.inspect
end

put '/**' do
  puts request.inspect
  puts "**#{request.body.read}**"
end

post '/**' do
  puts request.inspect
  puts "**#{request.body.read}**"
end

delete '/**' do
  puts request.inspect
  puts "**#{request.body.read}**"
end
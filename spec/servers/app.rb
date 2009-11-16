#!/usr/bin/env ruby
require 'rubygems'
require 'sinatra'
require 'json'

@@fail_count = 0
get '/fail/:number' do
  if @@fail_count >= params[:number].to_i
    "ok"
  else
    @@fail_count += 1
    error 500, "oh noes!"
   end
end

get '/fail_forever' do
  error 500, "oh noes!"
end

get '/redirect' do
  redirect '/'
end

get '/bad_redirect' do
  redirect '/bad_redirect'
end

get '/**' do
  sleep params["delay"].to_i if params.has_key?("delay")
  request.env.merge!(:body => request.body.read).to_json
end

put '/**' do
  puts request.inspect
  request.env.merge!(:body => request.body.read).to_json
end

post '/**' do
  puts request.inspect
  request.env.merge!(:body => request.body.read).to_json
end

delete '/**' do
  puts request.inspect
  request.env.merge!(:body => request.body.read).to_json
end

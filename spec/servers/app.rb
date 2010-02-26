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

get '/auth_basic/:username/:password' do
  @auth ||=  Rack::Auth::Basic::Request.new(request.env)
  # Check that we've got a basic auth, and that it's credentials match the ones
  # provided in the request
  if @auth.provided? && @auth.basic? && @auth.credentials == [ params[:username], params[:password] ]
    # auth is valid - confirm it
    true
  else
    # invalid auth - request the authentication
    response['WWW-Authenticate'] = %(Basic realm="Testing HTTP Auth")
    throw(:halt, [401, "Not authorized\n"])
  end
end

get '/auth_ntlm' do
  # we're just checking for the existence if NTLM auth header here. It's validation
  # is too troublesome and really doesn't bother is much, it's up to libcurl to make
  # it valid
  is_ntlm_auth = /^NTLM/ =~ request.env['HTTP_AUTHORIZATION']
  true if is_ntlm_auth
  throw(:halt, [401, "Not authorized\n"]) if !is_ntlm_auth
end

get '/**' do
  sleep params["delay"].to_i if params.has_key?("delay")
  request.env.merge!(:body => request.body.read).to_json
end

head '/**' do
  sleep params["delay"].to_i if params.has_key?("delay")
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

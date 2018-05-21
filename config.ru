#--
# Taken from https://github.com/cloudfoundry/omniauth-uaa-oauth2/blob/master/examples/config.ru
# Cloud Foundry 2012.02.03 Beta
# Copyright (c) [2009-2012] VMware, Inc. All Rights Reserved.
#
# This product is licensed to you under the Apache License, Version 2.0 (the "License").
# You may not use this product except in compliance with the License.
#
# This product includes a number of subcomponents with
# separate copyright notices and license terms. Your use of these
# subcomponents is subject to the terms and conditions of the
# subcomponent's license, as noted in the LICENSE file.
#++

# Run with "bundle exec rackup"

require 'rubygems'
require 'bundler'
require 'sinatra'
require 'omniauth'
require 'omniauth-uaa-oauth2'

class App < Sinatra::Base
  # to fix 'Forbidden errors': http://stackoverflow.com/questions/10509774/sinatra-and-rack-protection-setting
  set :protection, :except => [:json_csrf]

  get '/auth/cloudfoundry/callback' do
    session['auth_hash'] = request.env['omniauth.auth'].to_hash
    redirect session['redirect_to']
  end

  get '/auth/failure' do
    content_type 'text/plain'
    request.env['omniauth.auth'].to_hash.inspect rescue "No Data"
  end

  get '/logout' do
    session.clear
    # landing page = <app-url>/ (cut off path)
    landing_page = request.env['REQUEST_URI'].gsub request.env['REQUEST_PATH'], ''
    redirect "#{ENV['UAA_URL']}/logout.do?client_id=#{ENV['UAA_CLIENT_ID']}&redirect=#{CGI::escape landing_page}"
  end

  get '/*' do
    pass if request.env['REQUEST_PATH'] == '/favicon.ico'

    unless session.key? 'auth_hash'
      session['redirect_to'] = request.env['REQUEST_PATH']
      target_desc = ENV['TARGET_DESC'] || 'SSO'
      <<-HTML
    <ul>
      <li><a href='/auth/cloudfoundry'>Sign in with #{target_desc}</a></li>
    </ul>
      HTML
    else
      <<-HTML
    Requested path: #{request.env['REQUEST_PATH']}<br/><br/>
    User info: #{session['auth_hash']}<br/><br/>
    <a href='/logout'>Logout</a>
      HTML
    end
  end
end

use Rack::Session::Cookie, :key => 'rack.session', :path => '/', :secret => ENV['RACK_COOKIE_SECRET']

use OmniAuth::Builder do
  uaa_url = ENV['UAA_URL']
  provider :cloudfoundry, ENV['UAA_CLIENT_ID'], ENV['UAA_CLIENT_SECRET'],
           {:auth_server_url => uaa_url, :token_server_url => uaa_url}
end

run App.new

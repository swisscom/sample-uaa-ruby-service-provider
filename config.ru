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

  get '/' do
    <<-HTML
    <ul>
      <li><a href='/auth/cloudfoundry'>Sign in with Cloud Foundry</a></li>
    </ul>
    HTML
  end

  get '/auth/cloudfoundry/callback' do
    content_type 'application/json'
    request.env['omniauth.auth'].to_hash.to_json rescue "No Data"
  end
  
  get '/auth/failure' do
    content_type 'text/plain'
    request.env['omniauth.auth'].to_hash.inspect rescue "No Data"
  end
end

use Rack::Session::Cookie, :secret => ENV['RACK_COOKIE_SECRET']

use OmniAuth::Builder do
  uaa_url = ENV['UAA_URL']
  provider :cloudfoundry, ENV['UAA_CLIENT_ID'], ENV['UAA_CLIENT_SECRET'], 
    {:auth_server_url => uaa_url, :token_server_url => uaa_url}
end

run App.new

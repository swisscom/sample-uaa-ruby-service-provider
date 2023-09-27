# Copyright (c) 2018 Swisscom (Switzerland) Ltd.
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may not use
# this file except in compliance with the License. You may obtain a copy of the
# License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software distributed
# under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
# CONDITIONS OF ANY KIND, either express or implied. See the License for the
# specific language governing permissions and limitations under the License.
#

# Run with "bundle exec rackup"
# Based on https://github.com/cloudfoundry/omniauth-uaa-oauth2/blob/master/examples/config.ru

require 'rubygems'
require 'bundler'
require 'sinatra'
require 'omniauth'
require 'omniauth-uaa-oauth2'
require 'cf-app-utils'
require 'uri'
require 'webrick'

CREDS = CF::App::Credentials.find_by_service_tag('oauth2')
abort("No service with tag oauth2 found!") if CREDS.nil?

class App < Sinatra::Base
  # to fix 'Forbidden errors': http://stackoverflow.com/questions/10509774/sinatra-and-rack-protection-setting
  set :protection, :except => [:json_csrf], :logging => Logger::DEBUG

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
    redirect "#{CREDS['logoutEndpoint']}?client_id=#{CREDS['clientId']}&redirect=#{CGI::escape landing_page}"
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

use Rack::Session::Cookie,
  :key => 'rack.session',
  :path => '/',
  :expire_after => 2592000, # In seconds
  :secret => ENV.fetch('SESSION_SECRET') { SecureRandom.hex(64) }

# to fix Rack::Session::Cookie data size exceeds 4K & Rack::Session::Cookie failed to save session. Content dropped.
# (this happens when the user info hash contains a lot of attributes, i.e. all AD groups)
# this effectively means it will store sessions on disk, which will only work with 1 instance
use Rack::Session::Pool

use OmniAuth::Builder do
  OmniAuth.config.allowed_request_methods = %i[get]
  # omnitauth needs only base url and not specific auth and token endpoints. so we just use the base url of authorizationEndpoint
  auth_uri = URI(CREDS['authorizationEndpoint'])
  uaa_url = "#{auth_uri.scheme}://#{auth_uri.host}"
  provider :cloudfoundry, CREDS['clientId'], CREDS['clientSecret'],
           {:auth_server_url => uaa_url, :token_server_url => uaa_url, :scope => CREDS['scope']}
end

run App.new

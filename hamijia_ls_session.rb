require 'eldr'
require 'digest'

require_relative 'db_access'

class HamijiaLsSession < Eldr::App
  include RethinkDB::Shortcuts

  HA_LS_SESSION_TABLE = 'ha_ls_sessions'

  before do
    @conn = Helpers::DbAccess::CONN
  end

  get '/', -> { [200, { 'Content-Type' => 'txt' }, ['O hai der; serving hamijia-ls-session']] }

  get '/lssession/:ls_session_id' do |env|
    req           = Rack::Request.new(env)
    ls_session_id = req.env['eldr.params']['ls_session_id']

    # Try to locate this session_id in the database
    db_resp       = r.table(HA_LS_SESSION_TABLE).get(ls_session_id).run(@conn)

    Rack::Response.new([{ elements: [db_resp] }.to_json], 200, {
                                                          'HTTP_X_API_LOG_ID' => hash['api_request_log_id'],
                                                          'Content-Type'      => 'application/json'
                                                        })
  end

  post '/lssession' do |env|
    req = Rack::Request.new(env)

    hash                       = JSON.parse(req.body.read.to_s)
    hash['api_request_log_id'] = req.env['HTTP_X_API_LOG_ID']

    db_resp = r.table(HA_LS_SESSION_TABLE).insert(hash).run(@conn)
    resp = Rack::Response.new([db_resp.to_json], 201, {
                                                 'HTTP_X_API_LOG_ID' => hash['api_request_log_id'],
                                                 'Content-Type'      => 'application/json'
                                               })
    # Set cookie back _halssession
    unless db_resp['errors'] > 0
      cookie_halssession = Digest::SHA2.new(256).hexdigest(db_resp['generated_keys'].first)
      resp.env['rack.session']['_halsession'] = cookie_halssession
    end

    resp
  end
end
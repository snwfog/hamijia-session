require 'eldr'
require 'digest'

require_relative 'db_access'

class HamijiaLsSession < Eldr::App
  include RethinkDB::Shortcuts

  HA_LS_SESSION_TABLE = 'ha_ls_sessions'

  before do
    @conn = Helpers::DbAccess::CONN
  end

  get '/' do |env|
    resp = Rack::Response.new(['O hai der; serving hamijia-ls-session'], Rack::Utils::HTTP_STATUS_CODES.invert['OK'], { 'Content-Type' => 'txt' })
    resp.set_cookie('_ha_hi_der', 'Hello world')

    resp.to_a
  end

  get '/lssession/:ls_session_id' do |env|
    req           = Rack::Request.new(env)
    ls_session_id = req.env['eldr.params']['ls_session_id']

    # Try to locate this session_id in the database
    db_resp       = r.table(HA_LS_SESSION_TABLE).get(ls_session_id).run(@conn)

    Rack::Response.new([{ elements: [db_resp] }.to_json], 200, {
                                                            'HTTP_X_API_LOG_ID' => hash['api_request_log_id'],
                                                            'Content-Type'      => 'application/json'
                                                        }).to_a
  end

  post '/lssession' do |env|
    req = Rack::Request.new(env)

    hash                      = JSON.parse(req.body.read.to_s)
    hash[:timestamp]          = Time.now.utc
    hash[:api_request_log_id] = req.env['HTTP_X_API_LOG_ID']

    db_resp = r.table(HA_LS_SESSION_TABLE).insert(hash).run(@conn)
    if db_resp['errors'] > 0
      Rack::Response.new([db_resp.to_json], Rack::Utils::HTTP_STATUS_CODES.invert['Bad Request'], {
                                              'HTTP_X_API_LOG_ID' => hash['api_request_log_id'],
                                              'Content-Type'      => 'application/json'
                                          }).to_a
    end

    resp_cookie_halssession = Digest::SHA2.new(256).hexdigest(db_resp['generated_keys'].first)
    resp_inserted_id        = db_resp['generated_keys'].first

    # FIXME: Cookie should come from client
    Rack::Response.new([{ id: resp_inserted_id, session_id: resp_cookie_halssession }.to_json],
                       Rack::Utils::HTTP_STATUS_CODES.invert['Created'], {
                           'HTTP_X_API_LOG_ID' => hash['api_request_log_id'],
                           'Content-Type'      => 'application/json'
                       }).to_a
  end

  # catch app route
  get '/*' do |env|
    req  = Rack::Request.new(env)
    hash = { 'HTTP_X_API_LOG_ID' => req.env['HTTP_X_API_LOG_ID'] } unless req.env['HTTP_X_API_LOG_ID'].nil?
    raise 'Invalid route'
  end
end
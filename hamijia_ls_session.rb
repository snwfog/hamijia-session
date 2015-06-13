require 'eldr'

require_relative 'db_access'

class HamijiaLsSession < Eldr::App
  HA_LS_SESSION_TABLE = 'ha_ls_sessions'

  before do
    @conn = Helpers::DbAccess::CONN
  end

  include RethinkDB::Shortcuts
  get '/', -> { [200, { 'Content-Type' => 'txt' }, ['O hai der; serving hamijia-ls-session']] }

  get '/lssession/:ls_session_id' do |env|
    req           = Rack::Request.new(env)
    ls_session_id = req.env['eldr.params']['ls_session_id']

    # Try to locate this session_id in the database
    db_resp       = r.table(HA_LS_SESSION_TABLE).get(ls_session_id).run(@conn)

    response = Rack::Response.new

    if db_resp
      response.body = [{ elements: [db_resp] }.to_json]
    else
      response.body = [{ elements: [] }.to_json]
    end

    response.header['HTTP_X_API_LOG_ID'] = req.env['HTTP_X_API_LOG_ID']
    response.header['Content-Type']      = 'application/json'

    response
  end

  post '/lssession' do |env|
    req = Rack::Request.new(env)

    hash                       = JSON.parse(req.body.read.to_s)
    hash['api_request_log_id'] = req.env['HTTP_X_API_LOG_ID']

    db_resp = r.table(HA_LS_SESSION_TABLE).insert(hash).run(@conn)

    Rack::Response.new([db_resp.to_json], 201, {
                                          'HTTP_X_API_LOG_ID' => hash['api_request_log_id'],
                                          'Content-Type'      => 'application/json'
                                        })
  end
end
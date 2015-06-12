require 'eldr'

require_relative 'db_access'

class HamijiaLsSession < Eldr::App
  include RethinkDB::Shortcuts
  get '/', -> { [200, { 'Content-Type' => 'txt' }, ['O hai der; serving hamijia-ls-session']] }

  post '/lssession' do |env|
    req = Rack::Request.new(env)
    conn = Helpers::DbAccess::CONN

    hash = JSON.parse(req.body.read.to_s)
    hash['api_request_log_id'] = req.env['HTTP_X_API_LOG_ID']

    resp = r.table('ha_ls_sessions').insert(hash).run(conn)

    Rack::Response.new(resp.to_json)
  end
end
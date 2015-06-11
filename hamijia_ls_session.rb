require 'eldr'

require_relative 'db_access'

class HamijiaLsSession < Eldr::App
  include RethinkDB::Shortcuts
  get '/', -> { [200, { 'Content-Type' => 'txt' }, ['O hai der; serving hamijia-ls-session']] }

  post '/lssession' do |env|
    conn = Helpers::DbAccess::CONN
    request = Rack::Request.new(env)
    hash = JSON.parse(request.body.read.to_s)
    resp = r.table('ha_ls_sessions').insert(hash).run(conn)

    Rack::Response.new(resp.to_json)
  end
end
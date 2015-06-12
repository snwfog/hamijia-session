require 'eldr'

require_relative 'db_access'
class HamijiaApiLog < Eldr::App
  include RethinkDB::Shortcuts

  REQ_API_LOG = 'request_api_log'
  RESP_API_LOG = 'response_api_log'

  def initialize(app)
    @app = app
    @conn = Helpers::DbAccess::CONN
  end

  def call(env)
    req = Rack::Request.new(env)

    # We dont care about the validity of this request
    # We just want to log it

    # Open a new connection to db
    db_document = req.env.map { |k,v| [k, v.to_s] unless k =~ /rack\./ }
    db_resp = r.table(REQ_API_LOG).insert(db_document.compact.to_h).run(@conn)

    unless db_resp['errors'] > 0 || db_resp['inserted'] > 1
      req['X-API-Log-ID'] = db_resp['generated_keys'].first
    end

    status, headers, body = @app.call(req.env)

    # Log the response...
  end
end
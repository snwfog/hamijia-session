require 'eldr'

require_relative 'db_access'
class HamijiaApiLog < Eldr::App
  include RethinkDB::Shortcuts

  REQ_API_LOG  = 'request_api_log'
  RESP_API_LOG = 'response_api_log'

  def initialize(app)
    @app  = app
    @conn = Helpers::DbAccess::CONN
  end

  def call(env)
    req = Rack::Request.new(env)

    # We dont care about the validity of this request
    # We just want to log it
    log_request_and_add_log_header(req)

    resp = @app.call(req.env)

    log_response(resp)
  end

  def log_request_and_add_log_header(req)
    db_document             = Hash[req.env.map { |k, v| [k, v.to_s] unless k =~ /rack\./ }.compact]
    db_document[:timestamp] = Time.now.utc

    db_resp = r.table(REQ_API_LOG).insert(db_document).run(@conn)
    unless db_resp['errors'] > 0 || db_resp['inserted'] > 1
      req.env['HTTP_X_API_LOG_ID'] = db_resp['generated_keys'].first
    end
  end

  def log_response(resp)
    resp = Rack::Response.new(*resp) if resp.kind_of? Array

    r.table(RESP_API_LOG)
        .insert({ api_request_log_id: resp.header.delete('HTTP_X_API_LOG_ID'),
                  timestamp:          Time.now.utc,
                  status:             resp.status,
                  headers:            resp.header.to_h,
                  body:               (resp.header['Content-Type'] =~ /json/ && resp.body.first.kind_of?(String)) ? JSON.parse(resp.body.first) : resp.body.first }).run(@conn)
    resp
  end
end
require 'eldr'
require 'digest'

require_relative 'db_access'

class HamijiaLsSession < Eldr::App
  include RethinkDB::Shortcuts

  HA_LS_SESSION_TABLE = 'ha_ls_sessions'
  HA_OFFER_TABLE      = 'offers'
  HTTP_STATUS_CODES   = Rack::Utils::HTTP_STATUS_CODES.invert

  before do |env|
    @conn      = Helpers::DbAccess::CONN
    @sessionId = env['HTTP_AUTHORIZATION'][-64..-1]
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
                                                          'HTTP_X_API_LOG_ID' => req.env['HTTP_X_API_LOG_ID'],
                                                          'Content-Type'      => 'application/json'
                                                        })
  end

  post '/lssession' do |env|
    req = Rack::Request.new(env)

    body_content              = req.body.read.to_s
    hash                      = body_content.empty? ? {} : JSON.parse(body_content)
    hash[:timestamp]          = Time.now.utc
    hash[:api_request_log_id] = req.env['HTTP_X_API_LOG_ID']

    db_resp = r.table(HA_LS_SESSION_TABLE).insert(hash).run(@conn)
    return build_response([db_resp.to_json], HTTP_STATUS_CODES['Bad Request']) if db_resp['errors'] > 0

    user_session_id_halssession = Digest::SHA2.new(256).hexdigest(db_resp['generated_keys'].first)
    user_id                     = db_resp['generated_keys'].first
    response_obj                = { users: [{ id: user_id, session_id: user_session_id_halssession }] }

    # FIXME: Cookie should come from client
    build_response(response_obj.to_json, HTTP_STATUS_CODES['Created'])
  end

  get '/owner/offers/:id' do |env|
    req            = Rack::Request.new(env)
    owner_offer_id = req.env['eldr.params']['id']
    db_resp        = r.table(HA_OFFER_TABLE).get(owner_offer_id).run(@conn)
    model          = db_resp if (db_resp && db_resp['sessionId'] == @sessionId)
    status_code    = model.nil? ? HTTP_STATUS_CODES['Not Found'] : HTTP_STATUS_CODES['OK']

    build_response({ 'owner/offers' => [model].compact }.to_json, status_code)
  end

  post '/owner/offers' do |env|
    req     = Rack::Request.new(env)
    # raise 'Body should be empty for new offer creation' unless req.body.read.to_s.empty?
    db_resp = r.table(HA_OFFER_TABLE).insert({ timestamp: Time.now.utc, sessionId: @sessionId }).run(@conn)
    raise if db_resp['errors'] > 0
    response_body = { 'owner/offers' => [{ :id => db_resp['generated_keys'].first }] }

    Rack::Response.new(response_body.to_json,
                       Rack::Utils::HTTP_STATUS_CODES.invert['Created'], {
                         'HTTP_X_API_LOG_ID' => env['HTTP_X_API_LOG_ID'],
                         'Content-Type'      => 'application/json'
                       })
  end

  # catch app route
  get '/*' do |env|
    req  = Rack::Request.new(env)
    hash = { 'HTTP_X_API_LOG_ID' => req.env['HTTP_X_API_LOG_ID'] } unless req.env['HTTP_X_API_LOG_ID'].nil?
    raise 'Invalid route'
  end

  private

  def build_response(body, status = HTTP_STATUS_CODES['OK'], header = {})
    header = header.merge({
                            'HTTP_X_API_LOG_ID' => env['HTTP_X_API_LOG_ID'],
                            'Content-Type'      => 'application/json'
                          })


    Rack::Response.new([body], status, header)
  end
end
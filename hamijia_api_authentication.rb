require_relative 'db_access'

class HamijiaApiAuthentication
  def initialize(app)
    @app = app
    @conn = Helpers::DbAccess::CONN
  end

  def call(env)
    req = Rack::Request.new(env)

    return respond_unauthorized unless is_authorized?(req)

    @app.call(env)
  end

  def is_authorized?(req)
    puts req.env['HTTP_AUTHORIZATION']
    return false if req.env['HTTP_AUTHORIZATION'].nil?
    validate_api_key(req.env['HTTP_AUTHORIZATION'])
  end

  def validate_api_key(authorization_header)
    key = authorization_header.match(/(?:Bearer:\s?)([\w-]{64})/).captures.first
    puts "Authenticating key #{key}"

    # Retrieve the api key by the hash digest
    db_resp = r.table('api_key').get_all(key, index: 'key_digest').run(@conn).to_a

    db_resp.length > 0
  end

  def respond_unauthorized
    puts 'Unauthorized access'

    response = Rack::Response.new
    response.write 'unauthorized'
    response.body = ['unauthorized']
    response.status = 401

    response.finish
  end
end
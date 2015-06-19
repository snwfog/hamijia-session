class HamijiaRobustness
  def initialize(app)
    @app = app
  end

  def call(env)
    @app.call(env)
  rescue
    [400, { 'Content-Type' => 'application/json' }, [{ errors: 'Something went wrong' }.to_json]]
  end
end
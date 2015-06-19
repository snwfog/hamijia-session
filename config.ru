require 'rack/cors'

require_relative 'hamijia_robustness'
require_relative 'hamijia_api_log'
require_relative 'hamijia_api_authentication'
require_relative 'hamijia_ls_session'

use Rack::Session::Cookie
use Rack::Cors do
  allow do
    origins '*'
    resource '*', :headers => :any, :methods => %i(get post options)
  end
end
use HamijiaRobustness
use HamijiaApiLog
use HamijiaApiAuthentication
run HamijiaLsSession

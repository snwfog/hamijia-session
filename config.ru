require_relative 'hamijia_robustness'
require_relative 'hamijia_api_log'
require_relative 'hamijia_api_authentication'
require_relative 'hamijia_ls_session'

use Rack::Session::Cookie
use HamijiaRobustness
use HamijiaApiLog
use HamijiaApiAuthentication
run HamijiaLsSession

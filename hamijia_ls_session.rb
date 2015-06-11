require 'eldr'

require_relative 'db_access'

class HamijiaLsSession < Eldr::App
  get '/', -> { [200, { 'Content-Type' => 'txt' }, ['O hai der; serving hamijia-ls-session']] }

  post '/lssession' do |env|
    conn = Helpers::DbAccess::CONN
    puts conn
    puts env
  end
end
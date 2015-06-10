require 'eldr'

class HamijiaLsSession < Eldr::App
  get '/', -> { [200, { 'Content-Type' => 'txt' }, ['O hai der; serving hamijia-ls-session']] }
end
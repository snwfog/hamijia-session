require 'yaml'
require 'pry-byebug'
require 'colorize'
require 'rethinkdb'
require 'securerandom'

include RethinkDB::Shortcuts

db_config                            = YAML.load_file('database.yml')
port, host, database, suffix, tables = db_config['port'], db_config['host'], db_config['database'], db_config['suffix'], db_config['tables']
COMPLETE_DB_NAME                     = database + '_' + suffix
CONN                                 = r.connect(host: host, port: port, db: COMPLETE_DB_NAME)

API_KEY_TABLE = 'api_key' # lol

namespace :db do
  desc 'Create the local database'
  task :create do
    begin
      puts "Creating database #{COMPLETE_DB_NAME}...".green
      conn = r.connect(host: host, port: port, db: COMPLETE_DB_NAME)
      db   = r.db_create(COMPLETE_DB_NAME).run(conn)
      if db['created'] == 1
        puts "Successful creating #{COMPLETE_DB_NAME} on #{host}"
      else
        raise 'Failed creating db'
      end
    rescue RethinkDB::RqlRuntimeError => e
      puts e.to_s.green
    rescue Exception => e
      puts "Something when wrong... #{e}".red
    end
  end

  desc 'Setting up rethinkdb'
  task :setup do
    conn = r.connect(host: host, port: port, db: COMPLETE_DB_NAME) do |conn|
      res = tables.map do |t|
        begin
          r.table_create(t).run conn
        rescue RethinkDB::RqlRuntimeError => e
          puts e.to_s.red
        end
      end
    end
  end

  desc 'Apply index'
  task :index do
    puts 'Applying index on "key" column of "api_key" table'.yellow
    r.table(API_KEY_TABLE).index_create('key').run(CONN)
  end
end

namespace :api do
  desc 'Generate some api key'
  task :gen, [:number_of_api_key] do |t, args|
    number = args[:number_of_api_key].to_i
    puts "Going to generate #{number} API keys".green
    number.times do
      begin
        api_key = 'HA' + SecureRandom.hex(6).scan(/[\w]{4}/).join('-').upcase
        res     = r.table(API_KEY_TABLE).insert({ key: api_key }).run(CONN)
        # WARNING: Insert
        if res['inserted'] == 1
          puts "Inserting #{api_key}".green
        else
          raise "Key #{api_key} was not inserted properly"
        end
      ensure
        puts res.to_s.yellow
      end
    end
  end

  desc 'List api keys'
  task :list do
    r.table(API_KEY_TABLE).run(CONN).each do |api_key|
      puts api_key.to_s.yellow
    end
  end
end


# puts "This is blue".colorize(:blue)
# puts "This is light blue".colorize(:light_blue)
# puts "This is also blue".colorize(:color => :blue)
# puts "This is light blue with red background".colorize(:color => :light_blue, :background => :red)
# puts "This is light blue with red background".colorize(:light_blue ).colorize( :background => :red)
# puts "This is blue text on red".blue.on_red
# puts "This is red on blue".colorize(:red).on_blue
# puts "This is red on blue and underline".colorize(:red).on_blue.underline
# puts "This is blue text on red".blue.on_red.blink
# puts "This is uncolorized".blue.on_red.uncolorize
#
# String.colors                       # return array of all possible colors names
# String.modes                        # return array of all possible modes
# String.color_samples                # displays color samples in all combinations
# String.disable_colorization         # check if colorization is disabled
# String.disable_colorization = false # enable colorization
# String.disable_colorization false   # enable colorization
# String.disable_colorization = true  # disable colorization
# String.disable_colorization true    # disable colorization

# :black
# :red
# :green
# :yellow
# :blue
# :magenta
# :cyan
# :white

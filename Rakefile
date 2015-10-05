require 'yaml'
require 'pry-byebug'
require 'colorize'
require 'rethinkdb'
require 'securerandom'
require 'digest'

include RethinkDB::Shortcuts

db_config                            = YAML.load_file('database.yml')
port, host, database, suffix, tables = db_config['port'], db_config['host'], db_config['database'], db_config['suffix'], db_config['tables']
COMPLETE_DB_NAME                     = database + '_' + suffix
CONN                                 = r.connect(host: host, port: port, db: COMPLETE_DB_NAME)

APP_PATH      = File.dirname(__FILE__)
REMOTE_DIR    = '/home/ubuntu/hamijia/hamijia-ls-session'
REMOTE_HOST   = 'ec2.hamijia-ls-session'
EXCLUDED_PATH = %w(.* vendor tmp)

API_KEY_TABLE = 'api_key' # FIXME: plurialize
OFFER_TABLE = 'offers'

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
    indices = Hash[ API_KEY_TABLE, %w(key key_digest), OFFER_TABLE, %w(sessionId)]

    indices.each do |k, idxArray|
      list_index = r.table(k).index_list().run(CONN)

      idxArray.each do |idx|
        unless list_index.index idx
          puts "Creating index #{idx} on table #{k}".yellow
          r.table(k).index_create(idx).run(CONN)
        end
      end
    end
  end
end

namespace :api do
  desc 'Generate some api key'
  task :gen, [:api_user] do |t, args|
    api_client = args[:api_user]
    puts "Going to generate an API keys for user #{api_client}".magenta

    begin
      api_key = 'HA' + SecureRandom.hex(6).scan(/[\w]{4}/).join('-').upcase
      res     = r.table(API_KEY_TABLE).insert({ key:        api_key,
                                                key_digest: Digest::SHA2.new(256).hexdigest(api_key),
                                                api_client: api_client }).run(CONN)

      # puts Digest::SHA2.new(256).hexdigest(api_key)
      # binding.pry
      # WARNING: Insert
      if res['inserted'] == 1
        puts "Generated"
        puts "APIKEY: #{api_key}".yellow.on_light_black
        puts "DIGEST: #{Digest::SHA2.new(256).hexdigest(api_key)}"
      else
        raise "Key #{api_key} was not inserted properly"
      end
    ensure
      puts res.to_s.green
    end
  end

  desc 'List api keys'
  task :list do
    r.table(API_KEY_TABLE).run(CONN).each do |api_key|
      puts api_key.to_s.yellow
    end
  end
end

# Deployment
namespace :dep do
  desc 'Rsync local file to remote dir'
  task :sync, [:debug] do |t, args|
    # Sync the project folder with remote dir
    puts 'Syncing remote app folder...'.blue
    exclude_list = EXCLUDED_PATH.inject('') { |sum, path| sum << %Q( --exclude '#{path}') }
    sh "rsync --delete #{'--quiet' unless args[:debug] =~ /d/i} -IravzP #{APP_PATH}/ #{REMOTE_HOST}:#{REMOTE_DIR}/ #{exclude_list}"
  end

  desc 'Create deployment dir'
  task :setup do
    # Create deployment dir
    puts "Creating deployment dir #{REMOTE_DIR}...".blue
    sh "ssh ubuntu@#{REMOTE_HOST} 'mkdir -p #{REMOTE_DIR}'" do |ok, res|
      if ok
        puts 'Created.'.green
      else
        puts "Failed to create dir #{REMOTE_DIR}. (#{res.to_s})".red
      end
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

require 'rethinkdb'
include RethinkDB::Shortcuts

module Helpers
  module DbAccess
    db_config = YAML.load_file('database.yml')
    CONN      = r.connect(db_config).use("#{db_config['database']}_#{db_config['suffix']}")
  end
end

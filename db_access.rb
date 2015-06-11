require 'rethinkdb'
include RethinkDB::Shortcuts

module Helpers
  module DbAccess
    db_config                            = YAML.load_file('database.yml')
    port, host, database, suffix, tables = db_config['port'], db_config['host'], db_config['database'], db_config['suffix'], db_config['tables']
    COMPLETE_DB_NAME                     = database + '_' + suffix
    CONN                                 = r.connect(host: host, port: port, db: COMPLETE_DB_NAME)
  end
end

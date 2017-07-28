# frozen_string_literal: true

# Based on:
#   https://github.com/ReneB/activerecord-like/blob/72ca9d3c11f3d5a34f9bee530df5d43303259f51/test/helper.rb

module Test
  module Postgres
    def self.connect_db
      ActiveRecord::Base.establish_connection(postgres_config)
    end

    def self.drop_and_create_database
      # drops and create need to be performed with a connection to the 'postgres' (system) database
      temp_connection = postgres_config.merge(database: "postgres", schema_search_path: "public")
      ActiveRecord::Base.establish_connection(temp_connection)

      # drop the old database (if it exists)
      ActiveRecord::Base.connection.drop_database(database_name)

      # create new
      ActiveRecord::Base.connection.create_database(database_name)
    end

    def self.postgres_config
      @postgres_config ||= {
                             adapter:   "postgresql",
                             database:  database_name,
                             username:  "postgres",
                           }
    end

    def self.database_name
      "activerecord_where_assoc"
    end
  end

  module SQLite3
    def self.connect_db
      ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")
    end

    def self.drop_and_create_database
      # NOOP for SQLite3
    end
  end

  module MySQL
    def self.connect_db
      ActiveRecord::Base.establish_connection(mysql_config)
    end

    def self.drop_and_create_database
      temp_connection = mysql_config.merge(database: "mysql")

      ActiveRecord::Base.establish_connection(temp_connection)

      # drop the old database (if it exists)
      ActiveRecord::Base.connection.drop_database(database_name)

      # create new
      ActiveRecord::Base.connection.create_database(database_name)
    end

    def self.mysql_config
      @mysql_config ||= {
                          adapter:   "mysql2",
                          database:  database_name,
                          username:  db_user_name,
                        }
    end

    def self.db_user_name
      # change this to whatever your config requires
      ENV["TRAVIS"] ? "travis" : "root"
    end

    def self.database_name
      "activerecord_where_assoc"
    end
  end
end

case ENV["DB"]
when "pg"
  Test::SelectedDBHelper = Test::Postgres
when "sqlite3"
  Test::SelectedDBHelper = Test::SQLite3
when "mysql"
  Test::SelectedDBHelper = Test::MySQL
else
  puts "No DB environment variable provided, testing using SQLite3"
  Test::SelectedDBHelper = Test::SQLite3
end

Test::SelectedDBHelper.drop_and_create_database
Test::SelectedDBHelper.connect_db

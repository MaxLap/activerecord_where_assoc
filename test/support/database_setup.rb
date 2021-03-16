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
                             host: "localhost",
                             port: 5432,
                             database:  database_name,
                             username:  db_user_name,
                             password: db_password,
                           }
    end

    def self.database_name
      "activerecord_where_assoc"
    end

    def self.db_user_name
      return ENV["PGUSER"] if ENV["PGUSER"].present?
      `whoami`.strip
    end

    def self.db_password
      return ENV["PGPASSWORD"] if ENV["PGPASSWORD"].present?
      nil
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
                          password:  db_password,
                          collation: 'utf8_general_ci',
                        }
    end

    def self.db_user_name
      return ENV["MYSQL_USER"] if ENV["MYSQL_USER"].present?
      `whoami`
    end

    def self.db_password
      return ENV["MYSQL_PASSWORD"] if ENV["MYSQL_PASSWORD"].present?
      nil
    end

    def self.database_name
      "activerecord_where_assoc"
    end
  end
end

if ENV["DB"].blank?
  puts "No DB environment variable provided, testing using SQLite3"
  ENV["DB"] = "sqlite3"
end

case ENV["DB"]
when "pg", "postgres", "postgresql"
  Test::SelectedDBHelper = Test::Postgres
when "sqlite3"
  Test::SelectedDBHelper = Test::SQLite3
when "mysql"
  Test::SelectedDBHelper = Test::MySQL
else
  raise "Unhandled DB parameter: #{ENV['DB'].inspect}"
end

Test::SelectedDBHelper.drop_and_create_database unless ENV["CI"]
Test::SelectedDBHelper.connect_db

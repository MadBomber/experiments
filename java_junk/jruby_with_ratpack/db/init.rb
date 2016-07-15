raise "No DATABASE_URL found!" unless ENV['DATABASE_URL']
DB = Sequel.connect(JdbcUrl.from_database_url)

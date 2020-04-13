class Database
    def self.establish_connection(path)
        @@db = SQLite3::Database.open(path)
    end
end
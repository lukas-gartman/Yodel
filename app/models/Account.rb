class Account < Database
    attr_reader :id, :username
    attr_accessor :karma, :coords, :rank

    def initialize(username)
        user = @@db.execute("SELECT * FROM accounts WHERE username = ?", username).first
        @id = user[0]
        @username = user[1]
        @karma = user[4]
        @coords = "0.0,0.0"
        if user[5] == 1
            @rank = :mod
        elsif user[5] == 2
            @rank = :admin
        else
            @rank = :user
        end
    end

    def self.create(username, password, email)
        bcrypt_password = BCrypt::Password.create(password)
		@@db.execute("INSERT INTO accounts (username, password, email) VALUES (?, ?, ?)", username, bcrypt_password, email)
    end

    def self.username_available?(username)
        username_check = @@db.execute("SELECT username FROM accounts WHERE username = ?", username)
        username_check[0].nil? ? true : false
    end

    def self.email_available?(email)
        email_check = @@db.execute("SELECT email FROM accounts WHERE email = ?", email)
        email_check[0].nil? ? true : false
    end

    def self.auth(username, password)
        user_info = @@db.execute("SELECT username, password FROM accounts WHERE username = ?", username).first
        if user_info.nil?
            return false
        else
            encrypted_password = user_info[1]
			bcrypt_password = BCrypt::Password.new(encrypted_password)
			bcrypt_password == password ? true : false
		end
    end

    def has_rank?(rank)
        if self.rank == :admin  # admins have access to everything
            return true
        elsif self.rank == :mod
            return true if [:user, :mod].include? rank
        elsif self.rank == rank
            return true
        else
            return false
        end
    end
end
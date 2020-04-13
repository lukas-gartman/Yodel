class Post < Database
    attr_reader :id, :text, :owner, :date, :coords, :color
    attr_accessor :votes, :channel, :comments_count

    def initialize(id, text, owner, date, votes, coords, color, channel)
        @id = id
        @text = text
        @owner = owner
        @date = date
        @votes = votes
        @coords = coords
        @color = color
        @channel = channel
        @comments_count = 0
    end

    def self.create(text, owner, coords, color, channel)
        @@db.execute("INSERT INTO posts (text, owner, coords, color, channel) VALUES (?, ?, ?, ?, ?)", text, owner, coords, color, channel)
    end

    def self.delete(post_id)
        @@db.execute("DELETE FROM posts WHERE id = ?", post_id)
        @@db.execute("DELETE FROM comments WHERE post = ?", post_id)
        @@db.execute("DELETE FROM votes WHERE post = ?", post_id)
        @@db.execute("DELETE FROM pins WHERE post_id = ?", post_id)
    end

    # Get all posts
    def self.get_all
        posts = @@db.execute("SELECT * FROM posts ORDER BY id DESC")

        post_objects = []
        for post in posts
            p = self.new(*post)
            p.comments_count = Comment.get_comments_count(post[0])
            post_objects.push(p)
        end

        return post_objects
    end

    # Get posts in main channel
    def self.get_main_posts
        posts = @@db.execute("SELECT * FROM posts WHERE channel = 0 ORDER BY id DESC")

        post_objects = []
        for post in posts
            p = self.new(*post)
            p.comments_count = Comment.get_comments_count(post[0])
            post_objects.push(p)
        end

        return post_objects
    end

    # Get posts in channels where user is a member (including main channel)
    def self.get_posts(user_channels)
        sql = "SELECT * FROM posts WHERE channel = 0"
        endsql = " ORDER BY id DESC"
        for usr_chan in user_channels
            sql += " OR channel = #{usr_chan.id}"
        end

        query = sql + endsql
        posts = @@db.execute(query)

        post_objects = []
        for post in posts
            p = self.new(*post)
            p.comments_count = self.get_comments_count(post[0])
            post_objects.push(p)
        end

        return post_objects
    end

    def self.get_post(id)
        post = @@db.execute("SELECT * FROM posts WHERE id = ?", id).first
        
        return nil if post.nil?

        p = self.new(*post)
        p.comments_count = self.get_comments_count(post[0])
        return p
    end

    def self.get_channel_posts(channel_id)
        posts = @@db.execute("SELECT * FROM posts WHERE channel = ? ORDER BY id DESC", channel_id)

        post_objects = []
        for post in posts
            p = self.new(*post)
            p.comments_count = self.get_comments_count(post[0])
            post_objects.push(p)
        end

        return post_objects
    end

    def self.get_user_posts(user_id)
        posts = @@db.execute("SELECT * FROM posts WHERE owner = ? ORDER BY id DESC", user_id)

        post_objects = []
        for post in posts
            p = self.new(*post)
            p.comments_count = self.get_comments_count(post[0])
            post_objects.push(p)
        end

        return post_objects
    end

    def self.get_replied_posts(user_id)
        post_ids = @@db.execute("SELECT post FROM comments WHERE owner = ? ORDER BY id DESC", user_id)
        post_ids.uniq!
        
        post_objects = []
        for id in post_ids
            post = self.get_post(id)
            post_objects.push(post)
        end

        return post_objects
    end

    def self.get_pinned_posts(user_id)
        post_ids = @@db.execute("SELECT post_id FROM pins WHERE account_id = ? ORDER BY id DESC", user_id)
        
        post_objects = []
        for id in post_ids
            post = self.get_post(id)
            post_objects.push(post)
        end

        return post_objects
    end

    def self.get_voted_posts(user_id)
        post_ids = @@db.execute("SELECT post FROM votes WHERE account = ? ORDER BY id DESC", user_id)
        post_ids.uniq!
        
        post_objects = []
        for id in post_ids
            post = self.get_post(id)
            post_objects.push(post)
        end

        return post_objects
    end

    def self.get_post_owner(post_id)
        post_owner = @@db.execute("SELECT owner FROM posts WHERE id = ?", post_id).first.first
        return post_owner
    end

    def self.check_pin(post_id, user_id)
        pin_check = @@db.execute("SELECT id FROM pins WHERE account_id = ? AND post_id = ?", user_id, post_id).first
        pin_check.nil? ? false : true
    end

    def self.pin(post_id, user_id)
        @@db.execute("INSERT INTO pins (account_id, post_id) VALUES (?, ?)", user_id, post_id)
    end

    def self.unpin(post_id, user_id)
        @@db.execute("DELETE FROM pins WHERE account_id = ? AND post_id = ?", user_id, post_id)
    end
end
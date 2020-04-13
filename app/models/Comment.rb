class Comment < Post
    attr_reader :id, :text, :post, :owner, :identifier, :date
    attr_accessor :votes

    def initialize(id, text, post, owner, identifier, votes, date)
        @id = id
        @text = text
        @post = post
        @owner = owner
        @identifier = identifier
        @votes = votes
        @date = date
    end

    def superclass.create_comment(post_id, user_id, text)
        comments = @@db.execute("SELECT * FROM comments WHERE post = ?", post_id)
		post_owner = @@db.execute("SELECT owner FROM posts WHERE id = ?", post_id).first.first
		identCheck = @@db.execute("SELECT identifier FROM comments WHERE post = ? AND owner = ?", post_id, user_id).first
		
		if post_owner == user_id
			identifier = 0
		elsif comments.empty?
			identifier = 1
		elsif identCheck.nil?
			identifier = @@db.execute("SELECT identifier FROM comments WHERE post = ? ORDER BY identifier DESC", post_id).first.first
			identifier += 1
		else
			identifier = identCheck
		end

		@@db.execute("INSERT INTO comments (text, post, owner, identifier) VALUES (?, ?, ?, ?)", text, post_id, user_id, identifier)
    end

    def superclass.delete_comment(comment_id)
        @@db.execute("DELETE FROM comments WHERE id = ?", comment_id)
    end

    def superclass.get_comments(post_id)
        comments = @@db.execute("SELECT * FROM comments WHERE post = ?", post_id)

        comment_objects = []
        for comment in comments
            c = Comment.new(*comment)
            comment_objects.push(c)
        end

        return comment_objects
    end

    def superclass.get_comments_count(post_id)
        comments_count = @@db.execute("SELECT COUNT(id) FROM comments WHERE post = ?", post_id).first.first
        return comments_count
    end

    def superclass.get_comment_owner(comment_id)
        comment_owner = @@db.execute("SELECT owner FROM comments WHERE id = ?", comment_id).first.first
        return comment_owner
    end
end
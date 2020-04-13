class Vote < Post
    # Check if user has made a vote
    def superclass.check_vote(post_id, comment_id, user_id)
        vote_check = @@db.execute("SELECT * FROM votes WHERE post = ? AND comment = ? AND account = ?", post_id, comment_id, user_id).first
        vote_check.nil? ? false : true
    end

    def superclass.upvote(post_id, comment_id, user_id)
        post_owner = @@db.execute("SELECT owner FROM posts WHERE id = ?", post_id).first.first
        @@db.execute("INSERT INTO votes (post, account, vote, comment) VALUES (?, ?, ?, ?)", post_id, user_id, 1, comment_id)
        if comment_id == 0
            @@db.execute("UPDATE posts SET votes = votes + 1 WHERE id = ?", post_id)
        else
            @@db.execute("UPDATE comments SET votes = votes + 1 WHERE id = ?", comment_id)
        end
        # adds 10 karma to post/comment owner
        if comment_id == 0
            @@db.execute("UPDATE accounts SET karma = karma + 10 WHERE id = ?", post_owner)
        else
            comment_owner = @@db.execute("SELECT owner FROM comments WHERE id = ?", comment_id).first.first
            @@db.execute("UPDATE accounts SET karma = karma + 10 WHERE id = ?", comment_owner)
        end
        # 2 karma for each upvote
        @@db.execute("UPDATE accounts SET karma = karma + 2 WHERE id = ?", user_id)
    end

    def superclass.downvote(post_id, comment_id, user_id)
        post_owner = @@db.execute("SELECT owner FROM posts WHERE id = ?", post_id).first.first
        @@db.execute("INSERT INTO votes (post, account, vote, comment) VALUES (?, ?, ?, ?)", post_id, user_id, -1, comment_id)
        if comment_id == 0
            @@db.execute("UPDATE posts SET votes = votes - 1 WHERE id = ?", post_id)
        else
            @@db.execute("UPDATE comments SET votes = votes - 1 WHERE id = ?", comment_id)
        end
        # removes 10 karma from post/comment owner
        if comment_id == 0
            @@db.execute("UPDATE accounts SET karma = karma - 10 WHERE id = ?", post_owner)
        else
            comment_owner = @@db.execute("SELECT owner FROM comments WHERE id = ?", comment_id).first.first
            @@db.execute("UPDATE accounts SET karma = karma - 10 WHERE id = ?", comment_owner)
        end
        # -2 karma for each downvote
        @@db.execute("UPDATE accounts SET karma = karma - 2 WHERE id = ?", user_id)
    end
    
    def superclass.get_rating(post_id)
        rating = @@db.execute("SELECT votes FROM posts WHERE id = ?", post_id).first.first
        return rating
    end
end
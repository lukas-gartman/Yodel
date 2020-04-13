class Channel < Post
    attr_reader :id
    attr_accessor :name, :member_count

    def initialize(id, name, member_count)
        @id = id
        @name = name
        @member_count = member_count
    end

    def self.create(name)
        @@db.execute("INSERT INTO channels (name) VALUES (?)", name)
    end

    def self.join(user_id, channel_id)
        @@db.execute("INSERT INTO channel_membership (channel, account) VALUES (?, ?)", channel_id, user_id)
    end

    def self.leave(user_id, channel_id)
        @@db.execute("DELETE FROM channel_membership WHERE channel = ? AND account = ?", channel_id, user_id)
    end

    def self.get_all
        channel_objects = []
        channels = @@db.execute("SELECT * FROM channels")
        for channel in channels
            id = channel[0]
            chan_name = channel[1]
            member_count = self.count_members(id)
            c = self.new(id, chan_name, member_count)
            channel_objects.push(c)
        end
        return channel_objects
    end

    def self.get(channel_id)
        channel = @@db.execute("SELECT * FROM channels WHERE id = ?", channel_id).first
        unless channel.nil?
            name = channel[1]
            member_count = Channel.count_members(channel_id)
            c = Channel.new(channel_id, name, member_count)
            return c
        end
    end

    def self.get_memberships(user_id)
        memberships = @@db.execute("SELECT channel FROM channel_membership WHERE account = ?", user_id)
        channels = []
        unless memberships.nil?
            for channel in memberships
                chan_id = channel[0]
                c = self.get(chan_id)
                channels.push(c)
            end
        end
        
        return channels
    end

    def self.count_members(channel_id)
        member_count = @@db.execute("SELECT COUNT(id) FROM channel_membership WHERE channel = ?", channel_id).first.first
        return member_count
    end

    def self.is_member?(user_id, channel_id)
        member_check = @@db.execute("SELECT id FROM channel_membership WHERE account = ? AND channel = ?", user_id, channel_id).first
        if member_check.nil?
            return false
        else
            return true
        end
    end
end
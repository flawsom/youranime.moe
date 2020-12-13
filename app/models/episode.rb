class Episode < ActiveRecord::Base

    serialize :comments

    include Navigatable

    before_save {
        !self.show_id.nil?
    }

    def number
        return 1 if self.class.first.id == self.id
        result = 1
        self.class.all.each do |ep|
            break if ep.id == self.id
            result += 1
        end
        result
    end

    def show
        return @show unless @show.nil?
        return nil if self.show_id.nil?
        @show = Show.find(self.show_id)
    end

    def is_published?
        return false if self.published.nil?
        self.show.is_published? and self.published
    end

    def previous
        return @previous unless @previous.nil?
        #@previous = Episode.find(self.previous_id) unless self.previous_id.nil?
        #return @previous unless @previous.nil?
        return nil if self.episode_number == 1
        number = self.episode_number-1
        while true
            p "Looking at #{number}..."
            @previous = Episode.find_by(show_id: self.show_id, episode_number: number)
            return nil if @previous.nil?
            return @previous if @previous.is_published?
            number -= 1
        end
    end
    
    def next
        return @next unless @next.nil?
        #@next = Episode.find(self.next_id) unless self.next_id.nil?
        #return @next unless @next.nil?
        number = self.episode_number + 1
        until false
            p "Looking at #{number}"
            @next = Episode.find_by(show_id: self.show_id, episode_number: number)
            return nil if @next.nil?
            return @next if @next.is_published?
            number += 1
        end
        @next = Episode.find_by(show_id: self.show_id, episode_number: (self.episode_number+1))
    end

    def get_path_extension
        return nil if self.path.nil?
        parts = self.path.split "."

        # Only accept the last part, don't accept multiple extensions for videos
        parts[parts.size-1]
    end
    
    def has_previous?
        !self.previous.nil?
    end

    def has_next?
        !self.next.nil?
    end

    def get_path
        return self.path if self.path.nil? or self.path.start_with? "http"
        Config.path self.path
    end

    def get_new_path
        return self.path if self.path.nil? or self.path.start_with? "http"
        video_path = self.path
        parts = video_path.split '/'
        return nil if parts.size <= 2

        # Get the general information
        filename = parts[parts.size-1]
        show_name = parts[parts.size-2]

        # Get the episiode number and extension
        filename_parts = filename.split '.'
        ext = filename_parts[filename_parts.size-1]
        filename_name = filename_parts[0].split 'ep'
        ep_num = filename_name[1] || self.episode_number

        Config.path "videos?show=#{show_name}&episode=#{ep_num}&format=#{ext}&video=true"
    end

    def get_image_path(ext: 'jpg')
        video_path = self.get_path
        parts = video_path.split('/')
        filename = parts[parts.size-1]
        fs = filename.split '.'
        fs[1] = ext.to_s
        filename = fs.join '.'
        parts[parts.size-1] = filename
        parts.join '/'
    end

    def image_path
        'https://img1.ak.crunchyroll.com/i/spire1-tmb/1c0efc486cf747b74d985852857df7d51255463035_wide.jpg'
    end

    def get_new_image_path(ext: 'jpg')
        return self.path if self.path.nil? or self.path.start_with? "http"
        video_path = self.path
        parts = video_path.split '/'
        return nil if parts.size <= 2

        # Get the general information
        filename = parts[parts.size-1]
        show_name = parts[parts.size-2]

        # Get the episiode number and extension
        filename_parts = filename.split '.'
        filename_name = filename_parts[0].split 'ep'
        ep_num = filename_name[1] || self.episode_number

        Config.path "videos?show=#{show_name}&episode=#{ep_num}&format=#{ext}"
    end

    def get_subtitle_path(ext: 'vtt')
        get_image_path ext: ext
    end

    def get_new_subtitle_path(ext: 'vtt')
        path = get_new_image_path ext: ext
        path + "&subtitles=true"
    end

    def has_subs?
        self.show.subbed ? true : false
    end

    def was_watched_by?(user)
        return false if user.episodes_watched.nil? or user.episodes_watched.empty?
        !user.episodes_watched.select { |id| id == self.id }.empty?
    end

    def has_watched_mark?
        !get_watched_mark.nil?
    end

    def get_watched_mark
        80
    end

    def add_comment(comment)
        unless comment.instance_of? Hash
            return {success: false, message: "Invalid data was received."}
        else
            if self.comments.nil?
                self.comments = []
            end
            self.comments.push comment
            save = self.save
            message = save ? 'Comment was received.' : 'There was an error while saving the comment.'
            return {success: save, message: message}
        end
    end

    def get_comments(time: true, usernames: false)
        list = []
        return list if self.comments.nil?
        self.comments.each do |comment|
            next unless comment.instance_of? Hash
            new_comment = {text: comment[:text]}
            if time
                new_comment[:time] = Utils.get_date_from_time(Time.parse(comment[:time].to_s).getlocal)
            end
            if usernames
                user = User.find_by(id: comment[:user_id])
                if user.nil?
                    username = "User ##{comment[:user_id]}"
                else
                    username = user.username
                end
                new_comment[:user_id] = username
            end
            new_comment[:time] = comments[:time] if new_comment[:time].nil?
            new_comment[:user_id] = comments[:user_id] if new_comment[:user_id].nil?
            list.push new_comment
        end
        list
    end

    def self.instances
        [:title, :episode_number]
    end

end

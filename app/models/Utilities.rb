class Utilities
    def self.time_ago_in_words(time)
        timeAgo = (DateTime.now.to_time - DateTime.parse(time).to_time)
        if timeAgo / (60*60*24) < 1
            if timeAgo / (60*60) < 1
                if timeAgo / 60 < 1
                    return "#{timeAgo.to_i}s"
                else
                    return "#{(timeAgo / 60).to_i}min"
                end
            else
                return "#{(timeAgo / (60*60)).to_i}h"
            end
        else
            return "#{(timeAgo / (60*60*24)).to_i}d"
        end
    end

    def self.get_distance_between_coords(coords1, coords2)
        earth_radius = 6371

        coords1 = coords1.split(",")
        lat1 = degrees_to_radians(coords1[0].to_f)
        lon1 = degrees_to_radians(coords1[1].to_f)
        coords2 = coords2.split(",")
        lat2 = degrees_to_radians(coords2[0].to_f)
        lon2 = degrees_to_radians(coords2[1].to_f)

        d_lat = lat2 - lat1
        d_lon = lon2 - lon1

        a = Math.sin(d_lat/2) * Math.sin(d_lat/2) + Math.sin(d_lon/2) * Math.sin(d_lon/2) * Math.cos(lat1) * Math.cos(lat2)
        c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a))
        
        distance = earth_radius * c
        return distance
    end

    def self.degrees_to_radians(degrees)
        return degrees * Math::PI / 180
    end
end
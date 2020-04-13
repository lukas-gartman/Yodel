class Location
    class << self
        attr_accessor :OPENCAGE_API_KEY
    end

    def self.get_city(lat, long)
        geocoder = OpenCage::Geocoder.new(api_key: self.OPENCAGE_API_KEY)
        result = geocoder.reverse_geocode(lat, long)
        city = result.address.split(", ")[1]
        return city
    end
end
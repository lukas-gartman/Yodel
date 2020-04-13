# Use bundler to load gems from Gemfile
require 'bundler'
Bundler.require

# Load the app - Database and Post must be loaded first
require_relative '../app/models/Database.rb'
require_relative '../app/models/Post.rb'
Dir["app/*/*.rb"].each { |file| require_relative "../" + file }
require_relative 'settings.rb'

# Use opencage to reverse geocode data to city name
require 'opencage/geocoder'

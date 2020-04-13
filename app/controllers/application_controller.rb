class ApplicationController < Sinatra::Base
	enable :sessions
	register Sinatra::Flash

	configure do
		set :views, "app/views"
		set :public_dir, "public"
	end
	
	helpers do
		def logged_in?
			session[:username].nil? ? false : true
		end

		def display(file)
			slim file
		end
	end

	# Make sure user is logged in and has the appropriate rank
	set(:auth) do |*ranks|
		condition do
			unless logged_in? && ranks.any? { |rank| @user.has_rank? rank }
				redirect "/login", 303
			end
		end
	end
	
	before do
		if logged_in?
			# Get user info
			@user = Account.new(session[:username])

			# International feed is turned off by default
			session[:international_feed] ||= false
			@international_feed = session[:international_feed]

			# Check if user has a location
			if session[:location]
				if @international_feed
					@location = "International Feed"
					@user.coords = "0.0,0.0"
				else
					@location = session[:location]
					@user.coords = session[:user_coords]
				end
			else
				session[:international_feed] = true
				@location = "International Feed"
				@user.coords = "0.0,0.0"
			end
		end

		# Default page title
		@title ||= "Yodel"
	end

	not_found do
		@title = "404 Not Found"
		slim :not_found
	end
	
	get '/denied' do
		status 403  # Forbidden
		@title = "Denied"
		slim :denied
	end

	get '/', :auth => :user do
		user_channels = Channel.get_memberships(@user.id)
		if user_channels.empty?
			@posts = Post.get_main_posts
		else
			@posts = Post.get_posts(user_channels)
		end

		slim :index
	end

	get '/register' do
		redirect '/' if logged_in?

		@title = "Register account"

		slim :register
	end

	post '/register' do
		redirect '/' if logged_in?

		username = params['username']
		password = params['password']
		email = params['email']

		errors = []
		errors.push("Username cannot be empty.") if username.empty?
		errors.push("Password cannot be empty.") if password.empty?
		# errors.push("Email cannot be empty.") if email.empty?

		if errors.empty?
			errors.push("Username is already in use.") if !Account.username_available?(username)
			# errors.push("Email is already in use.") if !Account.email_available?(email)

			unless errors.empty?
				flash[:error] = errors
				redirect back
			end
		else
			flash[:error] = errors
			redirect back
		end

		Account.create(username, password, email)
		session[:username] = username
		# flash[:success] = "Welcome to Yodel!"
		redirect '/'
	end

	get '/login' do
		redirect '/' if logged_in?
		
		@title = "Login"
		slim :login
	end

	post '/login' do
		redirect '/' if logged_in?

		username = params['username']
		password = params['password']
		if Account.auth(username, password)
			session[:username] = username
			redirect '/get_location'
		else
			flash[:error] = "Username or password is invalid"
		end

		redirect back
	end

	get '/logout' do
		session.destroy
		redirect '/login'
	end

	get '/post/new', :auth => :user do
		@title = "New post"
        @color = COLORS.sample

		slim :new_post
	end

	post '/post/new', :auth => :user do
		text = params['text']
		coords = @user.coords
		channel = params['chan']
		# Color is sampled in get request
        color = params['color']
        color = COLORS.sample if !COLORS.include?(color)          
        
		if text.empty?
			flash[:error] = "Yodel cannot be empty."
			redirect back
		elsif !channel.empty?
			Post.create(text, @user.id, coords, color, channel)
			redirect "/channel/#{channel}"
		else
			Post.create(text, @user.id, coords, color, 0)
			redirect '/'
		end

		redirect back
	end

	get '/post/:id', :auth => :user do
		id = params['id']
		@post = Post.get_post(id)
		
		if @post.nil?
			status 404  # Not found
			return
		end
		
		@comments = Post.get_comments(id)

		slim :post
	end

	get '/post/:id/delete', :auth => :user do
		id = params['id']
		post_owner = Post.get_post_owner(id)
		if post_owner != @user.id
			status 403  # Forbidden
			redirect back
			# return "Forbidden"
		end

		Post.delete(id)
		redirect '/'
	end

	post '/post/:id/vote/up', :auth => :user do
		id = params['id']

		if Post.check_vote(id, 0, @user.id)
			status 403  # Forbidden
			return "You have already voted"
		end

		post_owner = Post.get_post_owner(id)
		# You can't vote on your own post
		if post_owner == @user.id
			status 403  # Forbidden
			return "You can't vote on your own post"
		end

		Post.upvote(id, 0, @user.id)
	end

	post '/post/:id/vote/down', :auth => :user do
		id = params['id']

		if Post.check_vote(id, 0, @user.id)
			status 403  # Forbidden
			return "You have already voted"
		end

		post_owner = Post.get_post_owner(id)
		# You can't vote on your own post
		if post_owner == @user.id
			status 403  # Forbidden
			return "You can't vote on your own post"
		end

		Post.downvote(id, 0, @user.id)

		# Remove post if it gets 5 downvotes
		rating = Post.get_rating(id)
		Post.delete(id) if rating <= -5
	end

	post '/post/:id/comment', :auth => :user do
		id = params['id']
		text = params['comment']

		Post.create_comment(id, @user.id, text)
		
		redirect back
	end

	get '/comment/:comment/delete', :auth => :user do
		comment_id = params['comment']

		comment_owner = Post.get_comment_owner(comment_id)
		if comment_owner != @user.id
			status 403  # Forbidden
			redirect back
		end

		Post.delete_comment(comment_id)

		redirect back
	end

	post '/post/:post/comment/:comment/vote/up', :auth => :user do
		post_id = params['post']
		comment_id = params['comment']

		if Post.check_vote(post_id, comment_id, @user.id)
			status 403  # Forbidden
			return "You have already voted"
		end

		comment_owner = Post.get_comment_owner(comment_id)
		# You can't vote on your own comment
		if comment_owner == @user.id
			status 403  # Forbidden
			return "You can't vote on your own comment"
		end

		Post.upvote(post_id, comment_id, @user.id)
	end

	post '/post/:post/comment/:comment/vote/down', :auth => :user do
		post_id = params['post']
		comment_id = params['comment']

		if Post.check_vote(post_id, comment_id, @user.id)
			status 403  # Forbidden
			return "You have already voted"
		end

		comment_owner = Post.get_comment_owner(comment_id)
		if comment_owner == @user.id
			status 403  # Forbidden
			return "You can't vote on your own post"
		end

		Post.downvote(post_id, comment_id, @user.id)
	end

	post '/post/pin/:post', :auth => :user do
		post_id = params['post']
		if !Post.check_pin(post_id, @user.id)
			Post.pin(post_id, @user.id)
		end
	end

	post '/post/unpin/:post', :auth => :user do
		post_id = params['post']
		if Post.check_pin(post_id, @user.id)
			Post.unpin(post_id, @user.id)
		end
	end

	get '/channels', :auth => :user do
		@title = "Channels"

		channels = Channel.get_all

		# Find channels where user is a member and separate them from the full channel list
		@member_channels = []
		@other_channels = []
		for channel in channels
			if Channel.is_member?(@user.id, channel.id)
				@member_channels.push(channel)
			else
				@other_channels.push(channel)
			end
		end

		slim :channels
	end

	post '/channel/new', :auth => :user do
		name = params['name']
		Channel.create(name) unless name.nil?

		redirect '/channels'
	end

	get '/channel/:id', :auth => :user do
		id = params['id'].to_i
		if id <= 0
			redirect '/'
		end

		@channel = Channel.get(id)
		@title = @channel.name

		@member = Channel.is_member?(@user.id, id)

		@posts = Post.get_channel_posts(id)

		slim :channel
	end

	get '/channel/:id/join', :auth => :user do
		channel_id = params['id']
		unless Channel.is_member?(@user.id, channel_id)
			Channel.join(@user.id, channel_id)
		end

		redirect back
	end

	get '/channel/:id/leave', :auth => :user do
		channel_id = params['id']
		if Channel.is_member?(@user.id, channel_id)
			Channel.leave(@user.id, channel_id)
		end

		redirect back
	end

	get '/my', :auth => :user do
		slim :my
	end

	get '/my/posts', :auth => :user do
		@posts = Post.get_user_posts(@user.id)
		slim :my_posts
	end

	get '/my/replies', :auth => :user do
		@posts = Post.get_replied_posts(@user.id)
		slim :my_posts
	end

	get '/my/pins', :auth => :user do
		@posts = Post.get_pinned_posts(@user.id)
		slim :my_posts
	end

	get '/my/votes', :auth => :user do
		@posts = Post.get_voted_posts(@user.id)
		slim :my_posts
	end

	get '/switch_feed', :auth => :user do
		if session[:international_feed]
			session[:international_feed] = false
			@user.coords = session[:user_coords]
			@location = session[:location]
		else
			session[:international_feed] = true
			@user.coords = "0.0,0.0"
			@location = "International Feed"
		end

		redirect '/'
	end

	# Location API
	get '/location' do
		unless logged_in?
			json = {
				'error' => {
					'message' => "Access denied"
				}
			}
			return JSON[json]
		end

		lat = params[:lat].to_f
		long = params[:long].to_f

		if lat == 0.0 || long == 0.0
			session[:location] = false
			json = {
				'error' => {
					'message' => "Invalid lat or long parameters"
				}
			}
			return JSON[json]
		end

		unless session[:location]
			city = Location.get_city(lat, long)
			session[:user_coords] = "#{lat},#{long}"
			session[:location] = city
			session[:international_feed] = false

			json = {
				'city' => city
			}
			return JSON[json]
		end

		json = {
			'error' => {
				'message' => "Location has already been gathered for this session"
			}
		}
		return JSON[json]
	end

	get '/get_location', :auth => :user do
		slim :loading
	end
end

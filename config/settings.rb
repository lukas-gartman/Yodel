COLORS = ["orange", "lawngreen", "turquoise", "#ff4d4d", "dodgerblue"]
POST_RADIUS = 10.0

#Slim HTML formatting
Slim::Engine.set_options pretty: true, sort_attrs: false

Database.establish_connection("app/db/db.sqlite")

Location.OPENCAGE_API_KEY = ""

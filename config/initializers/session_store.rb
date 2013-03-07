# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_megalab_v2_session',
  :secret      => '7cf42c2a369b048771c947db3b65555a215c619499dc7094ea5224ed1852efcd7602b7950af7c4ba19039654102c48373cb7d6a79dd9dcab24ed743ebb2f54f1'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store

# Be sure to restart your server when you modify this file.

Ce2::Application.config.session_store :redis_store

#Ce2::Application.config.session_store :cookie_store, key: '_ce2_session'

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rails generate session_migration")
# Ce2::Application.config.session_store :active_record_store

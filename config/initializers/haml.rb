# Adds the ability to use HAML templates in the asset pipeline for use with
# Angular.js partials
Rails.application.assets.register_mime_type 'text/html', '.html'
Rails.application.assets.register_engine '.haml', Tilt::HamlTemplate
#Rails.application.assets.register_engine '.haml', Haml::Template


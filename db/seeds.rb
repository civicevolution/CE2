# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)
# Environment variables (ENV['...']) are set in the file config/application.yml.
# See http://railsapps.github.com/rails-environment-variables.html

#puts 'ROLES'
#YAML.load(ENV['ROLES']).each do |role|
#  Role.where(name: role).first_or_create( without_protection: true )
#  puts 'role: ' << role
#end

puts 'DEFAULT USERS'
user = User.where( email: ENV['ADMIN_EMAIL'].dup ).first_or_create do |user|
  user.name = ENV['ADMIN_NAME'].dup
  user.first_name = ENV['ADMIN_FIRST_NAME'].dup
  user.last_name = ENV['ADMIN_LAST_NAME'].dup
  user.password = ENV['ADMIN_PASSWORD'].dup
  user.password_confirmation = ENV['ADMIN_PASSWORD'].dup
end
puts 'user: ' << user.name
user.add_role :admin

puts 'UNCONFIRMED USER'
unconfirmed_user = User.where( email: ENV['UNCONFIRMED_USER_EMAIL'].dup ).first_or_create do |user|
  user.name = ENV['UNCONFIRMED_USER_NAME'].dup
  user.first_name = ENV['UNCONFIRMED_USER_FIRST_NAME'].dup
  user.last_name = ENV['UNCONFIRMED_USER_LAST_NAME'].dup
  user.password = ENV['UNCONFIRMED_USER_PASSWORD'].dup
  user.password_confirmation = ENV['UNCONFIRMED_USER_PASSWORD'].dup
end

# create a test conversation on initialization
conversation = Conversation.where(id: 3).first_or_create do |conversation|
  conversation.user_id = user.id
  conversation.status = "ready"
  conversation.privacy = {list: true, invite: true, summary: true, comments: true, unknown_users: true, confirmed_privacy: true, confirmed_schedule: true}
  conversation.published = true
end

TitleComment.where( user_id: conversation.user_id, conversation_id: conversation.id ).first_or_create do |title_comment|
  title_comment.text = "Test conversation: #{Time.now.localtime("-08:00").strftime("%m/%d/%Y at %I:%M%p")}"
end

CallToActionComment.where( user_id: conversation.user_id, conversation_id: conversation.id).first_or_create do |cta|
  cta.text = "My first Call-to-action"
end

ConversationComment.where( user_id: conversation.user_id, conversation_id: conversation.id).first_or_create do |comment|
  comment.text = "My first comment, v1"
  comment.purpose = "experience"
end

tag = Tag.where(name: "Testing").first_or_create do |tag|
  tag.user_id = conversation.user_id
  tag.published = true
end

ConversationsTags.where( conversation_id: conversation.id, tag_id: tag.id).first_or_create do |ct|
  ct.published = 1
end

user.add_role :conversation_admin, Conversation.find(conversation.id)
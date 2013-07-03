# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)
# Environment variables (ENV['...']) are set in the file config/application.yml.
# See http://railsapps.github.com/rails-environment-variables.html

puts 'ROLES'
YAML.load(ENV['ROLES']).each do |role|
  Role.where(name: role).first_or_create( without_protection: true )
  puts 'role: ' << role
end

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


puts 'DEMO USER'
demo_user = User.where( email: ENV['DEMO_EMAIL'].dup ).first_or_create do |user|
  user.first_name = ENV['DEMO_FIRST_NAME'].dup
  user.last_name = ENV['DEMO_LAST_NAME'].dup
  user.password = ENV['DEMO_PASSWORD'].dup
  user.password_confirmation = ENV['DEMO_PASSWORD'].dup
end
puts "demo_user: #{demo_user.first_name}  #{demo_user.last_name}  at #{demo_user.email}"


puts "DEMO INITIATIVE"
initiative = Initiative.where(title: 'Demo initiative', description: 'Demo initiative description').first_or_create
puts "demo initiative title: #{initiative.title}"

puts "DEMO ISSUE"
issue = Issue.where(initiative_id: initiative.id, title: 'Demo issue', description: 'Demo issue description').first_or_create do |issue|
  issue.user_id = demo_user.id
  issue.purpose = "demo"
  issue.munged_title = "demo-issue"
end
puts "demo issue title: #{issue.title}"

puts "DEMO QUESTION"
question = Question.where(issue_id: issue.id, text: 'Demo question').first_or_create do |question|
  question.user_id = demo_user.id
  question.purpose = "demo"
end
puts "demo question text = #{question.text}"

puts "DEMO CONVERSATION"
conversation = Conversation.where(question_id: question.id).first_or_create
puts "demo conversation id: #{conversation.id}"

#puts "DEMO COMMENTS"
#['First demo comment', 'Second demo comment', 'Third demo comment'].each do |text|
#  comment = ConversationComment.where(conversation_id: conversation.id, text: text).first_or_create do |comment|
#    comment.user_id = demo_user.id
#  end
#  puts "conversation comment with text: #{comment.text}"
#end
#
#['First summary comment', 'Second summary comment', 'Third summary comment'].each do |text|
#  comment = SummaryComment.where(conversation_id: conversation.id, text: text).first_or_create do |comment|
#    comment.user_id = demo_user.id
#  end
#  puts "summary comment with text: #{comment.text}"
#end

puts "2029 INITIATIVE"
initiative = Initiative.where(title: '2029 and Beyond', description: '2029 and Beyond').first_or_create
puts "demo initiative title: #{initiative.title}"

puts "2029 INITIATIVE CGG Staff"
initiative = Initiative.where(title: '2029 and Beyond CGG Staff', description: '2029 and Beyond CGG Staff').first_or_create
puts "demo initiative title: #{initiative.title}"

puts "NCDD Catalyst Awards"
initiative = Initiative.where(title: 'NCDD Catalyst Awards', description: 'NCDD Catalyst Awards').first_or_create
puts "demo initiative title: #{initiative.title}"

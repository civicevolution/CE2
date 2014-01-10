
$redis =
  if Rails.env.development?
    Redis.new(:host => 'localhost', :port => 6379)
  else
    Redis.new(:host => YAML.load_file("#{Rails.root}/../../shared/config/database.yml")['production']['host'], :port => 6379)
  end

$redis_msg_ctr = 0
require 'logger'
##logger = Logger.new(File.open('sync.log', 'a'))
logger = Logger.new(STDOUT)


namespace :s3 do
  namespace :sync do

    def s3i
      @@s3 ||= s3i_open
    end

    def s3i_open
      s3_config = YAML.load_file(Rails.root.join("config/s3.yml")).symbolize_keys
      s3_key_id = s3_config[:access_key_id]
      s3_access_key = s3_config[:secret_access_key]
      RightAws::S3Interface.new(s3_key_id, s3_access_key, { logger: Rails.logger })
    end

    desc "Sync production bucket to staging."
    namespace :production do
      desc "Sync production bucket to staging."
      task :to_staging => :environment do
        Rake::Task["s3:sync:syncObjects"].execute({ from: "ce-test", to: "ce-users-dev" })
      end
    end

    desc "Sync two s3 buckets."
    task :syncObjects, [ :from, :to ] => :environment do |t, args|
      start_time = Time.now
      logger.info("[#{Time.now}] synchronizing from #{args[:from]} to #{args[:to]}")

      logger.info("[#{Time.now}] fetching keys from #{args[:from]}")
      source_objects_hash = Hash.new
      s3i.incrementally_list_bucket(args[:from], { 'prefix'=>'users/civic_dev', 'marker'=>'', delimiter: '/' }) do |response|
        response[:contents].each do |source_object|
          source_objects_hash[source_object[:key]] = source_object
        end
      end
      puts "Source keys"
      source_objects_hash.each {|key, value| puts "#{key} is #{value}" }

      logger.info("[#{Time.now}] fetching keys from #{args[:to]}")
      target_objects_hash = Hash.new
      s3i.incrementally_list_bucket(args[:to], { 'prefix'=>'users/civic', 'marker'=>'', delimiter: '/' }) do |response|
        response[:contents].each do |target_object|
          target_objects_hash[target_object[:key]] = target_object
        end
      end
      puts "Target keys"
      target_objects_hash.each {|key, value| puts "#{key} is #{value}" }


      logger.info("[#{Time.now}] synchronizing #{source_objects_hash.size} => #{target_objects_hash.size} object(s)")

      source_objects_hash.each do |key, source_object|
        target_object = target_objects_hash[key]
        if (target_object.nil?)
          logger.info(" #{key}: copy")
          s3i.copy(args[:from], key, args[:to], key, :copy, { 'x-amz-acl' => 'public-read' })
          #    copy(src_bucket, src_key, dest_bucket, dest_key=nil, directive=:copy, headers={})

        elsif (DateTime.parse(target_object[:last_modified]) < DateTime.parse(source_object[:last_modified]))
          logger.info(" #{key}: update")
          s3i.copy(args[:from], key, args[:to], key, :copy, { 'x-amz-acl' => 'public-read' })

        else
          logger.info(" #{key}: skip")
        end
      end
      #
      #target_objects_hash.each_key do |key|
      #  if (! source_objects_hash.has_key?(key))
      #    logger.info(" #{key}: delete")
      #    s3i.delete(args[:to], key)
      #  end
      #end

      logger.info("[#{Time.now}] done (#{Time.now - start_time})")
    end
  end
end
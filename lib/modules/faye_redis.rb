require 'multi_json'

module Modules
  module FayeRedis

    SERVER_TIMEOUT = 60
    # TODO should I worry about DEV/PROD differentiation in message queues?
    @ns = '' #Rails.env.development? ? "DEV" : "PROD"
    @message_channel = @ns + '/notifications/messages'

    CHANNEL_NAME =     /^\/(((([a-z]|[A-Z])|[0-9])|(\-|\_|\!|\~|\(|\)|\$|\@)))+(\/(((([a-z]|[A-Z])|[0-9])|(\-|\_|\!|\~|\(|\)|\$|\@)))+)*$/
    CHANNEL_PATTERN =  /^(\/(((([a-z]|[A-Z])|[0-9])|(\-|\_|\!|\~|\(|\)|\$|\@)))+)*\/\*{1,2}$/

    def self.add_session_to_redis(session_id, user, subscribe_channels, publish_channels)
      expire_secs = 60 * 60 * 24 * 2

      # use session_id or user.authentication_token
      session_id ||= user.authentication_token

      # Use a set to assign channels to session subscribe acl
      $redis.sadd "ror_sessions:#{session_id}:subscribe.acl", subscribe_channels unless subscribe_channels.empty?
      $redis.expire "ror_sessions:#{session_id}:subscribe.acl", expire_secs

      # Use a set to assign channels to session publish acl
      $redis.sadd "ror_sessions:#{session_id}:publish.acl", publish_channels unless publish_channels.empty?
      $redis.expire "ror_sessions:#{session_id}:publish.acl", expire_secs

      # Use a hash to assign user data to the session
      if user.nil?
        user = User.new first_name: '', last_name: ''
        user.name_count = 0
        user.code = ''
      end
      $redis.hmset "ror_sessions:#{session_id}:data", 'first', user.first_name, 'last', user.last_name, 'name_count', user.name_count, 'code', user.code
      $redis.expire "ror_sessions:#{session_id}:data", expire_secs

    end

    def self.delete_session_from_redis(session_id)
      Rails.logger.debug "^^^^^^ Modules::FayeRedis::delete_session_from_redis for session_id: #{session_id}"
      $redis.del "ror_sessions:#{session_id}:subscribe.acl"
      $redis.del "ror_sessions:#{session_id}:publish.acl"
      $redis.del "ror_sessions:#{session_id}:data"
    end

    def self.publish(message, channels)
      if message[:data][:id].nil?
        $redis_msg_ctr += 1
        message[:id] = $redis_msg_ctr.to_s(36)
      end

      message = {'channel' => channels, 'data' => message }

      json_message = MultiJson.dump(message)
      channels     = self.expand(message['channel'])
      keys         = channels.map { |c| @ns + "/channels#{c}" }

      Rails.logger.debug "Publish #{message} to #{channels} with keys: #{keys}"

       $redis.sunion(*keys).each do |client_id|
        Rails.logger.debug "keys each #{client_id}"
        #clients.each do |client_id|
          queue = @ns + "/clients/#{client_id}/messages"

          Rails.logger.debug "Queueing for client #{client_id}: #{message}"

          $redis.rpush(queue, json_message)
          $redis.publish(@message_channel, client_id)

          # TODO delete the client queue if the client doesn't exist
          #client_exists(client_id) do |exists|
          #  @redis.del(queue) unless exists
          #end
        #end
      end

    end


    private

    def self.expand(name)
      segments = self.parse(name)
      channels = ['/**', name]

      copy = segments.dup
      copy[copy.size - 1] = '*'
      channels << self.unparse(copy)

      1.upto(segments.size - 1) do |i|
        copy = segments[0...i]
        copy << '**'
        channels << self.unparse(copy)
      end

      channels
    end

    def self.valid?(name)
      CHANNEL_NAME =~ name or
          CHANNEL_PATTERN =~ name
    end

    def self.parse(name)
      return nil unless self.valid?(name)
      name.split('/')[1..-1]
    end

    def self.unparse(segments)
      '/' + segments.join('/')
    end


    #def client_exists(client_id, &callback)
    #  cutoff = get_current_time - (1000 * 1.6 * SERVER_TIMEOUT)
    #
    #  $redis.zscore(@ns + '/clients', client_id) do |score|
    #    callback.call(score.to_i > cutoff)
    #  end
    #end

  end
end

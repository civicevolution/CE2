module Modules
  module PostProcess
    extend ActiveSupport::Concern

    included do
      before_create { @_is_new_record = true }
      after_save :run_post_process
    end

    def run_post_process
      Rails.logger.debug "In run_post_process, call post_process.delay"
      post_process
      Rails.logger.debug "In run_post_process, AFTER call post_process.delay"
    end

    def post_process
      Rails.logger.debug "do post_process"

      AdminMailer.delay.follow_us("PostProcess1A-#{Time.now}@ce.org")
      sleep 10
      AdminMailer.delay.follow_us("PostProcess2A-#{Time.now}@ce.org")
    end
    handle_asynchronously :post_process, :priority => 20, :run_at => Proc.new { 10.seconds.from_now }
  end
end
begin
  #app = release_path.to_s.match(/\/data\/(\w+)/)[1]
  #if app == 'idea'
    Rails.logger.info "Restart: monit restart delayed_job_ce2_ver_1 "
     sudo 'echo "sleep 60 && monit restart delayed_job_ce2_ver_1" | at now'
  #end
rescue Exception => e
  run "echo 'deploy/after_restart.rb error: #{e.message}"
end

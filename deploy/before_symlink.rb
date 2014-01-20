Chef::Log.info("Running deploy/before_symlink.rb...")

#current_release = release_path
#
#execute "rake db:seed" do
#  cwd current_release
#  command "bundle exec rake db:seed"
#end

run_and_ignore_exitcode_and_print_command "cd #{release_path} && /usr/local/bin/bundle exec rake db:seed"
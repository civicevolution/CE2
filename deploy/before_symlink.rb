Chef::Log.info("Running deploy/before_symlink.rb...")

execute "rake db:seed" do
  cwd release_path
  command "bundle exec rake db:seed"
  ignore_failure true
end

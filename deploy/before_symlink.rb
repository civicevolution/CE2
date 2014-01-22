Chef::Log.info("^^^^^^ v1-22-10:32 Running deploy/before_symlink.rb...")

execute "rake db:seed" do
  cwd release_path
  command "bundle exec rake db:seed"
  ignore_failure true
end

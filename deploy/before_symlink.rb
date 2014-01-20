Chef::Log.info("Running deploy/before_symlink.rb...")

current_release = release_path

begin
  execute "rake db:seed" do
    cwd current_release
    command "bundle exec rake db:seed"
  end
rescue
end

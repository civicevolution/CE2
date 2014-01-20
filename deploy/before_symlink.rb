Chef::Log.info("Running deploy/before_symlink.rb...")

pending_migrations = ActiveRecord::Migrator.open(ActiveRecord::Migrator.migrations_paths).pending_migrations
if pending_migrations.any?
  Chef::Log.info("Running deploy/before_symlink.rb - RUN migration before db:seed can run...")
else

  current_release = release_path

  execute "rake db:seed" do
    cwd current_release
    command "bundle exec rake db:seed"
  end

end



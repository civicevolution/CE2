Chef::Log.info("Running deploy/before_symlink.rb...")

current_release = release_path

execute "rake db:seed" do
  cwd current_release
  command "bundle exec rake db:seed"

  not_if do
    ActiveRecord::Migrator.open(ActiveRecord::Migrator.migrations_paths).pending_migrations.any?
  end
end

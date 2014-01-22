Chef::Log.info("Running deploy/before_migrate.rb...")

rails_env = new_resource.environment["RAILS_ENV"]
Chef::Log.info("Precompiling assets for #{rails_env}...")

Chef::Log.info("v1-21-23:54 Precompiling assets into #{current_release}...")

execute "rake assets:precompile" do
  cwd current_release
  command "bundle exec rake assets:precompile"
  environment "RAILS_ENV" => rails_env
  ignore_failure true
end
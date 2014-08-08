# config valid only for Capistrano 3.1
lock '3.1.0'

set :application, 'ce2_ver_1'
#set :repo_url, 'https://github.com/civicevolution/CE2.git'
# use the git@ version for repo for ssh agent forwarding
set :repo_url, 'git@github.com:civicevolution/CE2.git'
#set :branch, 'master'
set :branch, 'api-dev-1'


# Default branch is :master
# ask :branch, proc { `git rev-parse --abbrev-ref HEAD`.chomp }

# Default deploy_to directory is /var/www/my_app
set :deploy_to, '/srv/www/ce2_ver_1'

set :user, "deploy"

# Default value for :scm is :git
# set :scm, :git

# Default value for :format is :pretty
# set :format, :pretty

# Default value for :log_level is :debug
# set :log_level, :debug

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
# set :linked_files, %w{config/database.yml}

# Default value for linked_dirs is []
# set :linked_dirs, %w{bin log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system}

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for keep_releases is 5
# set :keep_releases, 5


namespace :deploy do

  desc 'Restart application'
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      execute "#{shared_path}/scripts/unicorn restart"
      # Your restart mechanism here, for example:
      # execute :touch, release_path.join('tmp/restart.txt')
    end
  end

  after :publishing, :restart

  after :restart, :clear_cache do
    on roles(:web), in: :groups, limit: 3, wait: 10 do
      # Here we can do anything such as:
      # within release_path do
      #   execute :rake, 'cache:clear'
      # end
    end
  end

  desc 'Create a symlink to database.yml before assets:precompile'
  task :create_db_yml_symlink do
    #set :rails_env, (fetch(:rails_env) || fetch(:stage))
    #info "xxxxxxxx Inside create_db_yml_symlink task"
    on roles(:app) do
      set :rails_env, 'production'
      #  set :rails_env, (fetch(:rails_env) || fetch(:stage))
      execute "ln -nfs #{shared_path}/config/database.yml #{release_path}/config/database.yml"
      execute "mkdir #{release_path}/log"
      #execute "ln -nfs #{shared_path}/log/mail.sent.summary.log #{release_path}/log/mail.sent.summary.log"
    end
  end

  before "deploy:assets:precompile", "deploy:create_db_yml_symlink"

end

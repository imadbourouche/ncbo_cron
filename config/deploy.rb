set :author, "ontoportal-lirmm"
set :application, "ncbo_cron"
set :repo_url, "https://github.com/#{fetch(:author)}/#{fetch(:application)}.git"

set :deploy_via, :remote_cache

# Default branch is :master
# ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp

# Default deploy_to directory is /var/www/my_app_name
set :deploy_to, "/srv/ontoportal/#{fetch(:application)}"

# Default value for :log_level is :debug
set :log_level, :debug

# Default value for :linked_files is []
# append :linked_files, "config/database.yml", 'config/master.key'

# Default value for linked_dirs is []
# set :linked_dirs, %w{log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system}
set :linked_dirs, %w{log vendor/bundle tmp/pids tmp/sockets public/system}


# Default value for keep_releases is 5
set :keep_releases, 5
set :config_folder_path, "#{fetch(:application)}/#{fetch(:stage)}"


# If you want to restart using `touch tmp/restart.txt`, add this to your config/deploy.rb:

SSH_JUMPHOST = ENV.include?('SSH_JUMPHOST') ? ENV['SSH_JUMPHOST'] : 'jumpbox.hostname.com'
SSH_JUMPHOST_USER = ENV.include?('SSH_JUMPHOST_USER') ? ENV['SSH_JUMPHOST_USER'] : 'username'

JUMPBOX_PROXY = "#{SSH_JUMPHOST_USER}@#{SSH_JUMPHOST}"
set :ssh_options, {
  user: 'ontoportal',
  forward_agent: 'true',
  keys: %w(config/deploy_id_rsa),
  auth_methods: %w(publickey),
  # use ssh proxy if API servers are on a private network
  proxy: Net::SSH::Proxy::Command.new("ssh #{JUMPBOX_PROXY} -W %h:%p")
}

# private git repo for configuraiton
PRIVATE_CONFIG_REPO = ENV.include?('PRIVATE_CONFIG_REPO') ? ENV['PRIVATE_CONFIG_REPO'] : 'https://your_github_pat_token@github.com/your_organization/ontoportal-configs.git'
desc "Check if agent forwarding is working"
task :forwarding do
  on roles(:all) do |h|
    if test("env | grep SSH_AUTH_SOCK")
      info "Agent forwarding is up to #{h}"
    else
      error "Agent forwarding is NOT up to #{h}"
    end
  end
end

# Smoke test for checking if the service is up
desc 'Smoke test: Check if ncbo_cron service is running'
task :smoke_test do
  on roles(:app), in: :sequence, wait: 5 do
    # Check if the service is running using systemctl
    result = `systemctl is-active ncbo_cron`
    if result.strip == 'active'
      info "ncbo_cron service is up and running!"
    else
      error "ncbo_cron service failed to start."
    end
  end
end

namespace :deploy do

  desc 'Incorporate the private repository content'
  # Get cofiguration from repo if PRIVATE_CONFIG_REPO env var is set
  # or get config from local directory if LOCAL_CONFIG_PATH env var is set
  task :get_config do
    if defined?(PRIVATE_CONFIG_REPO)
      TMP_CONFIG_PATH = "/tmp/#{SecureRandom.hex(15)}".freeze
      on roles(:app) do
        execute "git clone -q #{PRIVATE_CONFIG_REPO} #{TMP_CONFIG_PATH}"
        execute "rsync -av #{TMP_CONFIG_PATH}/#{fetch(:config_folder_path)}/ #{release_path}/"
        execute "rm -rf #{TMP_CONFIG_PATH}"
      end
    elsif defined?(LOCAL_CONFIG_PATH)
      on roles(:app) do
        execute "rsync -av #{LOCAL_CONFIG_PATH}/#{fetch(:application)}/ #{release_path}/"
      end
    end
  end

  desc 'Restart application'
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      # Your restart mechanism here, for example:
      # execute :touch, release_path.join('tmp/restart.txt')
      execute 'sudo systemctl restart ncbo_cron'
      execute 'sleep 5'
    end
  end

  after :updating, :get_config
  after :publishing, :restart
  after :restart, :smoke_test

end

set :application, "cookbook"
set :repository,  "https://github.com/liziane/Cookbook.git"
set :scm, :git
set :user, "pico"
set :port, ENV["PORT"]
set :deploy_to, "/home/#{user}/apps/#{application}"
default_run_options[:pty] = true
set :ssh_options, { forward_agent: true }
set :bundle_flags, "--deployment --quiet --binstubs"
set :deploy_via, :remote_cache
server ENV["SERVER"], :web, :app, :db, primary: true
set :default_environment, {
  'PATH' => "$HOME/.rbenv/shims:$HOME/.rbenv/bin:$PATH"
}

set :branch do
  default_tag = `git tag`.split("\n").last

  tag = Capistrano::CLI.ui.ask "Tag to deploy (make sure to push the tag first): [#{default_tag}] "
  tag = default_tag if tag.empty?
  tag
end

after "deploy", "deploy:cleanup"
after "deploy:cold", "deploy:setup"

namespace :deploy do
  desc "Copies unicorn init script to init.d and symlink nginx"
  task :setup_config, roles: :app do
    run "chmod +x #{current_path}/config/unicorn_init.sh"
    run "#{sudo} ln -nfs #{current_path}/config/nginx.conf /etc/nginx/sites-enabled/#{application}"
    run "#{sudo} ln -nfs #{current_path}/config/unicorn_init.sh /etc/init.d/unicorn"
    run "#{sudo} /usr/sbin/update-rc.d -f unicorn defaults"
  end
  after "deploy:setup", "deploy:setup_config"

  "Restarts unicorn and nginx"
  task :restart do
    run "#{sudo} /etc/init.d/unicorn stop"
    run "#{sudo} service nginx stop"
    run "#{sudo} /etc/init.d/unicorn start"
    run "#{sudo} service nginx start"
  end
end

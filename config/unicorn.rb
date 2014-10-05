root = "/home/pico/apps/cookbook/current"
working_directory root
pid "#{root}/tmp/pids/unicorn.pid"
stderr_path "#{root}/log/unicorn_err.log"
stdout_path "#{root}/log/unicorn_std.log"

listen "/tmp/unicorn.cookbook.sock"

worker_processes 4
timeout 30
preload_app true


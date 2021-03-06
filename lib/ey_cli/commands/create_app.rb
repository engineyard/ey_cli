module EYCli
  module Command
    class CreateApp < Base
      def initialize
        @accounts = EYCli::Controller::Accounts.new
        @apps     = EYCli::Controller::Apps.new
        @envs     = EYCli::Controller::Environments.new
      end

      def invoke
        account = @accounts.fetch_account(options.delete(:account))
        app = @apps.create(account, Dir.pwd, options)
        if app
          env_parser = CreateEnv::EnvParser.new.fill_create_env_options(options)
          if options[:no_env]
            EYCli.term.say("Skipping creation of environment...")
          else
            environment = @envs.create(app, env_parser)
            EYCli.term.say("You can run now 'ey_cli show #{app.name}' to know the status of the application")
          end
        end
        app
      end

      def help
        <<-EOF

It takes its arguments(name, git repository and application type) from the base directory.
Usage: ey_cli create_app

Options:
       --account name             Name of the account to add the application to.
       --name name                Name of the app.
       --git uri                  Git repository uri.
       --type type                Application type, either rack, rails2 or rails3.
       --env_name name            Name of the environment to create.
       --framework_env env        Type of the environment (production, staging...).
       --url url                  Domain name for the app. It accepts comma-separated values.
       --app_instances number     Number of application instances.
       --db_instances number      Number of database slaves.
       --solo                     A single instance for application and database.
       --stack                    App server stack, either passenger, unicorn or trinidad.
       --db_stack                 DB stack, valid options:
                                      mysql (for MySQL 5.0),
                                      mysql5_5 (for MySQL 5.5),
                                      postgresql or postgres9_1 (for PostgreSQL 9.1)
       --no_env                   Prevent to not create a default environment.
       --app_size                 Size of the app instances.
       --db_size                  Size of the db instances.
EOF
      end

      def options_parser
        AppParser.new
      end

      class AppParser
        require 'slop'

        def parse(args)
          opts = Slop.parse(args, {:multiple_switches => false}) do
            on :account, true
            on :name, true
            on :git, true
            on :type, true
            on :env_name, true
            on :framework_env, true
            on :url, true
            on :app_instances, true, :as => :integer
            on :db_instances, true, :as => :integer
            #on :util_instances, true, :as => :integer # FIXME: utils instances are handled differently
            on :solo, false, :default => false
            on :stack, true, :matches => /passenger|unicorn|puma|thin|trinidad/
            on :db_stack, true, :matches => /mysql|postgres/
            on :no_env, false, :default => false
            on :app_size, true do |size|
              CreateEnv::EnvParser.check_instance_size(size)
            end
            on :db_size, true do |size|
              CreateEnv::EnvParser.check_instance_size(size)
            end
          end
          opts.to_hash
        end
      end
    end
  end
end

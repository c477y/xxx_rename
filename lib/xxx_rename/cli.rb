# frozen_string_literal: true

require "thor"

module XxxRename
  class StashAppSubCommand < Thor
    require "json"
    require "xxx_rename/stash_app_client"

    desc "scene_by_fragment", "For use through StashApp scraping only"
    option :config, alias: :c, type: :string, required: false, desc: "path to config file"
    def scene_by_fragment
      XxxRename.logger(**{ "mode" => Log::STASHAPP_LOGGING, "verbose" => options["verbose"] })
      XxxRename.logger.info "Initialising logger in #{Log::STASHAPP_LOGGING} mode"
      config = Contract::ConfigGenerator.new(options).generate!
      StashAppClient.new(config).scene_by_fragment
    end
  end

  class Cli < Thor
    SUPPORTED_SITES = %w[
      adult_time
      babes
      blacked
      blacked_raw
      brazzers
      digital_playground
      elegant_angel
      evil_angel
      goodporn
      jules_jordan
      manuel_ferrara
      mofos
      naughty_america
      nf_busty
      reality_kings
      stash
      tushy
      tushy_raw
      twistys
      vixen
      whale_media
      wicked
      x_empire
      zero_tolerance
    ].freeze

    def self.exit_on_failure?
      true
    end

    desc "version", "Print the CLI version"
    def version
      require_relative "version"
      puts "v#{XxxRename::VERSION}"
    end
    map %w[--version -v] => :version

    long_desc <<-LONGDESC
    Scan files and generate metadata

    For first time users, run the command without any flags to generate a config
    file in $HOME/.config/xxx_rename

    $ xxx_rename generate

    The cli will look for a config file in these three places in order:

    * --config (This takes precedence over everything)

    * $HOME/.config/xxx_rename

    * HOME/xxx_rename

    Examples

    # Scan all files in a given directory and its sub-directories

    $ xxx_rename generate . --nested

    # Force the cli to use `brazzers` to match a file

    $ xxx_rename generate . --verbose --override_site=brazzers

    # Generate a migrations file to rename the matched files

    $ xxx_rename generate . --actions=log_rename_op
    LONGDESC
    desc "generate FILE|FOLDER", "Rename a file or all file(s) inside a given directory"
    option :config,        alias: :c, type: :string,  required: false, desc: "path to config file"
    option :verbose,       alias: :v, type: :boolean, default:  false, desc: "enable verbose logging"
    option :override_site, alias: :s, type: :string,  required: false, desc: "force use an override site",
                           enum: SUPPORTED_SITES
    option :nested,                   type: :boolean, default:  false, desc: "recursively search for all files in the given directory"
    option :force_refresh_datastore,  type: :boolean, default:  false, desc: "force site client to fetch all scenes, if implemented"
    option :actions,       alias: :a, type: :string,  default:  [],    desc: "action to perform on a successful match",
                           enum: %w[sync_to_stash log_rename_op], repeatable: true
    option :force_refresh,            type: :boolean, default:  false, desc: "force match scenes from original sites"
    option :checkpoint,               type: :string,  required: false, desc: "skip all iterations until check-pointed file is matched"
    def generate(object)
      XxxRename.logger(**{ "mode" => Log::CLI_LOGGING, "verbose" => options["verbose"] })
      config = Contract::ConfigGenerator.new(options).generate!
      client = Client.new(config,
                          verbose: options["verbose"],
                          override_site: options["override_site"]&.to_sym,
                          nested: options["nested"],
                          checkpoint: options["checkpoint"])
      client.generate(object)
    rescue Interrupt
      print "Exiting...\n".colorize(:green)
    rescue Errors::FatalError => e
      XxxRename.logger.fatal "#{e.class} #{e.message}".colorize(:red)
      e.backtrace&.each { |x| XxxRename.logger.debug x }
      exit 1
    rescue StandardError => e
      XxxRename.logger.fatal "CLI ran into an unexpected error. Report this on https://github.com/c477y/xxx_rename/issues/new"
      XxxRename.logger.fatal "#{e.class} #{e.message}".colorize(:red)
      e.backtrace&.each { |x| XxxRename.logger.fatal x }
      exit 1
    end

    long_desc <<~LONGDESC
      WARNING: This is a destructive operation as it will rename files
      Run this on a small subset to be sure and run it at your own risk

      Rename files based on operations listed in a migration file.

      All rename files are located in your `generated_files_dir` directory.
      Migration files are plain YAML files of format 'output_YYYYMMDDHHMM.yml'

      Pass a migration file using option --version YYYYMMDDHHMM
      If you want to apply a migration file that you have just created,
        pass the --version as "latest". Or don't pass the --version
        flag and the CLI will use the latest version by default.

      Migration files have the following format:

      ---
      # 0 means the migration is not applied

      # 1 means the migration is applied

      # This flag prevents applying a migration that has already been applied

      ___MIGRATION_STATUS___: 0

      # All operations are stored as an array

      ___RENAME_ACTIONS___:

      # DO NOT MANIPULATE AN ARRAY ITEM! Doing so can result in unexpected

      # behaviour. You can remove an operation from the list entirely, but

      # the recommended way is to discard this migration completely,

      # modify the `output_format` for your file in the config and run the

      # generate command again

      - !ruby/object:XxxRename::Data::FileRenameOp

        attributes:

          :key: eab204175567d39202c1df5895e443be # DO NOT MODIFY THIS#{" "}

          :directory: "/ABSOLUTE/DIRECTORY/TOFILE"

          :source_filename: ORIGINAL_FILENAME.MP4

          :output_filename: NEW_FILENAME.MP4

          :mtime: 2000-01-01 00:00:00.000000000 +00:00

      Example Usage:

      $ xxx_rename migrate --version=202301131252

      $ xxx_rename migrate
    LONGDESC
    desc "migrate --version=VERSION", "Apply a rename migration file"
    option :config, alias: :c, type: :string, required: false, desc: "path to config file"
    option :version, type: :string, default: "latest", desc: "Name of migration file to apply"
    option :verbose, alias: :v, type: :boolean, default: false, desc: "enable verbose logging"
    def migrate
      XxxRename.logger(**{ "mode" => Log::CLI_LOGGING, "verbose" => options["verbose"] })
      config = Contract::ConfigGenerator.new(options.slice("config")).generate!
      MigrationClient.new(config, options["version"]).apply
    rescue Interrupt
      print "Exiting...\n".colorize(:green)
    rescue Errors::FatalError => e
      XxxRename.logger.fatal "#{e.class} #{e.message}".colorize(:red)
      e.backtrace&.each { |x| XxxRename.logger.debug x }
      exit 1
    rescue StandardError => e
      XxxRename.logger.fatal "CLI ran into an unexpected error. Report this on https://github.com/c477y/xxx_rename/issues/new"
      XxxRename.logger.fatal "#{e.class} #{e.message}".colorize(:red)
      e.backtrace&.each { |x| XxxRename.logger.fatal x }
      exit 1
    end

    long_desc <<-LONGDESC
    Reverse the actions taken by the `migrate` command

    Read the help command for more information
    $ xxx_rename help migrate
    LONGDESC
    desc "rollback --version=VERSION", "Rollback a migration"
    option :config, alias: :c, type: :string, required: false, desc: "path to config file"
    option :version, type: :string, default: "latest", desc: "Name of migration file to apply"
    option :verbose, alias: :v, type: :boolean, default: false, desc: "enable verbose logging"
    def rollback
      XxxRename.logger(**{ "mode" => Log::CLI_LOGGING, "verbose" => options["verbose"] })
      config = Contract::ConfigGenerator.new(options.slice("config")).generate!
      MigrationClient.new(config, options["version"]).rollback
    rescue Interrupt
      print "Exiting...\n".colorize(:green)
    rescue Errors::FatalError => e
      XxxRename.logger.fatal "#{e.class} #{e.message}".colorize(:red)
      e.backtrace&.each { |x| XxxRename.logger.debug x }
      exit 1
    rescue StandardError => e
      XxxRename.logger.fatal "CLI ran into an unexpected error. Report this on https://github.com/c477y/xxx_rename/issues/new"
      XxxRename.logger.fatal "#{e.class} #{e.message}".colorize(:red)
      e.backtrace&.each { |x| XxxRename.logger.fatal x }
      exit 1
    end

    desc "stashapp SUBCOMMAND", "Lookup a scene through StashApp"
    subcommand "stashapp", StashAppSubCommand
  end
end

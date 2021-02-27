# frozen_string_literal: true

require "thor"

module XxxRename
  class Cli < Thor
    def self.exit_on_failure?
      true
    end

    desc "rename object", "Rename a file or files inside a folder"
    long_desc <<-LONGDESC
    Rename files downloaded legally from porn sites. Works by finding a scene information
    derived from the file name. Since the API search is a bit unpredictable, the API
    fetches the first 10 matches and finds which name matches the file name of the scene.#{" "}

    Supported sites include:
    1. Brazzers (alias `bz`)
    2. Digital Playground (alias `dp`)

    It should be easy to add support for any other site owned by the
    parent company of Brazzers.

    The first argument can be a single file or a directory.#{" "}

    The mandatory option --site specifies which site you want to use when searching
    for the scene name. Possible values are `bz` and `dp`.

    The optional option --save specifies weather the files are to be renamed and the
    output be generated or just the output file is required. This makes it especially
    useful when there is certain mismatch in the response and you need to manually
    check the generated file to remove any false positives.

    e.g. xxx_rename rename DIRECTORY --site bz --save
    LONGDESC
    option :site, alias: :s, type: :string, required: true
    option :save, alias: :e, type: :boolean, default: false
    option :output, alias: :o, type: :string, required: false

    def rename(dir)
      @op = XxxRename::Output.new(options[:output])
      XxxRename::Validator.validate_rename_input(dir, options[:site])
      begin
        XxxRename::SearchByFilename.new(@op, dir, options[:site], options[:save])
      rescue Interrupt
        say "Exiting...", :green
      rescue StandardError => e
        say "Program ran into an error. Dumping output..."
        say e.message
        e.backtrace.each { |line| say line }
      ensure
        if @op.empty?
          say "Process completed. No files were renamed"
        else
          file = @op.write
          say "Process completed. Output written to #{file}"
        end
      end
    end

    desc "rollback file", "Rollback changes created by the rename tool"
    long_desc <<-LONGDESC
    Rolls back any rename operations made by the tool. Input should
    be the generated file.
    LONGDESC

    def rollback(filename)
      XxxRename::Validator.validate_rename_from_file(filename)
      XxxRename::Rollback.new(filename)
      say "Process completed.", :green
    rescue Interrupt
      say "Exiting...", :green
    end

    desc "rename_via_actor directory", "Attempts to generate scene name with actor name"
    long_desc <<-LONGDESC
    Alternate method to rename files. Assumes that the downloaded videos are stored
    inside directories with the name of the female performer in the video. This method
    first finds the actor details to verify if the name is correct. Once the actor is#{" "}
    verified, the command will fetch all the scenes of the actor and match against all
    the scenes to see if the scenes match.

    Currently, only brazzers is supported. However, it should be easy to implement this
    method for any other site owned by the parent company.

    Usage:

    xxx_rename rename_via_actor DIRECTORY --site "bz"
    LONGDESC
    option :site, alias: :s, type: :string, default: "bz"

    def rename_via_actor(dir)
      XxxRename::Validator.validate_dir dir
      @op = XxxRename::Output.new
      XxxRename::SearchByPerformer.new(@op, dir, options[:site])
    rescue Interrupt
      say "Exiting...", :green
    rescue StandardError => e
      say "Program ran into an error. Dumping output..."
      say e.message
      e.backtrace.each { |line| say line }
    ensure
      if @op.empty?
        say "Process completed. No files were renamed"
      else
        file = @op.write
        say "Process completed. Output written to #{file}"
      end
    end
  end
end

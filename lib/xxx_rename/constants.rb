# frozen_string_literal: true

module XxxRename
  module Constants
    VIDEO_EXTENSIONS = %w[m4v mp4 mov wmv avi mpg mpeg rmvb rm flv asf mkv webm].to_set.freeze

    DEFAULT_HEADERS = {
      "User-Agent" => "Mozilla/5.0 (platform; rv:geckoversion) Gecko/geckotrail Firefox/firefoxversion"
    }.freeze

    EVIL_ANGEL_ORIGINAL_FILE_PATTERN = /
          ^                          # Start of filename
          (?<title>[a-zA-z0-9-]+)   # Name of movie
          _s(?<index>\d{1,2})        # Scene index e.g. s01
          _                          # Underscore
          (?<actors>[a-zA-Z_]+)      # Actors in format ActorName,ActorName
          _\d{3,4}p                  # Scene Resolution
          \.\w+                      # File extension
          $                          # End of filename
          /x.freeze

    GOODPORN_ORIGINAL_FILE_FORMAT =
      /
      ^                          # Start of filename
      [a-z0-9-]+                 # Collection + Title
      -                          # Hyphen
      \d{2}-\d{2}-\d{4}          # Release Date
      (_(480|720|1080)p)?        # Scene Resolution
      \.\w+                      # File extension
      $                          # End of filename
      /x.freeze

    MG_PREMIUM_ORIGINAL_FILE_FORMAT =
      /
      ^                                             # Start of filename
      (?<title>[a-z\-\d]+).*(?<!\d{2}-\d{2}-\d{4})  # Scene Title (should not contain a date format \d{2}-\d{2}-\d{4})
      _                                             # Underscore
      \d{3,4}p                                      # Resolution
      \.\w{3,4}                                     # File extension
      $                                             # End of filename
      /x.freeze

    NAUGHTY_AMERICA_ORIGINAL_FILE_REGEX =
      /
      ^                            # Start of filename
      (?<compressed_scene>[a-z1]+) # Scene Title
      _                            # Underscore
      \d+\w+?                      # Resolution
      \.\w{0,4}                    # File extension
      $                            # End of filename
      /x.freeze

    NF_BUSTY_ORIGINAL_FILE_REGEX =
      /
      ^                            # Start of filename
      nfbusty_                     # Prefix
      (?<title>[a-z0-9_]+)         # Scene Title
      _                            # Underscore
      \d{3,4}                      # Resolution
      \.\w{0,4}                    # File extension
      $                            # End of filename
      /x.freeze

    # These regexes match the files downloaded originally from Vixen Media sites
    VIXEN_MEDIA_SITES = %w[DEEPER VIXEN BLACKEDRAW BLACKED TUSHYRAW TUSHY CHANNELS SLAYED].join("|")
    VIXEN_MEDIA_ORIGINAL_FILE_REGEX_1 = /(?<collection>(#{VIXEN_MEDIA_SITES}))_(?<id>\d*)_\d{3,4}P/x.freeze
    VIXEN_MEDIA_ORIGINAL_FILE_REGEX_2 = /(?<collection>(#{VIXEN_MEDIA_SITES}))_(?<id>\d{6})-.*_\d{3,4}P/x.freeze

    # rubocop:disable Lint/MixedRegexpCaptureTypes
    WHALE_ORIGINAL_FILE_PATTERN =
      /
      ^                            # Start of filename
      (?<site>(nannyspy|spyfam|holed|lubed|myveryfirsttime|tiny4k|povd|fantasyhd|castingcouchx|puremature|passionhd|exotic4k)) # Sitename
      -                            # Hyphen
      (?<title>[a-z0-9-]+)        # Scene Title (might contain random id strings)
      -                            # Hyphen separator for resolution
      \d{3,4}                      # Resolution
      \.\w+                        # File extension
      $                            # End of filename
      /x.freeze
    # rubocop:enable Lint/MixedRegexpCaptureTypes
  end

  module SystemConstants
    def home_dir
      ENV["HOME"]
    end

    def config_file_lookup_dirs
      [
        File.join(home_dir, ".config", "xxx_rename"),
        File.join(home_dir, "xxx_rename")
      ]
    end
  end
end

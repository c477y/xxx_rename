# frozen_string_literal: true

module XxxRename
  module Data
    class SimpleSiteConfig < Base
      attribute :output_format, Types::Array.of(Types::String)
      attribute :file_source_format, Types::Array.of(Types::String)
      attribute :collection_tag, Types::String
    end

    class CredentialsConfig < Base
      attribute? :username, Types::String.optional
      attribute? :password, Types::String.optional
      attribute? :cookie_file, Types::String.optional
      attribute? :api_token, Types::String.optional
    end

    class DatabaseConfig < Base
      attribute? :database, Types::String.optional
    end

    class AdultTimeConfig < Base
      attributes_from Data::SimpleSiteConfig
    end

    class EvilAngelConfig < Base
      attributes_from Data::SimpleSiteConfig
    end

    class ArchAngelConfig < Base
      attributes_from Data::SimpleSiteConfig
      attributes_from Data::DatabaseConfig
    end

    class ElegantAngelConfig < Base
      attributes_from Data::SimpleSiteConfig
      attributes_from Data::DatabaseConfig
    end

    class GoodpornConfig < Base
      attributes_from Data::SimpleSiteConfig
    end

    class JulesJordanMediaConfig < Base
      attributes_from Data::SimpleSiteConfig
      attributes_from Data::CredentialsConfig
      attributes_from Data::DatabaseConfig
    end

    class MgPremiumConfig < Base
      attributes_from Data::SimpleSiteConfig
    end

    class NaughtyAmericaConfig < Base
      attributes_from Data::SimpleSiteConfig
      attributes_from Data::DatabaseConfig
    end

    class NfBustyConfig < Base
      attributes_from Data::SimpleSiteConfig
      attributes_from Data::DatabaseConfig
    end

    class StashDBConfig < Base
      attributes_from Data::SimpleSiteConfig
      attributes_from Data::CredentialsConfig
    end

    class VixenMediaConfig < Base
      attributes_from Data::SimpleSiteConfig
    end

    class WhaleMediaConfig < Base
      attributes_from Data::SimpleSiteConfig
    end

    class WickedConfig < Base
      attributes_from Data::SimpleSiteConfig
    end

    class XEmpireConfig < Base
      attributes_from Data::SimpleSiteConfig
    end

    class ZeroToleranceConfig < Base
      attributes_from Data::SimpleSiteConfig
    end
  end
end

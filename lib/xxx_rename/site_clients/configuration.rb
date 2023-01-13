# frozen_string_literal: true

module XxxRename
  module SiteClients
    module Configuration
      def self.included(base)
        base.extend ClassMethods

        # The `ModuleInheritableAttributes` allows us to use some ruby magic
        base.send :include, HTTParty::ModuleInheritableAttributes
        base.send(:mattr_inheritable, :constants)
        base.instance_variable_set("@constants", {})

        base.class_eval do
          def site_config
            config.site.send(self.class.site_client_name.to_sym)
          end

          def site_client_datastore
            @site_client_datastore ||=
              begin
                datastore_name = site_config.database.presence ? site_config.database : self.class.name.demodulize.underscore
                qualified_name = datastore_name.end_with?(".store") ? datastore_name : "#{datastore_name}.store"
                path = File.join(config.generated_files_dir, self.class.site_client_name.to_s)
                FileUtils.mkpath(path)
                store = Data::SceneDatastore.new(path, qualified_name).store
                Data::SceneDatastoreQuery.new(store, config.mutex)
              end
          end

          # @return [Hash]
          def metadata
            site_client_datastore.metadata
          end

          # @param [Hash] opts
          # @return [Hash]
          def update_metadata(**opts)
            site_client_datastore.update_metadata(opts)
          end
        end
      end

      module ClassMethods
        def site_client_name(name = nil)
          return @constants[:site_client_name] if @constants.key?(:site_client_name)

          raise XxxRename::Errors::FatalError, "#{self.name} did not set its :site_client_name" if name.nil?

          @constants[:site_client_name] = name
        end
      end
    end
  end
end

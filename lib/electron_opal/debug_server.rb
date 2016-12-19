module Electron
  class DebugServer
    SOURCE_MAPS_PREFIX_PATH = '/__OPAL_SOURCE_MAPS__'

    def initialize(config)
      Opal::Config.source_map_enabled = true
      @opal = Opal::Server.new do |s|
        config.paths.each {|path| s.append_path path }
        s.debug = true
      end

      create_app @opal
    end

    def create_app(opal)
      maps_prefix = SOURCE_MAPS_PREFIX_PATH

      maps_app = ::Opal::SourceMapServer.new(opal.sprockets, maps_prefix)
      ::Opal::Sprockets::SourceMapHeaderPatch.inject!(maps_prefix)

      @app = Rack::Builder.app do
        not_found = lambda { |env| [404, {}, []] }
        use Rack::Deflater
        use Rack::ShowExceptions
        map(maps_prefix) do
          require 'rack/conditionalget'
          require 'rack/etag'
          use Rack::ConditionalGet
          use Rack::ETag
          run maps_app
        end
        map("/") { run opal.sprockets }
        run Rack::Static.new(not_found, urls: ["/"])
      end
    end

    def sprockets
      @opal.sprockets
    end

    def call(env)
      @app.call env
    end
  end
end

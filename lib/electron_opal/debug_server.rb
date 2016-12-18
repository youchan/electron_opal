module Electron
  class DebugServer
    SOURCE_MAPS_PREFIX_PATH = '/__OPAL_SOURCE_MAPS__'

    def initialize env
      Opal::Processor.source_map_enabled = true
      create_app env
    end

    def create_app(env)
      env.logger.level ||= Logger::DEBUG

      maps_prefix = SOURCE_MAPS_PREFIX_PATH
      maps_app = ::Opal::SourceMapServer.new(env, maps_prefix)
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
        map("/")      { run env }
        run Rack::Static.new(not_found, urls: ["/"])
      end
    end

    def call(env)
      @app.call env
    end
  end
end

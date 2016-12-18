require 'erb'
require 'fileutils'
require 'ostruct'
require 'opal/sprockets'
require 'opal-activesupport'
require 'opal-browser'
require 'opal-jquery'
require 'opal-vienna'
require 'rack'
require 'thin'


def env
  @env ||= Sprockets::Environment.new
  @env
end

def config
  return @config if @config
  @config = OpenStruct.new
  @config.paths = Array.new(Opal.paths)
  @config.paths << File.expand_path('../../opal', __FILE__)

  @config.app_class = "main"

  @config
end

def setup(&block)
  block.call config
end

def setup_env
  config.paths.flatten.each { |p| Opal.append_path(p) }
end

task :default do 
  sh "electron ."
end
task :config do 
  config.each_pair do | key, value |
    puts "#{key}: #{value}"
  end
end
task :build do 
  setup_env

  compile_js(config.app_class, load_asset_code: true)

  Dir["app/**/*_window.rb"].each do | file_path |
    asset_name = Pathname.new(file_path).basename(".rb").to_s
    compile_js(asset_name)
    create_html(asset_name)
  end
end
task :debug do 
  setup_env

  Dir["app/**/*_window.rb"].each do | file_path |
    asset_name = Pathname.new(file_path).basename(".rb")
    asset = env.find_asset(asset_name)
    create_debug_html(asset_name, asset)
  end
  Rack::Handler::Thin.run DebugServer.new env
end

def compile_js(asset_name, options={})
  load_asset_code = Opal::Builder.build(asset_name)
  write_to("#{asset_name}.js", load_asset_code)
end

def create_html(asset_name)
  write_to("#{asset_name}.html", Index.new(env, asset_name).html)
end

def create_debug_html(asset_name, asset)
  write_to("#{asset_name}.html", Index.new(env, asset_name, asset, true, "http://localhost:8080/").html)
end

def write_to(filename, source, load_code = "")
  filename = File.join('build', filename)
  FileUtils.mkdir_p File.dirname(filename)

  File.open(filename, 'wb+') do |f|
    f.write source
    f.write load_code
  end
end

class Index

  def initialize(env, name, asset=nil, debug=false, prefix="./")
    @env, @name, @asset, @debug, @prefix= env, name, asset, debug, prefix
  end

  def javascript_include_tag 
    scripts = []
      if @debug
        @asset.to_a.map do |dependency|
          scripts << %{<script src="#{@prefix}#{dependency.logical_path}?body=1"></script>}
        end
      else
        scripts << %{<script src="#{@prefix}#{@name}.js"></script>}
      end

      #scripts << %{<script>#{Opal::Processor.load_asset_code(@env, @name)}</script>}

      scripts.join "\n"
  end

  def html
    <<-HTML
          <!DOCTYPE html>
          <html>
          <head>
            <title>Opal Server</title>
          </head>
          <body>
    #{javascript_include_tag}
          </body>
          </html>
    HTML
  end
end

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

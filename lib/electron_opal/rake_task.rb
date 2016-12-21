require 'opal'
require 'haml'
require 'fssm'
require_relative 'index'
require_relative 'debug_server'

module Electron
  class RakeTask
    include Rake::DSL

    def initialize
      yield config if block_given?

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
        create_package_json

        compile_js(config.app_class, load_asset_code: true)

        Dir["app/**/*_window.rb"].each do |file_path|
          pathname = Pathname.new(file_path)
          asset_name = pathname.basename('.rb').to_s
          compile_js(asset_name)
          create_html(asset_name, haml(pathname).render(Index.new(asset_name)))
        end
      end

      task :debug do
        server = DebugServer.new config
        create_package_json

        Dir["app/**/*_window.rb"].each do |file_path|
          pathname = Pathname.new(file_path)
          asset_name = pathname.basename('.rb').to_s
          haml(pathname) {|haml| create_html(asset_name, haml.render(Index.new(asset_name, server.sprockets, true, "http://localhost:8080/"))) }
        end
        Rack::Handler::Thin.run server
      end
    end

    def compile_js(asset_name, options={})
      asset_code = Opal::Builder.build(asset_name)
      write_to("#{asset_name}.js", asset_code)
      asset_code
    end

    def haml(pathname, &block)
      haml = pathname.parent + "#{pathname.basename('.rb')}.haml"

      if haml.exist? && block
        EM.defer do
          FSSM.monitor(haml.parent, haml.basename) do
            update { block.call(Haml::Engine.new(haml.read)) }
          end
        end
      end

      haml = Pathname.new(File.expand_path('../default.haml', __FILE__)) unless haml.exist?
      engine = Haml::Engine.new(haml.read)
      block.call(engine) if block
      engine
    end

    def create_html(asset_name, haml)
      write_to("#{asset_name}.html", haml)
    end

    def create_package_json
      return if File.exist?('package.json')
      app_name = Pathname.new(File.expand_path('.')).basename.to_s
      package = {
        "name" => app_name,
        "version": "0.0.1",
        "main": "build/main.js"
      }
      File.open('package.json', 'w') {|f| f.write package.to_json}
    end

    def write_to(filename, source, load_code = "")
      filename = File.join('build', filename)
      FileUtils.mkdir_p File.dirname(filename)

      File.open(filename, 'wb+') do |f|
        f.write source
        f.write load_code
      end
    end

    def config
      return @config if @config
      @config = OpenStruct.new
      @config.paths = Array.new(Opal.paths)
      @config.paths << File.expand_path('../../opal', __FILE__)

      @config.app_class = "main"

      @config
    end

    def setup_env
      config.paths.flatten.each { |p| Opal.append_path(p) }
    end
  end
end

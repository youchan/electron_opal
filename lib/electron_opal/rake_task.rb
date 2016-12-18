require 'opal'
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

    def setup_env
      config.paths.flatten.each { |p| Opal.append_path(p) }
    end
  end
end

module Electron
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
end

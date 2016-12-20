module Electron
  class Index
    def initialize(name, sprockets=nil, debug=false, prefix="./")
      @name, @sprockets, @debug, @prefix= name, sprockets, debug, prefix
    end

    def javascript_include_tag 
      if @debug
        Opal::Sprockets.javascript_include_tag(@name, sprockets: @sprockets, prefix: @prefix, debug: true)
      else
        %{<script src="#{@prefix}#{@name}.js"></script>}
      end
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

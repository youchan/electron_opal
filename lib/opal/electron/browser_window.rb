require 'electron'

module Electron
  class BrowserWindow
    include Native

    def initialize(name = 'main_window', params = {}, debug: false)
      `var { BrowserWindow } = require('electron')`
      @native = JS.new(`BrowserWindow`, `params.$to_n()`)
      @native.JS.loadURL("file://#{`__dirname`}/#{name}.html")
      @native.JS[:webContents].JS.openDevTools if debug
      methods_ruby = []
      %x{
        for(var method in #@native) {
          #{methods_ruby << `method`}
        }
      }
      methods_ruby.each do |method|
        next if method[0] == '_'
        BrowserWindow.instance_eval do
          if method.index('is') == 0
            alias_native (method.delete('is') + '?').to_sym, method.to_sym
          elsif method.index('set') == 0
            alias_native (method.delete('set') + '=').to_sym, method.to_sym
          elsif method.index('get') == 0
            alias_native method.delete('get').to_sym, method.to_sym
          else
            alias_native method.to_sym
          end
        end
      end
    end
  end
end

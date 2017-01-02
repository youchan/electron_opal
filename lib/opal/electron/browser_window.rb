require 'electron'

module Electron
  class BrowserWindow
    include Native

    def initialize(name, params = {}, debug: false)
      `var { BrowserWindow } = require('electron')`
      @native = JS.new(`BrowserWindow`, `params.$to_n()`)
      @native.JS.loadURL("file://#{`__dirname`}/main_window.html")
      @native.JS[:webContents].JS.openDevTools if debug
    end

    alias_native :on
  end
end

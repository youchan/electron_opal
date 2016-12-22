require 'native'
require 'js'

module Electron
  class << self
    def app
      native.app
    end

    def native
      @native ||= Native(`require('electron')`)
    end
  end
end

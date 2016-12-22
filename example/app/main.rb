require 'opal'
require 'electron/browser_window'

app = Electron.app

app.on('window-all-closed') {  app.quit }
app.on('ready') do
  main_window = Electron::BrowserWindow.new('main_window', {width: 800, height: 600}, debug: true)
  main_window.on('closed') { main_window = nil }
end

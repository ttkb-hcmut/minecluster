import gi

gi.require_version("Gtk", "4.0")
gi.require_version("Adw", "1")
from gi.repository import Gtk, Adw

from components import model

def window(app, flow : model.Updater):
  win = Adw.ApplicationWindow(application=app)
  win.set_title("Minecluster")
  win.set_default_size(400, 200)
  pack = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=0)
  headerbar = Adw.HeaderBar()
  pack.append(headerbar)
  content = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=0)
  pack.append(content)
  btn = Gtk.Button(label='test')
  content.append(btn)
  win.set_content(pack)
  win.present()

def App(flow):
  app = Adw.Application(application_id='org.hcmut.ttkb.minecluster')
  app.connect('activate', lambda app: window(app, flow))
  app.run(None)

# TODO(kinten): for debugging purpose only; remove this in final version
if __name__ == '__main__':
  App(None)

import gi

gi.require_version("Gtk", "4.0")
gi.require_version("Adw", "1")
from gi.repository import Gtk, Adw

from components import model

def split_view():
  spl = Adw.OverlaySplitView()
  spl.set_sidebar_position(Gtk.PackType.END)
  return spl

def window(app, flow : model.Updater):
  win = Adw.ApplicationWindow(application=app)
  win.set_title("Minecluster")
  win.set_default_size(550, 280)

  spl = Adw.OverlaySplitView()
  spl.set_sidebar_position(Gtk.PackType.END)

  chat = Gtk.Box()
  spl.set_sidebar(chat)

  main = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=0)
  spl.set_content(main)
  headerbar = Adw.HeaderBar()
  headerbar.add_css_class("transparent")
  main.append(headerbar)
  title = Adw.WindowTitle(title="Waiting")
  headerbar.set_title_widget(title)
  spl_button = Adw.SplitButton()
  headerbar.pack_start(spl_button)
  menu = Gtk.Popover()
  spl_button.set_popover(menu)
  pack = Gtk.Box()
  pack.set_size_request(150, 150)
  menu.set_child(pack)

  win.set_content(spl)
  win.present()
  return win

def App(flow):
  app = Adw.Application(application_id='org.hcmut.ttkb.minecluster')
  css = Gtk.CssProvider()
  css.load_from_string("""
headerbar.transparent {
  background-color: rgba(0,0,0,0);
  box-shadow: 0 0 rgba(0,0,0,0);
}
""")

  def on_activate(app):
    win = window(app, flow)
    Gtk.StyleContext.add_provider_for_display(win.get_display(), css, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION)
    # Gtk.StyleContext.add_provider(win.get_style_context(), css, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION)
    pass

  def parsing_error(_):
    raise SyntaxError('css')

  css.connect('parsing-error', parsing_error)
  app.connect('activate', on_activate)
  app.run(None)

# TODO(kinten): for debugging purpose only; remove this in final version
if __name__ == '__main__':
  App(None)

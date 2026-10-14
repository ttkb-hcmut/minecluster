import gi, functools

gi.require_version("Gtk", "4.0")
gi.require_version("Adw", "1")
from gi.repository import Gtk, Adw

from components import model
from components.otherHelper import start

@functools.cache
def views_switching(with_ctrl : model.Updater):
  menu = Gtk.Popover()
  menu.add_css_class('viewswitching')
  pack = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
  pack.set_size_request(150, -1)

  def item(id, *, name=None):
    assert name is not None
    btn = Gtk.Button()
    def activate(_): with_ctrl.set("currentTab", id)
    btn.connect('clicked', activate)
    pack = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, halign=Gtk.Align.CENTER)
    pack.append(Gtk.Label(label=name))
    btn.set_child(pack)
    btn.add_css_class("i77")
    return btn

  start(pack) \
    .append(item("home", name="Home")) \
    .append(item("group", name="Group")) \
    .append(item("config", name="Config")) \
    .finish()

  menu.set_child(pack)
  return menu

def home(with_ctrl : model.Updater):
  spl = Adw.OverlaySplitView(sidebar_position=Gtk.PackType.END)
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
  spl_button.set_popover(views_switching(with_ctrl))

  return spl

def window(app, with_ctrl : model.Updater, k):
  win = Adw.ApplicationWindow(application=app, title="Minecluster")
  win.set_default_size(550, 280)

  @functools.cache
  def make_(tab):
    if tab == "home":
      return home(with_ctrl)
    elif tab == "group":
      return Gtk.Box()

  with_ctrl.subscribe("currentTab", lambda tab: win.set_content(make_(tab)))
  win.set_content(make_("home"))
  k(win)
  win.present()
  pass

STYLE_ = """
headerbar.transparent {
  background-color: rgba(0,0,0,0);
  box-shadow: 0 0 rgba(0,0,0,0);
}

.i77:not(:hover) {
  background-color: rgba(0,0,0,0);
}

.i77:hover {
  background-color: rgba(1,1,1,0.08);
}

.i77:active {
  background-color: rgba(1,1,1,0.15);
}

popover.viewswitching > contents {
  background-color: #fafafa;
}
"""

def App(flow):
  app = Adw.Application(application_id='org.hcmut.ttkb.minecluster')
  css = Gtk.CssProvider()
  css.load_from_string(STYLE_)

  def finalize_(win):
    Gtk.StyleContext.add_provider_for_display(
      win.get_display(), css,
      Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
    )

  def parsing_error(_):
    raise SyntaxError('css')

  css.connect('parsing-error', parsing_error)
  app.connect('activate', lambda app: window(app, flow, finalize_))
  app.run(None)

if __name__ == '__main__':
  import warnings
  warnings.warn("for debugging purpose only; remove this in final version")
  controller = model.Updater()
  App(controller)

import gi, functools
from components.otherHelper import start

start(gi) \
  .require_version("Gtk", "4.0") \
  .require_version("GObject", "2.0") \
  .require_version("Gio", "2.0") \
  .require_version("Adw", "1") \
  .finish()
from gi.repository import (
    Gtk as tk,
    GObject,
    Gio,
    Adw as ttk)

from components import model
from components.otherHelper import start

@functools.cache
def views_switching(with_ctrl : model.Updater):
  menu = tk.Popover()
  menu.add_css_class('viewswitching')
  pack = tk.Box(orientation=tk.Orientation.VERTICAL, spacing=2)
  pack.set_size_request(150, -1)

  def item(id, *, name=None, icon_name=None):
    assert name is not None and icon_name is not None
    btn = tk.Button()
    def activate(_): with_ctrl.set("currentTab", id)
    btn.connect('clicked', activate)
    pack = tk.Box(orientation=tk.Orientation.HORIZONTAL, halign=tk.Align.CENTER, spacing=8)
    pack.append(tk.Image(icon_name=icon_name))
    pack.append(tk.Label(label=name))
    btn.set_child(pack)
    btn.add_css_class("i77")
    return btn

  items = {
      'home': item("home", name="Home", icon_name="user-home-symbolic"),
      'group': item("group", name="Group", icon_name="network-workgroup-symbolic"),
      'config': item("config", name="Config", icon_name="preferences-system-symbolic")
  }

  def on_change(tab):
    for k, x in items.items():
      if k == tab:
        x.add_css_class('selected')
      else:
        x.remove_css_class('selected')

  def init(currentTab):
    on_change(currentTab)
    return menu

  for _, x in items.items(): pack.append(x)
  with_ctrl.subscribe('currentTab', on_change)
  menu.set_child(pack)
  return init

def home(with_ctrl : model.Updater, currentTab):
  spl = ttk.OverlaySplitView(sidebar_position=tk.PackType.END, name="a")
  bbox = ttk.OverlaySplitView(sidebar_position=tk.PackType.END, name="b")
  spl.set_sidebar(bbox)
  chatbox = tk.Box(orientation=tk.Orientation.VERTICAL)
  bbox.set_sidebar(chatbox)
  chatbox.set_size_request(10, -1)
  chatlist = tk.Box(vexpand=True)
  chatbox.append(chatlist)
  bottombar = tk.Box()
  chatbox.append(bottombar)
  bottombar.set_size_request(-1, 33)
  bottombar.add_css_class('bottombar1')
  mbox = tk.Box(orientation=tk.Orientation.VERTICAL)
  bbox.set_content(mbox)
  mbox.set_size_request(250, -1)
  store = Gio.ListStore.new(GObject.Object) # TODO(kinten): a gio.model interface for msgFeed

  def on_new_ls(ls):
    def ahm(x):
      o = GObject.Object()
      o.text = x
      return o
    store.splice(0, store.get_n_items(), [ahm(x.txt) for x in ls])
  with_ctrl.subscribe('msgFeed', on_new_ls)
  factory = tk.SignalListItemFactory()

  def on_setup(_, li):
    widget = tk.Box()
    label = tk.Label()
    widget.append(label)
    widget.label = label
    li.set_child(widget)

  def on_bind(_, li):
    widget = li.get_child()
    label = widget.label
    label.set_text(li.get_item().text)

  factory.connect('setup', on_setup)
  factory.connect('bind', on_bind)

  connlist = tk.ListView(model=tk.SingleSelection(model=store), factory=factory, vexpand=True)
  mbox.append(connlist)
  connlist.add_css_class('transparent')
  bottombar = tk.Box(orientation=tk.Orientation.VERTICAL)
  mbox.append(bottombar)
  entry = tk.Entry()

  def activate(entry):
    with_ctrl.pushMsgQueue(entry.get_text())

  entry.connect('activate', activate)
  bottombar.set_size_request(-1, 66)
  bottombar.add_css_class('bottombar')
  bottombar.append(entry)
  main = tk.Box(orientation=tk.Orientation.VERTICAL, spacing=0)
  spl.set_content(main)
  headerbar = ttk.HeaderBar()
  headerbar.add_css_class("transparent")
  main.append(headerbar)
  maininner = tk.Box(orientation=tk.Orientation.VERTICAL, spacing=0)
  main.append(maininner)
  maininner.set_margin_start(6)
  maininner.set_margin_end(6)
  loginform = tk.Box(orientation=tk.Orientation.HORIZONTAL, spacing=6)
  maininner.append(loginform)
  loginformaside = tk.Box(orientation=tk.Orientation.VERTICAL, spacing=0)
  loginform.append(loginformaside)
  loginformaside.add_css_class('vertical')
  loginformaside.add_css_class('linked')
  edit = tk.Button(icon_name='document-edit-symbolic')
  loginformaside.append(edit)
  edit.connect('clicked', lambda _: update_edit(True))
  cancel = tk.Button(icon_name='process-stop-symbolic')
  loginformaside.append(cancel)
  cancel.connect('clicked', lambda _: update_edit(False))
  save = tk.Button(icon_name='object-select-symbolic')
  loginformaside.append(save)
  loginformmain = tk.Box(orientation=tk.Orientation.VERTICAL, spacing=0, hexpand=True)
  loginform.append(loginformmain)
  loginformmain.add_css_class('vertical')
  loginformmain.add_css_class('linked')
  entry1 = tk.Entry(placeholder_text="Address")
  loginformmain.append(entry1)
  entry2 = tk.Entry(placeholder_text="Cookie")
  loginformmain.append(entry2)

  def update_edit(v):
    if v:
      edit.set_visible(False)
      cancel.set_visible(True)
      save.set_visible(True)
      entry1.set_sensitive(True)
      entry2.set_sensitive(True)
      entry2.set_icon_from_icon_name(tk.EntryIconPosition.SECONDARY, 'view-reveal-symbolic')
    else:
      edit.set_visible(True)
      cancel.set_visible(False)
      save.set_visible(False)
      entry1.set_sensitive(False)
      entry2.set_sensitive(False)
      entry2.set_icon_from_icon_name(tk.EntryIconPosition.SECONDARY, '')

  update_edit(False)
  connectform = tk.Box(orientation=tk.Orientation.VERTICAL, spacing=0)
  maininner.append(connectform)
  connectform.set_margin_top(12)
  heading3 = tk.Label(use_markup=True, label="<b>Connect</b>", halign=tk.Align.START, margin_bottom=2)
  connectform.append(heading3)
  connectforminner = tk.Box(orientation=tk.Orientation.HORIZONTAL)
  connectform.append(connectforminner)
  connectforminner.add_css_class('horizontal')
  connectforminner.add_css_class('linked')
  entry = tk.Entry(placeholder_text="Address", hexpand=True)
  connectforminner.append(entry)
  btn = tk.Button(icon_name="go-next-symbolic")
  connectforminner.append(btn)
  btn.set_visible(False)
  title = ttk.WindowTitle(title="Node self")
  headerbar.set_title_widget(title)
  spl_button = ttk.SplitButton()
  headerbar.pack_start(spl_button)
  spl_button.set_popover(views_switching(with_ctrl)(currentTab))

  return spl

def window(app, with_ctrl : model.Updater, k):
  win = ttk.ApplicationWindow(application=app, title="Minecluster")
  win.set_default_size(700, 280)

  @functools.cache
  def make_(tab):
    if tab == "home":
      return home(with_ctrl, tab)
    elif tab == "group":
      return tk.Box()

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

.view.transparent {
  background-color: rgba(0,0,0,0);
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

.i77.selected {
  border: solid 1px #FF00FF;
}

popover.viewswitching > contents {
  background-color: #fafafa;
}

.bottombar {
    border-top: solid 1px #DCDDDD;
    background-color: #FAFAFA;
}

.bottombar1 {
    border-top: solid 1px #DCDDDD;
    border-left: solid 1px #DCDDDD;
    background-color: #FAFAFA;
}

#a > .sidebar-pane {
    border-left: solid 1px #DCDDDD;
    border-right: none;
}

#b > .content-pane {
    box-shadow: none;
}

"""

def App(flow):
  app = ttk.Application(application_id='org.hcmutttkb.minecluster')
  css = tk.CssProvider()
  css.load_from_string(STYLE_)

  def finalize_(win):
    tk.StyleContext.add_provider_for_display(
      win.get_display(), css,
      tk.STYLE_PROVIDER_PRIORITY_APPLICATION
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

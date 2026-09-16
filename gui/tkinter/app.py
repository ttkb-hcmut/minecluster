import tkinter as tk
from tkinter import ttk
from components import model
from components import mainHome


class App(tk.Tk):
  def __init__(self,controller):
    super().__init__()
    self.title("Minecluster")
    self.geometry("500x500") 
    self.minsize(500,250) 
    self.columnconfigure(index=(0),weight=1)
    self.rowconfigure(index=(1),weight=1)
    
    self.backgroundColor = ttk.Label(self,background= "#ffffff").grid(row=0, column=0, rowspan=2, sticky="nsew")
    self.tabsBar = TabsBar(self,controller)
    self.main = Main(self,controller)
    self.mainloop()


class Main(ttk.Frame):
  def __init__(self,parent,controller):
    super().__init__(parent)
    self.grid(row=1, column=0, sticky="nsew")
    self.columnconfigure(index=(0),weight=1)
    self.rowconfigure(index=(1),weight=1)
    # self.backgroundColor = ttk.Label(self,background= "#ff0000").pack(expand= True, fill = "both")

    self.mainHome = mainHome.MainHome(self,controller)
    mainGroup = MainTab(self,controller,"group")
    mainConfig = MainTab(self,controller,"config")
    
class MainTab(ttk.Frame):
  def __init__(self,parent,controller,title):
    super().__init__(parent)
    self.grid(row=1, column=0)
    print(f"current tab is: {controller.get("currentTab")}")
    if controller.get("currentTab") != title:
      self.grid_remove()
    else:
      self.grid()

    self.title = title
    self.label = ttk.Label(self,text=f"Menu of {title}")
    self.label.grid(row=0, column=0, sticky="nsew")
    controller.subscribe("currentTab", self.showHideMenu)


  def showHideMenu(self,data):
    if data == self.title:
      self.grid()
    else:
      self.grid_remove()

class TabsBar(ttk.Frame):
  def __init__(self,parent,controller):
    super().__init__(parent)
    self.grid(row=0, column=0, sticky="nsew")

    self.button_style = ttk.Style()
    self.button_style.configure(
      'button_active.TButton', 
      foreground='#000000',   # Button body color
      background='#FF00FF',   # Button body color
      padding = 5,
    )
    self.button_style.configure(
      'button_inactive.TButton', 
      foreground ='#888888',   # Button body color
      background ='#dddddd',   # Button body color
      padding = 0
    )


    self.home_button    = ttk.Button(self,text="Home", style='button_active.TButton', padding=5,
                            command = lambda: controller.set("currentTab","home"))
    self.group_button   = ttk.Button(self,text="Group", style='button_inactive.TButton',
                            command = lambda: controller.set("currentTab","group"))
    self.config_button  = ttk.Button(self,text="Config", style='button_inactive.TButton',
                            command = lambda: controller.set("currentTab","config"))
    self.home_button.pack(side='left')
    self.group_button.pack(side='left')
    self.config_button.pack(side='left')

    # controller.subscribe("currentTab", lambda: self.configure_buttons())
    controller.subscribe("currentTab", self.configure_buttons)

  def configure_buttons(self,data):
    self.home_button.configure(style='button_inactive.TButton',padding=0)
    self.group_button.configure(style='button_inactive.TButton',padding=0)
    self.config_button.configure(style='button_inactive.TButton',padding=0)
    match data:
      case "home":
        self.home_button.configure(style='button_active.TButton',padding=5)
      case "group":
        self.group_button.configure(style='button_active.TButton',padding=5)
      case "config":
        self.config_button.configure(style='button_active.TButton',padding=5)

def add1tonum(num):
  num.set(num.get() + 1)

# def window(root,ma):
#   num = ttk.IntVar(value=0)
#   label = ttk.Label(root, textvariable=num, font=("Arial", 16))
#   button = ttk.Button(root, text = "balls", command = lambda: ma.action("changeTab",[thedata]))
#   label.pack(pady=20)
#   button.pack(pady=20)

if __name__ == "__main__":
  controller = model.Updater()
  app = App(controller)

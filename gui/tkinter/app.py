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
    self.rowconfigure(index=(0),weight=1)
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


import socket
import argparse
import threading
import json
# import tkinter as tk
# from tkinter import messagebox

class ServerGUISocket():
  def __init__(self,controller: model.Updater):
    parser = argparse.ArgumentParser(description="Process some integers.")
    parser.add_argument("--sport", type=int, help="Server Port number")
    parser.add_argument("--gport", type=int, help="Gui Port number")
    args = parser.parse_args()
    
    self.sport = args.sport
    self.gport = args.gport
    self.controller = controller
    self.controller.setPushToServer(self.send)
    self.connectToServer()
    self.serverToGui()
  #############################
  def connectToServer(self):
    try:
      self.gtsSocket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
      self.gtsSocket.connect(("localhost", int(self.sport)))
    except Exception as e:
      print(e)
      # messagebox.showerror("Error", "Could not connect to Elixir server. Is it running?")
      # self.root.quit()


  def serverToGui(self):
    try:
      self.stgSocket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
      self.stgSocket.bind(("localhost", int(self.gport)))
      threading.Thread(target=self.receiveLoop, daemon=True).start()
    
    except Exception as e:
      print(e)
  def receiveLoop(self):
    self.stgSocket.listen()
    conn, addr = self.stgSocket.accept()
    while True:
      try:
        received = conn.recv(1024).decode('utf-8').strip()
        self.controller.handleIncoming(json.loads(received))
      except Exception as e:
        # self.root.after(0, self.update_ui, f"Error: {e}")
        print(e)

  def send_data(self):
    api = self.entry.get()
    if not api:
      return
    threading.Thread(target=self.send, args=(api,), daemon=True).start()

  def send(self, text):
    try:
      # Append newline because Elixir uses `packet: :line`
      self.gtsSocket.sendall(f"{json.dumps(text)}\n".encode('utf-8'))
      
    except Exception as e:
        print(e)

  def on_close(self):
    self.stgSocket.close()
    self.gtsSocket.close()

# if __name__ == "__main__":
#   root = tk.Tk()
#   app = GuiApp(root)
#   root.mainloop()


if __name__ == "__main__":
  controller = model.Updater()
  connection = ServerGUISocket(controller)
  app = App(controller)

import tkinter as tk
from tkinter import ttk
from components import model
from components.stylingHelper import StyleEnum as Ste
from components.stylingHelper import RowTracker as Row
from .things import ScrollableList
    

class NodeSelf(ttk.Frame):
  def __init__(self,parent,controller):
    # borderwidth => padding
    # padding => margin

    # Frame's stuff
    super().__init__(parent, relief= Ste.FRAME_RELIEF.value, padding=Ste.PAD.value)
    self.grid_columnconfigure(index=(1),weight=1)

    row = Row()
    # form
    self.is_editting = False
    self.label_nodeself     = ttk.Label(self,text = "Node self",font=(Ste.FONT.value,Ste.FONT_SIZE.value,"bold", 'underline'))
    self.save_nodeself      = ttk.Button(self,text="Save",command=lambda:self.submit(controller))
    self.editcancel_nodeself= ttk.Button(self,text="Edit",command=lambda:self.toggleEdit(controller))
    self.label_nodeself.grid(row=row.curr(),column=0,sticky="nsew",padx=Ste.PAD.value)
    self.save_nodeself.grid(row=row.curr(),column=1,sticky="e",padx=Ste.PAD.value)
    self.save_nodeself.grid_remove()
    self.editcancel_nodeself.grid(row=row.curr(),column=2,sticky="ew",padx=Ste.PAD.value)

    row.next()
    ## Address
    self.label_address      = ttk.Label(self,text = "Address:")
    self.entry_address      = ttk.Entry(self)
    self.entry_address.insert(0, controller.get("selfAddress"))
    self.entry_address.state(['disabled'])
    self.label_address.grid(row=row.curr(),column=0,sticky="e",padx=Ste.PAD.value)
    self.entry_address.grid(row=row.curr(),column=1,sticky="ew",padx=Ste.PAD.value)

    row.next()
    ## Cookie
    self.label_cookie       = ttk.Label(self,text = "Cookie:")
    self.showhide_cookie    = ttk.Button(self,text="Toggle visible", 
                              command= lambda: self.toggleVisibility(self.entry_cookie))
    self.entry_cookie       = ttk.Entry(self,show="*")
    self.entry_cookie.insert(0, controller.get("selfCookie"))
    self.entry_cookie.state(['disabled'])
    self.label_cookie.grid(row=row.curr(),column=0,sticky="e",padx=Ste.PAD.value)
    self.entry_cookie.grid(row=row.curr(),column=1,sticky="ew",padx=Ste.PAD.value)
    self.showhide_cookie.grid(row=row.curr(),column=2,sticky="ew",padx=Ste.PAD.value)
    
    self.entry_address.bind("<Return>",lambda e: self.entry_cookie.focus_set())
    self.entry_cookie.bind("<Return>",lambda e: self.submit(controller))

    row.next()
    ## disconnect/stop
    self.disconnect_nodeself = ttk.Button(self,text="Disconnect",command=lambda:self.disconnect(controller))
    self.stop_nodeself       = ttk.Button(self,text="Stop",command=lambda:self.stop(controller))
    self.disconnect_nodeself.grid(row=row.curr(),column=1,sticky="e",padx=Ste.PAD.value)
    self.stop_nodeself.grid(row=row.curr(),column=2,sticky="ew",padx=Ste.PAD.value)
    self.disconnect_nodeself.grid_remove()
    self.stop_nodeself.grid_remove()

    controller.subscribe("selfAddress",lambda data: self.setDefault(self.entry_address,data))
    controller.subscribe("selfCookie",lambda data: self.setDefault(self.entry_cookie,data))
    self.fetchSelf(controller)

  def setDefault(self,element,data):
    element.state(['!disabled'])
    element.delete(0,"end")
    element.insert(0, data)
    if not self.is_editting:
      element.state(['disabled'])

  def toggleEdit(self,controller):
    if self.is_editting:
      self.is_editting = False
      self.save_nodeself.grid_remove()
      self.editcancel_nodeself.configure(text = "Edit")

      self.entry_address.delete(0,"end")
      self.entry_cookie.delete(0,"end")
      self.entry_address.insert(0, controller.get("selfAddress"))
      self.entry_cookie.insert(0, controller.get("selfCookie"))

      self.entry_address.state(['disabled'])
      self.entry_cookie.state(['disabled'])

      self.disconnect_nodeself.grid_remove()
      self.stop_nodeself.grid_remove()
    else:
      self.is_editting = True
      self.save_nodeself.grid()
      self.editcancel_nodeself.configure(text = "Cancel")

      self.entry_address.state(['!disabled'])
      self.entry_cookie.state(['!disabled'])

      self.disconnect_nodeself.grid()
      self.stop_nodeself.grid() 

  def toggleVisibility(self,element):
    if element["show"] == "":
      element.configure(show="*")
    else:
      element.configure(show="")

  def fetchSelf(self,controller:model.Updater):
    controller.sendFetch("api","self")

  def disconnect(self,controller:model.Updater):
    controller.sendFetch("command",["disconnect"])
    self.toggleEdit(controller)
    self.fetchSelf(controller)
  def stop(self,controller:model.Updater):
    controller.sendFetch("command",["stop"])
    self.toggleEdit(controller)
    self.fetchSelf(controller)

  def submit(self,controller:model.Updater):
    if self.is_editting:
      address = self.entry_address.get()
      cookie = self.entry_cookie.get()
      command = ["start"]
      command += ["-a", address] if address != "" else []
      command += ["-c", cookie ] if cookie  != "" else []

      controller.sendFetch("command",command)
    self.fetchSelf(controller)
    self.toggleEdit(controller)

class ConnectNode(ttk.Frame):
  def __init__(self,parent,controller):
    # borderwidth => padding
    # padding => margin

    # Frame's stuff
    super().__init__(parent, relief= Ste.FRAME_RELIEF.value, padding=Ste.PAD.value)
    self.grid_columnconfigure(index=(1),weight=1)

    row = Row()
    # form
    self.label_nodeself     = ttk.Label(self,text = "Connect Node",font=(Ste.FONT.value,Ste.FONT_SIZE.value,"bold", 'underline'))
    self.label_nodeself.grid(row=row.curr(),column=0,sticky="nsew",padx=Ste.PAD.value)

    row.next()
    ## Address
    self.label_address      = ttk.Label(self,text = "Address:")
    self.entry_address      = ttk.Entry(self)
    self.entry_address.bind("<Return>",lambda e: self.submit(controller))
    self.connect            = ttk.Button(self,text= "Connect",command=lambda:self.submit(controller))
    self.label_address.grid(row=row.curr(),column=0,sticky="e",padx=Ste.PAD.value)
    self.entry_address.grid(row=row.curr(),column=1,sticky="ew",padx=Ste.PAD.value) 
    self.connect.grid(row=row.curr(),column=2,sticky="ew",padx=Ste.PAD.value) 

  def submit(self,controller: model.Updater):
    controller.sendFetch("command",["connect",self.entry_address.get(),controller.get("selfCookie")])
    self.entry_address.delete(0,"end")
    
class ConnectedList(ttk.Frame):
  def __init__(self,parent,controller):
    # borderwidth => padding
    # padding => margin

    # Frame's stuff
    super().__init__(parent, relief= Ste.FRAME_RELIEF.value, padding=Ste.PAD.value)
    self.grid_columnconfigure(index=(0),weight=1)
    self.grid_rowconfigure(index=(1),weight=1)

    # title
    self.label = ttk.Label(self,text = "Nodes connected:",font=(Ste.FONT.value,Ste.FONT_SIZE.value,"bold", 'underline'))
    self.label.grid(row=0,column=0,sticky="ew",padx=Ste.PAD.value)
    self.refresh = ttk.Button(self,text = "Refresh",command=lambda:self.fetchList(controller))
    self.refresh.grid(row=0,column=1,sticky="ew",padx=Ste.PAD.value)


    # scrollable list ??? 
    self.list = ScrollableList(self,controller,controller.get("nodeList"))
    self.list.grid(row=1,column=0,columnspan=2,sticky="nsew",padx=Ste.PAD.value)

    controller.subscribe("nodeList",lambda data: self.refreshList(data,controller))
  def refreshList(self,data,controller):
    self.list.set(data)
    
  def fetchList(self,controller):
    controller.sendFetch("api","list")
    
class ChatWindow(ttk.Frame):
  def __init__(self,parent,controller):
    # borderwidth => padding
    # padding => margin

    # Frame's stuff
    super().__init__(parent, relief= Ste.FRAME_RELIEF.value, padding=Ste.PAD.value)
    self.grid_columnconfigure(index=(0),weight=1)
    self.grid_rowconfigure(index=(1),weight=1)

    # title
    self.label = ttk.Label(self,text = "Chat:",font=(Ste.FONT.value,Ste.FONT_SIZE.value,"bold", 'underline'))
    self.label.grid(row=0,column=0,columnspan=2,sticky="ew",padx=Ste.PAD.value)


    # scrollable list ??? 
    self.list = ScrollableList(self,controller,controller.get("msgFeed"),stickToBottom=True)
    self.list.grid(row=1,column=0,columnspan=2,sticky="nsew",padx=Ste.PAD.value)


    self.entry = ttk.Entry(self)
    self.entry.grid(row=2,column=0,sticky="nsew",padx=Ste.PAD.value)
    self.entry.bind("<Return>",lambda e: self.submit(controller))
    self.enter = ttk.Button(self,text="Send",command=lambda: self.submit(controller))
    self.enter.grid(row=2,column=1,sticky="ns",padx=Ste.PAD.value)

    controller.subscribe("msgFeed",lambda data: self.refreshList(data,controller))
  def refreshList(self,data,controller):
    self.list.set(data)
    # is_at_bottom = self.list.getBottom()
    # self.list.destroy()
    # self.list = ScrollableList(self,controller,data,toBottom = is_at_bottom)
    # self.list.grid(row=1,column=0,columnspan=2,sticky="nsew",padx=Ste.PAD.value)
  def submit(self,controller):
    self.entry.focus_set()
    msg = self.entry.get().strip()
    if msg != "":
      controller.pushMsgQueue(msg)
    self.entry.delete(0,"end")


class MainHome(ttk.Frame):
  def __init__(self,parent,controller):
    super().__init__(parent)
    self.id = "home"
    self.grid(row=0, column=0, sticky="nsew")
    self.grid_columnconfigure(index=(0),weight=2)
    self.grid_columnconfigure(index=(1),weight=1)
    self.grid_rowconfigure(index=(2),weight=1)
    if controller.get("currentTab") != self.id:
      self.grid_remove()
    else:
      self.grid()

    self.initcontent(controller)
    controller.subscribe("currentTab", self.showHideMenu)

  def initcontent(self,controller):
    self.nodeself = NodeSelf(self,controller)
    self.nodeself.grid(row=0, column=0, columnspan=2, sticky="nsew",padx=Ste.PAD.value,pady=Ste.PAD.value)
    self.connectNode = ConnectNode(self,controller)
    self.connectNode.grid(row=1, column=0, columnspan=2, sticky="nsew",padx=Ste.PAD.value,pady=Ste.PAD.value)
    self.chat = ChatWindow(self,controller)
    self.chat.grid(row=2, column=0, sticky="nsew",padx=Ste.PAD.value,pady=Ste.PAD.value)
    self.connected = ConnectedList(self,controller)
    self.connected.grid(row=2, column=1, sticky="nsew",padx=Ste.PAD.value,pady=Ste.PAD.value)

  def showHideMenu(self,data):
    if data == self.id:
      self.grid()
    else:
      self.grid_remove()

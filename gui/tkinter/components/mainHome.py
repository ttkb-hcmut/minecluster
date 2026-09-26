import tkinter as tk
from tkinter import ttk
from components import model
from components.stylingHelper import StyleEnum as Ste
from components.stylingHelper import RowTracker as Row


# class Connection(ttk.Frame):
#   def __init__(self,parent,controller):
#     super().__init__(parent)
#     self.grid(row=0, column=0, sticky="nsew")
#     self.grid_columnconfigure(index=(2),weight=1)

#     # connect node
#     self.is_editting = False
#     self.label_nodeself     = ttk.Label(self,text = "Node self:")
#     self.save_nodeself      = ttk.Button(self,text="Save",command=lambda:self.submit(controller),padding=(5,0))
#     self.editcancel_nodeself= ttk.Button(self,text="Edit",command=lambda:self.toggleEdit(controller),padding=(5,0))
#     self.label_nodeself.grid(row=0,column=0,sticky="w")
#     self.save_nodeself.grid(row=0,column=1,sticky="e")
#     self.save_nodeself.grid_remove()
#     self.editcancel_nodeself.grid(row=0,column=2,sticky="w")

#     ## Address
#     self.label_address      = ttk.Label(self,text = "Address:",padding=(5,0))
#     self.entry_address      = ttk.Entry(self)
#     self.entry_address.insert(0, controller.get("selfAddress"))
#     self.entry_address.state(['disabled'])
#     self.label_address.grid(row=1,column=0,sticky="e")
#     self.entry_address.grid(row=1,column=1,sticky="ew")
    
#     ## Cookie
#     self.label_cookie       = ttk.Label(self,text = "Cookie:",padding=(5,0))
#     self.showhide_cookie    = ttk.Button(self,text="Toggle visible", command= lambda: self.toggleVisibility(self.entry_cookie),padding=(5,0))
#     self.entry_cookie       = ttk.Entry(self,show="*")
#     self.entry_cookie.insert(0, controller.get("selfCookie"))
#     self.entry_cookie.state(['disabled'])
#     self.label_cookie.grid(row=2,column=0,sticky="e")
#     self.entry_cookie.grid(row=2,column=1,sticky="ew")
#     self.showhide_cookie.grid(row=2,column=2,sticky="w")

#     # connect group
#     self.is_editting = False
#     self.label_nodeself     = ttk.Label(self,text = "Node self:",padding=(5,0))
#     self.save_nodeself      = ttk.Button(self,text="Save",command=lambda:self.submit(controller),padding=(5,0))
#     self.editcancel_nodeself= ttk.Button(self,text="Edit",command=lambda:self.toggleEdit(controller),padding=(5,0))
#     self.label_nodeself.grid(row=0,column=0,sticky="w")
#     self.save_nodeself.grid(row=0,column=1,sticky="e")
#     self.save_nodeself.grid_remove()
#     self.editcancel_nodeself.grid(row=0,column=2,sticky="w")

#     ## Address
#     self.label_address      = ttk.Label(self,text = "Address:",padding=(5,0))
#     self.entry_address      = ttk.Entry(self)
#     self.entry_address.insert(0, controller.get("selfAddress"))
#     self.entry_address.state(['disabled'])
#     self.label_address.grid(row=1,column=0,sticky="e")
#     self.entry_address.grid(row=1,column=1,sticky="w")
    
#     ## Cookie
#     self.label_cookie       = ttk.Label(self,text = "Cookie:",padding=(5,0))
#     self.showhide_cookie    = ttk.Button(self,text="Toggle visible", command= lambda: self.toggleVisibility(self.entry_cookie),padding=(5,0))
#     self.entry_cookie       = ttk.Entry(self,show="*")
#     self.entry_cookie.insert(0, controller.get("selfCookie"))
#     self.entry_cookie.state(['disabled'])
#     self.label_cookie.grid(row=2,column=0,sticky="e")
#     self.entry_cookie.grid(row=2,column=1,sticky="w")
#     self.showhide_cookie.grid(row=2,column=2,sticky="w")

#   def toggleEdit(self,controller):
#     if self.is_editting:
#       self.is_editting = False
#       self.save_nodeself.grid_remove()
#       self.editcancel_nodeself.configure(text = "Edit")
#       self.entry_address.delete(0,"end")
#       self.entry_cookie.delete(0,"end")
#       self.entry_address.insert(0, controller.get("selfAddress"))
#       self.entry_cookie.insert(0, controller.get("selfCookie"))
#       self.entry_address.state(['disabled'])
#       self.entry_cookie.state(['disabled'])
#     else:
#       self.is_editting = True
#       self.save_nodeself.grid()
#       self.editcancel_nodeself.configure(text = "Cancel")
#       self.entry_address.state(['!disabled'])
#       self.entry_cookie.state(['!disabled'])

#   def toggleVisibility(self,element):
#     if element["show"] == "":
#       element.configure(show="*")
#     else:
#       element.configure(show="")

#   def submit(self,controller):
#     if self.is_editting:
#       # node start -a address -c cookie
#       print(f">start -a {self.entry_address.get()} -c {self.entry_cookie.get()}")
#       self.toggleEdit(controller)
    

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
    self.disconnect_nodeself = ttk.Button(self,text="Disconnect",command=lambda:self.submit(controller))
    self.stop_nodeself       = ttk.Button(self,text="Stop",command=lambda:self.submit(controller))
    self.disconnect_nodeself.grid(row=row.curr(),column=1,sticky="e",padx=Ste.PAD.value)
    self.stop_nodeself.grid(row=row.curr(),column=2,sticky="ew",padx=Ste.PAD.value)
    self.disconnect_nodeself.grid_remove()
    self.stop_nodeself.grid_remove()

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

  def submit(self,controller):
    if self.is_editting:
      # node start -a address -c cookie
      print(f">start -a {self.entry_address.get()} -c {self.entry_cookie.get()}")
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

  def submit(self,controller):
    if self.is_editting:
      # node start -a address -c cookie
      print(f">connect -a {self.entry_address.get()} -c {self.entry_cookie.get()}")
    
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
    self.refresh = ttk.Button(self,text = "Refresh",command=lambda:self.refreshList(controller.get("nodeList"),controller))
    self.refresh.grid(row=0,column=1,sticky="ew",padx=Ste.PAD.value)


    # scrollable list ??? 
    self.list = ScrollableList(self,controller,controller.get("nodeList"))
    self.list.grid(row=1,column=0,columnspan=2,sticky="nsew",padx=Ste.PAD.value)

    controller.subscribe("nodeList",lambda data: self.refreshList(data,controller))
  def refreshList(self,data,controller):
    self.list.destroy()
    self.list = ScrollableList(self,controller,data)
    self.list.grid(row=1,column=0,columnspan=2,sticky="nsew",padx=Ste.PAD.value)
    
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
    self.list = ScrollableList(self,controller,controller.get("msgFeed"))
    self.list.grid(row=1,column=0,columnspan=2,sticky="nsew",padx=Ste.PAD.value)


    self.entry = ttk.Entry(self)
    self.entry.grid(row=2,column=0,sticky="nsew",padx=Ste.PAD.value)
    self.entry.bind("<Return>",lambda e: self.submit(controller))
    self.enter = ttk.Button(self,text="Send",command=lambda: self.submit(controller))
    self.enter.grid(row=2,column=1,sticky="ns",padx=Ste.PAD.value)

    controller.subscribe("msgFeed",lambda data: self.refreshList(data,controller))
  def refreshList(self,data,controller):
    is_at_bottom = self.list.canvas.yview()[1] == 1.0
    self.list.destroy()
    self.list = ScrollableList(self,controller,data,toBottom = is_at_bottom)
    self.list.grid(row=1,column=0,columnspan=2,sticky="nsew",padx=Ste.PAD.value)
  def submit(self,controller):
    self.entry.focus_set()
    msg = self.entry.get().strip()
    if msg != "":
      controller.pushMsgQueue(f"You> {msg}")
    self.entry.delete(0,"end")

class ScrollableList(ttk.Frame):
  def __init__(self,parent,controller,list,toBottom = False):
    super().__init__(parent)
    self.grid_columnconfigure(index=(0),weight=1)
    self.grid_rowconfigure(index=(0),weight=1)


    self.canvas = tk.Canvas(self,width=0,height=0)
    self.canvas.grid(row=0,column=0,sticky="nsew")
    self.canvas.grid_rowconfigure(index=0,weight=1)
    self.canvas.grid_columnconfigure(index=0,weight=1)
    self.scrollbar = tk.Scrollbar(self, orient="vertical", command=self.canvas.yview)
    self.scrollbar.grid(row=0,column=1,sticky="nsew")
    self.canvas.configure(yscrollcommand=self.scrollbar.set)
    self.frame = ttk.Frame(self.canvas,relief= Ste.FRAME_RELIEF.value, padding=Ste.PAD.value)
    self.frame.grid(row = 0,column = 0,sticky="nsew")
    self.frame.grid_columnconfigure(index=0,weight=1)
    self.canvas.create_window((0, 0), window=self.frame, anchor= "nw")
    self.frame.bind("<Configure>",lambda e: self.canvas.configure(scrollregion=self.canvas.bbox("all")) or (self.canvas.yview_moveto(1.0) if toBottom else False))

    li = self.listItems(list)

    self.canvas.bind("<Configure>", lambda event: [i.configure(wraplength=event.width - self.scrollbar.winfo_width()) for i in li])
    
  def listItems(self,data):
    row = Row(0)
    iterable = []
    for i in data:
      a = ttk.Label(self.frame, text=f"{i}",justify="left")
      a.grid(row=row.curr(),column=0,padx=Ste.PAD.value,sticky="ew")
      iterable.append(a)
      row.next()
    return iterable
    

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

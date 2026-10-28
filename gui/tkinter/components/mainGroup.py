import tkinter as tk
from tkinter import ttk
from components import model
from components.stylingHelper import StyleEnum as Ste
from components.stylingHelper import RowTracker as Row
from .things import ScrollableList, ScrollableList2, Tablerone

class GroupList(ttk.Frame):
  def __init__(self,parent,controller):
    super().__init__(parent, relief= Ste.FRAME_RELIEF.value, padding=Ste.PAD.value)
    self.currentlySelectedGroup = parent.currentlySelectedGroup

    self.label    = ttk.Label(self, text="Group List:" + self.currentlySelectedGroup.get(),font=(Ste.FONT.value,Ste.FONT_SIZE.value,"bold", 'underline'))
    self.newGroup = ttk.Button(self, text="Add +")
    self.refresh  = ttk.Button(self, text="Refresh", command = lambda: controller.sendFetch("api","group/list"))
    self.grid_columnconfigure(index=(0,),weight=1)
    self.grid_rowconfigure(index=(1,),weight=1)
    self.label.grid(row= 0, column = 0,sticky="nsew")    
    self.newGroup.grid(row= 0, column = 1,sticky="nsew") 
    self.refresh.grid(row= 0, column = 2,sticky="nsew")  
    self.gl = ScrollableList2(self)
    self.gl.grid(row=1,column=0,columnspan=3,sticky="nsew")
    self.table = Tablerone(self.gl.frameframe,col=2)

    controller.subscribe("groupList", lambda data: self.refreshGroups(data[0]))
  def refreshGroups(self,data):
    self.table.destroy()
    self.table = Tablerone(self.gl.frameframe)
    for k,v in data.items():
      self.table.newRow(
        self.table.label(text=v,id=k)
      )
      self.table.get(id=k).bind("<Button-1>", lambda _ : self.selectGroup(k))
    self.table.grid(row=0,column=0,sticky="nsew")

  def selectGroup(self,id):
    if self.currentlySelectedGroup.get() == id:
      self.currentlySelectedGroup.set(None)
    else: self.currentlySelectedGroup.set(id)

class GroupControls(ttk.Frame):
  def __init__(self,parent,controller):
    super().__init__(parent, relief= Ste.FRAME_RELIEF.value, padding=Ste.PAD.value)

class MainGroup(ttk.Frame):
  def __init__(self,parent,controller):
    super().__init__(parent, relief= Ste.FRAME_RELIEF.value, padding=Ste.PAD.value)
    self.id = "group"
    self.grid(row=0, column=0, sticky="nsew")
    self.grid_columnconfigure(index=(0),weight=2)
    self.grid_columnconfigure(index=(1),weight=1)
    self.grid_rowconfigure(index=(0),weight=1)
    if controller.get("currentTab") != self.id:
      self.grid_remove()
    else:
      self.grid()

    self.initcontent(controller)
    controller.subscribe("currentTab", lambda data: self.showHideMenu(data,controller))

  def initcontent(self,controller):
    self.currentlySelectedGroup = tk.StringVar(self,value = None)
    self.groupList = GroupList(self,controller)
    self.groupList.grid(row=0, column=0, sticky="nsew",padx=Ste.PAD.value,pady=Ste.PAD.value)
    self.groupControls = GroupControls(self,controller)
    self.groupControls.grid(row=0, column=1, sticky="nsew",padx=Ste.PAD.value,pady=Ste.PAD.value)

  def showHideMenu(self,data,controller):
    if data == self.id:
      self.grid()
      controller.sendFetch("api","group/list")
    else:
      self.grid_remove()

import tkinter as tk
from tkinter import ttk
from components import model
from components.stylingHelper import StyleEnum as Ste
from components.stylingHelper import RowTracker as Row
from .things import ScrollableList, ScrollableList2

class GroupList(ttk.Frame):
  def __init__(self,parent,controller):
    super().__init__(parent, relief= Ste.FRAME_RELIEF.value, padding=Ste.PAD.value)
    self.label    = ttk.Label(self, text="Group List",font=(Ste.FONT.value,Ste.FONT_SIZE.value,"bold", 'underline'))
    self.newGroup = ttk.Button(self, text="Add +")
    self.refresh  = ttk.Button(self, text="Refresh")
    self.grid_columnconfigure(index=(0,),weight=1)
    self.grid_rowconfigure(index=(1,),weight=1)
    self.label.grid(row= 0, column = 0,sticky="nsew")    
    self.newGroup.grid(row= 0, column = 1,sticky="nsew") 
    self.refresh.grid(row= 0, column = 2,sticky="nsew")  
    self.gl = ScrollableList2(self)
    self.gl.grid(row=1,column=0,columnspan=3,sticky="nsew")
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
    controller.subscribe("currentTab", self.showHideMenu)

  def initcontent(self,controller):
    self.groupList = GroupList(self,controller)
    self.groupList.grid(row=0, column=0, sticky="nsew",padx=Ste.PAD.value,pady=Ste.PAD.value)
    self.groupControls = GroupControls(self,controller)
    self.groupControls.grid(row=0, column=1, sticky="nsew",padx=Ste.PAD.value,pady=Ste.PAD.value)

  def showHideMenu(self,data):
    if data == self.id:
      self.grid()
    else:
      self.grid_remove()

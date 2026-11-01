import tkinter as tk
from tkinter import ttk
from components import model
from components.stylingHelper import StyleEnum as Ste
from components.stylingHelper import RowTracker as Row
from .things import ScrollableList, ScrollableList2, Tablerone

class MainConfig(ttk.Frame):
  def __init__(self,parent,controller):
    super().__init__(parent, relief= Ste.FRAME_RELIEF.value, padding=Ste.PAD.value)
    self.id = "config"
    self.configDict = {} 
    self.grid(row=0, column=0, sticky="nsew")
    if controller.get("currentTab") != self.id:
      self.grid_remove()
    else:
      self.grid()

    self.initcontent(controller)
    controller.subscribe("currentTab", lambda data: self.showHideMenu(data,controller))

  def initcontent(self,controller):
    self.grid_columnconfigure(index=(0),weight=1)
    self.grid_rowconfigure(index=(1),weight=1)
    self.label  = ttk.Label( self, text="Configs",font=(Ste.FONT.value,Ste.FONT_SIZE.value,"bold", 'underline'))
    self.save   = ttk.Button(self, text="Save",command = lambda: self.submit(controller))
    self.cancel = ttk.Button(self, text="Cancel",command= lambda: controller.sendFetch("api","config/all"))
    self.label.grid(row = 0, column = 0, sticky="nsew")
    self.save.grid(row = 0, column = 1, sticky="nsew")
    self.cancel.grid(row = 0, column = 2, sticky="nsew")
    self.cl = ScrollableList2(self)
    self.cl.grid(row=1, column=0, columnspan=3, sticky="nsew",padx=Ste.PAD.value,pady=Ste.PAD.value)
    self.table = Tablerone(self.cl.frameframe)
    controller.subscribe("configAll",lambda data:self.refreshConfigs(data[0]))
    controller.sendFetch("api","config/all")
  
  def submit(self,controller):
    dic = controller.get("configAll")[0]
    for k,v in dic.items():
      newVal = self.table.get(id=k).get()
      oldVal = v if isinstance(v,str) else ",".join(v)
      if newVal != oldVal:
        controller.sendFetch("command",["config",k] + newVal.split(","))

  def refreshConfigs(self,data):
    self.table.destroy()
    self.table = Tablerone(self.cl.frameframe)
    for k,v in data.items():
      self.table.newRow(self.table.label(text=k))
      self.table.newRow(self.table.entry(id=k,default=v if isinstance(v,str) else ",".join(v)))
    # self.label.config(text = self.configDict)
    self.table.grid(row=0,column=0,sticky="nsew")

  def showHideMenu(self,data,controller):
    if data == self.id:
      controller.sendFetch("api","config/all")
      self.grid()
    else:
      self.grid_remove()

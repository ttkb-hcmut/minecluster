import tkinter as tk
from tkinter import ttk
from components import model
from components.stylingHelper import StyleEnum as Ste
from components.stylingHelper import RowTracker as Row
from .things import ScrollableList, ScrollableList2, Tablerone

class GroupList(ttk.Frame):
  def __init__(self,parent,controller):
    super().__init__(parent, relief= Ste.FRAME_RELIEF.value, padding=Ste.PAD.value)
    self.currentlySelectedGroup : tk.StringVar = parent.currentlySelectedGroup
    style = ttk.Style()
    style.configure("Selected.TLabel", background="#FF69FF")

    self.label    = ttk.Label(self, text="Group List:",font=(Ste.FONT.value,Ste.FONT_SIZE.value,"bold", 'underline'))
    self.newGroup = ttk.Button(self, text="Add +")
    self.refresh  = ttk.Button(self, text="Refresh", command = lambda: controller.sendFetch("api","group/list"))
    self.grid_columnconfigure(index=(0,),weight=1)
    self.grid_rowconfigure(index=(1,),weight=1)
    self.label.grid(row= 0, column = 0,sticky="nsew")    
    self.newGroup.grid(row= 0, column = 1,sticky="nsew") 
    self.refresh.grid(row= 0, column = 2,sticky="nsew")  
    self.gl = ScrollableList2(self)
    self.gl.grid(row=1,column=0,columnspan=3,sticky="nsew")
    self.gl.frameframe.grid_columnconfigure(index=(0,),weight=1)
    self.table = Tablerone(self.gl.frameframe,col=2)

    controller.subscribe("groupList", lambda data: self.refreshGroups(data[0],controller))
  def refreshGroups(self,data,controller):
    self.table.destroy()
    self.table = Tablerone(self.gl.frameframe)
    self.table.grid_columnconfigure(index=(0,),weight=1)
    for k,v in data.items():
      self.table.newRow(
        self.table.label(text=v,id=k)
      )
      # I hate lazy eval                                vvvvv needed to capture k at this point in the loop
      self.table.get(id=k).bind("<Button-1>", lambda _, x = k : self.selectGroup(x,controller))
    self.table.grid(row=0,column=0,sticky="nsew")

  def selectGroup(self,id,controller):
    curr = self.currentlySelectedGroup.get()
    if curr is not None and curr != '':
      self.table.get(id=curr).config(style="TLabel")
    
    if curr == id:
      self.currentlySelectedGroup.set('')
    else: 
      self.currentlySelectedGroup.set(id)
      self.table.get(id=id).config(style="Selected.TLabel")

class GroupInfo(ttk.Frame):
  def __init__(self,parent,controller):
    super().__init__(parent, relief= Ste.FRAME_RELIEF.value, padding=Ste.PAD.value)
    self.currentlySelectedGroup : tk.StringVar = parent.currentlySelectedGroup
    self.currentlySelectedGroup.trace_add('write',lambda var_name,var_index,mode: self.onSelectGroup(var_name,var_index,mode,controller))
    self.grid_columnconfigure(index=(0,1,),weight=1)
    self.lt = Tablerone(self,col=2)
    self.lt.grid(column=0,row=0,sticky="nsew")
    self.lt.grid_columnconfigure(index=(0,),weight=1)
    self.rt = Tablerone(self,col=1)
    self.rt.grid(column=1,row=0,sticky="nsew")
    self.rt.grid_columnconfigure(index=(0,),weight=1)

    # Name, Cookie, central info
    self.lt.newRow(
      self.lt.label(text="Name",id="name"),
      self.lt.none()
    )
    self.lt.newRow(
      self.lt.label(text="Cookie:"),
      self.lt.button(text="Copy",id="copyCookie")
    )
    self.lt.newRow(
      self.lt.label(text="...",id="cookie", wraplength = 100*Ste.PAD.value)
    )
    self.lt.newRow(
      self.lt.label(text="Central:"),
      self.lt.button(text="Copy",id="copyCentral")
    )
    self.lt.newRow(
      self.lt.label(text="...",id = "centralSource"),
      self.lt.label(text="...",id = "centralAddress")
    )
    #
    self.name           : ttk.Label = self.lt.get(id="name")
    self.cookie         : ttk.Label = self.lt.get(id="cookie")
    self.centralSource  : ttk.Label = self.lt.get(id="centralSource")
    self.centralAddress : ttk.Label = self.lt.get(id="centralAddress")
    # Member List
    self.rt.newRow(self.rt.label(text = "Members of group:"))
    self.rt.newRow(self.rt.cell(thingClass = ScrollableList2,id="memberList"))
    self.rt.grid_rowconfigure(index=(1,),weight=1)
    # 
    self.memberList     : ScrollableList2 = self.rt.get(id="memberList")

    controller.subscribe("groupInfo",lambda data: self.updateWithInfo(data[0]))
  def updateWithInfo(self,data):
    self.name.config(           text = data.get("name","None"))           
    cookie = data.get("cookie","None")
    self.cookie.config(         text = cookie if len(cookie)<10 else cookie[:7] + "...")         
    self.lt.get(id="copyCookie").config(command= lambda data = cookie: self.copyToClipboard(data))
    central = data.get("central",{"None":"None"})
    for k,v in central.items():
      self.centralSource.config(  text = k)  
      self.centralAddress.config( text = v) 
      self.lt.get(id="copyCentral").config(command= lambda data = v: self.copyToClipboard(data))
    self.memberList.set(data.get("connections",[])) 

  def onSelectGroup(self,var_name,var_index,mode,controller):
    if mode != "write": 
      controller.sendFetch("command",["msg",var_name,var_index,mode])
      return
    if self.currentlySelectedGroup.get() is None or self.currentlySelectedGroup.get() == '':
      self.grid_remove()
    else:
      controller.sendFetch("command",["msg",self.currentlySelectedGroup.get()])
      controller.sendFetch("api",["group/info",self.currentlySelectedGroup.get()])
      self.grid()

  def copyToClipboard(self,text_to_copy):
    self.clipboard_clear()
    self.clipboard_append(text_to_copy)
    self.update()
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
    self.groupInfo = GroupInfo(self,controller)
    self.groupInfo.grid(row=1, column=0, sticky="nsew",padx=Ste.PAD.value,pady=Ste.PAD.value)
    self.groupInfo.grid_remove()
    self.groupControls = GroupControls(self,controller)
    self.groupControls.grid(row=0, column=1,rowspan=2, sticky="nsew",padx=Ste.PAD.value,pady=Ste.PAD.value)

  def showHideMenu(self,data,controller):
    if data == self.id:
      self.grid()
      controller.sendFetch("api","group/list")
    else:
      self.grid_remove()

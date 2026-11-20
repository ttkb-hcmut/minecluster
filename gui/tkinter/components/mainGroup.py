import tkinter as tk
from tkinter import ttk
from components import model
from components.stylingHelper import StyleEnum as Ste
from components.stylingHelper import RowTracker as Row
from .things import ScrollableList, ScrollableList2, Tablerone, BoxScaler

class GroupList(ttk.Frame):
  def __init__(self,parent,controller):
    super().__init__(parent, relief= Ste.FRAME_RELIEF.value, padding=Ste.PAD.value)
    self.currentlySelectedGroup : tk.StringVar = parent.currentlySelectedGroup
    style = ttk.Style()
    style.configure("Selected.TLabel", background="#FF69FF")

    self.label    = ttk.Label(self, text="Group List:",font=(Ste.FONT.value,Ste.FONT_SIZE.value,"bold", 'underline'))
    self.refresh  = ttk.Button(self, text="Refresh", command = lambda: controller.sendFetch("api","group/list"))
    self.grid_columnconfigure(index=(0,),weight=1)
    self.grid_rowconfigure(index=(1,),weight=1)
    self.label.grid(row= 0, column = 0,sticky="nsew")    
    self.refresh.grid(row= 0, column = 1,sticky="nsew")  
    self.gl = ScrollableList2(self)
    self.gl.grid(row=1,column=0,columnspan=3,sticky="nsew")
    self.gl.frameframe.grid_columnconfigure(index=(0,),weight=1)
    self.table = Tablerone(self.gl.frameframe,col=2)

    controller.subscribe("groupList", lambda data: self.refreshGroups(data,controller))
  def refreshGroups(self,data,controller):
    self.table.destroy()
    self.currentlySelectedGroup.set("")
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

    controller.subscribe("groupInfo",lambda data: self.updateWithInfo(data))
  def updateWithInfo(self,data):
    self.name.config(           text = data.get("name","None"))           
    cookie = data.get("cookie","None")
    self.cookie.config(         text = cookie if len(cookie)<10 else cookie[:7] + "...")         
    self.lt.get(id="copyCookie").config(command= lambda data = cookie: copyToClipboard(self,data))
    central = data.get("central",{"None":"None"})
    self.centralSource.config(  text = "...")  
    self.centralAddress.config( text = "...") 
    for k,v in central.items():
      self.centralSource.config(  text = k)  
      self.centralAddress.config( text = v) 
      self.lt.get(id="copyCentral").config(command= lambda data = v: copyToClipboard(self,data))
    self.memberList.set(data.get("connections",[])) 

  def onSelectGroup(self,var_name,var_index,mode,controller):
    if mode != "write": 
      return
    if self.currentlySelectedGroup.get() is None or self.currentlySelectedGroup.get() == '':
      self.grid_remove()
    else:
      controller.sendFetch("api",["group/info",self.currentlySelectedGroup.get()])
      self.grid()

def copyToClipboard(self,text_to_copy):
  self.clipboard_clear()
  self.clipboard_append(text_to_copy)
  self.update()

class GroupControls(ttk.Frame):
  def __init__(self,parent,controller):
    super().__init__(parent, relief= Ste.FRAME_RELIEF.value, padding=Ste.PAD.value)
    self.currentlySelectedGroup : tk.StringVar = parent.currentlySelectedGroup
    self.currentlySelectedGroup.trace_add(mode="write",callback = lambda a,b,m: self.changeState() if m == "write" else None)
    self.grid_columnconfigure(index=(0,),weight=1)
    row = Row()
    self.groupAction = Tablerone(self,col=1)
    self.groupAction.grid(row=0,column=0,sticky = "ew")
    self.groupAction.grid_remove()
    self.groupAction.grid_columnconfigure(index=(0,),weight=1)
    self.groupAction.newRow(self.groupAction.label(text="Group Action:"))
    self.groupAction.newRow(self.groupAction.cell(ttk.Button,text="connect",command=lambda : self.connectGroup(controller)))
    self.groupAction.newRow(self.groupAction.cell(ttk.Button,text="delete",command= lambda: controller.sendFetch("command",["group","delete",controller.get("groupInfo")["name"]]) or controller.sendFetch("api","group/list")))
    
      
    self.groupOther = None 
    self.newGroup = Tablerone(self,col=1)
    self.newGroup.grid(row=0,column=0,sticky = "ew")
    self.newGroup.grid_remove()
    self.newGroup.grid_columnconfigure(index=(0,),weight=1)
    self.newGroup.newRow(
      self.newGroup.label(text="Add group:")
    )
    self.newGroupName = tk.StringVar(self,value="new_group")
    self.newGroup.newRow(
      self.newGroup.entry(textvariable=self.newGroupName)
    )
    self.newGroup.newRow(
      self.newGroup.button(text="Add +",command=lambda: self.makeGroup(controller))
    )

    self.currGroup = Tablerone(self,col = 1)
    self.currGroup.grid(row=0,column=0,sticky = "ew")
    self.currGroup.grid_remove()
    self.currGroup.grid_columnconfigure(index=(0,),weight=1)
    self.currGroup.newRow(
      self.currGroup.label(text="In Group:")
    )
    self.currGroup.newRow(
      self.currGroup.label(text="...",id = "currentJoinedGroup"),
    )
    self.currentCookie = tk.StringVar(self)
    self.currGroup.newRow(
      self.currGroup.button(text="Copy Cookie", command = lambda: copyToClipboard(self,self.currentCookie.get())),
    )
    self.currGroup.newRow(
      self.currGroup.button(text="Become Central", command = lambda: controller.sendFetch("command",["group","role","central"])),
    )
    self.currGroup.newRow(self.currGroup.cell(Tablerone,id = "installServer"))
    self.installServer = self.currGroup.get(id="installServer")
    self.installServer.newRow(self.installServer.label(text="Group has no server"))
    self.installServer.newRow(
      self.installServer.comboBox(
        id="versionPlatform",
        values=["Java","Bedrock"],
        state="readonly",
        command= lambda event: (
          controller.sendFetch("command",["msg"]+controller.get("versionsJava")),
          self.installServer.get(id="versionNumber").config(values = controller.get("versions"+event.widget.get())), 
          self.installServer.get(id="versionNumber").set('')
          ),
      ))
    self.installServer.newRow(
      self.installServer.comboBox(
        id="versionNumber",
        state="readonly",
      ))
    self.installServer.newRow(
      self.installServer.button(
        text="Install",
        command= lambda: (
          controller.sendFetch("command",[
            "group","server",
            self.installServer.get(id="versionPlatform").get().lower(),
            self.installServer.get(id="versionNumber").get()
          ]),
          controller.sendFetch("api","group/status")
          )
        )
      )
    
    # self.currGroup.newRow(
    #   self.currGroup.button(text="Leave",command = lambda: controller.sendFetch("api",["group/status"])),
    # )


    # all this manual state changes pissing me off, fuck it truth table
    self.s_inagroup = tk.BooleanVar(self,False)
    self.s_servered = tk.BooleanVar(self,False)
    
    controller.subscribe("groupStatusName",   lambda data: self.refreshCurrentConnectedGroup(data,"name")  )
    controller.subscribe("groupStatusCookie", lambda data: self.refreshCurrentConnectedGroup(data,"cookie"))
    controller.subscribe("groupStatusServer", lambda data: self.s_servered.set(data is not None))
    self.refreshCurrentConnectedGroup(controller.get("groupStatusName"),"name")  
    self.refreshCurrentConnectedGroup(controller.get("groupStatusCookie"),"cookie")
  def makeGroup(self,controller):
    name = "".join([c if c != " " else "_" for c in self.newGroupName.get() if c not in ["/","\\","<",">",":","|","?"]])
    if len(name) == 0:
      name = "new_group"
    postfix = 0
    while f"{name}{f"_{postfix}" if postfix > 0 else ""}" in controller.get("groupList").values():
      postfix += 1
    name = f"{name}{f"_{postfix}" if postfix > 0 else ""}"
    controller.sendFetch("command",["group","make",name])
    controller.sendFetch("api","group/list")
    controller.sendFetch("api","group/status")


    
  def changeState(self):
    self.groupOther = self.currGroup if self.s_inagroup.get() else self.newGroup
      
    if self.currentlySelectedGroup.get() in [None,""]:
      self.groupOther.grid()
      self.groupAction.grid_remove()
    else:
      self.groupOther.grid_remove()
      self.groupAction.grid()
    
    if self.s_inagroup.get() and not self.s_servered.get():
      self.installServer.grid()
    else:
      self.installServer.grid_remove()


  def refreshCurrentConnectedGroup(self,data,thing):
    if thing == "cookie":
      self.currentCookie.set(data)
      return
    
    if self.groupOther is not None:
      self.groupOther.grid_remove()

    if data is None or data == '':
      self.s_inagroup.set(False)
    else:
      self.currGroup.get(id="currentJoinedGroup").config(text = data)
      self.s_inagroup.set(True)
    self.changeState()

  def connectGroup(self,controller):
    if self.currentlySelectedGroup.get() == '' or self.currentlySelectedGroup.get() is None:
      return
    controller.sendFetch("command",["connect","group",controller.get("groupInfo")["name"]])
    controller.sendFetch("api","group/status")

class MainGroup(ttk.Frame):
  def __init__(self,parent,controller):
    super().__init__(parent, relief= Ste.FRAME_RELIEF.value, padding=Ste.PAD.value)
    self.id = "group"
    self.grid(row=0, column=0, sticky="nsew")
    self.grid_columnconfigure(index=(0),weight=2000)
    self.grid_columnconfigure(index=(2),weight=1000)
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
    self.groupControls.grid(row=0, column=2,rowspan=2, sticky="nsew",padx=Ste.PAD.value,pady=Ste.PAD.value)
    BoxScaler(self,self.groupList,self.groupControls,"horizontal").grid(row= 0, column = 1, rowspan= 2, sticky="nsew")


  def showHideMenu(self,data,controller):
    if data == self.id:
      self.grid()
      controller.sendFetch("api","group/list")
      controller.sendFetch("api","group/status")
    else:
      self.grid_remove()

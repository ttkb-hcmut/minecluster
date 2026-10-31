import tkinter as tk
from tkinter import ttk
from components import model
import sys
from components.stylingHelper import StyleEnum as Ste
from components.stylingHelper import RowTracker as Row

class ScrollableList(ttk.Frame):
  # def setBottom(self):
  #   self.isBottom = self.canvas.yview()[1] == 1.0
  # def getBottom(self):
  #   return self.canvas.yview()[1] == 1.0
  def append(self,data):
    a = ttk.Label(self.frameframe, text=f"{data}",justify="left")
    a.grid(row=len(self.li),column=0,padx=Ste.PAD.value,sticky="ew")
    self.li.append(a)

  def set(self, list):
    self.old_frameframe = self.frameframe
    self.frameframe = ttk.Frame(self.frame)
    self.old_frameframe.lift(self.frameframe)
    self.frameframe.grid(row=0,column=0,sticky="nsew")
    self.li = self.listItems(list)
    self.frameframe.update_idletasks()
    if self.old_frameframe: 
      self.old_frameframe.destroy()

  def listItems(self,data):
    row = Row(0)
    iterable = []
    for i in data:
      if i is str:
        a = ttk.Label(self.frameframe, text=f"{i}",justify="left",wraplength=self.canvas.winfo_width() - self.scrollbar.winfo_width())
      else:
        a = i
      a.grid(row=row.curr(),column=0,padx=Ste.PAD.value,sticky="ew")
      iterable.append(a)
      row.next()
    return iterable
  
  def setBottom(self):
    self.tryBottom = self.canvas.yview()[1] == 1.0
    
  def __init__(self,parent,controller,list=[],stickToBottom = False):
    super().__init__(parent)
    self.grid_columnconfigure(index=(0),weight=1)
    self.grid_rowconfigure(index=(0),weight=1)
    self.tryBottom = stickToBottom
    self.old_frameframe = None
    # scrollable canvas stuff ###############################
    self.canvas = tk.Canvas(self,width=0,height=0)
    self.canvas.grid(row=0,column=0,sticky="nsew")
    self.canvas.grid_rowconfigure(index=0,weight=1)
    self.canvas.grid_columnconfigure(index=0,weight=1)
    self.scrollbar = tk.Scrollbar(self, orient="vertical", command=lambda *args : self.canvas.yview(*args) or self.setBottom())
    self.scrollbar.grid(row=0,column=1,sticky="nsew")
    self.canvas.configure(yscrollcommand=self.scrollbar.set)
    self.frame = ttk.Frame(self.canvas,relief= Ste.FRAME_RELIEF.value, padding=Ste.PAD.value)
    self.frame.grid(row = 0,column = 0,sticky="nsew")
    self.frame.grid_columnconfigure(index=0,weight=1)
    self.canvas.create_window((0, 0), window=self.frame, anchor= "nw")
    self.frame.bind("<Configure>",lambda e: self.canvas.configure(scrollregion=self.canvas.bbox("all")) or (self.canvas.yview_moveto(1.0) if self.tryBottom and stickToBottom else False))
    # end scrollable canvas stuff ###############################


    self.frameframe = ttk.Frame(self.frame)
    self.frameframe.grid(row=0,column=0,sticky="nsew")
    self.li = self.listItems(list)
    self.toBottom = False

    self.canvas.bind("<Configure>", lambda event: [i.configure(wraplength=event.width - self.scrollbar.winfo_width()) for i in self.li])
    
    

import tkinter as tk
from tkinter import ttk


class Tablerone(ttk.Frame):
  def __init__(self, parent=None, col=1):
    super().__init__(parent)
    # column major
    self.dict = {}
    self.table = [[] for i in range(col)]

  def newRow(self, *args):
    nextRow = len(self.table[0])
    for i in range(len(args)):
      self.table[i].append(args[i])
      if args[i] is not None:
        args[i].grid(row=nextRow, column=i, sticky="nsew", padx=2, pady=2)
    return nextRow

  def none(self):
    return None
  def cell(self,/,thingClass = None,id=None,doAfterCreated = None,**kwargs):
    if thingClass is None:
      return self.none()
    else:
      thing = thingClass(self,**kwargs)
      if id is not None:
        self.dict[id] = thing
      if doAfterCreated is not None:
        for func in doAfterCreated:
          func(thing)
      return thing
  def label(self, /, id=None, **kwargs):
    lab = ttk.Label(self, **kwargs, background="")
    if id is not None:
      self.dict[id] = lab
    return lab

  def comboBox(self, /, id=None, default=None, command=None, **kwargs):
    combo = ttk.Combobox(self, **kwargs)
    if id is not None:
      self.dict[id] = combo
    if default is not None:
      combo.current(default)
    if command is not None:
      combo.bind("<<ComboboxSelected>>", command)
    return combo

  def spinBox(self, /, id=None, default=None, **kwargs):
    spinbox = ttk.Spinbox(self, **kwargs)
    if id is not None:
      self.dict[id] = spinbox
    if default is not None:
      spinbox.set(default)
    return spinbox

  def checkButton(self, /, id=None, default=None, **kwargs):
    var = kwargs.pop("variable", None) or tk.BooleanVar(master=self)
    button = ttk.Checkbutton(self, variable=var, **kwargs)
    button.var = var  # keep a reference so it isn't garbage collected
    if id is not None:
      self.dict[id] = button
    if default is not None:
      var.set(default)
    return button

  # def checkButton(self, /, id=None, default=None, **kwargs):
  #   button = ttk.Checkbutton(self, **kwargs)
  #   if id is not None:
  #     self.dict[id] = button
  #   if default is not None:
  #     button.variable().set(default)
  #   return button

  def slider(self, /, id=None, **kwargs):
    slider = ttk.Scale(self, **kwargs)
    if id is not None:
      self.dict[id] = slider
    return slider

  def button(self, /, id=None, **kwargs):
    button = ttk.Button(self, **kwargs)
    if id is not None:
      self.dict[id] = button
    return button

  def entry(self, /, default="", id=None, **kwargs):
    ent = ttk.Entry(self, **kwargs, background="")
    if default != "":
      ent.delete(0,"end")
      ent.insert(0, default)
    if id is not None:
      self.dict[id] = ent
    return ent

  def get(self, id: str = None, row: int = None, col: int = None):
    if row is None or col is None:
      return self.dict[id]
    else:
      return self.table[col][row]


import tkinter as tk
from tkinter import ttk
from .stylingHelper import StyleEnum as Ste
from .stylingHelper import RowTracker as Row

class ScrollableList2(ttk.Frame):
  # def setBottom(self):
  #   self.isBottom = self.canvas.yview()[1] == 1.0
  # def getBottom(self):
  #   return self.canvas.yview()[1] == 1.0
  def append(self,data):
    a = ttk.Label(self.frameframe, text=f"{data}",justify="left")
    a.grid(row=len(self.li),column=0,padx=Ste.PAD.value,pady=Ste.PAD.value,sticky="ew")
    self.li.append(a)

  def set(self, list):
    self.old_frameframe = self.frameframe
    self.frameframe = ttk.Frame(self.frame)
    self.old_frameframe.lift(self.frameframe)
    self.frameframe.grid(row=0,column=0,sticky="nsew")
    self.li = self.listItems(list)
    self.frameframe.update_idletasks()
    if self.old_frameframe: 
      self.old_frameframe.destroy()

  def listItems(self,data):
    row = Row(0)
    iterable = []
    for i in data:
      if isinstance(i,str):
        a = ttk.Label(self.frameframe, text=f"{i}",justify="left",wraplength=self.canvas.winfo_width() - self.scrollbar.winfo_width())
      else:
        a = i[0](self.frameframe)
        for j in i[1:]:
          j(a)
      a.grid(row=row.curr(),column=0,padx=Ste.PAD.value,sticky="ew")
      iterable.append(a)
      row.next()
    return iterable
  
  def setBottom(self):
    self.tryBottom = self.canvas.yview()[1] == 1.0
    
  def __init__(self,parent=None,list=[], func = lambda: None,stickToBottom = False, **kw):
    super().__init__(parent,**kw,relief= Ste.FRAME_RELIEF.value, padding=Ste.PAD.value)
    self.grid_columnconfigure(index=(0),weight=1)
    self.grid_rowconfigure(index=(0),weight=1)
    self.tryBottom = stickToBottom
    self.old_frameframe = None
    # scrollable canvas stuff ###############################
    self.canvas = tk.Canvas(self,width=0,height=0)
    self.canvas.grid(row=0,column=0,sticky="nsew")
    # self.canvas.grid_rowconfigure(index=0,weight=1)
    # self.canvas.grid_columnconfigure(index=0,weight=1)
    self.scrollbar = tk.Scrollbar(self, orient="vertical", command=lambda *args : self.canvas.yview(*args) or self.setBottom())
    self.scrollbar.grid(row=0,column=1,sticky="nsew")
    self.canvas.configure(yscrollcommand=self.scrollbar.set)

    self.frame = ttk.Frame(self.canvas)
    
    
    self.frame.grid(row = 0,column = 0)
    self.frame.grid_columnconfigure(index=(0,),weight=1)
    self.window = self.canvas.create_window((0, 0), window=self.frame, anchor= "nw")
    excess = 20*Ste.PAD.value
    self.bind("<Configure>", func = lambda event: self.canvas.itemconfig(self.window,width = event.width - excess))
    self.frame.bind("<Configure>",lambda e: self.canvas.configure(scrollregion=self.canvas.bbox("all")) or (self.canvas.yview_moveto(1.0) if self.tryBottom and stickToBottom else False))
    
    # end scrollable canvas stuff ###############################

    self.frameframe = ttk.Frame(self.frame)
    self.frameframe.grid(row=0,column=0,sticky="nsew")
    self.li = self.listItems(list)
    self.toBottom = False

    match sys.platform:
      case "win32" | "darwin":
        self.frameframe.bind("<MouseWheel>", lambda e: self.canvas.yview_scroll(int(- e.delta/20),what="unit"))
      case "linux":
        self.bind("<Button-4>", lambda e: self.canvas.yview_scroll(int(- 5),what="unit"))
        self.bind("<Button-5>", lambda e: self.canvas.yview_scroll(int(5),what="unit"))
    self.canvas.bind("<Configure>", lambda event: [i.configure(wraplength=event.width - self.scrollbar.winfo_width()) for i in self.li])
    
    
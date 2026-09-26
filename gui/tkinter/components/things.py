import tkinter as tk
from tkinter import ttk
from components import model
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
      a = ttk.Label(self.frameframe, text=f"{i}",justify="left",wraplength=self.canvas.winfo_width() - self.scrollbar.winfo_width())
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
    
    
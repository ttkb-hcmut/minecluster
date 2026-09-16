import tkinter as tk
from tkinter import ttk
from components import model


class NodeSelf(ttk.Frame):
  def __init__(self,parent,controller):
    super().__init__(parent)
    self.id = "home"
    self.grid(row=0, column=0, sticky="nsew")
    self.grid_columnconfigure(index=(2),weight=1)

    # form
    self.is_editting = False
    self.label_nodeself     = ttk.Label(self,text = "Node self:",padding=(5,0))
    self.save_nodeself      = ttk.Button(self,text="Save",command=lambda:self.submit(controller),padding=(5,0))
    self.editcancel_nodeself= ttk.Button(self,text="Edit",command=lambda:self.toggleEdit(controller),padding=(5,0))
    self.label_nodeself.grid(row=0,column=0,sticky="w")
    self.save_nodeself.grid(row=0,column=1,sticky="e")
    self.save_nodeself.grid_remove()
    self.editcancel_nodeself.grid(row=0,column=2,sticky="w")

    ## Address
    self.label_address      = ttk.Label(self,text = "Address:",padding=(5,0))
    self.entry_address      = ttk.Entry(self)
    self.entry_address.insert(0, controller.get("selfAddress"))
    self.entry_address.state(['disabled'])
    self.label_address.grid(row=1,column=0,sticky="e")
    self.entry_address.grid(row=1,column=1,sticky="w")
    
    ## Cookie
    self.label_cookie       = ttk.Label(self,text = "Cookie:",padding=(5,0))
    self.showhide_cookie    = ttk.Button(self,text="Toggle visible", command= lambda: self.toggleVisibility(self.entry_cookie),padding=(5,0))
    self.entry_cookie       = ttk.Entry(self,show="*")
    self.entry_cookie.insert(0, controller.get("selfCookie"))
    self.entry_cookie.state(['disabled'])
    self.label_cookie.grid(row=2,column=0,sticky="e")
    self.entry_cookie.grid(row=2,column=1,sticky="w")
    self.showhide_cookie.grid(row=2,column=2,sticky="w")

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
    else:
      self.is_editting = True
      self.save_nodeself.grid()
      self.editcancel_nodeself.configure(text = "Cancel")
      self.entry_address.state(['!disabled'])
      self.entry_cookie.state(['!disabled'])

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
    


class MainHome(ttk.Frame):
  def __init__(self,parent,controller):
    super().__init__(parent)
    self.id = "home"
    self.grid(row=0, column=0, sticky="nsew")
    self.grid_columnconfigure(index=(0),weight=1)
    self.grid_columnconfigure(index=(0),weight=1)
    if controller.get("currentTab") != self.id:
      self.grid_remove()
    else:
      self.grid()

    self.initcontent(controller)
    controller.subscribe("currentTab", self.showHideMenu)

  def initcontent(self,controller):
    self.nodeself = NodeSelf(self,controller)

  def showHideMenu(self,data):
    if data == self.id:
      self.grid()
    else:
      self.grid_remove()

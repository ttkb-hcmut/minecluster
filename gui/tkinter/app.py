import tkinter as tk
from .components import model
def add1tonum(num):
  num.set(num.get() + 1)

def window(root,ma):
  num = tk.IntVar(value=0)
  label = tk.Label(root, textvariable=num, font=("Arial", 16))
  button = tk.Button(root, text = "balls", command = lambda: ma.action("changeTab",[thedata]))
  label.pack(pady=20)
  button.pack(pady=20)

if __name__ == "__main__":
  controller = model.Updater()
  root = tk.Tk()
  root.title("Mineclusterer")
  root.geometry("1000x500")
  window(root)
  root.mainloop()
  print("hello world")

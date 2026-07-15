import tkinter as tk

def add1tonum(num):
  num.set(num.get() + 1)

def window(root):
  num = tk.IntVar(value=0)
  label = tk.Label(root, textvariable=num, font=("Arial", 16))
  button = tk.Button(root, text = "balls", command = lambda: add1tonum(num))
  label.pack(pady=20)
  button.pack(pady=20)

if __name__ == "__main__":
  root = tk.Tk()
  root.title("Deltarune")
  root.geometry("400x200")
  window(root)
  root.mainloop()
  print("hello world")

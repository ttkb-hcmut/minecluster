import tkinter as tk

root = tk.Tk()

num = tk.IntVar(value=0)
def add1tonum ():
  num.set(num.get() + 1)
root.title("Deltarune")
root.geometry("400x200")
label = tk.Label(root, textvariable=num, font=("Arial", 16))
button = tk.Button(root, text = "balls", command = add1tonum)
label.pack(pady=20)
button.pack(pady=20)

root.mainloop()



print("hello world")
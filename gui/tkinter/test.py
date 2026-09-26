import socket
import argparse
import threading
import json
import tkinter as tk
from tkinter import messagebox

class GuiApp:

  def __init__(self, root):
    self.root = root
    self.root.title("Python GUI to Elixir")
    self.root.geometry("400x200")

    parser = argparse.ArgumentParser(description="Process some integers.")
    parser.add_argument("--sport", type=int, help="Server Port number")
    parser.add_argument("--gport", type=int, help="Gui Port number")
    args = parser.parse_args()
    
    self.sport = args.sport
    self.gport = args.gport
    
    self.connectToServer()
    self.serverToGui()

    # UI Elements
    self.label = tk.Label(root, text="Enter text to send to Elixir:")
    self.label.pack(pady=10)

    self.entry = tk.Entry(root, width=30)
    self.entry.pack(pady=5)

    self.btn = tk.Button(root, text="Send to Elixir", command=self.send_data)
    self.btn.pack(pady=5)

    self.result_label = tk.Label(root, text=f"Data received on port '{args.gport}': ", fg="blue")
    self.result_label.pack(pady=20)

    self.root.protocol("WM_DELETE_WINDOW", self.on_close)

  #############################
  def connectToServer(self):
    try:
      self.gtsSocket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
      self.gtsSocket.connect(("localhost", int(self.sport)))
    except ConnectionRefusedError:
      messagebox.showerror("Error", "Could not connect to Elixir server. Is it running?")
      self.root.quit()


  def serverToGui(self):
    self.stgSocket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    self.stgSocket.bind(("localhost", int(self.gport)))
    threading.Thread(target=self.receiveLoop, daemon=True).start()
    
  def receiveLoop(self):
    self.stgSocket.listen()
    conn, addr = self.stgSocket.accept()
    while True:
      try:
        received = conn.recv(1024).decode('utf-8').strip()
        self.root.after(0, self.update_ui, received)
      except Exception as e:
        self.root.after(0, self.update_ui, f"Error: {e}")

  def send_data(self):
    api = self.entry.get()
    if not api:
      return
    threading.Thread(target=self.send, args=(api,), daemon=True).start()

  def send(self, text):
    try:
      # Append newline because Elixir uses `packet: :line`
      self.gtsSocket.sendall(f"{text}\n".encode('utf-8'))
      
    except Exception as e:
      self.root.after(0, self.update_ui, f"Error: {e}")

  def update_ui(self, message):
    self.result_label.config(text=f"Response: {message}")

  def on_close(self):
    self.stgSocket.close()
    self.gtsSocket.close()
    self.root.destroy()

if __name__ == "__main__":
  root = tk.Tk()
  app = GuiApp(root)
  root.mainloop()

import socket
import argparse
import threading
import json

class ServerGUISocket():
  def __init__(self, controller: 'model.Updater'):
    parser = argparse.ArgumentParser(description="Process some integers.")
    parser.add_argument("--hkind",  type=str, help="Harbor kind")
    parser.add_argument("--sport", type=str, help="Server Port number")
    parser.add_argument("--gport", type=str, help="Gui Port number")
    args = parser.parse_args()
    
    self.hkind = args.hkind
    if self.hkind == "coco":
      self.socketkind = socket.AF_INET
      self.sport = ("localhost", int(args.sport))
      self.gport = ("localhost", int(args.gport))
    elif self.hkind == "agott":
      self.socketkind = socket.AF_UNIX
      self.sport = args.sport
      self.gport = args.gport
    self.controller = controller
    self.controller.setPushToServer(self.send)
    self.connectToServer()
    self.serverToGui()
  #############################
  def connectToServer(self):
    try:
      self.gtsSocket = socket.socket(self.socketkind, socket.SOCK_STREAM)
      self.gtsSocket.connect(self.sport)
    except Exception as e:
      print(e)
      # messagebox.showerror("Error", "Could not connect to Elixir server. Is it running?")
      # self.root.quit()


  def serverToGui(self):
    try:
      self.stgSocket = socket.socket(self.socketkind, socket.SOCK_STREAM)
      self.stgSocket.bind(self.gport)
      threading.Thread(target=self.receiveLoop, daemon=True).start()
    
    except Exception as e:
      print(e)
  def receiveLoop(self):
    self.stgSocket.listen()
    conn, addr = self.stgSocket.accept()
    while True:
      try:
        received = conn.recv(1024).decode('utf-8').strip()
        self.controller.handleIncoming(json.loads(received))
      except Exception as e:
        # self.root.after(0, self.update_ui, f"Error: {e}")
        print(e)

  def send_data(self):
    api = self.entry.get()
    if not api:
      return
    threading.Thread(target=self.send, args=(api,), daemon=True).start()

  def send(self, text):
    try:
      # Append newline because Elixir uses `packet: :line`
      self.gtsSocket.sendall(f"{json.dumps(text)}\n".encode('utf-8'))
      
    except Exception as e:
        print(e)

  def on_close(self):
    self.stgSocket.close()
    self.gtsSocket.close()

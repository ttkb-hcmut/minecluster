#!/usr/bin/env -S python -u
import os, socket, argparse, threading, json
if   os.getenv('MINECLUSTER_UI') is None or os.getenv('MINECLUSTER_UI') == 'windows':
  from ui import App
elif os.getenv('MINECLUSTER_UI') == 'gnome':
  from ui_linux_gnome import App
else:
  raise TypeError(f'unknown ui kind {os.getenv('MINECLUSTER_UI')=}')
from components import model

def receiveLoop(controller, stgSocket):
  stgSocket.listen()
  conn, addr = stgSocket.accept()
  while True:
    try:
      received = conn.recv(1024).decode('utf-8').strip()
      controller.handleIncoming(json.loads(received))
    except Exception as e:
      # self.root.after(0, self.update_ui, f"Error: {e}")
      print(e)

def send(gtsSocket, text):
  try:
    # Append newline because Elixir uses `packet: :line`
    gtsSocket.sendall(f"{json.dumps(text)}\n".encode('utf-8'))
    
  except Exception as e:
      print(e)

def ServerGUISocket(controller: 'model.Updater'):
  parser = argparse.ArgumentParser(description="Process some integers.")
  parser.add_argument("--hkind", type=str, help="Harbor kind")
  parser.add_argument("--sport", type=str, help="Server Port number")
  parser.add_argument("--gport", type=str, help="Gui Port number")
  args = parser.parse_args()

  if args.hkind == "coco":
    socketkind = socket.AF_INET
    sport = ("localhost", int(args.sport))
    gport = ("localhost", int(args.gport))
  elif args.hkind == "agott":
    socketkind = socket.AF_UNIX
    sport = args.sport
    gport = args.gport
  else:
    raise TypeError(f"unknown {args.hkind=}")

  def connectToServer(socketkind, sport):
    gtsSocket = socket.socket(socketkind, socket.SOCK_STREAM)
    gtsSocket.connect(sport)
    return gtsSocket

  def serverToGui(controller, socketkind, gport):
    stgSocket = socket.socket(socketkind, socket.SOCK_STREAM)
    stgSocket.bind(gport)
    threading.Thread(target=receiveLoop, daemon=True, args=(controller, stgSocket)).start()
    return stgSocket

  gtsSocket = connectToServer(socketkind, sport)
  controller.setPushToServer(lambda text: send(gtsSocket, text))
  stgSocket = serverToGui(controller, socketkind, gport)

if __name__ == "__main__":
  controller = model.Updater()
  ServerGUISocket(controller)
  app = App(controller)

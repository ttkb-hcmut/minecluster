import socket
import threading
import json

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

def ServerGUISocket(controller: 'model.Updater', args):
  def connectToServer(socketkind, sport):
    gtsSocket = socket.socket(socketkind, socket.SOCK_STREAM)
    gtsSocket.connect(sport)
    return gtsSocket

  def serverToGui(controller, socketkind, gport):
    stgSocket = socket.socket(socketkind, socket.SOCK_STREAM)
    stgSocket.bind(gport)
    threading.Thread(target=receiveLoop, daemon=True, args=(controller, stgSocket)).start()
    return stgSocket

  gtsSocket = connectToServer(args.socketkind, args.sport)
  controller.setPushToServer(lambda text: send(gtsSocket, text))
  stgSocket = serverToGui(controller, args.socketkind, args.gport)

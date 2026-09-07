import socket
import argparse
import threading
import tkinter as tk
from tkinter import messagebox

class GuiApp:
    def __init__(self, root):
        self.root = root
        self.root.title("Python GUI to Elixir")
        self.root.geometry("400x200")

        parser = argparse.ArgumentParser(description="Process some integers.")
        parser.add_argument("--sport", type=int, help="Elixir Port number")
        parser.add_argument("--gport", type=int, help="GUI Port number")
        args = parser.parse_args()
        # Connect to Elixir TCP Server
        try:
            self.client_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            self.client_socket.connect(("localhost", int(args.port)))
        except ConnectionRefusedError:
            messagebox.onerror("Error", "Could not connect to Elixir server. Is it running?")
            self.root.quit()

        # UI Elements
        self.label = tk.Label(root, text="Enter text to send to Elixir:")
        self.label.pack(pady=10)

        self.entry = tk.Entry(root, width=30)
        self.entry.pack(pady=5)

        self.btn = tk.Button(root, text="Send to Elixir", command=self.send_data)
        self.btn.pack(pady=5)

        self.result_label = tk.Label(root, text=f"{args.port}: ", fg="blue")
        self.result_label.pack(pady=20)

        # Handle clean exit
        self.root.protocol("WM_DELETE_WINDOW", self.on_close)

    def send_data(self):
        text_to_send = self.entry.get()
        if not text_to_send:
            return
        
        # Run network logic in a background thread to keep GUI responsive
        threading.Thread(target=self.network_worker, args=(text_to_send,), daemon=True).start()

    def network_worker(self, text):
        try:
            # Append newline because Elixir uses `packet: :line`
            self.client_socket.sendall(f"{text}\n".encode('utf-8'))
            
            # Read response from Elixir
            response = self.client_socket.recv(1024).decode('utf-8').strip()
            
            # Update GUI from the main thread safely
            self.root.after(0, self.update_ui, response)
        except Exception as e:
            self.root.after(0, self.update_ui, f"Error: {e}")

    def update_ui(self, message):
        self.result_label.config(text=f"Response: {message}")

    def on_close(self):
        self.client_socket.close()
        self.root.destroy()

if __name__ == "__main__":
    root = tk.Tk()
    app = GuiApp(root)
    root.mainloop()
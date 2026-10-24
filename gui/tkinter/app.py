#!/usr/bin/env -S python -u
import os
if   os.getenv('MINECLUSTER_UI') is None or os.getenv('MINECLUSTER_UI') == 'windows':
  from ui import App
elif os.getenv('MINECLUSTER_UI') == 'gnome':
  from ui_linux_gnome import App
else:
  raise TypeError(f'unknown ui kind {os.getenv('MINECLUSTER_UI')=}')
from components import model
from minecluster import ServerGUISocket
import cmdline

if __name__ == "__main__":
  controller = model.Updater()
  args = cmdline.arguments().parse_args()
  ServerGUISocket(controller, args)
  App(controller)

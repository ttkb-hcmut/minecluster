import os, sys, signal
from PySide6.QtGui import QGuiApplication
from PySide6.QtCore import QUrl
from PySide6.QtQml import QQmlApplicationEngine

from components import model

def App(ctrl):
  app = QGuiApplication(sys.argv)
  engine = QQmlApplicationEngine()
  signal.signal(signal.SIGINT, signal.SIG_DFL)
  if not os.environ.get("QT_QUICK_CONTROLS_STYLE"):
    os.environ["QT_QUICK_CONTROLS_STYLE"] = "org.kde.desktop"
  basepath = os.path.abspath(os.path.dirname(__file__))
  url = QUrl(f"file:///{basepath}/ui_linux_plasma.qml")
  engine.load(url)
  if len(engine.rootObjects()) == 0: quit()
  app.exec()

if __name__ == "__main__":
  ctrl = model.Updater()
  App(ctrl)

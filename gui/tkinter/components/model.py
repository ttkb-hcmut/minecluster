from dataclasses import dataclass, fields
import threading
@dataclass
class Model:
  # GUI specific data fields ====================
  currentTab: str

  # Application data fields =====================
  ## config/all
  configAll: dict
  ## list
  nodeList: list
  central: list
  host: list
  online: list
  ## group/list
  groupList: dict
  ## group/status
  groupStatusName: str
  groupStatusConnections: list
  groupStatusCookie: str

class Updater:
  def __init__(self):
    self._lock = threading.Lock()
    self.model = Model()
    self.subscribers = {}
    self.modelFields = list(map(lambda e: e.name, fields(Model)))
    for field in self.modelFields:
      self.subscribers[field] = []

  def subscribe(self,field,func):
    self.subscribers[field] += [func]

  def sendFetch(self,api):
    #send data
    pass

  def set(self,field, data):
    with self._lock:
      if field in self.modelFields:
        setattr(self.model, field, data)

        for subscriber in self.subscribers[field]:
          subscriber()
      else:
        raise ValueError(f"Unknown datafield '{field}'")
    
  def set_multiple(self, fieldDataList):
    with self._lock:
      for field, data in fieldDataList:
        if field in self.modelFields:
          setattr(self.model, field, data)

          for subscriber in self.subscribers[field]:
            subscriber()
        else:
          raise ValueError(f"Unknown datafield '{field}'")

  def get(self,field):
    with self._lock:
      if field in self.modelFields:
          getattr(self.model, field)
      else:
        raise ValueError(f"Unknown datafield '{field}'")

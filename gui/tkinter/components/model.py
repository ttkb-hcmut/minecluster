from dataclasses import dataclass, field, fields

import threading
@dataclass
class Model:
  # GUI specific data fields ====================
  currentTab: str = "home"

  # Application data fields =====================
  ## config/all
  configAll: dict = field(default_factory=dict)
  ## self
  selfAddress: str = "nonode@nohost"
  selfCookie: str = "balls"
  ## list
  nodeList: list = field(default_factory=list)
  central: list = field(default_factory=list)
  host: list = field(default_factory=list)
  online: list = field(default_factory=list)
  ## group/list
  groupList: dict = field(default_factory=dict)
  ## group/status
  groupStatusName: str = ""
  groupStatusConnections: list = field(default_factory=list)
  groupStatusCookie: str = ""

class Updater:
  def __init__(self):
    self._lock = threading.Lock()
    self.model = Model()
    print(f"started up with {getattr(self.model, "currentTab")}")
    self.subscribers = {}
    self.modelFields = list(map(lambda e: e.name, fields(Model)))
    for field in self.modelFields:
      self.subscribers[field] = []

  def subscribe(self,field,func):
    self.subscribers[field] = self.subscribers[field] + [func]
    print(f"{field} -> {func}")

  def sendFetch(self,api):
    #send data
    pass

  def set(self,field, data):
    with self._lock:
      if field in self.modelFields:
        print(f"Setting field {field} = {data}")
        setattr(self.model, field, data)

        for subscriber in self.subscribers[field]: 
          subscriber(data)    
      else:
        raise ValueError(f"Unknown datafield '{field}'")
    
  def set_multiple(self, fieldDataList):
    with self._lock:
      for field, data in fieldDataList:
        if field in self.modelFields:
          setattr(self.model, field, data)

          for subscriber in self.subscribers[field]:
            subscriber(data)
        else:
          raise ValueError(f"Unknown datafield '{field}'")

  def get(self,field):
    with self._lock:
      if field in self.modelFields:
        res = getattr(self.model, field)
        print(f"Getting field: {field} = {res}")
        return res
      else:
        raise ValueError(f"Unknown datafield '{field}'")

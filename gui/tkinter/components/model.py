from dataclasses import dataclass, field, fields
_LOGGING = False
import threading
@dataclass
class Model:
  # GUI specific data fields ====================
  currentTab: str = "home"
  msgFeed: list = field(default_factory=list)

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
    self.pushFunc = lambda a: print(f"Unbinded push func recieved:",a)
    print(f"started up with {getattr(self.model, "currentTab")}") if _LOGGING else None
    self.subscribers = {}
    self.modelFields = list(map(lambda e: e.name, fields(Model)))
    for field in self.modelFields:
      self.subscribers[field] = []

  def subscribe(self,field,func):
    self.subscribers[field] = self.subscribers[field] + [func]
    print(f"{field} -> {func}") if _LOGGING else None

  def setPushToServer(self,func):
    self.pushFunc = func

  def sendFetch(self,api,data):
    message = {}
    message[api] = data
    print(message)
    self.pushFunc(message)
    pass

  def handleIncoming(self,data):
    for key in data.keys():
      if key == "message":
        [sender, group, message] = data[key]
        self.pushMsgQueue(message,sender=sender)



  def set(self,field, data):
    with self._lock:
      if field in self.modelFields:
        print(f"Setting field {field} = {data}") if _LOGGING else None
        setattr(self.model, field, data)

        for subscriber in self.subscribers[field]: 
          subscriber(data)    
      else:
        raise ValueError(f"Unknown datafield '{field}'")
  
  def get_and_set(self,field, func = lambda e:e):
    with self._lock:
      if field in self.modelFields:
        old = getattr(self.model, field)
        print(f"Getting field: {field} = {old}") if _LOGGING else None
        new = func(old)
        setattr(self.model, field, new)
        print(f"Setting field {field} = {new}") if _LOGGING else None

        for subscriber in self.subscribers[field]: 
          subscriber(new)    
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
        print(f"Getting field: {field} = {res}") if _LOGGING else None
        return res
      else:
        raise ValueError(f"Unknown datafield '{field}'")
      
  def pushMsgQueue(self,msg,sender = None):
    if sender is None:
      youmsg = f"You> {msg.strip()}"
      self.get_and_set("msgFeed",
        lambda old: old + [youmsg] if len(old)<32 else [i for i in (old[-31:] + [youmsg])]
      )
      self.sendFetch("command",["msg",msg])
    else:
      fullmsg = f"{sender}:{msg}"
      self.get_and_set("msgFeed",
        lambda old: old + [fullmsg] if len(old)<32 else [i for i in (old[-31:] + [fullmsg])]
      )
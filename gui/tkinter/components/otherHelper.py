class start:
  def __init__(self, pack): self.pack = pack
  def finish(self): pass

class start(start):
  def append(self, it): self.pack.append(it); return self

class start(start):
  def require_version(self, *args): self.pack.require_version(*args); return self

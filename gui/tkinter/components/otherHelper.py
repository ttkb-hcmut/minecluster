class start:
  def __init__(self, pack): self.pack = pack
  def append(self, it): self.pack.append(it); return self
  def require_version(self, *args): self.pack.require_version(*args); return self
  def finish(self): pass

from enum import Enum

class StyleEnum(Enum):
  PAD = 2
  PADD = 5

  FONT = "Arial"
  FONT_SIZE = 10
  FONT_SIZEE = 12

  FRAME_RELIEF = "groove"

class RowTracker():
  def __init__(self, starting = 0):
    self.index = starting if starting >= 0 else 0

  def curr(self, offset = 0):
    return self.index + offset if self.index + offset >= 0 else 0
  
  def next(self,by=1):
    self.index += by
    return self.index if self.index >= 0 else 0

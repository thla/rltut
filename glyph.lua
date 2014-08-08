local class = require 'middleclass'

local Glyph = class('Glyph')

-- syntax equivalent to "Glyph.new = function..."
function Glyph:initialize(properties)
  -- Instantiate properties to default if they weren't passed
  properties = properties or {}
  self._char = properties.character or ' '
  self._foreground = properties.foreground or 'white'
  self._background = properties.background or 'black'
end

function Glyph:getChar()
  return self._char
end

function Glyph:getBackground()
  return self._background
end

function Glyph:getForeground()
  return self._foreground
end

return Glyph

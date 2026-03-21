#pragma once

#include <SDL2/SDL.h>

#include <string>
#include <unordered_map>

#include "core_types.hpp"

namespace war30k {

using FontMap = std::unordered_map<char, Glyph>;

FontMap buildFont();
void drawText(SDL_Renderer* renderer,
              const FontMap& font,
              const std::string& text,
              int x,
              int y,
              int scale,
              SDL_Color color);

}  // namespace war30k

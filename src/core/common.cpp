#include "core_types.hpp"
#include "font.hpp"

#include <algorithm>
#include <cmath>
#include <cctype>
#include <unordered_map>

namespace war30k {

float length(Vec2 v) {
  return std::sqrt(v.x * v.x + v.y * v.y);
}

Vec2 normalize(Vec2 v) {
  const float len = length(v);
  if (len <= 0.0001f) {
    return {0.0f, 0.0f};
  }
  return {v.x / len, v.y / len};
}

float distanceSquared(Vec2 a, Vec2 b) {
  const float dx = a.x - b.x;
  const float dy = a.y - b.y;
  return dx * dx + dy * dy;
}

float clamp(float value, float minValue, float maxValue) {
  return std::max(minValue, std::min(maxValue, value));
}

Facing facingFromVector(Vec2 v, Facing fallback) {
  if (std::fabs(v.x) < 0.01f && std::fabs(v.y) < 0.01f) {
    return fallback;
  }
  if (std::fabs(v.x) > std::fabs(v.y)) {
    return v.x < 0 ? Facing::Left : Facing::Right;
  }
  return v.y < 0 ? Facing::Up : Facing::Down;
}

FontMap buildFont() {
  return {
      {'A', {{0b01110, 0b10001, 0b10001, 0b11111, 0b10001, 0b10001, 0b10001}}},
      {'B', {{0b11110, 0b10001, 0b10001, 0b11110, 0b10001, 0b10001, 0b11110}}},
      {'C', {{0b01110, 0b10001, 0b10000, 0b10000, 0b10000, 0b10001, 0b01110}}},
      {'D', {{0b11100, 0b10010, 0b10001, 0b10001, 0b10001, 0b10010, 0b11100}}},
      {'E', {{0b11111, 0b10000, 0b10000, 0b11110, 0b10000, 0b10000, 0b11111}}},
      {'F', {{0b11111, 0b10000, 0b10000, 0b11110, 0b10000, 0b10000, 0b10000}}},
      {'G', {{0b01110, 0b10001, 0b10000, 0b10000, 0b10011, 0b10001, 0b01110}}},
      {'H', {{0b10001, 0b10001, 0b10001, 0b11111, 0b10001, 0b10001, 0b10001}}},
      {'I', {{0b11111, 0b00100, 0b00100, 0b00100, 0b00100, 0b00100, 0b11111}}},
      {'J', {{0b00111, 0b00010, 0b00010, 0b00010, 0b10010, 0b10010, 0b01100}}},
      {'K', {{0b10001, 0b10010, 0b10100, 0b11000, 0b10100, 0b10010, 0b10001}}},
      {'L', {{0b10000, 0b10000, 0b10000, 0b10000, 0b10000, 0b10000, 0b11111}}},
      {'M', {{0b10001, 0b11011, 0b10101, 0b10001, 0b10001, 0b10001, 0b10001}}},
      {'N', {{0b10001, 0b10001, 0b11001, 0b10101, 0b10011, 0b10001, 0b10001}}},
      {'O', {{0b01110, 0b10001, 0b10001, 0b10001, 0b10001, 0b10001, 0b01110}}},
      {'P', {{0b11110, 0b10001, 0b10001, 0b11110, 0b10000, 0b10000, 0b10000}}},
      {'Q', {{0b01110, 0b10001, 0b10001, 0b10001, 0b10101, 0b10010, 0b01101}}},
      {'R', {{0b11110, 0b10001, 0b10001, 0b11110, 0b10100, 0b10010, 0b10001}}},
      {'S', {{0b01111, 0b10000, 0b10000, 0b01110, 0b00001, 0b00001, 0b11110}}},
      {'T', {{0b11111, 0b00100, 0b00100, 0b00100, 0b00100, 0b00100, 0b00100}}},
      {'U', {{0b10001, 0b10001, 0b10001, 0b10001, 0b10001, 0b10001, 0b01110}}},
      {'V', {{0b10001, 0b10001, 0b10001, 0b10001, 0b01010, 0b01010, 0b00100}}},
      {'W', {{0b10001, 0b10001, 0b10001, 0b10101, 0b10101, 0b10101, 0b01010}}},
      {'X', {{0b10001, 0b01010, 0b00100, 0b00100, 0b00100, 0b01010, 0b10001}}},
      {'Y', {{0b10001, 0b01010, 0b00100, 0b00100, 0b00100, 0b00100, 0b00100}}},
      {'Z', {{0b11111, 0b00010, 0b00100, 0b00100, 0b01000, 0b10000, 0b11111}}},
      {'0', {{0b01110, 0b10001, 0b10011, 0b10101, 0b11001, 0b10001, 0b01110}}},
      {'1', {{0b00100, 0b01100, 0b00100, 0b00100, 0b00100, 0b00100, 0b01110}}},
      {'2', {{0b01110, 0b10001, 0b00001, 0b00010, 0b00100, 0b01000, 0b11111}}},
      {'3', {{0b11110, 0b00001, 0b00001, 0b01110, 0b00001, 0b00001, 0b11110}}},
      {'4', {{0b00010, 0b00110, 0b01010, 0b10010, 0b11111, 0b00010, 0b00010}}},
      {'5', {{0b11111, 0b10000, 0b10000, 0b11110, 0b00001, 0b00001, 0b11110}}},
      {'6', {{0b01110, 0b10000, 0b10000, 0b11110, 0b10001, 0b10001, 0b01110}}},
      {'7', {{0b11111, 0b00001, 0b00010, 0b00100, 0b01000, 0b01000, 0b01000}}},
      {'8', {{0b01110, 0b10001, 0b10001, 0b01110, 0b10001, 0b10001, 0b01110}}},
      {'9', {{0b01110, 0b10001, 0b10001, 0b01111, 0b00001, 0b00001, 0b01110}}},
      {'-', {{0b00000, 0b00000, 0b00000, 0b11111, 0b00000, 0b00000, 0b00000}}},
      {'.', {{0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00100, 0b00100}}},
      {':', {{0b00000, 0b00100, 0b00100, 0b00000, 0b00100, 0b00100, 0b00000}}},
      {'!', {{0b00100, 0b00100, 0b00100, 0b00100, 0b00100, 0b00000, 0b00100}}},
      {'?', {{0b01110, 0b10001, 0b00001, 0b00010, 0b00100, 0b00000, 0b00100}}},
      {'\'', {{0b00100, 0b00100, 0b00000, 0b00000, 0b00000, 0b00000, 0b00000}}},
      {'/', {{0b00001, 0b00010, 0b00100, 0b00100, 0b01000, 0b10000, 0b00000}}},
      {' ', {{0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00000}}},
  };
}

void drawText(SDL_Renderer* renderer,
              const FontMap& font,
              const std::string& text,
              int x,
              int y,
              int scale,
              SDL_Color color) {
  SDL_SetRenderDrawColor(renderer, color.r, color.g, color.b, color.a);
  int cursor = x;
  for (char c : text) {
    char key = static_cast<char>(std::toupper(static_cast<unsigned char>(c)));
    auto it = font.find(key);
    if (it == font.end()) {
      cursor += 6 * scale;
      continue;
    }
    for (int row = 0; row < 7; ++row) {
      for (int col = 0; col < 5; ++col) {
        if ((it->second.rows[row] >> (4 - col)) & 1U) {
          SDL_Rect pixel{cursor + col * scale, y + row * scale, scale, scale};
          SDL_RenderFillRect(renderer, &pixel);
        }
      }
    }
    cursor += 6 * scale;
  }
}

}  // namespace war30k

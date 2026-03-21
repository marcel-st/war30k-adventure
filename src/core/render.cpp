#include "render.hpp"

#include <algorithm>
#include <cmath>
#include <vector>

namespace war30k {

void drawPixelSprite(SDL_Renderer* renderer,
                     const std::vector<std::string>& art,
                     int x,
                     int y,
                     int scale,
                     const std::unordered_map<char, SDL_Color>& palette) {
  for (int row = 0; row < static_cast<int>(art.size()); ++row) {
    for (int col = 0; col < static_cast<int>(art[row].size()); ++col) {
      char p = art[row][col];
      if (p == '.') {
        continue;
      }
      auto it = palette.find(p);
      if (it == palette.end()) {
        continue;
      }
      SDL_SetRenderDrawColor(renderer, it->second.r, it->second.g, it->second.b, it->second.a);
      SDL_Rect px{x + col * scale, y + row * scale, scale, scale};
      SDL_RenderFillRect(renderer, &px);
    }
  }
}

void drawGarro(SDL_Renderer* renderer, Vec2 pos, Facing facing, bool walkFrame) {
  std::vector<std::string> sprite = {
      "....GGGG....",
      "...GSSSSG...",
      "..GSHHHHSG..",
      "..GSSSSSSG..",
      "..GAAAAAAG..",
      ".GGAKKKKAGG.",
      ".GAAKMMKAAG.",
      ".GAAKMMKAAG.",
      ".GAAAAAAAAG.",
      ".GGAA..AAGG.",
      "..GA....AG..",
      "..G......G..",
  };

  if (facing == Facing::Left) {
    sprite[5] = ".GGAKKKAAGG.";
  } else if (facing == Facing::Right) {
    sprite[5] = ".GGAAKKKAGG.";
  } else if (facing == Facing::Up) {
    sprite[2] = "..GSHSHHSG..";
  }

  if (walkFrame) {
    sprite[10] = "..G..  ..G..";
    std::replace(sprite[10].begin(), sprite[10].end(), ' ', '.');
  }

  std::unordered_map<char, SDL_Color> palette{
      {'G', {56, 60, 66, 255}},
      {'S', {188, 198, 205, 255}},
      {'H', {214, 181, 146, 255}},
      {'A', {130, 144, 62, 255}},
      {'K', {235, 215, 120, 255}},
      {'M', {85, 95, 40, 255}},
  };

  drawPixelSprite(renderer, sprite, static_cast<int>(pos.x) - 24, static_cast<int>(pos.y) - 24, 4, palette);
}

void drawTraitor(SDL_Renderer* renderer, Vec2 pos, bool walkFrame) {
  std::vector<std::string> sprite = {
      "...RRRR...",
      "..RHHHHR..",
      "..RHHHHR..",
      "..RBBBBR..",
      ".RRBKKBRR.",
      ".RBBBBBBR.",
      ".RBB..BBR.",
      "..RB..BR..",
      "..R....R..",
  };

  if (walkFrame) {
    sprite[7] = "..R.BR.R..";
  }

  std::unordered_map<char, SDL_Color> palette{
      {'R', {95, 24, 24, 255}},
      {'H', {205, 164, 128, 255}},
      {'B', {164, 44, 44, 255}},
      {'K', {245, 210, 90, 255}},
  };

  drawPixelSprite(renderer, sprite, static_cast<int>(pos.x) - 18, static_cast<int>(pos.y) - 18, 4, palette);
}

void drawBeacon(SDL_Renderer* renderer, Vec2 pos, bool used, float pulse) {
  SDL_Color c0 = used ? SDL_Color{70, 205, 140, 255} : SDL_Color{85, 140, 240, 255};
  SDL_Color c1 = used ? SDL_Color{145, 245, 190, 255} : SDL_Color{175, 210, 255, 255};

  int size = used ? 18 : 16;
  int glow = static_cast<int>(4.0f + pulse * 6.0f);

  SDL_SetRenderDrawColor(renderer, c1.r, c1.g, c1.b, 120);
  SDL_Rect outer{static_cast<int>(pos.x) - size - glow,
                 static_cast<int>(pos.y) - size - glow,
                 (size + glow) * 2,
                 (size + glow) * 2};
  SDL_RenderFillRect(renderer, &outer);

  SDL_SetRenderDrawColor(renderer, c0.r, c0.g, c0.b, 255);
  SDL_Rect core{static_cast<int>(pos.x) - size, static_cast<int>(pos.y) - size, size * 2, size * 2};
  SDL_RenderFillRect(renderer, &core);
}

void drawTileMap(SDL_Renderer* renderer, const Stage& stage, const std::vector<std::string>& map) {
  for (int y = 0; y < MAP_HEIGHT; ++y) {
    for (int x = 0; x < MAP_WIDTH; ++x) {
      SDL_Color c = stage.floor;
      char tile = map[y][x];
      if (tile == '#') {
        c = stage.wall;
      } else if (tile == '+') {
        c = stage.deco;
      } else if ((x + y) % 2 == 0) {
        c = {static_cast<uint8_t>(std::min(255, stage.floor.r + 8)),
             static_cast<uint8_t>(std::min(255, stage.floor.g + 8)),
             static_cast<uint8_t>(std::min(255, stage.floor.b + 8)),
             255};
      }

      SDL_SetRenderDrawColor(renderer, c.r, c.g, c.b, 255);
      SDL_Rect tileRect{x * TILE_SIZE, y * TILE_SIZE, TILE_SIZE, TILE_SIZE};
      SDL_RenderFillRect(renderer, &tileRect);

      if (tile == '#') {
        SDL_SetRenderDrawColor(renderer,
                               static_cast<uint8_t>(std::min(255, c.r + 20)),
                               static_cast<uint8_t>(std::min(255, c.g + 20)),
                               static_cast<uint8_t>(std::min(255, c.b + 20)),
                               255);
        SDL_RenderDrawLine(renderer,
                           x * TILE_SIZE,
                           y * TILE_SIZE,
                           x * TILE_SIZE + TILE_SIZE - 1,
                           y * TILE_SIZE);
      }
    }
  }
}

void drawMiniMap(SDL_Renderer* renderer,
                 const std::vector<std::string>& map,
                 Vec2 player,
                 const std::vector<Enemy>& enemies,
                 const std::vector<Beacon>& beacons,
                 SDL_Rect targetZone) {
  constexpr int miniW = 240;
  constexpr int miniH = 135;
  constexpr int pad = 18;

  SDL_Rect panel{WINDOW_WIDTH - miniW - pad, pad, miniW, miniH};
  SDL_SetRenderDrawColor(renderer, 8, 8, 10, 220);
  SDL_RenderFillRect(renderer, &panel);
  SDL_SetRenderDrawColor(renderer, 180, 180, 180, 255);
  SDL_RenderDrawRect(renderer, &panel);

  const float scaleX = static_cast<float>(miniW - 8) / WINDOW_WIDTH;
  const float scaleY = static_cast<float>(miniH - 8) / WINDOW_HEIGHT;

  for (int y = 0; y < MAP_HEIGHT; ++y) {
    for (int x = 0; x < MAP_WIDTH; ++x) {
      if (map[y][x] != '#') {
        continue;
      }
      SDL_SetRenderDrawColor(renderer, 95, 95, 105, 255);
      SDL_Rect r{panel.x + 4 + static_cast<int>(x * TILE_SIZE * scaleX),
                 panel.y + 4 + static_cast<int>(y * TILE_SIZE * scaleY),
                 std::max(1, static_cast<int>(TILE_SIZE * scaleX)),
                 std::max(1, static_cast<int>(TILE_SIZE * scaleY))};
      SDL_RenderFillRect(renderer, &r);
    }
  }

  SDL_SetRenderDrawColor(renderer, 182, 205, 80, 255);
  SDL_Rect goal{panel.x + 4 + static_cast<int>(targetZone.x * scaleX),
                panel.y + 4 + static_cast<int>(targetZone.y * scaleY),
                std::max(2, static_cast<int>(targetZone.w * scaleX)),
                std::max(2, static_cast<int>(targetZone.h * scaleY))};
  SDL_RenderDrawRect(renderer, &goal);

  for (const auto& beacon : beacons) {
    SDL_SetRenderDrawColor(renderer, beacon.used ? 90 : 65, beacon.used ? 210 : 130, 220, 255);
    SDL_Rect b{panel.x + 4 + static_cast<int>(beacon.pos.x * scaleX) - 1,
               panel.y + 4 + static_cast<int>(beacon.pos.y * scaleY) - 1,
               3,
               3};
    SDL_RenderFillRect(renderer, &b);
  }

  SDL_SetRenderDrawColor(renderer, 190, 58, 58, 255);
  for (const auto& enemy : enemies) {
    if (!enemy.alive) {
      continue;
    }
    SDL_Rect e{panel.x + 4 + static_cast<int>(enemy.pos.x * scaleX) - 1,
               panel.y + 4 + static_cast<int>(enemy.pos.y * scaleY) - 1,
               2,
               2};
    SDL_RenderFillRect(renderer, &e);
  }

  SDL_SetRenderDrawColor(renderer, 238, 238, 238, 255);
  SDL_Rect p{panel.x + 4 + static_cast<int>(player.x * scaleX) - 2,
             panel.y + 4 + static_cast<int>(player.y * scaleY) - 2,
             4,
             4};
  SDL_RenderFillRect(renderer, &p);
}

}  // namespace war30k

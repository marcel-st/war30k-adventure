#pragma once

#include <SDL2/SDL.h>

#include <string>
#include <unordered_map>
#include <vector>

#include "core_types.hpp"

namespace war30k {

void drawPixelSprite(SDL_Renderer* renderer,
                     const std::vector<std::string>& art,
                     int x,
                     int y,
                     int scale,
                     const std::unordered_map<char, SDL_Color>& palette);

void drawGarro(SDL_Renderer* renderer, Vec2 pos, Facing facing, bool walkFrame);
void drawTraitor(SDL_Renderer* renderer, Vec2 pos, bool walkFrame);
void drawBeacon(SDL_Renderer* renderer, Vec2 pos, bool used, float pulse);
void drawTileMap(SDL_Renderer* renderer, const Stage& stage, const std::vector<std::string>& map);
void drawMiniMap(SDL_Renderer* renderer,
                 const std::vector<std::string>& map,
                 Vec2 player,
                 const std::vector<Enemy>& enemies,
                 const std::vector<Beacon>& beacons,
                 SDL_Rect targetZone);

}  // namespace war30k

#pragma once

#include <SDL2/SDL.h>

#include <array>
#include <cstdint>
#include <string>
#include <vector>

namespace war30k {

inline constexpr int WINDOW_WIDTH = 1280;
inline constexpr int WINDOW_HEIGHT = 720;
inline constexpr int TILE_SIZE = 32;
inline constexpr int MAP_WIDTH = WINDOW_WIDTH / TILE_SIZE;
inline constexpr int MAP_HEIGHT = WINDOW_HEIGHT / TILE_SIZE;

inline constexpr float PLAYER_SPEED = 230.0f;
inline constexpr float ENEMY_TOUCH_DAMAGE = 15.0f;
inline constexpr float ENEMY_DAMAGE_COOLDOWN = 0.7f;
inline constexpr float ATTACK_COOLDOWN = 0.3f;
inline constexpr float ATTACK_ARC_TIME = 0.16f;
inline constexpr float ATTACK_RANGE = 60.0f;
inline constexpr float ENTITY_RADIUS = 10.0f;
inline constexpr float PROJECTILE_SPEED = 220.0f;
inline constexpr float PROJECTILE_COOLDOWN = 1.3f;

struct Vec2 {
  float x = 0.0f;
  float y = 0.0f;
};

struct Enemy {
  Vec2 pos;
  float speed = 80.0f;
  float shootTimer = 0.0f;
  bool alive = true;
};

struct Beacon {
  Vec2 pos;
  bool used = false;
};

struct Projectile {
  Vec2 pos;
  Vec2 vel;
  bool alive = true;
};

enum class ObjectiveType { ReachZone, Purge, ActivateBeacons };
enum class PlayPhase { Briefing, Gameplay, Outro, Victory, GameOver };
enum class Facing { Up, Down, Left, Right };

struct Stage {
  std::string name;
  std::vector<std::string> briefing;
  std::vector<std::string> outro;
  SDL_Color bg;
  SDL_Color accent;
  SDL_Color floor;
  SDL_Color wall;
  SDL_Color deco;
  ObjectiveType objectiveType;
  int objectiveCount;
  std::string objectiveLabel;
  int enemyCount;
  float enemySpeed;
};

struct Glyph {
  std::array<uint8_t, 7> rows{};
};

float length(Vec2 v);
Vec2 normalize(Vec2 v);
float distanceSquared(Vec2 a, Vec2 b);
float clamp(float value, float minValue, float maxValue);
Facing facingFromVector(Vec2 v, Facing fallback);

}  // namespace war30k

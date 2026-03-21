#pragma once

#include <SDL2/SDL.h>

#include <random>
#include <string>

#include "core_types.hpp"

namespace war30k::ai {

class Enemy {
 public:
  Enemy(Vec2 spawnPosition, int aggroDistancePixels = 220);
  virtual ~Enemy() = default;

  virtual const char* kind() const = 0;

  void updateAI(float deltaSeconds, SDL_Point playerPosition, std::mt19937& rng);

  void setSpriteSourceRect(SDL_Rect source);
  void render(SDL_Renderer* renderer, SDL_Texture* spriteSheet) const;

  static bool applyLegionPalette(SDL_Texture* texture, const std::string& legionName);

  void knockbackFromPlayer(const SDL_Rect& playerCollisionBox, int pixels);

  SDL_Rect collisionBox() const;
  Vec2 position() const;
  bool isAggro() const;

  void setMovementSpeeds(float wanderSpeed, float aggroSpeed);

 protected:
  Vec2 position_{};
  Vec2 moveDirection_{};
  int aggroDistancePixels_ = 220;
  float wanderSpeed_ = 54.0f;
  float aggroSpeed_ = 92.0f;

 private:
  void updateWanderDirection(float deltaSeconds, std::mt19937& rng);

  SDL_Rect sourceRect_{0, 0, 32, 32};
  bool aggro_ = false;
  float wanderTimerSeconds_ = 0.0f;
};

class DeathGuardTraitorEnemy final : public Enemy {
 public:
  explicit DeathGuardTraitorEnemy(Vec2 spawnPosition);
  const char* kind() const override;
};

class NurgleDaemonEnemy final : public Enemy {
 public:
  explicit NurgleDaemonEnemy(Vec2 spawnPosition);
  const char* kind() const override;
};

}  // namespace war30k::ai

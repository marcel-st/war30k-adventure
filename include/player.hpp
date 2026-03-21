#pragma once

#include <SDL2/SDL.h>

#include <string>

#include "core_types.hpp"

namespace war30k {

struct SpriteState {
  enum class Direction { Up, Down, Left, Right };

  Direction direction = Direction::Down;
  bool moving = false;
  bool swordSwing = false;
  int animationFrame = 0;
  float animationTimerSeconds = 0.0f;
};

class Player {
 public:
  Player(SDL_Renderer* renderer,
         const std::string& spriteSheetPath,
         int frameWidth,
         int frameHeight,
         float renderScale = 2.0f);
  ~Player();

  Player(const Player&) = delete;
  Player& operator=(const Player&) = delete;

  Player(Player&& other) noexcept;
  Player& operator=(Player&& other) noexcept;

  bool isValid() const;
  std::string lastError() const;

  void setPosition(Vec2 pos);
  Vec2 position() const;

  void setMoveIntent(float inputX, float inputY);
  void startSwordSwing();
  void update(float deltaSeconds);

  void render(SDL_Renderer* renderer) const;

  bool isSwordSwingActive() const;
  SDL_Rect swordSwingHitbox() const;
  bool swordHitIntersects(const SDL_Rect& target) const;

  const SpriteState& spriteState() const;

 private:
  int directionRow(SpriteState::Direction direction) const;
  SDL_Rect sourceRect() const;
  float baseDirectionAngleRadians() const;

  SDL_Texture* spriteSheet_ = nullptr;
  int frameWidth_ = 32;
  int frameHeight_ = 32;
  float renderScale_ = 2.0f;

  Vec2 position_{120.0f, 120.0f};
  SpriteState spriteState_{};

  float swordSwingTimerSeconds_ = 0.0f;
  float swordSwingDurationSeconds_ = 0.22f;
  float walkFrameDurationSeconds_ = 0.10f;
  int walkFrameCount_ = 4;
  int swordFrameCount_ = 4;

  bool valid_ = false;
  std::string error_;
};

}  // namespace war30k

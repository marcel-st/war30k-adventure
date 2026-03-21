#include "enemy.hpp"

#include <algorithm>
#include <array>
#include <cctype>
#include <cmath>

namespace war30k::ai {

namespace {

float clampFloat(float value, float minValue, float maxValue) {
  return std::max(minValue, std::min(maxValue, value));
}

std::string lower(std::string text) {
  std::transform(text.begin(), text.end(), text.begin(), [](unsigned char c) {
    return static_cast<char>(std::tolower(c));
  });
  return text;
}

bool intersects(const SDL_Rect& a, const SDL_Rect& b) {
  return SDL_HasIntersection(&a, &b) == SDL_TRUE;
}

}  // namespace

Enemy::Enemy(Vec2 spawnPosition, int aggroDistancePixels)
    : position_(spawnPosition),
      aggroDistancePixels_(std::max(40, aggroDistancePixels)) {
}

void Enemy::setMovementSpeeds(float wanderSpeed, float aggroSpeed) {
  wanderSpeed_ = std::max(1.0f, wanderSpeed);
  aggroSpeed_ = std::max(wanderSpeed_, aggroSpeed);
}

void Enemy::setSpriteSourceRect(SDL_Rect source) {
  sourceRect_.w = std::max(1, source.w);
  sourceRect_.h = std::max(1, source.h);
  sourceRect_.x = std::max(0, source.x);
  sourceRect_.y = std::max(0, source.y);
}

void Enemy::render(SDL_Renderer* renderer, SDL_Texture* spriteSheet) const {
  if (renderer == nullptr || spriteSheet == nullptr) {
    return;
  }

  SDL_Rect dst{
      static_cast<int>(std::round(position_.x)),
      static_cast<int>(std::round(position_.y)),
      sourceRect_.w * 2,
      sourceRect_.h * 2,
  };

  SDL_RenderCopyEx(renderer, spriteSheet, &sourceRect_, &dst, 0.0, nullptr, SDL_FLIP_NONE);
}

bool Enemy::applyLegionPalette(SDL_Texture* texture, const std::string& legionName) {
  if (texture == nullptr) {
    return false;
  }

  const std::string name = lower(legionName);

  if (name.find("emperor") != std::string::npos && name.find("children") != std::string::npos) {
    SDL_SetTextureColorMod(texture, 168, 96, 210);
    return true;
  }

  if (name.find("world") != std::string::npos && name.find("eater") != std::string::npos) {
    SDL_SetTextureColorMod(texture, 222, 230, 255);
    return true;
  }

  SDL_SetTextureColorMod(texture, 255, 255, 255);
  return true;
}

void Enemy::updateAI(float deltaSeconds, SDL_Point playerPosition, std::mt19937& rng) {
  const float dt = std::max(0.0f, deltaSeconds);

  const float ex = position_.x + static_cast<float>(sourceRect_.w);
  const float ey = position_.y + static_cast<float>(sourceRect_.h);
  const float dx = static_cast<float>(playerPosition.x) - ex;
  const float dy = static_cast<float>(playerPosition.y) - ey;
  const float distSq = dx * dx + dy * dy;
  const float aggroRadius = static_cast<float>(aggroDistancePixels_);

  if (distSq <= aggroRadius * aggroRadius) {
    aggro_ = true;
  } else if (distSq > (aggroRadius * 1.35f) * (aggroRadius * 1.35f)) {
    aggro_ = false;
  }

  if (aggro_) {
    const float len = std::sqrt(std::max(0.0001f, distSq));
    moveDirection_.x = dx / len;
    moveDirection_.y = dy / len;
  } else {
    updateWanderDirection(dt, rng);
  }

  const float speed = aggro_ ? aggroSpeed_ : wanderSpeed_;
  position_.x += moveDirection_.x * speed * dt;
  position_.y += moveDirection_.y * speed * dt;

  position_.x = clampFloat(position_.x, 0.0f, static_cast<float>(WINDOW_WIDTH - sourceRect_.w * 2));
  position_.y = clampFloat(position_.y, 0.0f, static_cast<float>(WINDOW_HEIGHT - sourceRect_.h * 2));
}

void Enemy::updateWanderDirection(float deltaSeconds, std::mt19937& rng) {
  wanderTimerSeconds_ -= deltaSeconds;
  if (wanderTimerSeconds_ > 0.0f) {
    return;
  }

  std::uniform_real_distribution<float> timerDist(0.35f, 1.25f);
  std::uniform_int_distribution<int> dirDist(0, 8);

  static constexpr std::array<Vec2, 9> directions{{
      {0.0f, -1.0f},
      {0.707f, -0.707f},
      {1.0f, 0.0f},
      {0.707f, 0.707f},
      {0.0f, 1.0f},
      {-0.707f, 0.707f},
      {-1.0f, 0.0f},
      {-0.707f, -0.707f},
      {0.0f, 0.0f},
  }};

  wanderTimerSeconds_ = timerDist(rng);
  moveDirection_ = directions[dirDist(rng)];
}

void Enemy::knockbackFromPlayer(const SDL_Rect& playerCollisionBox, int pixels) {
  const SDL_Rect enemyBox = collisionBox();
  const float enemyCenterX = static_cast<float>(enemyBox.x + enemyBox.w / 2);
  const float enemyCenterY = static_cast<float>(enemyBox.y + enemyBox.h / 2);
  const float playerCenterX = static_cast<float>(playerCollisionBox.x + playerCollisionBox.w / 2);
  const float playerCenterY = static_cast<float>(playerCollisionBox.y + playerCollisionBox.h / 2);

  float pushX = enemyCenterX - playerCenterX;
  float pushY = enemyCenterY - playerCenterY;
  const float len = std::sqrt(pushX * pushX + pushY * pushY);

  if (len < 0.001f) {
    pushX = 1.0f;
    pushY = 0.0f;
  } else {
    pushX /= len;
    pushY /= len;
  }

  const float pushPixels = static_cast<float>(std::max(1, pixels));
  position_.x += pushX * pushPixels;
  position_.y += pushY * pushPixels;

  SDL_Rect newEnemyBox = collisionBox();
  if (intersects(newEnemyBox, playerCollisionBox)) {
    const int overlapLeft = (newEnemyBox.x + newEnemyBox.w) - playerCollisionBox.x;
    const int overlapRight = (playerCollisionBox.x + playerCollisionBox.w) - newEnemyBox.x;
    const int overlapTop = (newEnemyBox.y + newEnemyBox.h) - playerCollisionBox.y;
    const int overlapBottom = (playerCollisionBox.y + playerCollisionBox.h) - newEnemyBox.y;

    const int sepX = std::min(overlapLeft, overlapRight);
    const int sepY = std::min(overlapTop, overlapBottom);

    if (sepX < sepY) {
      if (enemyCenterX < playerCenterX) {
        position_.x -= static_cast<float>(sepX + 1);
      } else {
        position_.x += static_cast<float>(sepX + 1);
      }
    } else {
      if (enemyCenterY < playerCenterY) {
        position_.y -= static_cast<float>(sepY + 1);
      } else {
        position_.y += static_cast<float>(sepY + 1);
      }
    }
  }
}

SDL_Rect Enemy::collisionBox() const {
  const int width = static_cast<int>(std::round(sourceRect_.w * 1.45f));
  const int height = static_cast<int>(std::round(sourceRect_.h * 1.45f));
  const int offsetX = static_cast<int>(std::round(sourceRect_.w * 0.25f));
  const int offsetY = static_cast<int>(std::round(sourceRect_.h * 0.35f));

  return {
      static_cast<int>(std::round(position_.x)) + offsetX,
      static_cast<int>(std::round(position_.y)) + offsetY,
      width,
      height,
  };
}

Vec2 Enemy::position() const {
  return position_;
}

bool Enemy::isAggro() const {
  return aggro_;
}

DeathGuardTraitorEnemy::DeathGuardTraitorEnemy(Vec2 spawnPosition)
    : Enemy(spawnPosition, 230) {
  setMovementSpeeds(52.0f, 94.0f);
}

const char* DeathGuardTraitorEnemy::kind() const {
  return "Death Guard Traitor";
}

NurgleDaemonEnemy::NurgleDaemonEnemy(Vec2 spawnPosition)
    : Enemy(spawnPosition, 260) {
  setMovementSpeeds(46.0f, 82.0f);
}

const char* NurgleDaemonEnemy::kind() const {
  return "Nurgle Daemon";
}

}  // namespace war30k::ai

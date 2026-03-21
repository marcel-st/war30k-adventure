#include "player.hpp"

#include <SDL2/SDL.h>

#include <algorithm>
#include <cmath>
#include <string>
#include <utility>

namespace war30k {

namespace {

constexpr float PI = 3.1415926535f;

}  // namespace

Player::Player(SDL_Renderer* renderer,
               const std::string& spriteSheetPath,
               int frameWidth,
               int frameHeight,
               float renderScale)
    : frameWidth_(std::max(1, frameWidth)),
      frameHeight_(std::max(1, frameHeight)),
      renderScale_(std::max(1.0f, renderScale)) {
  SDL_SetHint(SDL_HINT_RENDER_SCALE_QUALITY, "0");

  SDL_Surface* surface = SDL_LoadBMP(spriteSheetPath.c_str());
  if (surface == nullptr) {
    error_ = "Failed to load player spritesheet: " + spriteSheetPath + " - " + SDL_GetError();
    return;
  }

  spriteSheet_ = SDL_CreateTextureFromSurface(renderer, surface);
  SDL_FreeSurface(surface);

  if (spriteSheet_ == nullptr) {
    error_ = "Failed to create player texture: " + spriteSheetPath + " - " + SDL_GetError();
    return;
  }

    swordSwingDurationSeconds_ = 0.18f;
    walkFrameDurationSeconds_ = 0.085f;

  valid_ = true;
}

Player::~Player() {
  if (spriteSheet_ != nullptr) {
    SDL_DestroyTexture(spriteSheet_);
    spriteSheet_ = nullptr;
  }
}

Player::Player(Player&& other) noexcept {
  *this = std::move(other);
}

Player& Player::operator=(Player&& other) noexcept {
  if (this == &other) {
    return *this;
  }

  if (spriteSheet_ != nullptr) {
    SDL_DestroyTexture(spriteSheet_);
  }

  spriteSheet_ = other.spriteSheet_;
  frameWidth_ = other.frameWidth_;
  frameHeight_ = other.frameHeight_;
  renderScale_ = other.renderScale_;
  position_ = other.position_;
  spriteState_ = other.spriteState_;
  swordSwingTimerSeconds_ = other.swordSwingTimerSeconds_;
  swordSwingDurationSeconds_ = other.swordSwingDurationSeconds_;
  walkFrameDurationSeconds_ = other.walkFrameDurationSeconds_;
  walkFrameCount_ = other.walkFrameCount_;
  swordFrameCount_ = other.swordFrameCount_;
  valid_ = other.valid_;
  error_ = std::move(other.error_);

  other.spriteSheet_ = nullptr;
  other.valid_ = false;

  return *this;
}

bool Player::isValid() const {
  return valid_;
}

std::string Player::lastError() const {
  return error_;
}

void Player::setPosition(Vec2 pos) {
  position_ = pos;
}

Vec2 Player::position() const {
  return position_;
}

void Player::setMoveIntent(float inputX, float inputY) {
  const float magnitudeSquared = inputX * inputX + inputY * inputY;
  spriteState_.moving = magnitudeSquared > 0.0001f;

  if (!spriteState_.moving) {
    return;
  }

  if (std::fabs(inputX) > std::fabs(inputY)) {
    spriteState_.direction = inputX >= 0.0f ? SpriteState::Direction::Right : SpriteState::Direction::Left;
  } else {
    spriteState_.direction = inputY >= 0.0f ? SpriteState::Direction::Down : SpriteState::Direction::Up;
  }
}

void Player::startSwordSwing() {
  spriteState_.swordSwing = true;
  swordSwingTimerSeconds_ = 0.0f;
  spriteState_.animationFrame = 0;
  spriteState_.animationTimerSeconds = 0.0f;
}

void Player::update(float deltaSeconds) {
  if (!valid_) {
    return;
  }

  const float dt = std::max(0.0f, deltaSeconds);
  spriteState_.animationTimerSeconds += dt;

  if (spriteState_.swordSwing) {
    swordSwingTimerSeconds_ += dt;

    const float swingProgress = std::min(1.0f, swordSwingTimerSeconds_ / swordSwingDurationSeconds_);
    spriteState_.animationFrame = std::min(swordFrameCount_ - 1, static_cast<int>(swingProgress * swordFrameCount_));

    if (swordSwingTimerSeconds_ >= swordSwingDurationSeconds_) {
      spriteState_.swordSwing = false;
      swordSwingTimerSeconds_ = 0.0f;
      spriteState_.animationFrame = 0;
      spriteState_.animationTimerSeconds = 0.0f;
    }
    return;
  }

  if (!spriteState_.moving) {
    spriteState_.animationFrame = 0;
    spriteState_.animationTimerSeconds = 0.0f;
    return;
  }

  while (spriteState_.animationTimerSeconds >= walkFrameDurationSeconds_) {
    spriteState_.animationTimerSeconds -= walkFrameDurationSeconds_;
    spriteState_.animationFrame = (spriteState_.animationFrame + 1) % walkFrameCount_;
  }
}

void Player::render(SDL_Renderer* renderer) const {
  if (!valid_ || renderer == nullptr || spriteSheet_ == nullptr) {
    return;
  }

  const SDL_Rect src = sourceRect();
  SDL_Rect dst{
      static_cast<int>(std::round(position_.x)),
      static_cast<int>(std::round(position_.y)),
      static_cast<int>(std::round(static_cast<float>(frameWidth_) * renderScale_)),
      static_cast<int>(std::round(static_cast<float>(frameHeight_) * renderScale_)),
  };

  SDL_RenderCopyEx(renderer, spriteSheet_, &src, &dst, 0.0, nullptr, SDL_FLIP_NONE);
}

bool Player::isSwordSwingActive() const {
  return spriteState_.swordSwing;
}

SDL_Rect Player::swordSwingHitbox() const {
  if (!spriteState_.swordSwing) {
    return {0, 0, 0, 0};
  }

  const float progress = std::min(1.0f, swordSwingTimerSeconds_ / swordSwingDurationSeconds_);
  const float centerAngle = baseDirectionAngleRadians();
  const float arcStart = centerAngle - (PI / 2.0f);
    if (progress < 0.06f || progress > 0.97f) {
      return {0, 0, 0, 0};
    }

    const float easedProgress = 1.0f - std::pow(1.0f - progress, 2.2f);
    const float angle = arcStart + easedProgress * PI;

  const float spriteWorldWidth = static_cast<float>(frameWidth_) * renderScale_;
  const float spriteWorldHeight = static_cast<float>(frameHeight_) * renderScale_;
  const Vec2 center{
      position_.x + spriteWorldWidth * 0.5f,
      position_.y + spriteWorldHeight * 0.56f,
  };

    const float radius = std::max(spriteWorldWidth, spriteWorldHeight) * 0.66f;
    const float hitboxScalePulse = 0.86f + 0.36f * std::sin(easedProgress * PI);
    const float hitboxSize = std::max(16.0f, spriteWorldWidth * 0.34f * hitboxScalePulse);

  const float hitboxX = center.x + std::cos(angle) * radius - hitboxSize * 0.5f;
  const float hitboxY = center.y + std::sin(angle) * radius - hitboxSize * 0.5f;

  return {
      static_cast<int>(std::round(hitboxX)),
      static_cast<int>(std::round(hitboxY)),
      static_cast<int>(std::round(hitboxSize)),
      static_cast<int>(std::round(hitboxSize)),
  };
}

bool Player::swordHitIntersects(const SDL_Rect& target) const {
  SDL_Rect swordBox = swordSwingHitbox();
  if (swordBox.w == 0 || swordBox.h == 0) {
    return false;
  }
  return SDL_HasIntersection(&swordBox, &target) == SDL_TRUE;
}

const SpriteState& Player::spriteState() const {
  return spriteState_;
}

int Player::directionRow(SpriteState::Direction direction) const {
  switch (direction) {
    case SpriteState::Direction::Down:
      return 0;
    case SpriteState::Direction::Left:
      return 1;
    case SpriteState::Direction::Right:
      return 2;
    case SpriteState::Direction::Up:
      return 3;
  }
  return 0;
}

SDL_Rect Player::sourceRect() const {
  const int frame = spriteState_.swordSwing
                        ? std::min(spriteState_.animationFrame, swordFrameCount_ - 1)
                        : (spriteState_.moving ? spriteState_.animationFrame : 0);

  const int row = directionRow(spriteState_.direction);
  const int rowOffset = spriteState_.swordSwing ? 4 : 0;

  return {
      frame * frameWidth_,
      (row + rowOffset) * frameHeight_,
      frameWidth_,
      frameHeight_,
  };
}

float Player::baseDirectionAngleRadians() const {
  switch (spriteState_.direction) {
    case SpriteState::Direction::Right:
      return 0.0f;
    case SpriteState::Direction::Down:
      return PI * 0.5f;
    case SpriteState::Direction::Left:
      return PI;
    case SpriteState::Direction::Up:
      return PI * 1.5f;
  }
  return 0.0f;
}

}  // namespace war30k

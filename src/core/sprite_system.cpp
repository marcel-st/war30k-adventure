#include "sprite_system.hpp"

#include <SDL2/SDL.h>

#include <algorithm>
#include <cmath>

namespace war30k::retro {

namespace {

int directionRow(Direction direction) {
  switch (direction) {
    case Direction::NORTH:
      return 0;
    case Direction::SOUTH:
      return 1;
    case Direction::EAST:
      return 2;
    case Direction::WEST:
      return 3;
  }
  return 1;
}

}  // namespace

SpaceMarine::SpaceMarine(SDL_Texture* spriteSheet) {
  sprite_.texture = spriteSheet;
  sprite_.frameWidth = 24;
  sprite_.frameHeight = 32;
  sprite_.framesPerDirection = 2;
  sprite_.direction = Direction::SOUTH;
}

void SpaceMarine::setPosition(int x, int y) {
  worldX_ = x;
  worldY_ = y;
}

void SpaceMarine::setDirection(Direction direction) {
  sprite_.direction = direction;
}

void SpaceMarine::setMoving(bool moving) {
  moving_ = moving;
  if (!moving_) {
    sprite_.currentFrame = 0;
    torsoBounceOffset_ = 0;
  }
}

void SpaceMarine::updateWalkingAnimation(float deltaSeconds) {
  if (!moving_) {
    return;
  }

  sprite_.frameTimerMs += std::max(0.0f, deltaSeconds) * 1000.0f;
  while (sprite_.frameTimerMs >= 150.0f) {
    sprite_.frameTimerMs -= 150.0f;
    sprite_.currentFrame = (sprite_.currentFrame + 1) % 2;
  }

  torsoBounceOffset_ = (sprite_.currentFrame == 1) ? 1 : 0;
}

SDL_Rect SpaceMarine::sourceRect() const {
  const int row = directionRow(sprite_.direction);
  return {
      sprite_.currentFrame * sprite_.frameWidth,
      row * sprite_.frameHeight,
      sprite_.frameWidth,
      sprite_.frameHeight,
  };
}

SDL_Rect SpaceMarine::collisionBounds() const {
  return {worldX_, worldY_, 24, 32};
}

int SpaceMarine::sortY() const {
  SDL_Rect box = collisionBounds();
  return box.y + box.h;
}

void SpaceMarine::render(SDL_Renderer* renderer, float) {
  if (renderer == nullptr || sprite_.texture == nullptr) {
    return;
  }

  SDL_Rect src = sourceRect();

  SDL_Rect dst = collisionBounds();

  SDL_Rect srcLower{src.x, src.y + src.h / 2, src.w, src.h / 2};
  SDL_Rect dstLower{dst.x, dst.y + dst.h / 2, dst.w, dst.h / 2};

  SDL_Rect srcUpper{src.x, src.y, src.w, src.h / 2};
  SDL_Rect dstUpper{dst.x, dst.y + torsoBounceOffset_, dst.w, dst.h / 2};

  SDL_RenderCopyEx(renderer, sprite_.texture, &srcLower, &dstLower, 0.0, nullptr, SDL_FLIP_NONE);
  SDL_RenderCopyEx(renderer, sprite_.texture, &srcUpper, &dstUpper, 0.0, nullptr, SDL_FLIP_NONE);
}

AnimatedSprite& SpaceMarine::sprite() {
  return sprite_;
}

const AnimatedSprite& SpaceMarine::sprite() const {
  return sprite_;
}

WarpDaemon::WarpDaemon(SDL_Texture* spriteSheet) {
  sprite_.texture = spriteSheet;
  sprite_.frameWidth = 24;
  sprite_.frameHeight = 32;
  sprite_.framesPerDirection = 2;
  sprite_.direction = Direction::SOUTH;
}

void WarpDaemon::setPosition(int x, int y) {
  worldX_ = x;
  worldY_ = y;
}

void WarpDaemon::setDirection(Direction direction) {
  sprite_.direction = direction;
}

void WarpDaemon::setFloatParameters(float amplitudePixels, float frequency) {
  floatAmplitude_ = std::max(0.0f, amplitudePixels);
  floatFrequency_ = std::max(0.01f, frequency);
}

SDL_Rect WarpDaemon::sourceRect() const {
  const int row = directionRow(sprite_.direction);
  return {
      sprite_.currentFrame * sprite_.frameWidth,
      row * sprite_.frameHeight,
      sprite_.frameWidth,
      sprite_.frameHeight,
  };
}

SDL_Rect WarpDaemon::applyWarpFloat(SDL_Rect destination, float elapsedSeconds) const {
  const float offsetY = floatAmplitude_ * std::sin(floatFrequency_ * elapsedSeconds);
  destination.y += static_cast<int>(std::round(offsetY));
  return destination;
}

SDL_Rect WarpDaemon::collisionBounds() const {
  return {worldX_, worldY_, 24, 32};
}

int WarpDaemon::sortY() const {
  SDL_Rect box = collisionBounds();
  return box.y + box.h;
}

void WarpDaemon::render(SDL_Renderer* renderer, float elapsedSeconds) {
  if (renderer == nullptr || sprite_.texture == nullptr) {
    return;
  }

  SDL_Rect src = sourceRect();
  SDL_Rect dst = collisionBounds();
  dst = applyWarpFloat(dst, elapsedSeconds);

  SDL_RenderCopyEx(renderer, sprite_.texture, &src, &dst, 0.0, nullptr, SDL_FLIP_NONE);
}

void sortEntitiesByY(std::vector<SpriteEntity*>& entities) {
  std::stable_sort(entities.begin(), entities.end(), [](const SpriteEntity* a, const SpriteEntity* b) {
    if (a == nullptr || b == nullptr) {
      return b != nullptr;
    }
    return a->sortY() < b->sortY();
  });
}

}  // namespace war30k::retro

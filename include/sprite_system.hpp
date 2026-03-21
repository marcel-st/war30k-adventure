#pragma once

#include <SDL2/SDL.h>

#include <vector>

namespace war30k::retro {

enum class Direction {
  NORTH = 0,
  SOUTH = 1,
  EAST = 2,
  WEST = 3,
};

struct AnimatedSprite {
  SDL_Texture* texture = nullptr;
  int currentFrame = 0;
  Direction direction = Direction::SOUTH;
  int frameWidth = 24;
  int frameHeight = 32;
  int framesPerDirection = 2;
  float frameTimerMs = 0.0f;
};

class SpriteEntity {
 public:
  virtual ~SpriteEntity() = default;

  virtual SDL_Rect collisionBounds() const = 0;
  virtual int sortY() const = 0;
  virtual void render(SDL_Renderer* renderer, float elapsedSeconds) = 0;
};

class SpaceMarine : public SpriteEntity {
 public:
  explicit SpaceMarine(SDL_Texture* spriteSheet);

  void setPosition(int x, int y);
  void setDirection(Direction direction);
  void setMoving(bool moving);

  void updateWalkingAnimation(float deltaSeconds);

  SDL_Rect collisionBounds() const override;
  int sortY() const override;
  void render(SDL_Renderer* renderer, float elapsedSeconds) override;

  AnimatedSprite& sprite();
  const AnimatedSprite& sprite() const;

 private:
  SDL_Rect sourceRect() const;

  AnimatedSprite sprite_{};
  int worldX_ = 100;
  int worldY_ = 100;
  bool moving_ = false;
  int torsoBounceOffset_ = 0;
};

class WarpDaemon : public SpriteEntity {
 public:
  explicit WarpDaemon(SDL_Texture* spriteSheet);

  void setPosition(int x, int y);
  void setDirection(Direction direction);
  void setFloatParameters(float amplitudePixels, float frequency);

  SDL_Rect applyWarpFloat(SDL_Rect destination, float elapsedSeconds) const;

  SDL_Rect collisionBounds() const override;
  int sortY() const override;
  void render(SDL_Renderer* renderer, float elapsedSeconds) override;

 private:
  SDL_Rect sourceRect() const;

  AnimatedSprite sprite_{};
  int worldX_ = 220;
  int worldY_ = 220;
  float floatAmplitude_ = 2.0f;
  float floatFrequency_ = 5.0f;
};

void sortEntitiesByY(std::vector<SpriteEntity*>& entities);

}  // namespace war30k::retro

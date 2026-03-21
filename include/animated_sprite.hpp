#pragma once

#include <SDL2/SDL.h>

#include <array>
#include <string>
#include <unordered_map>
#include <vector>

namespace war30k {

class AnimatedSprite {
 public:
  struct Frame {
    SDL_Rect source{0, 0, 0, 0};
    int durationMs = 120;
  };

  AnimatedSprite(SDL_Renderer* renderer,
                 const std::string& spriteSheetPath,
                 const std::string& frameDefinitionPath);
  ~AnimatedSprite();

  AnimatedSprite(const AnimatedSprite&) = delete;
  AnimatedSprite& operator=(const AnimatedSprite&) = delete;

  AnimatedSprite(AnimatedSprite&& other) noexcept;
  AnimatedSprite& operator=(AnimatedSprite&& other) noexcept;

  bool isValid() const;
  std::string lastError() const;

  bool setAnimation(const std::string& state, int direction);
  void update(float deltaSeconds);

  void draw(SDL_Renderer* renderer,
            int x,
            int y,
            float scale = 1.0f,
            SDL_RendererFlip flip = SDL_FLIP_NONE) const;

  std::string currentState() const;
  int currentDirection() const;

 private:
  using DirectionSet = std::array<std::vector<Frame>, 8>;

  bool loadSpriteSheet(SDL_Renderer* renderer, const std::string& spriteSheetPath);
  bool loadFrameDefinition(const std::string& frameDefinitionPath);

  std::vector<Frame> parseFrameArray(const std::string& json, std::size_t arrayStart) const;
  int parseIntField(const std::string& objectText, const std::string& key, int fallback) const;
  std::size_t findMatching(const std::string& text, std::size_t openPos, char openChar, char closeChar) const;

  const std::vector<Frame>& activeFrames() const;
  void normalizeStateDirection(std::string& state, int& direction) const;

  SDL_Texture* texture_ = nullptr;
  std::unordered_map<std::string, DirectionSet> animations_;

  std::string state_ = "Idle";
  int direction_ = 0;
  std::size_t frameIndex_ = 0;
  float frameTimerMs_ = 0.0f;
  float stateElapsedSeconds_ = 0.0f;

  bool valid_ = false;
  std::string error_;
};

}  // namespace war30k

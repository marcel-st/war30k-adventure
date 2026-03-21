#include "animated_sprite.hpp"

#include <SDL2/SDL.h>

#include <algorithm>
#include <cctype>
#include <cmath>
#include <fstream>
#include <iterator>
#include <string>
#include <utility>

namespace war30k {

namespace {

std::string toTitleCase(std::string state) {
  std::transform(state.begin(), state.end(), state.begin(), [](unsigned char c) {
    return static_cast<char>(std::tolower(c));
  });
  if (!state.empty()) {
    state[0] = static_cast<char>(std::toupper(static_cast<unsigned char>(state[0])));
  }
  return state;
}

}  // namespace

AnimatedSprite::AnimatedSprite(SDL_Renderer* renderer,
                               const std::string& spriteSheetPath,
                               const std::string& frameDefinitionPath) {
  valid_ = loadSpriteSheet(renderer, spriteSheetPath) && loadFrameDefinition(frameDefinitionPath);
  if (!valid_ && error_.empty()) {
    error_ = "AnimatedSprite initialization failed";
  }
}

AnimatedSprite::~AnimatedSprite() {
  if (texture_ != nullptr) {
    SDL_DestroyTexture(texture_);
    texture_ = nullptr;
  }
}

AnimatedSprite::AnimatedSprite(AnimatedSprite&& other) noexcept {
  *this = std::move(other);
}

AnimatedSprite& AnimatedSprite::operator=(AnimatedSprite&& other) noexcept {
  if (this == &other) {
    return *this;
  }

  if (texture_ != nullptr) {
    SDL_DestroyTexture(texture_);
  }

  texture_ = other.texture_;
  animations_ = std::move(other.animations_);
  state_ = std::move(other.state_);
  direction_ = other.direction_;
  frameIndex_ = other.frameIndex_;
  frameTimerMs_ = other.frameTimerMs_;
  stateElapsedSeconds_ = other.stateElapsedSeconds_;
  valid_ = other.valid_;
  error_ = std::move(other.error_);

  other.texture_ = nullptr;
  other.valid_ = false;

  return *this;
}

bool AnimatedSprite::isValid() const {
  return valid_;
}

std::string AnimatedSprite::lastError() const {
  return error_;
}

std::string AnimatedSprite::currentState() const {
  return state_;
}

int AnimatedSprite::currentDirection() const {
  return direction_;
}

bool AnimatedSprite::setAnimation(const std::string& state, int direction) {
  std::string normalized = state;
  int normalizedDirection = direction;
  normalizeStateDirection(normalized, normalizedDirection);

  auto stateIt = animations_.find(normalized);
  if (stateIt == animations_.end()) {
    return false;
  }

  if (stateIt->second[normalizedDirection].empty()) {
    return false;
  }

  if (state_ != normalized || direction_ != normalizedDirection) {
    state_ = normalized;
    direction_ = normalizedDirection;
    frameIndex_ = 0;
    frameTimerMs_ = 0.0f;
    stateElapsedSeconds_ = 0.0f;
  }

  return true;
}

void AnimatedSprite::update(float deltaSeconds) {
  const std::vector<Frame>& frames = activeFrames();
  if (!valid_ || frames.empty()) {
    return;
  }

  const float deltaMs = deltaSeconds * 1000.0f;
  frameTimerMs_ += deltaMs;
  stateElapsedSeconds_ += deltaSeconds;

  while (frameTimerMs_ >= static_cast<float>(std::max(1, frames[frameIndex_].durationMs))) {
    frameTimerMs_ -= static_cast<float>(std::max(1, frames[frameIndex_].durationMs));
    frameIndex_ = (frameIndex_ + 1) % frames.size();
  }
}

void AnimatedSprite::draw(SDL_Renderer* renderer,
                          int x,
                          int y,
                          float scale,
                          SDL_RendererFlip flip) const {
  if (!valid_ || texture_ == nullptr || renderer == nullptr) {
    return;
  }

  const std::vector<Frame>& frames = activeFrames();
  if (frames.empty()) {
    return;
  }

  const Frame& frame = frames[frameIndex_ % frames.size()];
  SDL_Rect dst{ x,
                y,
                static_cast<int>(std::round(static_cast<float>(frame.source.w) * scale)),
                static_cast<int>(std::round(static_cast<float>(frame.source.h) * scale)) };

  float idleBreathOffset = 0.0f;
  float walkStompOffset = 0.0f;

  if (state_ == "Idle") {
    idleBreathOffset = std::sin(stateElapsedSeconds_ * 2.2f) * 1.5f;
  } else if (state_ == "Walk") {
    float normalizedFrameTime = frameTimerMs_ / static_cast<float>(std::max(1, frame.durationMs));
    bool heavyStep = (frameIndex_ % 2) == 1;
    if (heavyStep) {
      float down = std::sin(normalizedFrameTime * 3.14159265f);
      walkStompOffset = std::max(0.0f, down) * 4.0f;
    }
  }

  dst.y += static_cast<int>(std::round(walkStompOffset));

  SDL_RenderCopyEx(renderer, texture_, &frame.source, &dst, 0.0, nullptr, flip);

  if (state_ == "Idle") {
    SDL_Rect upperSrc = frame.source;
    upperSrc.h = frame.source.h / 2;

    SDL_Rect upperDst = dst;
    upperDst.h = dst.h / 2;
    upperDst.y += static_cast<int>(std::round(idleBreathOffset));

    SDL_RenderCopyEx(renderer, texture_, &upperSrc, &upperDst, 0.0, nullptr, flip);
  }
}

bool AnimatedSprite::loadSpriteSheet(SDL_Renderer* renderer, const std::string& spriteSheetPath) {
  SDL_Surface* surface = SDL_LoadBMP(spriteSheetPath.c_str());
  if (surface == nullptr) {
    error_ = "Failed to load spritesheet: " + spriteSheetPath + " - " + SDL_GetError();
    return false;
  }

  texture_ = SDL_CreateTextureFromSurface(renderer, surface);
  SDL_FreeSurface(surface);

  if (texture_ == nullptr) {
    error_ = "Failed to create texture from spritesheet: " + spriteSheetPath + " - " + SDL_GetError();
    return false;
  }

  return true;
}

bool AnimatedSprite::loadFrameDefinition(const std::string& frameDefinitionPath) {
  std::ifstream file(frameDefinitionPath);
  if (!file) {
    error_ = "Failed to open frame definition JSON: " + frameDefinitionPath;
    return false;
  }

  std::string json((std::istreambuf_iterator<char>(file)), std::istreambuf_iterator<char>());

  std::array<std::string, 2> states{"Idle", "Walk"};
  for (const std::string& state : states) {
    DirectionSet directionSet;
    for (int dir = 0; dir < 8; ++dir) {
      const std::string key = "\"" + state + "_" + std::to_string(dir) + "\"";
      std::size_t keyPos = json.find(key);
      if (keyPos == std::string::npos) {
        continue;
      }

      std::size_t arrayStart = json.find('[', keyPos);
      if (arrayStart == std::string::npos) {
        continue;
      }

      directionSet[dir] = parseFrameArray(json, arrayStart);
    }
    animations_[state] = std::move(directionSet);
  }

  if (animations_.empty()) {
    error_ = "No animations were parsed from JSON";
    return false;
  }

  if (!setAnimation("Idle", 0)) {
    if (!setAnimation("Walk", 0)) {
      error_ = "No valid Idle/Walk directional frames found in JSON";
      return false;
    }
  }

  return true;
}

std::vector<AnimatedSprite::Frame> AnimatedSprite::parseFrameArray(const std::string& json,
                                                                   std::size_t arrayStart) const {
  std::vector<Frame> frames;
  std::size_t arrayEnd = findMatching(json, arrayStart, '[', ']');
  if (arrayEnd == std::string::npos) {
    return frames;
  }

  std::size_t cursor = arrayStart;
  while (cursor < arrayEnd) {
    std::size_t objStart = json.find('{', cursor);
    if (objStart == std::string::npos || objStart > arrayEnd) {
      break;
    }
    std::size_t objEnd = findMatching(json, objStart, '{', '}');
    if (objEnd == std::string::npos || objEnd > arrayEnd) {
      break;
    }

    std::string objectText = json.substr(objStart, objEnd - objStart + 1);
    Frame frame;
    frame.source.x = parseIntField(objectText, "x", 0);
    frame.source.y = parseIntField(objectText, "y", 0);
    frame.source.w = parseIntField(objectText, "w", 0);
    frame.source.h = parseIntField(objectText, "h", 0);
    frame.durationMs = parseIntField(objectText, "duration", 120);

    if (frame.source.w > 0 && frame.source.h > 0) {
      frames.push_back(frame);
    }

    cursor = objEnd + 1;
  }

  return frames;
}

int AnimatedSprite::parseIntField(const std::string& objectText,
                                  const std::string& key,
                                  int fallback) const {
  const std::string token = "\"" + key + "\"";
  std::size_t keyPos = objectText.find(token);
  if (keyPos == std::string::npos) {
    return fallback;
  }

  std::size_t colon = objectText.find(':', keyPos);
  if (colon == std::string::npos) {
    return fallback;
  }

  std::size_t valueStart = colon + 1;
  while (valueStart < objectText.size() && std::isspace(static_cast<unsigned char>(objectText[valueStart]))) {
    valueStart++;
  }

  std::size_t valueEnd = valueStart;
  if (valueEnd < objectText.size() && (objectText[valueEnd] == '-' || std::isdigit(static_cast<unsigned char>(objectText[valueEnd])))) {
    valueEnd++;
    while (valueEnd < objectText.size() && std::isdigit(static_cast<unsigned char>(objectText[valueEnd]))) {
      valueEnd++;
    }
  }

  if (valueEnd <= valueStart) {
    return fallback;
  }

  try {
    return std::stoi(objectText.substr(valueStart, valueEnd - valueStart));
  } catch (...) {
    return fallback;
  }
}

std::size_t AnimatedSprite::findMatching(const std::string& text,
                                         std::size_t openPos,
                                         char openChar,
                                         char closeChar) const {
  if (openPos >= text.size() || text[openPos] != openChar) {
    return std::string::npos;
  }

  int depth = 0;
  for (std::size_t i = openPos; i < text.size(); ++i) {
    if (text[i] == openChar) {
      depth++;
    } else if (text[i] == closeChar) {
      depth--;
      if (depth == 0) {
        return i;
      }
    }
  }

  return std::string::npos;
}

const std::vector<AnimatedSprite::Frame>& AnimatedSprite::activeFrames() const {
  static const std::vector<Frame> empty;
  auto stateIt = animations_.find(state_);
  if (stateIt == animations_.end()) {
    return empty;
  }
  if (direction_ < 0 || direction_ > 7) {
    return empty;
  }
  return stateIt->second[direction_];
}

void AnimatedSprite::normalizeStateDirection(std::string& state, int& direction) const {
  state = toTitleCase(state);
  direction = std::max(0, std::min(7, direction));
}

}  // namespace war30k

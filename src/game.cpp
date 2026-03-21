#include "game.hpp"

#include <SDL2/SDL.h>

#include <algorithm>
#include <cmath>
#include <iostream>
#include <random>
#include <string>
#include <vector>

#include "animated_sprite.hpp"
#include "core_types.hpp"
#include "font.hpp"
#include "render.hpp"
#include "world.hpp"

namespace war30k {

namespace {

int toDirectionIndex(Vec2 v, int fallback = 4) {
  if (std::fabs(v.x) < 0.001f && std::fabs(v.y) < 0.001f) {
    return fallback;
  }

  const float deg = std::atan2(v.y, v.x) * (180.0f / 3.14159265f);

  if (deg >= -112.5f && deg < -67.5f) {
    return 0;
  }
  if (deg >= -67.5f && deg < -22.5f) {
    return 1;
  }
  if (deg >= -22.5f && deg < 22.5f) {
    return 2;
  }
  if (deg >= 22.5f && deg < 67.5f) {
    return 3;
  }
  if (deg >= 67.5f && deg < 112.5f) {
    return 4;
  }
  if (deg >= 112.5f && deg < 157.5f) {
    return 5;
  }
  if (deg >= 157.5f || deg < -157.5f) {
    return 6;
  }
  return 7;
}

}  // namespace

int Game::run() {
  if (SDL_Init(SDL_INIT_VIDEO | SDL_INIT_GAMECONTROLLER) != 0) {
    std::cerr << "SDL INIT FAILED: " << SDL_GetError() << '\n';
    return 1;
  }

  SDL_Window* window = SDL_CreateWindow("WAR30K ADVENTURE - GARRO'S FLIGHT",
                                        SDL_WINDOWPOS_CENTERED,
                                        SDL_WINDOWPOS_CENTERED,
                                        WINDOW_WIDTH,
                                        WINDOW_HEIGHT,
                                        SDL_WINDOW_SHOWN);
  if (!window) {
    std::cerr << "WINDOW FAILED: " << SDL_GetError() << '\n';
    SDL_Quit();
    return 1;
  }

  SDL_Renderer* renderer = SDL_CreateRenderer(window,
                                              -1,
                                              SDL_RENDERER_ACCELERATED |
                                                  SDL_RENDERER_PRESENTVSYNC);
  if (!renderer) {
    std::cerr << "RENDERER FAILED: " << SDL_GetError() << '\n';
    SDL_DestroyWindow(window);
    SDL_Quit();
    return 1;
  }

  SDL_GameController* controller = nullptr;
  for (int i = 0; i < SDL_NumJoysticks(); ++i) {
    if (SDL_IsGameController(i)) {
      controller = SDL_GameControllerOpen(i);
      if (controller) {
        break;
      }
    }
  }

  const FontMap font = buildFont();
  const std::vector<Stage> stages = buildStages();
  std::mt19937 rng(std::random_device{}());

  AnimatedSprite garroSprite(renderer, "assets/garro_sheet.bmp", "assets/garro_frames.json");
  const bool garroSpriteReady = garroSprite.isValid();

  Vec2 player{120.0f, WINDOW_HEIGHT * 0.5f};
  Vec2 facingVec{1.0f, 0.0f};
  Facing facingDir = Facing::Right;
  float playerHealth = 100.0f;
  float enemyDamageTimer = 0.0f;
  float attackTimer = 0.0f;
  float swingTimer = 0.0f;
  float animTimer = 0.0f;

  int stageIndex = 0;
  int messageLine = 0;
  int progressCount = 0;

  bool running = true;
  bool attackPressed = false;
  bool interactPressed = false;

  PlayPhase phase = PlayPhase::Briefing;

  SDL_Rect targetZone{WINDOW_WIDTH - 140, WINDOW_HEIGHT / 2 - 70, 96, 128};
  std::vector<Enemy> enemies;
  std::vector<AnimatedSprite> enemySprites;
  std::vector<Beacon> beacons;
  std::vector<Projectile> enemyShots;
  std::vector<std::string> stageMap;
  bool enemySpritesReady = true;

  auto resetRun = [&]() {
    stageIndex = 0;
    playerHealth = 100.0f;
    phase = PlayPhase::Briefing;
    messageLine = 0;
  };

  auto setupStage = [&](int idx) {
    const Stage& stage = stages[idx];
    messageLine = 0;
    progressCount = 0;
    phase = PlayPhase::Briefing;

    stageMap = buildStageMap(idx);

    player = {96.0f, (MAP_HEIGHT / 2.0f) * TILE_SIZE};
    facingVec = {1.0f, 0.0f};
    facingDir = Facing::Right;
    targetZone = {WINDOW_WIDTH - 136, WINDOW_HEIGHT / 2 - 64, 96, 128};

    enemies.clear();
    enemySprites.clear();
    beacons.clear();
    enemyShots.clear();

    enemies.reserve(stage.enemyCount);
    enemySprites.reserve(stage.enemyCount);
    enemyShots.reserve(stage.enemyCount * 2);
    enemySpritesReady = true;

    for (int i = 0; i < stage.enemyCount; ++i) {
      Vec2 spawn = randomFreePosition(rng, stageMap, player, 180.0f);
      Enemy enemy;
      enemy.pos = spawn;
      enemy.speed = stage.enemySpeed;
      enemy.shootTimer = (static_cast<float>(i % 7) / 7.0f) * PROJECTILE_COOLDOWN;
      enemy.alive = true;
      enemies.push_back(enemy);

      enemySprites.emplace_back(renderer, "assets/traitor_sheet.bmp", "assets/traitor_frames.json");
      if (!enemySprites.back().isValid()) {
        enemySpritesReady = false;
      }
    }

    if (stage.objectiveType == ObjectiveType::ActivateBeacons) {
      beacons.push_back({{(7.5f) * TILE_SIZE, (4.5f) * TILE_SIZE}, false});
      beacons.push_back({{(20.5f) * TILE_SIZE, (11.5f) * TILE_SIZE}, false});
      beacons.push_back({{(33.5f) * TILE_SIZE, (17.5f) * TILE_SIZE}, false});
    }
  };

  setupStage(stageIndex);

  uint64_t prevTicks = SDL_GetPerformanceCounter();
  const double freq = static_cast<double>(SDL_GetPerformanceFrequency());

  while (running) {
    attackPressed = false;
    interactPressed = false;

    SDL_Event event;
    while (SDL_PollEvent(&event)) {
      if (event.type == SDL_QUIT) {
        running = false;
      }
      if (event.type == SDL_KEYDOWN) {
        if (event.key.keysym.sym == SDLK_ESCAPE) {
          running = false;
        }
        if (event.key.keysym.sym == SDLK_SPACE || event.key.keysym.sym == SDLK_j) {
          attackPressed = true;
        }
        if (event.key.keysym.sym == SDLK_e || event.key.keysym.sym == SDLK_RETURN) {
          interactPressed = true;
        }
        if ((phase == PlayPhase::GameOver || phase == PlayPhase::Victory) && event.key.keysym.sym == SDLK_r) {
          resetRun();
          setupStage(stageIndex);
        }
      }

      if (event.type == SDL_CONTROLLERBUTTONDOWN) {
        if (event.cbutton.button == SDL_CONTROLLER_BUTTON_A) {
          attackPressed = true;
        }
        if (event.cbutton.button == SDL_CONTROLLER_BUTTON_X ||
            event.cbutton.button == SDL_CONTROLLER_BUTTON_B) {
          interactPressed = true;
        }
      }
    }

    uint64_t nowTicks = SDL_GetPerformanceCounter();
    float dt = static_cast<float>((nowTicks - prevTicks) / freq);
    prevTicks = nowTicks;
    dt = clamp(dt, 0.0f, 0.05f);

    animTimer += dt;
    bool walkFrame = (static_cast<int>(animTimer * 8.0f) % 2) == 0;

    if (enemyDamageTimer > 0.0f) {
      enemyDamageTimer -= dt;
    }
    if (attackTimer > 0.0f) {
      attackTimer -= dt;
    }
    if (swingTimer > 0.0f) {
      swingTimer -= dt;
    }

    if (phase != PlayPhase::GameOver && phase != PlayPhase::Victory) {
      const Stage& stage = stages[stageIndex];

      if (phase == PlayPhase::Briefing) {
        if (interactPressed) {
          messageLine++;
          if (messageLine >= static_cast<int>(stage.briefing.size())) {
            phase = PlayPhase::Gameplay;
            messageLine = 0;
          }
        }
      } else if (phase == PlayPhase::Outro) {
        if (interactPressed) {
          messageLine++;
          if (messageLine >= static_cast<int>(stage.outro.size())) {
            stageIndex++;
            if (stageIndex >= static_cast<int>(stages.size())) {
              phase = PlayPhase::Victory;
            } else {
              setupStage(stageIndex);
            }
          }
        }
      } else {
        const uint8_t* keyboard = SDL_GetKeyboardState(nullptr);
        Vec2 input;
        bool playerMoving = false;

        if (keyboard[SDL_SCANCODE_W] || keyboard[SDL_SCANCODE_UP]) {
          input.y -= 1.0f;
        }
        if (keyboard[SDL_SCANCODE_S] || keyboard[SDL_SCANCODE_DOWN]) {
          input.y += 1.0f;
        }
        if (keyboard[SDL_SCANCODE_A] || keyboard[SDL_SCANCODE_LEFT]) {
          input.x -= 1.0f;
        }
        if (keyboard[SDL_SCANCODE_D] || keyboard[SDL_SCANCODE_RIGHT]) {
          input.x += 1.0f;
        }

        if (controller) {
          const float axisX = SDL_GameControllerGetAxis(controller, SDL_CONTROLLER_AXIS_LEFTX) / 32767.0f;
          const float axisY = SDL_GameControllerGetAxis(controller, SDL_CONTROLLER_AXIS_LEFTY) / 32767.0f;
          if (std::fabs(axisX) > 0.18f) {
            input.x += axisX;
          }
          if (std::fabs(axisY) > 0.18f) {
            input.y += axisY;
          }
          if (SDL_GameControllerGetAxis(controller, SDL_CONTROLLER_AXIS_TRIGGERRIGHT) > 10000) {
            attackPressed = true;
          }
        }

        input = normalize(input);
        playerMoving = length(input) > 0.01f;
        if (length(input) > 0.0f) {
          facingVec = input;
          facingDir = facingFromVector(input, facingDir);
        }

        const int playerDirIndex = toDirectionIndex(facingVec, 2);
        if (garroSpriteReady) {
          garroSprite.setAnimation(playerMoving ? "Walk" : "Idle", playerDirIndex);
          garroSprite.update(dt);
        }

        moveWithCollision(stageMap,
                          player,
                          {input.x * PLAYER_SPEED * dt, input.y * PLAYER_SPEED * dt},
                          ENTITY_RADIUS);

        if (attackPressed && attackTimer <= 0.0f) {
          attackTimer = ATTACK_COOLDOWN;
          swingTimer = ATTACK_ARC_TIME;
          for (auto& enemy : enemies) {
            if (!enemy.alive) {
              continue;
            }
            const Vec2 toEnemy{enemy.pos.x - player.x, enemy.pos.y - player.y};
            const float d2 = toEnemy.x * toEnemy.x + toEnemy.y * toEnemy.y;
            if (d2 > ATTACK_RANGE * ATTACK_RANGE) {
              continue;
            }
            const Vec2 dirToEnemy = normalize(toEnemy);
            const float dot = dirToEnemy.x * facingVec.x + dirToEnemy.y * facingVec.y;
            if (dot > 0.2f) {
              enemy.alive = false;
              progressCount++;
            }
          }
        }

        for (std::size_t i = 0; i < enemies.size(); ++i) {
          auto& enemy = enemies[i];
          if (!enemy.alive) {
            continue;
          }

          const Vec2 beforeMove = enemy.pos;
          Vec2 chase{player.x - enemy.pos.x, player.y - enemy.pos.y};
          chase = normalize(chase);
          moveWithCollision(stageMap,
                            enemy.pos,
                            {chase.x * enemy.speed * dt, chase.y * enemy.speed * dt},
                            ENTITY_RADIUS);

          if (enemySpritesReady && i < enemySprites.size()) {
            const bool enemyMoving = distanceSquared(beforeMove, enemy.pos) > 0.2f;
            const int enemyDirIndex = toDirectionIndex(chase, 4);
            enemySprites[i].setAnimation(enemyMoving ? "Walk" : "Idle", enemyDirIndex);
            enemySprites[i].update(dt);
          }

          enemy.shootTimer -= dt;
          if (enemy.shootTimer <= 0.0f && distanceSquared(enemy.pos, player) < 320.0f * 320.0f) {
            Vec2 dir = normalize({player.x - enemy.pos.x, player.y - enemy.pos.y});
            Projectile shot;
            shot.pos = enemy.pos;
            shot.vel = {dir.x * PROJECTILE_SPEED, dir.y * PROJECTILE_SPEED};
            shot.alive = true;
            enemyShots.push_back(shot);
            enemy.shootTimer = PROJECTILE_COOLDOWN;
          }

          if (distanceSquared(enemy.pos, player) < 24.0f * 24.0f && enemyDamageTimer <= 0.0f) {
            playerHealth -= ENEMY_TOUCH_DAMAGE;
            enemyDamageTimer = ENEMY_DAMAGE_COOLDOWN;
            if (playerHealth <= 0.0f) {
              phase = PlayPhase::GameOver;
            }
          }
        }

        for (auto& shot : enemyShots) {
          if (!shot.alive) {
            continue;
          }

          moveWithCollision(stageMap,
                            shot.pos,
                            {shot.vel.x * dt, shot.vel.y * dt},
                            4.0f);

          if (collidesMap(stageMap, shot.pos, 4.0f)) {
            shot.alive = false;
            continue;
          }

          if (distanceSquared(shot.pos, player) < 16.0f * 16.0f && enemyDamageTimer <= 0.0f) {
            playerHealth -= ENEMY_TOUCH_DAMAGE * 0.6f;
            enemyDamageTimer = ENEMY_DAMAGE_COOLDOWN * 0.75f;
            shot.alive = false;
            if (playerHealth <= 0.0f) {
              phase = PlayPhase::GameOver;
            }
          }
        }

        enemyShots.erase(
            std::remove_if(enemyShots.begin(), enemyShots.end(), [](const Projectile& p) { return !p.alive; }),
            enemyShots.end());

        if (stage.objectiveType == ObjectiveType::ReachZone) {
          SDL_Rect playerRect{static_cast<int>(player.x - 10), static_cast<int>(player.y - 10), 20, 20};
          if (SDL_HasIntersection(&playerRect, &targetZone)) {
            progressCount = stage.objectiveCount;
          }
        } else if (stage.objectiveType == ObjectiveType::ActivateBeacons && interactPressed) {
          for (auto& beacon : beacons) {
            if (beacon.used) {
              continue;
            }
            if (distanceSquared(beacon.pos, player) < 44.0f * 44.0f) {
              beacon.used = true;
              progressCount++;
              break;
            }
          }
        }

        if (progressCount >= stage.objectiveCount) {
          phase = PlayPhase::Outro;
          messageLine = 0;
          enemyShots.clear();
        }
      }
    } else if (garroSpriteReady) {
      garroSprite.setAnimation("Idle", toDirectionIndex(facingVec, 2));
      garroSprite.update(dt);
    }

    const Stage& currentStage = stages[stageIndex < static_cast<int>(stages.size()) ? stageIndex : stages.size() - 1];

    SDL_SetRenderDrawColor(renderer, currentStage.bg.r, currentStage.bg.g, currentStage.bg.b, 255);
    SDL_RenderClear(renderer);

    drawTileMap(renderer, currentStage, stageMap);

    if (phase != PlayPhase::Victory && phase != PlayPhase::GameOver) {
      if (currentStage.objectiveType == ObjectiveType::ReachZone) {
        SDL_SetRenderDrawColor(renderer, 188, 208, 92, 255);
        SDL_RenderFillRect(renderer, &targetZone);

        SDL_SetRenderDrawColor(renderer, 228, 240, 140, 255);
        SDL_Rect inner{targetZone.x + 8, targetZone.y + 8, targetZone.w - 16, targetZone.h - 16};
        SDL_RenderDrawRect(renderer, &inner);
      }

      float pulse = 0.5f + 0.5f * std::sin(animTimer * 3.6f);
      for (const auto& beacon : beacons) {
        drawBeacon(renderer, beacon.pos, beacon.used, pulse);
      }

      for (std::size_t i = 0; i < enemies.size(); ++i) {
        const auto& enemy = enemies[i];
        if (!enemy.alive) {
          continue;
        }

        if (enemySpritesReady && i < enemySprites.size() && enemySprites[i].isValid()) {
          enemySprites[i].draw(renderer,
                               static_cast<int>(enemy.pos.x) - 24,
                               static_cast<int>(enemy.pos.y) - 24,
                               1.5f);
        } else {
          drawTraitor(renderer, enemy.pos, walkFrame);
        }
      }

      SDL_SetRenderDrawColor(renderer, 230, 90, 90, 255);
      for (const auto& shot : enemyShots) {
        SDL_Rect r{static_cast<int>(shot.pos.x) - 3, static_cast<int>(shot.pos.y) - 3, 6, 6};
        SDL_RenderFillRect(renderer, &r);
      }

      if (garroSpriteReady) {
        garroSprite.draw(renderer,
                         static_cast<int>(player.x) - 24,
                         static_cast<int>(player.y) - 24,
                         1.5f);
      } else {
        drawGarro(renderer, player, facingDir, walkFrame);
      }

      if (swingTimer > 0.0f) {
        SDL_SetRenderDrawColor(renderer, 255, 235, 120, 210);
        SDL_Rect swing{static_cast<int>(player.x + facingVec.x * 28.0f) - 20,
                       static_cast<int>(player.y + facingVec.y * 28.0f) - 20,
                       40,
                       40};
        SDL_RenderFillRect(renderer, &swing);
      }

      drawMiniMap(renderer, stageMap, player, enemies, beacons, targetZone);
    }

    SDL_Color uiColor{240, 240, 240, 255};
    drawText(renderer, font, currentStage.name, 20, 20, 3, uiColor);

    if (phase != PlayPhase::Victory && phase != PlayPhase::GameOver) {
      std::string hp = "HP " + std::to_string(static_cast<int>(std::max(0.0f, playerHealth)));
      drawText(renderer, font, hp, 20, 60, 3, uiColor);

      std::string objective = currentStage.objectiveLabel + " " + std::to_string(progressCount) +
                              "/" + std::to_string(currentStage.objectiveCount);
      drawText(renderer, font, objective, 20, 95, 2, uiColor);
    }

    if (phase == PlayPhase::Briefing || phase == PlayPhase::Outro) {
      SDL_Rect panel{80, WINDOW_HEIGHT - 220, WINDOW_WIDTH - 160, 160};
      SDL_SetRenderDrawColor(renderer, 10, 10, 10, 225);
      SDL_RenderFillRect(renderer, &panel);
      SDL_SetRenderDrawColor(renderer, 180, 180, 180, 255);
      SDL_RenderDrawRect(renderer, &panel);

      const auto& lines = (phase == PlayPhase::Briefing) ? currentStage.briefing : currentStage.outro;
      if (!lines.empty()) {
        int lineIdx = std::min(messageLine, static_cast<int>(lines.size()) - 1);
        drawText(renderer, font, lines[lineIdx], panel.x + 20, panel.y + 28, 2, uiColor);
      }

      drawText(renderer, font, "PRESS E ENTER OR X TO CONTINUE", panel.x + 20, panel.y + 108, 2, uiColor);
    }

    if (phase == PlayPhase::GameOver) {
      SDL_Rect panel{220, 260, WINDOW_WIDTH - 440, 180};
      SDL_SetRenderDrawColor(renderer, 10, 0, 0, 230);
      SDL_RenderFillRect(renderer, &panel);
      SDL_SetRenderDrawColor(renderer, 210, 90, 90, 255);
      SDL_RenderDrawRect(renderer, &panel);
      drawText(renderer, font, "MISSION FAILED", panel.x + 130, panel.y + 46, 3, {255, 220, 220, 255});
      drawText(renderer, font, "PRESS R TO RESTART", panel.x + 130, panel.y + 102, 2, {255, 220, 220, 255});
    }

    if (phase == PlayPhase::Victory) {
      SDL_Rect panel{150, 230, WINDOW_WIDTH - 300, 240};
      SDL_SetRenderDrawColor(renderer, 18, 18, 8, 238);
      SDL_RenderFillRect(renderer, &panel);
      SDL_SetRenderDrawColor(renderer, 210, 190, 120, 255);
      SDL_RenderDrawRect(renderer, &panel);
      drawText(renderer, font, "TERRA WARNED", panel.x + 190, panel.y + 40, 4, {255, 245, 185, 255});
      drawText(renderer,
               font,
               "GARRO DELIVERS THE TRUTH OF HORUS'S TREACHERY.",
               panel.x + 60,
               panel.y + 122,
               2,
               {255, 245, 185, 255});
      drawText(renderer, font, "PRESS R TO PLAY AGAIN", panel.x + 170, panel.y + 176, 2, {255, 245, 185, 255});
    }

    SDL_RenderPresent(renderer);
  }

  if (controller) {
    SDL_GameControllerClose(controller);
  }
  SDL_DestroyRenderer(renderer);
  SDL_DestroyWindow(window);
  SDL_Quit();

  return 0;
}

}  // namespace war30k

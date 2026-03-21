#include "world.hpp"

#include <cmath>

namespace war30k {

std::vector<Stage> buildStages() {
  return {
      {
          "ISTVAAN V - BROKEN LOYALTY",
          {
              "NATHANIEL GARRO STANDS ALONE IN THE SMOKE OF BETRAYAL.",
              "TRAITOR LEGIONS CLOSE FROM ALL SIDES.",
              "REACH THE EXFILTRATION BEACON AND SURVIVE.",
          },
          {
              "GARRO BREAKS THE KILL ZONE AND BOARDS A DAMAGED FRIGATE.",
          },
          {38, 26, 24, 255},
          {160, 64, 64, 255},
          {52, 34, 30, 255},
          {93, 48, 44, 255},
          {138, 76, 60, 255},
          ObjectiveType::ReachZone,
          1,
          "REACH EXTRACTION",
          12,
          86.0f,
      },
      {
          "WARP CROSSING - THE EISENSTEIN",
          {
              "THE WARP HOWLS AROUND THE EISENSTEIN.",
              "CALM THE SHIP'S FAILING WARD-RELICS.",
              "ACTIVATE ALL BEACONS TO HOLD THE GELLER FIELD.",
          },
          {
              "THE SHIP STABILIZES. TERRA IS STILL WITHIN REACH.",
          },
          {20, 20, 45, 255},
          {110, 110, 210, 255},
          {26, 28, 58, 255},
          {52, 54, 98, 255},
          {100, 96, 165, 255},
          ObjectiveType::ActivateBeacons,
          3,
          "ACTIVATE WARDS",
          10,
          95.0f,
      },
      {
          "LUNA APPROACH - BLOCKADE RUN",
          {
              "TRAITOR PICKETS GUARD THE WAY TO TERRA.",
              "CUT THROUGH BOARDING PARTIES TO OPEN A CORRIDOR.",
              "PURGE HOSTILES TO FORCE A PASSAGE.",
          },
          {
              "THE TRAITOR SCREEN BREAKS. THE THRONEWORLD IS IN SIGHT.",
          },
          {24, 24, 30, 255},
          {210, 145, 65, 255},
          {36, 36, 43, 255},
          {76, 76, 85, 255},
          {156, 108, 58, 255},
          ObjectiveType::Purge,
          14,
          "PURGE TRAITORS",
          20,
          108.0f,
      },
      {
          "TERRA - THE WARNING",
          {
              "GARRO REACHES THE PALACE APPROACHES.",
              "CUSTODES HOLD THE GATES IN SUSPICION.",
              "REACH THE RELAY AND SEND THE WARNING TO THE EMPEROR.",
          },
          {
              "THE WARNING IS SENT. THE HERESY CAN NO LONGER BE HIDDEN.",
          },
          {40, 35, 18, 255},
          {190, 170, 85, 255},
          {54, 48, 28, 255},
          {118, 102, 58, 255},
          {178, 154, 84, 255},
          ObjectiveType::ReachZone,
          1,
          "REACH RELAY",
          16,
          115.0f,
      },
  };
}

std::vector<std::string> buildStageMap(int stageIndex) {
  std::vector<std::string> map(MAP_HEIGHT, std::string(MAP_WIDTH, '.'));

  for (int y = 0; y < MAP_HEIGHT; ++y) {
    for (int x = 0; x < MAP_WIDTH; ++x) {
      if (x == 0 || y == 0 || x == MAP_WIDTH - 1 || y == MAP_HEIGHT - 1) {
        map[y][x] = '#';
      }
    }
  }

  if (stageIndex == 0) {
    for (int y = 2; y < MAP_HEIGHT - 2; ++y) {
      if (y == MAP_HEIGHT / 2 || y == MAP_HEIGHT / 2 - 1 || y == MAP_HEIGHT / 2 + 1) {
        continue;
      }
      map[y][9] = '#';
      map[y][20] = '#';
    }
    for (int x = 11; x < MAP_WIDTH - 3; ++x) {
      if (x > 17 && x < 23) {
        continue;
      }
      map[6][x] = '#';
      map[15][x] = '#';
    }
  } else if (stageIndex == 1) {
    for (int x = 3; x < MAP_WIDTH - 3; ++x) {
      if (x == 10 || x == 20 || x == 30) {
        continue;
      }
      map[5][x] = '#';
      map[11][x] = '#';
      map[17][x] = '#';
    }
    for (int y = 3; y < MAP_HEIGHT - 3; ++y) {
      if (y == 8 || y == 14) {
        continue;
      }
      map[y][14] = '#';
      map[y][26] = '#';
    }
  } else if (stageIndex == 2) {
    for (int y = 3; y < MAP_HEIGHT - 3; ++y) {
      map[y][12] = '#';
      map[y][13] = '#';
      map[y][25] = '#';
      map[y][26] = '#';
    }
    for (int x = 4; x < MAP_WIDTH - 4; ++x) {
      if (x > 16 && x < 22) {
        continue;
      }
      map[8][x] = '#';
      map[14][x] = '#';
    }
    for (int y = 9; y <= 13; ++y) {
      map[y][19] = '.';
      map[y][20] = '.';
      map[y][21] = '.';
    }
  } else {
    for (int x = 4; x < MAP_WIDTH - 4; ++x) {
      map[6][x] = '#';
      map[16][x] = '#';
    }
    for (int y = 3; y < MAP_HEIGHT - 3; ++y) {
      map[y][8] = '#';
      map[y][31] = '#';
    }
    for (int x = 17; x <= 22; ++x) {
      map[6][x] = '.';
      map[16][x] = '.';
    }
    for (int y = 9; y <= 13; ++y) {
      map[y][8] = '.';
      map[y][31] = '.';
    }
  }

  for (int y = 1; y < MAP_HEIGHT - 1; ++y) {
    for (int x = 1; x < MAP_WIDTH - 1; ++x) {
      if (map[y][x] == '.' && ((x * 31 + y * 17 + stageIndex * 13) % 23 == 0)) {
        map[y][x] = '+';
      }
    }
  }

  return map;
}

bool isBlockedTile(const std::vector<std::string>& map, int tx, int ty) {
  if (tx < 0 || ty < 0 || tx >= MAP_WIDTH || ty >= MAP_HEIGHT) {
    return true;
  }
  return map[ty][tx] == '#';
}

bool collidesMap(const std::vector<std::string>& map, Vec2 pos, float radius) {
  int minTileX = static_cast<int>(std::floor((pos.x - radius) / TILE_SIZE));
  int maxTileX = static_cast<int>(std::floor((pos.x + radius) / TILE_SIZE));
  int minTileY = static_cast<int>(std::floor((pos.y - radius) / TILE_SIZE));
  int maxTileY = static_cast<int>(std::floor((pos.y + radius) / TILE_SIZE));

  for (int y = minTileY; y <= maxTileY; ++y) {
    for (int x = minTileX; x <= maxTileX; ++x) {
      if (isBlockedTile(map, x, y)) {
        return true;
      }
    }
  }
  return false;
}

void moveWithCollision(const std::vector<std::string>& map, Vec2& pos, Vec2 delta, float radius) {
  Vec2 tryX{pos.x + delta.x, pos.y};
  if (!collidesMap(map, tryX, radius)) {
    pos.x = tryX.x;
  }

  Vec2 tryY{pos.x, pos.y + delta.y};
  if (!collidesMap(map, tryY, radius)) {
    pos.y = tryY.y;
  }
}

Vec2 randomFreePosition(std::mt19937& rng, const std::vector<std::string>& map, Vec2 avoid, float avoidDist) {
  std::uniform_int_distribution<int> tx(1, MAP_WIDTH - 2);
  std::uniform_int_distribution<int> ty(1, MAP_HEIGHT - 2);

  for (int i = 0; i < 2000; ++i) {
    int x = tx(rng);
    int y = ty(rng);
    if (map[y][x] == '#') {
      continue;
    }
    Vec2 pos{(x + 0.5f) * TILE_SIZE, (y + 0.5f) * TILE_SIZE};
    if (distanceSquared(pos, avoid) < avoidDist * avoidDist) {
      continue;
    }
    return pos;
  }

  return {(MAP_WIDTH / 2.0f) * TILE_SIZE, (MAP_HEIGHT / 2.0f) * TILE_SIZE};
}

}  // namespace war30k

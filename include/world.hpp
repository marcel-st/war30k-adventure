#pragma once

#include <random>
#include <string>
#include <vector>

#include "core_types.hpp"

namespace war30k {

std::vector<Stage> buildStages();
std::vector<std::string> buildStageMap(int stageIndex);

bool isBlockedTile(const std::vector<std::string>& map, int tx, int ty);
bool collidesMap(const std::vector<std::string>& map, Vec2 pos, float radius);
void moveWithCollision(const std::vector<std::string>& map, Vec2& pos, Vec2 delta, float radius);
Vec2 randomFreePosition(std::mt19937& rng, const std::vector<std::string>& map, Vec2 avoid, float avoidDist);

}  // namespace war30k

// I started a C++ implementation that still wasn't fast enough, then after solving via Z3
// (see 10c.rb) I came across this reddit post describing a clever recursive algorithm that 
// implements part 2 in terms of part 1. I decided to adapt this code to use that algorithm
// https://www.reddit.com/r/adventofcode/comments/1pk87hl/2025_day_10_part_2_bifurcate_your_way_to_victory/

#include <iostream>
#include <vector>
#include <string>
#include <sstream>
#include <bit>
#include <ranges>
#include <map>
#include <unordered_map>

using namespace std;

class Machine {
  int light_count, light_mask = 0;
  vector<int> target;
  vector<int> buttons;
  unordered_map<int, vector<unsigned int>> parity_cache;
  map<vector<int>, int> target_cache;

public:
  explicit Machine(const string &line) {
    istringstream ss(line);
    string token;
    while (ss >> token) {
      if (token.size() < 3) {
        throw "bad token";
      }
      bool is_button = token[0] == '(';
      bool is_target = token[0] == '{';
      if (is_button || is_target) {
        istringstream interior(token.substr(1, token.size() - 2));
        string num_str;
        int b = 0;
        while(getline(interior, num_str, ',')) {
          int n = stoi(num_str);
          if (is_button) {
            b |= (1 << n);
          } else {
            target.push_back(n);
          }
        }
        if (is_button) {
          buttons.push_back(b);
        }
      } else {
        string interior(token.substr(1, token.size() - 2));
        light_count = interior.size();
        for(int i = 0; i < light_count; ++i) {
          if (interior[i] == '#')
            light_mask |= (1 << i);
        }
      }
    }
  }

  int solve_lights() {
    auto combos = solve_lights(light_mask);
    auto it = ranges::min_element(combos, {}, [](auto x) { return popcount(x); });
    return popcount(*it);
  }

  int solve_jolts() {
    return solve_jolts(target);
  }

private:
  vector<unsigned int> solve_lights(int target) {
    if (auto it = parity_cache.find(target); it != parity_cache.end())
      return it->second;

    vector<unsigned int> combos;
    unsigned int iters = 1 << buttons.size();
    for(unsigned int i = 0; i < iters; ++i) {
      int scratch = 0;
      for(int b = 0; b < buttons.size(); ++b) {
        if (i & (1 << b))
          scratch ^= buttons[b];
      }
      if (scratch == target) {
        combos.push_back(i);
      }
    }
    parity_cache[target] = combos;
    return combos;
  }

  int solve_jolts(const vector<int> &target) {
    if (*max_element(target.begin(), target.end()) == 0) {
      return 0;
    }
    if (auto it = target_cache.find(target); it != target_cache.end()) {
      return it->second;
    }

    int parity = 0;
    for(int i = 0; i < target.size(); ++i) {
      parity |= (target[i] & 1) << i;
    }
    auto combos = solve_lights(parity);

    vector<int> subtarget(target.size());
    int best = numeric_limits<int>::max();
    for(auto combo : combos) {
      copy(target.begin(), target.end(), subtarget.begin());
      for(int i = 0; i < buttons.size(); ++i) {
        if ((1 << i) & combo) {
          int b = buttons[i], j = 0;
          while (b) {
            if (b & 1)
              --subtarget[j];
            b >>= 1;
            ++j;
          }
        }
      }
      
      if (*min_element(subtarget.begin(), subtarget.end()) < 0)
        continue;

      for(int &i : subtarget) {
        if (i & 1) throw "parity error";
        i >>= 1;
      }
      int subscore = solve_jolts(subtarget);
      if (subscore == numeric_limits<int>::max())
        continue;

      int score = popcount(combo) + 2 * subscore;
      if (score < best)
        best = score;
    }

    target_cache[target] = best;
    return best;
  }
};

int main(int argc, char **argv)
{
  vector<Machine> machines;
  string line;
  while (getline(cin, line)) {
    machines.emplace_back(line);
  }

  // part 1
  int total = 0;
  for(auto &m : machines) {
    total += m.solve_lights();
  }
  cout << total << endl;

  // part 2
  total = 0;
  for(auto &m : machines) {
    total += m.solve_jolts();
  }
  cout << total << endl;
}
// I started a C++ implementation that still wasn't fast enough, then after solving via Z3
// (see 10c.rb) I came across this reddit post describing a clever recursive algorithm that 
// implements part 2 in terms of part 1. I decided to adapt this code to use that algorithm
// https://www.reddit.com/r/adventofcode/comments/1pk87hl/2025_day_10_part_2_bifurcate_your_way_to_victory/

#include <iostream>
#include <vector>
#include <string>
#include <sstream>
#include <bit>
#include <map>

using namespace std;

class Machine {
  int light_count, light_mask = 0;
  vector<int> target;
  vector<int> buttons;
  
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
    vector<unsigned long> scratch;
    return solve_lights(light_mask, scratch);
  }

  int solve_jolts() {
    map<vector<int>, int> memo;
    return solve_jolts(target, memo);
  }

private:
  int solve_lights(int target, vector<unsigned long> &combos) {
    int best = numeric_limits<int>::max();
    unsigned long iters = 1 << buttons.size();
    for(unsigned long i = 0; i < iters; ++i) {
      int scratch = 0;
      for(int b = 0; b < buttons.size(); ++b) {
        if (i & (1 << b))
          scratch ^= buttons[b];
      }
      if (scratch == target) {
        int n = popcount(i);
        if (n < best)
          best = n;
        combos.push_back(i);
      }
    }
    return best;
  }

  int solve_jolts(const vector<int> &target, map<vector<int>, int> &memo) {
    if (*max_element(target.begin(), target.end()) == 0) {
      return 0;
    }
    if (auto it = memo.find(target); it != memo.end()) {
      return it->second;
    }

    int parity = 0;
    for(int i = 0; i < target.size(); ++i) {
      parity |= (target[i] & 1) << i;
    }
    vector<unsigned long> combos;
    solve_lights(parity, combos);

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
      int subscore = solve_jolts(subtarget, memo);
      if (subscore == numeric_limits<int>::max())
        continue;

      int score = popcount(combo) + 2 * subscore;
      if (score < best)
        best = score;
    }

    memo[target] = best;
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
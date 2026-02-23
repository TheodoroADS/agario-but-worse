import raylib;
import normal_distribution;
import std::math::random;
import std::collections::list;
import std::core::mem;

const uint INIT_WIDTH = 900;
const uint INIT_HEIGHT = 900;
const uint WALL_THICK = 90;

const uint WORLD_SIZE = 1200;
const uint WORLD_WIDTH = WORLD_SIZE;
const uint WORLD_HEIGTH = WORLD_SIZE;

const uint FONT_SIZE = 20;

uint width = INIT_WIDTH;
uint height = INIT_HEIGHT;
uint inner_width;
uint inner_height;

const raylib::Color BACKGROUND_COLOR = {120, 120, 120, 255};
const raylib::Color WALL_COLOR = {255, 255, 255, 255}; 

const uint NUM_ENEMIES = 2;

const float POINTS_TO_RADIUS_COEF = 0.01;
const float PLAYER_SPEED = 90f;
const float ENEMY_SPEED = 20f;

const int MIN_ACTIVE_FOOD = 30;
const int MAX_ACTIVE_FOOD = 60;

const float FOOD_RESPAWN_PROB = 0.003f;

const BALL_MAX_RADIUS = 500;

struct Ball {
    raylib::Vector2 center;
    float radius;
    float points;
    Color color;
    bool active;
}

struct Player {
    Ball ball;
    String name;
    bool alive;
}


const Color[] BALL_COLORS = {
    {255, 255, 255, 255}, // WHITE
    {255, 0, 0, 255}, // RED
    {0, 255, 0, 255}, // GREEN
    {0, 0, 255, 255}, // BLUE
};

fn Vector2 rel_to_abs(raylib::Vector2 vec) {
    return {vec[0] * width, vec[1] * height}; 
}


fn float points_to_radius(float points) {
    
    float radius = POINTS_TO_RADIUS_COEF * points;

    if (radius > BALL_MAX_RADIUS) {
        radius = BALL_MAX_RADIUS;
    }
    
    return radius;
}

fn raylib::Color random_color() {

    int rand_idx = raylib::get_random_value(0, BALL_COLORS.len - 1);
    return BALL_COLORS[rand_idx];
}

const uint BALL_SPAWN_WALL_PADDING = 20;

fn Ball make_random_ball() {

    // balls are uniformly spread accross the terrain
    float rand_x = (float) raylib::get_random_value(BALL_SPAWN_WALL_PADDING + WALL_THICK, WORLD_WIDTH - BALL_SPAWN_WALL_PADDING - WALL_THICK);
    float rand_y = (float) raylib::get_random_value(BALL_SPAWN_WALL_PADDING + WALL_THICK, WORLD_HEIGTH - BALL_SPAWN_WALL_PADDING - WALL_THICK);
    
    // but radius follows a normal distribution
    float rand_points = normal_distribution::sample_normal(600, 500);

    return  {
        .center = {rand_x, rand_y},
        .points = rand_points,
        .radius = points_to_radius(rand_points),
        .color = random_color(),
        .active = true
    };

}

fn void Ball.clip_position(Ball* self) {

    float edge_right = self.center[0] + self.radius;
    float edge_left  = self.center[0] - self.radius;
    float edge_up    = self.center[1] - self.radius;
    float edge_down  = self.center[1] + self.radius;

    if (edge_right > WORLD_WIDTH - WALL_THICK) {
        float corrected = WORLD_WIDTH - self.radius - WALL_THICK; 
        self.center[0] = corrected; 
    }

    if (edge_left < WALL_THICK) {
        float corrected = WALL_THICK + self.radius;
        self.center[0] = corrected;
    }
    
    if (edge_down > WORLD_HEIGTH - WALL_THICK) {
        float corrected = WORLD_HEIGTH - self.radius - WALL_THICK; 
        self.center[1] = corrected; 
    }

    if (edge_up < WALL_THICK) {
        float corrected = WALL_THICK + self.radius;
        self.center[1] = corrected;
    }
}

fn void Ball.update_radius(Ball* self) {
    self.radius = points_to_radius(self.points);
}

fn bool Ball.overlaps(Ball* self, Ball* other) {

    float dist_between_centers = (other.center - self.center).length();
    return dist_between_centers + other.radius < self.radius; 
}


fn void Ball.draw(Ball* self) {
    raylib::draw_circle_v({self.center[0], self.center[1]}, self.radius, self.color);
}

fn void Player.draw(Player* self) {
    
    int text_size  = raylib::measure_text(self.name, FONT_SIZE);

    uint pos_x = (uint) (self.ball.center[0]) - text_size;
    uint pos_y = (uint) (self.ball.center[1]) - text_size / 2;
    
    self.ball.draw();
    raylib::draw_text(self.name, pos_x, pos_y, 30, {255,255,255,255});
}

fn void Player.eat(Player* self, Ball* other) {
    self.ball.points += other.points;
    self.update_radius();
    other.active = false;
}

fn void Player.eat_player(Player* self, Player* other) {
    self.eat(&other.ball);
    other.alive = false;
}

fn void Player.update_radius(Player* self) {
    self.ball.update_radius();
}

fn void try_spawn_food(int* number_of_food) {

    for (int i = 0; i < all_food.len; i++) {
        
        if (!(all_food[i].active) || i >= *number_of_food) {
            all_food[i] = make_random_ball();
            if (i >= *number_of_food) {
                *number_of_food = i;
            }
            return;
        }
    }

}

fn float compute_camera_zoom(float zoom, float player_radius) {

    float player_diameter = player_radius * 2;
    float screen_width = WORLD_WIDTH / 2;

    // update zoom if the player already occupies half the screen
    if (player_diameter / screen_width > 0.4f) {
      // make the player occupy only a Xth of the screen
      float desired_screen_width = 2f * player_diameter;
      float new_zoom = WORLD_WIDTH / desired_screen_width;

      if (new_zoom > 1f) {
        new_zoom = 1f;
      }

      return new_zoom;
    }

    return zoom;
}

struct NameRecord {
  String name;
  bool picked;
}

NameRecord[] enemy_names = {
 {"Ernesto", false},
 {"Pablo", false},
 {"Jorge", false},
 {"Maurice", false},
 {"Jacquin", false},
 {"Mauricette", false},
 {"João", false},
 {"Denis", false},
 {"Penis", false},
 {"Eita", false},
};

fn String random_name() {
  
  uint idx = raylib::get_random_value(0, enemy_names.len - 1);
  
  int visited = 0;
  while (enemy_names[idx].picked) {
    if (idx <= enemy_names.len - 2) {
      idx += 1;
    }
    else {
      idx = 0;  
    }
    visited += 1;
  
    if (visited == enemy_names.len) {
      foreach (&record : enemy_names) {
        record.picked = false;
      }
      return enemy_names[0].name;
    }
  }

  enemy_names[idx].picked = true;
  return enemy_names[idx].name;

}

fn Player enemy_make() {
  return {
    .ball = make_random_ball(),
    .name = random_name(),
    .alive = true
  };
}

fn void Player.enemy_update(Player* enemy) {

  Vector2 where_to_go;
  float min_distance = (float) WORLD_SIZE;
  
  for (int i; i < number_of_food; i++) {

    Ball* food = &all_food[i];
    
    if (food.active && enemy.ball.points > food.points) {
      if (enemy.ball.overlaps(food)) {
        enemy.eat(food);
        food.active = false;
      } else {
        Vector2 way_there = {
            food.center[0] - enemy.ball.center[0],
            food.center[1] - enemy.ball.center[1]
        };
        float distance = way_there.length();
        if (distance < min_distance) {
          where_to_go = way_there;
          min_distance = distance;
        }
      }
    }
  }
  
  Vector2 pvp_where_to_go = {0f, 0f};
  foreach (&other_enemy : enemies) {
    if (other_enemy.alive) {
      if (
        enemy.ball.center.distance(other_enemy.ball.center) > 200
        && enemy.ball.points > other_enemy.ball.points
      ) pvp_where_to_go = {
            other_enemy.ball.center.x - enemy.ball.center.x,
            other_enemy.ball.center.y - enemy.ball.center.y
        };

      if (enemy.ball.overlaps(&other_enemy.ball)) {
        enemy.eat_player(other_enemy);
      }
    }
  }

  // move the player
  enemy.ball.center += (where_to_go + pvp_where_to_go).normalize() * ENEMY_SPEED * delta_time; 
  enemy.ball.clip_position();
}

/*
TODOS
- fix enemy movement
- add PVP
- display the points from the current player
- display leaderboard
*/

Ball[MAX_ACTIVE_FOOD] all_food;
Player[NUM_ENEMIES] enemies;
float delta_time;
int number_of_food;

fn void main() {

    raylib::init_window(width, height, "Agario but worse");
    number_of_food = raylib::get_random_value(MIN_ACTIVE_FOOD, MAX_ACTIVE_FOOD);  

    for (int i = 0; i <= number_of_food; i++) {
        Ball food = make_random_ball();
        all_food[i] = food;
    }

    Ball player_ball = {
        .center = {WORLD_WIDTH /2, WORLD_HEIGTH / 2},
        .radius = points_to_radius(2000),
        .points = 2000,
        .color = {0, 0, 0, 255},
        .active = true
    };

    raylib::Camera2D camera = {
        .target = {player_ball.center[0],player_ball.center[1]},
        .offset = {0,0}, // will update during game loop
        .rotation = 0.0f,
        .zoom = 2.0f 
    };

    Player player = {
        .name = "Teco",
        .ball = player_ball,
        .alive = true
    };
   
    // initialize enemies
    for (int i = 0; i < enemies.len; i++) {
      enemies[i] = enemy_make();
    } 

    raylib::set_target_fps(60);

    bool window_should_close = false;

    while (!window_should_close) {

        width = raylib::get_screen_width();
        height = raylib::get_screen_height();
        camera.offset[0] = (float) width / 2;
        camera.offset[1] = (float) height / 2;
        delta_time = raylib::get_frame_time();

        if (raylib::is_key_down(raylib::KEY_A) || raylib::is_key_down(raylib::KEY_LEFT)) {
            player.ball.center[0] -= PLAYER_SPEED*delta_time;
        }

        if (raylib::is_key_down(raylib::KEY_D) || raylib::is_key_down(raylib::KEY_RIGHT)) {
            player.ball.center[0] += PLAYER_SPEED*delta_time;
        }

        if (raylib::is_key_down(raylib::KEY_S) || raylib::is_key_down(raylib::KEY_DOWN)) {
            player.ball.center[1] += PLAYER_SPEED*delta_time;
        }

        if (raylib::is_key_down(raylib::KEY_W) || raylib::is_key_down(raylib::KEY_UP)) {
            player.ball.center[1] -= PLAYER_SPEED*delta_time;
        }

        player.ball.clip_position();

        raylib::begin_drawing();
        raylib::begin_mode_2d(camera); // where the magic happens
        // let's say that is the color of the wall
        raylib::clear_background(WALL_COLOR);
        raylib::draw_rectangle_v({WALL_THICK, WALL_THICK}, {WORLD_WIDTH - WALL_THICK * 2, WORLD_HEIGTH - WALL_THICK * 2}, BACKGROUND_COLOR);

        // roll the dice to spawn the food
        if (((float) random::rand(1000) / 1000) < FOOD_RESPAWN_PROB) {
            try_spawn_food(&number_of_food);
        }
        
        foreach (&enemy : enemies) {
          if (enemy.alive) {
            enemy.enemy_update();
            if (player.ball.overlaps(&enemy.ball)) {
              player.eat_player(enemy);
            } 
            enemy.draw();
          }
        }

        int food_idx = 0;
        foreach (&food : all_food) {
            
            if (food_idx++ >= number_of_food) {
                break;
            }

            if (food.active) {
                
                if (player.ball.overlaps(food)) {
                    player.eat(food);
                }

                food.draw();
            }
        }

        player.draw();
        camera.target[0] = player.ball.center[0];
        camera.target[1] = player.ball.center[1];
        camera.zoom = compute_camera_zoom(camera.zoom, player.ball.radius);

        raylib::end_mode_2d();
        raylib::end_drawing();
        window_should_close = raylib::window_should_close() || window_should_close;
    }

    raylib::close_window();
    
}





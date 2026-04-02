# Darts League — Custom Files Package

Drop these files into a fresh Rails 7.1 project created with:

  rails new darts_league --database=sqlite3 --javascript=importmap

Then follow the steps below.

────────────────────────────────────────────────
STEP 1 — Add gems (edit your generated Gemfile)
────────────────────────────────────────────────

In the :development, :test group add:
  gem "rspec-rails",       "~> 6.0"
  gem "factory_bot_rails"
  gem "faker"

In the :test group add:
  gem "shoulda-matchers", "~> 5.0"

Then run:
  bundle install
  rails generate rspec:install

────────────────────────────────────────────────
STEP 2 — Add one line to config/application.rb
────────────────────────────────────────────────

Inside the Application class body add:
  config.autoload_paths << Rails.root.join("app/services")

────────────────────────────────────────────────
STEP 3 — Copy these files into your project
────────────────────────────────────────────────

REPLACE (overwrite the generated file):
  app/controllers/application_controller.rb  → app/controllers/
  app/views/layouts/application.html.erb     → app/views/layouts/
  app/assets/stylesheets/application.css     → app/assets/stylesheets/
  config/routes.rb                           → config/

CREATE (new files, folder may not exist yet):
  app/services/                              ← create this folder
  app/services/pairing_service.rb

PASTE (new files into existing folders):
  app/models/player.rb
  app/models/match.rb
  app/models/game.rb
  app/models/game_participant.rb
  app/models/absence.rb

  app/controllers/home_controller.rb
  app/controllers/matches_controller.rb
  app/controllers/players_controller.rb
  app/controllers/games_controller.rb
  app/controllers/absences_controller.rb

  app/views/matches/index.html.erb
  app/views/matches/show.html.erb
  app/views/matches/new.html.erb
  app/views/matches/edit.html.erb
  app/views/matches/_form.html.erb

  app/views/players/index.html.erb
  app/views/players/new.html.erb
  app/views/players/edit.html.erb
  app/views/players/_form.html.erb

  app/javascript/controllers/flash_controller.js

  db/migrate/20240101000001_create_players.rb
  db/migrate/20240101000002_create_matches.rb
  db/migrate/20240101000003_create_games.rb
  db/migrate/20240101000004_create_game_participants.rb
  db/migrate/20240101000005_create_absences.rb
  db/seeds.rb

  spec/factories/players.rb
  spec/factories/matches.rb
  spec/models/player_spec.rb
  spec/models/match_spec.rb
  spec/controllers/matches_controller_spec.rb
  spec/services/pairing_service_spec.rb

────────────────────────────────────────────────
STEP 4 — Boot it up
────────────────────────────────────────────────

  rails db:migrate
  rails db:seed
  rails server

Open http://localhost:3000

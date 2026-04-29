# 🎯 Dart League Manager

A web-based league management application built with **Ruby on Rails** to manage a competitive darts league. Developed as a self-directed learning exercise — my first Ruby on Rails application, built with no prior Rails experience.

> **Live demo:** [dartleague.onrender.com](https://dartleague.onrender.com)

---

## What it does

Manages the full lifecycle of a darts league season including players, match scheduling, automatic pairing, game tracking, and attendance.

### Players
- Full player roster management (add, edit, remove)
- Gender and skill rank tracking per player
- Expandable roster (up to 8 players)
- Track player availability and absences

### Matches
- Schedule league matches with opponent, date, and venue
- Automatic player pairing via `PairingService`
- Idempotent seed data — re-running seeds never duplicates matches
- Track match status (assigned → completed)

### Games
- Record individual game results within each match
- `build_standard_slate` generates the full game card for each match automatically
- Track game participants via `GameParticipant` join model
- Game status tracking (assigned, completed)

### Absences
- Log player absences per match
- Affects pairing and scheduling logic

### PairingService
- Automatically assigns players to games based on availability
- Handles `InsufficientPlayersError` and `PairingImpossibleError` gracefully
- Pairing respects gender and rank attributes

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Ruby on Rails 7 |
| Language | Ruby 3.x |
| Database | SQLite |
| Frontend | ERB templates, HTML, JavaScript |
| Deployment | Render.com |
| Container | Docker |
| Code Style | RuboCop |
| Testing | RSpec |

---

## Architecture

```
app/
├── controllers/
│   ├── players_controller.rb      # Player CRUD
│   ├── matches_controller.rb      # Match scheduling & results
│   ├── games_controller.rb        # Individual game tracking
│   ├── absences_controller.rb     # Player absence management
│   └── home_controller.rb         # Dashboard
├── models/
│   ├── player.rb                  # Player entity (name, gender, rank)
│   ├── match.rb                   # Match entity with build_standard_slate
│   ├── game.rb                    # Game entity
│   ├── game_participant.rb        # Join model — players ↔ games
│   └── absence.rb                 # Absence tracking
├── services/
│   └── pairing_service.rb         # Automatic match pairing logic
└── views/
    ├── matches/                   # Match views (index, show, new, edit)
    └── players/                   # Player views (index, new, edit)
```

---

## Seed data

The app ships with a realistic seed file that sets up a full league season:

```ruby
# Real roster with gender and skill rank
ROSTER = [
  { name: "Linda",   gender: "female", rank: 3 },
  { name: "Mike",    gender: "male",   rank: 1 },
  { name: "Charlie", gender: "male",   rank: 2 },
  # ...
]

# Real match schedule with opponents and venues
SCHEDULE = [
  { opponent: "Elaine, Show Us Those Trips!", location: "Rags",           match_date: ... },
  { opponent: "It's Irrelevant",              location: "Top Spin",       match_date: ... },
  { opponent: "Diddler & Co.",                location: "Crown & Anchor", match_date: ... },
]
```

Running `rails db:seed` creates the roster, schedules all matches, and automatically assigns pairings.

---

## Running locally

```bash
# Clone the repo
git clone https://github.com/chazmj1s/DartLeague.git
cd DartLeague

# Install dependencies
bundle install

# Set up the database
rails db:create db:migrate db:seed

# Start the server
rails server
```

Visit `http://localhost:3000`

---

## Status & Roadmap

- ✅ Player roster management
- ✅ Match scheduling and results
- ✅ Automatic player pairing
- ✅ Game tracking with participant records
- ✅ Absence tracking
- ✅ Deployed to Render.com via Docker
- 🔲 Season standings and statistics
- 🔲 User authentication
- 🔲 Mobile-responsive UI improvements

---

## Development Approach

This project was built using **AI-assisted development** with Anthropic's Claude as a
collaborative coding partner. Claude was used for code generation, Rails conventions,
and debugging — while all product decisions, domain logic, and requirements came from me
as the developer and an active darts league player.

This was not a "generate and accept" workflow. Throughout development I:
- Applied real league knowledge to drive data model and scheduling decisions
- Made direct hands-on code modifications to meet exact specifications
- Debugged deployment and runtime issues independently
- Drove all feature requirements from actual league management needs

---

## About this project

I've been a competitive darts player in a local league for several years. Rather than
using generic scheduling software, I built a tool tailored to how our league actually
runs. This project was my deliberate entry point into Ruby on Rails, chosen to broaden
my stack beyond the Windows/.NET world I've worked in professionally for 30+ years.

*Built by a senior .NET developer (C#, ASP.NET MVC, SQL Server) expanding into full-stack web development.*
* ...

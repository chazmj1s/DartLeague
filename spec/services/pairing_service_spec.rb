# spec/services/pairing_service_spec.rb
require "rails_helper"

RSpec.describe PairingService do

  # ── Roster helpers ───────────────────────────────────────────────────────────
  let!(:linda)   { create(:player, name: "Linda",   gender: "female") }
  let!(:anita)   { create(:player, name: "Anita",   gender: "female") }
  let!(:mike)    { create(:player, name: "Mike",    gender: "male")   }
  let!(:dave)    { create(:player, name: "Dave",    gender: "male")   }
  let!(:charlie) { create(:player, name: "Charlie", gender: "male")   }
  let!(:ronnie)  { create(:player, name: "Ronnie",  gender: "male")   }

  let(:match)   { Match.build_standard_slate(opponent: "Test Pub", match_date: Date.today).tap(&:save!) }
  subject(:svc) { described_class.new(match) }

  # ── Full 6-player roster ─────────────────────────────────────────────────────

  describe "#assign! with full roster (6 players)" do
    before { svc.assign! }

    it "assigns all 11 games" do
      expect(match.games.where(status: "assigned").count).to eq(11)
    end

    it "assigns exactly 1 player to each singles game" do
      match.games.singles.each { |g| expect(g.home_players.count).to eq(1) }
    end

    it "assigns exactly 2 players to each doubles game" do
      match.games.doubles.each { |g| expect(g.home_players.count).to eq(2) }
    end

    it "assigns exactly 4 players to the team game" do
      expect(match.games.team.first.home_players.count).to eq(4)
    end

    it "never repeats a doubles partnership within the match" do
      keys = match.games.doubles.map { |g| g.home_players.map(&:id).sort }
      expect(keys).to eq(keys.uniq)
    end

    it "includes a woman in at least one singles game" do
      female_in_singles = match.games.singles.any? { |g| g.home_players.any?(&:female?) }
      expect(female_in_singles).to be true
    end

    it "includes a woman in at least one doubles game" do
      female_in_doubles = match.games.doubles.any? { |g| g.home_players.any?(&:female?) }
      expect(female_in_doubles).to be true
    end

    it "includes a woman in the team game" do
      expect(match.games.team.first.home_players.any?(&:female?)).to be true
    end

    it "distributes load as evenly as possible (max spread ≤ 1 game)" do
      # 6 players, 20 slots → 2 players get 4 games, 4 players get 3 games
      counts = match.load_report.values
      expect(counts.max - counts.min).to be <= 1
    end

    it "allows any gender combination in doubles" do
      # No restriction — woman+woman, woman+man, man+man all valid
      expect { svc.assign! }.not_to raise_error
    end
  end

  # ── Load balancing across roster sizes ──────────────────────────────────────

  describe "load balancing" do
    context "with 4 players (exact)" do
      before do
        [charlie, ronnie, anita].each { |p| Absence.create!(match: match, player: p) }
        described_class.new(match).assign!
      end

      it "each player plays exactly 5 games (20 ÷ 4)" do
        counts = match.load_report.values
        expect(counts.uniq).to eq([5])
      end
    end

    context "with 5 players (exact)" do
      before do
        [charlie, ronnie].each { |p| Absence.create!(match: match, player: p) }
        described_class.new(match).assign!
      end

      it "each player plays exactly 4 games (20 ÷ 5)" do
        counts = match.load_report.values
        expect(counts.uniq).to eq([4])
      end
    end

    context "with 6 players" do
      before { svc.assign! }

      it "load spread is at most 1 game (3 or 4 games per player)" do
        counts = match.load_report.values
        expect(counts.max - counts.min).to be <= 1
        expect(counts.min).to be >= 3
        expect(counts.max).to be <= 4
      end
    end

    context "with 8 players (full roster)" do
      let!(:sarah) { create(:player, name: "Sarah", gender: "female") }
      let!(:tina)  { create(:player, name: "Tina",  gender: "female") }

      before { described_class.new(match).assign! }

      it "load spread is at most 1 game (2 or 3 games per player)" do
        counts = match.load_report.values
        expect(counts.max - counts.min).to be <= 1
      end
    end
  end

  # ── Female coverage mandate ──────────────────────────────────────────────────

  describe "female coverage" do
    context "with only one woman available" do
      before do
        Absence.create!(match: match, player: anita)
        described_class.new(match).assign!
      end

      it "the one woman appears in a singles game" do
        expect(match.games.singles.any? { |g| g.home_players.include?(linda) }).to be true
      end

      it "the one woman appears in a doubles game" do
        expect(match.games.doubles.any? { |g| g.home_players.include?(linda) }).to be true
      end

      it "the one woman appears in the team game" do
        expect(match.games.team.first.home_players.include?(linda)).to be true
      end
    end
  end

  # ── Absence handling ─────────────────────────────────────────────────────────

  describe "absence handling" do
    context "when one player is absent" do
      before do
        Absence.create!(match: match, player: ronnie)
        described_class.new(match).assign!
      end

      it "does not include the absent player" do
        ids = match.games.flat_map { |g| g.home_players.map(&:id) }
        expect(ids).not_to include(ronnie.id)
      end

      it "still assigns all 11 games" do
        expect(match.games.where(status: "assigned").count).to eq(11)
      end
    end
  end

  # ── Error cases ──────────────────────────────────────────────────────────────

  describe "error handling" do
    context "with fewer than 4 players available" do
      before do
        [anita, mike, dave, charlie].each { |p| Absence.create!(match: match, player: p) }
      end

      it "raises InsufficientPlayersError" do
        expect { described_class.new(match).assign! }
          .to raise_error(PairingService::InsufficientPlayersError, /minimum is 4/)
      end
    end

    context "with no women on the roster" do
      before do
        [linda, anita].each { |p| Absence.create!(match: match, player: p) }
      end

      it "raises InsufficientPlayersError citing female requirement" do
        expect { described_class.new(match).assign! }
          .to raise_error(PairingService::InsufficientPlayersError, /female/)
      end
    end

    context "with too few players for unique doubles pairs" do
      # Need C(n,2) >= 6  →  n >= 4, but 4 players gives C(4,2)=6 exactly
      # So 3 players (C(3,2)=3) would fail — but we already need min 4.
      # With 4 players C(4,2)=6 pairs for 6 doubles slots — exactly enough.
      it "succeeds with exactly 4 players (C(4,2)=6 pairs for 6 games)" do
        [charlie, ronnie, anita].each { |p| Absence.create!(match: match, player: p) }
        expect { described_class.new(match).assign! }.not_to raise_error
      end
    end
  end

  # ── Roster summary ───────────────────────────────────────────────────────────

  describe "#roster_summary" do
    it "returns correct counts for the 6-player roster" do
      s = svc.roster_summary
      expect(s[:total]).to eq(6)
      expect(s[:women]).to eq(2)
      expect(s[:men]).to eq(4)
      expect(s[:total_slots]).to eq(20)
      expect(s[:target_load]).to eq(3.33)
      # C(6,2) = 15 valid pairs
      expect(s[:valid_pairs]).to eq(15)
    end
  end
end

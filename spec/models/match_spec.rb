# spec/models/match_spec.rb
require "rails_helper"

RSpec.describe Match, type: :model do
  describe "validations" do
    it { should validate_presence_of(:opponent) }
    it { should validate_presence_of(:match_date) }
    it { should validate_inclusion_of(:status).in_array(%w[draft finalized completed]) }
  end

  describe ".build_standard_slate" do
    subject(:match) { Match.build_standard_slate(opponent: "The Red Lion", match_date: Date.today) }

    it "builds exactly 11 games" do
      expect(match.games.size).to eq(11)
    end

    it "includes 4 singles games" do
      expect(match.games.count { |g| g.format == "singles" }).to eq(4)
    end

    it "includes 6 doubles games" do
      expect(match.games.count { |g| g.format == "doubles" }).to eq(6)
    end

    it "includes 1 team game" do
      expect(match.games.count { |g| g.format == "team" }).to eq(1)
    end

    it "sets all games to unassigned" do
      expect(match.games.map(&:status).uniq).to eq(["unassigned"])
    end

    it "assigns sequences 1–11 in order" do
      expect(match.games.map(&:sequence)).to eq((1..11).to_a)
    end
  end

  describe "#load_report" do
    let(:match)  { Match.build_standard_slate(opponent: "Pub", match_date: Date.today).tap(&:save!) }
    let(:player) { create(:player) }

    it "returns zero for a player with no assignments" do
      expect(match.load_report[player]).to eq(0)
    end
  end

  describe "status predicates" do
    it { expect(build(:match, status: "draft").finalized?).to     be false }
    it { expect(build(:match, status: "finalized").finalized?).to be true  }
    it { expect(build(:match, status: "completed").completed?).to be true  }
  end
end

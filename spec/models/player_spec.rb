# spec/models/player_spec.rb
require "rails_helper"

RSpec.describe Player, type: :model do
  describe "validations" do
    it { should validate_presence_of(:name) }
    it { should validate_inclusion_of(:gender).in_array(%w[male female]) }
  end

  describe "scopes" do
    let!(:active_m)   { create(:player, :male,   active: true)  }
    let!(:active_f)   { create(:player, :female, active: true)  }
    let!(:inactive)   { create(:player, active: false) }

    it ".active returns only active players"  { expect(Player.active).to     include(active_m, active_f) }
    it ".active excludes inactive players"    { expect(Player.active).not_to include(inactive)           }
    it ".male filters correctly"              { expect(Player.male).to        include(active_m)           }
    it ".female filters correctly"            { expect(Player.female).to      include(active_f)           }
    it ".ordered sorts by name"               { expect(Player.active.ordered.first.name).to be <= Player.active.ordered.last.name }
  end

  describe ".available_for" do
    let(:match)  { create(:match) }
    let(:player) { create(:player) }
    let(:absent) { create(:player) }

    before { create(:absence, match: match, player: absent) }

    it "includes players not marked absent"  { expect(Player.available_for(match)).to     include(player) }
    it "excludes players marked absent"      { expect(Player.available_for(match)).not_to include(absent) }
  end

  describe "predicates" do
    let(:man)   { build(:player, :male)   }
    let(:woman) { build(:player, :female) }

    it { expect(man.male?).to   be true  }
    it { expect(man.female?).to be false }
    it { expect(woman.female?).to be true }
    it { expect(woman.gender_label).to eq "F" }
    it { expect(man.gender_label).to   eq "M" }
  end

  describe "roster cap validation" do
    before do
      Player::MAX_ROSTER.times { create(:player) }
    end

    it "prevents adding a player beyond MAX_ROSTER" do
      over = build(:player)
      expect(over).not_to be_valid
      expect(over.errors[:base]).to include(/full/i)
    end
  end
end

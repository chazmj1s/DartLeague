# spec/controllers/matches_controller_spec.rb
require "rails_helper"

RSpec.describe MatchesController, type: :controller do
  let!(:linda)   { create(:player, name: "Linda",   gender: "female") }
  let!(:anita)   { create(:player, name: "Anita",   gender: "female") }
  let!(:mike)    { create(:player, name: "Mike",    gender: "male")   }
  let!(:dave)    { create(:player, name: "Dave",    gender: "male")   }
  let!(:charlie) { create(:player, name: "Charlie", gender: "male")   }
  let!(:ronnie)  { create(:player, name: "Ronnie",  gender: "male")   }

  let(:valid_params) do
    { match: { opponent: "The Crown", match_date: Date.today + 7, location: "home" } }
  end

  describe "GET #index" do
    it "returns success" do
      get :index
      expect(response).to be_successful
    end
  end

  describe "GET #new" do
    it "returns success and builds a slate" do
      get :new
      expect(response).to be_successful
      expect(assigns(:match).games.size).to eq(11)
    end
  end

  describe "POST #create" do
    it "creates a match and redirects to it" do
      expect {
        post :create, params: valid_params
      }.to change(Match, :count).by(1)
      expect(response).to redirect_to(match_path(Match.last))
    end

    it "renders new on invalid params" do
      post :create, params: { match: { opponent: "" } }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "POST #reassign" do
    let!(:match) { Match.build_standard_slate(opponent: "Pub", match_date: Date.today).tap(&:save!) }

    it "reassigns pairings and redirects back" do
      post :reassign, params: { id: match.id }
      expect(response).to redirect_to(match_path(match))
      expect(flash[:notice]).to match(/updated/i)
    end
  end

  describe "POST #finalize" do
    let!(:match) { create(:match) }

    it "sets status to finalized" do
      post :finalize, params: { id: match.id }
      expect(match.reload.status).to eq("finalized")
    end
  end

  describe "DELETE #destroy" do
    let!(:match) { create(:match) }

    it "deletes the match and redirects to index" do
      expect {
        delete :destroy, params: { id: match.id }
      }.to change(Match, :count).by(-1)
      expect(response).to redirect_to(matches_path)
    end
  end
end

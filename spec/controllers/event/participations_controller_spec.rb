# encoding: utf-8

#  Copyright (c) 2012-2015, Pfadibewegung Schweiz. This file is part of
#  hitobito_pbs and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pbs.

require 'spec_helper'

describe Event::ParticipationsController do

  let(:group) { course.groups.first }
  let(:course) { Fabricate(:youth_course, groups: [groups(:top_layer)]) }
  let(:participation) { assigns(:participation).reload }

  before { sign_in(people(:top_leader)) }



  context 'GET#index' do
    it 'does not include tentative participants' do
      Fabricate(:event_participation,
                event: course,
                state: 'applied',
                person: people(:bottom_member),
                active: true)
      get :index, group_id: group.id, event_id: course.id
      expect(assigns(:participations)).to be_empty
    end
  end

  context 'POST#create' do

    it 'sets participation state to applied' do
      post :create,
           group_id: group.id,
           event_id: course.id,
           event_participation: { person_id: people(:top_leader).id }
      expect(participation.state).to eq 'applied'
    end

    it 'sets participation state to assigned when created by organisator' do
      post :create,
           group_id: group.id,
           event_id: course.id,
           event_participation: { person_id: people(:bottom_member).id }
      expect(participation.state).to eq 'assigned'
    end

  end

  context 'POST cancel' do

    let(:participation) { Fabricate(:youth_participation, event: course) }

    it 'cancels participation' do
      post :cancel,
           group_id: group.id,
           event_id: course.id,
           id: participation.id,
           event_participation: { canceled_at: Date.today }
      expect(flash[:notice]).to be_present
      participation.reload
      expect(participation.canceled_at).to eq Date.today
      expect(participation.state).to eq 'canceled'
      expect(participation.active).to eq false
    end

    it 'requires canceled_at date' do
      post :cancel,
           group_id: group.id,
           event_id: course.id,
           id: participation.id,
           event_participation: { canceled_at: ' ' }
      expect(flash[:alert]).to be_present
      participation.reload
      expect(participation.canceled_at).to eq nil
    end
  end

  context 'POST reject' do
    render_views

    let(:participation) { Fabricate(:youth_participation, event: course) }
    let(:dom) { Capybara::Node::Simple.new(response.body) }

    it 'rejects participation' do
      post :reject,
        group_id: group.id,
        event_id: course.id,
        id: participation.id
      participation.reload
      expect(participation.state).to eq 'rejected'
      expect(participation.active).to eq false
    end

  end

end

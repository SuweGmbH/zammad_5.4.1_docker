# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Mobile > Organization > Can view organization', app: :mobile, type: :system do
  let(:organization)        { create(:organization, domain: 'domain.com', note: '') }
  let(:user)                { create(:customer, organization: organization) }
  let(:group)               { create(:group) }
  let(:agent)               { create(:agent, groups: [group]) }

  def open_organization
    visit "/organizations/#{organization.id}"
    wait_for_gql('apps/mobile/entities/organization/graphql/queries/organization.graphql')
  end

  context 'when visiting as agent', authenticated_as: :agent do
    it 'shows general information' do
      organization.update!(note: 'This is test organization')
      open_organization

      expect(page).to have_text(organization.name)

      domain = find('section', text: %r{Domain})
      expect(domain).to have_text('domain.com')

      note = find('section', text: %r{Note})
      expect(note).to have_text('This is test organization')

      organization.update!(name: 'Some New Name')

      wait_for_gql('apps/mobile/entities/organization/graphql/subscriptions/organizationUpdates.graphql')

      expect(page).to have_text('Some New Name')
    end

    it 'shows object attributes', db_strategy: :reset do
      screens = { view: { 'ticket.agent': { shown: true, required: false } } }
      attribute = create_attribute(
        :object_manager_attribute_text,
        object_name: 'Organization',
        display:     'Custom Text',
        screens:     screens
      )
      organization[attribute.name] = 'Attribute Text'
      organization.save!

      open_organization

      domain = find('section', text: %r{Custom Text})
      expect(domain).to have_text('Attribute Text')

      organization[attribute.name] = 'Updated Text'
      organization.save!

      wait_for_gql('apps/mobile/entities/organization/graphql/subscriptions/organizationUpdates.graphql')

      expect(domain).to have_text('Updated Text')
    end
  end

  context 'when visiting as customer', authenticated_as: :user do
    it 'redirects to error' do
      visit '/organizations/1'
      expect_current_route('/error')
    end
  end
end

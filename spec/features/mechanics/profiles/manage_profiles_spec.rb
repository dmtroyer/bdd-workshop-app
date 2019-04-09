require 'rails_helper'

feature 'user manages profiles', js: true do
  scenario 'complains bitterly if the profile cannot be retrieved' do
    When 'the user visits the profile page and the API returns an error' do
      ForceApiError.force(method: 'post', url: '/api/v1/profiles', error: 'something went wrong')
      visit('/profile')
    end

    Then 'I see an error message' do
      # TODO: 5XX errors should be generic "something went wrong" message
      wait_for { focus_on(:messages).error }.to eq '500 - Internal Server Error'
      wait_for { focus_on(:util).other_test_elements }.to eq []
    end
  end

  context 'Given a user has a partially complete profile' do
    before do
      @profile = Player.create!(id: '01234567-0123-4abc-8abc-0123456789ab', handle: 'princess')
      page.visit('/')
      player = {
        id: @profile.id,
        handle: @profile.handle
      }
      page.execute_script("window.localStorage.setItem('player','#{player.to_json}')")
    end

    scenario 'profile page displays a loading state while retrieving profile details from api' do
      When 'user visits their profile page in original loading state' do
        with_api_route_paused(method: 'get', url: '/api/v1/profiles') do
          visit('/profile')
          wait_for { focus_on(:util).test_elements('profile') }.to eq ['Loading...']
        end
      end

      Then 'the loading element is no longer visible' do
        wait_for { focus_on(:util).test_elements('profile') }.to_not include('Loading...')
      end
    end

    scenario 'page shows error if profile fetch failed'

    scenario 'complains bitterly if the profile cannot be updated' do
      When 'user tries to update their profile'
      But 'the database has gone down'
      Then 'an error message is shown'
    end

    context 'and some other profile exists as well' do
      before do
        Player.create!(
          id: '01234567-0123-4abc-8abc-0123456789ac',
          handle: 'troll',
          email: 'troll@email.com'
        )
      end

      scenario 'new handles must be unique' do
        When 'user tries to update handle to be the same as an existing one' do
          visit('/profile')
          focus_on(:page_content).container_for('profile').action_item('Edit')
          focus_on(:form).form_for('profile').fill_in_row_for('handle', 'troll')
          focus_on(:form).form_for('profile').submit
        end

        Then 'a warning message is shown' do
          wait_for { focus_on(:messages).error }.to eq('handle: has already been taken')
          wait_for { focus_on(:form).form_for('profile').field('handle') }.to eq('troll')
          # TODO: check top right hand for princess unchanged
        end

        When 'user refreshes the page' do
          page.refresh
        end

        Then 'handle has not been updated' do
          wait_for { focus_on(:profile).details[:handle] }.to eq('princess')
        end

        When 'user changes handle to something unique' do
          focus_on(:page_content).container_for('profile').action_item('Edit')
          focus_on(:form).form_for('profile').fill_in_row_for('handle', 'disney_princess')
          focus_on(:form).form_for('profile').submit
        end

        Then 'profile is saved successfully' do
          wait_for { focus_on(:messages).info }.to eq('Updated user profile')
        end
      end

      scenario 'auto generating a new handle' do
        When 'user tries to update handle to be the same as an existing one'
        Then 'a warning message is shown'
        When 'user chooses to auto generate a handle'
        Then 'profile is saved successfully'
      end

      scenario 'handle cannot be autogenerated' do
        When 'user tries to update handle to be the same as an existing one'
        But 'for some reason the handle cannot be generated at this time'
        Then 'a message is shown to try again later or contact support'
      end
    end

    describe 'profile pictures' do
      scenario 'uploading a profile picture' do
        When 'user uploads a profile picture'
        Then 'their uploaded picture is shown as the profile picture'
      end

      scenario 'selecting a gravatar as the profile picture' do
        When 'user chooses a gravatar for their profile picture'
        Then 'their selected gravatar is shown as the profile picture'
      end

      context 'profile picture has been uploaded to this users profile' do
        scenario 'switching between uploaded profile picture, gravatar and placeholder profile picture' do
          When 'user successfully uploads a new profile picture'
          Then 'profile picture is updated to new profile picture'
          When 'user deletes uploaded profile picture'
          Then 'profile picture is updated to placeholder'
          When 'user chooses gravatar'
          Then 'profile picture is updated to gravatar'
          When 'user successfully uploads a profile picture again'
          Then 'profile picture is updated to new profile picture'
          When 'user deletes uploaded profile picture'
          Then 'profile picture is updated to last selected gravatar'
        end
      end

      # warnings
      scenario 'uploading a profile picture fails' do
        When 'user attempts to upload a new profile picture'
        Then 'an error is thrown'
      end
    end
  end
end

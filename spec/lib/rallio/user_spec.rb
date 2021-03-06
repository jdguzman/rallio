module Rallio
  describe User do
    let(:parsed_response) { accessible_users_response }
    let(:api_response) { double(:api_response, parsed_response: parsed_response) }

    before do
      Rallio.application_id = 'foobar'
      Rallio.application_secret = 'bizbaz'
      allow(described_class).to receive(:get).and_return(api_response)
      allow(described_class).to receive(:post).and_return(api_response)
    end

    describe '.accessible_users' do
      let(:headers) do
        {
          'X-Application-ID' => Rallio.application_id,
          'X-Application-Secret' => Rallio.application_secret
        }
      end
      let(:parsed_response) { accessible_users_response }

      it 'calls out to get accessible users for app' do
        expect(described_class).to receive(:get).with('/accessible_users', headers: headers)
        described_class.accessible_users
      end

      it 'returns an array' do
        expect(described_class.accessible_users).to be_a Array
      end

      it 'contains an array with User objects' do
        expect(described_class.accessible_users).to include(a_kind_of(User))
      end
    end

    describe '.create' do
      let(:headers) do
        {
          'X-Application-ID' => Rallio.application_id,
          'X-Application-Secret' => Rallio.application_secret
        }
      end
      let(:parsed_response) { user_response }
      let(:body) do
        {
          user: {
            email: 'example@example.com',
            first_name: 'John',
            last_name: 'Doe'
          }
        }
      end

      it 'calls out to create a new user' do
        expect(described_class).to receive(:post).with('/users', headers: headers, body: body)
        described_class.create(user: body[:user])
      end

      it 'returns a User object' do
        expect(described_class.create(user: body[:user])).to be_a Rallio::User
      end
    end

    describe '#sign_on_token' do
      let(:headers) do
        {
          'X-Application-ID' => Rallio.application_id,
          'X-Application-Secret' => Rallio.application_secret
        }
      end
      let(:parsed_response) { sign_on_tokens_response }
      let(:token) { SignOnToken.new(sign_on_tokens_response) }
      let(:user) { described_class.new(accessible_users_response['users'].first) }

      before do
        allow(SignOnToken).to receive(:create).and_return(token)
      end

      it 'calls create on SignOnToken with user id' do
        expect(SignOnToken).to receive(:create).with(user_id: user.id, params: {})
        user.sign_on_token
      end

      it 'returns a SignOnToken' do
        expect(user.sign_on_token).to be_a SignOnToken
      end
    end

    describe '#access_token' do
      let(:token) { Rallio::AccessToken.new(access_tokens_response) }

      subject { described_class.new(accessible_users_response['users'].first) }

      before do
        allow(AccessToken).to receive(:create).and_return(token)
      end

      it 'calls create on AccessToken with user id' do
        expect(AccessToken).to receive(:create).with(user_id: subject.id)
        subject.access_token
      end

      it 'returns an AccessToken instance' do
        expect(subject.access_token).to be_a Rallio::AccessToken
      end

      it 'sets the @access_token ivar' do
        subject.access_token
        expect(subject.instance_variable_get(:@access_token)).to eq token
      end
    end

    describe '#account_ownerships' do
      let(:parsed_response) { account_ownerships_response }
      let(:token) { Rallio::AccessToken.new(access_tokens_response) }

      subject { described_class.new(user_response) }

      before do
        subject.access_token = token
        allow(AccountOwnership).to receive(:get).and_return(api_response)
      end

      it 'calls out to get accounts the user has access to' do
        expect(AccountOwnership).to receive(:for).with(access_token: token.access_token)
        subject.account_ownerships
      end

      it 'returns an array of AccountOwnerships' do
        expect(subject.account_ownerships).to include(a_kind_of(AccountOwnership))
      end
    end

    describe '#franchisor_ownerships' do
      let(:parsed_response) { franchisor_ownerships_response }
      let(:token) { Rallio::AccessToken.new(access_tokens_response) }

      subject { described_class.new(user_response) }

      before do
        subject.access_token = token
        allow(FranchisorOwnership).to receive(:get).and_return(api_response)
      end

      it 'calls out to get accounts the user has access to' do
        expect(FranchisorOwnership).to receive(:for).with(access_token: token.access_token)
        subject.franchisor_ownerships
      end

      it 'returns an array of FranchisorOwnerships' do
        expect(subject.franchisor_ownerships).to include(a_kind_of(FranchisorOwnership))
      end
    end

    describe '#dashboard' do
      let(:token) { Rallio::AccessToken.new(access_tokens_response) }
      let(:headers) { { 'Authorization' => "Bearer #{token.access_token}" } }
      let(:parsed_response) { dashboard_response }

      subject { described_class.new(user_response) }

      before do
        allow(AccessToken).to receive(:create).and_return(token)
      end

      it 'calls out to get authenticated users info' do
        expect(described_class).to receive(:get).with('/dashboard', headers: headers)
        subject.dashboard
      end

      context 'user data changed' do
        it 'updates the user info to reflect changes' do
          subject.dashboard
          aggregate_failures do
            expect(subject.name).to eq parsed_response['me']['name']
            expect(subject.accounts.first.name).to eq parsed_response['accounts'].first['name']
          end
        end

        it 'returns and instance of Rallio::User' do
          expect(subject.dashboard).to be_a Rallio::User
        end
      end
    end
  end
end

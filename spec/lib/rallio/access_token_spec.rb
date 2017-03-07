module Rallio
  describe AccessToken do
    let(:parsed_response) { access_token }
    let(:api_response) { double(:api_response, parsed_response: parsed_response) }

    before do
      Rallio.application_id = 'foobar'
      Rallio.application_secret = 'bizbaz'
      allow(described_class).to receive(:post).and_return(api_response)
    end

    describe '.create' do
      let(:headers) do
        {
          'X-Application-ID' => Rallio.application_id,
          'X-Application-Secret' => Rallio.application_secret
        }
      end
      let(:user_id) { access_token[:user_id] }

      it 'calls new with passed args' do
        expect(described_class).to receive(:post).with("/users/#{user_id}/access_token", headers: headers)
        described_class.create(user_id: user_id)
      end

      it 'returns an AccessToken object' do
        expect(described_class.create(user_id: user_id).to_hash).to eq access_token
      end
    end

    describe '#destroy' do
      let(:headers) do
        {
          'Authentication' => "Bearer #{access_token[:access_token]}"
        }
      end

      before do
        allow(described_class).to receive(:delete).and_return(api_response)
      end

      subject { described_class.new(access_token) }

      it 'calls out to destroy the token' do
        expect(described_class).to receive(:delete).with('/access_token', headers: headers)
        subject.destroy
      end

      it 'returns true on success' do
        expect(subject.destroy).to eq true
      end
    end
  end
end
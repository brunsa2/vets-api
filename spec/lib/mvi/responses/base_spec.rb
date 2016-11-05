# frozen_string_literal: true
require 'rails_helper'
require 'mvi/responses/find_candidate'

describe MVI::Responses::Base do
  let(:klass) do
    Class.new(MVI::Responses::Base) do
      mvi_endpoint :PRPA_IN201306UV02
    end
  end
  let(:faraday_response) { instance_double('Faraday::Response') }

  context 'with valid body' do
    let(:body) { Ox.parse(File.read('spec/support/mvi/find_candidate_response.xml')) }

    before(:each) do
      allow(faraday_response).to receive(:body) { body }
    end

    describe '#intialize' do
      it 'should be initialized with the correct attrs' do
        response = klass.new(faraday_response)
        expect(response.code).to eq('AA')
        expect(response.query).to_not be_nil
        expect(response.original_response).to eq(body)
      end
    end

    describe '#body' do
      it 'should invoke the subclass body' do
        allow(faraday_response).to receive(:body) { body }
        response = klass.new(faraday_response)
        expect { response.body }.to raise_error(MVI::Responses::NotImplementedError)
      end
    end
  end
  context 'when body contains fault' do
    let(:body) { Ox.parse(File.read('spec/support/mvi/find_candidate_internal_error_response.xml')) }

    before(:each) do
      allow(faraday_response).to receive(:body) { body }
    end

    describe '#intialize' do
      it 'should raise MVI::HTTPError' do
        expect(Rails.logger).to receive(:error).with('MVI fault code: env:Server').once
        expect(Rails.logger).to receive(:error).with('MVI fault string: Internal Error (from server)').once
        expect { klass.new(faraday_response) }.to raise_error(MVI::Errors::HTTPError, 'MVI internal server error')
      end
    end
  end
end

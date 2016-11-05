# frozen_string_literal: true
require 'mvi/errors/errors'
require 'mvi/responses/find_candidate'
require 'mvi/middleware/request/soap'
require 'mvi/middleware/response/soap'

module MVI
  # Wrapper for the MVI (Master Veteran Index) Service. vets.gov has access
  # to three MVI endpoints:
  # * PRPA_IN201301UV02 (TODO(AJD): Add Person)
  # * PRPA_IN201302UV02 (TODO(AJD): Update Person)
  # * PRPA_IN201305UV02 (aliased as .find_candidate)
  #
  # = Usage
  # Calls endpoints as class methods, if successful it will return a ruby hash of the SOAP XML response.
  #
  # Example:
  #  birth_date = Time.new(1980, 1, 1).utc
  #  message = MVI::Messages::FindCandidateMessage.new(['John', 'William'], 'Smith', birth_date, '555-44-3333').to_xml
  #  response = MVI::Service.new.find_candidate(message)
  #
  class Service
    OPERATIONS = {
      add_person: 'PRPA_IN201301UV02',
      update_person: 'PRPA_IN201302UV02',
      find_candidate: 'PRPA_IN201305UV02'
    }.freeze

    def self.options
      opts = {
        url: MVI::Settings::URL
      }
      if MVI::Settings::SSL_CERT && MVI::Settings::SSL_KEY
        opts[:ssl] = {
          client_cert: MVI::Settings::SSL_CERT,
          client_key: MVI::Settings::SSL_KEY
        }
      end
      opts
    end

    def find_candidate(message)
      faraday_response = connection.post '', message.to_xml, { soapaction: OPERATIONS[:find_candidate] }
      response = MVI::Responses::FindCandidate.new(faraday_response)
      invalid_request_handler('find_candidate', response.original_response) if response.invalid?
      request_failure_handler('find_candidate', response.original_response) if response.failure?
      raise MVI::Errors::RecordNotFound.new('MVI subject missing from response body', response) unless response.body
      response.body
    rescue Faraday::ConnectionFailed => e
      Rails.logger.error "MVI find_candidate connection failed: #{e.message}"
      raise MVI::ServiceError, 'MVI connection failed'
    end

    private

    def connection
      @conn ||= Faraday.new(MVI::Service.options) do |faraday|
        faraday.use MVI::Middleware::Request::Soap
        faraday.use MVI::Middleware::Response::Soap
        faraday.adapter  :httpclient
      end
    end

    def invalid_request_handler(operation, xml)
      Rails.logger.error "mvi #{operation} invalid request structure: #{xml}"
      raise MVI::Errors::InvalidRequestError
    end

    def request_failure_handler(operation, xml)
      Rails.logger.error "mvi #{operation} request failure: #{xml}"
      raise MVI::Errors::RequestFailureError
    end
  end
end

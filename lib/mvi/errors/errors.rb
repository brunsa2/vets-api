# frozen_string_literal: true
module MVI
  module Errors
    class ServiceError < StandardError
    end
    class RequestFailureError < MVI::Errors::ServiceError
    end
    class InvalidRequestError < MVI::Errors::ServiceError
    end
    class HTTPError < MVI::Errors::ServiceError
      attr_accessor :code

      def initialize(message = nil, code = nil)
        super(message)
        @code = code
      end
    end
    class RecordNotFound < StandardError
      attr_accessor :query, :original_response

      def initialize(message = nil, response = nil)
        super(message)
        @query = response.query
        @original_response = response.original_response
      end
    end
  end
end

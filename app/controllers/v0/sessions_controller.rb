# frozen_string_literal: true
module V0
  class SessionsController < ApplicationController
    skip_before_action :authenticate, only: [:new, :saml_callback]

    def new
      level = LOA::THREE if params['level'] == 'high'
      saml_auth_request = OneLogin::RubySaml::Authrequest.new
      render json: { authenticate_via_get: saml_auth_request.create(saml_settings(level)) }
    end

    def show
      render json: @session
    end

    def destroy
      @session.destroy
      head :no_content
    end

    def saml_callback
      @saml_response = OneLogin::RubySaml::Response.new(
        params[:SAMLResponse], settings: saml_settings
      )

      if @saml_response.is_valid?
        persist_session_and_user!
        render json: @session, status: :created
      else
        # TODO: also need to make sure error json conforms to api spec
        render json: { errors: @saml_response.errors }, status: :forbidden
      end
    end

    private

    def persist_session_and_user!
      @session = Session.new(user_attributes.slice(:uuid))
      @current_user = User.find(@session.uuid) || create_new_user
      @session.save && @current_user.save
    end

    def user_attributes
      attributes = @saml_response.attributes.all.to_h
      {
        first_name:   attributes['fname']&.first,
        middle_name:  attributes['mname']&.first,
        last_name:    attributes['lname']&.first,
        zip:          attributes['zip']&.first,
        email:        attributes['email']&.first,
        ssn:          attributes['social']&.first&.delete('-'),
        birth_date:   parse_date(attributes['birth_date']&.first),
        uuid:         attributes['uuid']&.first,

        level_of_assurance: level_of_assurance
      }
    end

    def parse_date(date_string)
      Time.parse(date_string).utc unless date_string.nil?
    rescue TypeError => e
      Rails.logger.error "error: #{e.message} when parsing date from saml date string: #{date_string.inspect}"
      nil
    end

    # Ruby-Saml does not parse the <samlp:Response> xml so we do it ourselves to find
    # which LOA was performed on the ID.me side.
    # TODO - remove this method once LOA is returned as a SAML Attribute
    def level_of_assurance
      raw_loa = Hash.from_xml(@saml_response.response)
                    .dig('Response', 'Assertion', 'AuthnStatement', 'AuthnContext', 'AuthnContextClassRef')
      LOA::MAPPING[raw_loa.to_sym]
    end

    def create_new_user
      if user_attributes[:level_of_assurance] == LOA::ONE
        User.new(user_attributes)
      else
        Decorators::MviUserDecorator.new(User.new(user_attributes)).create
      end
    end
  end
end

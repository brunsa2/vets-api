# frozen_string_literal: true

class DisabilityClaimsBaseController < ApplicationController
  before_action :authorize_user
  skip_before_action :authenticate

  protected

  def authorize_user
    unless current_user.evss_attrs?
      raise Common::Exceptions::Forbidden, detail: 'You do not have access to claim status'
    end
  end

  def claim_service
    @claim_service ||= DisabilityClaimService.new(current_user)
  end

  def current_user
    return @claim_current_user if @claim_current_user
    attrs = JSON.load(ENV['EVSS_SAMPLE_CLAIMANT_USER'])
    attrs[:last_signed_in] = Time.current.utc
    @claim_current_user = User.new(attrs)
  end
end

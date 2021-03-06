# frozen_string_literal: true
class VAFacilitySerializer < ActiveModel::Serializer
  def id
    "#{PREFIX_MAP[object.facility_type]}_#{object.unique_id}"
  end

  attributes :unique_id, :name, :facility_type, :classification, :website, :lat, :long,
             :address, :phone, :hours, :services, :feedback

  PREFIX_MAP = {
    'va_health_facility' => 'vha',
    'va_benefits_facility' => 'vba',
    'va_cemetery' => 'nca'
  }.freeze
end

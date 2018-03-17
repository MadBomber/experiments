# example_query_object.rb
# Makes use of Ruby version 2.5.0's Object#yeild_self method
# This would be a wonderful refactor of the CPP Referral
# and Consultation Filters
#
# See:  https://robots.thoughtbot.com/using-yieldself-for-composable-activerecord-relations
#



class QueryObjectName
  def self.call(base_relation, params)
    new(base_relation, params).call
  end

  def initialize(base_relation, params)
    @base_relation = base_relation
    @params = params
  end

  def call
    base_relation.
      joins(:care_periods).
      yield_self(&method(:care_provider_clause)).
      yield_self(&method(:hospital_clause)).
      yield_self(&method(:discharge_period_clause))
  end

  private

  def care_provider_clause(relation)
    if params.care_provider_id.present?
      relation.where(care_periods: { care_provider_id: params.care_provider_id })
    else
      relation
    end
  end

  def hospital_clause(relation)
    if params.hospital_id.present?
      relation.where(care_periods: { hospital_id: params.hospital_id })
    else
      relation
    end
  end

  def discharge_period_clause(relation)
    if params.discharge_period.present?
      relation.
        joins(:hospital_visit).
        where(hospital_visits: { end_on: params.discharge_period }
    else
      relation
    end
  end

  attr_reader :base_relation, :params
end # class QueryObjectName


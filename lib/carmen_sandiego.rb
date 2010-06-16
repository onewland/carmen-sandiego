require 'httparty'

=begin

CarmenSandiego makes searching GeoAPI not suck for Ruby. 

CarmenSandiego::Detective.new('api key goes here')

CarmenSandiego::Detective.search do |q|
  q.radius 1
  q.radius_unit :km
  q.lat 27.93547
  q.lng -82.50429
end

=end

module CarmenSandiego
  class QueryBuilder
    def initialize
      @result_types = []
    end

    attr_accessor :result_types

    private
    def self.add_query_setter(name, *aliases)
      s_name = name.to_s
      module_eval(%Q{
        def #{s_name}(val=nil)
          if !val
            @#{s_name}
          else
            @#{s_name} = val
          end
        end

        public(:#{s_name})
      })
      aliases.each do |a|
        module_eval(%Q{
          alias_method :#{a.to_s}, :#{s_name}
        })
      end
    end

    add_query_setter :radius
    add_query_setter :radius_unit, :distance_unit, :unit
    add_query_setter :latitude, :lat
    add_query_setter :longitude, :lon, :lng
    
    public
    def include_result_type(type)
      @result_types.push(type) if !@result_types.include?(type)
    end

    def exclude_result_type(type)
      @result_types.delete(type) if @result_types.include?(type) 
    end

    def set_result_types(types)
      @result_types = types
    end
  end

  class Detective
    def initialize(api_key)
      @api_key = api_key
    end

    def self.search(api_key, &block)
      d = Detective.new(api_key)
      d.search(&block)
    end

    def search
      q = QueryBuilder.new
      yield q
      search_with_query(q)
    end

    def search_with_query(query)
      raise InvalidQueryException if !(query.latitude && query.longitude && query.apikey)
      HTTParty.get("http://api.geoapi.com/v1/search", :query => {
          :lat => query.latitude,
          :lon => query.longitude,
          :apikey => @api_key,
          :pretty => 0
      })
    end
  end
end

require 'httparty'

=begin

CarmenSandiego makes searching GeoAPI not suck for Ruby. 

d = CarmenSandiego::Detective.new('api key goes here')

spots = d.search do |q|
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
      @prefetch_view_types = []
    end

    attr_accessor :result_types, :prefetch_view_types

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

    def self.add_query_list_setter(name)
      s_name = name.to_s
      module_eval(%Q{
        attr_accessor :#{s_name}s

        def include_#{s_name}(val)
          @#{s_name}s.push(val) if !@#{s_name}s.include?(val)
        end
        public(:include_#{s_name})

        def exclude_#{s_name}(val)
          @#{s_name}s.delete(val) if @#{s_name}s.include?(val)
        end
        public(:exclude_#{s_name})

        def set_#{s_name}s(vals)
          @#{s_name}s = vals
        end
        public(:set_#{s_name}s)
      })
    end

    add_query_setter :radius
    add_query_setter :radius_unit, :distance_unit, :unit
    add_query_setter :latitude, :lat
    add_query_setter :longitude, :lon, :lng
    add_query_list_setter :result_type
    add_query_list_setter :prefetch_view_type
  end

  class Detective
    class Spot 
      attr_accessor :guid, :name, :distance
      attr_reader :available_views, :views

      def initialize(hash)
        @guid = hash['guid']
        @geom = hash['meta']['geom']
        @name = hash['meta']['name']
        @distance = hash['distance-in-meters']
        @available_views = (hash['meta']['views'] + hash['meta']['userviews']).map {|v| v.to_sym}
        @views = {}
      end

      def load_views(type_list, api_key)
        type_list.each do |type| 
          load_view(type, api_key) if @available_views.include?(type)
        end
      end

      def load_view(type, api_key)
        puts "loading #{type}, available = #{@available_views.inspect}"
        q = {
          :apikey => api_key 
        }
        if @available_views.include?(type)
          url = "http://api.geoapi.com/v1/e/#{@guid}/view/#{type.to_s}"
          resp = HTTParty.get(url, :query => q)
          if !resp['error']
            views[type] = resp['result']
          end
        else
          raise UnavailableViewException
        end
      end
    end

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
      raise InvalidQueryException if !(query.latitude && query.longitude && @api_key)
      q = {
         :lat => query.latitude,
         :lon => query.longitude,
         :apikey => @api_key,
         :pretty => 0
      }

      if query.radius && query.radius_unit
        q[:radius] = query.radius.to_s + query.radius_unit.to_s
      end

      result = HTTParty.get("http://api.geoapi.com/v1/search", :query => q)['result']
      result.map do |h| 
        e = create_entity_from_result(h)
        e.load_views(query.prefetch_view_types, @api_key)
        e
      end
    end

    private
    def create_entity_from_result(hash)
      Spot.new(hash)
    end
  end
end

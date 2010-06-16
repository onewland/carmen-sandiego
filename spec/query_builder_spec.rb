require File.join( File.dirname(__FILE__), '..', 'lib', 'carmen_sandiego.rb' )

describe CarmenSandiego do
  describe CarmenSandiego::QueryBuilder do
    describe "should have proper block-style accessors" do
      before(:each) do 
        @q = CarmenSandiego::QueryBuilder.new
      end

      it "should set radius" do 
        @q.radius 50
        @q.radius.should == 50
      end

      it "should set radius unit" do
        @q.radius_unit :km
        @q.radius_unit.should == :km
      end

      it "should set latitude" do
        @q.latitude 10
        @q.latitude.should == 10
        @q.lat.should == 10
      end

      it "should set longitude" do
        @q.longitude 10
        @q.longitude.should == 10
        @q.lng.should == 10
        @q.lon.should == 10
      end

      it "should add and remove include type" do
        @q.include_result_type :foo
        @q.result_types.should == [:foo]
        @q.exclude_result_type :foo
        @q.result_types.should == []
      end

      it "should set result types from an array" do
        @q.set_result_types [:foo, :bar]
        @q.result_types.should == [:foo, :bar]
      end
    end
  end
end

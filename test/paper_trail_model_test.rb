require File.dirname(__FILE__) + '/test_helper.rb'

class Widget < ActiveRecord::Base
  has_paper_trail
  has_one :wotsit
end

class FooWidget < Widget
  # Note we don't need to declare has_paper_trail here.
end

class Wotsit < ActiveRecord::Base
  belongs_to :widget
end


class HasPaperTrailModelTest < Test::Unit::TestCase
  load_schema

  context 'A new record' do
    setup { @widget = Widget.new }

    should 'not have any previous versions' do
      assert_equal [], @widget.versions
    end


    context 'which is then created' do
      setup { @widget.update_attributes :name => 'Henry' }

      should 'have one previous version' do
        assert_equal 1, @widget.versions.length
      end

      should 'be nil in its previous version' do
        assert_nil @widget.versions.first.object
        assert_nil @widget.versions.first.reify
      end

      should 'record the correct event' do
        assert_match /create/i, @widget.versions.first.event
      end


      context 'and then updated without any changes' do
        setup { @widget.save }

        should 'not have a new version' do
          assert_equal 1, @widget.versions.length
        end
      end


      context 'and then updated with changes' do
        setup { @widget.update_attributes :name => 'Harry' }

        should 'have two previous versions' do
          assert_equal 2, @widget.versions.length
        end

        should 'be available in its previous version' do
          assert_equal 'Harry', @widget.name
          assert_not_nil @widget.versions.last.object
          widget = @widget.versions.last.reify
          assert_equal 'Henry', widget.name
          assert_equal 'Harry', @widget.name
        end

        should 'have the same ID in its previous version' do
          assert_equal @widget.id, @widget.versions.last.reify.id
        end

        should 'record the correct event' do
          assert_match /update/i, @widget.versions.last.event
        end

        
        context 'and has one associated object' do
          setup { @wotsit = @widget.create_wotsit :name => 'John' }

          should 'not save the associated object when reifying' do
            assert_nil @widget.versions.last.reify.wotsit.id
          end

          should "preserve the associated object's values when reifying" do
            assert_equal @wotsit.attributes.reject{ |k,v| k == 'id' },
              @widget.versions.last.reify.wotsit.attributes.reject{ |k,v| k == 'id'}
          end
        end


        context 'and then destroyed' do
          setup { @widget.destroy }

          should 'have three previous versions' do
            assert_equal 3, @widget.versions.length
          end

          should 'be available in its previous version' do
            widget = @widget.versions.last.reify
            assert_equal @widget.id, widget.id
            assert_equal @widget.attributes, widget.attributes
          end

          should 'record the correct event' do
            assert_match /destroy/i, @widget.versions.last.event
          end
        end
      end
    end
  end


  # Test the serialisation and unserialisation.
  # TODO: binary
  context "A record's papertrail" do
    setup do
      @date_time = DateTime.now.utc
      @time = Time.now
      @date = Date.new 2009, 5, 29
      @widget = Widget.create :name        => 'Warble',
                              :a_text      => 'The quick brown fox',
                              :an_integer  => 42,
                              :a_float     => 153.01,
                              :a_decimal   => 2.71828,
                              :a_datetime  => @date_time,
                              :a_time      => @time,
                              :a_date      => @date,
                              :a_boolean   => true

      @widget.update_attributes :name      => nil,
                              :a_text      => nil,
                              :an_integer  => nil,
                              :a_float     => nil,
                              :a_decimal   => nil,
                              :a_datetime  => nil,
                              :a_time      => nil,
                              :a_date      => nil,
                              :a_boolean   => false
      @previous = @widget.versions.last.reify
    end

    should 'handle strings' do
      assert_equal 'Warble', @previous.name
    end

    should 'handle text' do
      assert_equal 'The quick brown fox', @previous.a_text
    end

    should 'handle integers' do
      assert_equal 42, @previous.an_integer
    end

    should 'handle floats' do
      assert_in_delta 153.01, @previous.a_float, 0.001
    end

    should 'handle decimals' do
      assert_in_delta 2.71828, @previous.a_decimal, 0.00001
    end

    should 'handle datetimes' do
      # Is there a better way to test equality of two datetimes?
      format = '%a, %d %b %Y %H:%M:%S %z' # :rfc822
      assert_equal @date_time.strftime(format), @previous.a_datetime.strftime(format)
    end

    should 'handle times' do
      assert_equal @time, @previous.a_time
    end

    should 'handle dates' do
      assert_equal @date, @previous.a_date
    end

    should 'handle booleans' do
      assert @previous.a_boolean
    end


    context "after a column is removed from the record's schema" do
      setup do
        change_schema
        Widget.reset_column_information
        assert_raise(NoMethodError) { Widget.new.sacrificial_column }
        @last = @widget.versions.last
      end

      should 'reify previous version' do
        assert_kind_of Widget, @last.reify
      end

      should 'restore all forward-compatible attributes' do
        format = '%a, %d %b %Y %H:%M:%S %z' # :rfc822
        assert_equal    'Warble',                    @last.reify.name
        assert_equal    'The quick brown fox',       @last.reify.a_text
        assert_equal    42,                          @last.reify.an_integer
        assert_in_delta 153.01,                      @last.reify.a_float,   0.001
        assert_in_delta 2.71828,                     @last.reify.a_decimal, 0.00001
        assert_equal    @date_time.strftime(format), @last.reify.a_datetime.strftime(format)
        assert_equal    @time,                       @last.reify.a_time
        assert_equal    @date,                       @last.reify.a_date
        assert          @last.reify.a_boolean
      end
    end
  end


  context 'A record' do
    setup { @widget = Widget.create :name => 'Zaphod' }

    context 'with its paper trail turned off' do
      setup do
        Widget.paper_trail_off
        @count = @widget.versions.length
      end

      teardown { Widget.paper_trail_on }

      context 'when updated' do
        setup { @widget.update_attributes :name => 'Beeblebrox' }

        should 'not add to its trail' do
          assert_equal @count, @widget.versions.length
        end
      end

      context 'and then its paper trail turned on' do
        setup { Widget.paper_trail_on }

        context 'when updated' do
          setup { @widget.update_attributes :name => 'Ford' }

          should 'add to its trail' do
            assert_equal @count + 1, @widget.versions.length
          end
        end
      end
    end
  end


  context 'A papertrail with somebody making changes' do
    setup do
      PaperTrail.whodunnit = 'Colonel Mustard'
      @widget = Widget.new :name => 'Fidget'
    end

    context 'when a record is created' do
      setup { @widget.save }

      should 'track who made the change' do
        assert_equal 'Colonel Mustard', @widget.versions.last.whodunnit
      end

      context 'when a record is updated' do
        setup { @widget.update_attributes :name => 'Rivet' }

        should 'track who made the change' do
          assert_equal 'Colonel Mustard', @widget.versions.last.whodunnit
        end

        context 'when a record is destroyed' do
          setup { @widget.destroy }

          should 'track who made the change' do
            assert_equal 'Colonel Mustard', @widget.versions.last.whodunnit
          end
        end
      end
    end
  end


  context 'A subclass' do
    setup do
      @foo = FooWidget.create
      @foo.update_attributes :name => 'Fooey'
    end

    should 'reify with the correct type' do
      thing = @foo.versions.last.reify
      assert_kind_of FooWidget, thing
    end
  end

end

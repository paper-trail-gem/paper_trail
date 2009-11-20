require File.dirname(__FILE__) + '/test_helper.rb'

class Widget < ActiveRecord::Base
  has_paper_trail
  has_one :wotsit
  has_many :fluxors, :order => :name
end

class FooWidget < Widget
end

class Wotsit < ActiveRecord::Base
  belongs_to :widget
end

class Fluxor < ActiveRecord::Base
  belongs_to :widget
end

class Article < ActiveRecord::Base
  has_paper_trail :ignore => [:title]
end


class HasPaperTrailModelTest < Test::Unit::TestCase
  load_schema

  context 'A record' do
    setup { @article = Article.create }
    
    context 'which updates an ignored column' do
      setup { @article.update_attributes :title => 'My first title' }
      should_not_change('the number of versions') { Version.count }
    end

    context 'which updates an ignored column and a non-ignored column' do
      setup { @article.update_attributes :title => 'My first title', :content => 'Some text here.' }
      should_change('the number of versions', :by => 1) { Version.count }
    end

  end

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
          setup do
            @wotsit = @widget.create_wotsit :name => 'John'
            @reified_widget = @widget.versions.last.reify
          end

          should 'copy the has_one association when reifying' do
            assert_equal @wotsit, @reified_widget.wotsit
          end
        end


        context 'and has many associated objects' do
          setup do
            @f0 = @widget.fluxors.create :name => 'f-zero'
            @f1 = @widget.fluxors.create :name => 'f-one'
            @reified_widget = @widget.versions.last.reify
          end

          should 'copy the has_many associations when reifying' do
            assert_equal @widget.fluxors.length, @reified_widget.fluxors.length
            assert_same_elements @widget.fluxors, @reified_widget.fluxors

            assert_equal @widget.versions.length, @reified_widget.versions.length
            assert_same_elements @widget.versions, @reified_widget.versions
          end
        end


        context 'and then destroyed' do
          setup do
            @fluxor = @widget.fluxors.create :name => 'flux'
            @widget.destroy
            @reified_widget = @widget.versions.last.reify
          end

          should 'record the correct event' do
            assert_match /destroy/i, @widget.versions.last.event
          end

          should 'have three previous versions' do
            assert_equal 3, @widget.versions.length
          end

          should 'be available in its previous version' do
            assert_equal @widget.id, @reified_widget.id
            assert_equal @widget.attributes, @reified_widget.attributes
          end

          should 'be re-creatable from its previous version' do
            assert @reified_widget.save
          end

          should 'restore its associations on its previous version' do
            @reified_widget.save
            assert_equal 1, @reified_widget.fluxors.length
          end
        end
      end
    end
  end


  # Test the serialisation and deserialisation.
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
      assert_equal @date_time.utc.strftime(format), @previous.a_datetime.utc.strftime(format)
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
        assert_equal    'Warble',                        @last.reify.name
        assert_equal    'The quick brown fox',           @last.reify.a_text
        assert_equal    42,                              @last.reify.an_integer
        assert_in_delta 153.01,                          @last.reify.a_float,   0.001
        assert_in_delta 2.71828,                         @last.reify.a_decimal, 0.00001
        assert_equal    @date_time.utc.strftime(format), @last.reify.a_datetime.utc.strftime(format)
        assert_equal    @time,                           @last.reify.a_time
        assert_equal    @date,                           @last.reify.a_date
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


    context 'when destroyed' do
      setup { @foo.destroy }

      should 'reify with the correct type' do
        thing = @foo.versions.last.reify
        assert_kind_of FooWidget, thing
      end
    end
  end


  context 'An item with versions' do
    setup do
      @widget = Widget.create :name => 'Widget'
      @widget.update_attributes :name => 'Fidget'
      @widget.update_attributes :name => 'Digit'
    end

    context 'on the first version' do
      setup { @version = @widget.versions.first }

      should 'have a nil previous version' do
        assert_nil @version.previous
      end

      should 'return the next version' do
        assert_equal @widget.versions[1], @version.next
      end

      should 'return the correct index' do
        assert_equal 0, @version.index
      end
    end

    context 'on the last version' do
      setup { @version = @widget.versions.last }

      should 'return the previous version' do
        assert_equal @widget.versions[@widget.versions.length - 2], @version.previous
      end

      should 'have a nil next version' do
        assert_nil @version.next
      end

      should 'return the correct index' do
        assert_equal @widget.versions.length - 1, @version.index
      end
    end
  end

end

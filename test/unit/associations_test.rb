require "test_helper"
require "time_travel_helper"

class AssociationsTest < ActiveSupport::TestCase
  CHAPTER_NAMES = [
    "Down the Rabbit-Hole",
    "The Pool of Tears",
    "A Caucus-Race and a Long Tale",
    "The Rabbit Sends in a Little Bill",
    "Advice from a Caterpillar",
    "Pig and Pepper",
    "A Mad Tea-Party",
    "The Queen's Croquet-Ground",
    "The Mock Turtle's Story",
    "The Lobster Quadrille",
    "Who Stole the Tarts?",
    "Alice's Evidence"
  ].freeze

  # These would have been done in test_helper.rb if using_mysql? is true
  unless using_mysql?
    if respond_to? :use_transactional_tests=
      self.use_transactional_tests = false
    else
      self.use_transactional_fixtures = false
    end
    setup { DatabaseCleaner.start }
  end

  teardown do
    Timecop.return
    # This would have been done in test_helper.rb if using_mysql? is true
    DatabaseCleaner.clean unless using_mysql?
  end

  context "a has_one association" do
    setup { @widget = Widget.create name: "widget_0" }

    context "before the associated was created" do
      setup do
        @widget.update_attributes name: "widget_1"
        @wotsit = @widget.create_wotsit name: "wotsit_0"
      end

      context "when reified" do
        setup { @widget_0 = @widget.versions.last.reify(has_one: true) }

        should "see the associated as it was at the time" do
          assert_nil @widget_0.wotsit
        end

        should "not persist changes to the live association" do
          assert_equal @wotsit, @widget.reload.wotsit
        end
      end
    end

    context "where the association is created between model versions" do
      setup do
        @wotsit = @widget.create_wotsit name: "wotsit_0"
        Timecop.travel 1.second.since
        @widget.update_attributes name: "widget_1"
      end

      context "when reified" do
        setup { @widget_0 = @widget.versions.last.reify(has_one: true) }

        should "see the associated as it was at the time" do
          assert_equal "wotsit_0", @widget_0.wotsit.name
        end

        should "not persist changes to the live association" do
          assert_equal @wotsit, @widget.reload.wotsit
        end
      end

      context "and then the associated is updated between model versions" do
        setup do
          @wotsit.update_attributes name: "wotsit_1"
          @wotsit.update_attributes name: "wotsit_2"
          Timecop.travel 1.second.since
          @widget.update_attributes name: "widget_2"
          @wotsit.update_attributes name: "wotsit_3"
        end

        context "when reified" do
          setup { @widget_1 = @widget.versions.last.reify(has_one: true) }

          should "see the associated as it was at the time" do
            assert_equal "wotsit_2", @widget_1.wotsit.name
          end

          should "not persist changes to the live association" do
            assert_equal "wotsit_3", @widget.reload.wotsit.name
          end
        end

        context "when reified opting out of has_one reification" do
          setup { @widget_1 = @widget.versions.last.reify(has_one: false) }

          should "see the associated as it is live" do
            assert_equal "wotsit_3", @widget_1.wotsit.name
          end
        end
      end

      context "and then the associated is destroyed" do
        setup do
          @wotsit.destroy
        end

        context "when reify" do
          setup { @widget_1 = @widget.versions.last.reify(has_one: true) }

          should "see the associated as it was at the time" do
            assert_equal @wotsit, @widget_1.wotsit
          end

          should "not persist changes to the live association" do
            assert_nil @widget.reload.wotsit
          end
        end

        context "and then the model is updated" do
          setup do
            Timecop.travel 1.second.since
            @widget.update_attributes name: "widget_3"
          end

          context "when reified" do
            setup { @widget_2 = @widget.versions.last.reify(has_one: true) }

            should "see the associated as it was at the time" do
              assert_nil @widget_2.wotsit
            end
          end
        end
      end
    end
  end

  context "a has_many association" do
    setup { @customer = Customer.create name: "customer_0" }

    context "updated before the associated was created" do
      setup do
        @customer.update_attributes! name: "customer_1"
        @customer.orders.create! order_date: Date.today
      end

      context "when reified" do
        setup { @customer_0 = @customer.versions.last.reify(has_many: true) }

        should "see the associated as it was at the time" do
          assert_equal [], @customer_0.orders
        end

        should "not persist changes to the live association" do
          assert_not_equal [], @customer.orders.reload
        end
      end

      context "when reified with option mark_for_destruction" do
        should "mark the associated for destruction" do
          @customer_0 = @customer.versions.last.reify(
            has_many: true,
            mark_for_destruction: true
          )
          assert_equal [true], @customer_0.orders.map(&:marked_for_destruction?)
        end
      end
    end

    context "where the association is created between model versions" do
      setup do
        @order = @customer.orders.create! order_date: "order_date_0"
        Timecop.travel 1.second.since
        @customer.update_attributes name: "customer_1"
      end

      context "when reified" do
        setup { @customer_0 = @customer.versions.last.reify(has_many: true) }

        should "see the associated as it was at the time" do
          assert_equal ["order_date_0"], @customer_0.orders.map(&:order_date)
        end
      end

      context "and then a nested has_many association is created" do
        setup do
          @order.line_items.create! product: "product_0"
        end

        context "when reified" do
          setup { @customer_0 = @customer.versions.last.reify(has_many: true) }

          should "see the live version of the nested association" do
            assert_equal ["product_0"], @customer_0.orders.first.line_items.map(&:product)
          end
        end
      end

      context "and then the associated is updated between model versions" do
        setup do
          @order.update_attributes order_date: "order_date_1"
          @order.update_attributes order_date: "order_date_2"
          Timecop.travel 1.second.since
          @customer.update_attributes name: "customer_2"
          @order.update_attributes order_date: "order_date_3"
        end

        context "when reified" do
          setup { @customer_1 = @customer.versions.last.reify(has_many: true) }

          should "see the associated as it was at the time" do
            assert_equal ["order_date_2"], @customer_1.orders.map(&:order_date)
          end

          should "not persist changes to the live association" do
            assert_equal ["order_date_3"], @customer.orders.reload.map(&:order_date)
          end
        end

        context "when reified opting out of has_many reification" do
          setup { @customer_1 = @customer.versions.last.reify(has_many: false) }

          should "see the associated as it is live" do
            assert_equal ["order_date_3"], @customer_1.orders.map(&:order_date)
          end
        end

        context "and then the associated is destroyed" do
          setup do
            @order.destroy
          end

          context "when reified" do
            setup { @customer_1 = @customer.versions.last.reify(has_many: true) }

            should "see the associated as it was at the time" do
              assert_equal ["order_date_2"], @customer_1.orders.map(&:order_date)
            end

            should "not persist changes to the live association" do
              assert_equal [], @customer.orders.reload
            end
          end
        end
      end

      context "and then the associated is destroyed" do
        setup do
          @order.destroy
        end

        context "when reified" do
          setup { @customer_1 = @customer.versions.last.reify(has_many: true) }

          should "see the associated as it was at the time" do
            assert_equal [@order.order_date], @customer_1.orders.map(&:order_date)
          end

          should "not persist changes to the live association" do
            assert_equal [], @customer.orders.reload
          end
        end
      end

      context "and then the associated is destroyed between model versions" do
        setup do
          @order.destroy
          Timecop.travel 1.second.since
          @customer.update_attributes name: "customer_2"
        end

        context "when reified" do
          setup { @customer_1 = @customer.versions.last.reify(has_many: true) }

          should "see the associated as it was at the time" do
            assert_equal [], @customer_1.orders
          end
        end
      end

      context "and then another association is added" do
        setup do
          @customer.orders.create! order_date: "order_date_1"
        end

        context "when reified" do
          setup { @customer_0 = @customer.versions.last.reify(has_many: true) }

          should "see the associated as it was at the time" do
            assert_equal ["order_date_0"], @customer_0.orders.map(&:order_date)
          end

          should "not persist changes to the live association" do
            assert_equal %w(order_date_0 order_date_1),
              @customer.orders.reload.map(&:order_date).sort
          end
        end

        context "when reified with option mark_for_destruction" do
          should "mark the newly associated for destruction" do
            @customer_0 = @customer.versions.last.reify(
              has_many: true,
              mark_for_destruction: true
            )
            assert @customer_0.
              orders.
              detect { |o| o.order_date == "order_date_1" }.
              marked_for_destruction?
          end
        end
      end
    end
  end

  context "has_many through associations" do
    context "Books, Authors, and Authorships" do
      setup { @book = Book.create title: "book_0" }

      context "updated before the associated was created" do
        setup do
          @book.update_attributes! title: "book_1"
          @book.authors.create! name: "author_0"
        end

        context "when reified" do
          setup { @book_0 = @book.versions.last.reify(has_many: true) }

          should "see the associated as it was at the time" do
            assert_equal [], @book_0.authors
          end

          should "not persist changes to the live association" do
            assert_equal ["author_0"], @book.authors.reload.map(&:name)
          end
        end

        context "when reified with option mark_for_destruction" do
          setup do
            @book_0 = @book.versions.last.reify(
              has_many: true,
              mark_for_destruction: true
            )
          end

          should "mark the associated for destruction" do
            assert_equal [true], @book_0.authors.map(&:marked_for_destruction?)
          end

          should "mark the associated-through for destruction" do
            assert_equal [true], @book_0.authorships.map(&:marked_for_destruction?)
          end
        end
      end

      context "updated before it is associated with an existing one" do
        setup do
          person_existing = Person.create(name: "person_existing")
          Timecop.travel 1.second.since
          @book.update_attributes! title: "book_1"
          @book.authors << person_existing
        end

        context "when reified" do
          setup do
            @book_0 = @book.versions.last.reify(has_many: true)
          end

          should "see the associated as it was at the time" do
            assert_equal [], @book_0.authors
          end
        end

        context "when reified with option mark_for_destruction" do
          setup do
            @book_0 = @book.versions.last.reify(
              has_many: true,
              mark_for_destruction: true
            )
          end

          should "not mark the associated for destruction" do
            assert_equal [false], @book_0.authors.map(&:marked_for_destruction?)
          end

          should "mark the associated-through for destruction" do
            assert_equal [true], @book_0.authorships.map(&:marked_for_destruction?)
          end
        end
      end

      context "where the association is created between model versions" do
        setup do
          @author = @book.authors.create! name: "author_0"
          @person_existing = Person.create(name: "person_existing")
          Timecop.travel 1.second.since
          @book.update_attributes! title: "book_1"
        end

        context "when reified" do
          setup { @book_0 = @book.versions.last.reify(has_many: true) }

          should "see the associated as it was at the time" do
            assert_equal ["author_0"], @book_0.authors.map(&:name)
          end
        end

        context "and then the associated is updated between model versions" do
          setup do
            @author.update_attributes name: "author_1"
            @author.update_attributes name: "author_2"
            Timecop.travel 1.second.since
            @book.update_attributes title: "book_2"
            @author.update_attributes name: "author_3"
          end

          context "when reified" do
            setup { @book_1 = @book.versions.last.reify(has_many: true) }

            should "see the associated as it was at the time" do
              assert_equal ["author_2"], @book_1.authors.map(&:name)
            end

            should "not persist changes to the live association" do
              assert_equal ["author_3"], @book.authors.reload.map(&:name)
            end
          end

          context "when reified opting out of has_many reification" do
            setup { @book_1 = @book.versions.last.reify(has_many: false) }

            should "see the associated as it is live" do
              assert_equal ["author_3"], @book_1.authors.map(&:name)
            end
          end
        end

        context "and then the associated is destroyed" do
          setup do
            @author.destroy
          end

          context "when reified" do
            setup { @book_1 = @book.versions.last.reify(has_many: true) }

            should "see the associated as it was at the time" do
              assert_equal [@author.name], @book_1.authors.map(&:name)
            end

            should "not persist changes to the live association" do
              assert_equal [], @book.authors.reload
            end
          end
        end

        context "and then the associated is destroyed between model versions" do
          setup do
            @author.destroy
            Timecop.travel 1.second.since
            @book.update_attributes title: "book_2"
          end

          context "when reified" do
            setup { @book_1 = @book.versions.last.reify(has_many: true) }

            should "see the associated as it was at the time" do
              assert_equal [], @book_1.authors
            end
          end
        end

        context "and then the associated is dissociated between model versions" do
          setup do
            @book.authors = []
            Timecop.travel 1.second.since
            @book.update_attributes title: "book_2"
          end

          context "when reified" do
            setup { @book_1 = @book.versions.last.reify(has_many: true) }

            should "see the associated as it was at the time" do
              assert_equal [], @book_1.authors
            end
          end
        end

        context "and then another associated is created" do
          setup do
            @book.authors.create! name: "author_1"
          end

          context "when reified" do
            setup { @book_0 = @book.versions.last.reify(has_many: true) }

            should "only see the first associated" do
              assert_equal ["author_0"], @book_0.authors.map(&:name)
            end

            should "not persist changes to the live association" do
              assert_equal %w(author_0 author_1), @book.authors.reload.map(&:name)
            end
          end

          context "when reified with option mark_for_destruction" do
            setup do
              @book_0 = @book.versions.last.reify(
                has_many: true,
                mark_for_destruction: true
              )
            end

            should "mark the newly associated for destruction" do
              assert @book_0.
                authors.
                detect { |a| a.name == "author_1" }.
                marked_for_destruction?
            end

            should "mark the newly associated-through for destruction" do
              assert @book_0.
                authorships.
                detect { |as| as.author.name == "author_1" }.
                marked_for_destruction?
            end
          end
        end

        context "and then an existing one is associated" do
          setup do
            @book.authors << @person_existing
          end

          context "when reified" do
            setup { @book_0 = @book.versions.last.reify(has_many: true) }

            should "only see the first associated" do
              assert_equal ["author_0"], @book_0.authors.map(&:name)
            end

            should "not persist changes to the live association" do
              assert_equal %w(author_0 person_existing), @book.authors.reload.map(&:name).sort
            end
          end

          context "when reified with option mark_for_destruction" do
            setup do
              @book_0 = @book.versions.last.reify(
                has_many: true,
                mark_for_destruction: true
              )
            end

            should "not mark the newly associated for destruction" do
              assert !@book_0.
                authors.
                detect { |a| a.name == "person_existing" }.
                marked_for_destruction?
            end

            should "mark the newly associated-through for destruction" do
              assert @book_0.
                authorships.
                detect { |as| as.author.name == "person_existing" }.
                marked_for_destruction?
            end
          end
        end
      end

      context "updated before the associated without paper_trail was created" do
        setup do
          @book.update_attributes! title: "book_1"
          @book.editors.create! name: "editor_0"
        end

        context "when reified" do
          setup { @book_0 = @book.versions.last.reify(has_many: true) }

          should "see the live association" do
            assert_equal ["editor_0"], @book_0.editors.map(&:name)
          end
        end
      end
    end

    context "Chapters, Sections, Paragraphs, Quotations, and Citations" do
      setup { @chapter = Chapter.create(name: CHAPTER_NAMES[0]) }

      context "before any associations are created" do
        setup do
          @chapter.update_attributes(name: CHAPTER_NAMES[1])
        end

        should "not reify any associations" do
          chapter_v1 = @chapter.versions[1].reify(has_many: true)
          assert_equal CHAPTER_NAMES[0], chapter_v1.name
          assert_equal [], chapter_v1.sections
          assert_equal [], chapter_v1.paragraphs
        end
      end

      context "after the first has_many through relationship is created" do
        setup do
          assert_equal 1, @chapter.versions.size
          @chapter.update_attributes name: CHAPTER_NAMES[1]
          assert_equal 2, @chapter.versions.size

          Timecop.travel 1.second.since
          @chapter.sections.create name: "section 1"
          Timecop.travel 1.second.since
          @chapter.sections.first.update_attributes name: "section 2"
          Timecop.travel 1.second.since
          @chapter.update_attributes name: CHAPTER_NAMES[2]
          assert_equal 3, @chapter.versions.size

          Timecop.travel 1.second.since
          @chapter.sections.first.update_attributes name: "section 3"
        end

        context "version 1" do
          should "have no sections" do
            chapter_v1 = @chapter.versions[1].reify(has_many: true)
            assert_equal [], chapter_v1.sections
          end
        end

        context "version 2" do
          should "have one section" do
            chapter_v2 = @chapter.versions[2].reify(has_many: true)
            assert_equal 1, chapter_v2.sections.size

            # Shows the value of the section as it was before
            # the chapter was updated.
            assert_equal ["section 2"], chapter_v2.sections.map(&:name)

            # Shows the value of the chapter as it was before
            assert_equal CHAPTER_NAMES[1], chapter_v2.name
          end
        end

        context "version 2, before the section was destroyed" do
          setup do
            @chapter.update_attributes name: CHAPTER_NAMES[2]
            Timecop.travel 1.second.since
            @chapter.sections.destroy_all
            Timecop.travel 1.second.since
          end

          should "have the one section" do
            chapter_v2 = @chapter.versions[2].reify(has_many: true)
            assert_equal ["section 2"], chapter_v2.sections.map(&:name)
          end
        end

        context "version 3, after the section was destroyed" do
          setup do
            @chapter.sections.destroy_all
            Timecop.travel 1.second.since
            @chapter.update_attributes name: CHAPTER_NAMES[3]
            Timecop.travel 1.second.since
          end

          should "have no sections" do
            chapter_v3 = @chapter.versions[3].reify(has_many: true)
            assert_equal 0, chapter_v3.sections.size
          end
        end

        context "after creating a paragraph" do
          setup do
            assert_equal 3, @chapter.versions.size
            @section = @chapter.sections.first
            Timecop.travel 1.second.since
            @paragraph = @section.paragraphs.create name: "para1"
          end

          context "new chapter version" do
            should "have one paragraph" do
              initial_section_name = @section.name
              initial_paragraph_name = @paragraph.name
              Timecop.travel 1.second.since
              @chapter.update_attributes name: CHAPTER_NAMES[4]
              assert_equal 4, @chapter.versions.size
              Timecop.travel 1.second.since
              @paragraph.update_attributes name: "para3"
              chapter_v3 = @chapter.versions[3].reify(has_many: true)
              assert_equal [initial_section_name], chapter_v3.sections.map(&:name)
              paragraphs = chapter_v3.sections.first.paragraphs
              assert_equal 1, paragraphs.size
              assert_equal [initial_paragraph_name], paragraphs.map(&:name)
            end
          end

          context "the version before a section is destroyed" do
            should "have the section and paragraph" do
              Timecop.travel 1.second.since
              @chapter.update_attributes(name: CHAPTER_NAMES[3])
              assert_equal 4, @chapter.versions.size
              Timecop.travel 1.second.since
              @section.destroy
              assert_equal 4, @chapter.versions.size
              chapter_v3 = @chapter.versions[3].reify(has_many: true)
              assert_equal CHAPTER_NAMES[2], chapter_v3.name
              assert_equal [@section], chapter_v3.sections
              assert_equal [@paragraph], chapter_v3.sections[0].paragraphs
              assert_equal [@paragraph], chapter_v3.paragraphs
            end
          end

          context "the version after a section is destroyed" do
            should "not have any sections or paragraphs" do
              @section.destroy
              Timecop.travel 1.second.since
              @chapter.update_attributes(name: CHAPTER_NAMES[5])
              assert_equal 4, @chapter.versions.size
              chapter_v3 = @chapter.versions[3].reify(has_many: true)
              assert_equal 0, chapter_v3.sections.size
              assert_equal 0, chapter_v3.paragraphs.size
            end
          end

          context "the version before a paragraph is destroyed" do
            should "have the one paragraph" do
              initial_paragraph_name = @section.paragraphs.first.name
              Timecop.travel 1.second.since
              @chapter.update_attributes(name: CHAPTER_NAMES[5])
              Timecop.travel 1.second.since
              @paragraph.destroy
              chapter_v3 = @chapter.versions[3].reify(has_many: true)
              paragraphs = chapter_v3.sections.first.paragraphs
              assert_equal 1, paragraphs.size
              assert_equal initial_paragraph_name, paragraphs.first.name
            end
          end

          context "the version after a paragraph is destroyed" do
            should "have no paragraphs" do
              @paragraph.destroy
              Timecop.travel 1.second.since
              @chapter.update_attributes(name: CHAPTER_NAMES[5])
              chapter_v3 = @chapter.versions[3].reify(has_many: true)
              assert_equal 0, chapter_v3.paragraphs.size
              assert_equal [], chapter_v3.sections.first.paragraphs
            end
          end
        end
      end

      context "a chapter with one paragraph and one citation" do
        should "reify paragraphs and citations" do
          chapter = Chapter.create(name: CHAPTER_NAMES[0])
          section = Section.create(name: "Section One", chapter: chapter)
          paragraph = Paragraph.create(name: "Paragraph One", section: section)
          quotation = Quotation.create(chapter: chapter)
          citation = Citation.create(quotation: quotation)
          Timecop.travel 1.second.since
          chapter.update_attributes(name: CHAPTER_NAMES[1])
          assert_equal 2, chapter.versions.count
          paragraph.destroy
          citation.destroy
          reified = chapter.versions[1].reify(has_many: true)
          assert_equal [paragraph], reified.sections.first.paragraphs
          assert_equal [citation], reified.quotations.first.citations
        end
      end
    end
  end

  context "belongs_to associations" do
    context "Wotsit and Widget" do
      setup { @widget = Widget.create(name: "widget_0") }

      context "where the association is created between model versions" do
        setup do
          @wotsit = Wotsit.create(name: "wotsit_0")
          Timecop.travel 1.second.since
          @wotsit.update_attributes widget_id: @widget.id, name: "wotsit_1"
        end

        context "when reified" do
          setup { @wotsit_0 = @wotsit.versions.last.reify(belongs_to: true) }

          should "see the associated as it was at the time" do
            assert_nil @wotsit_0.widget
          end

          should "not persist changes to the live association" do
            assert_equal @widget, @wotsit.reload.widget
          end
        end

        context "and then the associated is updated between model versions" do
          setup do
            @widget.update_attributes name: "widget_1"
            @widget.update_attributes name: "widget_2"
            Timecop.travel 1.second.since
            @wotsit.update_attributes name: "wotsit_2"
            @widget.update_attributes name: "widget_3"
          end

          context "when reified" do
            setup { @wotsit_1 = @wotsit.versions.last.reify(belongs_to: true) }

            should "see the associated as it was at the time" do
              assert_equal "widget_2", @wotsit_1.widget.name
            end

            should "not persist changes to the live association" do
              assert_equal "widget_3", @wotsit.reload.widget.name
            end
          end

          context "when reified opting out of belongs_to reification" do
            setup { @wotsit_1 = @wotsit.versions.last.reify(belongs_to: false) }

            should "see the associated as it is live" do
              assert_equal "widget_3", @wotsit_1.widget.name
            end
          end
        end

        context "and then the associated is destroyed" do
          setup do
            @wotsit.update_attributes name: "wotsit_2"
            @widget.destroy
          end

          context "when reified" do
            setup { @wotsit_2 = @wotsit.versions.last.reify(belongs_to: true) }

            should "see the associated as it was at the time" do
              assert_equal @widget, @wotsit_2.widget
            end

            should "not persist changes to the live association" do
              assert_nil @wotsit.reload.widget
            end
          end

          context "and then the model is updated" do
            setup do
              Timecop.travel 1.second.since
              @wotsit.update_attributes name: "wotsit_3"
            end

            context "when reified" do
              setup { @wotsit_2 = @wotsit.versions.last.reify(belongs_to: true) }

              should "see the associated as it was the time" do
                assert_nil @wotsit_2.widget
              end
            end
          end
        end
      end

      context "where the association is changed between model versions" do
        setup do
          @wotsit = @widget.create_wotsit(name: "wotsit_0")
          Timecop.travel 1.second.since
          @new_widget = Widget.create(name: "new_widget")
          @wotsit.update_attributes(widget_id: @new_widget.id, name: "wotsit_1")
        end

        context "when reified" do
          setup { @wotsit_0 = @wotsit.versions.last.reify(belongs_to: true) }

          should "see the association as it was at the time" do
            assert_equal "widget_0", @wotsit_0.widget.name
          end

          should "not persist changes to the live association" do
            assert_equal @new_widget, @wotsit.reload.widget
          end
        end

        context "when reified with option mark_for_destruction" do
          setup do
            @wotsit_0 = @wotsit.versions.last.
              reify(belongs_to: true, mark_for_destruction: true)
          end

          should "should not mark the new associated for destruction" do
            assert_equal false, @new_widget.marked_for_destruction?
          end
        end
      end
    end
  end

  context "has_and_belongs_to_many associations" do
    context "foo and bar" do
      setup do
        @foo = FooHabtm.create(name: "foo")
        Timecop.travel 1.second.since
      end

      context "where the association is created between model versions" do
        setup do
          @foo.update_attributes(name: "foo1", bar_habtms: [BarHabtm.create(name: "bar")])
        end

        context "when reified" do
          setup { @reified = @foo.versions.last.reify(has_and_belongs_to_many: true) }

          should "see the associated as it was at the time" do
            assert_equal 0, @reified.bar_habtms.length
          end

          should "not persist changes to the live association" do
            assert_not_equal @reified.bar_habtms, @foo.reload.bar_habtms
          end
        end
      end

      context "where the association is changed between model versions" do
        setup do
          @foo.update_attributes(name: "foo2", bar_habtms: [BarHabtm.create(name: "bar2")])
          Timecop.travel 1.second.since
          @foo.update_attributes(name: "foo3", bar_habtms: [BarHabtm.create(name: "bar3")])
        end

        context "when reified" do
          setup { @reified = @foo.versions.last.reify(has_and_belongs_to_many: true) }

          should "see the association as it was at the time" do
            assert_equal "bar2", @reified.bar_habtms.first.name
          end

          should "not persist changes to the live association" do
            assert_not_equal @reified.bar_habtms.first, @foo.reload.bar_habtms.first
          end
        end

        context "when reified with has_and_belongs_to_many: false" do
          setup { @reified = @foo.versions.last.reify }

          should "see the association as it is now" do
            assert_equal "bar3", @reified.bar_habtms.first.name
          end
        end
      end

      context "where the association is destroyed between model versions" do
        setup do
          @foo.update_attributes(name: "foo2", bar_habtms: [BarHabtm.create(name: "bar2")])
          Timecop.travel 1.second.since
          @foo.update_attributes(name: "foo3", bar_habtms: [])
        end

        context "when reified" do
          setup { @reified = @foo.versions.last.reify(has_and_belongs_to_many: true) }

          should "see the association as it was at the time" do
            assert_equal "bar2", @reified.bar_habtms.first.name
          end

          should "not persist changes to the live association" do
            assert_not_equal @reified.bar_habtms.first, @foo.reload.bar_habtms.first
          end
        end
      end

      context "where the unassociated model changes" do
        setup do
          @bar = BarHabtm.create(name: "bar2")
          @foo.update_attributes(name: "foo2", bar_habtms: [@bar])
          Timecop.travel 1.second.since
          @foo.update_attributes(name: "foo3", bar_habtms: [BarHabtm.create(name: "bar4")])
          Timecop.travel 1.second.since
          @bar.update_attributes(name: "bar3")
        end

        context "when reified" do
          setup { @reified = @foo.versions.last.reify(has_and_belongs_to_many: true) }

          should "see the association as it was at the time" do
            assert_equal "bar2", @reified.bar_habtms.first.name
          end

          should "not persist changes to the live association" do
            assert_not_equal @reified.bar_habtms.first, @foo.reload.bar_habtms.first
          end
        end
      end
    end

    context "updated via nested attributes" do
      setup do
        @foo = FooHabtm.create(
          name: "foo",
          bar_habtms_attributes: [{ name: "bar" }]
        )
        Timecop.travel 1.second.since
        @foo.update_attributes(
          name: "foo2",
          bar_habtms_attributes: [{ id: @foo.bar_habtms.first.id, name: "bar2" }]
        )

        @reified = @foo.versions.last.reify(has_and_belongs_to_many: true)
      end

      should "see the associated object as it was at the time" do
        assert_equal "bar", @reified.bar_habtms.first.name
      end

      should "not persist changes to the live object" do
        assert_not_equal @reified.bar_habtms.first.name, @foo.reload.bar_habtms.first.name
      end
    end
  end
end

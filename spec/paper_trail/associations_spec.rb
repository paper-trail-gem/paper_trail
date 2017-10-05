require "spec_helper"

RSpec.describe(::PaperTrail, versioning: true) do
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

  after do
    Timecop.return
  end

  context "a has_one association" do
    before { @widget = Widget.create(name: "widget_0") }

    context "before the associated was created" do
      before do
        @widget.update_attributes(name: "widget_1")
        @wotsit = @widget.create_wotsit(name: "wotsit_0")
      end

      context "when reified" do
        before { @widget0 = @widget.versions.last.reify(has_one: true) }

        it "see the associated as it was at the time" do
          expect(@widget0.wotsit).to be_nil
        end

        it "not persist changes to the live association" do
          expect(@widget.reload.wotsit).to(eq(@wotsit))
        end
      end
    end

    context "where the association is created between model versions" do
      before do
        @wotsit = @widget.create_wotsit(name: "wotsit_0")
        Timecop.travel(1.second.since)
        @widget.update_attributes(name: "widget_1")
      end

      context "when reified" do
        before { @widget0 = @widget.versions.last.reify(has_one: true) }

        it "see the associated as it was at the time" do
          expect(@widget0.wotsit.name).to(eq("wotsit_0"))
        end

        it "not persist changes to the live association" do
          expect(@widget.reload.wotsit).to(eq(@wotsit))
        end
      end

      context "and then the associated is updated between model versions" do
        before do
          @wotsit.update_attributes(name: "wotsit_1")
          @wotsit.update_attributes(name: "wotsit_2")
          Timecop.travel(1.second.since)
          @widget.update_attributes(name: "widget_2")
          @wotsit.update_attributes(name: "wotsit_3")
        end

        context "when reified" do
          before { @widget1 = @widget.versions.last.reify(has_one: true) }

          it "see the associated as it was at the time" do
            expect(@widget1.wotsit.name).to(eq("wotsit_2"))
          end

          it "not persist changes to the live association" do
            expect(@widget.reload.wotsit.name).to(eq("wotsit_3"))
          end
        end

        context "when reified opting out of has_one reification" do
          before { @widget1 = @widget.versions.last.reify(has_one: false) }

          it "see the associated as it is live" do
            expect(@widget1.wotsit.name).to(eq("wotsit_3"))
          end
        end
      end

      context "and then the associated is destroyed" do
        before { @wotsit.destroy }

        context "when reify" do
          before { @widget1 = @widget.versions.last.reify(has_one: true) }

          it "see the associated as it was at the time" do
            expect(@widget1.wotsit).to(eq(@wotsit))
          end

          it "not persist changes to the live association" do
            expect(@widget.reload.wotsit).to be_nil
          end
        end

        context "and then the model is updated" do
          before do
            Timecop.travel(1.second.since)
            @widget.update_attributes(name: "widget_3")
          end

          context "when reified" do
            before { @widget2 = @widget.versions.last.reify(has_one: true) }

            it "see the associated as it was at the time" do
              expect(@widget2.wotsit).to be_nil
            end
          end
        end
      end
    end
  end

  context "a has_many association" do
    before { @customer = Customer.create(name: "customer_0") }

    context "updated before the associated was created" do
      before do
        @customer.update_attributes!(name: "customer_1")
        @customer.orders.create!(order_date: Date.today)
      end

      context "when reified" do
        before { @customer0 = @customer.versions.last.reify(has_many: true) }

        it "see the associated as it was at the time" do
          expect(@customer0.orders).to(eq([]))
        end

        it "not persist changes to the live association" do
          expect(@customer.orders.reload).not_to(eq([]))
        end
      end

      context "when reified with option mark_for_destruction" do
        it "mark the associated for destruction" do
          @customer0 = @customer.versions.last.reify(has_many: true, mark_for_destruction: true)
          expect(@customer0.orders.map(&:marked_for_destruction?)).to(eq([true]))
        end
      end
    end

    context "where the association is created between model versions" do
      before do
        @order = @customer.orders.create!(order_date: "order_date_0")
        Timecop.travel(1.second.since)
        @customer.update_attributes(name: "customer_1")
      end

      context "when reified" do
        before { @customer0 = @customer.versions.last.reify(has_many: true) }

        it "see the associated as it was at the time" do
          expect(@customer0.orders.map(&:order_date)).to(eq(["order_date_0"]))
        end
      end

      context "and then a nested has_many association is created" do
        before { @order.line_items.create!(product: "product_0") }

        context "when reified" do
          before { @customer0 = @customer.versions.last.reify(has_many: true) }

          it "see the live version of the nested association" do
            expect(@customer0.orders.first.line_items.map(&:product)).to(eq(["product_0"]))
          end
        end
      end

      context "and then the associated is updated between model versions" do
        before do
          @order.update_attributes(order_date: "order_date_1")
          @order.update_attributes(order_date: "order_date_2")
          Timecop.travel(1.second.since)
          @customer.update_attributes(name: "customer_2")
          @order.update_attributes(order_date: "order_date_3")
        end

        context "when reified" do
          before { @customer1 = @customer.versions.last.reify(has_many: true) }

          it "see the associated as it was at the time" do
            expect(@customer1.orders.map(&:order_date)).to(eq(["order_date_2"]))
          end

          it "not persist changes to the live association" do
            expect(@customer.orders.reload.map(&:order_date)).to(eq(["order_date_3"]))
          end
        end

        context "when reified opting out of has_many reification" do
          before { @customer1 = @customer.versions.last.reify(has_many: false) }

          it "see the associated as it is live" do
            expect(@customer1.orders.map(&:order_date)).to(eq(["order_date_3"]))
          end
        end

        context "and then the associated is destroyed" do
          before { @order.destroy }

          context "when reified" do
            before { @customer1 = @customer.versions.last.reify(has_many: true) }

            it "see the associated as it was at the time" do
              expect(@customer1.orders.map(&:order_date)).to(eq(["order_date_2"]))
            end

            it "not persist changes to the live association" do
              expect(@customer.orders.reload).to(eq([]))
            end
          end
        end
      end

      context "and then the associated is destroyed" do
        before { @order.destroy }

        context "when reified" do
          before { @customer1 = @customer.versions.last.reify(has_many: true) }

          it "see the associated as it was at the time" do
            expect(@customer1.orders.map(&:order_date)).to(eq([@order.order_date]))
          end

          it "not persist changes to the live association" do
            expect(@customer.orders.reload).to(eq([]))
          end
        end
      end

      context "and then the associated is destroyed between model versions" do
        before do
          @order.destroy
          Timecop.travel(1.second.since)
          @customer.update_attributes(name: "customer_2")
        end

        context "when reified" do
          before { @customer1 = @customer.versions.last.reify(has_many: true) }

          it "see the associated as it was at the time" do
            expect(@customer1.orders).to(eq([]))
          end
        end
      end

      context "and then another association is added" do
        before { @customer.orders.create!(order_date: "order_date_1") }

        context "when reified" do
          before { @customer0 = @customer.versions.last.reify(has_many: true) }

          it "see the associated as it was at the time" do
            expect(@customer0.orders.map(&:order_date)).to(eq(["order_date_0"]))
          end

          it "not persist changes to the live association" do
            expect(
              @customer.orders.reload.map(&:order_date)
            ).to match_array(%w[order_date_0 order_date_1])
          end
        end

        context "when reified with option mark_for_destruction" do
          it "mark the newly associated for destruction" do
            @customer0 = @customer.versions.last.reify(has_many: true, mark_for_destruction: true)
            order = @customer0.orders.detect { |o| o.order_date == "order_date_1" }
            expect(order).to be_marked_for_destruction
          end
        end
      end
    end
  end

  context "has_many through associations" do
    context "Books, Authors, and Authorships" do
      before { @book = Book.create(title: "book_0") }

      context "updated before the associated was created" do
        before do
          @book.update_attributes!(title: "book_1")
          @book.authors.create!(name: "author_0")
        end

        context "when reified" do
          before { @book0 = @book.versions.last.reify(has_many: true) }

          it "see the associated as it was at the time" do
            expect(@book0.authors).to(eq([]))
          end

          it "not persist changes to the live association" do
            expect(@book.authors.reload.map(&:name)).to(eq(["author_0"]))
          end
        end

        context "when reified with option mark_for_destruction" do
          before do
            @book0 = @book.versions.last.reify(has_many: true, mark_for_destruction: true)
          end

          it "mark the associated for destruction" do
            expect(@book0.authors.map(&:marked_for_destruction?)).to(eq([true]))
          end

          it "mark the associated-through for destruction" do
            expect(@book0.authorships.map(&:marked_for_destruction?)).to(eq([true]))
          end
        end
      end

      context "updated before it is associated with an existing one" do
        before do
          person_existing = Person.create(name: "person_existing")
          Timecop.travel(1.second.since)
          @book.update_attributes!(title: "book_1")
          (@book.authors << person_existing)
        end

        context "when reified" do
          before { @book0 = @book.versions.last.reify(has_many: true) }

          it "see the associated as it was at the time" do
            expect(@book0.authors).to(eq([]))
          end
        end

        context "when reified with option mark_for_destruction" do
          before do
            @book0 = @book.versions.last.reify(has_many: true, mark_for_destruction: true)
          end

          it "not mark the associated for destruction" do
            expect(@book0.authors.map(&:marked_for_destruction?)).to(eq([false]))
          end

          it "mark the associated-through for destruction" do
            expect(@book0.authorships.map(&:marked_for_destruction?)).to(eq([true]))
          end
        end
      end

      context "where the association is created between model versions" do
        before do
          @author = @book.authors.create!(name: "author_0")
          @person_existing = Person.create(name: "person_existing")
          Timecop.travel(1.second.since)
          @book.update_attributes!(title: "book_1")
        end

        context "when reified" do
          before { @book0 = @book.versions.last.reify(has_many: true) }

          it "see the associated as it was at the time" do
            expect(@book0.authors.map(&:name)).to(eq(["author_0"]))
          end
        end

        context "and then the associated is updated between model versions" do
          before do
            @author.update_attributes(name: "author_1")
            @author.update_attributes(name: "author_2")
            Timecop.travel(1.second.since)
            @book.update_attributes(title: "book_2")
            @author.update_attributes(name: "author_3")
          end

          context "when reified" do
            before { @book1 = @book.versions.last.reify(has_many: true) }

            it "see the associated as it was at the time" do
              expect(@book1.authors.map(&:name)).to(eq(["author_2"]))
            end

            it "not persist changes to the live association" do
              expect(@book.authors.reload.map(&:name)).to(eq(["author_3"]))
            end
          end

          context "when reified opting out of has_many reification" do
            before { @book1 = @book.versions.last.reify(has_many: false) }

            it "see the associated as it is live" do
              expect(@book1.authors.map(&:name)).to(eq(["author_3"]))
            end
          end
        end

        context "and then the associated is destroyed" do
          before { @author.destroy }

          context "when reified" do
            before { @book1 = @book.versions.last.reify(has_many: true) }

            it "see the associated as it was at the time" do
              expect(@book1.authors.map(&:name)).to(eq([@author.name]))
            end

            it "not persist changes to the live association" do
              expect(@book.authors.reload).to(eq([]))
            end
          end
        end

        context "and then the associated is destroyed between model versions" do
          before do
            @author.destroy
            Timecop.travel(1.second.since)
            @book.update_attributes(title: "book_2")
          end

          context "when reified" do
            before { @book1 = @book.versions.last.reify(has_many: true) }

            it "see the associated as it was at the time" do
              expect(@book1.authors).to(eq([]))
            end
          end
        end

        context "and then the associated is dissociated between model versions" do
          before do
            @book.authors = []
            Timecop.travel(1.second.since)
            @book.update_attributes(title: "book_2")
          end

          context "when reified" do
            before { @book1 = @book.versions.last.reify(has_many: true) }

            it "see the associated as it was at the time" do
              expect(@book1.authors).to(eq([]))
            end
          end
        end

        context "and then another associated is created" do
          before { @book.authors.create!(name: "author_1") }

          context "when reified" do
            before { @book0 = @book.versions.last.reify(has_many: true) }

            it "only see the first associated" do
              expect(@book0.authors.map(&:name)).to(eq(["author_0"]))
            end

            it "not persist changes to the live association" do
              expect(@book.authors.reload.map(&:name)).to(eq(%w[author_0 author_1]))
            end
          end

          context "when reified with option mark_for_destruction" do
            before do
              @book0 = @book.versions.last.reify(has_many: true, mark_for_destruction: true)
            end

            it "mark the newly associated for destruction" do
              author = @book0.authors.detect { |a| a.name == "author_1" }
              expect(author).to be_marked_for_destruction
            end

            it "mark the newly associated-through for destruction" do
              authorship = @book0.authorships.detect { |as| as.author.name == "author_1" }
              expect(authorship).to be_marked_for_destruction
            end
          end
        end

        context "and then an existing one is associated" do
          before { (@book.authors << @person_existing) }

          context "when reified" do
            before { @book0 = @book.versions.last.reify(has_many: true) }

            it "only see the first associated" do
              expect(@book0.authors.map(&:name)).to(eq(["author_0"]))
            end

            it "not persist changes to the live association" do
              expect(@book.authors.reload.map(&:name).sort).to(eq(%w[author_0 person_existing]))
            end
          end

          context "when reified with option mark_for_destruction" do
            before do
              @book0 = @book.versions.last.reify(has_many: true, mark_for_destruction: true)
            end

            it "not mark the newly associated for destruction" do
              author = @book0.authors.detect { |a| a.name == "person_existing" }
              expect(author).not_to be_marked_for_destruction
            end

            it "mark the newly associated-through for destruction" do
              authorship = @book0.authorships.detect { |as| as.author.name == "person_existing" }
              expect(authorship).to be_marked_for_destruction
            end
          end
        end
      end

      context "updated before the associated without paper_trail was created" do
        before do
          @book.update_attributes!(title: "book_1")
          @book.editors.create!(name: "editor_0")
        end

        context "when reified" do
          before { @book0 = @book.versions.last.reify(has_many: true) }

          it "see the live association" do
            expect(@book0.editors.map(&:name)).to(eq(["editor_0"]))
          end
        end
      end
    end

    context "Chapters, Sections, Paragraphs, Quotations, and Citations" do
      before { @chapter = Chapter.create(name: CHAPTER_NAMES[0]) }

      context "before any associations are created" do
        before { @chapter.update_attributes(name: CHAPTER_NAMES[1]) }

        it "not reify any associations" do
          chapter_v1 = @chapter.versions[1].reify(has_many: true)
          expect(chapter_v1.name).to(eq(CHAPTER_NAMES[0]))
          expect(chapter_v1.sections).to(eq([]))
          expect(chapter_v1.paragraphs).to(eq([]))
        end
      end

      context "after the first has_many through relationship is created" do
        before do
          expect(@chapter.versions.size).to(eq(1))
          @chapter.update_attributes(name: CHAPTER_NAMES[1])
          expect(@chapter.versions.size).to(eq(2))
          Timecop.travel(1.second.since)
          @chapter.sections.create(name: "section 1")
          Timecop.travel(1.second.since)
          @chapter.sections.first.update_attributes(name: "section 2")
          Timecop.travel(1.second.since)
          @chapter.update_attributes(name: CHAPTER_NAMES[2])
          expect(@chapter.versions.size).to(eq(3))
          Timecop.travel(1.second.since)
          @chapter.sections.first.update_attributes(name: "section 3")
        end

        context "version 1" do
          it "have no sections" do
            chapter_v1 = @chapter.versions[1].reify(has_many: true)
            expect(chapter_v1.sections).to(eq([]))
          end
        end

        context "version 2" do
          it "have one section" do
            chapter_v2 = @chapter.versions[2].reify(has_many: true)
            expect(chapter_v2.sections.size).to(eq(1))
            expect(chapter_v2.sections.map(&:name)).to(eq(["section 2"]))
            expect(chapter_v2.name).to(eq(CHAPTER_NAMES[1]))
          end
        end

        context "version 2, before the section was destroyed" do
          before do
            @chapter.update_attributes(name: CHAPTER_NAMES[2])
            Timecop.travel(1.second.since)
            @chapter.sections.destroy_all
            Timecop.travel(1.second.since)
          end

          it "have the one section" do
            chapter_v2 = @chapter.versions[2].reify(has_many: true)
            expect(chapter_v2.sections.map(&:name)).to(eq(["section 2"]))
          end
        end

        context "version 3, after the section was destroyed" do
          before do
            @chapter.sections.destroy_all
            Timecop.travel(1.second.since)
            @chapter.update_attributes(name: CHAPTER_NAMES[3])
            Timecop.travel(1.second.since)
          end

          it "have no sections" do
            chapter_v3 = @chapter.versions[3].reify(has_many: true)
            expect(chapter_v3.sections.size).to(eq(0))
          end
        end

        context "after creating a paragraph" do
          before do
            expect(@chapter.versions.size).to(eq(3))
            @section = @chapter.sections.first
            Timecop.travel(1.second.since)
            @paragraph = @section.paragraphs.create(name: "para1")
          end

          context "new chapter version" do
            it "have one paragraph" do
              initial_section_name = @section.name
              initial_paragraph_name = @paragraph.name
              Timecop.travel(1.second.since)
              @chapter.update_attributes(name: CHAPTER_NAMES[4])
              expect(@chapter.versions.size).to(eq(4))
              Timecop.travel(1.second.since)
              @paragraph.update_attributes(name: "para3")
              chapter_v3 = @chapter.versions[3].reify(has_many: true)
              expect(chapter_v3.sections.map(&:name)).to(eq([initial_section_name]))
              paragraphs = chapter_v3.sections.first.paragraphs
              expect(paragraphs.size).to(eq(1))
              expect(paragraphs.map(&:name)).to(eq([initial_paragraph_name]))
            end
          end

          context "the version before a section is destroyed" do
            it "have the section and paragraph" do
              Timecop.travel(1.second.since)
              @chapter.update_attributes(name: CHAPTER_NAMES[3])
              expect(@chapter.versions.size).to(eq(4))
              Timecop.travel(1.second.since)
              @section.destroy
              expect(@chapter.versions.size).to(eq(4))
              chapter_v3 = @chapter.versions[3].reify(has_many: true)
              expect(chapter_v3.name).to(eq(CHAPTER_NAMES[2]))
              expect(chapter_v3.sections).to(eq([@section]))
              expect(chapter_v3.sections[0].paragraphs).to(eq([@paragraph]))
              expect(chapter_v3.paragraphs).to(eq([@paragraph]))
            end
          end

          context "the version after a section is destroyed" do
            it "not have any sections or paragraphs" do
              @section.destroy
              Timecop.travel(1.second.since)
              @chapter.update_attributes(name: CHAPTER_NAMES[5])
              expect(@chapter.versions.size).to(eq(4))
              chapter_v3 = @chapter.versions[3].reify(has_many: true)
              expect(chapter_v3.sections.size).to(eq(0))
              expect(chapter_v3.paragraphs.size).to(eq(0))
            end
          end

          context "the version before a paragraph is destroyed" do
            it "have the one paragraph" do
              initial_paragraph_name = @section.paragraphs.first.name
              Timecop.travel(1.second.since)
              @chapter.update_attributes(name: CHAPTER_NAMES[5])
              Timecop.travel(1.second.since)
              @paragraph.destroy
              chapter_v3 = @chapter.versions[3].reify(has_many: true)
              paragraphs = chapter_v3.sections.first.paragraphs
              expect(paragraphs.size).to(eq(1))
              expect(paragraphs.first.name).to(eq(initial_paragraph_name))
            end
          end

          context "the version after a paragraph is destroyed" do
            it "have no paragraphs" do
              @paragraph.destroy
              Timecop.travel(1.second.since)
              @chapter.update_attributes(name: CHAPTER_NAMES[5])
              chapter_v3 = @chapter.versions[3].reify(has_many: true)
              expect(chapter_v3.paragraphs.size).to(eq(0))
              expect(chapter_v3.sections.first.paragraphs).to(eq([]))
            end
          end
        end
      end

      context "a chapter with one paragraph and one citation" do
        it "reify paragraphs and citations" do
          chapter = Chapter.create(name: CHAPTER_NAMES[0])
          section = Section.create(name: "Section One", chapter: chapter)
          paragraph = Paragraph.create(name: "Paragraph One", section: section)
          quotation = Quotation.create(chapter: chapter)
          citation = Citation.create(quotation: quotation)
          Timecop.travel(1.second.since)
          chapter.update_attributes(name: CHAPTER_NAMES[1])
          expect(chapter.versions.count).to(eq(2))
          paragraph.destroy
          citation.destroy
          reified = chapter.versions[1].reify(has_many: true)
          expect(reified.sections.first.paragraphs).to(eq([paragraph]))
          expect(reified.quotations.first.citations).to(eq([citation]))
        end
      end
    end
  end

  context "belongs_to associations" do
    context "Wotsit and Widget" do
      before { @widget = Widget.create(name: "widget_0") }

      context "where the association is created between model versions" do
        before do
          @wotsit = Wotsit.create(name: "wotsit_0")
          Timecop.travel(1.second.since)
          @wotsit.update_attributes(widget_id: @widget.id, name: "wotsit_1")
        end

        context "when reified" do
          before { @wotsit0 = @wotsit.versions.last.reify(belongs_to: true) }

          it "see the associated as it was at the time" do
            expect(@wotsit0.widget).to be_nil
          end

          it "not persist changes to the live association" do
            expect(@wotsit.reload.widget).to(eq(@widget))
          end
        end

        context "and then the associated is updated between model versions" do
          before do
            @widget.update_attributes(name: "widget_1")
            @widget.update_attributes(name: "widget_2")
            Timecop.travel(1.second.since)
            @wotsit.update_attributes(name: "wotsit_2")
            @widget.update_attributes(name: "widget_3")
          end

          context "when reified" do
            before { @wotsit1 = @wotsit.versions.last.reify(belongs_to: true) }

            it "see the associated as it was at the time" do
              expect(@wotsit1.widget.name).to(eq("widget_2"))
            end

            it "not persist changes to the live association" do
              expect(@wotsit.reload.widget.name).to(eq("widget_3"))
            end
          end

          context "when reified opting out of belongs_to reification" do
            before { @wotsit1 = @wotsit.versions.last.reify(belongs_to: false) }

            it "see the associated as it is live" do
              expect(@wotsit1.widget.name).to(eq("widget_3"))
            end
          end
        end

        context "and then the associated is destroyed" do
          before do
            @wotsit.update_attributes(name: "wotsit_2")
            @widget.destroy
          end

          context "when reified with belongs_to: true" do
            before { @wotsit2 = @wotsit.versions.last.reify(belongs_to: true) }

            it "see the associated as it was at the time" do
              expect(@wotsit2.widget).to(eq(@widget))
            end

            it "not persist changes to the live association" do
              expect(@wotsit.reload.widget).to be_nil
            end

            it "be able to persist the reified record" do
              expect { @wotsit2.save! }.not_to(raise_error)
            end
          end

          context "when reified with belongs_to: false" do
            before { @wotsit2 = @wotsit.versions.last.reify(belongs_to: false) }

            it "save should not re-create the widget record" do
              @wotsit2.save!
              expect(::Widget.find_by(id: @widget.id)).to be_nil
            end
          end

          context "and then the model is updated" do
            before do
              Timecop.travel(1.second.since)
              @wotsit.update_attributes(name: "wotsit_3")
            end

            context "when reified" do
              before { @wotsit2 = @wotsit.versions.last.reify(belongs_to: true) }

              it "see the associated as it was the time" do
                expect(@wotsit2.widget).to be_nil
              end
            end
          end
        end
      end

      context "where the association is changed between model versions" do
        before do
          @wotsit = @widget.create_wotsit(name: "wotsit_0")
          Timecop.travel(1.second.since)
          @new_widget = Widget.create(name: "new_widget")
          @wotsit.update_attributes(widget_id: @new_widget.id, name: "wotsit_1")
        end

        context "when reified" do
          before { @wotsit0 = @wotsit.versions.last.reify(belongs_to: true) }

          it "see the association as it was at the time" do
            expect(@wotsit0.widget.name).to(eq("widget_0"))
          end

          it "not persist changes to the live association" do
            expect(@wotsit.reload.widget).to(eq(@new_widget))
          end
        end

        context "when reified with option mark_for_destruction" do
          before do
            @wotsit0 = @wotsit.versions.last.reify(belongs_to: true, mark_for_destruction: true)
          end

          it "does not mark the new associated for destruction" do
            expect(@new_widget.marked_for_destruction?).to(eq(false))
          end
        end
      end
    end
  end

  context "has_and_belongs_to_many associations" do
    context "foo and bar" do
      before do
        @foo = FooHabtm.create(name: "foo")
        Timecop.travel(1.second.since)
      end

      context "where the association is created between model versions" do
        before do
          @foo.update_attributes(name: "foo1", bar_habtms: [BarHabtm.create(name: "bar")])
        end

        context "when reified" do
          before do
            @reified = @foo.versions.last.reify(has_and_belongs_to_many: true)
          end

          it "see the associated as it was at the time" do
            expect(@reified.bar_habtms.length).to(eq(0))
          end

          it "not persist changes to the live association" do
            expect(@foo.reload.bar_habtms).not_to(eq(@reified.bar_habtms))
          end
        end
      end

      context "where the association is changed between model versions" do
        before do
          @foo.update_attributes(name: "foo2", bar_habtms: [BarHabtm.create(name: "bar2")])
          Timecop.travel(1.second.since)
          @foo.update_attributes(name: "foo3", bar_habtms: [BarHabtm.create(name: "bar3")])
        end

        context "when reified" do
          before do
            @reified = @foo.versions.last.reify(has_and_belongs_to_many: true)
          end

          it "see the association as it was at the time" do
            expect(@reified.bar_habtms.first.name).to(eq("bar2"))
          end

          it "not persist changes to the live association" do
            expect(@foo.reload.bar_habtms.first).not_to(eq(@reified.bar_habtms.first))
          end
        end

        context "when reified with has_and_belongs_to_many: false" do
          before { @reified = @foo.versions.last.reify }

          it "see the association as it is now" do
            expect(@reified.bar_habtms.first.name).to(eq("bar3"))
          end
        end
      end

      context "where the association is destroyed between model versions" do
        before do
          @foo.update_attributes(name: "foo2", bar_habtms: [BarHabtm.create(name: "bar2")])
          Timecop.travel(1.second.since)
          @foo.update_attributes(name: "foo3", bar_habtms: [])
        end

        context "when reified" do
          before do
            @reified = @foo.versions.last.reify(has_and_belongs_to_many: true)
          end

          it "see the association as it was at the time" do
            expect(@reified.bar_habtms.first.name).to(eq("bar2"))
          end

          it "not persist changes to the live association" do
            expect(@foo.reload.bar_habtms.first).not_to(eq(@reified.bar_habtms.first))
          end
        end
      end

      context "where the unassociated model changes" do
        before do
          @bar = BarHabtm.create(name: "bar2")
          @foo.update_attributes(name: "foo2", bar_habtms: [@bar])
          Timecop.travel(1.second.since)
          @foo.update_attributes(name: "foo3", bar_habtms: [BarHabtm.create(name: "bar4")])
          Timecop.travel(1.second.since)
          @bar.update_attributes(name: "bar3")
        end

        context "when reified" do
          before do
            @reified = @foo.versions.last.reify(has_and_belongs_to_many: true)
          end

          it "see the association as it was at the time" do
            expect(@reified.bar_habtms.first.name).to(eq("bar2"))
          end

          it "not persist changes to the live association" do
            expect(@foo.reload.bar_habtms.first).not_to(eq(@reified.bar_habtms.first))
          end
        end
      end
    end

    context "updated via nested attributes" do
      before do
        @foo = FooHabtm.create(name: "foo", bar_habtms_attributes: [{ name: "bar" }])
        Timecop.travel(1.second.since)
        @foo.update_attributes(
          name: "foo2",
          bar_habtms_attributes: [{ id: @foo.bar_habtms.first.id, name: "bar2" }]
        )
        @reified = @foo.versions.last.reify(has_and_belongs_to_many: true)
      end

      it "see the associated object as it was at the time" do
        expect(@reified.bar_habtms.first.name).to(eq("bar"))
      end

      it "not persist changes to the live object" do
        expect(@foo.reload.bar_habtms.first.name).not_to(eq(@reified.bar_habtms.first.name))
      end
    end
  end
end

# frozen_string_literal: true

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

  context "Books, Authors, and Authorships" do
    before { @book = Book.create(title: "book_0") }

    context "updated before the associated was created" do
      before do
        @book.update!(title: "book_1")
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
        @book.update!(title: "book_1")
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
        @book.update!(title: "book_1")
      end

      context "when reified" do
        before { @book0 = @book.versions.last.reify(has_many: true) }

        it "see the associated as it was at the time" do
          expect(@book0.authors.map(&:name)).to(eq(["author_0"]))
        end
      end

      context "and then the associated is updated between model versions" do
        before do
          @author.update(name: "author_1")
          @author.update(name: "author_2")
          @book.update(title: "book_2")
          @author.update(name: "author_3")
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
          @book.update(title: "book_2")
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
          @book.update(title: "book_2")
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
        @book.update!(title: "book_1")
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
      before { @chapter.update(name: CHAPTER_NAMES[1]) }

      it "not reify any associations" do
        chapter_v1 = @chapter.versions[1].reify(has_many: true)
        expect(chapter_v1.name).to(eq(CHAPTER_NAMES[0]))
        expect(chapter_v1.sections).to(eq([]))
        expect(chapter_v1.paragraphs).to(eq([]))
      end
    end

    context "after the first has_many through relationship is created" do
      before do
        @chapter.update(name: CHAPTER_NAMES[1])
        @chapter.sections.create(name: "section 1")
        @chapter.sections.first.update(name: "section 2")
        @chapter.update(name: CHAPTER_NAMES[2])
        @chapter.sections.first.update(name: "section 3")
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
          @chapter.update(name: CHAPTER_NAMES[2])
          @chapter.sections.destroy_all
        end

        it "have the one section" do
          chapter_v2 = @chapter.versions[2].reify(has_many: true)
          expect(chapter_v2.sections.map(&:name)).to(eq(["section 2"]))
        end
      end

      context "version 3, after the section was destroyed" do
        before do
          @chapter.sections.destroy_all
          @chapter.update(name: CHAPTER_NAMES[3])
        end

        it "have no sections" do
          chapter_v3 = @chapter.versions[3].reify(has_many: true)
          expect(chapter_v3.sections.size).to(eq(0))
        end
      end

      context "after creating a paragraph" do
        before do
          @section = @chapter.sections.first
          @paragraph = @section.paragraphs.create(name: "para1")
        end

        context "new chapter version" do
          it "have one paragraph" do
            initial_section_name = @section.name
            initial_paragraph_name = @paragraph.name
            @chapter.update(name: CHAPTER_NAMES[4])
            expect(@chapter.versions.size).to(eq(4))
            @paragraph.update(name: "para3")
            chapter_v3 = @chapter.versions[3].reify(has_many: true)
            expect(chapter_v3.sections.map(&:name)).to(eq([initial_section_name]))
            paragraphs = chapter_v3.sections.first.paragraphs
            expect(paragraphs.size).to(eq(1))
            expect(paragraphs.map(&:name)).to(eq([initial_paragraph_name]))
          end
        end

        context "the version before a section is destroyed" do
          it "have the section and paragraph" do
            @chapter.update(name: CHAPTER_NAMES[3])
            expect(@chapter.versions.size).to(eq(4))
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
            @chapter.update(name: CHAPTER_NAMES[5])
            expect(@chapter.versions.size).to(eq(4))
            chapter_v3 = @chapter.versions[3].reify(has_many: true)
            expect(chapter_v3.sections.size).to(eq(0))
            expect(chapter_v3.paragraphs.size).to(eq(0))
          end
        end

        context "the version before a paragraph is destroyed" do
          it "have the one paragraph" do
            initial_paragraph_name = @section.paragraphs.first.name
            @chapter.update(name: CHAPTER_NAMES[5])
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
            @chapter.update(name: CHAPTER_NAMES[5])
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
        chapter.update(name: CHAPTER_NAMES[1])
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

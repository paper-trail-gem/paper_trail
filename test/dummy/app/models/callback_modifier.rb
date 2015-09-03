class CallbackModifier < ActiveRecord::Base
  # This will not be directly instantiated, but we need to set paper_trail up
  # before we can run tests on fake classes inheriting from CallbackModifier
  has_paper_trail :on => []

  def test_destroy
    transaction do
      run_callbacks(:destroy) do
        self.deleted = true
        save!
      end
    end
  end

  def flagged_deleted?
    deleted?
  end
end

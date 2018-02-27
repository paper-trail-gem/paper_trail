# frozen_string_literal: true

class Elephant < Animal
end

# Nice! We used to have `paper_trail.disable` inside the class, which was really
# misleading because it looked like a permanent, global setting. It's so much
# more obvious now that we are disabling the model for this request only. Of
# course, we run the PT unit tests in a single thread, and I think this setting
# will affect multiple unit tests, but in a normal application, this new API is
# a huge improvement.
#
# TODO: If this call to `disable_model` were moved to the unit tests, this file
# would be more like normal application code. It'd be pretty strange for someone
# to do this in app code, especially now that it is obvious that it only affects
# the current request.
PaperTrail.request.disable_model(Elephant)

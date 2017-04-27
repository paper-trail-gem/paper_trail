# The warning about not setting whodunnit

After upgrading to PaperTrail 5, you see this warning:

> user_for_paper_trail is present, but whodunnit has not been set. PaperTrail no
> longer adds the set_paper_trail_whodunnit before_action for you. Please add this
> before_action to your ApplicationController to continue recording whodunnit.

## You want to track whodunnit

Add `before_action :set_paper_trail_whodunnit` to your ApplicationController.
See the PaperTrail readme for an example (https://git.io/vrsbt).

## You don't want to track whodunnit

If you no longer want to track whodunnit, you may disable this
warning by overriding user_for_paper_trail to return nil.

```
# in application_controller.rb
def user_for_paper_trail
  nil # disable whodunnit tracking
end
```

## You just want the warning to go away

Upgrade to PT 6.

## Why does PT no longer add this callback for me?

So that you can control the order of callbacks. Maybe you have another callback
that must happen first, before `set_paper_trail_whodunnit`.

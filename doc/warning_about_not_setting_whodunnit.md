# The warning about not setting whodunnit

After upgrading to PaperTrail 5, you see this warning:

> user_for_paper_trail is present, but whodunnit has not been set. PaperTrail no
> longer adds the set_paper_trail_whodunnit before_filter for you. Please add this
> before_filter to your ApplicationController to continue recording whodunnit.

## You want to track whodunnit

Add the set_paper_trail_whodunnit before_filter to your ApplicationController.
See the PaperTrail readme for an example (https://git.io/vrTYG).

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

To disable this warning for any other reason, use `skip_after_action`.

```
skip_after_action :warn_about_not_setting_whodunnit
```

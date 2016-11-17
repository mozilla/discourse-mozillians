# discourse-mozillians
*Mozillians magic for Discourse*

## Installation

Follow the Discourse [Install a Plugin](https://meta.discourse.org/t/install-a-plugin/19157) guide.

For a standard installation, once Discourse has launched, add groups for users to be placed in (these are all optional - if you don't add the group, users simply won't be placed in them):
- `mozillians` (for everybody on mozillians.org)
- `mozillians_unvouched` (for unvouched users of mozillians.org)
- `mozillians_vouched` (for vouched users of mozillians.org)
- `mozillians_nda` (for vouched users of mozillians.org within the NDA group)

Then, navigate to `/admin/site_settings/category/plugins`:
- Set `mozillians_api_key` to your API key
- Check the `mozillians_enabled` checkbox

You're all set! Now when users log in, they should be assigned to the groups you created based on their status on mozillians.org.

## Licence

[MPL 2.0](https://www.mozilla.org/MPL/2.0/)

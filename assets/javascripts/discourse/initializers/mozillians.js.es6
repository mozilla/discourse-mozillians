import PreferencesController from 'discourse/controllers/preferences'
import { setting } from 'discourse/lib/computed'

export default {
  name: 'mozillians',
  initialize: function () {
    PreferencesController.reopen({
      mozilliansEnabled: setting('mozillians_enabled'),
      mozilliansProgress: null,
      actions: {
        updateMozillians () {
          if (!this.get('mozilliansProgress')) {
            this.set('mozilliansProgress', '(updating)')
            return Discourse.ajax('/session/update_mozillians', {
              dataType: 'json',
              data: { login: this.get('model').get('username') },
              type: 'POST'
            }).then(() => {
              // mozillians updated
              this.setProperties({
                updateMozilliansProgress: false,
                mozilliansProgress: '(updated)'
              })
            }).catch(() => {
              // mozillians failed to update
              this.setProperties({
                updateMozilliansProgress: false,
                mozilliansProgress: '(failed)'
              })
            })
          }
        }
      }
    })
  }
}

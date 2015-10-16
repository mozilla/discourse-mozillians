# name: discourse-mozillians
# about: Mozillians magic for Discourse
# version: 0.0.1
# author: Leo McArdle

enabled_site_setting :mozillians_enabled

after_initialize do
  require_dependency File.expand_path('../jobs/mozillians_magic.rb', __FILE__)

  module AuthExtensions
    def after_authenticate(auth_token)
      result = super(auth_token)

      user = result.user
      if SiteSetting.mozillians_enabled?
        Jobs.enqueue(:mozillians_magic, user_id: user.id) if user.try(:id)
      end

      result
    end

    def after_create_account(user, auth)
      super(user, auth)

      if SiteSetting.mozillians_enabled?
        Jobs.enqueue(:mozillians_magic, user_id: user.id)
      end
    end
  end

  Auth::Authenticator.descendants.each do |auth_class|
    auth_class.prepend(AuthExtensions)
  end
end

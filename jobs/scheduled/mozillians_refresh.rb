module Jobs
  class MozilliansRefresh < Jobs::Scheduled
    every 1.day

    def execute(args)
      return unless SiteSetting.mozillians_enabled?

      staff_action_logger = StaffActionLogger.new(Discourse.system_user)
      staff_action_logger.log_custom('mozillians_refresh')

      User.find_each(batch_size: 5000) do |user|
        Jobs.enqueue(:mozillians_magic, user_id: user.id)
      end
    end
  end
end

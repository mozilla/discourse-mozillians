module Jobs
  class MozilliansMagic < Jobs::Base

    def add_to_group(user, group_name)
      group = Group.where(name: group_name).first
      if group
        if group.group_users.where(user_id: user.id).first.nil?
          group.group_users.create(user_id: user.id, group_id: group.id)
        end
      end
    end

    def remove_from_group(user, group_name)
      group = Group.where(name: group_name).first
      if group
        if not group.group_users.where(user_id: user.id).first.nil?
          group.group_users.where(user_id: user.id).destroy_all
        end
      end
    end

    def purge_from_groups(user)
      remove_from_group(user, 'mozillians')

      groups = Group.where("name LIKE 'mozillians*_%' ESCAPE '*'")
      groups.each do |group|
        remove_from_group(user, group.name)
      end
    end

    def execute(args)
      raise Discourse::InvalidParameters.new(:user_id) unless args[:user_id].present?

      return unless SiteSetting.mozillians_enabled?

      user = User.find(args[:user_id])
      email = user.email

      Rails.logger.info "Mozillians: getting data for #{email}"

      begin
        uri = URI('https://mozillians.org/api/v2/users/')
        params = { email: email }
        uri.query = URI.encode_www_form(params)

        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true

        request = Net::HTTP::Get.new(uri.request_uri)
        request['X-API-KEY'] = SiteSetting.mozillians_api_key

        response = http.request(request)

        if response.code.to_i == 200
          res = JSON.parse(response.body)
          count = res['count']

          if count.to_i == 1
            is_vouched = !!res['results'].first['is_vouched']

            add_to_group(user, 'mozillians')

            if is_vouched
              remove_from_group(user, 'mozillians_unvouched')
              add_to_group(user, 'mozillians_vouched')
            else
              remove_from_group(user, 'mozillians_vouched')
              add_to_group(user, 'mozillians_unvouched')
            end

          else
            purge_from_groups(user)
          end

        else
          purge_from_groups(user)
        end

      rescue Exception => details
        Rails.logger.error "Failed to query API: #{details.message}"
        purge_from_groups(user)
      end
    end

  end
end

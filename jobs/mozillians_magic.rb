module Jobs
  class MozilliansMagic < Jobs::Base

    def add_to_group(group_name)
      group = Group.where(name: group_name).first
      if group
        if group.group_users.where(user_id: @user.id).first.nil?
          group.group_users.create(user_id: @user.id, group_id: group.id)
        end
      end
    end

    def remove_from_group(group_name)
      group = Group.where(name: group_name).first
      if group
        if not group.group_users.where(user_id: @user.id).first.nil?
          group.group_users.where(user_id: @user.id).destroy_all
        end
      end
    end

    def purge_from_groups
      remove_from_group('mozillians')

      groups = Group.where("name LIKE 'mozillians*_%' ESCAPE '*'")
      groups.each do |group|
        remove_from_group(group.name)
      end
    end

    def query_mozillians(params = { email: @user.email }, url = 'https://mozillians.org/api/v2/users/')
      uri = URI(url)
      uri.query = URI.encode_www_form(params)

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true

      request = Net::HTTP::Get.new(uri.request_uri)
      request['X-API-KEY'] = SiteSetting.mozillians_api_key

      http.request(request)
    end

    def iterate_mozillians_groups(groups)
      remove_from_group('mozillians_nda')
      remove_from_group('mozillians_iam_project')
      groups.each do |group|
        name = group['name']
        add_to_group('mozillians_nda') if name == 'nda'
        add_to_group('mozillians_iam_project') if name == 'iam-project'
        add_to_group('mozillians_communities_advisory_group_early_2017') if name == 'communities advisory group - early 2017'
      end
    end

    def query_mozillians_profile(_url)
      response = query_mozillians({}, _url)

      if response.code.to_i == 200
        profile = JSON.parse(response.body)
        iterate_mozillians_groups(profile['groups']['value'])
      else
        purge_from_groups
      end
    end

    def execute(args)
      raise Discourse::InvalidParameters.new(:user_id) unless args[:user_id].present?

      return unless SiteSetting.mozillians_enabled?

      @user = User.find(args[:user_id])

      Rails.logger.info "Mozillians: getting data for #{@user.email}"

      begin
        response = query_mozillians

        if response.code.to_i == 200
          response = JSON.parse(response.body)
          count = response['count']
          result = response['results'].first

          if count.to_i == 1
            is_vouched = !!result['is_vouched']

            add_to_group('mozillians')

            if is_vouched
              remove_from_group('mozillians_unvouched')
              add_to_group('mozillians_vouched')
              query_mozillians_profile(result['_url'])
            else
              remove_from_group('mozillians_vouched')
              add_to_group('mozillians_unvouched')
            end

          else
            purge_from_groups
          end

        else
          purge_from_groups
        end

      rescue Exception => details
        Rails.logger.error "Failed to query API: #{details.message}"
        purge_from_groups
      end
    end

  end
end

module V1
  class Options < Grape::API
    version 'v1'
    format :json

    resource :options do

      desc "get role list"
      params do
        optional :role_type, type: String, values: ['global', 'invention', 'organization'], desc: 'role type'
      end
      get :roles do
        role_type = params[:role_type]
        roles = if role_type.present?
          Role.where(role_type: role_type)
        else
          Role.where(role_type: ['global', 'invention', 'organization'])
        end
        resp_ok("roles" => RoleSerializer.build_array(roles))
      end

      desc "user organization roles"
      params do
        requires 'organization_id', type: Integer, desc: "organization id"
        requires 'user_id', type: Integer, desc: "user_id"
      end
      get :organization_roles do
        organization = Organization.find_by(id: params[:organization_id])
        return data_not_found(MISSING_ORG) if organization.nil?
        user = organization.users.find_by(id: params[:user_id])
        return data_not_found(MISSING_USR) if user.nil?
        organization_roles = user.organization_roles(organization)
        resp_ok("organization_roles" => RoleSerializer.build_array(organization_roles))
      end

      desc "user invention roles"
      params do
        requires 'invention_id', type: Integer, desc: "invention id"
        requires 'user_id', type: Integer, desc: "user_id"
      end
      get :invention_roles do
        invention = Invention.find_by(id: params[:invention_id])
        return data_not_found(MISSING_INV) if invention.nil?
        user = invention.users.find_by(id: params[:user_id])
        return data_not_found(MISSING_USR) if user.nil?
        invention_roles = user.invention_roles(invention)
        resp_ok("invention_roles" => RoleSerializer.build_array(invention_roles))
      end

      desc "user global roles"
      params do
        requires 'user_id', type: Integer, desc: "user_id"
      end
      get :global_roles do
        user = User.find_by(id: params[:user_id])
        return data_not_found(MISSING_USR) if user.nil?
        resp_ok("global_roles" => RoleSerializer.build_array(user.roles))
      end

      desc "get organization list"
      params do
        optional :page, type: Integer, desc: 'curent page index，default: 1'
        optional :size, type: Integer, desc: 'records count in each page, default: 20'
      end
      get :organizations do
        page = params[:page].presence || 1
        size = params[:size].presence || 20
        organizations = Organization.all.order(id: :desc).page(page).per(size)
        resp_ok("organizations" => OrganizationSerializer.build_array(organizations))
      end

      desc "get organization"
      params do
        requires :organization_id, type: Integer, desc: 'organization id'
      end
      get :organization do
        organization = Organization.find_by(id: params[:organization_id])
        return data_not_found(MISSING_ORG) if organization.nil?
        resp_ok("organization" => OrganizationSerializer.new(organization))
      end

      # desc "get user list"
      # params do
      #   optional :page, type: Integer, desc: 'curent page index，default: 1'
      #   optional :size, type: Integer, desc: 'records count in each page, default: 20'
      # end
      # get :users do
      #   authenticate!
      #   page = params[:page].presence || 1
      #   size = params[:size].presence || 20
      #   if current_user.god?
      #     users = User.all.order(id: :desc).page(page).per(size)
      #     resp_ok("users" => UserSerializer.build_array(users))
      #   elsif current_user.managed_organizations.any?
      #     users = User.includes(:organizations).where(organizations: {id: current_user.managed_organizations.map(&:id)})
      #     users = users.order(id: :desc).page(page).per(size)
      #     resp_ok("users" => UserSerializer.build_array(users, managed_organizations: current_user.managed_organizations))
      #   else
      #     return permission_denied(NOT_GOD_OA_DENIED)
      #   end
      # end

      desc "get Users List Filtering"
      params do
        optional 'name', type: String, desc: "name"
        optional 'organization_id', type: Integer, desc: "organization_id, null for all"
        optional 'status', type: String, desc: "status, null for all"
        optional :page, type: Integer, desc: 'curent page index，default: 1'
        optional :size, type: Integer, desc: 'records count in each page, default: 20'
      end
      get :users do
        authenticate!
        page = params[:page].presence || 1
        size = params[:size].presence || 20
        organizations = if params[:organization_id]
          Organization.where(id: params[:organization_id])
        else
          Organization.all
        end
        unless current_user.god?
          organizations = (organizations & current_user.member_organizations)
        end
        uoss = if params[:status]
          UserOrganizationStatus.where(organization_id: organizations.map(&:id)).where(status: params[:status])
        else
          UserOrganizationStatus.where(organization_id: organizations.map(&:id))
        end
        users = User.includes(:user_organization_statuses).where(user_organization_statuses: {id: uoss.map(&:id)})
        if params[:name].present?
          name = params[:name].strip
          nameparts = name.gsub(/\s/,'%')
          users = users.where("LOCATE(?, firstname) OR LOCATE(?, lastname) OR LOCATE(?, email) OR CONCAT(firstname,' ', lastname) LIKE ?", name, name, name, nameparts)
        end
        users = users.order(id: :desc).page(page).per(size)
        resp_ok("users" => UserSerializer.build_array(users, managed_organizations: current_user.managed_organizations))
      end

      desc "get Users List Filtering"
      params do
        optional 'name', type: String, desc: "name"
        optional 'organization_id', type: Integer, desc: "organization_id, null for all"
        optional 'status', type: String, desc: "status, null for all"
        optional :page, type: Integer, desc: 'curent page index，default: 1'
        optional :size, type: Integer, desc: 'records count in each page, default: 20'
      end
      get :filter_users do
        authenticate!
        page = params[:page].presence || 1
        size = params[:size].presence || 20
        organizations = if params[:organization_id]
          Organization.where(id: params[:organization_id])
        else
          Organization.all
        end
        unless current_user.god?
          organizations = (organizations & current_user.member_organizations)
        end
        uoss = if params[:status]
          UserOrganizationStatus.where(organization_id: organizations.map(&:id)).where(status: params[:status])
        else
          UserOrganizationStatus.where(organization_id: organizations.map(&:id))
        end
        users = User.includes(:user_organization_statuses).where(user_organization_statuses: {id: uoss.map(&:id)})
        if params[:name].present?
          name = params[:name].strip
          nameparts = name.gsub(/\s/,'%')
          users = users.where("LOCATE(?, firstname) OR LOCATE(?, lastname) OR LOCATE(?, email) OR CONCAT(firstname,' ', lastname) LIKE ?", name, name, name, nameparts)
        end
        users = users.order(id: :desc).page(page).per(size)
        resp_ok("users" => UserSerializer.build_array(users, managed_organizations: current_user.managed_organizations))
      end

      desc "get user"
      params do
        requires :user_id, type: Integer, desc: 'user_id'
      end
      get :user do
        authenticate!
        user = User.find_by(id: params[:user_id])
        return data_not_found(MISSING_USR) if user.nil?
        orgs = (current_user.member_organizations & user.organizations)
        if current_user.god? || orgs.any?
          resp_ok("user" => UserSerializer.new(user, managed_organizations: current_user.managed_organizations))
        else
          return permission_denied(NOT_GOD_OA_MEMBER_DENIED)
        end
      end

      desc "get citizenships"
      params do
      end
      get :citizenships do
        citizenships = Citizenship.all
        resp_ok("citizenships" => CitizenshipSerializer.build_array(citizenships))
      end

      desc "get languages"
      params do
      end
      get :languages do
        languages = Language.all
        resp_ok("languages" => LanguageSerializer.build_array(languages))
      end

      # desc "get time_zones"
      # params do
      # end
      # get :time_zones do
      #   time_zones = TimeZone.all
      #   resp_ok("time_zones" => TimeZoneSerializer.build_array(time_zones))
      # end

    end
  end
end

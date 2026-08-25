class MyEnterprise::MembershipsController < MyEnterprise::BaseController
  def index
    @memberships = enterprise.memberships.includes(:user).order(:id)
  end

  def create
    user = User.find_by_phone(params[:phone])
    if user.nil?
      redirect_to my_enterprise_memberships_path, alert: t("memberships.not_found")
      return
    end
    membership = enterprise.memberships.create(user:)
    if membership.persisted?
      redirect_to my_enterprise_memberships_path, notice: t("memberships.added", name: user.name)
    else
      redirect_to my_enterprise_memberships_path, alert: membership.errors.full_messages.join(", ")
    end
  end

  def destroy
    membership = enterprise.memberships.find(params[:id])
    if membership.destroy
      session.delete(:enterprise_id) if membership.user == Current.user
      redirect_to(membership.user == Current.user ? root_path : my_enterprise_memberships_path, notice: t("memberships.removed"))
    else
      redirect_to my_enterprise_memberships_path, alert: membership.errors.full_messages.join(", ")
    end
  end
end

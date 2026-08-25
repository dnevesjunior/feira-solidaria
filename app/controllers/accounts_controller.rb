# "Minha conta": a pessoa troca a própria senha (ADR 0007).
class AccountsController < ApplicationController
  def show
    @user = Current.user
  end

  def update
    @user = Current.user
    unless @user.authenticate(params[:current_password].to_s)
      flash.now[:alert] = t("accounts.wrong_current_password")
      return render :show, status: :unprocessable_entity
    end

    if @user.update(password: params[:password], password_confirmation: params[:password_confirmation])
      redirect_to account_path, notice: t("accounts.password_changed")
    else
      render :show, status: :unprocessable_entity
    end
  end
end

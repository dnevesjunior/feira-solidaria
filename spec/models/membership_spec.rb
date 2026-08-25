require "rails_helper"

RSpec.describe Membership do
  let(:maria) { create_user(phone: "13 90000-0001") }
  let(:jose) { create_user(name: "José", phone: "13 90000-0002") }
  let(:enterprise) { create_enterprise(user: maria) }

  it "é escopado por empreendimento" do
    expect(Membership).to include(EnterpriseScoped)
  end

  it "não repete a mesma pessoa" do
    expect(enterprise.memberships.create(user: maria)).not_to be_persisted
  end

  it "registra entrada e saída com referência, não nome" do
    m = enterprise.memberships.create!(user: jose)
    expect(Event.where(kind: "enterprise.member_added", subject: enterprise).last.payload).to eq({ "user_id" => jose.id })
    m.destroy!
    expect(Event.where(kind: "enterprise.member_removed", subject: enterprise).last.payload).to eq({ "user_id" => jose.id })
  end

  it "não remove a última pessoa" do
    only = enterprise.memberships.first
    expect(only.destroy).to be(false)
    expect(only.errors[:base].join).to match(/pelo menos uma pessoa/)
    expect(enterprise.memberships.count).to eq(1)
  end
end

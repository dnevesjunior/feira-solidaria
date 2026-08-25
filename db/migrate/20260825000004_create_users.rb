# Contas de membros (ADR 0007): telefone é o identificador; e-mail é opcional
# e não participa do login.
class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :name, null: false
      t.string :phone, null: false
      t.string :email
      t.string :password_digest, null: false

      t.timestamps
    end
    add_index :users, :phone, unique: true
  end
end

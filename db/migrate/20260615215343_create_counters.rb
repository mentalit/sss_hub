class CreateCounters < ActiveRecord::Migration[8.1]
  def change
    create_table :counters do |t|
      t.string :user_id
      t.date :counter_cert_training
      t.references :store, null: false, foreign_key: true

      t.timestamps
    end
  end
end

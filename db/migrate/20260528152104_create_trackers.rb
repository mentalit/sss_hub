class CreateTrackers < ActiveRecord::Migration[8.1]
  def change
    create_table :trackers do |t|
      t.string :art_num
      t.string :art_name
      t.integer :boh
      t.string :counter
      t.integer :initial_diff
      t.integer :sss_inv_count
      t.float :price
      t.float :initial_loss
      t.integer :diff_after_recount
      t.float :loss_after_recount
      t.string :slid_h
      t.text :comment
      t.references :store, null: false, foreign_key: true

      t.timestamps
    end
  end
end

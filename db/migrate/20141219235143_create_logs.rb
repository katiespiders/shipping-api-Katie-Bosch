class CreateLogs < ActiveRecord::Migration
  def change
    create_table :logs do |t|
      t.integer :status
      t.json :params
      t.string :from

      t.timestamps
    end
  end
end

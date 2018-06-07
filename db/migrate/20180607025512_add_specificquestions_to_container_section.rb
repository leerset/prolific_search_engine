class AddSpecificquestionsToContainerSection < ActiveRecord::Migration[5.1]
  def change
    add_column :container_sections, :specificquestions, :text
    add_column :container_sections, :specificquestions_completion, :boolean, default: false
  end
end

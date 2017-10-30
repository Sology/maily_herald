class RenameTemplateFromMailyHeraldDispatches < ActiveRecord::Migration[4.2]
  def change
    rename_column :maily_herald_dispatches, :template, :template_plain
  end
end

Sequel.migration do
  change do
    create_table(:widgets) do
      primary_key :id
      String :name, :null=>false
    end
  end
end

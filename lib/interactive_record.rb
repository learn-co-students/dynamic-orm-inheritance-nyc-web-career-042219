require_relative "../config/environment.rb"
require 'active_support/inflector'

class InteractiveRecord

  #* grab the table name from the class name.
  def self.table_name
    #* take the class name turn it to a string.
    #* then lowercase it and pluralize it.
    self.to_s.downcase.pluralize
  end

  #* grab all of the column names from the table.
  def self.column_names
    #* grab the results as a hash rather than an array.
    DB[:conn].results_as_hash = true

    #* use pragma table_info() method to get info on a
    #* table. the method takes in an argument of a 
    #* table name. Because of the self.table_name method
    #* we can get the info of any table name.
    sql = "pragma table_info('#{table_name}')"

    #@ table_info is a hash because of the results_as_hash.
    table_info = DB[:conn].execute(sql)
    column_names = []
    table_info.each do |row|
      #* we can use row['name'] to get the name of the
      #* column and shovel it into an array.
      column_names << row["name"]
    end
    column_names.compact
  end

  #* using a hash is more dynamic because we can take in
  #* an infinte number of arguments in the form of key-value
  #* pairs rather then having to expect several arguments.
  #* it also makes our code less brittle allowing us to 
  #* insert arguments in any order.
  def initialize(options={})
    #* iterate over the hash
    #@ property is the key and value the value
    options.each do |property, value|
      #* use the setter method to set the key = value.
      self.send("#{property}=", value)
    end
  end

  def save
    #* insert into a table and column values
    sql = "INSERT INTO #{table_name_for_insert} (#{col_names_for_insert}) VALUES (#{values_for_insert})"
    DB[:conn].execute(sql)
    #* grab the id from the db.
    @id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{table_name_for_insert}")[0][0]
  end

  #* allow the instance to have access to the table name.
  def table_name_for_insert
    self.class.table_name
  end

  #* grabs the values to be inserted into the db.
  def values_for_insert
    #* values will be stored in an array initially
    values = []
    #* iterate over each column name
    self.class.column_names.each do |col_name|
      #* shovel the values into an array unless they are nil
      values << "'#{send(col_name)}'" unless send(col_name).nil?
    end
    #* convert them into a string separated by a comma.
    values.join(", ")
  end

  #* allow the instance access to column names except for 
  #* id, since we want the database to give us an id.
  def col_names_for_insert
    #* delete the id column and join together the values into
    #* a string to be used on insert.
    self.class.column_names.delete_if {|col| col == "id"}.join(", ")
  end

  #* take in a name parameter to use in a search.
  def self.find_by_name(name)
    #* find the matching element in the database.
    sql = "SELECT * FROM #{self.table_name} WHERE name = '?'"
    DB[:conn].execute(sql, name)
  end

end

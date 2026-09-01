# Preserve physical column order in db/schema.rb.
#
# Rails' default schema dumper sorts columns alphabetically
# (ActiveRecord::SchemaDumper#table uses `columns.sort_by(&:name)`), so the
# dump never matches the migration's declaration order. We override `table`
# using the Rails 8.1.3 implementation with only that sort removed.
#
# See ADR-0001: `Task` is modeled 1:1 on tasks_index.json, and we want
# db/schema.rb to read in the same order as the model/source document.

module PreserveColumnOrder
  def table(table, stream)
    columns = @connection.columns(table)
    begin
      self.table_name = table

      tbl = StringIO.new

      pk = @connection.primary_key(table)

      tbl.print "  create_table #{relation_name(remove_prefix_and_suffix(table)).inspect}"

      case pk
      when String
        tbl.print ", primary_key: #{pk.inspect}" unless pk == "id"
        pkcol = columns.detect { |c| c.name == pk }
        pkcolspec = column_spec_for_primary_key(pkcol)
        unless pkcolspec.empty?
          if pkcolspec != pkcolspec.slice(:id, :default)
            pkcolspec = { id: { type: pkcolspec.delete(:id), **pkcolspec }.compact }
          end
          tbl.print ", #{format_colspec(pkcolspec)}"
        end
      when Array
        tbl.print ", primary_key: #{pk.inspect}"
      else
        tbl.print ", id: false"
      end

      table_options = @connection.table_options(table)
      if table_options.present?
        tbl.print ", #{format_options(table_options)}"
      end

      tbl.puts ", force: :cascade do |t|"

      columns.each do |column|
        raise StandardError, "Unknown type '#{column.sql_type}' for column '#{column.name}'" unless @connection.valid_type?(column.type)
        next if column.name == pk

        type, colspec = column_spec(column)
        if type.is_a?(Symbol)
          tbl.print "    t.#{type} #{column.name.inspect}"
        else
          tbl.print "    t.column #{column.name.inspect}, #{type.inspect}"
        end
        tbl.print ", #{format_colspec(colspec)}" if colspec.present?
        tbl.puts
      end

      indexes_in_create(table, tbl)
      remaining = check_constraints_in_create(table, tbl) if @connection.supports_check_constraints?
      exclusion_constraints_in_create(table, tbl) if @connection.supports_exclusion_constraints?
      unique_constraints_in_create(table, tbl) if @connection.supports_unique_constraints?

      tbl.puts "  end"

      if remaining
        tbl.puts
        tbl.print remaining.string
      end

      stream.print tbl.string
    rescue => e
      stream.puts "# Could not dump table #{table.inspect} because of following #{e.class}"
      stream.puts "#   #{e.message}"
      stream.puts
    ensure
      self.table_name = nil
    end
  end
end

ActiveSupport.on_load(:active_record) do
  ActiveRecord::SchemaDumper.prepend(PreserveColumnOrder)
end

require "test_helper"

class SchemaDumpOrderTest < ActiveSupport::TestCase
  test "schema dump preserves task column order instead of sorting alphabetically" do
    io = StringIO.new
    ActiveRecord::SchemaDumper.dump(ActiveRecord::Base.connection_pool, io)
    dump = io.string

    table_region = dump[/create_table "tasks".*?end/m]
    assert table_region

    columns = table_region.scan(/t\.(\w+) "(\w+)"/).map(&:last)
    columns.reject! { |name| name == "id" }

    expected = %w[
      bsg_id name full_name wiki_link given_by
      kappa_required lightkeeper_required
      leads_to requirements start_rewards finish_rewards
      created_at updated_at
    ]

    assert_equal expected, columns
    # Sanity: the alphabetical variant would put finish_rewards before full_name.
    assert_operator columns.index("full_name"), :<, columns.index("finish_rewards")
  end
end

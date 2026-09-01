require "open3"

namespace :neon do
  desc "Replace the Neon production database with a data image of the local dev database (destructive on prod)"
  task push: :environment do
    prod_url = ENV["NEON_PROD_URL"].to_s
    if prod_url.empty?
      abort "Set NEON_PROD_URL to your Neon connection string " \
            "(console.neon.tech -> your project -> Connection details) or refuse to run."
    end

    config = ActiveRecord::Base.connection_db_config.configuration_hash
    dump_args = [ "pg_dump", "--data-only", "--no-owner", "--no-privileges" ]
    dump_args << "--host=#{config[:host]}" if config[:host]
    dump_args << "--port=#{config[:port]}" if config[:port]
    dump_args << "--username=#{config[:username]}" if config[:username]
    dump_args << "--dbname=#{config[:database]}"

    tables = ActiveRecord::Base.connection.tables.sort
    abort "No tables to push (dev database is empty)" if tables.empty?

    puts "Dumping #{config[:database]} (#{tables.size} tables)"

    env = {}
    env["PGPASSWORD"] = config[:password].to_s if config[:password].present?
    dump, dump_err, dump_status = Open3.capture3(env, *dump_args)
    abort "pg_dump failed: #{dump_err}" unless dump_status.success?

    rows = dump.scan(/^COPY /).size
    puts "Restoring into Neon... (#{rows} tables)"

    script = +"BEGIN;\n"
    script << "TRUNCATE #{tables.join(', ')} RESTART IDENTITY CASCADE;\n"
    script << dump
    script << "COMMIT;\n"

    restore_env = { "PGSSLMODE" => ENV["PGSSLMODE"].presence || "require" }
    restore_cmd = [ "psql", prod_url, "--set=ON_ERROR_STOP=1", "--quiet", "--no-psqlrc" ]
    _, restore_err, restore_status = Open3.capture3(restore_env, *restore_cmd, stdin_data: script)
    abort "Neon restore failed: #{restore_err}" unless restore_status.success?

    puts "Done: Neon now mirrors #{config[:database]} (rows moved: #{rows} COPY blocks)"
  end
end

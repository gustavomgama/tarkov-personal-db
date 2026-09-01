namespace :ci do
  desc "Run full CI pipeline locally (mirrors .github/workflows/ci.yml)"
  task all: %i[security lint fasterer development test coverage audit] do
    puts "\n✅ All CI checks passed."
  end

  desc "Brakeman static security analysis + bundler-audit"
  task :security do
    puts "── Security ──"
    run "bundle exec brakeman --no-pager --exit-on-warn"
    run "bundle exec bundler-audit"
  end

  desc "RuboCop linting"
  task :lint do
    puts "── Lint ──"
    run "bundle exec rubocop"
  end

  desc "Fasterer performance-idiom check"
  task :fasterer do
    puts "── Fasterer ──"
    run "bundle exec fasterer"
  end

  desc "Boot app in development and verify routes"
  task :development do
    puts "── Development ──"
    run "RAILS_ENV=development bundle exec rails db:prepare"
    run "RAILS_ENV=development bundle exec rails runner \"puts 'Rails booted OK: ' + Rails.env\""
    run "RAILS_ENV=development bundle exec rails routes >/dev/null"
    verify_perf_tooling("development")
  end

  desc "Run test suite"
  task :test do
    puts "── Test ──"
    verify_perf_tooling("test", clean_env: true)
    run "RAILS_ENV=test bundle exec rails test", clean_env: true
  end

  desc "Run tests with 90% line coverage enforcement"
  task :coverage do
    puts "── Coverage ──"
    run "RAILS_ENV=test bundle exec rails test", clean_env: true
    score = coverage_percent
    puts "Line coverage: #{score}%"
    abort "❌ Coverage is #{score}% — requires 90%" if score < 90
  end

  desc "Rubycritic score (≥ 75 threshold)"
  task :audit do
    puts "── Audit ──"
    run "bundle exec rubycritic --no-browser --format json app/"
    score = rubycritic_score
    puts "Rubycritic score: #{score}"
    abort "❌ Score #{score} is below 75 threshold" if score < 75
  end

  desc "Run security + lint only (fast checks)"
  task quick: %i[security lint]

  private

  def run(command, clean_env: false)
    puts "  $ #{command}"
    if clean_env
      env = ENV.to_h.merge(
        "DATABASE_URL" => nil,
        "DATABASE_URL_POOLED" => nil,
        "DATABASE_URL_UNPOOLED" => nil
      )
      system(env, command) || abort("❌ Command failed: #{command}")
    else
      system(command) || abort("❌ Command failed: #{command}")
    end
  end

  # Confirms the dev/test-only performance gems (bullet, goldiloader) are
  # actually active in the given environment, not just installed.
  def verify_perf_tooling(env, clean_env: false)
    check = "Bullet.enable? && Goldiloader.enabled? ? " \
            "(puts 'bullet + goldiloader active') : abort('perf tooling not active')"
    run "RAILS_ENV=#{env} bundle exec rails runner \"#{check}\"", clean_env: clean_env
  end

  def coverage_percent
    require "json"
    data = JSON.parse(File.read("coverage/coverage.json"))
    data.dig("total", "lines", "percent").to_f
  rescue Errno::ENOENT
    abort "❌ coverage/coverage.json not found — run tests first"
  end

  def rubycritic_score
    report = "tmp/rubycritic/report.json"
    require "json"
    data = JSON.parse(File.read(report))
    data.fetch("score", 0).to_f
  rescue Errno::ENOENT
    abort "❌ #{report} not found — rubycritic must run first"
  end
end

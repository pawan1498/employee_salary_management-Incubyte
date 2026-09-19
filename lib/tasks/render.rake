# Render's default Rails build runs assets:precompile / assets:clean even when
# there is no asset pipeline. Keep these as no-ops that do NOT boot Rails, so
# the build does not require SECRET_KEY_BASE. Migrations run in bin/render-start.sh.
namespace :assets do
  desc "No asset pipeline (API-only app)"
  task :precompile do
    puts "Skipping assets:precompile (API-only app)"
  end

  desc "No asset pipeline to clean (API-only app)"
  task :clean do
    puts "Skipping assets:clean (API-only app)"
  end
end

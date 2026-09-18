# Render's default Rails build runs assets:precompile / assets:clean even when
# there is no asset pipeline. These no-op tasks keep that build green and run
# db:prepare so migrations apply before the web process starts.
namespace :assets do
  desc "Prepare the database instead of compiling assets (API-only app)"
  task precompile: :environment do
    Rake::Task["db:prepare"].invoke if Rails.env.production?

    puts "Skipping assets:precompile (API-only app)"
  end

  desc "No asset pipeline to clean (API-only app)"
  task clean: :environment do
    puts "Skipping assets:clean (API-only app)"
  end
end

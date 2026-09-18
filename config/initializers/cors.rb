# Be sure to restart your server when you modify this file.

allowed_origins = if Rails.env.production?
  ENV.fetch("CORS_ORIGINS", "http://localhost:5173").split(",").map(&:strip)
else
  [ %r{\Ahttp://(localhost|127\.0\.0\.1)(:\d+)?\z} ]
end

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins(*allowed_origins)

    resource "*",
             headers: :any,
             methods: %i[get post patch put delete options head]
  end
end

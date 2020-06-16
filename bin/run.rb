require 'airbrake-ruby'

Airbrake.configure do |c|
  c.project_id = ENV.fetch('AIRBRAKE_PROJECT_ID')
  c.project_key = ENV.fetch('AIRBRAKE_PROJECT_KEY')
end

require_relative '../lib/ripple_worker'

worker = RippleWorker::Worker.new
worker.run

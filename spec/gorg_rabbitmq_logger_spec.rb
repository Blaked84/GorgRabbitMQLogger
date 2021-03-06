require 'spec_helper'
require 'json'
require 'active_record'
require 'gorg_service'
require 'message_handlers/log_message_handler'
require 'gorg_message_sender'
require File.expand_path('../support/conf/rabbitmq_config.rb', __FILE__)


ActiveRecord::Base.establish_connection({
  :adapter => "sqlite3",
  :database => "tests.sqlite3",
  :dbfile => "logs.sqlite"
  })

begin
  ActiveRecord::Schema.drop_table('logs')
rescue
  nil
end

ActiveRecord::Schema.define do
  create_table "logs", :force => true do |t|
    t.column "data", :string
    t.column "event", :string
    t.column "event_id", :string
    t.column "event_errors", :string
    t.column "creation_time", :string
    t.column "sender", :string
  end
end

puts "Sending message"
sender=GorgMessageSender.new(
 host: RabbitmqConfig.value_at("r_host"),
 port: RabbitmqConfig.value_at("r_port"),
 user: RabbitmqConfig.value_at("r_user"),
 pass: RabbitmqConfig.value_at("r_pass"),
 vhost: RabbitmqConfig.value_at("r_vhost"),
 exchange_name: "exchange",
 app_id: "logger-test",
 durable_exchange: true)
sender.send({this_is: "my data hash"},
 "logs",
 event_uuid: "8c4abe62-26fe-11e6-b67b-9e71128cae77",
 event_creation_time: DateTime.new(2084,05,10,01,57,00),
 event_sender_id: "test-logger"
 )
puts "-> Done"

my_service = GorgService.new
my_service.start
sleep(1)
my_service.stop

describe LogMessageHandler do
  log = Log.last
  it "save the message to the database" do
   expect(log.event).to eq("logs")
   expect(log.event_id).to eq("8c4abe62-26fe-11e6-b67b-9e71128cae77")
   expect(log.data).to eq({this_is: "my data hash"}.to_s)
   expect(log.event_errors).to eq("[]")
   expect(log.creation_time).to eq(DateTime.new(2084,05,10,01,57,00).to_s)
   expect(log.sender).to eq("test-logger")
 end 

end
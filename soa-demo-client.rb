require "bunny"
require "json"

name = "Bob"
address = "123 main"
orderId = "12345"

puts "I want some pizza"

session = Bunny.new(:host => "localhost", :username => "craftsman", :password => "utahsc2015")
session.start
ch = session.create_channel

couponqueue = ch.queue("", :exclusive => true)
couponqueue.bind("couponissued.v1")

puts "Exchange exists: "  
puts session.exchange_exists?("pizzarequested.v1")

exchange = ch.exchange("pizzarequested.v1", :passive => true)
exchange.publish({:name => name, :address => address, :toppings => ['pepperoni'], :orderId => orderId}.to_json)
puts "Pizz ordered!"

couponqueue.subscribe(:block => true) do |delivery_info, properties, body|
	puts "I got a free pizza coupon message"
	puts body
	response = JSON.parse(body)
	if response["correlationId"] == "12345"
		puts "The free pizza coupon is for me!"
		exchange.publish({:name => name, :address => address, :toppings => ['pepperoni', 'sausage'], :orderId => orderId, :coupon => response["coupon"]}.to_json)
		puts "Free pizza ordered!"
		exit
	end
end
#!/usr/bin/ruby
load "libircbot.rb"
bot = Ircbot.new("irc.freenode.org", "#maeln3", "Izam_bot", "key")
bot.connect
loop do
	tmp = bot.capture_msg
	puts "sender : #{tmp[0]}"
	puts "target : #{tmp[2]}"
	puts "Msg : #{tmp[3]}"
	if tmp[3] == "!42" then
		bot.send_msg("Answer to the Ultimate Question of Life, the Universe, and Everything", tmp[0])
	elsif tmp[3].to_s.include?("!msg")
		msg = tmp[3].gsub(/\!msg /, "")
		bot.send_msg(msg)
	elsif tmp[3] == "!quit"
		bot.quit("see")
	elsif tmp[3].to_s.include?("!nick")
		msg = tmp[3].gsub(/\!nick /, "")
		bot.send_s(":#{bot.nick} NICK #{msg}")
	elsif tmp[3].to_s.include?("!topic")
		msg = tmp[3].gsub(/\!topic /, "")
		bot.topic(msg)
	elsif tmp[3] == "!op" then
		if tmp[0] == "maeln" then
			bot.mode("+o", "maeln")
		end
	elsif tmp[3] == "!m" then
		if tmp[0] == "maeln" then
			bot.mode("+m")
		end
	end
	sleep 0.1
end

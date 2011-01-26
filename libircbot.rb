# LibIRCbot.rb
# Author:: maeln (contact@maeln.com)
# Licence:: WTFPL
# Version:: 0.2

require "socket"
#== Cette librairie à pour but de faciliter la création de Bot IRC en Ruby.
#=== Elle est simple et minimaliste tout en étant permissif.
# Si vous observez des bugs ou que vous avez des remarques, contactez moi à l'adresse : contact@maeln.com
class Ircbot
	attr_reader :server, :chan, :nick, :key, :port
	#=== Défini les différents paramètres nécessaire au bot.
	#== exemple :
	#
	#[Ce connecter à freenode sur le channel \#chan] bot = Ircbot.new("irc.freenode.org", "\#chan", "Rbot")
	# -> Le bot ce connectera au serveur irc.freenode.org, rejoindra le channel #chan et aura pour nick Rbot.
	#
	#[Ce connecter à un channel protégé par mot de passe] bot = Ircbot.new("irc.freenode.org", "\#chan", "Rbot", "passwd")
	# -> Ce connectera au channel #chan en indiquant comme mot de passe "passwd".
	#
	#[Ce connecter à un serveur qui utilise un autre port que 6667] bot = Ircbot.new("irc.freenode.org", "\#chan", "Rbot", "", 3256)
	# -> Ce connectera au serveur de freenode en utilisant le port 3256.
	# -> /!\ le 4eme champ correspond au mot de passe, si le channel que vous rejoignez n'en utilise pas laissez ce champ vide.
	def initialize(server, chan, nick, key="", port=6667)
		@server = server.chomp
		@port = port.to_i
		@chan = chan.chomp
		@nick = nick.chomp
		@key = key.chomp
	end
	
	#=== Lance la connexion avec le serveur.
	#==== Doit être utilisé avant tout autre méthode.
	#
	def connect
		begin
			@socket = TCPSocket.new(@server, @port)
			["NICK #{@nick}", "USER #{@nick} 0 * :NSSIrc user", "JOIN #{@chan} #{@key}"].each do |n|
				@socket.puts n
			end
		end
	end
	
	#=== Récupère le flux brut du socket.
	#
	def capture
		irc_tamp = @socket.gets.strip
		ping(irc_tamp)
		return irc_tamp
	end
	
	#=== Récupère le flux du socket et renvoie un Array avec les informations traitées.
	#==== Composition de l'Array :
	#* \[0] -> Pseudonyme de l'expéditeur du message.
	#* \[1] -> Host de l'expéditeur du message.
	#* \[2] -> Le destinataire du message (Note: Peut étre un channel ).
	#* \[3] -> Le contenue du message.
	#
	def capture_msg
		irc_tamp = capture
		ping(irc_tamp)
		sender = /:(\w+)/.match(irc_tamp).to_s.gsub(/^:/, "")
		host = /!(.\S+)/.match(irc_tamp).to_s.gsub(/^\!~/, "")
		target = /PRIVMSG (.\S+)/.match(irc_tamp).to_s.gsub(/PRIVMSG /, "")
		msg = /\s:(.+)+$/.match(irc_tamp)[1] unless /\s:(.+)+$/.match(irc_tamp).nil?
		res = [sender, host, target, msg]
		return res
	end
	
	#=== Récupère le flux du socket et renvoie l'information traité avec l'expression régulière passé en argument.
	#
	def capture_with_pattern(pattern)
		irc_tamp = capture
		ping(irc_tamp)
		if irc_tamp =~ pattern then
			return irc_tamp
		end
	end
	
	#=== Répond au PING du serveur pour éviter que le bot ce fasse expulser par "Ping Timeout".
	#==== NOTE: Les fonctions "capture" utilise automatiquement cette fonction.
	#
	def ping(irc_tamp)
		unless /^PING :(.+)/.match(irc_tamp).nil? then
			sender = /^PING :(.+)/.match(irc_tamp)[1]
			@socket.puts "PONG :#{sender}"
		end
	end
	
	#=== Envoie un message à un utilisateur ou à un channel.
	# Si aucun utilisateur n'est défini, le message sera envoyé sur le channel
	#==== Exemples :
	#[Envoyer un message sur le channel] bot.send_msg("Hello World !")
	#
	#[Envoyer un message privé à l'utilisateur "Jack"] bot.send_msg("Salut Jack !", user="Jack")
	#
	def send_msg(msg, user=nil)
		if user.nil? then
			@socket.puts "PRIVMSG #{@chan} :#{msg}"
		else
			@socket.puts "PRIVMSG #{user} :#{msg}"
		end
	end
	
	#=== Envoie un message non-traité directement au serveur.
	# Cette fonction peut permettre d'utiliser des spécificités non-implémenté.
	#==== Exemple :
	#[Changer le nick du bot] bot.send_s(":\#{bot.nick} NICK {nouveau nick}")
	#
	def send_s(msg)
		@socket.puts msg
	end
	
	#=== Permet de changer le mode du channel ou d'un utilisateur.
	#==== Exemples :
	#[Passer le channel en mode modéré] bot.mode("+m")
	#
	#[Donner le status d'opérateur à 'Jack'] bot.mode("+o", "Jack")
	#
	#[Enlever le status voiced à 'Jack'] bot.mode("-v", "Jack")
	#
	def mode(mode, user="")
		@socket.puts "MODE #{@chan} #{mode} #{user}"
	end
	
	#=== Modifie le titre du channel.
	#==== Exemple :
	#[Changer le titre du Channel] bot.topic("Mon chan IRC qui poutre.")
	#
	def topic(msg)
		@socket.puts "TOPIC #{@chan} :#{msg}"
	end
	
	#=== Quit le serveur IRC.
	# NOTE: Un bug empêche de laisser un message de départ.
	#==== Exemples :
	#[Quitter le serveur] bot.quit
	#
	#[Quitter le serveur en laissant un message] bot.quit("Bye bye tout le monde") #<b>Ne marche pas actuellement</b>
	#
	def quit(msg="")
		puts "QUIT :#{msg}"
		@socket.puts "QUIT :#{msg}"
		exit
	end
end
		

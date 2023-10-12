package quake;

@:publicFields
class NETSocketBase {
    var disconnected:Bool;
    var address:String;
	var connecttime:Float;
	var lastMessageTime:Float;
	var driver:Int;

    function new(address:String) {
		connecttime = NET.time;
		lastMessageTime = NET.time;
		driver = NET.driverlevel;
		this.address = address;
    }
}

interface INETSocket {
    var disconnected:Bool;
	var driver:Int;
	var lastMessageTime:Float;
	var connecttime:Float;
	var address:String;
	function Close():Void;
	function GetMessage():Int;
	function SendMessage(data:MSG):Int;
	function SendUnreliableMessage(data:MSG):Int;
	function CanSendMessage():Bool;
}

private typedef NETDriver = {
	var initialized:Bool;
	function Init():Bool;
	function Connect(host:String):INETSocket;
	function CheckNewConnections():INETSocket;
	function CheckForResend():Int;
}


@:publicFields
class NET {
	static var activeSockets:Array<INETSocket> = [];
	static var message = new MSG(8192);
	static var activeconnections = 0;
	static var driverlevel:Int;
	static var time:Float;
	static var start_time:Float;
	static var reps:Int;
	static var drivers:Array<NETDriver>;
	static var newsocket:INETSocket;

	static var messagetimeout:Cvar;
	static var hostname:Cvar;

	static function AddNewSocket(sock:INETSocket):Void {
		var i = 0;
		while (i < activeSockets.length) {
			if (activeSockets[i].disconnected)
				break;
			i++;
		}
		activeSockets[i] = sock;
	}

	static function Connect(host:String):INETSocket {
		time = Sys.FloatTime();

		if (host == 'local') {
			driverlevel = 0;
			return NET_Loop.Connect(host);
		}

		for (i in 1...drivers.length) {
			driverlevel = i;
			var dfunc = drivers[driverlevel];
			if (!dfunc.initialized)
				continue;
			var ret = dfunc.Connect(host);
			if ((cast ret) == 0) {
				CL.cls.state = connecting;
				Console.Print('trying...\n');
				start_time = time;
				reps = 0;
				throw 'NET.Connect';
			}
			if (ret != null)
				return ret;
		}

		return null;
	}

	static function CheckForResend() {
		time = Sys.FloatTime();
		var dfunc = drivers[newsocket.driver];
		if (reps <= 2) {
			if ((time - start_time) >= (2.5 * (reps + 1))) {
				Console.Print('still trying...\n');
				++reps;
			}
		} else if (reps == 3) {
			if ((time - start_time) >= 10.0) {
				Close(newsocket);
				CL.cls.state = disconnected;
				Console.Print('No Response\n');
				Host.Error('NET.CheckForResend: connect failed\n');
			}
		}
		var ret = dfunc.CheckForResend();
		if (ret == 1) {
			newsocket.disconnected = false;
			CL.Connect(newsocket);
		}
		else if (ret == -1) {
			newsocket.disconnected = false;
			Close(newsocket);
			CL.cls.state = disconnected;
			Console.Print('Network Error\n');
			Host.Error('NET.CheckForResend: connect failed\n');
		}
	}

	static function CheckNewConnections():INETSocket {
		time = Sys.FloatTime();

		for (i in 0...drivers.length) {
			driverlevel = i;
			var dfunc = drivers[driverlevel];
			if (!dfunc.initialized)
				continue;
			var ret = dfunc.CheckNewConnections();
			if (ret != null)
				return ret;
		}

		return null;
	}

	static function Close(sock:INETSocket) {
		if (sock == null)
			return;
		if (sock.disconnected)
			return;
		time = Sys.FloatTime();
		sock.Close();
		sock.disconnected = true;
	}

	static function GetMessage(sock:INETSocket):Int {
		if (sock == null)
			return -1;
		if (sock.disconnected) {
			Console.Print('NET.GetMessage: disconnected socket\n');
			return -1;
		}
		time = Sys.FloatTime();
		var ret = sock.GetMessage();
		if (sock.driver != 0) {
			if (ret == 0) {
				if ((time - sock.lastMessageTime) > messagetimeout.value) {
					Close(sock);
					return -1;
				}
			}
			else if (ret > 0)
				sock.lastMessageTime = time;
		}
		return ret;
	}

	static function SendMessage(sock:INETSocket, data:MSG):Int {
		if (sock == null)
			return -1;
		if (sock.disconnected) {
			Console.Print('NET.SendMessage: disconnected socket\n');
			return -1;
		}
		time = Sys.FloatTime();
		return sock.SendMessage(data);
	}

	static function SendUnreliableMessage(sock:INETSocket, data:MSG):Int {
		if (sock == null)
			return -1;
		if (sock.disconnected) {
			Console.Print('NET.SendUnreliableMessage: disconnected socket\n');
			return -1;
		}
		time = Sys.FloatTime();
		return sock.SendUnreliableMessage(data);
	}

	static function CanSendMessage(sock:INETSocket):Bool {
		if (sock == null)
			return false;
		if (sock.disconnected)
			return false;
		time = Sys.FloatTime();
		return sock.CanSendMessage();
	}

	static function SendToAll(data:MSG):Int {
		var count = 0, state1 = [], state2 = [];
		for (i in 0...SV.svs.maxclients) {
			Host.client = SV.svs.clients[i];
			if (Host.client.netconnection == null)
				continue;
			if (!Host.client.active) {
				state1[i] = state2[i] = true;
				continue;
			}
			if (Host.client.netconnection.driver == 0) {
				SendMessage(Host.client.netconnection, data);
				state1[i] = state2[i] = true;
				continue;
			}
			++count;
			state1[i] = state2[i] = false;
		}
		var start = Sys.FloatTime();
		while (count != 0) {
			count = 0;
			for (i in 0...SV.svs.maxclients) {
				Host.client = SV.svs.clients[i];
				if (!state1[i]) {
					if (CanSendMessage(Host.client.netconnection)) {
						state1[i] = true;
						SendMessage(Host.client.netconnection, data);
					}
					else
						GetMessage(Host.client.netconnection);
					++count;
					continue;
				}
				if (!state2[i]) {
					if (CanSendMessage(Host.client.netconnection))
						state2[i] = true;
					else
						GetMessage(Host.client.netconnection);
					++count;
				}
			}
			if ((Sys.FloatTime() - start) > 5.0)
				return count;
		}
		return count;
	}

	static function Init():Void {
		time = Sys.FloatTime();

		messagetimeout = Cvar.RegisterVariable('net_messagetimeout', '300');
		hostname = Cvar.RegisterVariable('hostname', 'UNNAMED');

		drivers = [NET_Loop, NET_WEBS];
		for (i in 0...drivers.length) {
			driverlevel = i;
			drivers[driverlevel].initialized = drivers[driverlevel].Init();
		}
	}

	static function Shutdown():Void {
		time = Sys.FloatTime();
		for (i in 0...activeSockets.length)
			Close(activeSockets[i]);
	}
}

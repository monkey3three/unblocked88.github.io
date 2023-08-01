package quake;

import js.html.ArrayBuffer;
import js.html.Uint8Array;
import quake.NET.INETSocket;

private class LoopNETSocket extends quake.NET.NETSocketBase implements INETSocket {
    var receiveMessage:Uint8Array;
    var receiveMessageLength:Int;
    var canSend:Bool;
    var other_side:LoopNETSocket;

    function new(address:String) {
    	super(address);
		this.receiveMessage = new Uint8Array(new ArrayBuffer(8192));
    }

	function Close():Void {
		if (other_side != null)
			other_side.other_side = null;
		receiveMessageLength = 0;
		canSend = false;
		if (this == NET_Loop.client)
			NET_Loop.client = null;
		else
			NET_Loop.server = null;
	}	

	function GetMessage():Int {
		if (receiveMessageLength == 0)
			return 0;
		var ret = receiveMessage[0];
		var length = receiveMessage[1] + (receiveMessage[2] << 8);
		if (length > NET.message.data.byteLength)
			Sys.Error('GetMessage: overflow');
		NET.message.cursize = length;
		new Uint8Array(NET.message.data).set(receiveMessage.subarray(3, length + 3));
		receiveMessageLength -= length;
		if (receiveMessageLength >= 4) {
			for (i in 0...receiveMessageLength)
				receiveMessage[i] = receiveMessage[length + 3 + i];
		}
		receiveMessageLength -= 3;
		if (other_side != null && ret == 1)
			other_side.canSend = true;
		return ret;
	}

	function SendMessage(data:MSG):Int {
		if (other_side == null)
			return -1;
		var bufferLength = other_side.receiveMessageLength;
		other_side.receiveMessageLength += data.cursize + 3;
		if (other_side.receiveMessageLength > 8192)
			Sys.Error('SendMessage: overflow');
		var buffer = other_side.receiveMessage;
		buffer[bufferLength] = 1;
		buffer[bufferLength + 1] = data.cursize & 0xff;
		buffer[bufferLength + 2] = data.cursize >> 8;
		buffer.set(new Uint8Array(data.data, 0, data.cursize), bufferLength + 3);
		canSend = false;
		return 1;
	}

	function SendUnreliableMessage(data:MSG):Int {
		if (other_side == null)
			return -1;
		var bufferLength = other_side.receiveMessageLength;
		other_side.receiveMessageLength += data.cursize + 3;
		if (other_side.receiveMessageLength > 8192)
			Sys.Error('SendMessage: overflow');
		var buffer = other_side.receiveMessage;
		buffer[bufferLength] = 2;
		buffer[bufferLength + 1] = data.cursize & 0xff;
		buffer[bufferLength + 2] = data.cursize >> 8;
		buffer.set(new Uint8Array(data.data, 0, data.cursize), bufferLength + 3);
		return 1;
	}

	function CanSendMessage():Bool {
		if (other_side != null)
			return canSend;
		return false;
	}
}


@:publicFields
class NET_Loop {
	static var localconnectpending = false;
	static var client:LoopNETSocket;
	static var server:LoopNETSocket;
	static var initialized = false;

	static function Init():Bool {
		return true;
	}

	static function Connect(host:String):INETSocket {
		if (host != 'local')
			return null;

		localconnectpending = true;

		if (client == null)
			client = new LoopNETSocket('localhost');
		client.receiveMessageLength = 0;
		client.canSend = true;

		if (server == null)
			server = new LoopNETSocket('LOCAL');
		server.receiveMessageLength = 0;
		server.canSend = true;

		client.other_side = server;
		server.other_side = client;

		NET.AddNewSocket(client);
		NET.AddNewSocket(server);

		return client;
	}

	static function CheckNewConnections():INETSocket {
		if (!localconnectpending)
			return null;
		localconnectpending = false;
		server.receiveMessageLength = 0;
		server.canSend = true;
		client.receiveMessageLength = 0;
		client.canSend = true;
		return server;
	}


	static function CheckForResend():Int throw "Not implemented";
}

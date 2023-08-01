package quake;

import js.Browser.document;
import js.Browser.window;
import js.html.ArrayBuffer;
import js.html.BinaryType;
import js.html.Uint8Array;
import quake.NET.INETSocket;

@:native("WebSocket")
extern class WebSocket extends js.html.WebSocket {
	public var data_socket:WEBSNETSocket;
}

private class WEBSNETSocket extends quake.NET.NETSocketBase implements INETSocket {
    var receiveMessage:Array<Uint8Array>;
    var native_socket:WebSocket;

    function new(address:String) {
    	super(address);
		this.disconnected = true;
		this.receiveMessage = [];
		this.native_socket = new WebSocket(address, 'quake');
		this.native_socket.data_socket = this;
		this.native_socket.binaryType = BinaryType.ARRAYBUFFER;
		this.native_socket.onerror = OnError;
		this.native_socket.onmessage = OnMessage;
	}

	function OnError():Void {
		NET.Close(this);
	}

	function OnMessage(message:MSG):Void {
		var data = message.data;
		if (Std.is(data, String))
			return;
		if (data.byteLength > 8000)
			return;
		receiveMessage.push(new Uint8Array(data));
	}

	function Close():Void {
		if (native_socket != null)
			native_socket.close(1000);
	}

	function GetMessage():Int {
		if (native_socket == null)
			return -1;
		if (native_socket.readyState != 1)
			return -1;
		if (receiveMessage.length == 0)
			return 0;
		var message = receiveMessage.shift();
		NET.message.cursize = message.length - 1;
		new Uint8Array(NET.message.data).set(message.subarray(1, message.length));
		return message[0];
	}


	function SendMessage(data:MSG):Int {
		if (native_socket == null)
			return -1;
		if (native_socket.readyState != 1)
			return -1;
		var buf = new ArrayBuffer(data.cursize + 1), dest = new Uint8Array(buf);
		dest[0] = 1;
		dest.set(new Uint8Array(data.data, 0, data.cursize), 1);
		native_socket.send(buf);
		return 1;
	}

	function SendUnreliableMessage(data:MSG):Int {
		if (native_socket == null)
			return -1;
		if (native_socket.readyState != 1)
			return -1;
		var buf = new ArrayBuffer(data.cursize + 1), dest = new Uint8Array(buf);
		dest[0] = 2;
		dest.set(new Uint8Array(data.data, 0, data.cursize), 1);
		native_socket.send(buf);
		return 1;
	}

	function CanSendMessage():Bool {
		if (native_socket == null)
			return false;
		if (native_socket.readyState == 1)
			return true;
		return false;
	}
}


@:publicFields
class NET_WEBS {
	static var available = false;
	static var initialized = false;

	static function Init():Bool {
		if ((cast window).WebSocket == null || document.location.protocol == 'https:')
			return false;
		available = true;
		return true;
	}

	static function Connect(host:String):INETSocket {
		if (host.length <= 5)
			return null;
		if (host.charCodeAt(5) == 47)
			return null;
		if (host.substring(0, 5) != 'ws://')
			return null;
		host = 'ws://' + host.split('/')[2];
		var sock = try new WEBSNETSocket(host) catch (e:Any) return null;
		NET.newsocket = sock;
		NET.AddNewSocket(sock);
		return cast 0;
	}

	static function CheckNewConnections():INETSocket {
		return null;
	}

	static function CheckForResend():Int {
		var sock:WEBSNETSocket = cast NET.newsocket;
		if (sock.native_socket.readyState == 1)
			return 1;
		if (sock.native_socket.readyState != 0)
			return -1;
		return null;
	}
}

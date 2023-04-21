/*
	All this code is copyright Orteil, 2016-2020.
	Spoilers ahead.
	welcome to my awful soup
	https://orteil.dashnet.org
*/

/*
	Note : this is the game engine. It loads and interprets data files.
	The default data file is located at /data.js and contains all techs, traits, units, policies, resources, terrains etc.
*/

VERSION=1;//increment by 1 with every major change; will make old datasets incompatible
SAVESLOT='alpha';//actual slot will be 'legacySave-'+SAVESLOT
UPDATELOG=[
	{date:'2013-2014',title:'Prototype',text:['started working on a prototype for a cross between Civilization and an idle game after the sudden success of my game, <a href="//orteil.dashnet.org/cookieclicker/" target="_blank">Cookie Clicker</a>','encountered some issues with gameplay design and ended up putting the project on hold']},
	{date:'2015',title:'Prototype, part II',text:['the broken, buggy prototype has been <a href="//orteil.dashnet.org/experiments/legacy/" target="_blank">put online for all to see</a>']},
	{date:'2016',title:'Return of the Prototype',text:['motivated by the positive response to the previous prototype, a new version was started from scratch with fresh new ideas']},
	{date:'3/23/2017',title:'Alpha launch',text:['a playable alpha is launched publicly','at this point, the game features 54 technologies, 42 units, and 91 resources']},
	{date:'3/24/2017',title:'Alpha patch',text:['added an outline to your explored territory on the map','hunters dying, quarries/mines collapsing and scouts getting lost should no longer disproportionately harm your population; those effects have also been made less frequent','people get sick less often','added a new policy to control birth rate','mines can now mine for salt','resources now display how much you\'re gaining and losing every tick']},
	{date:'3/25/2017',title:'Alpha patch 2',text:['units are now queued for automatic purchase rather than being purchased directly; this allows them to be automatically replaced should they be harmed','fixed bug with units getting lost or wounded way too much (maybe for good this time?)','buildings no longer require you to have available tools and workers to build them, as this was confusing and not very fun','graves now decay over time to make room for more; architects now have an "undertaker" mode that automatically creates graves if there are unburied corpses','material and food decay were slowed and storage units have bigger capacity']},
	{date:'3/25/2017',title:'Alpha patch 3',text:['units can now be active or inactive; a building that lacks workers, or a crafter that lacks its tools, will simply go inactive instead of disappearing, and will be made active again when the requirements are met; units are inactive when they\'re first created and when they\'ve just been set to a new mode','the mausoleum can be completed again','graves should behave better']},
	{date:'3/26/2017',title:'Alpha patch 4',text:['fixed many miscellaneous bugs, hopefully','scouting and exploring speed now properly depends on how many wanderers or scouts you have','gathering is now soft-capped by natural resources; this means having many gathering units but few tiles won\'t have optimal results','removing units now removes the idle ones first']},
	{date:'3/26/2017',title:'Alpha patch 5',text:['your people will no longer be completely apathetic and neutrally healthy from some bug with consuming food','fire pits warm more people','clothiers no longer need to know leatherworking to sew grass clothing','happiness and health sources are detailed more explicitly','many messages now have icons']},
	{date:'3/28/2017',title:'Alpha patch 6',text:['unit modes now have icons','added custom bulk-buying in units','gathering was reworked, expect different rates for resource production','workers dying while working probably won\'t result in ghost workers anymore','units have innate priorities in the context of being created and acting, with food-producing units going first','happier people now produce more babies, while unhappy people just aren\'t feeling it as much','corpses decay slowly']},
];



//misc handy stuff

function l(what) {return document.getElementById(what);}
function choose(arr) {return arr[Math.floor(Math.random()*arr.length)];}
function randomFloor(x) {if ((x%1)<Math.random()) return Math.floor(x); else return Math.ceil(x);}
String.prototype.replaceAll=function(search,replacement)
{var target=this;return target.replace(new RegExp(search,'g'),replacement);};
function AddEvent(html_element,event_name,event_function)
{
	if(html_element.attachEvent) html_element.attachEvent("on" + event_name, function() {event_function.call(html_element);});
	else if(html_element.addEventListener) html_element.addEventListener(event_name, event_function, false);
}
function addHover(el,className)
{
	AddEvent(el,'mouseover',function(className){return function(e){e.target.classList.add(className);};}(className));
	AddEvent(el,'mouseout',function(className){return function(e){e.target.classList.remove(className);};}(className));
}

function addCSSRule(sheet, selector, rules, index)
{
	if("insertRule" in sheet) sheet.insertRule(selector + "{" + rules + "}", index);
	else if("addRule" in sheet)	sheet.addRule(selector, rules, index);
}

function shuffle(array) {
    var tmp, current, top = array.length;

    if(top) while(--top) {
        current = Math.floor(Math.random() * (top + 1));
        tmp = array[current];
        array[current] = array[top];
        array[top] = tmp;
    }
    return array;
}

function addObjects(obj1,obj2)
{
	var out={};
	for (var i in obj1)
	{out[i]=obj1[i];}
	for (var i in obj2)
	{
		if (!out[i]) out[i]=0;
		out[i]+=obj2[i];
	}
	return out;
}

function isEmpty(obj)
{
	return (Object.keys(obj).length === 0 && obj.constructor === Object);
}

function byteCount(s){return encodeURI(s).split(/%..|./).length-1;}
//also see : http://code.stephenmorley.org/javascript/finding-the-memory-usage-of-objects/

function decodeEntities(string){
	var elem=document.createElement('div');
	elem.innerHTML=string;
	return elem.textContent;
}

function b64EncodeUnicode(str){
	return btoa(encodeURIComponent(str).replace(/%([0-9A-F]{2})/g, function(match, p1) {
		return String.fromCharCode('0x' + p1);
	}));
}
function b64DecodeUnicode(str){
	return decodeURIComponent(atob(str).split('').map(function(c) {
		return '%' + ('00' + c.charCodeAt(0).toString(16)).slice(-2);
	}).join(''));
}

function triggerAnim(element,anim)
{
	if (!element) return;
	element.classList.remove(anim);
	void element.offsetWidth;
	element.classList.add(anim);
}

//file save function from https://github.com/eligrey/FileSaver.js
var saveAs=saveAs||function(view){"use strict";if(typeof navigator!=="undefined"&&/MSIE [1-9]\./.test(navigator.userAgent)){return}var doc=view.document,get_URL=function(){return view.URL||view.webkitURL||view},save_link=doc.createElementNS("http://www.w3.org/1999/xhtml","a"),can_use_save_link="download"in save_link,click=function(node){var event=new MouseEvent("click");node.dispatchEvent(event)},is_safari=/Version\/[\d\.]+.*Safari/.test(navigator.userAgent),webkit_req_fs=view.webkitRequestFileSystem,req_fs=view.requestFileSystem||webkit_req_fs||view.mozRequestFileSystem,throw_outside=function(ex){(view.setImmediate||view.setTimeout)(function(){throw ex},0)},force_saveable_type="application/octet-stream",fs_min_size=0,arbitrary_revoke_timeout=500,revoke=function(file){var revoker=function(){if(typeof file==="string"){get_URL().revokeObjectURL(file)}else{file.remove()}};if(view.chrome){revoker()}else{setTimeout(revoker,arbitrary_revoke_timeout)}},dispatch=function(filesaver,event_types,event){event_types=[].concat(event_types);var i=event_types.length;while(i--){var listener=filesaver["on"+event_types[i]];if(typeof listener==="function"){try{listener.call(filesaver,event||filesaver)}catch(ex){throw_outside(ex)}}}},auto_bom=function(blob){if(/^\s*(?:text\/\S*|application\/xml|\S*\/\S*\+xml)\s*;.*charset\s*=\s*utf-8/i.test(blob.type)){return new Blob(["\ufeff",blob],{type:blob.type})}return blob},FileSaver=function(blob,name,no_auto_bom){if(!no_auto_bom){blob=auto_bom(blob)}var filesaver=this,type=blob.type,blob_changed=false,object_url,target_view,dispatch_all=function(){dispatch(filesaver,"writestart progress write writeend".split(" "))},fs_error=function(){if(target_view&&is_safari&&typeof FileReader!=="undefined"){var reader=new FileReader;reader.onloadend=function(){var base64Data=reader.result;target_view.location.href="data:attachment/file"+base64Data.slice(base64Data.search(/[,;]/));filesaver.readyState=filesaver.DONE;dispatch_all()};reader.readAsDataURL(blob);filesaver.readyState=filesaver.INIT;return}if(blob_changed||!object_url){object_url=get_URL().createObjectURL(blob)}if(target_view){target_view.location.href=object_url}else{var new_tab=view.open(object_url,"_blank");if(new_tab==undefined&&is_safari){view.location.href=object_url}}filesaver.readyState=filesaver.DONE;dispatch_all();revoke(object_url)},abortable=function(func){return function(){if(filesaver.readyState!==filesaver.DONE){return func.apply(this,arguments)}}},create_if_not_found={create:true,exclusive:false},slice;filesaver.readyState=filesaver.INIT;if(!name){name="download"}if(can_use_save_link){object_url=get_URL().createObjectURL(blob);setTimeout(function(){save_link.href=object_url;save_link.download=name;click(save_link);dispatch_all();revoke(object_url);filesaver.readyState=filesaver.DONE});return}if(view.chrome&&type&&type!==force_saveable_type){slice=blob.slice||blob.webkitSlice;blob=slice.call(blob,0,blob.size,force_saveable_type);blob_changed=true}if(webkit_req_fs&&name!=="download"){name+=".download"}if(type===force_saveable_type||webkit_req_fs){target_view=view}if(!req_fs){fs_error();return}fs_min_size+=blob.size;req_fs(view.TEMPORARY,fs_min_size,abortable(function(fs){fs.root.getDirectory("saved",create_if_not_found,abortable(function(dir){var save=function(){dir.getFile(name,create_if_not_found,abortable(function(file){file.createWriter(abortable(function(writer){writer.onwriteend=function(event){target_view.location.href=file.toURL();filesaver.readyState=filesaver.DONE;dispatch(filesaver,"writeend",event);revoke(file)};writer.onerror=function(){var error=writer.error;if(error.code!==error.ABORT_ERR){fs_error()}};"writestart progress write abort".split(" ").forEach(function(event){writer["on"+event]=filesaver["on"+event]});writer.write(blob);filesaver.abort=function(){writer.abort();filesaver.readyState=filesaver.DONE};filesaver.readyState=filesaver.WRITING}),fs_error)}),fs_error)};dir.getFile(name,{create:false},abortable(function(file){file.remove();save()}),abortable(function(ex){if(ex.code===ex.NOT_FOUND_ERR){save()}else{fs_error()}}))}),fs_error)}),fs_error)},FS_proto=FileSaver.prototype,saveAs=function(blob,name,no_auto_bom){return new FileSaver(blob,name,no_auto_bom)};if(typeof navigator!=="undefined"&&navigator.msSaveOrOpenBlob){return function(blob,name,no_auto_bom){if(!no_auto_bom){blob=auto_bom(blob)}return navigator.msSaveOrOpenBlob(blob,name||"download")}}FS_proto.abort=function(){var filesaver=this;filesaver.readyState=filesaver.DONE;dispatch(filesaver,"abort")};FS_proto.readyState=FS_proto.INIT=0;FS_proto.WRITING=1;FS_proto.DONE=2;FS_proto.error=FS_proto.onwritestart=FS_proto.onprogress=FS_proto.onwrite=FS_proto.onabort=FS_proto.onerror=FS_proto.onwriteend=null;return saveAs}(typeof self!=="undefined"&&self||typeof window!=="undefined"&&window||this.content);if(typeof module!=="undefined"&&module.exports){module.exports.saveAs=saveAs}else if(typeof define!=="undefined"&&define!==null&&define.amd!=null){define([],function(){return saveAs})}


//the old Beautify function from Cookie Clicker, shortened to B(value)
//initially adapted from http://cookieclicker.wikia.com/wiki/Frozen_Cookies_%28JavaScript_Add-on%29
function formatEveryThirdPower(notations)
{
	return function (value)
	{
		var base = 0,
		notationValue = '';
		if (value >= 1000 && isFinite(value))
		{
			value /= 1000;
			while(Math.round(value) >= 1000)
			{
				value /= 1000;
				base++;
			}
			if (base > notations.length) {return 'Inf';} else {notationValue = notations[base];}
		}
		return ( Math.round(value * 10) / 10 ) + notationValue;
	};
}

function rawFormatter(value) {return Math.round(value * 1000) / 1000;}

var numberFormatters =
[
	rawFormatter,
	formatEveryThirdPower([
		' thousand',
		' million',
		' billion',
		' trillion',
		' quadrillion',
		' quintillion',
		' sextillion',
		' septillion',
		' octillion',
		' nonillion',
		' decillion'
	]),
	formatEveryThirdPower([
		'k',
		'M',
		'B',
		'T',
		'Qa',
		'Qi',
		'Sx',
		'Sp',
		'Oc',
		'No',
		'Dc'
	])
];
function Beautify(value,floats)
{
	var negative=(value<0);
	var decimal='';
	if (Math.abs(value)<1000 && floats>0) decimal='.'+(value.toFixed(floats).toString()).split('.')[1];
	value=Math.floor(Math.abs(value));
	var formatter=numberFormatters[2];
	var output=formatter(value).toString().replace(/\B(?=(\d{3})+(?!\d))/g,',');
	if (output=='0') negative=false;
	return negative?'-'+output:output+decimal;
}
var B=Beautify;

function BeautifyTime(value)
{
	//value should be in seconds
	value=Math.max(Math.ceil(value,0));
	var years=Math.floor(value/31536000);
	value-=years*31536000;
	var days=Math.floor(value/86400);
	value-=days*86400;
	var hours=Math.floor(value/3600)%24;
	value-=hours*3600;
	var minutes=Math.floor(value/60)%60;
	value-=minutes*60;
	var seconds=Math.floor(value)%60;
	var str='';
	if (years) str+=B(years)+'Y';
	if (days || str!='') str+=B(days)+'d';
	if (hours || str!='') str+=hours+'h';
	if (minutes || str!='') str+=minutes+'m';
	if (seconds || str!='') str+=seconds+'s';
	if (str=='') str+='0s';
	return str;
}
var BT=BeautifyTime;

function cap(str)
{return str.charAt(0).toUpperCase()+str.slice(1);}

//polyfills

if (!String.prototype.includes) {
  Object.defineProperty(String.prototype, "includes", {value: 
		function(search, start) {
			'use strict';
			if (typeof start !== 'number') {
			  start = 0;
			}
			
			if (start + search.length > this.length) {
			  return false;
			} else {
			  return this.indexOf(search, start) !== -1;
			}
		  }
  });
}

if (!Array.prototype.includes) {
  Object.defineProperty(Array.prototype, "includes", {value: 
		function(searchElement /*, fromIndex*/ ) {
		'use strict';
		var O = Object(this);
		var len = parseInt(O.length, 10) || 0;
		if (len === 0) {
		  return false;
		}
		var n = parseInt(arguments[1], 10) || 0;
		var k;
		if (n >= 0) {
		  k = n;
		} else {
		  k = len + n;
		  if (k < 0) {k = 0;}
		}
		var currentElement;
		while (k < len) {
		  currentElement = O[k];
		  if (searchElement === currentElement) { // NaN !== NaN
			return true;
		  }
		  k++;
		}
		return false;
	  }
  });
}


//other fun stuff

//seeded random function, courtesy of http://davidbau.com/archives/2010/01/30/random_seeds_coded_hints_and_quintillions.html
(function(a,b,c,d,e,f){function k(a){var b,c=a.length,e=this,f=0,g=e.i=e.j=0,h=e.S=[];for(c||(a=[c++]);d>f;)h[f]=f++;for(f=0;d>f;f++)h[f]=h[g=j&g+a[f%c]+(b=h[f])],h[g]=b;(e.g=function(a){for(var b,c=0,f=e.i,g=e.j,h=e.S;a--;)b=h[f=j&f+1],c=c*d+h[j&(h[f]=h[g=j&g+b])+(h[g]=b)];return e.i=f,e.j=g,c})(d)}function l(a,b){var e,c=[],d=(typeof a)[0];if(b&&"o"==d)for(e in a)try{c.push(l(a[e],b-1))}catch(f){}return c.length?c:"s"==d?a:a+"\0"}function m(a,b){for(var d,c=a+"",e=0;c.length>e;)b[j&e]=j&(d^=19*b[j&e])+c.charCodeAt(e++);return o(b)}function n(c){try{return a.crypto.getRandomValues(c=new Uint8Array(d)),o(c)}catch(e){return[+new Date,a,a.navigator.plugins,a.screen,o(b)]}}function o(a){return String.fromCharCode.apply(0,a)}var g=c.pow(d,e),h=c.pow(2,f),i=2*h,j=d-1;c.seedrandom=function(a,f){var j=[],p=m(l(f?[a,o(b)]:0 in arguments?a:n(),3),j),q=new k(j);return m(o(q.S),b),c.random=function(){for(var a=q.g(e),b=g,c=0;h>a;)a=(a+c)*d,b*=d,c=q.g(1);for(;a>=i;)a/=2,b/=2,c>>>=1;return(a+c)/b},p},m(c.random(),b)})(this,[],Math,256,6,52);

chars='abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPRSTUVWXYZ0123456789'.split('');
makeSeed=function(len)
{
	var str='';
	for (var i=0;i<len;i++)
	{str+=choose(chars);}
	return str;
}

pics=[];
Pic=function(url)
{
	return pics[url];
}

PicLoader=function(urls,callback)
{
	this.pics=[];
	this.toLoad=urls.length;
	this.loaded=0;
	this.callback=callback;
	
	for (var i in urls)
	{
		var pic=new Image();
		//pic.setAttribute('crossOrigin','Anonymous');
		pic.src=urls[i];
		pic.onload=function(loader){return function(){loader.toLoad--;loader.loaded++;if (loader.toLoad<=0) loader.callback();}}(this);
		pics[urls[i]]=pic;
	}
}

ERROR=function(what)
{
	console.log(what);
	console.trace();
}


//getting this started

G={};//(actually short for "Game")

G.Launch=function()
{

	/*=====================================================================================
	INITIALIZE
	=======================================================================================*/	
	G.engineVersion=VERSION;
	
	
	G.LoadResources=function()
	{
		var resources=[
			'img/terrain.png',
			'img/blot.png',
			'img/iconSheet.png?v=1'
		];
		var loader=new PicLoader(resources,function(){G.Init();});//load all resources then init the game when done
	}
	G.selectVersion=function(e)
	{
		var version=G.versionsById[e.target.value];
		if (version) window.location.href=version.url;
	}
	G.Init=function()
	{
		G.T=0;
		G.drawT=0;
		G.fps=30;
		
		G.l=l('game');
		G.wrapl=l('wrap');
		G.wrapl.classList.add('skinRock');
		
		G.local=true;
		if (window.location.protocol=='http:' || window.location.protocol=='https:') G.local=false;
		G.isIE=false;
		if (document.documentMode || /Edge/.test(navigator.userAgent)) G.isIE=true;
		
		if (G.versions)
		{
			G.versionsById=[];
			for (var i in G.versions)
			{
				G.versionsById[G.versions[i].version]=G.versions[i];
			}
			var str='';
			str+='<select id="versionsSelect" onchange="G.selectVersion(event);">';
			for (var i in G.versions)
			{
				var version=G.versions[i];
				str+='<option '+(version.version==G.engineVersion?'selected="selected" ':'')+'value="'+version.version+'">'+version.name+'</option>';
			}
			str+='</select>';
			l('versions').innerHTML=str;
		}
		
		//upscale pixel icons and apply to stylesheet (this is kind of cheaty)
		//only for Edge and IE since they have """"trouble"""" with nearest-neighbor
		G.iconScale=1;
		G.iconURL='img/iconSheet.png?v=1';
		if (G.isIE)
		{
			var img=Pic('img/iconSheet.png?v=1');
			var c=document.createElement('canvas');c.width=img.width*2;c.height=img.height*2;
			var ctx=c.getContext('2d');
			ctx.mozImageSmoothingEnabled=false;
			ctx.webkitImageSmoothingEnabled=false;
			ctx.msImageSmoothingEnabled=false;
			ctx.imageSmoothingEnabled=false;
			ctx.drawImage(img,0,0,img.width*2,img.height*2);
			
			var sheet=(function()
			{
				var style=document.createElement('style');
				style.appendChild(document.createTextNode(''));
				document.head.appendChild(style);
				return style.sheet;
			})();
			addCSSRule(sheet,'.IE .icon','background-image:url('+c.toDataURL('image/png')+')');
			G.iconURL=c.toDataURL('image/png');
			addCSSRule(sheet,'.IE .icon.double','background-image:url('+G.iconURL+'),url('+G.iconURL+')');
			G.wrapl.classList.add('IE');
			G.iconScale=2;
		}
		
		
		G.w=window.innerWidth;
		G.h=window.innerHeight;
		G.resizing=false;
		G.stabilizeResize=function()
		{
			G.resizing=false;
			//change page layout to fit width
			if (G.w<288*3) {G.wrapl.classList.remove('narrow');G.wrapl.classList.add('narrower');}
			else if (G.w<384*3) {G.wrapl.classList.remove('narrower');G.wrapl.classList.add('narrow');}
			else {G.wrapl.classList.remove('narrower');G.wrapl.classList.remove('narrow');}
			//if (G.tab.id=='unit') G.cacheUnitBounds();
		}
		G.resize=function()
		{
			G.resizing=true;
		}
		window.addEventListener('resize',function(event)
		{
			G.w=window.innerWidth;
			G.h=window.innerHeight;
			G.resize();
		});
		
		G.mouseDown=false;//mouse button just got pressed
		G.mouseUp=false;//mouse button just got released
		G.mousePressed=false;//mouse button is currently down
		G.clickL=0;//what element got clicked
		AddEvent(document,'mousedown',function(event){G.mouseDown=true;G.mousePressed=true;G.mouseDragFrom=event.target;G.mouseDragFromX=G.mouseX;G.mouseDragFromY=G.mouseY;});
		AddEvent(document,'mouseup',function(event){G.mouseUp=true;G.mouseDragFrom=0;});
		AddEvent(document,'click',function(event){G.clickL=event.target;});
		
		G.mouseX=0;
		G.mouseY=0;
		G.mouseMoved=0;
		G.draggedFrames=0;//increment every frame when we're moving the mouse and we're clicking
		G.GetMouseCoords=function(e)
		{
			var posx=0;
			var posy=0;
			if (!e) var e=window.event;
			if (e.pageX||e.pageY)
			{
				posx=e.pageX;
				posy=e.pageY;
			}
			else if (e.clientX || e.clientY)
			{
				posx=e.clientX+document.body.scrollLeft+document.documentElement.scrollLeft;
				posy=e.clientY+document.body.scrollTop+document.documentElement.scrollTop;
			}
			var x=0;
			var y=0;
			G.mouseX=posx-x;
			G.mouseY=posy-y;
			G.mouseMoved=1;
		}
		AddEvent(document,'mousemove',G.GetMouseCoords);
		
		G.Scroll=0;
		G.handleScroll=function(e)
		{
			if (!e) e=event;
			G.Scroll=(e.detail<0||e.wheelDelta>0)?1:-1;
		};
		AddEvent(document,'DOMMouseScroll',G.handleScroll);
		AddEvent(document,'mousewheel',G.handleScroll);
		
		G.keys=[];//key is being held down
		G.keysD=[];//key was just pressed down
		G.keysU=[];//key was just pressed up
		//shift=16, ctrl=17
		AddEvent(window,'keyup',function(e){
			if ((document.activeElement.nodeName=='TEXTAREA' || document.activeElement.nodeName=='INPUT') && e.keyCode!=27) return;
			if (e.keyCode==27) {}//esc
			else if (e.keyCode==13) {}//enter
			G.keys[e.keyCode]=0;
			G.keysD[e.keyCode]=0;
			G.keysU[e.keyCode]=1;
		});
		AddEvent(window,'keydown',function(e){
			if (!G.keys[e.keyCode])//prevent repeats
			{
				if (e.ctrlKey && e.keyCode==83) {e.preventDefault();}//ctrl-s
				if ((document.activeElement.nodeName=='TEXTAREA' || document.activeElement.nodeName=='INPUT') && e.keyCode!=27) return;
				if (e.keyCode==32) {e.preventDefault();}//space
				G.keys[e.keyCode]=1;
				G.keysD[e.keyCode]=1;
				G.keysU[e.keyCode]=0;
				//console.log('Key pressed : '+e.keyCode);
			}
		});
		AddEvent(window,'blur',function(e){
			G.keys=[];
			G.keysD=[];
			G.keysU=[];
		});
		
		//latency compensator stuff
		G.time=new Date().getTime();
		G.fpsMeasure=new Date().getTime();
		G.accumulatedDelay=0;
		G.catchupLogic=0;
		G.fpsStartTime=0;
		G.frameNumber=0;
		G.getFps=function()
		{
			G.frameNumber++;
			var currentTime=(Date.now()-G.fpsStartTime )/1000;
			var result=Math.floor((G.frameNumber/currentTime));
			if (currentTime>1)
			{
				G.fpsStartTime=Date.now();
				G.frameNumber=0;
			}
			return result;
		}
		G.fpsGraph=l('fpsGraph');
		G.fpsGraphCtx=G.fpsGraph.getContext('2d');
		var ctx=G.fpsGraphCtx;
		ctx.fillStyle='#000';
		ctx.fillRect(0,0,128,64);
		G.currentFps=0;
		G.previousFps=0;
		
		G.animIntro=true;
		G.introDur=G.fps*1;
				
		//is there a file save already? if yes, load it, if not, hard-reset and start a new game
		if (!G.Load())
		{
			G.Reset(true);
			G.NewGame();
		}
		
		G.resize();
		
		G.Loop();
	}
	
	/*=====================================================================================
	UPDATES, DRAWS & LOGICS
	=======================================================================================*/
	G.update=[];//these involve rebuilding a whole display's DOM
	G.draw=[];//these involve updating elements within the display and should be invoked within G.Draw
	G.logic=[];//these involve updating gameplay elements and should be invoked within G.Logic
	
	
	/*=====================================================================================
	SAVING AND LOADING
	=======================================================================================*/
	G.saveTo='legacySave-'+SAVESLOT;
	
	G.FileSave=function()
	{
		var filename='legacySave';
		var text=G.Export();
		var blob=new Blob([text],{type:'text/plain;charset=utf-8'});
		saveAs(blob,filename+'.txt');
	}
	G.FileLoad=function(e)
	{
		if (e.target.files.length==0) return false;
		var file=e.target.files[0];
		var reader=new FileReader();
		reader.onload=function(e)
		{
			G.Import(e.target.result);
		}
		reader.readAsText(file);
	}
	G.Export=function()
	{
		return G.Save(true);
	}
	G.Import=function(str)
	{
		G.importStr=str;
		G.Load(false);
	}
	
	G.Save=function(toStr)
	{
		//if toStr is true, don't actually save; return a string containing the save
		if (!toStr && G.local && G.isIE) return false;
		var str='';
		
		//general
		G.lastDate=parseInt(Date.now());
		str+=
			parseFloat(G.engineVersion).toString()+';'+
			parseFloat(G.startDate).toString()+';'+
			parseFloat(G.fullDate).toString()+';'+
			parseFloat(G.lastDate).toString()+';'+
			parseFloat(G.year).toString()+';'+
			parseFloat(G.day).toString()+';'+
			parseFloat(G.fastTicks).toString()+';'+
			parseFloat(G.furthestDay).toString()+';'+
			parseFloat(G.totalDays).toString()+';'+
			parseFloat(G.resets).toString()+';'+
			'';
		str+='|';
		
		//settings
		for (var i in G.settings)
		{
			var me=G.settings[i];
			if (me.type=='toggle') str+=(me.value?'1':'0');
			else if (me.type=='int') str+=parseInt(me.value).toString();
			str+=';';
		}
		str+='|';
		
		//mods
		for (var i in G.mods)
		{
			var me=G.mods[i];
			str+='"'+me.url.replaceAll('"','&quot;')+'":';
			if (me.achievs)
			{
				//we save achievements separately for each mod
				for (var ii in me.achievs)
				{
					str+=parseInt(me.achievs[ii].won).toString()+',';
				}
			}
			str+=':';
			//tracked stats (not fully implemented yet)
			str+=parseFloat(G.trackedStat).toString();
			str+=';';
		}
		str+='|';
		
		//culture and names
		str+=(G.cultureSeed)+';';
		str+=G.getSafeName('ruler')+';';
		str+=G.getSafeName('civ')+';';
		str+=G.getSafeName('civadj')+';';
		str+=G.getSafeName('inhab')+';';
		str+=G.getSafeName('inhabs')+';';
		str+='|';
		
		//maps
		str+=(G.currentMap.seed)+';';
		
		var map=G.currentMap;
		for (var x=0;x<map.w;x++)
		{
			for (var y=0;y<map.h;y++)
			{
				var tile=map.tiles[x][y];
				str+=
					parseInt(tile.owner).toString()+':'+
					parseInt(Math.floor(tile.explored*100)).toString()+':'+
					',';
			}
		}
		
		str+='|';
		
		//techs & traits
		var len=G.techsOwned.length;
		for (var i=0;i<len;i++)
		{
			str+=parseInt(G.techsOwned[i].tech.id).toString()+';';
		}
		str+='|';
		var len=G.traitsOwned.length;
		for (var i=0;i<len;i++)
		{
			str+=parseInt(G.traitsOwned[i].trait.id).toString()+';';
		}
		str+='|';
		
		//policies
		var len=G.policy.length;
		for (var i=0;i<len;i++)
		{
			var me=G.policy[i];
			if (me.visible)
			{
				str+=parseInt(me.id).toString()+','+parseInt(me.mode?me.mode.num:0).toString()+';';
			}
		}
		str+='|';
		
		//res
		var len=G.res.length;
		for (var i=0;i<len;i++)
		{
			var me=G.res[i];
			str+=
				(!me.meta?(parseFloat(Math.round(me.amount)).toString()+','):'')+
				(me.displayUsed?(parseFloat(Math.round(me.used)).toString()+','):'')+
				(me.visible?'1':'0')+';';
		}
		str+='|';
		
		//units
		var len=G.unitsOwned.length;
		for (var i=0;i<len;i++)
		{
			var me=G.unitsOwned[i];
			if (true)//me.amount>0)
			{
				str+=parseInt(me.unit.id).toString()+','+
				parseFloat(Math.round(me.amount)).toString()+
				((me.unit.gizmos||me.unit.wonder)?
					(','+parseInt(me.unit.wonder?me.mode:(me.mode?me.mode.num:0)).toString()+','+//mode
					parseInt(me.percent).toString())//percent
					:'')+
				','+parseFloat(Math.round(me.targetAmount)).toString()+
				','+parseFloat(Math.round(me.idle)).toString()+
				';';
			}
		}
		str+='|';
		
		//chooseboxes
		var len=G.chooseBox.length;
		for (var i=0;i<len;i++)
		{
			var me=G.chooseBox[i];
			var choices=[parseFloat(me.roll)];
			for (var ii in me.choices)
			{
				choices.push(parseInt(me.choices[ii].id));
			}
			str+=choices.join(',')+';';
		}
		str+='|';
		
		//console.log('SAVE');
		//console.log(str);
		str=escape(str);
		str=b64EncodeUnicode(str);
		//console.log(Math.ceil(byteCount(str)/1000)+'kb');
		if (!toStr)
		{
			window.localStorage.setItem(G.saveTo,str);
			G.middleText('- Game saved -');
			//console.log('Game saved successfully.');
		}
		else return str;
	}
	
	G.stringsLoadedN=0;
	G.stringsLoaded=[];
	G.parseLoadStrings=function(str)
	{
		str=str.substring(1,str.length-1);
		//str=decodeEntities(str);
		G.stringsLoaded[G.stringsLoadedN]=str;
		G.stringsLoadedN++;
		return 'str'+(G.stringsLoadedN-1);
	}
	G.readLoadedString=function(str)
	{
		if (!str || str.indexOf('str')==-1) return 0;
		return G.stringsLoaded[parseInt(str.split('str')[1])];
	}
	
	G.importStr=0;
	G.Load=function(doneLoading)
	{
		if (G.importStr) {var local=G.importStr;}
		else
		{
			var local=window.localStorage.getItem(G.saveTo);
		}
		if (!local) return false;
		var str='';
		str=b64DecodeUnicode(local);
		//console.log('LOAD');
		//console.log(Math.ceil(byteCount(str)/1000)+'kb');
		str=unescape(str);
		//console.log(str);
		if (str!='null' && str!='')
		{
			G.Reset();
			G.resetSettings();
			
			//take care of strings first
			G.stringsLoadedN=0;
			G.stringsLoaded=[];
			str=str.replace(/"(.*?)"/gi,G.parseLoadStrings);
			
			str=str.split('|');
			
			var s=0;
			//general
			var spl=str[s++].split(';');
			//console.log('General : '+spl);
			var i=0;
			var fromVersion=parseFloat(spl[i++]);
			G.startDate=parseFloat(spl[i++]);
			G.fullDate=parseFloat(spl[i++]);
			G.lastDate=parseFloat(spl[i++]);
			G.year=parseFloat(spl[i++]);
			G.day=parseFloat(spl[i++]);
			G.fastTicks=parseFloat(spl[i++]);
			G.furthestDay=parseFloat(spl[i++]);
			G.totalDays=parseFloat(spl[i++]);
			G.resets=parseFloat(spl[i++]);
			//accumulate fast ticks when offline
			var timeOffline=Math.max(0,(Date.now()-G.lastDate)/1000);
			G.fastTicks+=Math.floor(timeOffline);
			G.nextFastTick=Math.ceil((1-(timeOffline-Math.floor(timeOffline)))*G.tickDuration);
			
			//settings
			var spl=str[s++].split(';');
			//console.log('Settings : '+spl);
			var len=spl.length;
			for (var i=0;i<len;i++)
			{
				if (spl[i]!='' && G.settings[i])
				{
					var me=G.settings[i];
					if (me.type=='toggle') me.value=(spl[i]=='1'?true:false);
					else if (me.type=='int') me.value=parseInt(spl[i]);
				}
			}
			for (var i in G.settings)
			{
				var me=G.settings[i];
				if (me.onChange) me.onChange();
			}
			
			
			if (!doneLoading)
			{
				//mods
				var spl=str[s++].split(';');
				var mods=[];
				for (var i in spl)
				{
					var spl2=spl[i].split(':');
					var val=G.readLoadedString(spl2[0]);
					if (val)
					{
						mods.push(val.replaceAll('&quot;','"'));
					}
				}
				G.LoadMods(mods,G.Load,false);
				return 1;
			}
			
			G.importStr=0;
			
			//mod achievs & tracked stats
			var spl=str[s++].split(';');
			for (var i in spl)
			{
				var spl2=spl[i].split(':');
				var mod=G.mods[i];
				if (spl2[1] && mod.achievs)
				{
					bit=spl2[1].split(',');
					for (var ii in bit)
					{
						if (bit[ii])
						{
							if (mod.achievs[ii]) mod.achievs[ii].won=parseInt(bit[ii]);
						}
					}
				}
				if (spl2[2])
				{
					bit=spl2[2].split(',');
					for (var ii in bit)
					{
						if (bit[ii])
						{
							G.trackedStat=parseFloat(bit[ii]);
						}
					}
				}
			}
			
			//culture and names
			var spl=str[s++].split(';');
			var ss=0;
			G.cultureSeed=spl[ss++];
			G.setSafeName('ruler',G.readLoadedString(spl[ss++]),'Anonymous');
			G.setSafeName('civ',G.readLoadedString(spl[ss++]),'nameless tribe');
			G.setSafeName('civadj',G.readLoadedString(spl[ss++]),'tribal');
			G.setSafeName('inhab',G.readLoadedString(spl[ss++]),'inhabitant');
			G.setSafeName('inhabs',G.readLoadedString(spl[ss++]),'inhabitants');
			
			//maps
			var spl=str[s++].split(';');
			//console.log('Map tiles : '+spl);
			G.currentMap=new G.Map(0,24,24,spl[0]);
			
			var map=G.currentMap;
			var spl2=spl[1].split(',');
			var I=0;
			for (var x=0;x<map.w;x++)
			{
				for (var y=0;y<map.h;y++)
				{
					if (spl2[I])
					{
						var tile=map.tiles[x][y];
						spl3=spl2[I].split(':');
						tile.owner=parseInt(spl3[0]);
						tile.explored=parseInt(spl3[1])/100;
					}
					I++;
				}
			}
			
			G.updateMapForOwners(map);
			G.centerMap(map);
			
			//techs & traits
			var spl=str[s++].split(';');
			//console.log('Techs : '+spl);
			var len=spl.length;
			for (var i=len-1;i>=0;i--)
			{if (spl[i]!='') {G.gainTech(G.know[parseInt(spl[i])]);}}
			
			var spl=str[s++].split(';');
			//console.log('Traits : '+spl);
			var len=spl.length;
			for (var i=len-1;i>=0;i--)
			{if (spl[i]!='') G.gainTrait(G.know[parseInt(spl[i])]);}
			
			//policies
			var spl=str[s++].split(';');
			//console.log('Policies : '+spl);
			var len=spl.length;
			for (var i=len-1;i>=0;i--)
			{if (spl[i]!='') {
				var spl2=spl[i].split(',');
				var me=G.policy[parseInt(spl2[0])];
				G.gainPolicy(me);
				me.mode=me.modesById[parseInt(spl2[1])];
			}}
			
			//res
			var spl=str[s++].split(';');
			//console.log('Resources : '+spl);
			var len=G.res.length;
			for (var i=0;i<len;i++)
			{
				if (spl[i])
				{
					var me=G.res[i];
					var spl2=spl[i].split(',');
					if (parseInt(spl2[spl2.length-1])==1) me.visible=true; else me.visible=false;
					if (!me.meta) me.amount=parseFloat(spl2[0]);
					if (me.displayUsed) me.used=parseFloat(spl2[1]);
				}
			}
			
			//units
			var spl=str[s++].split(';');
			//console.log('Units : '+spl);
			var len=spl.length;
			for (var i=len-1;i>=0;i--)
			{if (spl[i]!='')
				{
					var spl2=spl[i].split(',');
					//unit id, amount, and if unit has gizmos : mode, percent
					var obj={
						id:G.unitN,
						unit:G.unit[parseInt(spl2[0])],
						amount:parseFloat(spl2[1]),
						targetAmount:((typeof spl2[4]!=='undefined')?parseFloat(spl2[4]):parseFloat(spl2[1])),
						idle:((typeof spl2[5]!=='undefined')?parseFloat(spl2[5]):0),
						displayedAmount:0,
						mode:parseInt(spl2[2])||0,
						percent:parseInt(spl2[3]),
						popups:[]
						};
					G.unitsOwned.unshift(obj);
					var unit=G.unitsOwned[0];
					if (unit.unit.modesById[0]) unit.mode=unit.unit.modesById[unit.mode];
					G.unitsOwnedNames.unshift(G.unit[parseInt(spl2[0])].name);
					G.unitN++;
				}
			}
			
			//assign unit .splitOf
			var prev=0;
			var len=G.unitsOwned.length;
			for (var i=0;i<len;i++)
			{
				var me=G.unitsOwned[i];
				if (prev && me.unit.id==prev.unit.id) me.splitOf=prev;
				else prev=me;
			}
			prev=0;
			
			//chooseboxes
			var spl=str[s++].split(';');
			var len=spl.length;
			for (var i=len-1;i>=0;i--)
			{if (spl[i]!='')
				{
					G.chooseBox[i].choices=[];
					var spl2=spl[i].split(',');
					for (var ii in spl2)
					{
						if (ii==0) G.chooseBox[i].roll=parseFloat(spl2[ii]);
						else G.chooseBox[i].choices[ii-1]=G.know[parseInt(spl2[ii])];
					}
				}
			}
			
			G.runUnitReqs();
			G.runPolicyReqs();
			
			G.applyAchievEffects('load');
			
			G.updateEverything();
			G.createTopInterface();
			G.createDebugMenu();
			if (G.tabs[G.settingsByName['tab'].value]) G.setTab(G.tabs[G.settingsByName['tab'].value]);
			G.setSetting('forcePaused',0);
			
			l('blackBackground').style.opacity=0;
			if (timeOffline>=1) G.middleText('- Welcome back -<br><small>You accumulated '+B(timeOffline)+' fast ticks while you were away.</small>',true);
			
			G.rememberAchievs=true;
			
			G.animIntro=true;
			G.introDur=G.fps*1;
		
			G.doFunc('game loaded');
			
			G.Logic(true);//force a tick (solves some issues with display updates; this howeverr means loading a paused game, saving and reloading will make a single day go by everytime, which isn't ideal)
			
			console.log('Game loaded successfully.');
			return true;
		}
		return false;
	}
	
	G.Clear=function()
	{
		//erase the save and start a new one, handy when the page crashes when testing new save formats
		console.log('Save data cleared. Refresh the page to take effect.');
		G.T=0;
		window.localStorage.setItem(G.saveTo,'');
		var debug=0;
		if (G.getSetting('debug')) debug=1;
		G.Reset(true);
		if (debug) G.setSetting('debug',1);
		G.NewGame();
	}
	
	G.Reset=function(hard)
	{
		//clean all data and set the stage
		//console.log('Resetting...');
		G.T=0;
		
		if (hard) G.resetSettings();
		
		G.startDate=parseInt(Date.now());//when we started playing
		if (hard) G.fullDate=parseInt(Date.now());//when we started playing (carries over with resets)
		G.lastDate=parseInt(Date.now());//when we last saved the game (used to compute offline progression)
		
		G.tick=0;//how many ticks have elapsed since we started
		G.nextTick=0;
		G.year=0;//current game year (can be calculated from G.tick) - 5 irl minutes = 1 ingame year
		G.day=0;//300 days in a year; 1 day = 1 irl second
		
		if (hard)
		{
			G.resets=0;//how many ascending resets we've done
			G.furthestDay=G.year;//furthest time we've pushed a game
			G.totalDays=0;//total time we've done across all games
			G.trackedStat=0;//this tracks population for now, but should be generalized in the future
		}
		
		G.fastTicks=0;//how many fast ticks we've accumulated by being paused or offline; we can run the game on fast speed until these run out
		G.nextFastTick=G.tickDuration;
		
		G.on=true;//set this to false when game over
		
		G.deleteSelfUpdatingTexts();
		G.dialogue.init();
		G.widget.init();
		G.tooltip.init();
		G.infoPopup.init();
		G.initMessages();
		G.particlesInit();
		
		G.buildTabs();
		
		if (hard) {G.savedAchievs=[];G.rememberAchievs=false;}
		
		G.CreateData();
		
		G.resInstances=[];
		G.unitN=0;
		G.unitsOwned=[];
		G.unitsOwnedNames=[];
		G.techN=0;
		G.traitN=0;
		G.techsOwned=[];
		G.techsOwnedNames=[];
		G.traitsOwned=[];
		G.traitsOwnedNames=[];
		G.shortMemory=5;
		G.longMemory=15;
		G.shouldRunReqs=0;
		
		G.exploreNewTiles=0;
		G.exploreOwnedTiles=0;
		G.allowShoreExplore=false;
		G.allowOceanExplore=false;
		
		G.names=[];
		G.maps=[];
		
		G.resCategoriesByName=[];
		for (var i in G.resCategories)
		{
			if (typeof G.resCategories[i].open==='undefined') G.resCategories[i].open=true;
			G.resCategoriesByName[i]=G.resCategories[i];
		}
		for (var i in G.res)
		{
			if (G.res[i].category && G.resCategoriesByName[G.res[i].category]) G.resCategoriesByName[G.res[i].category].base.push(G.res[i].name);
		}
		
		G.unitCategoriesByName=[];
		for (var i in G.unitCategories)
		{
			if (typeof G.unitCategories[i].open==='undefined') G.unitCategories[i].open=true;
			G.unitCategoriesByName[i]=G.unitCategories[i];
			G.unitCategories[i].base=[];
		}
		for (var i in G.unit)
		{
			if (G.unit[i].category && G.unitCategoriesByName[G.unit[i].category]) G.unitCategoriesByName[G.unit[i].category].base.push(G.unit[i]);
		}
		
		G.policyCategoriesByName=[];
		for (var i in G.policyCategories)
		{
			if (typeof G.policyCategories[i].open==='undefined') G.policyCategories[i].open=true;
			G.policyCategoriesByName[i]=G.policyCategories[i];
			G.policyCategories[i].base=[];
		}
		for (var i in G.policy)
		{
			if (G.policy[i].category && G.policyCategoriesByName[G.policy[i].category]) G.policyCategoriesByName[G.policy[i].category].base.push(G.policy[i]);
		}
		
		G.knowCategoriesByName=[];
		for (var i in G.knowCategories)
		{
			if (typeof G.knowCategories[i].open==='undefined') G.knowCategories[i].open=true;
			G.knowCategoriesByName[i]=G.knowCategories[i];
			G.knowCategories[i].base=[];
		}
		for (var i in G.know)
		{
			if (G.know[i].category && G.knowCategoriesByName[G.know[i].category]) G.knowCategoriesByName[G.know[i].category].base.push(G.know[i]);
		}
		
		for (var i in G.chooseBox)
		{
			G.initChooseBox(G.chooseBox[i]);
		}
		
		/*for (var i in G.unit)
		{
		}
		for (var i in G.tech)
		{
		}
		for (var i in G.trait)
		{
		}*/
		
		
		//reset map controls
		G.initMap();
		
		G.sequence='main';
		/*this is the game's state, which can have the following values :
			-"loading", when resources are being loaded
			-"failed loading", when the loading sequence times out without completing
			-"checking", when all mods are loaded and their status is being checked
			-"updating", when all mods are checked and their manifests are being checked
			-"main", regular gameplay
			-"settle", a screen where the player can start a new game and settle on a tile
		*/
	
		l('foreground').style.display='none';
		
		var div=l('deleteOnLoad');
		if (div)
		{
			div.outerHTML='';
			delete div;
		}
	}
	G.NewGameWithSameMods=function()
	{
		var mods=[];
		for (var i in G.mods)
		{
			mods.push(G.mods[i].url);
		}
		G.NewGame(false,mods);
	}
	
	G.savedAchievs=[];
	G.rememberAchievs=false;
	G.NewGame=function(doneLoading,mods)
	{
		//clean up data, create a map and ask the player to pick a starting location
		if (!doneLoading)
		{
			//save achievements for each mod so we can reapply them later
			if (G.rememberAchievs)
			{
				var achievs=[];
				for (var i in G.mods)
				{
					var me=G.mods[i];
					achievs[me.name]=[];
					if (me.achievs)
					{
						for (var ii in me.achievs)
						{
							achievs[me.name].push(me.achievs[ii].won);
						}
					}
				}
				G.savedAchievs=achievs;
			}
			G.rememberAchievs=false;
			
			G.LoadMods(mods||['data.js'],G.NewGame,true);
			return 0;
		}
		
		try
		{
			G.Reset();
			l('blackBackground').style.opacity=1;
			
			G.modsStr='';
			G.newModsStr='';
			for (var i in G.mods)
			{
				G.modsStr+=G.mods[i].url+'\n';
			}
			
			G.applyAchievEffects('pre-new');
			G.sequence='settle';
		}
		catch(err)
		{
			G.sequence='failed loading';
			console.log('Something went wrong :');
			console.log(err.message||err);
			
			G.dialogue.popup(function(div){
				return '<div style="width:480px;height:240px;"><div class="fancyText title">Error!</div>'+
				'<div class="bitBiggerText scrollBox underTitle"><div class="par">Something went wrong when launching a new game :</div><div class="divider"></div>'+
				'<div class="par" style="color:#f30;">'+(err.message||err)+'</div>'+
				'</div>'+
				'<div class="buttonBox">'+
					G.button({tooltip:'Try to select different mods this time!',text:'Back to menu',classes:'frameless',onclick:function(){G.dialogue.forceClose();G.NewGame();}})+
				'</div></div>';
			},'noClose');
			return 0;
		}
		
		//create starting names
		G.cultureSeed=makeSeed(5);
		G.setName('ruler',G.translate(cap(G.getRandomString(3,5)),['primitive'],G.cultureSeed));
		var civname=cap(G.getRandomString(3,6));
		G.setName('civ',G.translate(civname,['primitive'],G.cultureSeed));
		
		if (Math.random()<0.05)
		{
			G.setName('inhab','child of '+G.getName('ruler'));
			G.setName('inhabs','children of '+G.getName('ruler'));
		}
		else
		{
			G.setName('inhab',G.translate(civname+G.getRandomString(1),['primitive'],G.cultureSeed));
			var str=G.getName('inhab');
			var finds=['s','x','z'];
			if (finds.indexOf(str.slice(-1))==-1) str+='s';
			else str+='es';
			G.setName('inhabs',str);
		}
		
		var str=G.getName('civ').toLowerCase();
		var finds=['a','e','i','o','u','y'];
		if (finds.indexOf(str.slice(-1))==-1) str+='';//ends in consonant
		else str+=choose(['n','d','s','t','b','l']);//ends in vowel
		str+=choose(['ian','ish','ese','an']);
		G.setName('civadj',str);
		
		
		G.dialogue.popup(function(div){
			return '<div style="padding:16px;min-width:320px;"><div class="fancyText title">Start a new game</div>'+
			G.button({style:'position:absolute;right:-6px;top:-6px;',tooltip:'Select mods for this playthrough.',text:'Use mods',onclick:function(e){G.SelectMods();}})+
			G.button({style:'position:absolute;left:-6px;top:-6px;',tooltip:'View the game\'s version history.',text:'Update log',onclick:function(e){G.dialogue.popup(G.tabPopup['updates'],'bigDialogue');}})+
			G.button({style:'position:absolute;left:-6px;top:20px;',tooltip:'Change the game\'s settings.',text:'Settings',onclick:function(e){G.dialogue.popup(G.tabPopup['settings'],'bigDialogue');}})+
			'<div class="framed bgMid fancyText" style="position:absolute;left:-2px;bottom:-26px;">'+G.textWithTooltip('About this alpha','<div style="width:240px;text-align:left;padding:4px;"><div class="par">The game in its current state features stone age technology and up to some parts of iron age.</div><div class="par">Features to be added later include agriculture, religion, commerce, military, and interactions with other civilizations, among other things planned.</div><div class="par">Feedback about bugs, oversights and technological inaccuracies are appreciated! (Send me a message to my tumblr at the top)</div><div class="par">Thank you for playing this alpha!</div><div class="par" style="text-align:right;">-Orteil</div></div>')+'</div>'+
			G.doFunc('new game blurb','What is your name?<br>')+
			G.field({style:'width:100%;',text:G.getName('ruler'),tooltip:'Enter your name here.<br>Make it something memorable!',oninput:function(val){G.setName('ruler',val);}})+
			'<div class="divider"></div>'+
			(G.resets>0?('You have '+B(G.resets)+' ascension'+(G.resets==1?'':'s')+' behind you.<br>'):'')+
			'You choose to start somewhere...<br><br>'+
			/*G.button({style:'display:block;width:100%;',tooltip:'Start your civilization!',text:'Well okay then',onclick:function(e){var names=G.names;G.dialogue.forceClose();G.NewGameConfirm();G.names=names;}})+*/
			G.button({style:'width:33%;min-width:75px;box-shadow:0px 0px 1px 1px #963;',/*style:'display:block;width:100%;',*/tooltip:'Start your civilization in a harsh terrain with scarce natural resources.',text:'Awful',onclick:function(e){G.startingType=1;var names=G.names;G.dialogue.forceClose();G.NewGameConfirm();G.names=names;}})+
			G.button({style:'width:33%;min-width:75px;box-shadow:0px 0px 1px 1px #693;',/*style:'display:block;width:100%;',*/tooltip:'Start your civilization in a welcoming terrain full of natural resources.',text:'Pleasant',onclick:function(e){G.startingType=0;var names=G.names;G.dialogue.forceClose();G.NewGameConfirm();G.names=names;}})+
			G.button({style:'width:33%;min-width:75px;box-shadow:0px 0px 1px 1px #666;',/*style:'display:block;width:100%;',*/tooltip:'Start your civilization in a random place on the map.<br>Who knows how your people will fare in these strange lands!',text:'Random',onclick:function(e){G.startingType=2;var names=G.names;G.dialogue.forceClose();G.NewGameConfirm();G.names=names;}})+
			'</div>';
		},'noClose');
	}
	G.NewGameConfirm=function()
	{
		//the player has selected a starting location; launch the game proper
		//G.Reset();
		G.sequence='main';
		G.T=0;
		
		G.rememberAchievs=true;
		for (var i in G.savedAchievs)
		{
			//reload achievements
			if (G.modsByName[i] && G.modsByName[i].achievs)
			{
				for (var ii in G.savedAchievs[i])
				{
					if (G.modsByName[i].achievs[ii]) G.modsByName[i].achievs[ii].won=G.savedAchievs[i][ii];
				}
			}
		}
		
		//init everything
		
		G.createMaps();
		
		for (var i in G.res)
		{
			G.res[i].amount=G.res[i].startWith;
		}
		for (var i in G.tech)
		{
			if (G.tech[i].startWith) G.gainTech(G.tech[i]);
		}
		for (var i in G.trait)
		{
			if (G.trait[i].startWith) G.gainTrait(G.trait[i]);
		}
		for (var i in G.policy)
		{
			if (G.policy[i].startWith) G.gainPolicy(G.policy[i]);
		}
		
		for (var i in G.res)
		{
			G.res[i].tick(G.res[i],G.tick);
		}
		
		G.runUnitReqs();
		G.runPolicyReqs();
		
		G.applyAchievEffects('new');
		
		G.updateEverything();
		G.createTopInterface();
		G.createDebugMenu();
		
		for (var i in G.unit)
		{
			if (G.unit[i].startWith) {G.buyUnitByName(G.unit[i].name,G.unit[i].startWith);}
		}
		
		l('blackBackground').style.opacity=0;
		
		G.setSetting('forcePaused',0);
		G.setSetting('paused',0);
		G.setSetting('fast',0);
		
		G.animIntro=true;
		G.introDur=G.fps*3;
		
		G.doFunc('new game');
		
		G.Message({type:'important',text:'If this is your first time playing, you may want to consult some quick '+G.button({text:'Getting started',tooltip:'Read a few tips on how to make it past the stone age.',onclick:function(){G.dialogue.popup(function(div){
			return '<div style="width:480px;min-height:320px;height:75%;">'+
				'<div class="fancyText title">A few tips on how to not die horribly :</div>'+
				'<div class="fancyText bitBiggerText scrollBox underTitle" style="text-align:left;padding:16px;">'+
				'<div style="float:right;margin:8px;width:121px;text-align:center;line-height:80%;"><img style="box-shadow:2px 2px 2px 1px #000;" src="img/helpLocation.jpg"/><br><small>Mouse over these buttons for more explanations!</small></div>'+
				'<div class="bulleted">early on, focus most of your workers on food gathering</div>'+
				'<div class="bulleted">assign a few spare workers as dreamers, in order to get some Insight which you can use to research technologies</div>'+
				'<div class="bulleted">check the territory tab and click your starting location; if you\'ve got very few sources of food or water, you might want to restart the game</div>'+
				'<div class="bulleted">don\'t bother researching fishing or hunting if none of your tiles have animals or fish!</div>'+
				'<div class="bulleted">enabling elder/child work policies can be useful if you need extra workers, but may prove detrimental to your people\'s health</div>'+
				'<div class="bulleted">if things get too hectic, you can pause the game and take your time</div>'+
				'<div class="bulleted">this is an early alpha, so you don\'t have to worry about meeting other civilizations just yet</div>'+
				'<div class="bulleted">sometimes things just go wrong; don\'t lose hope, you can always start over!</div>'+
				'</div>'+
			'</div><div class="buttonBox">'+
				G.dialogue.getCloseButton('Got it!')+
			'</div></div>';
		});}})+' tips.'});
	}
	G.SelectMods=function()
	{
		G.dialogue.popup(function(div){
			var modsStr=G.modsStr;
			G.newModsStr=modsStr;
			return '<div style="padding:16px;width:480px;"><div class="fancyText title">Select mods</div>'+
			'<div class="par">Enter the URLs for mods you want to use, separated by linebreaks.</div><div class="par"><b>data.js</b> is the default content used by the game.</div><div class="par"><b><span style="color:#f30;">Note :</span> once your game starts, you won\'t be able<br>to change your mods until you start a new game.</b></div><div class="par"><b><span style="color:#f30;">Note :</span> removing a mod will also remove<br>any achievements linked to it.</b></div><div class="par"><b><span style="color:#f30;">Note :</span> only load mods from sources you trust!</b></div>'+
			G.textarea({style:'width:100%;height:180px;',text:modsStr,select:true,oninput:function(val){G.newModsStr=val;}})+
			'<br><br></div>'+
			'<div class="buttonBox">'+
				G.button({text:'Load mods',classes:'frameless',onclick:function(){
					G.dialogue.close();
					var mods=G.newModsStr;
					mods=mods.split('\n');
					var mods2=[];
					for (var i in mods)
					{
						mods[i]=mods[i].trim()
						if (mods[i].length>0) mods2.push(mods[i]);
					}
					G.NewGame(false,mods2);
				}})+
				G.dialogue.getCloseButton('Cancel')+
			'</div>';
		});
	}
	
	G.GameOver=function()
	{
		if (G.on)
		{
			G.on=false;
			G.doFunc('game over');
		}
	}
	
	
	/*=====================================================================================
	SOME INTERFACE STUFF
	=======================================================================================*/
	G.createTopInterface=function()
	{
		var str=''+
		'<div class="flourishL"></div><div class="framed fancyText bgMid" style="display:inline-block;padding:8px 12px;font-weight:bold;font-size:18px;font-variant:small-caps;" id="date">-</div><div class="flourishR"></div><br>'+
		'<div class="flourish2L"></div>'+
		'<div id="fastTicks" class="framed" style="display:inline-block;padding-left:8px;padding-right:8px;font-weight:bold;">0</div>'+
		G.button({id:'pauseButton',
			text:'<div class="image" style="width:9px;background:url(img/playButtons.png) 0px 0px;"></div>',
			tooltip:'Time will be stopped.<br>Generates fast ticks.',
			onclick:function(){G.setSetting('paused',1);}
		})+
		G.button({id:'playButton',
			text:'<div class="image" style="width:9px;background:url(img/playButtons.png) -11px 0px;"></div>',
			tooltip:'Time will pass by normally - 1 day every second.',
			onclick:function(){G.setSetting('paused',0);G.setSetting('fast',0);}
		})+
		G.button({id:'fastButton',
			text:'<div class="image" style="width:9px;background:url(img/playButtons.png) -21px 0px;"></div>',
			tooltip:'Time will go by about 30 times faster - 1 month every second.<br>Uses up fast ticks.<br>May lower browser performance while active.',
			onclick:function(){if (G.fastTicks>0) {G.setSetting('paused',0);G.setSetting('fast',1);}}
		})+
		'<div class="flourish2R"></div>';
		
		l('topInterface').innerHTML=str;
		
		G.addTooltip(l('date'),function(){return '<div class="barred">Date</div><div class="par">This is the current date in your civilization.<br>One day elapses every second, and 300 days make up a year.</div>';},{offY:-8});
		G.addTooltip(l('fastTicks'),function(){return '<div class="barred">Fast ticks</div><div class="par">This is how many ingame days you can run at fast speed.</div><div class="par">You gain a fast tick for every second you\'re paused or offline.</div><div class="par">You also gain fast ticks everytime you research a technology.</div><div class="divider"></div><div class="par">You currently have <b>'+BT(G.fastTicks)+'</b> of game time saved up,<br>which will execute in <b>'+BT(G.fastTicks/30)+'</b> at fast speed,<br>advancing your civilization by <b>'+G.BT(G.fastTicks)+'</b>.</div>';},{offY:-8});
		
		l('fastTicks').onclick=function(e)
		{
			if (G.getSetting('debug'))
			{
				//debug : gain fast ticks
				G.fastTicks+=10*G.getBuyAmount();
				G.fastTicks=Math.max(0,G.fastTicks);
			}
		};
		
		G.addCallbacks();
		G.updateSpeedButtons();
	}
	G.updateSpeedButtons=function()
	{
			var div=l('pauseButton');
			if (div)
			{
				var speed=1;
				if (G.getSetting('fast')) speed=2;
				if (G.getSetting('paused') || G.getSetting('forcePaused')) speed=0;
				if (speed==0) {if (G.getSetting('animations')) {triggerAnim(l('pauseButton'),'plop');} l('pauseButton').classList.add('on');l('playButton').classList.remove('on');l('fastButton').classList.remove('on');}
				else if (speed==1) {if (G.getSetting('animations')) {triggerAnim(l('playButton'),'plop');} l('pauseButton').classList.remove('on');l('playButton').classList.add('on');l('fastButton').classList.remove('on');}
				else if (speed==2) {if (G.getSetting('animations')) {triggerAnim(l('fastButton'),'plop');} l('pauseButton').classList.remove('on');l('playButton').classList.remove('on');l('fastButton').classList.add('on');}
			}
	}
	G.createDebugMenu=function()
	{
		var str=''+
		'<div style="float:left;">'+
		G.button({text:'New game',tooltip:'Instantly start a new game.',onclick:function(){G.T=0;G.NewGameWithSameMods();}})+
		G.button({text:'Load',tooltip:'Reload the save.',onclick:function(){G.T=0;G.Load();}})+
		G.button({text:'Clear',tooltip:'Wipe save data.',onclick:function(){G.Clear();}})+
		'<br>'+
		G.button({text:'ALMIGHTY',tooltip:'Unlock every tech, trait and policy.',onclick:function(){
			for (var i in G.tech)
			{
				if (!G.techsOwnedNames.includes(G.tech[i].name)) G.gainTech(G.tech[i]);
			}
			for (var i in G.trait)
			{
				if (!G.traitsOwnedNames.includes(G.trait[i].name)) G.gainTrait(G.trait[i]);
			}
			for (var i in G.policy)
			{
				G.gainPolicy(G.policy[i]);
			}
			G.shouldRunReqs=true;
			G.middleText('- You are almighty! -');
		}})+
		G.writeSettingButton({id:'showAllRes',name:'showAllRes',text:'Show resources',tooltip:'Toggle whether all resources should be visible.'})+
		G.writeSettingButton({id:'tieredDisplay',name:'tieredDisplay',text:'Show tiers',tooltip:'Toggle whether technologies should display in tiers instead of in the order they were researched.<br>When in that mode, click a tech to highlight its ancestors and descendants.'})+
		'<br>'+
		G.button({text:'Reveal map',tooltip:'Explore the whole map instantly.',onclick:function(){G.revealMap(G.currentMap);}})+
		G.textWithTooltip('?','<div style="width:240px;text-align:left;">This is the debug menu. Please debug responsibly.<br>Further debug abilities while this mode is active :<div class="bulleted">click resources to add/remove some (keyboard shortcuts work the same way they do for purchasing units)</div><div class="bulleted">ctrl-click a tech, trait or policy to remove it (may have strange, buggy effects)</div><div class="bulleted">click the Fast ticks display to get more fast ticks</div><div class="bulleted">always see tech costs and requirements</div><div class="bulleted">gain access to debug robot units</div><div class="bulleted">edit the map</div></div>','infoButton')+
		'</div>';
		l('debug').innerHTML=str;
		
		G.addCallbacks();
	}
	G.Cheat=function()
	{
		if (!G.getSetting('debug'))
		{G.setSetting('debug',1);G.middleText('- Debug mode activated -');G.Message({type:'important',text:'Debug mode activated.'});return 'Debug mode activated.';}
		else {G.setSetting('debug',0);G.middleText('- Debug mode disabled -');G.Message({type:'important',text:'Debug mode disabled.'});return 'Debug mode disabled.';}
	}
	G.RuinTheFun=G.Cheat;
	G.Debug=G.Cheat;
	
	
	//some neat functions i wish i came up with earlier
	
	G.buttonsN=0;
	G.button=function(obj)
	{
		//returns a string for a new button; creates a callback that must be applied after the html has been created, with G.addCallbacks()
		//obj can have text, tooltip (text that shows on hover), onclick (function executed when button is clicked), classes (CSS classes added to the button), id (force button to have that id)
		var id=obj.id||('button-'+G.buttonsN);
		var str='<div '+(obj.style?('style="'+obj.style+'" '):'')+'class="button'+(obj.classes?(' '+obj.classes):'')+'" id="'+id+'">'+(obj.text||'-')+'</div>';
		if (obj.onclick || obj.tooltip || obj.tooltipFunc)
		{
			G.pushCallback(function(id,obj){return function(){
				if (l(id))
				{
					if (obj.tooltip) G.addTooltip(l(id),function(){return obj.tooltip;},{offY:-8});
					else if (obj.tooltipFunc) G.addTooltip(l(id),obj.tooltipFunc,{offY:-8});
					if (obj.onclick) l(id).onclick=obj.onclick;
				}
			}}(id,obj));
		}
		G.buttonsN++;
		return str;
	}
	
	G.fieldN=0;
	G.field=function(obj)
	{
		//returns a string for a new text input field; creates a callback that must be applied after the html has been created, with G.addCallbacks()
		//obj can have text (the default value), min and max (character length limits), tooltip (text that shows on hover), oninput (function executed when text is entered in the field), onclick (function executed when field is clicked), classes (CSS classes added)
		var id=G.fieldN;
		if (!obj.textarea) var str='<input type="text" '+(obj.style?('style="'+obj.style+'" '):'')+'class="field'+(obj.classes?(' '+obj.classes):'')+'" id="field-'+id+'" value="'+(obj.text.replaceAll('"','&quot;')||'')+'"/>';
		else var str='<textarea '+(obj.style?('style="'+obj.style+'" '):'')+'class="field'+(obj.classes?(' '+obj.classes):'')+'" id="field-'+id+'">'+(obj.text.replaceAll('"','&quot;')||'')+'</textarea>';
		if (obj.onclick || obj.tooltip || obj.oninput || obj.select)
		{
			G.pushCallback(function(id,obj){return function(){
				if (obj.tooltip) G.addTooltip(l('field-'+id),function(){return obj.tooltip;},{offY:-8});
				if (obj.onclick) l('field-'+id).onclick=obj.onclick;
				if (obj.oninput) l('field-'+id).oninput=function(e){obj.oninput(e.target.value);};
				if (obj.select) l('field-'+id).select();
			}}(id,obj));
		}
		G.fieldN++;
		return str;
	}
	G.textarea=function(obj)
	{
		//returns a string for a new text input area; much the same as G.field
		obj.textarea=true;
		return G.field(obj);
	}
	
	G.arbitraryCallback=function(func)
	{
		G.pushCallback(func);
	}
	
	G.textN=0;
	G.textE=0;
	G.textWithTooltip=function(text,tooltip,classes)
	{
		//returns a string for a span of text with a tooltip; creates a callback that must be applied after the html has been created, with G.addCallbacks()
		var id=G.textN;
		var str='<span class="tooltiped'+(classes?(' '+classes):'')+'" id="textspan-'+id+'">'+text+'</span>';
		G.pushCallback(function(id,tooltip){return function(){
			G.addTooltip(l('textspan-'+id),function(){return tooltip;},{offY:-8});
		}}(id,tooltip));
		G.textN++;
		return str;
	}
	
	G.clickableText=function(text,func,classes)
	{
		//returns a string for a span of text that triggers a function on click; creates a callback that must be applied after the html has been created, with G.addCallbacks()
		var id=G.textN;
		var str='<span class="'+(classes?(' '+classes):'')+'" id="clickabletextspan-'+id+'">'+text+'</span>';
		G.pushCallback(function(id,func){return function(div){
			l('clickabletextspan-'+id).onclick=func;
		}}(id,func));
		G.textN++;
		return str;
	}
	
	G.deleteSelfUpdatingTexts=function()
	{
		var divs=document.getElementsByClassName('updatabletextspan');
		for (var i=0;i<divs.length;i++)
		{
			divs[i].id='';
			divs[i].className='';
		}
		var divs=document.getElementsByClassName('tooltiped');
		for (var i=0;i<divs.length;i++)
		{
			divs[i].id='';
			divs[i].className='';
		}
	}
	G.updateTextTimer=function(id,func)
	{
		var el=l('updatabletextspan-'+id);
		if (el)
		{
			el.innerHTML=func();
			setTimeout(function(id,func){return function(){G.updateTextTimer(id,func);}}(id,func),1000);
		}
	}
	G.selfUpdatingText=function(func)
	{
		//returns a string for a span of text that updates itself every second; creates a callback that must be applied after the html has been created, with G.addCallbacks()
		var id=G.textN;
		var str='<span class="updatabletextspan" id="updatabletextspan-'+id+'">'+func()+'</span>';
		G.pushCallback(function(id,func){return function(){
			G.updateTextTimer(id,func);
		}}(id,func));
		G.textN++;
		return str;
	}
	
	/*=====================================================================================
	NAMES
	=======================================================================================*/
	//stuff that can be set by the player like ruler name, country name and so on
	G.names=[];
	G.getName=function(name,fallback){if (!G.names[name]) return fallback; else return G.names[name];}
	G.setName=function(name,val,fallback){if (!val) {val=fallback;}G.names[name]=val.replaceAll('<','&lt;').replaceAll('>','&gt;');}
	G.getSafeName=function(name,fallback){if (!G.names[name]) return fallback; else return '"'+G.names[name].replaceAll('"','&quot;')+'"';}//okay for saving
	G.setSafeName=function(name,val,fallback){if (!val) {val=fallback;}G.names[name]=val.replaceAll('<','&lt;').replaceAll('>','&gt;');}//okay for loading
	
	/*=====================================================================================
	TABS
	=======================================================================================*/
	G.tabs=
	[
		//div : which div to empty+hide or display when tab is toggled
		//update : which system's update to call when toggling on
		{name:'Production',id:'unit',update:'unit',desc:'Recruit units and create buildings.'},
		{name:'Territory',id:'land',update:'land',showMap:true,desc:'View the world map, inspect explored territory and see your natural resources.'},
		//{name:'Diplomacy',id:'diplo',showMap:true,desc:'View and interact with other civilizations; conduct trade and send armies.'},//later
		{name:'Policies',id:'policy',update:'policy',desc:'Use your influence to enact policies that change the way your civilization functions.'},
		{name:'Traits',id:'trait',update:'trait',desc:'View traits and edit your civilization\'s properties.'},
		{name:'Research',id:'tech',update:'tech',desc:'Purchase new technologies that improve your civilization and unlock new units.'},
		{name:'Settings',id:'settings',popup:true,addClass:'right',desc:'Change the game\'s settings.'},
		{name:'Update log',id:'updates',popup:true,addClass:'right',desc:'View the game\'s version history and other information.'},
		{name:'Legacy',id:'legacy',popup:true,addClass:'right',desc:'View your legacy stats and achievements.'}
	];
	for (var i=0;i<G.tabs.length;i++){G.tabs[i].I=i;}
	G.tabPopup=[];
	
	G.buildTabs=function()
	{
		var str='';
		str+='<div id="sectionTabs" class="tabList"></div>';
		str+='<div id="mapBreakdown"></div>';
		str+='<div id="mapSection"></div>';
		for (var i in G.tabs)
		{G.tabs[i].div=G.tabs[i].id+'Div';str+='<div id="'+G.tabs[i].div+'" class="subsection'+(G.tabs[i].noScroll?' noScroll':'')+'"></div>';}
		l('sections').innerHTML=str;
		G.buildMapDisplay();
		var str='';
		for (var i in G.tabs)
		{str+='<div id="tab-'+G.tabs[i].id+'" class="tab bgMid'+(G.tabs[i].addClass?' '+G.tabs[i].addClass:'')+'">'+G.tabs[i].name+'</div>';}
		l('sectionTabs').innerHTML=str;
		for (var i in G.tabs)
		{
			G.tabs[i].l=l('tab-'+G.tabs[i].id);
			G.tabs[i].l.onclick=function(tab){return function(){G.setTab(tab);};}(G.tabs[i]);
			if (G.tabs[i].desc) G.addTooltip(G.tabs[i].l,function(tab){return function(){return tab.desc;};}(G.tabs[i]),{offY:-8});
		}
		G.setTab(G.tabs[0]);
	}
	G.setTab=function(tab)
	{
		if (tab.popup)
		{
			if (G.getSetting('animations')) triggerAnim(tab.l,'plop');
			G.dialogue.popup(G.tabPopup[tab.id],'bigDialogue',tab.l);
		}
		else
		{
			G.tab=tab;
			G.settingsByName['tab'].value=G.tab.I;
			for (var i in G.tabs)
			{
				var me=G.tabs[i];
				if (me.id!=tab.id)//close other tabs
				{
					me.l.classList.remove('on');
					me.l.classList.remove('bgLight');
					me.l.classList.add('bgMid');
					if (me.div) {l(me.div).style.display='none';l(me.div).innerHTML='';}
				}
				else//update focused tab
				{
					me.l.classList.add('on');
					me.l.classList.remove('bgMid');
					me.l.classList.add('bgLight');
					if (me.div) l(me.div).style.display='block';
					if (me.update) G.update[me.update]();
					if (G.getSetting('animations')) triggerAnim(me.l,'plop');
				}
			}
			if (tab.showMap) G.showMap();
			else G.hideMap();
			G.particlesReset();
		}
	}
	
	/*=====================================================================================
	UPDATE LOG
	=======================================================================================*/
	G.updateLogPreface='<div class="par"><b>NeverEnding Legacy</b> is a game by <a href="https://orteil42.tumblr.com/" target="_blank">Orteil</a> and <a href="https://optidash.tumblr.com/" target="_blank">Opti</a>. It is currently in early alpha, may feature strange and exotic bugs, and may be updated at any time. (Please don\'t get too attached to your saves.)</div>'+
	'<div class="par">Updates will most likely only affect your game after you ascend or reset to a new legacy.</div>'+
	'<br><div class="fancyText">The long term</div>'+
	'<div class="par">The idea is to keep releasing incremental updates that add new technological eras or expand on existing features. This may take a while.</div>';
	
	G.updateLog=UPDATELOG;
	
	G.tabPopup['updates']=function()
	{
		var str='';
		str+=G.updateLogPreface;
		str+='<div class="divider"></div><div class="fancyText">Update log :</div>';
		var n=G.updateLog.length;
		for (var i=n-1;i>=0;i--)
		{
			var me=G.updateLog[i];
			str+='<br><div class="fancyText"><span style="color:#999;">'+me.date+' :</span> '+me.title+'</div>';
			var len=me.text.length;
			for (var ii=0;ii<len;ii++)
			{
				str+='<div class="bulleted">'+me.text[ii]+'</div>';
			}
		}
		str='<div class="fancyText title">About</div><div class="bitBiggerText scrollBox underTitle">'+str+'</div>';
		str+='<div class="buttonBox">'+
		G.dialogue.getCloseButton()+
		'</div>';
		return str;
	}
	
	/*=====================================================================================
	SETTINGS
	=======================================================================================*/
	/*
		example use :
			str=G.writeSettingButton({id:'myButton',name:'name-of-the-setting-to-affect',text:'Text that will be on the button',tooltip:'Tooltip to display on button hover',value:(value this button sets the setting to, not required for toggle settings),siblings:[list of ids of other linked buttons as strings (like 'myButton2','myButton3'...) which will be toggled off when this button is toggled on]});
		don't forget to use G.addCallbacks() once the str has been added to the html
	*/
	G.settings=[
		{name:'mapEditMode',type:'int',def:0,onChange:function(){
			G.editMode=(G.getSetting('mapEditMode'));
			G.mapEditWithLand=0;
			var div=l('tileEditButton');
			if (div && G.editMode==2)
			{
				div.style.display='block';
				if (G.getSetting('animations')) triggerAnim(div,'plop');
				if (G.land[G.mapEditWithLand])
				{
					div.style.background=G.getLandIconBG(G.land[G.mapEditWithLand]);
					div.style.backgroundPosition=G.getLandIconBGpos(G.land[G.mapEditWithLand]);
				}
			}
			else if (div) div.style.display='none';
		}},//what are we doing to the map?
		{name:'paused',type:'toggle',def:0,onChange:function(){G.updateSpeedButtons();}},//is the game currently paused?
		{name:'fast',type:'toggle',def:1,onChange:function(){G.updateSpeedButtons();}},//is the game currently on fast speed?
		{name:'forcePaused',type:'toggle',def:0,onChange:function(){G.updateSpeedButtons();}},//force pause when on
		{name:'tab',type:'int',def:0,onChange:function(){}},//current tab
		{name:'showLeads',type:'int',def:0,onChange:function(){}},//show what any given tech or trait will lead to (kinda cheaty/cumbersome)
		{name:'pauseOnMenus',type:'toggle',def:1,onChange:function(){}},//pause when in menus
		{name:'atmosphere',type:'toggle',def:1,onChange:function(){}},//show atmospheric messages
		{name:'particles',type:'toggle',def:1,onChange:function(){}},//show particles
		{name:'animations',type:'toggle',def:1,onChange:function(){if (G.getSetting('animations')) G.wrapl.classList.add('animationsOn'); else G.wrapl.classList.remove('animationsOn');}},//show animations ("plops" and blue squares)
		{name:'filters',type:'toggle',def:1,onChange:function(){if (G.getSetting('filters')) G.wrapl.classList.add('filtersOn'); else G.wrapl.classList.remove('filtersOn');}},//use CSS filters
		{name:'fpsgraph',type:'toggle',def:1,onChange:function(){if (G.getSetting('fpsgraph')) {G.fpsGraph.style.display='block';l('fpsCounter').style.display='block';} else {G.fpsGraph.style.display='none';l('fpsCounter').style.display='none';}}},//show fps graph
		{name:'debug',type:'toggle',def:0,onChange:function(){if (G.getSetting('debug')) G.wrapl.classList.add('debugOn'); else G.wrapl.classList.remove('debugOn');}},//cheaty debug mode
		{name:'showAllRes',type:'toggle',def:0,onChange:function(){}},//see all resources
		{name:'autosave',type:'toggle',def:1,onChange:function(){}},//game will save every minute
		{name:'buyAny',type:'toggle',def:0,onChange:function(){}},//when bulk-buying, buy any amount up to the demanded amount instead of cancelling if we can't buy the demanded amount
		{name:'tieredDisplay',type:'toggle',def:0,onChange:function(){if (l('techDiv')) G.update['tech']();}},//techs will be displayed as tiers instead of in the order they were researched
		{name:'buyAmount',type:'int',def:1,onChange:function(){G.updateBuyAmount();}},//how many units we create/remove at once
	];
	G.settingsByName=[];
	for (var i in G.settings){G.settingsByName[G.settings[i].name]=G.settings[i];}
	G.getSetting=function(name){return G.settingsByName[name].value;}
	G.setSetting=function(name,value)
	{
		var me=G.settingsByName[name];
		me.value=value;
		if (me.onChange) me.onChange();
	}
	G.resetSettings=function()
	{
		for (var i in G.settings)
		{
			G.settings[i].value=G.settings[i].def;
			if (G.settings[i].onChange) G.settings[i].onChange();
		}
	}
	G.writeSettingButton=function(obj)
	{
		G.pushCallback(function(obj){return function(){
			var div=l('settingButton-'+obj.id);
			if (div)
			{
				var me=G.settingsByName[obj.name];
				
				var valueMatches=(!(typeof obj.value==='undefined') && me.value==obj.value);
				var on=false;
				if (me.type=='toggle' && me.value==true) on=true;
				else if (valueMatches) on=true;
				
				div.innerHTML=obj.text||me.name;
				if (on) div.classList.add('on');
				
				div.onclick=function(div,name,value,siblings){return function(){G.clickSettingButton(div,name,value,siblings);}}(div,obj.name,obj.value,obj.siblings);
				if (obj.tooltip) G.addTooltip(div,function(str){return function(){return str;};}(obj.tooltip),{offY:-8});
			}
		}}(obj));
		return '<div class="button" id="settingButton-'+obj.id+'"></div>';
	}
	G.clickSettingButton=function(div,name,value,siblings)
	{
		var me=G.settingsByName[name];
		var newValue=value;
		if (me.type=='toggle') newValue=!me.value;
		if (!(typeof newValue==='undefined'))
		{
			G.setSetting(name,newValue);
		}
		if (div)
		{
			var valueMatches=(!(typeof value==='undefined') && me.value==value);
			var on=false;
			if (me.type=='toggle' && me.value==true) on=true;
			else if (valueMatches) on=true;
			if (on) div.classList.add('on'); else div.classList.remove('on');
			if (siblings)
			{
				for (var i in siblings)
				{
					if (('settingButton-'+siblings[i])!=div.id)
					{l('settingButton-'+siblings[i]).classList.remove('on');}
				}
			}
		}
	}
	G.tabPopup['settings']=function()
	{
		var str='';
		str+='<div class="fancyText title">Settings</div>';
		str+='<div class="scrollBox underTitle">'+
		(G.sequence=='main'?
		(
			'<div class="barred fancyText">Save file</div>'+
			'<div style="float:right;text-align:right;">'+
				G.button({text:'View loaded mods',tooltip:'Check which mods are currently active on this game.',onclick:function(){G.dialogue.popup(function(div){
					var str='';
					str='<div style="width:480px;height:240px;"><div class="fancyText title">Loaded mods</div><div class="bitBiggerText scrollBox underTitle" style="text-align:center;"><div class="par">You can change mods when you start a new game.</div>';
					for (var i in G.mods)
					{
						var mod=G.mods[i];
						str+='<div class="barred fancyText">'+G.textWithTooltip(mod.name,'<div class="info"><div class="barred fancyText infoTitle">'+mod.name+'</div>'+(mod.author?('<div class="barred fancyText">by '+mod.author+'</div>'):'')+'<div class="barred fancyText">URL : '+mod.url+'</div><div class="infoDesc">'+(mod.desc?(mod.desc):'')+'</div></div>')+'</div>';
					}
					str+='</div>'+
					'<div class="buttonBox">'+
					G.dialogue.getCloseButton()+
					'</div></div>';
					return str;
				});}})+
				'<br>'+
				G.button({text:'Wipe save',tooltip:'Clear your save completely, removing your current game<br>and any achievements and game data.<br>Cannot be undone!',style:'box-shadow:0px 0px 2px 1px #f00;',onclick:function(){G.dialogue.popup(function(div){
					return '<div style="padding:16px;">Are you really sure you want to delete your save file?<br><br>'+G.button({text:'Yes!',onclick:function(){G.Clear();G.middleText('- Save wiped -');G.dialogue.close();}})+G.button({text:'No!',onclick:function(){G.dialogue.close();}})+'</div>';
				});}})+
			'</div>'+
			G.button({text:'New game',tooltip:'Abandon your current game and start a new one.',onclick:function(){G.dialogue.popup(function(div){
				return '<div style="padding:16px;">Are you sure you want to start a new game?<br>You will have to start over<br>(but you will keep your stats and achievements).<br><br>'+G.button({text:'Yes',onclick:function(){G.dialogue.close();G.NewGameWithSameMods();}})+G.button({text:'No',onclick:function(){G.dialogue.close();}})+'</div>';
			});}})+
			G.button({text:'Save game',tooltip:'Save your current game.<br>You can also save at any time with ctrl+S.',onclick:function(){G.Save();}})+
			'<br>'+
			G.button({text:'Load from file<input type="file" style="cursor:pointer;opacity:0;position:absolute;left:0px;top:0px;width:100%;height:100%;" onchange="G.FileLoad(event);"/>',tooltip:'Load a game from an external save file.',onclick:function(){}})+
			G.button({text:'Save to file',tooltip:'Save the game to an external save file.<br>Use this to keep backups of your save on your computer.',onclick:function(){G.FileSave();}})+
			'<br><br><br>'
		)
		:'')+
		'<div class="barred fancyText">Gameplay</div>'+
		G.writeSettingButton({id:'pauseOnMenus',name:'pauseOnMenus',text:'Pause in menus',tooltip:'Time will stop while in a menu or prompt.'})+
		G.writeSettingButton({id:'buyAny',name:'buyAny',text:'Buy any amount',tooltip:'When this is on, bulk-buying a unit (by shift-clicking it)<br>will buy as many as you can, up to 50;<br>if this is off, it will only bulk-buy<br>if you can buy all 50 at once.'})+
		G.writeSettingButton({id:'atmosphere',name:'atmosphere',text:'Show atmospheric messages',tooltip:'Turn ambience flavor text in messages on/off.'})+
		G.writeSettingButton({id:'autosave',name:'autosave',text:'Autosave',tooltip:'Turn autosaving every 60 seconds on/off.'})+
		
		'<div class="barred fancyText">Graphics</div>'+
		'<div class="par">Turning these off may improve performance.</div>'+
		G.writeSettingButton({id:'particles',name:'particles',text:'Particles',tooltip:'Turn resource particles on/off.'})+
		G.writeSettingButton({id:'animations',name:'animations',text:'Animations',tooltip:'Turn interface animations on/off.'})+
		G.writeSettingButton({id:'filters',name:'filters',text:'CSS filters',tooltip:'Turn fancy CSS filters on/off.<br>Includes effects such as icon shadows, blurring and brightness adjustments.'})+
		
		'<div class="barred fancyText">Misc.</div>'+
		G.writeSettingButton({id:'fpsgraph',name:'fpsgraph',text:'Show fps',tooltip:'Display the frames per second graph.'})+
		'</div>';
		str+='<div class="buttonBox">'+
		G.dialogue.getCloseButton()+
		'</div>';
		return str;
	}
	
	/*=====================================================================================
	USEFUL STUFF
	=======================================================================================*/
	G.checkReq=function(req)
	{
		//run through a list of requirements and return true if all match
		var success=true;
		for (var i in req)
		{
			var found=false;
			if (G.getDict(i).type=='policy')
			{
				var policy=G.getDict(i);
				if (policy.visible && policy.mode.id==req[i]) {}
				else return false;
				//else {success=false;}
			}
			else
			{
				if (G.has(i)) found=true;
				if (found && req[i]==true) {}
				else if (!found && req[i]==false) {}
				else return false;
				//else {success=false;}
			}
		}
		return success;
	}
	G.has=function(what)
	{
		//return true if we have at least 1 of the tech, trait or unit
		var me=G.getDict(what);
		var type=me.type;
		if (type=='tech' && G.techsOwnedNames.includes(what)) return true;
		else if (type=='trait' && G.traitsOwnedNames.includes(what)) return true;
		else if (type=='unit' && G.unitsOwnedNames.includes(what)) return true;
		//NOTE : actually returns true for units if they're visible on the production screen at all
		return false;
	}
	
	G.debugInfo=function(me)
	{
		return '<div class="debugInfo">id:'+me.id+', raw:"'+me.name+'"<br>mod:'+(me.mod?me.mod.name:'none')+'</div>'
	}
	
	//the icon functions are a bit of a redundant mess honestly
	G.getIconClasses=function(me,allowWide)
	{
		//returns some CSS classes
		var str='';
		if (me.wideIcon && allowWide) str+=' wide3';
		else str+=' wide1';
		return str;
	}
	G.getIconStr=function(me,id,classes,allowWide)
	{
		//returns a DOM string
		var icon=G.getIconUsedBy(me,allowWide);
		return '<div'+(id?' id="'+id+'"':'')+' class="icon'+((icon.length>2)?' double':'')+''+(classes?(' '+classes):'')+'" style="'+icon+'"></div>';
	}
	G.getIconUsedBy=function(me,allowWide)
	{
		//returns a style string for something's icon
		var icon=me.icon||[0,0];
		if (allowWide && me.wideIcon) icon=me.wideIcon;
		if (me.getIcon) icon=me.getIcon(me);
		return G.getIcon(icon);
	}
	G.getIcon=function(icon,split)
	{
		//returns a style string
		/*examples for the icon parameter :
			[1,2] - returns the icon at 1,2 in the default spritesheet
			[1,2,3,4] - returns the icon at 1,2, overlaid on top of the icon at 3,4 in the default spritesheet
			[1,2,"mySheet"] - returns the icon at 1,2 in the custom spritesheet with id "mySheet"
			[1,2,"mySheet",3,4] - returns the icon at 1,2 in the custom spritesheet with id "mySheet" overlaid on top of the icon at 3,4 in the default spritesheet
		*/
		var bg=[];
		var bgP=[];
		
		var bit=[];
		for (var i=0;i<icon.length;i++)
		{
			if (bit.length==2)
			{
				if (G.isIE && typeof icon[i]=='string') bit=[0,0];//TODO : fix for IE
				bgP.push((-bit[0]*24*G.iconScale)+'px '+(-bit[1]*24*G.iconScale)+'px');
				bit=[];
				if (typeof icon[i]=='string')
				{
					bg.push('url('+G.sheets[icon[i]]+')');
				}
				else
				{
					bg.push('url('+G.iconURL+')');
					bit.push(icon[i]);
				}
			}
			else
			{
				bit.push(icon[i]);
			}
		}
		if (bit.length==2)
		{
			bgP.push((-bit[0]*24*G.iconScale)+'px '+(-bit[1]*24*G.iconScale)+'px');
			bg.push('url('+G.iconURL+')');
		}
		
		if (split) return [bg.join(','),bgP.join(',')];
		var str='';
		if (!G.isIE) str+='background:'+bg.join(',')+';';//TODO : fix for IE
		str+='background-position:'+bgP.join(',')+';';
		return str;
		
		/*
		if (icon.length>2) return 'background-position:'+(-icon[0]*24*G.iconScale)+'px '+(-icon[1]*24*G.iconScale)+'px,'+(-icon[2]*24*G.iconScale)+'px '+(-icon[3]*24*G.iconScale)+'px;';
		return 'background-position:'+(-icon[0]*24*G.iconScale)+'px '+(-icon[1]*24*G.iconScale)+'px;';*/
	}
	G.getFreeformIcon=function(x,y,w,h)
	{
		//returns a style string
		return 'background-position:'+(-x*G.iconScale)+'px '+(-y*G.iconScale)+'px;width:'+(w)+'px;height:'+(h)+'px;';
	}
	G.setIcon=function(div,icon)
	{
		//updates an existing DOM element's icon
		div.style.cssText=G.getIcon(icon);
		if (icon.length>2) div.classList.add('double'); else div.classList.remove('double');
	}
	G.getArbitraryIcon=function(icon,clipped,id)
	{
		return '<div class="thing standalone wide1'+(clipped?' clipped':'')+'">'+'<div '+(id?('id="'+id+'" '):'')+'class="icon'+((icon.length>2)?' double':'')+'" style="'+G.getIcon(icon)+'"></div>'+'</div>';
	}
	G.getArbitrarySmallIcon=function(icon,clipped,id)
	{
		return '<div class="thing small standalone wide1'+(clipped?' clipped':'')+'">'+'<div '+(id?('id="'+id+'" '):'')+'class="icon'+((icon.length>2)?' double':'')+'" style="'+G.getIcon(icon)+'"></div>'+'</div>';
	}
	
	//dictionary : everything is stored in here by name
	//handy for getting something without knowing its type
	//sends a warning when trying to declare something with a duplicate name
	G.dict=[];
	G.setDict=function(name,what)
	{
		if (G.dict[name]) {console.log('WARNING : there is already something with the id "'+name+'".');return false;}
		else {G.dict[name]=what;return true;}
	}
	G.getDict=function(name)
	{
		if (!G.dict[name]) ERROR('Nothing exists with the name '+name+'.');
		else if (G.dict[name].type=='res') return G.resolveRes(G.dict[name]); else return G.dict[name];
	}
	G.getRawDict=function(name)
	{
		if (!G.dict[name]) ERROR('Nothing exists with the name '+name+'.');
		else return G.dict[name];
	}
	G.resolveRes=function(res){if (res.replacement) return G.resolveRes(G.dict[res.replacement]); else return res;}
	
	G.setTile=function(x,y,what)
	{
		G.currentMap.tiles[x][y].land=G.land[what];
	}
	
	G.getSmallThing=function(what,text)
	{
		return '<span class="smallThing"><div class="thing standalone wide1'+((what.type && (what.type=='tech'||what.type=='trait'||what.type=='unit'))?' clipped':'')+'">'+G.getIconStr(what)+'</div>'+(text=='*PLURAL*'?(what.displayName+'s'):(text||what.displayName||'<span style="opacity:0;">!</span>'))+'</span>'
	}
	G.getBrokenSmallThing=function(what,text)
	{
		return '<span class="brokenSmallThing">'+(text=='*PLURAL*'?(what+'s'):(text||what))+'</span>'
	}
	G.parseFunc=function(str)
	{
		str=str.substring(1,str.length-1);
		var parts=str.split(',');
		var keyword=parts[0];
		parts.shift();
		var val=parts.join(',');
		var exact=false;
		if (keyword.charAt(0)=='#')
		{
			exact=true;
			keyword=keyword.substring(1,keyword.length);
		}
		//str='['+keyword+' (not defined yet)]';
		if (exact && G.getRawDict(keyword)) str=G.getSmallThing(G.getRawDict(keyword),val);
		else if (!exact && G.getDict(keyword)) str=G.getSmallThing(G.getDict(keyword),val);
		else str=G.getBrokenSmallThing(keyword,val);
		return str;
	}
	G.parse=function(what)
	{
		/*
			Syntax :
				-[fruit] will display the fruit resource in bold with a small icon (also works for any other element registered in the dictionary)
				-[fruit]s will do the same, but add an "s" at the end
				-[fruit,Apples] will display the fruit resource but the name will be replaced with "Apples"
				-[#fruit] will display the fruit resource, even if it has a replacement which should be displayed instead
				-// will create a new paragraph
				-@ will create a bullet list point
				-<> will create a full-width divider
		*/
		var str='<div class="par">'+((what.replaceAll(']s',',*PLURAL*]')).replace(/\[(.*?)\]/gi,G.parseFunc)).replaceAll('//','</div><div class="par">').replaceAll('@','</div><div class="par bulleted">').replaceAll('<>','</div><div class="divider"></div><div class="par">')+'</div>';
		return str;
	}
	
	G.getCostString=function(costs,verbose,neutral,mult)
	{
		//returns a string that displays resource costs with icons and amount; the amounts will be red if our current resources don't match them, unless neutral is set to true; only the amount will be displayed unless verbose is true, in which case the amount and the resource name will be displayed; costs will be multiplied by mult if specified
		var costsStr=[];
		mult=mult||1;
		for (var i in costs)
		{
			var thing=G.getDict(i);
			var text=B(costs[i]*mult)+(verbose?(' '+thing.displayName):'');
			if (thing.amount<costs[i]*mult && !neutral) text='<span style="color:#f00;">'+text+'</span>';
			costsStr.push(G.getSmallThing(thing,text));
		}
		return costsStr.join(', ');
	}
	G.getUseString=function(costs,verbose,neutral,mult)
	{
		//same as above, but takes into account the unused amount of a usable resource instead of its total amount
		var costsStr=[];
		mult=mult||1;
		for (var i in costs)
		{
			var thing=G.getDict(i);
			var text=B(costs[i]*mult)+(verbose?(' '+thing.displayName):'');
			if ((thing.amount-thing.used)<costs[i]*mult && !neutral) text='<span style="color:#f00;">'+text+'</span>';
			costsStr.push(G.getSmallThing(thing,text));
		}
		return costsStr.join(', ');
	}
	G.getLimitString=function(costs,verbose,neutral,amount)
	{
		//same as above, but for limits
		var costsStr=[];
		amount=amount||1;
		for (var i in costs)
		{
			var thing=G.getDict(i);
			var text='1 per '+B(costs[i])+(verbose?(' '+thing.displayName):'');
			if (((thing.amount+costs[i])/amount)<=costs[i] && !neutral) text='<span style="color:#f00;">'+text+'</span>';
			costsStr.push(G.getSmallThing(thing,text));
		}
		return costsStr.join(', ');
	}
	
	G.updateEverything=function()
	{
		for (var i in G.update)
		{
			G.update[i]();
		}
		G.updateMapDisplay();
	}
	
	//callbacks system : basically we have functions that return HTML but also add a callback to the callbacks array; after the HTML has been added to the DOM we call G.addCallbacks() to apply all the pending callbacks - this lets us centralize HTML and callbacks in one function
	G.Callbacks=[];
	G.addCallbacks=function()
	{
		var len=G.Callbacks.length;
		for (var i=0;i<len;i++)
		{G.Callbacks[i]();}
		G.Callbacks=[];
	}
	G.pushCallback=function(func)
	{
		G.Callbacks.push(func);
	}
	
	//datasets can declare functions that will be executed in specific contexts; for instance, G.funcs['new year'] will be executed at the start of every new year
	G.doFunc=function(what,fallback)
	{
		if (G.funcs[what]) return G.funcs[what](); else return fallback;
	}
	G.doFuncWithArgs=function(what,args,fallback)
	{
		if (G.funcs[what]) return G.funcs[what].apply(this,args); else return fallback;
	}
	
	G.cantWhenPaused=function()
	{
		G.middleText('<small>Can\'t do that when paused!</small>');
	}
	
	G.BT=function(value)//value is in game days
	{
		//give a Beautified Time string for the given value
		value=Math.max(Math.ceil(value,0));
		var years=Math.floor(value/300);
		value-=years*300;
		var days=Math.floor(value);
		var bits=[];
		if (years) bits.push(B(years)+' year'+(years==1?'':'s'));
		if (days || bits.length==0) bits.push(B(days)+' day'+(days==1?'':'s'));
		return bits.join(', ');
	}
	
	/*=====================================================================================
	PARTICLES
	=======================================================================================*/
	G.particlesInit=function()
	{
		G.particles=[];
		G.particlesI=0;
		G.particlesN=100;
		var str='';
		for (var i=0;i<G.particlesN;i++)
		{
			str+='<div id="particle'+i+'" class="icon particle" style="display:none;"></div>';
		}
		l('particlesAnchor').innerHTML=str;
		for (var i=0;i<G.particlesN;i++)
		{
			G.particles[i]={on:false,x:0,y:0,l:0,lm:0,icon:[0,0],type:0,el:l('particle'+i)};
		}
	}
	G.particlesReset=function()
	{
		for (var i=0;i<G.particlesN;i++)
		{
			var me=G.particles[i];
			me.on=false;
			me.el.style.display='none';
		}
	}
	G.showParticle=function(obj)
	{
		if (!G.getSetting('particles')) return 0;
		if (obj.y && (obj.y>G.h-102 || obj.y<26)) return 0;//cull if on black interface
		var me=G.particles[G.particlesI];
		me.x=0;
		me.y=0;
		me.lm=0;
		me.icon=[0,0];
		me.type=0;
		for (var i in obj) {me[i]=obj[i];}
		me.on=true;
		me.l=0;
		if (me.type==0)
		{
			me.x+=Math.random()*32-16;
			me.xd=Math.random()*4-2;
			me.yd=-(Math.random()*2+1);
			me.lm=me.lm||30;
			//me.icon=choose(G.res).icon;
			me.el.style.transform='translate('+(me.x-12)+'px,'+(me.y-12)+'px)';
			var iconStr=G.getIcon(me.icon,true);
			me.el.style.background=iconStr[0];
			me.el.style.backgroundPosition=iconStr[1];
			//me.el.style.backgroundPosition=(-me.icon[0]*24*G.iconScale)+'px '+(-me.icon[1]*24*G.iconScale)+'px';
			me.el.style.display='block';
		}
		G.particlesI++;
		if (G.particlesI>=G.particlesN) G.particlesI=0;
	}
	G.logic['particles']=function()
	{
		for (var i=0;i<G.particlesN;i++)
		{
			var me=G.particles[i];
			if (me.on)
			{
				if (me.type==0)
				{
					me.x+=me.xd;
					me.y+=me.yd;
					me.yd+=0.2;
					me.xd*=0.95;
				}
				me.l++;
				if (me.l>me.lm) {me.on=false;me.el.style.display='none';}
			}
		}
	}
	G.draw['particles']=function()
	{
		for (var i=0;i<G.particlesN;i++)
		{
			var me=G.particles[i];
			if (me.on)
			{
				me.el.style.transform='translate('+(me.x-12)+'px,'+(me.y-12)+'px)';
				me.el.style.opacity=1-(me.l/me.lm);
			}
		}
	}
	
	/*=====================================================================================
	BIG MIDDLE TEXT
	=======================================================================================*/
	G.middleText=function(text,slow)
	{
		l('middleText').innerHTML='<div class="showUp" style="text-align:center;position:absolute;bottom:16px;width:100%;">'+text+'</div>';
		//l('middleText').innerHTML='<div class="fullCenteredOuter" style="height:100%;"><div class="fullCenteredInner" style="text-align:center;">'+text+'</div></div>';
		triggerAnim(l('middleText'),'slowFadeOut');
		if (slow) l('middleText').style.animationDuration='5s';
		else l('middleText').style.animationDuration='1.5s';
	}
	
	/*=====================================================================================
	MESSAGES
	=======================================================================================*/
	G.messages=[];
	G.maxMessages=50;
	G.Message=function(obj)
	{
		//syntax :
		//G.Message({type:'important',text:'This is a message.'});
		//.type is optional
		var me={};
		me.type='normal';
		for (var i in obj) {me[i]=obj[i];}
		var scrolled=!(Math.abs(G.messagesWrapl.scrollTop-(G.messagesWrapl.scrollHeight-G.messagesWrapl.offsetHeight))<3);//is the message list not scrolled at the bottom? (if yes, don't update the scroll - the player probably manually scrolled it)
		
		me.date=G.year*300+G.day;
		var text=me.text||me.textFunc(me.args);
		
		var mergeWith=0;
		if (me.mergeId)
		{
			//this is a system where similar messages merge together if they're within 100 days of each other, in order to reduce spam
			//simply declare a .mergeId to activate merging on this message with others like it
			//syntax :
			//var cakes=10;G.Message({type:'important',mergeId:'newCakes',textFunc:function(args){return 'We\'ve baked '+args.n+' new cakes.';},args:{n:cakes}});
			//numeric arguments will be added to the old ones unless .replaceOnly is true
			
			for (var i in G.messages)
			{
				var other=G.messages[i];
				if (other.id==me.mergeId && me.date-other.date<100) mergeWith=other;
			}
			me.id=me.mergeId;
		}
		if (mergeWith)
		{
			me.date=other.date;
			if (me.replaceOnly)
			{
				for (var i in me.args)
				{mergeWith.args[i]=me.args[i];}
			}
			else
			{
				for (var i in me.args)
				{
					if (!isNaN(parseFloat(me.args[i]))) mergeWith.args[i]+=me.args[i];
					else mergeWith.args[i]=me.args[i];
				}
			}
			text=me.textFunc(mergeWith.args);
		}
		
		var str='<div class="messageTimestamp" title="'+'year '+(G.year+1)+', day '+(G.day+1)+'">'+'Y:'+(G.year+1)+'</div>'+
		'<div class="messageContent'+(me.icon?' hasIcon':'')+'">'+(me.icon?(G.getArbitraryIcon(me.icon)):'')+'<span class="messageText">'+text+'</span></div>';
		
		if (mergeWith) mergeWith.l.innerHTML=str;
		else
		{
			var div=document.createElement('div');
			div.innerHTML=str;
			div.className='message popInVertical '+(me.type).replaceAll(' ','Message ')+'Message';
			G.messagesl.appendChild(div);
			me.l=div;
			G.messages.push(me);
			if (G.messages.length>G.maxMessages)
			{
				var el=G.messagesl.firstChild;
				for (var i in G.messages)
				{
					if (G.messages[i].l==el)
					{
						G.messages.splice(i,1);
						break;
					}
				}
				G.messagesl.removeChild(el);
				//G.messages.pop();
				//G.messagesl.removeChild(G.messagesl.firstChild);
			}
			if (!scrolled) G.messagesWrapl.scrollTop=G.messagesWrapl.scrollHeight-G.messagesWrapl.offsetHeight;
		}
		G.addCallbacks();
	}
	G.initMessages=function()
	{
		G.messages=[];
		G.messagesl=l('messagesList');
		G.messagesWrapl=l('messages');
		G.messagesl.innerHTML='';
	}
	G.updateMessages=function()
	{
	}
	
	/*=====================================================================================
	LANGUAGE
		A system for translation into pseudo-languages.
		This system takes in a language object, composed of word starts, middles, jointers and ends, and an input text, and outputs that text "translated" into the language.
		The translation should always return the same output for the same word.
	=======================================================================================*/
	//http://symbolcodes.tlt.psu.edu/web/codehtml.html
	G.languages={
		'primitive':{
			name:'Primitive',
			starts:['g','gr','gn','m','r','b','br','k','kr','z','h','d','th','thr','ob','ok','ork','ak','ark'],
			mids:['a','a','a','a','a','a','o','o','o','o','o','o','i','i','e','e','u','u','y',/**/'oo','oh','aa','ah','&uuml;','&uuml;&uuml;','&ouml;','&ouml;&ouml;'],
			joints:['nk','z','r','rb','rh','d','m','b','h','n','nd','mb','k','kt','lk','st','k\'t','g\'h'],
			ends:['k','k','k','k','g','g','g','r','r','r','ko','nko','nka','mbo','mba','rk','nk','do','dia','kko','tta','tto','tia','t','th','b','l','ll','n','m','x','rx','rg'],
		},
		'english':{
			name:'Brittanoid',
			starts:[/*common*/'d','m','n','b','g','l','p','f','v','w','d','m','n','b','g','l','p','f','v','w','d','m','n','b','g','l','p','f','v','w',/**/'th','tr','thr','gr','cr','cl','br','bl','fl','fr','ar','or','wr','h','sc','sh','ch','wh','wh','wh','dr','st','str','squ','pl','pr','y'],
			mids:[/*common*/'a','a','a','a','a','o','o','o','o','i','i','i','i','e','e','e','e','e',/**/'oo','ee','ea','io','ie','ei','iou','u','au','ai','ou','y'],
			joints:['l','t','cr','ct','rm','tr','s','r','rs','pt','g','gg','b','h','ll','ls','th','gn','nc','ns','nd','rst','v','lv','ght','ghb','rb','bd','ncl','bg','lt','st','qu','rt','lb','gl','ff','fr','fl','mb','x'],
			ends:['k','ck','s','ss','sk','m','n','nt','nk','nks','ng','ng','ng','ngs','le','ne','me','de','t','tt','ll','rp','p','r','re','d','w','l','ble','nkle','ttle','ggle','the','te','ve','gh','cks','tch','rch','nch','rse','sh','rt','rst','rsty','rty','rm','rf','pt','nny','se','ce','ge','nce','nge','ngth','rk','key','ky','sy','ry','ty','ly','py','lly','ff','t\'s','\'s','x','zz'],
		},
		'french':{
			name:'Frankoid',
			starts:['b','j','g','d','h','p','m','n','ad','ab','fr','fl','ch','f','c','ph','qu','gr','tr','l','gl','dr','cl','cr','br','bl','pr','pl','t','r','s','sc','l\'','s\'','qu\'','&eacute;l','&eacute;t','&eacute;tr'],
			mids:['a','a','a','o','o','i','i','e','e','e','u','u','ai','au','ou','oi','ui','ie','&agrave;','&egrave;','&eacute;','&ecirc;','&acirc;','&ucirc;','&ocirc;'],
			joints:['l','t','c','cr','cc','ss','ct','tr','rs','rt','ff','fr','fl','pt','pht','s','r','g','ll','gn','nc','ns','nd','ls','dm','mb','mbl','md','mpt','ng','mm','nn','v','lv','rb','bd','lt','lb','st','mb','mbr','qu','&ccedil;'],
			ends:['nt','nd','nte','nde','m','n','le','ne','me','de','rti','rtie','r','t','te','t&eacute;','s&eacute;','tte','tre','che','cru','gru','gt','que','sque','n','rd','rde','rt','rte','s','se','fe','re','phe','d','l','gne','tion','bli','pi','pie','rme','ble','tions','lier','li&egrave;re','bles','teau','telle','peau','pelle','meau','melle','ste','nse','nce','rs','ng','nge','x','z'],
		},
		'japanese':{
			name:'Nipponoid',
			starts:['ak','al','as','ik','is','its','ot','ok','k','s','t','n','h','m','w','d','p','j','ch','z','r','sh','g','ts'],
			mids:[/*common*/'a','a','a','o','o','o','u','u','i','i','e','e','a','a','a','o','o','o','u','u','i','i','e','e',/**/'in','ou','ai','ao','ii','ei','yo','ya','yu','aa'],
			joints:['t','k','s','b','n','m','g','z','sh','j','p','d','h','kk','ch','ts','ht'],
			ends:['ko','ka','ki','ku','ke','mo','ma','mi','mu','me','no','na','ni','nu','ne','to','ta','ti','tu','te','ro','ra','ri','ru','re','jo','ja','ji','ju','je','do','da','di','du','de','tso','tsa','tsi','tsu','tse','n','n','n','n','wa','sai','chi','jio'],
		},
		'grecoroman':{
			name:'Grecoromanoid',
			starts:['m','n','x','g','gn','p','tr','t','gr','ad','ap','agr','atr','ant','ambr','arthr','pr','cl','chl','kl','st','sp','sk','skl','skr','ov','om','omb','onth','on','v','l','k','h','d','s','int','inc','in','fr','gl','pt','pht','aut','aud','ur','ult','exp','extr','ext'],
			mids:['a','e','i','o','u','y','io','ia','iu','ae','eu'],
			joints:['th','l','ll','nt','t','thr','tr','st','sk','skl','skr','gr','ngr','ntr','nth','v','g','gg','c','cc','k','s','x','d','cl','ct','kl','r','fr','pt','pht','mb','mbr'],
			ends:[/*common*/'n','s','m','th','d','n','s','m','th','sma','rma','d','n','s','m','th','d','n','s','m','th','d',/**/'x','na','nus','nis','sa','sia','sus','sis','ta','tia','tius','tis','ga','gia','gius','gis','la','lia','lius','lis'],
		},
	};
	
	G.translate=function(input,languages,seed)
	{
		var starts=[];
		var mids=[];
		var joints=[];
		var ends=[];
		
		var seed=seed||'0';
		if (!languages) {languages=[];for (var i in G.languages) {languages.push(i);}}
		for (var i in languages)
		{
			var language=G.languages[languages[i]];
			starts.push(language.starts);
			mids.push(language.mids);
			joints.push(language.joints);
			ends.push(language.ends);
		}
		
		var output='';
		input=decodeEntities(input);
		input+=' ';
		var len=input.length;
		var word='';
		var endWord=false;
		for (var i=0;i<len;i++)
		{
			var thisChar=input.charAt(i);
			//if the char is a letter or ', add it to the word; if not, end the word
			if (thisChar.toLowerCase()!=thisChar.toUpperCase() || thisChar=='\'') {word+=thisChar;} else {endWord=true;}
			if (endWord && word.length>0)
			{
				//if we reached the end of a word, process it; chop it into chunks of 4 letters and translate each chunk
				var len2=Math.ceil(word.length/4);
				var bits=[];
				var balance=false;
				//if (len2%3==2) balance=true;//if the last chunk is only 1 letter, add 1 to it and remove 1 from the first chunk
				for (var ii=0;ii<len2;ii++)
				{
					//if (ii==len2-2 && balance) bits.push(word.charAt(ii*3)+word.charAt(ii*3+1));
					//else if (ii==len2-1 && balance) bits.push(word.charAt(ii*3-1)+word.charAt(ii*3)+word.charAt(ii*3+1));
					//else bits.push(word.charAt(ii*3)+word.charAt(ii*3+1)+word.charAt(ii*3+2));
					bits.push(word.charAt(ii*3)+word.charAt(ii*3+1)+word.charAt(ii*3+2));
				}
				var len2=bits.length;
				for (var ii=0;ii<len2;ii++)
				{
					var bit='';
					Math.seedrandom('translate'+seed+bits[ii].toLowerCase());
					var lang=Math.floor(Math.random()*starts.length);
					var start=starts[lang];
					var end=ends[lang];
					var mid=mids[lang];
					var joint=joints[lang];
					if (ii==0 && ii==len2-1 && bits[ii].length>2 && Math.random()<0.5) bit=choose(start)+choose(mid)+choose(end);//longish singles
					else if (ii==0 && ii==len2-1) bit=choose([choose(mid),choose(start)+choose(mid),choose(mid)+choose(end)]);//singles
					else if (ii==0) bit=choose(start)+choose(mid);//first part
					else if (ii==len2-1) bit=choose(end);//end
					else bit=choose(joint)+choose(mid);//middles
					
					bit=decodeEntities(bit);
					if (bits[ii].charAt(0).toUpperCase()==bits[ii].charAt(0)) bit=bit.charAt(0).toUpperCase()+bit.slice(1);
					output+=bit;
				}
				word='';
			}
			if (endWord) {output+=thisChar;word='';endWord=false;}
		}
		output=output.slice(0,-1);
		return output;
	}
	G.getRandomString=function(syllables,maxSyllables)
	{
		if (!maxSyllables) var maxSyllables=syllables;
		syllables=Math.floor(Math.random()*(maxSyllables-syllables)+syllables);
		var vow=['a','e','i','o','u','y'];
		var cons=['b','c','d','f','g','h','j','k','l','m','n','p','q','r','s','t','v','w','x','z'];
		var str='';
		for (var i=0;i<syllables;i++)
		{
			str+=choose(cons)+choose(vow);
		}
		if (Math.random()<0.25) str+=choose(cons);
		return str;
	}
	G.testTranslate=function(input,languages)
	{
		for (var i=0;i<10;i++)
		{
			document.write(G.translate(input,languages)+'<br>');
		}
	}

	/*=====================================================================================
	RESOURCES
	=======================================================================================*/
	G.res=[];
	G.resByName=[];
	G.getRes=function(name){if (!G.resByName[name]) ERROR('No resource exists with the name '+name+'.'); else return G.resolveRes(G.resByName[name]);}
	G.getRawRes=function(name){if (!G.resByName[name]) ERROR('No resource exists with the name '+name+'.'); else return G.resByName[name];}
	G.resCategories=[];
	G.resInstances=[];//all resources displayed are actually instances of resources; this lets us have a resource be displayed multiple times (for instance in the regular display and in a pinned list) - note : these instances are not actually saved and are recreated with every filter change; amounts are part of the resource itself, not its instances
	G.resN=0;//incrementer
	
	G.Res=function(obj)
	{
		this.type='res';
		this.amount=0;
		this.used=0;//only used by some special resources (houses occupied, workers busy...); will only be handled and saved if the resource has .displayUsed=true
		this.mult=1;//gain multiplier; all gains of this resource are multiplied by this; updated every tick
		this.displayedAmount=0;//used to tick up the displayed number
		this.displayedUsedAmount=0;//used to tick up the displayed number
		this.startWith=0;
		this.gained=0;//gained this tick
		this.lost=0;//lost this tick
		this.gainedBy=[];//filled by unit names and other processes that create this resource; emptied after every tick
		this.lostBy=[];//filled by unit names and other processes that use up this resource; emptied after every tick
		this.meta=false;//does this resource have subparts?
		this.partOf=false;//is this resource a subpart of another resource? (a resource cannot be a subresource AND have subresources of its own)
		this.subRes=[];//subresources if this is a meta-resource; handled automatically
		this.tick=function(){};
		this.getMult=function(){return 1;};
		this.getDisplayAmount=function(){
			if (this.displayUsed) return B(this.displayedUsedAmount)+'<wbr>/'+B(this.displayedAmount);
			else return B(this.displayedAmount);
		};
		this.category='';
		this.icon=[0,0];
		this.visible=false;//a resource will only be displayed if you've had some of the resource at some point (you can set .visible to force it to start visible; you can also set .hidden to override .visible)
		
		for (var i in obj) this[i]=obj[i];
		this.id=G.res.length;
		if (!this.displayName) this.displayName=cap(this.name);
		G.res.push(this);
		G.resByName[this.name]=this;
		G.setDict(this.name,this);
		this.mod=G.context;
	}
	
	G.lose=function(what,amount,context)
	{
		if (amount<0) {return G.gain(what,-amount,context);}
		//remove some amount from a resource; return how much we did manage to remove
		var me=G.getRes(what);
		if (me.replacement) me=G.getRes(me.replacement);
		var removed=0;
		if (amount>0)
		{
			if (me.meta)
			{
				var resAmount=0;
				for (var i in me.subRes) {resAmount+=G.resolveRes(me.subRes[i]).amount;}
				if (resAmount>0)
				{
					for (var i in me.subRes) {if (G.resolveRes(me.subRes[i]).amount>0) {G.lose(me.subRes[i].name,/*Math.round*/((G.resolveRes(me.subRes[i]).amount/resAmount)*amount),context);}}
				}
				removed+=Math.min(amount,resAmount);
			}
			else
			{
				var oldAmount=me.amount;
				me.amount-=amount;
				if (!me.fractional) me.amount=Math.max(0,randomFloor(me.amount));
				removed=oldAmount-me.amount;
				if (context && me.turnToByContext && me.turnToByContext[context])
				{
					for (var i in me.turnToByContext[context]) {G.gain(i,me.turnToByContext[context][i]*removed,(me.name==i?'-':me.displayName));}
				}
				if (context!='-') me.lost+=removed;
				if (context && context!='-' && !me.lostBy.includes(context)) me.lostBy.push(context);
				if (me.partOf) 
				{
					var meta=G.getRes(me.partOf);
					if (context!='-') meta.lost+=removed;
					if (context && context!='-' && !meta.lostBy.includes(context)) meta.lostBy.push(context);
				}
			}
		}
		return removed;
	}
	G.gain=function(what,amount,context)
	{
		//add some amount to a resource; do not use on meta-resources
		if (amount<0) {return G.lose(what,-amount,context);}
		var me=G.getRes(what);
		if (me.replacement) me=G.getRes(me.replacement);
		if (amount>0)
		{
			if (me.meta)
			{
				return 0;
			}
			else
			{
				var oldAmount=me.amount;
				me.amount+=amount*me.mult;
				if (!me.fractional) me.amount=randomFloor(me.amount);
				if (context!='-') me.gained+=me.amount-oldAmount;
				if (context && context!='-' && !me.gainedBy.includes(context)) me.gainedBy.push(context);
				if (me.partOf) 
				{
					var meta=G.getRes(me.partOf);
					if (context!='-') meta.gained+=me.amount-oldAmount;
					if (context && context!='-' && !meta.gainedBy.includes(context)) meta.gainedBy.push(context);
				}
			}
		}
	}
	G.getAmount=function(what)
	{
		//add some amount to a resource; do not use on meta-resources
		var me=G.getRes(what);
		if (me.replacement) me=G.getRes(me.replacement);
		return me.amount;
	}
	
	G.testCost=function(costs,mult)
	{
		//can we afford the specified amount
		var success=true;
		for (var i in costs)
		{
			var cost=costs[i]*mult;
			if (cost>0)
			{
				var res=G.getRes(i);
				if (res.meta)
				{
					var resAmount=0;
					for (var ii in res.subRes) {resAmount+=res.subRes[ii].amount;}
					if (resAmount<cost) success=false;
				}
				else
				{
					if (res.amount<cost) success=false;
				}
			}
		}
		return success;
	}
	G.testAnyCost=function(costs)
	{
		//how many we can afford (returns -1 for infinity)
		var n=-1;
		for (var i in costs)
		{
			var cost=costs[i];
			if (cost>0)
			{
				var res=G.getRes(i);
				if (res.meta)
				{
					var resAmount=0;
					for (var ii in res.subRes) {resAmount+=res.subRes[ii].amount;}
					if (n==-1) n=resAmount/cost; else n=Math.min(n,resAmount/cost);
				}
				else
				{
					if (n==-1) n=res.amount/cost; else n=Math.min(n,res.amount/cost);
				}
			}
		}
		n=Math.floor(n);
		return n;
	}
	G.testUse=function(uses,mult)
	{
		//can we afford the specified amount
		var success=true;
		for (var i in uses)
		{
			var use=uses[i]*mult;
			if (use>0)
			{
				var res=G.getRes(i);
				var free=(res.amount-res.used);
				if (res.used>res.amount) free=0;
				if (free<use) success=false;
			}
		}
		return success;
	}
	G.testAnyUse=function(uses)
	{
		//how many we can afford (returns -1 for infinity)
		var n=-1;
		for (var i in uses)
		{
			var use=uses[i];
			if (use>0)
			{
				var res=G.getRes(i);
				var free=(res.amount-res.used);
				if (res.used>res.amount) free=0;
				if (n==-1) n=free/use; else n=Math.min(n,free/use);
			}
		}
		n=Math.floor(n);
		return n;
	}
	G.testLimit=function(limits,amount)
	{
		//can we afford the specified amount
		var success=true;
		for (var i in limits)
		{
			var limit=limits[i];
			if (limit>0)
			{
				var res=G.getRes(i);
				if (((res.amount+limit)/amount)<=limit) success=false;
			}
		}
		return success;
	}
	G.testAnyLimit=function(limits,amount)
	{
		//how many we can afford (returns -1 for infinity)
		var n=-1;
		if (!limits || isEmpty(limits)) return n;
		for (var i in limits)
		{
			var limit=limits[i];
			if (limit>0)
			{
				var res=G.getRes(i);
				if (n==-1) n=((res.amount+limit)/amount)/limit; else n=Math.min(n,((res.amount+limit)/amount)/limit);
			}
		}
		n=Math.floor(n);
		return n;
	}
	G.subtractCost=function(cost1,cost2,mult)
	{
		//returns a list of costs that is cost2, minus all the costs in cost1
		var out={};
		var mult=mult||1;
		
		for (var i in cost2)
		{
			var cost=cost2[i]*mult;
			if (cost1[i]) cost-=cost1[i]*mult;
			if (cost>0) out[i]=cost;
		}
		return out;
	}
	
	G.doCost=function(costs,mult)
	{
		for (var i in costs)
		{
			var res=G.getRes(i);
			var cost=costs[i]*mult;
			
			if (res.meta)
			{
				var resAmount=0;
				for (var ii in res.subRes) {resAmount+=G.resolveRes(res.subRes[ii]).amount;}
				for (var ii in res.subRes)
				{
					var subRes=G.resolveRes(res.subRes[ii]);
					subRes.amount-=/*Math.round*/((subRes.amount/resAmount)*cost);
					if (!subRes.fractional) subRes.amount=Math.max(randomFloor(subRes.amount),0);
				}
			}
			else
			{
				res.amount-=cost;
				if (!res.fractional) res.amount=Math.max(randomFloor(res.amount),0);
			}
		}
	}
	G.doUse=function(uses,mult)
	{
		for (var i in uses)
		{
			var res=G.getRes(i);
			var use=uses[i]*mult;
			res.used+=use;
		}
	}
	G.undoUse=function(uses,mult)
	{
		for (var i in uses)
		{
			var res=G.getRes(i);
			var use=uses[i]*mult;
			res.used-=use;
			if (res.used<0) res.used=0;
		}
	}
	
	G.cacheMetaResources=function()
	{
		G.metaRes=[];
		for (var i in G.res) {if (G.res[i].meta) {G.metaRes.push(G.res[i]);G.res[i].subRes=[];}}
		G.subRes=[];
		for (var i in G.res)
		{
			if (G.res[i].partOf)
			{
				G.subRes.push(G.res[i]);
				G.getRes(G.res[i].partOf).subRes.push(G.res[i]);
			}
		}
	}
	
	G.pseudoGather=function(what,amount)
	{
		what.whenGathered(what,amount);
	}
	
	G.makePartOf=function(what,parent)
	{
		//what is a resource name (or an array of resource names) that should become a part of the parent resource
		//parent can be an empty string to remove the relationship
		if (typeof what==='string') what=[what];
		var len=what.length;
		for (var i=0;i<len;i++)
		{
			G.resByName[what[i]].partOf=(parent==''?false:parent);
		}
		G.cacheMetaResources();
		G.update['res']();
	}
	
	G.getResTooltip=function(me,amountStr)
	{
		var str='<div class="info">';
		str+='<div class="infoIcon"><div class="thing standalone'+G.getIconClasses(me,true)+'">'+G.getIconStr(me,0,0,true)+'</div><div class="fancyText infoAmount">'+(amountStr||me.getDisplayAmount())+'</div></div>';
		str+='<div class="fancyText barred infoTitle">'+me.displayName+'</div>';
		if (me.partOf && !G.getDict(me.partOf).hidden) str+='<div class="fancyText barred">part of '+G.getSmallThing(G.getDict(me.partOf))+'</div>';
		if (me.limit) str+='<div class="fancyText barred">limit : '+(G.getDict(me.limit)).getDisplayAmount()+' '+G.getSmallThing(G.getDict(me.limit))+'</div>';
		if (!amountStr)
		{
			if (me.gained>0 && me.gainedBy.length>0) str+='<div class="fancyText barred" style="color:#3f0;">+'+B(me.gained,1)+' from '+me.gainedBy.join(', ')+'</div>';
			else if (me.gained>0) str+='<div class="fancyText barred" style="color:#3f0;">+'+B(me.gained,1)+'</div>';
			if (me.lost>0 && me.lostBy.length>0) str+='<div class="fancyText barred" style="color:#f30;">-'+B(me.lost,1)+' from '+me.lostBy.join(', ')+'</div>';
			else if (me.lost>0) str+='<div class="fancyText barred" style="color:#f30;">-'+B(me.lost,1)+'</div>';
		}
		if (me.desc) str+='<div class="infoDesc">'+G.parse(me.desc)+'</div>';
		str+='</div>';
		str+=G.debugInfo(me);
		return str;
	}
	
	G.logic['res']=function()
	{
		//update visibility
		var len=G.res.length;
		for (var i=0;i<len;i++)
		{
			var res=G.res[i];
			res.gainedBy=[];
			res.lostBy=[];
			res.gained=0;
			res.lost=0;
		}
		for (var i=0;i<len;i++)
		{
			var realRes=G.res[i];
			var res=G.resolveRes(realRes);
			if (res!=realRes)
			{
				realRes.tick(realRes,G.tick);
				if (realRes.hidden) realRes.visible=false;
				else if (res.amount!=0) realRes.visible=true;
			}
			else
			{
				res.tick(res,G.tick);
				res.mult=res.getMult();
				if (res.hidden) res.visible=false;
				else if (res.amount!=0) res.visible=true;
			}
		}
		//resolve meta-resources with sub-resources
		var len=G.metaRes.length;
		for (var i=0;i<len;i++)
		{
			var me=G.resolveRes(G.metaRes[i]);me.amount=0;
		}
		var len=G.subRes.length;
		for (var i=0;i<len;i++)
		{
			var me=G.subRes[i];
			var meta=G.getRes(me.partOf);
			meta.amount+=me.amount;
			meta.gained+=me.gained;
			meta.lost+=me.lost;
			for (var ii in me.gainedBy)
			{if (!meta.gainedBy.includes(me.gainedBy[ii])) meta.gainedBy.push(me.gainedBy[ii]);}
			for (var ii in me.lostBy)
			{if (!meta.lostBy.includes(me.lostBy[ii])) meta.lostBy.push(me.lostBy[ii]);}
		}
	}
	G.update['res']=function()
	{
		var str='';
		
		str+=G.textWithTooltip('?','<div style="width:240px;text-align:left;"><div class="par">These are your resources. Some of them are physical goods you own, while others are indicators of various stats about your civilization.</div><div class="par">Resources are used for many things; creating units, crafting more resources, generating technologies and cultural traits...</div><div class="par">Some resources are part of other resources; for instance, the "food" resource represents the sum of all food-type resources you own, such as herbs and fruits.</div><div class="par">Many resources decay over time : food rots, fresh water goes bad, crafting materials get lost or stolen. Some measures such as storage containers can mitigate that.</div><div class="par">You can click on resource category headers to collapse them.</div></div>','infoButton');
		
		l('extraRes').innerHTML=str;
		
		//create the instances and set their DOM
		G.resInstances=[];
		G.resN=0;
		str='';
		
		var catI=0;
		//run through every category and create resource instances as specified
		for (var i in G.resCategories)
		{
			var cat=G.resCategories[i];
			str+='<div class="categoryName barred fancyText" style="display:none;" id="res-catName-'+catI+'">'+cat.name+'</div>';
			if (cat.open)
			{
				var catRes=[];
				var catSideRes=[];
				for (var ii in cat.base||[])
				{catRes.push(G.getRawRes(cat.base[ii]));}
				for (var ii in cat.side||[])
				{catSideRes.push(G.getRawRes(cat.side[ii]));}
				
				G.resCategories[i].contents=[];//we're caching the resources contained in each category, this comes in handy later
				
				//if (catI>0) str+='<div class="divider"></div>';
				
				str+='<div class="category'+(catSideRes.length>0?' categoryWithSide':'')+'" style="display:none;" id="res-cat-'+catI+'">';
				
				if (catSideRes.length>0)
				{
					str+='<div class="sideCategory">';
					for (var ii in catSideRes)
					{
						var rawMe=catSideRes[ii];
						var me=G.resolveRes(catSideRes[ii]);
						var instance={res:rawMe,id:G.resN};
						G.resInstances.unshift(instance);
						G.resCategories[i].contents.push(rawMe);
						G.resN++;
						
						str+='<div class="res thing'+G.getIconClasses(rawMe)+'" id="res-'+instance.id+'" style="display:none;">'+
							G.getIconStr(rawMe,'res-icon-'+instance.id)+
							'<div class="overlay" id="res-over-'+instance.id+'"></div>'+
							'<div class="amount" id="res-amount-'+instance.id+'"></div>'+
						'</div>';
					}
					str+='</div>';
				}
				
				for (var ii in catRes)
				{
					var rawMe=catRes[ii];
					var me=G.resolveRes(catRes[ii]);
					var instance={res:rawMe,id:G.resN};
					G.resInstances.unshift(instance);
					G.resCategories[i].contents.push(rawMe);
					G.resN++;
					
					str+='<div class="res thing'+G.getIconClasses(rawMe)+'" id="res-'+instance.id+'">'+
						G.getIconStr(rawMe,'res-icon-'+instance.id)+
						'<div class="overlay" id="res-over-'+instance.id+'"></div>'+
						'<div class="amount" id="res-amount-'+instance.id+'"></div>'+
					'</div>';
				}
				
				str+='</div>';
			}
			catI++;
		}
		
		l('resBox').innerHTML=str;
		
		G.addCallbacks();
		
		//run through every category and attach event handlers (toggling category visibility)
		var catI=0;
		for (var i in G.resCategories)
		{
			var me=G.resCategories[i];
			var div=l('res-catName-'+catI);
			if (div) div.onclick=function(cat){return function(){
				cat.open=!cat.open;
				G.update['res']();
			};}(me);
			
			G.resCategories[i].l=l('res-cat-'+catI);
			G.resCategories[i].lName=div;
			catI++;
		}
		
		//run through every instance and attach event handlers
		var len=G.resInstances.length;
		for (var i=0;i<len;i++)
		{
			var me=G.resInstances[i];
			var div=l('res-'+me.id);if (div) me.l=div; else me.l=0;
			var div=l('res-icon-'+me.id);if (div) me.lIcon=div; else me.lIcon=0;
			var div=l('res-over-'+me.id);if (div) me.lOver=div; else me.lOver=0;
			var div=l('res-amount-'+me.id);if (div) me.lAmount=div; else me.lAmount=0;
			G.addTooltip(me.l,function(me){return function(){
				return G.getResTooltip(me);
			};}(me.res),{offY:-8});
			if (me.l) me.l.onclick=function(me){return function(){
				if (G.getSetting('debug'))
				{
					//debug : click on a resource to add to it for free
					var res=me.res;
					var amount=G.getBuyAmount();
					if (amount<0) G.lose(res.name,-amount,'cheating');
					else if (amount>0) {if (res.whenGathered) res.whenGathered(res,amount); else G.gain(res.name,amount,'cheating');}
					if (amount!=0 && G.getSetting('animations')) triggerAnim(me.l,'plop');
				}
			};}(me);
		}
		G.draw['res']();
	}
	G.draw['res']=function()
	{
		var alreadyDone=[];//we want to only update displayed amounts of resources we're displaying, but we only want to do each resource once even if it has multiple instances
		/*var bounds=l('resources').getBoundingClientRect();
		var top=bounds.top;
		var bottom=bounds.bottom;*/
		
		var showAll=(G.getSetting('showAllRes') && G.getSetting('debug'));
		//run through every category and set it to visible if one of its constituents is visible
		var catI=0;
		for (var i in G.resCategories)
		{
			var cat=G.resCategories[i];
			var visible=false;
			for (var ii in cat.contents)
			{
				if (cat.contents[ii].visible || (showAll && !cat.contents[ii].hidden)) visible=true;
			}
			if (visible)
			{
				if (cat.lName) cat.lName.style.display='block';
				if (cat.l) cat.l.style.display='block';
			}
			catI++;
		}
		
		var len=G.resInstances.length;
		for (var i=0;i<len;i++)
		{
			var instance=G.resInstances[i];
			//var myBounds=instance.l.getBoundingClientRect();
			if (false){}//(myBounds.bottom<top || myBounds.top>bottom) {}
			else//NOTE : turns out getBoundingClientRect is actually PRETTY DANG SLOW//only update if visible within the scrolled section of the resource box
			{
				var rawMe=instance.res;
				var me=G.resolveRes(rawMe);
				var formattedAmount=me.getDisplayAmount();
				var dif=me.displayedAmount-me.amount;
				if (dif>0.001) {instance.l.classList.remove('green');instance.l.classList.add('red');}
				else if (dif<-0.001) {instance.l.classList.remove('red');instance.l.classList.add('green');}
				else {instance.l.classList.remove('red');instance.l.classList.remove('green');}
				if (!me.fractional)
				{
					if (me.amount>0) {instance.l.classList.remove('zero');}
					else {instance.l.classList.add('zero');}
				}
				if (instance.lAmount) instance.lAmount.innerHTML=formattedAmount;
				if (!alreadyDone.includes(me.name))//update displayed amounts
				{
					me.displayedAmount+=(me.amount-me.displayedAmount)*0.25;
					if (Math.abs(me.displayedAmount-me.amount)<0.5) me.displayedAmount=me.amount;
					if (me.displayUsed)
					{
						me.displayedUsedAmount+=(me.used-me.displayedUsedAmount)*0.25;
						if (Math.abs(me.displayedUsedAmount-me.used)<0.5) me.displayedUsedAmount=me.used;
					}
					alreadyDone.push(me.name);
				}
				if (((showAll && !rawMe.hidden) || rawMe.visible) && rawMe.getIcon) G.setIcon(instance.lIcon,rawMe.getIcon(rawMe));
				if ((showAll && !rawMe.hidden) || rawMe.visible) instance.l.style.display='inline-block'; else instance.l.style.display='none';
			}
		}
	}
	
	/*=====================================================================================
	UNITS
	=======================================================================================*/
	G.unit=[];
	G.unitCategories=[];
	G.unitByName=[];
	G.getUnit=function(name){if (!G.unitByName[name]) ERROR('No unit exists with the name '+name+'.'); else return G.unitByName[name];}
	G.unitN=0;//incrementer
	G.unitsOwned=[];//all units the player currently has, from newest to oldest
	G.unitsOwnedNames=[];//names of all units owned
	G.Unit=function(obj)
	{
		this.type='unit';
		this.startWith=0;
		this.cost={};//spent to purchase the unit
		this.use={};//resources the unit "takes up", such as workers or land; must satisfy these to purchase; also, if the used resources become lacking, the unit will waste away
		this.staff={};//much like "use", except the unit doesn't waste away if it lacks those (use this for workers in a building, or a worker's tools); a percent of it simply goes idle - if the requirements are met again, the unit will cease being idle
		this.require={};//resources the unit requires to build; works like "use", except the resources aren't actually used, we just need to own the specified amounts
		this.upkeep={};//used every tick to keep the unit working
		this.limitPer={};//the unit can't be built more than 1 per X of those resources (ie. : "only 1 per 100 population")
		this.effects=[];
		this.modes=[];
		this.category='';
		this.icon=[0,0];
		this.priority=0;//units with a higher priority are executed and built first
		
		for (var i in obj) this[i]=obj[i];
		this.id=G.unit.length;
		if (!this.displayName) this.displayName=cap(this.name);
		if (this.wonder)
		{
			//if the unit is a wonder, .mode is now an integer representing the status of the wonder (0 : not started, 1 : started, 2 : started but paused, 3 : needs final step, 4 : complete) and .percent is now the wonder's completion step
			//a wonder takes an initial cost, then a cost repeated a number of steps, then a final cost before it is complete
			this.finalStepCost=this.finalStepCost||{};
			this.finalStepUse=this.finalStepUse||{};
			this.finalStepRequire=this.finalStepRequire||{};
			this.steps=this.steps||0;
			this.costPerStep=this.costPerStep||{};
		}
		G.unit.push(this);
		G.unitByName[this.name]=this;
		G.setDict(this.name,this);
		this.mod=G.context;
	}
	G.logic['unit']=function()
	{
		var mult=G.doFunc('production multiplier',1);//global production multiplier - affects how many times the unit effects will be applied every tick
		
		var len=G.unitsOwned.length;
		//we turn the list of owned units into internally shuffled sections sorted by priority, then work through those in order
		var priorities=[];
		for (var i=0;i<len;i++)
		{
			if (!priorities[G.unitsOwned[i].unit.priority]) priorities[G.unitsOwned[i].unit.priority]=[G.unitsOwned[i].unit.priority];
			priorities[G.unitsOwned[i].unit.priority].push(G.unitsOwned[i]);
		}
		
		priorities.sort(function(a,b){return b[0]-a[0]});
				
		for (var iP in priorities)
		{
			priorities[iP].shift();
			shuffle(priorities[iP]);
			var len=priorities[iP].length;
			for (var i=0;i<len;i++)
			{
				var me=priorities[iP][i];
				if (!me.unit.wonder && me.amount<me.targetAmount)//try to build up to target
				{
					var toMake=Math.min(me.targetAmount-me.amount,Math.max(1,me.targetAmount*0.5));
					G.buyUnit(me,toMake,true);
				}
				else if (!me.unit.wonder && me.amount>me.targetAmount)
				{
					var toDie=Math.min(me.amount-me.targetAmount,Math.max(1,me.amount*0.5));
					G.killUnit(me,toDie,true);
				}
				if (!me.unit.wonder && me.idle>0)//try to refill
				{
					var toMake=Math.min(me.idle,Math.max(1,me.idle*0.5));
					G.unidleUnit(me,toMake);
				}
				
				var amount=G.applyUnitAmountEffects(me);//modify the effective amount
				if (amount>0)
				{
					//apply effects every tick
					var repeat=randomFloor(mult);
					if (repeat>0)
					{
						for (var ii=0;ii<repeat;ii++)
						{
							G.applyUnitEffects(me,amount);
						}
					}
				}
				if (me.unit.wonder)
				{
					//apply steps
					if (me.mode==1 || me.mode==2)
					{
						if (me.percent>=me.unit.steps)
						{
							me.mode=3;
							if (G.getSetting('animations') && me.l) triggerAnim(me.l,'plop');
						}
						if (me.mode==1 && G.testCost(me.unit.costPerStep,1))
						{
							me.percent++;
							G.doCost(me.unit.costPerStep,1);
							if (G.getSetting('animations') && me.l) triggerAnim(me.l,'plop');
						}
						if (me.percent>=me.unit.steps)
						{
							me.mode=3;
							if (G.getSetting('animations') && me.l) triggerAnim(me.l,'plop');
						}
					}
				}
				if (me.amount>0)
				{
					var waste=0;
					var idle=0;
					//run upkeep and check used resources; if we're short on either, waste away
					for (var ii in me.unit.upkeep)
					{
						var res=G.getRes(ii);
						var upkeep=me.unit.upkeep[ii]*(me.amount-me.idle);
						var spent=G.lose(ii,upkeep,'unit upkeep');
						if (spent<upkeep)
						{
							if (me.unit.alternateUpkeep && me.unit.alternateUpkeep[ii])//last resort
							{spent+=G.lose(me.unit.alternateUpkeep[ii],upkeep*(me.amount-me.idle)-spent,'unit upkeep');}
							if (spent<upkeep) idle=true;
						}
					}
					for (var ii in me.unit.use)
					{
						var res=G.getRes(ii);
						var use=me.unit.use[ii];
						//if (res.amount<res.used) waste=1;
						//if (me.amount>0 && res.name=='worker') console.log('we need '+(use*(me.amount))+', we have '+(res.amount-res.used)+' for '+(me.amount)+' '+me.unit.name+'; deleting '+(waste,(use*(me.amount)-(res.amount-res.used))/use));
						if (use && (res.amount<=use*(me.amount) || res.amount<res.used)) waste=true;
					}
					for (var ii in me.unit.staff)
					{
						var res=G.getRes(ii);
						var use=me.unit.staff[ii];
						//if (res.amount<res.used) idle=1;
						if (use && (res.amount<=use*(me.amount-me.idle) || res.amount<res.used)) idle=true;
					}
					for (var ii in me.mode.use)
					{
						var res=G.getRes(ii);
						var use=me.mode.use[ii];
						//if (res.amount<res.used) idle=1;
						if (use && (res.amount<=use*(me.amount-me.idle) || res.amount<res.used)) idle=true;
					}
					if (!G.testLimit(me.unit.limitPer,G.getUnitAmount(me.unit.name))) waste=true;
					
					//if (idle) G.idleUnit(me,Math.ceil(idle));
					//if (waste) G.wasteUnit(me,Math.ceil(waste));
					if (idle) G.idleUnit(me,Math.ceil((me.amount-me.idle)*0.05));
					if (waste) G.wasteUnit(me,Math.ceil(me.amount*0.05));
				}
			}
		}
	}
	G.update['unit']=function()
	{
		l('unitDiv').innerHTML=
			G.textWithTooltip('?','<div style="width:240px;text-align:left;"><div class="par">Units are the core of your resource production and gathering.</div><div class="par">Units can be <b>queued</b> for purchase by clicking on them; they will then automatically be created over time until they reach the queued amount. Creating units usually takes up resources such as workers or tools; resources shown in red in the tooltip are resources you do not have enough of.<div class="bulleted">click a unit to queue 1</div><div class="bulleted">right-click or ctrl-click to remove 1</div><div class="bulleted">shift-click to queue 50</div><div class="bulleted">shift-right-click or ctrl-shift-click to remove 50</div></div><div class="par">Units usually require some resources to be present; a <b>building</b> will crumble if you do not have the land to support it, or it could go inactive if you lack the workers or tools (it will become active again once you fit the requirements). Some units may also require daily <b>upkeep</b>, such as fresh food or money, without which they will go inactive.</div><div class="par">Furthermore, workers will sometimes grow old, get sick, or die, removing a unit they\'re part of in the process.</div><div class="par">Units that die off will be automatically replaced until they match the queued amount again.</div><div class="par">Some units have different <b>modes</b> of operation, which can affect what they craft or how they act; you can use the small buttons next to such units to change those modes and do other things. One of those buttons is used to <b>split</b> the unit into another stack; each stack can have its own mode.</div></div>','infoButton')+
			'<div style="position:absolute;z-index:100;top:0px;left:0px;right:0px;text-align:center;"><div class="flourishL"></div>'+
				G.button({id:'removeBulk',
					text:'<span style="position:relative;width:9px;margin-left:-4px;margin-right:-4px;z-index:10;font-weight:bold;">-</span>',
					tooltip:'Divide by 10',
					onclick:function(){
						var n=G.getSetting('buyAmount');
						if (G.keys[17]) n=-n;
						else
						{
							if (n==1) n=-1;
							else if (n<1) n=n*10;
							else if (n>1) n=n/10;
						}
						n=Math.round(n);
						n=Math.max(Math.min(n,1e+35),-1e+35);
						G.setSetting('buyAmount',n);
						G.updateBuyAmount();
					},
				})+
				'<div id="buyAmount" class="bgMid framed" style="width:128px;display:inline-block;padding-left:8px;padding-right:8px;font-weight:bold;">...</div>'+
				G.button({id:'addBulk',
					text:'<span style="position:relative;width:9px;margin-left:-4px;margin-right:-4px;z-index:10;font-weight:bold;">+</span>',
					tooltip:'Multiply by 10',
					onclick:function(){
						var n=G.getSetting('buyAmount');
						if (G.keys[17]) n=-n;
						else
						{
							if (n==-1) n=1;
							else if (n>-1) n=n*10;
							else if (n<-1) n=n/10;
						}
						n=Math.round(n);
						n=Math.max(Math.min(n,1e+35),-1e+35);
						G.setSetting('buyAmount',n);
						G.updateBuyAmount();
					}
				})+
			'<div class="flourishR"></div></div>'+
			'<div class="fullCenteredOuter" style="padding-top:16px;"><div id="unitBox" class="thingBox fullCenteredInner"></div></div>';
		
		/*
			-create an empty string for every unit category
			-go through every unit owned and add it to the string of its category
			-display each string under category headers, then attach events
		*/
		var strByCat=[];
		var len=G.unitCategories.length;
		for (var iC=0;iC<len;iC++)
		{
			strByCat[G.unitCategories[iC].id]='';
		}
		var len=G.unitsOwned.length;
		for (var i=0;i<len;i++)
		{
			var str='';
			var me=G.unitsOwned[i];
			str+='<div class="thingWrapper">';
			str+='<div class="unit thing'+G.getIconClasses(me.unit,true)+'" id="unit-'+me.id+'">'+
				G.getIconStr(me.unit,'unit-icon-'+me.id,0,true)+
				G.getArbitrarySmallIcon([0,0],false,'unit-modeIcon-'+me.id)+
				'<div class="overlay" id="unit-over-'+me.id+'"></div>'+
				'<div class="amount" id="unit-amount-'+me.id+'"></div>'+
			'</div>';
			if (me.unit.gizmos)
			{
				str+='<div class="gizmos">'+
					'<div class="gizmo gizmo1" id="unit-mode-'+me.id+'"></div>'+
					'<div class="gizmo gizmo2'+(me.splitOf?' off':'')+'" id="unit-split-'+me.id+'"></div>'+
					'<div class="gizmo gizmo3" id="unit-percent-'+me.id+'"><div class="percentGizmo" id="unit-percentDisplay-'+me.id+'"></div></div>'+
				'</div>';
			}
			str+='</div>';
			strByCat[me.unit.category]+=str;
		}
		
		var str='';
		var len=G.unitCategories.length;
		for (var iC=0;iC<len;iC++)
		{
			if (strByCat[G.unitCategories[iC].id]!='')
			{
				if (G.unitCategories[iC].id=='wonder') str+='<br>';
				str+='<div class="category" style="display:inline-block;"><div class="categoryName barred fancyText" id="unit-catName-'+iC+'">'+G.unitCategories[iC].name+'</div>'+strByCat[G.unitCategories[iC].id]+'</div>';
			}
		}
		l('unitBox').innerHTML=str;
		
		G.addCallbacks();
		
		
		G.addTooltip(l('buyAmount'),function(){return '<div style="width:320px;"><div class="barred">Buy amount</div><div class="par">This is how many units you\'ll queue or unqueue at once in a single click.</div><div class="par">Click the + and - buttons to increase or decrease the amount. You can ctrl-click either button to instantly make the amount negative or positive.</div><div class="par">You can also ctrl-click a unit to unqueue an amount instead of queueing it, or shift-click to queue 50 times more.</div></div>';},{offY:-8});
		
		G.updateBuyAmount();
		var len=G.unitsOwned.length;
		for (var i=0;i<len;i++)
		{
			var me=G.unitsOwned[i];
			var div=l('unit-'+me.id);if (div) me.l=div; else me.l=0;
			var div=l('unit-icon-'+me.id);if (div) me.lIcon=div; else me.lIcon=0;
			var div=l('unit-over-'+me.id);if (div) me.lOver=div; else me.lOver=0;
			var div=l('unit-amount-'+me.id);if (div) me.lAmount=div; else me.lAmount=0;
			var div=l('unit-modeIcon-'+me.id);if (div) me.lMode=div; else me.lMode=0;
			if (me.lMode && me.mode.icon) {G.setIcon(me.lMode,me.mode.icon);me.lMode.style.display='block';}
			else if (me.lMode) me.lMode.style.display='none';
			if (me.unit.gizmos)
			{
				var div=l('unit-mode-'+me.id);div.onmousedown=function(unit,div){return function(){G.selectModeForUnit(unit,div);};}(me,div);
				G.addTooltip(div,function(me,instance){return function(){return 'Click and drag to change unit mode.<br>Current mode :<div class="info"><div class="fancyText barred infoTitle">'+(instance.mode.icon?G.getSmallThing(instance.mode):'')+''+instance.mode.name+'</div>'+G.parse(instance.mode.desc)+'</div>';};}(me.unit,me),{offY:-8});
				var div=l('unit-split-'+me.id);div.onclick=function(unit,div){return function(){if (G.speed>0) G.splitUnit(unit,div); else G.cantWhenPaused();};}(me,div);
				G.addTooltip(div,function(me,instance){return function(){if (instance.splitOf) return 'Click to remove this stack of units.'; else return 'Click to split into another unit stack.<br>Different unit stacks can use different modes.'};}(me.unit,me),{offY:-8-16});
				var div=l('unit-percent-'+me.id);div.onmousedown=function(unit,div){return function(){if (G.speed>0) G.selectPercentForUnit(unit,div); else G.cantWhenPaused();};}(me,div);
				G.addTooltip(div,function(me,instance){return function(){return 'Click and drag to set unit work capacity.<br>This feature is not yet implemented.'};}(me.unit,me),{offY:8,anchor:'bottom'});
			}
			G.addTooltip(me.l,function(me,instance){return function(){
				var amount=G.getBuyAmount(instance);
				if (me.wonder) amount=(amount>0?1:-1);
				if (me.wonder)
				{
					var str='<div class="info">';
					str+='<div class="infoIcon"><div class="thing standalone'+G.getIconClasses(me,true)+'">'+G.getIconStr(me,0,0,true)+'</div></div>';
					str+='<div class="fancyText barred infoTitle">'+me.displayName+'</div>';
					str+='<div class="fancyText barred" style="color:#c3f;">Wonder</div>';
					if (amount<0) str+='<div class="fancyText barred">You cannot destroy wonders</div>';
					else
					{
						if (instance.mode==0) str+='<div class="fancyText barred">Unbuilt<br>Click to start construction ('+B(me.steps)+' steps)</div>';
						else if (instance.mode==1) str+='<div class="fancyText barred">Being constructed - Step : '+B(instance.percent)+'/'+B(me.steps)+'<br>Click to pause construction</div>';
						else if (instance.mode==2) str+='<div class="fancyText barred">'+(instance.percent==0?('Construction paused<br>Click to begin construction'):('Construction paused - Step : '+B(instance.percent)+'/'+B(me.steps)+'<br>Click to resume'))+'</div>';
						else if (instance.mode==3) str+='<div class="fancyText barred">Requires final step<br>Click to perform</div>';
						else if (instance.mode==4) str+='<div class="fancyText barred">Completed<br>Click to ascend</div>';
						//else if (amount<=0) str+='<div class="fancyText barred">Click to destroy</div>';
					}
					if (amount<0) amount=0;
					
					if (instance.mode!=4)
					{
						str+='<div class="fancyText barred">';
							if (instance.mode==0 && amount>0)
							{
								if (!isEmpty(me.cost)) str+='<div>Initial cost : '+G.getCostString(me.cost,true,false,amount)+'</div>';
								if (!isEmpty(me.use)) str+='<div>Uses : '+G.getUseString(me.use,true,false,amount)+'</div>';
								if (!isEmpty(me.require)) str+='<div>Prerequisites : '+G.getUseString(me.require,true,false,amount)+'</div>';
							}
							else if ((instance.mode==1 || instance.mode==2) && !isEmpty(me.costPerStep)) str+='<div>Cost per step : '+G.getCostString(me.costPerStep,true,false,amount)+'</div>';
							else if (instance.mode==3 && !isEmpty(me.finalStepCost)) str+='<div>Final step cost : '+G.getCostString(me.finalStepCost,true,false,amount)+'</div>';
						str+='</div>';
					}
					
					if (me.desc) str+='<div class="infoDesc">'+G.parse(me.desc)+'</div>';
					str+='</div>';
					str+=G.debugInfo(me);
					return str;
				}
				else
				{
					if (amount<0) amount=Math.max(-instance.targetAmount,amount);
					/*if (G.getSetting('buyAny'))
					{
						var n=0;
						n=G.testAnyCost(me.cost);
						if (n!=-1) amount=Math.min(n,amount);
						n=G.testAnyUse(me.use,amount);
						if (n!=-1) amount=Math.min(n,amount);
						n=G.testAnyUse(me.require,amount);
						if (n!=-1) amount=Math.min(n,amount);
						n=G.testAnyUse(instance.mode.use,amount);
						if (n!=-1) amount=Math.min(n,amount);
						n=G.testAnyLimit(me.limitPer,G.getUnitAmount(me.name)+amount);
						if (n!=-1) amount=Math.min(n,amount);
					}*/
					var str='<div class="info">';
					//infoIconCompensated ?
					str+='<div class="infoIcon"><div class="thing standalone'+G.getIconClasses(me,true)+'">'+G.getIconStr(me,0,0,true)+'</div>'+
					'<div class="fancyText infoAmount onLeft">'+B(instance.displayedAmount)+'</div>'+
					'<div class="fancyText infoAmount onRight" style="font-size:12px;">'+(instance.targetAmount!=instance.amount?('queued :<br>'+B(instance.targetAmount-instance.displayedAmount)):'')+(instance.amount>0?('<br>active :<br>'+B(instance.amount-instance.idle)+'/'+B(instance.amount)):'')+'</div>'+
					'</div>';
					str+='<div class="fancyText barred infoTitle">'+me.displayName+'</div>';
					str+='<div class="fancyText barred">Click to '+(amount>=0?'queue':'unqueue')+' '+B(Math.abs(amount))+'</div>';
					if (me.modesById[0]) {str+='<div class="fancyText barred">Current mode :<br><b>'+(instance.mode.icon?G.getSmallThing(instance.mode):'')+''+instance.mode.name+'</b></div>';}
					str+='<div class="fancyText barred">';
						if (!isEmpty(me.cost)) str+='<div>Cost : '+G.getCostString(me.cost,true,false,amount)+'</div>';
						if (!isEmpty(me.use) || !isEmpty(me.staff)) str+='<div>Uses : '+G.getUseString(addObjects(me.use,me.staff),true,false,amount)+'</div>';
						if (!isEmpty(me.require)) str+='<div>Prerequisites : '+G.getUseString(me.require,true,false,amount)+'</div>';//should amount count?
						if (!isEmpty(me.upkeep)) str+='<div>Upkeep : '+G.getCostString(me.upkeep,true,false,amount)+'</div>';
						if (!isEmpty(me.limitPer)) str+='<div>Limit : '+G.getLimitString(me.limitPer,true,false,G.getUnitAmount(me.name)+amount)+'</div>';
						if (isEmpty(me.cost) && isEmpty(me.use) && isEmpty(me.staff) && isEmpty(me.upkeep) && isEmpty(me.require)) str+='<div>Free</div>';
						if (me.modesById[0] && !isEmpty(instance.mode.use)) str+='<div>Current mode uses : '+G.getUseString(instance.mode.use,true,false,amount)+'</div>';
					str+='</div>';
					if (me.desc) str+='<div class="infoDesc">'+G.parse(me.desc)+'</div>';
					str+='</div>';
					str+=G.debugInfo(me);
					return str;
				}
			};}(me.unit,me),{offY:-8});
			if (me.l) me.l.onclick=function(unit){return function(e){
				if (G.speed>0)
				{
					var amount=G.getBuyAmount(unit);
					if (unit.unit.wonder) amount=(amount>0?1:-1);
					if (amount<0) G.taskKillUnit(unit,-amount);
					else if (amount>0) G.taskBuyUnit(unit,amount,(G.getSetting('buyAny')));
				} else G.cantWhenPaused();
			};}(me);
			if (me.l) me.l.oncontextmenu=function(unit){return function(e){
				e.preventDefault();
				if (G.speed>0)
				{
					var amount=-G.getBuyAmount(unit);
					if (unit.unit.wonder) amount=(amount>0?1:-1);
					if (amount<0) G.taskKillUnit(unit,-amount);
					//else if (amount>0) G.buyUnit(unit,amount);
				} else G.cantWhenPaused();
			};}(me);
		}
		G.draw['unit']();
		//G.cacheUnitBounds();
	}
	G.draw['unit']=function()
	{
		if (G.tab.id=='unit')
		{
			var len=G.unitsOwned.length;
			for (var i=0;i<len;i++)
			{
				var me=G.unitsOwned[i];
				if (me.lIcon && me.unit.getIcon) G.setIcon(me.lIcon,me.unit.getIcon(me));
				if (me.l)
				{
					if ((!me.unit.wonder && me.amount==0) || (me.unit.wonder && (me.mode==0 || me.mode==2))) me.l.classList.add('zero');
					else me.l.classList.remove('zero');
				}
				if (me.lAmount)
				{
					if (me.unit.wonder)
					{
						if (me.mode==0) me.lAmount.innerHTML='Unbuilt';
						else if (me.mode==3) me.lAmount.innerHTML='Ready';
						else if (me.mode==4) me.lAmount.innerHTML='Complete';
						else me.lAmount.innerHTML=Math.round((me.percent/me.unit.steps)*100)+'%';
					}
					else
					{
						var str=B(Math.round(me.displayedAmount));
						if (me.idle) str='<span style="opacity:0.8;">'+B(Math.round(me.amount-me.idle))+'</span>/'+str;
						if (me.targetAmount-me.displayedAmount!=0) str=str+'<br><span style="opacity:0.8;">'+B(Math.round(me.targetAmount-me.displayedAmount))+'</span>';
						me.lAmount.innerHTML=str;
					}
				}
				//me.displayedAmount+=(me.amount-me.displayedAmount)*0.25;
				me.displayedAmount=me.amount;
				if (G.drawT%3==0)
				{
					var popupsLen=me.popups.length;
					if (popupsLen>0)
					{
						//work through the queue of icon popups and pop one at random
						var bounds=me.l.getBoundingClientRect();
						var posX=bounds.left+bounds.width/2;
						var posY=bounds.top;
						
						var popupIndex=Math.floor(Math.random()*popupsLen);
						G.showParticle({x:posX,y:posY,icon:me.popups.splice(popupIndex,1)[0]});
						if (popupsLen>10) me.popups=[];
						if (G.tooltip.parent!=me.l && G.getSetting('animations')) triggerAnim(me.l,'plop');
					}
				}
			}
		}
	}
	G.cacheUnitBounds=function()
	{
		//turns out to not work very well
		/*
		var len=G.unitsOwned.length;
		for (var i=0;i<len;i++)
		{
			var me=G.unitsOwned[i];
			me.bounds=me.l.getBoundingClientRect();
			console.log(me.bounds);
		}
		*/
	}
	
	G.runUnitReqs=function()
	{
		//unlock units
		//executed on gaining a new tech or trait
		var len=G.unit.length;
		for (var i=0;i<len;i++)
		{
			var me=G.unit[i];
			if (!G.unitsOwnedNames.includes(me.name) && ((me.req && G.checkReq(me.req)) || (me.category=='debug' && G.getSetting('debug')))) G.unlockUnit(me.name);
			else if (G.unitsOwnedNames.includes(me.name) && me.req && !G.checkReq(me.req)) G.lockUnit(me.name);
			//else if (!me.req) G.unlockUnit(me.name);
		}
	}
	G.unlockUnit=function(name)
	{
		if (!G.unitsOwnedNames.includes(name))
		{
			var unit=G.getUnit(name);
			G.unitsOwned.unshift({id:G.unitN,unit:unit,amount:0,targetAmount:0,displayedAmount:0,idle:0,mode:unit.modesById[0]||0,percent:100,popups:[]});
			G.unitsOwnedNames.unshift(unit.name);
			G.unitN++;
		}
	}
	G.lockUnit=function(name)
	{
		if (!G.unitsOwnedNames.includes(name))
		{
			var unit=G.getUnit(name);
			var toRemove=[];
			for (var i in G.unitsOwned)
			{
				var me=G.unitsOwned[i];
				if (me.unit==unit) toRemove.push(me);
			}
			for (var i in toRemove)
			{
				G.removeUnit(toRemove);
			}
		}
	}
	G.canBuyUnit=function(me,amount)
	{
		var success=true;
		if (!G.testCost(me.unit.cost,amount)) success=false;
		else if (!G.testUse(me.unit.use,amount)) success=false;
		else if (!G.testUse(me.unit.require,amount)) success=false;//should amount count?
		//else if (!G.testUse(me.mode.use,amount)) success=false;
		else if (!G.testLimit(me.unit.limitPer,G.getUnitAmount(me.unit.name)+amount)) success=false;
		return success;
	}
	G.canBuyUnitByName=function(name,amount)
	{
		var out=false;
		var unit=G.getUnitByName(name);
		if (unit) out=G.canBuyUnit(unit,amount);
		return out;
	}
	G.getUnitAmount=function(name)
	{
		//get how many of a unit we have
		var amount=0;
		var len=G.unitsOwned.length;
		for (var i=0;i<len;i++)
		{
			if (G.unitsOwned[i].unit.name==name) amount+=G.unitsOwned[i].amount;
		}
		return amount;
	}
	G.getUnitByName=function(name)
	{
		//returns one of the unit stacks with this name
		var amount=0;
		var len=G.unitsOwned.length;
		var units=[];
		for (var i=0;i<len;i++)
		{
			if (G.unitsOwned[i].unit.name==name) units.push(G.unitsOwned[i]);
		}
		if (units.length>0) return choose(units);
		return false;
	}
	G.buyUnitByName=function(name,amount,any)
	{
		var out=false;
		var unit=G.getUnitByName(name);
		if (unit) out=G.taskBuyUnit(unit,amount,any);
		return out;
	}
	G.killUnitByName=function(name,amount,any)
	{
		var out=false;
		var unit=G.getUnitByName(name);
		if (unit) out=G.killUnit(unit,amount,any);
		return out;
	}
	G.taskBuyUnit=function(me,amount,any)
	{
		if (amount<=0) return false;
		if (me.unit.wonder) G.buyUnit(me,amount,any);
		else me.targetAmount+=amount;
	}
	G.taskKillUnit=function(me,amount)
	{
		if (me.unit.wonder) {}
		else
		{
			//G.killUnit(me,amount);
			me.targetAmount-=amount;
			me.targetAmount=Math.max(0,me.targetAmount);
		}
	}
	G.buyUnit=function(me,amount,any)
	{
		//if any is true, by anywhere between 0 and amount; otherwise, fail if we can't buy the precise amount
		var success=true;
		amount=Math.round(amount);
		if (me.unit.wonder && amount>0)
		{
			//check requirements
			if (me.mode==0)
			{
				//initial step
				if (!G.testCost(me.unit.cost,amount)) success=false;
				else if (!G.testUse(me.unit.use,amount)) success=false;
				else if (!G.testUse(me.unit.require,amount)) success=false;
				if (success)
				{
					if (me.unit.messageOnStart) G.Message({type:'important',text:me.unit.messageOnStart});
					G.doCost(me.unit.cost,amount);
					G.doUse(me.unit.use,amount);
					G.applyUnitBuyEffects(me,amount);
					me.mode=2;//start paused
					me.percent=0;
					if (G.getSetting('animations')) triggerAnim(me.l,'plop');
					
					var bounds=me.l.getBoundingClientRect();
					var posX=bounds.left+bounds.width/2;
					var posY=bounds.top;
					for (var i in me.unit.cost)
					{G.showParticle({x:posX,y:posY,icon:G.dict[i].icon});}
				}
			}
			else if (me.mode==1)
			{
				//building in progress; pausing construction
				if (success)
				{
					me.mode=2;
					if (G.getSetting('animations')) triggerAnim(me.l,'plop');
				}
			}
			else if (me.mode==2)
			{
				//building in progress; resuming construction
				if (success)
				{
					me.mode=1;
					if (G.getSetting('animations')) triggerAnim(me.l,'plop');
				}
			}
			else if (me.mode==3 || me.mode==4)
			{
				//building complete; applying final step
				//this also handles the step afterwards, when we click the final wonder
				G.dialogue.popup(function(me,instance){return function(div){
					var str=
					'<div style="width:280px;min-height:320px;">'+
					'<div class="thing standalone'+G.getIconClasses(me,true)+''+(instance.mode==3?' wonderUnbuilt':' wonderBuilt')+'" style="transform:scale(2);position:absolute;left:70px;top:52px;">'+G.getIconStr(me,0,0,true)+'</div>'+
					'<div class="fancyText title">'+me.displayName+'</div><div class="bitBiggerText scrollBox underTitle shadowed" style="text-align:center;overflow:hidden;top:118px;bottom:50px;">';
					if (instance.mode==3)
					{
						str+='<div class="fancyText par">This wonder only needs one more step to finalize.</div>';
						if (me.finalStepDesc) str+='<div class="fancyText par">'+G.parse(me.finalStepDesc)+'</div>';
						str+='</div><div class="buttonBox">'+
						G.button({text:'Complete',tooltipFunc:function(me){return function(){return '<div style="max-width:240px;padding:16px 24px;">You need '+G.getCostString(me.finalStepCost,true,false,1)+'.</div>';}}(me),onclick:function(me){return function(){
							var amount=1;
							var success=true;
							if (!G.testCost(me.unit.finalStepCost,amount)) success=false;
							//else if (!G.testUse(me.unit.finalStepUse,amount)) success=false;
							//else if (!G.testUse(me.unit.finalStepRequire,amount)) success=false;
							if (success)
							{
								G.dialogue.close();
								G.doCost(me.unit.finalStepCost,amount);
								
								me.mode=4;
								me.amount+=1;
								if (G.getSetting('animations')) triggerAnim(me.l,'plop');
								
								var bounds=me.l.getBoundingClientRect();
								var posX=bounds.left+bounds.width/2;
								var posY=bounds.top;
								for (var i in me.unit.finalStepCost)
								{G.showParticle({x:posX,y:posY,icon:G.dict[i].icon});}
								G.buyUnit(me,amount,true);//show dialogue for step 4
							}
						}}(instance)})+'<br>'+
						G.dialogue.getCloseButton('Back')+
						'</div>';
					}
					else
					{
						str+='<div class="fancyText par">Wonder complete.</div>';
						str+='<div class="fancyText par">You may now ascend to a higher state of existence, or remain on this mortal plane for as long as you choose.</div>';
						str+='</div><div class="buttonBox">'+
						G.button({text:'Ascend',style:'box-shadow:0px 0px 10px 1px #39f;',tooltipFunc:function(me){return function(){return '<div style="max-width:240px;padding:16px 24px;"><div class="par">Ascending will end this game and let you create a new one.</div><div class="par">You will unlock permanent legacy bonuses for completion of this wonder.</div><div class="par">You may choose to do this later; click this wonder again to ascend at any time.</div><div class="par">Only do this when you\'re certain you\'re done with this world!</div></div>';}}(me),onclick:function(me){return function(){
							//ascend
							G.dialogue.close();
							var middleText='';
							var achiev=G.getAchiev(me.unit.wonder);
							if (achiev)
							{
								if (!achiev.won) middleText='- Completed the '+achiev.displayName+' victory -';
								achiev.won++;
							}
							G.resets++;
							G.NewGameWithSameMods();
							G.middleText(middleText,true);
						}}(instance)})+'<br>'+
						G.dialogue.getCloseButton('Back')+
						'</div>';
					}
					str+='</div>';
					return str;
				}}(me.unit,me));
			}
		}
		else if (amount>0)
		{
			//check requirements
			if (any)
			{
				var originalAmount=amount;
				var n=0;
				n=G.testAnyCost(me.unit.cost);
				if (n!=-1) amount=Math.min(n,amount);
				n=G.testAnyUse(me.unit.use,amount);
				if (n!=-1) amount=Math.min(n,amount);
				n=G.testAnyUse(me.unit.require,amount);
				if (n!=-1) amount=Math.min(n,amount);
				//n=G.testAnyUse(me.mode.use,amount);
				//if (n!=-1) amount=Math.min(n,amount);
				n=G.testAnyLimit(me.unit.limitPer,G.getUnitAmount(me.unit.name)+amount);
				if (n!=-1) amount=Math.min(n,amount);
				if (amount<=0) success=false;
			}
			else
			{
				if (!G.testCost(me.unit.cost,amount)) success=false;
				else if (!G.testUse(me.unit.use,amount)) success=false;
				else if (!G.testUse(me.unit.require,amount)) success=false;//should amount count?
				//else if (!G.testUse(me.mode.use,amount)) success=false;
				else if (!G.testLimit(me.unit.limitPer,G.getUnitAmount(me.unit.name)+amount)) success=false;
			}
			//actually purchase if we meet the requirements
			if (success)
			{
				G.doCost(me.unit.cost,amount);
				G.doUse(me.unit.use,amount);
				//G.doUse(me.mode.use,amount);
				G.applyUnitBuyEffects(me,amount);
				me.amount+=amount;
				me.idle+=amount;
				if (G.tooltip.parent!=me.l && G.getSetting('animations')) triggerAnim(me.l,'plop');
				
				var bounds=me.l.getBoundingClientRect();
				var posX=bounds.left+bounds.width/2;
				var posY=bounds.top;
				for (var i in me.unit.cost)
				{G.showParticle({x:posX,y:posY,icon:G.dict[i].icon});}
			}
		}
		return success;
	}
	G.killUnit=function(me,amount)
	{
		amount=Math.round(amount);
		if (me.unit.wonder)
		{
			//can't destroy wonders yet
			/*
			if (me.mode>0)
			{
				me.mode=0;
				me.percent=0;
				
				//amount=Math.min(amount,me.amount);
				if (amount>0)
				{
					G.applyUnitBuyEffects(me,-amount);
					G.undoUse(me.unit.use,amount);
					if (me.amount>0) me.amount-=amount;
				}
				if (G.getSetting('animations')) triggerAnim(me.l,'plop');
			}
			*/
		}
		else
		{
			amount=Math.min(amount,me.amount);
			if (amount>0)
			{
				var unidle=me.amount-me.idle;
				G.applyUnitBuyEffects(me,-amount);
				G.undoUse(me.unit.use,amount);
				me.amount-=amount;
				if (unidle>me.amount)
				{
					G.idleUnit(me,unidle-me.amount);
					//me.idle-=unidle-me.amount;
				}
				me.idle-=amount;
				me.idle=Math.max(0,Math.min(me.amount,me.idle));
				if (G.tooltip.parent!=me.l && G.getSetting('animations')) triggerAnim(me.l,'plop');
			}
		}
	}
	G.wasteUnit=function(me,amount)//for when we have more units than we can support
	{
		G.killUnit(me,amount);
	}
	
	G.idleUnit=function(me,amount)//make some of the unit idle
	{
		amount=Math.ceil(amount);
		if (amount>0)
		{
			me.idle=me.idle+amount;
			me.idle=Math.min(me.amount,me.idle);
			G.applyUnitUnidleEffects(me,-amount);
			G.undoUse(me.unit.staff,amount);
			G.undoUse(me.mode.use,amount);
		}
	}
	G.unidleUnit=function(me,amount)//make some of the unit active again
	{
		amount=Math.ceil(Math.max(0,Math.min(me.idle,amount)));
		if (amount>0)
		{
			var success=true;
			var newAmount=me.amount-(me.idle-amount);
			for (var ii in me.unit.upkeep)
			{
				var res=G.getRes(ii);
				var upkeep=me.unit.upkeep[ii]*newAmount;
				if (upkeep>G.getRes(ii).amount && (!me.unit.alternateUpkeep || !me.unit.alternateUpkeep[ii] || me.unit.upkeep[ii]*newAmount>G.getRes(me.unit.alternateUpkeep[ii]).amount)) success=false;
			}
			for (var ii in me.unit.staff)
			{
				var res=G.getRes(ii);
				var use=me.unit.staff[ii];
				if (res.amount<res.used+use) success=false;
			}
			for (var ii in me.mode.use)
			{
				var res=G.getRes(ii);
				var use=me.mode.use[ii];
				if (res.amount<res.used+use) success=false;
			}
			if (success)
			{
				me.idle=me.idle-amount;
				G.applyUnitUnidleEffects(me,amount);
				G.doUse(me.unit.staff,amount);
				G.doUse(me.mode.use,amount);
			}
		}
	}
	
	G.getBuyAmount=function(me)
	{
		//returns a number for how many of a unit instance we would buy or sell by clicking it
		//affected by ctrl and shift keys, and (if "me" is specified) how much of the unit we already have (at 1000, we start buying 10 by 10, then 100 by 100 at 10,000, etc)
		var amount=1;
		amount=G.getSetting('buyAmount');
		if (G.keys[17]) amount*=-1;//ctrl : lose
		if (G.keys[16]) amount*=50;//shift : bulk
		return amount;
	}
	G.updateBuyAmount=function()
	{
		if (l('buyAmount'))
		{
			var str='';
			if (G.getSetting('buyAmount')>0) str='Add '+B(G.getSetting('buyAmount'));
			else str='Remove '+B(-G.getSetting('buyAmount'));
			l('buyAmount').innerHTML=str;
		}
	}
	
	G.setUnitMode=function(me,mode)
	{
		//free old mode uses, and assign new mode uses
		var oldMode=me.mode;
		var newMode=mode;
		if (oldMode==newMode) return;
		G.undoUse(oldMode.use,me.amount-me.idle);
		//G.doUse(newMode.use,me.amount);
		me.idle=me.amount;
		me.mode=mode;
		if (me.lMode && me.mode.icon) {G.setIcon(me.lMode,me.mode.icon);me.lMode.style.display='block';}
		else if (me.lMode) me.lMode.style.display='none';
		if (G.getSetting('animations')) triggerAnim(me.l,'plop');
	}
	
	G.applyUnitEffects=function(me,mult){G.fullApplyUnitEffects(me,0,mult);}
	G.applyUnitBuyEffects=function(me,newAmount){G.fullApplyUnitEffects(me,1,newAmount);}
	G.applyUnitUnidleEffects=function(me,newAmount){G.fullApplyUnitEffects(me,3,newAmount);}
	G.applyUnitAmountEffects=function(me){return G.fullApplyUnitEffects(me,2);}
	G.fullApplyUnitEffects=function(me,type,amountParam)
	{
		//run through every effect in a unit and apply them
		//"type" lets us run specific effects only : 0 means all effects that happen every tick, 1 means all effects that happen on unit purchase (or sale, or death, if the amount is negative), 2 means all effects that affect the effective unit amount, 3 means all effects that happen when unit is made unidle (or idle, if the amount is negative)
		//"amountParam" depends on the type : if type is 0, it represents the effective unit amount; if type is 1, it is the new amount of the unit we just purchased; if type is 3, it is the amount that was just made unidle
		
		var len=me.unit.effects.length;
		var visible=false;
		if (me.l && G.tab.id=='unit') visible=true;
		var out=0;//return value; only used by type 2 effects
		if (type==2) out=me.amount-me.idle;
		
		for (var i=0;i<len;i++)
		{
			var effect=me.unit.effects[i];
			if (!effect.req || G.checkReq(effect.req))
			{
				if ((!effect.mode || me.mode.id==effect.mode) && (!effect.notMode || me.mode.id!=effect.notMode))
				{
					if (type==0)//effects that happen every tick
					{
						if (!effect.every || G.tick%effect.every==0)//.every : effect only triggers every X days
						{
							var repeat=1;
							if (effect.repeat) repeat=effect.repeat;//.repeat : effect triggers X times every day
							for (var repI=0;repI<repeat;repI++)
							{
								var myAmount=amountParam;
								if (effect.type=='gather')//gather : extract either specific resources, or anything from a context, or both, using the available resources in owned tiles
								//if .max is specified, each single unit can only gather that amount at most, forcing the player to create enough units to match the resources available in owned tiles
								//by default, units try to gather a random amount between 50% and 100% of the specified amount; add .exact=true to get the precise amount instead
								//the amount gathered is soft-capped by the natural resource
								{
									var resWeight=0.95;
									var unitWeight=1-resWeight;
									var res=[];
									var specific=false;
									if (effect.what)//gathering something in particular
									{res=effect.what;specific=true;}
									else//harvest by context only
									{res=G.currentMap.computedPlayerRes[effect.context];}
									for (var ii in res)
									{
										var amount=0;
										if (specific)
										{
											var toGather=myAmount*res[ii];
											var resAmount=toGather;//if no context is defined, ignore terrain goods - just harvest from thin air
											if (effect.context && G.currentMap.computedPlayerRes[effect.context]) resAmount=G.currentMap.computedPlayerRes[effect.context][ii]||0;
											var max=effect.max||0;
										}
										else
										{
											var toGather=myAmount*(effect.amount||1);
											var resAmount=res[ii];
											var max=effect.max||0;
										}
										
										amount=Math.min(resAmount,toGather)*resWeight+unitWeight*(toGather);
										if (!effect.exact) amount*=(0.5+0.5*Math.random());
										if (max) amount=Math.min(max*myAmount,amount);
										amount=randomFloor(amount);
										
										if (amount>0)
										{
											if (G.getRes(ii).whenGathered) G.getRes(ii).whenGathered(G.getRes(ii),amount,me,effect);
											else G.gain(ii,amount,me.unit.displayName);
											if (visible) me.popups.push(G.dict[ii].icon);
										}
									}
								}
								else if (effect.type=='convert')//convert : convert resources into other resources as long as we have enough materials
								{
									if (!effect.chance || Math.random()<effect.chance)
									{
										//establish how many we can make from the current resources
										//i hope i didn't mess up somewhere in there
										var amountToMake=myAmount;
										for (var ii in effect.from)
										{
											amountToMake=Math.min(amountToMake,G.getRes(ii).amount/(effect.from[ii]*myAmount));
										}
										
										amountToMake=randomFloor(Math.min(1,amountToMake)*myAmount);
										
										if (amountToMake>0)
										{
											for (var ii in effect.from)
											{
												G.lose(ii,effect.from[ii]*amountToMake,me.unit.displayName);
											}
											for (var ii in effect.into)
											{
												if (G.getRes(ii).whenGathered) G.getRes(ii).whenGathered(G.getRes(ii),effect.into[ii]*amountToMake,me,effect);
												else G.gain(ii,effect.into[ii]*amountToMake,me.unit.displayName);
												if (visible && effect.into[ii]*amountToMake>0) me.popups.push(G.dict[ii].icon);
											}
										}
									}
								}
								else if (effect.type=='waste')//waste : a random percent of the unit dies off every tick
								{
									var toDie=randomFloor(effect.chance*me.amount);
									if (toDie>0)
									{
										if (effect.desired) me.targetAmount-=toDie;
										G.wasteUnit(me,toDie);
									}
								}
								else if (effect.type=='explore')//explore : discover new tiles or explore owned tiles
								{
									if (effect.explored) G.exploreOwnedTiles+=Math.random()*effect.explored*myAmount;
									if (effect.unexplored) G.exploreNewTiles+=Math.random()*effect.unexplored*myAmount;
								}
								else if (effect.type=='function')//function : any arbitrary function (or list of functions)
								{
									if (!effect.chance || Math.random()<effect.chance)
									{
										if (effect.funcs)
										{
											for (var ii in effect.funcs)
											{effect.funcs[ii](me);}
										}
										else effect.func(me);
									}
								}
							}
						}
					}
					else if (type==1)//effects that happen when the unit is bought or killed
					{
					}
					else if (type==3)//effects that happen when the unit is made unidle or idle
					{
						if (effect.type=='provide')//provide : when the unit is bought, give a flat amount of a resource; remove that same amount when the unit is deleted
						{
							if (effect.what)
							{
								for (var ii in effect.what)
								{
									var amount=effect.what[ii]*amountParam;
									if (amountParam>0 || !effect.noTakeBack)
									{
										if (G.getRes(ii).whenGathered) G.getRes(ii).whenGathered(G.getRes(ii),amount,me,effect);
										else G.gain(ii,amount,me.unit.displayName);
										if (visible && amount>0) me.popups.push(G.dict[ii].icon);
									}
								}
							}
						}
					}
					else if (type==2)//effects that modify the effective unit amount
					{
						if (effect.what)
						{
							if (effect.type=='add')//add the amount of these resources to the amount
							{
								for (var ii in effect.what)
								{
									var res=G.getRes(ii);
									out+=res.amount*effect.what[ii];
								}
							}
							else if (effect.type=='addFree')//add the free portion of these resources to the amount
							{
								for (var ii in effect.what)
								{
									var res=G.getRes(ii);
									out+=Math.max(0,res.amount-res.used)*effect.what[ii];
								}
							}
							else if (effect.type=='mult')//multiply the amount by the amount of these resources
							{
								for (var ii in effect.what)
								{
									var res=G.getRes(ii);
									out+=res.amount*effect.what[ii];
								}
							}
							else if (effect.type=='multFree')//multiply the amount by the free portion of these resources
							{
								for (var ii in effect.what)
								{
									var res=G.getRes(ii);
									out*=Math.max(0,res.amount-res.used)*effect.what[ii];
								}
							}
						}
						else//flat values
						{
							if (effect.type=='add')//add the value to the amount
							{
								out+=effect.value;
							}
							else if (effect.type=='mult')//multiply the amount by the value
							{
								out*=effect.value;
							}
						}
					}
				}
			}
		}
		return out;
	}
	
	G.removeUnit=function(me)
	{
		var splitOf=me.splitOf;
		G.killUnit(me,me.amount);
		var index=G.unitsOwned.indexOf(me);
		G.unitsOwned.splice(index,1);
		G.unitsOwnedNames.splice(index,1);
		G.update['unit']();
		if (splitOf && G.getSetting('animations')) triggerAnim(splitOf.l,'plop');
	}
	G.splitUnit=function(me,div)
	{
		if (me.splitOf) G.removeUnit(me);//if this is already a split, delete instead
		else
		{
			var index=G.unitsOwned.indexOf(me);
			G.unitsOwned.splice(index+1,0,{id:G.unitN,unit:me.unit,amount:0,targetAmount:0,displayedAmount:0,idle:0,mode:me.unit.modesById[0]||0,percent:100,splitOf:me,popups:[]});
			G.unitsOwnedNames.splice(index+1,0,me.unit.name);
			G.unitN++;
			G.update['unit']();
			G.popupSquares.spawn(me.l,G.unitsOwned[index+1].l);
			G.unitsOwned[index+1].l.classList.add('popIn');
		}
	}
	G.selectModeForUnit=function(me,div)
	{
		if (div==G.widget.parent) G.widget.close();
		else
		{
			G.widget.popup({
				func:function(widget)
				{
					var str='';
					var me=widget.linked;
					for (var i in me.unit.modes)
					{
						var mode=me.unit.modes[i];
						if (!mode.req || G.checkReq(mode.req))
						//{str+='<div class="button'+(mode.num==me.mode.num?' on':'')+'" id="mode-button-'+mode.num+'">'+mode.name+'</div>';}
						{str+='<div class="button'+(mode.num==me.mode.num?' on':'')+'" id="mode-button-'+mode.num+'">'+(mode.icon?G.getSmallThing(mode):'')+''+mode.name+'</div>';}
					}
					widget.l.innerHTML=str;
					for (var i in me.unit.modes)
					{
						var mode=me.unit.modes[i];
						if (!mode.req || G.checkReq(mode.req))
						{
							l('mode-button-'+mode.num).onmouseup=function(unit,mode,div){return function(){
								//released the mouse on this mode button; test if we can switch to this mode, then close the widget
								if (G.speed>0)
								{
									if (true)//G.testUse(G.subtractCost(unit.mode.use,mode.use),unit.amount))
									{
										//remove "on" class from all mode buttons and add it to the current mode button
										for (var i in unit.unit.modes)
										{if (l('mode-button-'+unit.unit.modes[i].num)) {l('mode-button-'+unit.unit.modes[i].num).classList.remove('on');}}
										l('mode-button-'+mode.num).classList.add('on');
										G.setUnitMode(unit,mode);
										if (unit.l) G.popupSquares.spawn(l('mode-button-'+mode.num),unit.l);
									}
								} else G.cantWhenPaused();
								widget.closeOnMouseUp=false;//override default behavior
								widget.close(5);//schedule to close the widget in 5 frames
							};}(me,mode,div);
							
							if (true)/*G.testUse(G.subtractCost(me.mode.use,mode.use),me.amount))*/ addHover(l('mode-button-'+mode.num),'hover');//fake mouseover because :hover doesn't trigger when mouse is down
							G.addTooltip(l('mode-button-'+mode.num),function(me,unit){return function(){
								//var uses=G.subtractCost(unit.mode.use,me.use);
								var str='<div class="info"><div class="fancyText barred infoTitle">'+(me.icon?G.getSmallThing(me):'')+''+me.name+'</div>'+G.parse(me.desc);
								if (!isEmpty(me.use)) str+='<div class="divider"></div><div class="fancyText par">Uses : '+G.getUseString(me.use,true,true)+' per '+unit.unit.displayName+'</div>';
								//if (unit.amount>0 && unit.mode.num!=me.num && !isEmpty(uses)) str+='<div class="divider"></div><div class="fancyText par">Needs '+G.getUseString(uses,true,false,unit.amount)+' to switch</div>';
								if (unit.amount>0 && unit.mode.num!=me.num) str+='<div class="divider"></div><div class="fancyText par">Switching will reset all of this stack\'s units to idle</div>';
								str+='</div>';
								return str;
							};}(mode,me),{offY:-8});
						}
					}
				},
				offX:0,
				offY:-8,
				anchor:'top',
				parent:div,
				linked:me,
				closeOnMouseUp:true
			});
		}
	}
	G.selectPercentForUnit=function(me,div)
	{
		if (div==G.widget.parent) G.widget.close();
		else
		{
			G.widget.popup({
				func:function(widget)
				{
					var str='(this will be a percent slider)';//TODO
					widget.l.innerHTML=str;
				},
				offX:0,
				offY:8,
				anchor:'bottom',
				parent:div,
				linked:me,
				closeOnMouseUp:true
			});
		}
	}
	
	/*=====================================================================================
	ACHIEVEMENTS AND LEGACY
		When the player completes a wonder, they may click it to ascend; this takes them to the new game screen.
		Ascending with a wonder unlocks that wonder's achievement and its associated effects, which can be anything from adding free fast ticks at the start of every game to unlocking new special units available in every playthrough.
		There are other achievements, not necessarily linked to wonders. Some achievements are used to track generic things across playthroughs, such as tutorial tips.
	=======================================================================================*/
	G.achiev=[];
	G.achievByName=[];
	G.achievByTier=[];
	G.getAchiev=function(name){if (!G.achievByName[name]) ERROR('No achievement exists with the name '+name+'.'); else return G.achievByName[name];}
	G.achievN=0;//incrementer
	G.legacyBonuses=[];
	G.Achiev=function(obj)
	{
		this.type='achiev';
		this.effects=[];//applied on new game start
		this.tier=0;//where the achievement is located vertically on the legacy screen
		this.won=0;//how many times we've achieved this achievement (may also be used to track other info about the achievement)
		this.visible=true;
		this.icon=[0,0];
		
		for (var i in obj) this[i]=obj[i];
		this.id=G.achiev.length;
		if (!this.displayName) this.displayName=cap(this.name);
		
		G.achiev.push(this);
		G.achievByName[this.name]=this;
		if (!G.achievByTier[this.tier]) G.achievByTier[this.tier]=[];
		G.achievByTier[this.tier].push(this);
		//G.setDict(this.name,this);
		this.mod=G.context;
		if (!this.mod.achievs) this.mod.achievs=[];
		this.mod.achievs.push(this);
	}
	
	G.applyAchievEffects=function(context)
	{
		//this is done on creating or loading a game
		for (var i in G.achiev)
		{
			var me=G.achiev[i];
			if (me.won)
			{
				for (var ii in me.effects)
				{
					var effect=me.effects[ii];
					var type=effect.type;
					if (G.legacyBonuses[type])
					{
						var bonus=G.legacyBonuses[type];
						if (bonus.func && (!bonus.context || bonus.context==context))
						{
							bonus.func(effect);
						}
					}
				}
			}
		}
	}
	G.getAchievEffectsString=function(effects)
	{
		//returns a string that describes the effects of a achievement
		var str='';
		for (var i in effects)
		{
			var effect=effects[i];
			var type=effect.type;
			if (G.legacyBonuses[type])
			{
				var bonus=G.legacyBonuses[type];
				str+='<div class="bulleted" style="text-align:left;"><b>'+bonus.name.replaceAll('\\[X\\]',B(effect.amount))+'</b><div style="font-size:90%;">'+bonus.desc+'</div></div>';
			}
		}
		return str;
	}
	
	
	G.tabPopup['legacy']=function()
	{
		var str='';
		str+='<div class="fancyText title">Legacy</div>';
		str+='<div class="scrollBox underTitle" style="width:248px;left:0px;">';
		str+='<div class="fancyText barred bitBiggerText" style="text-align:center;">Stats</div>';
		str+='<div class="par">Behold, the fruits of your legacy! Below are stats about your current and past games.</div>';
		str+='<div class="par">Legacy started : <b>'+G.selfUpdatingText(function(){return BT((Date.now()-G.fullDate)/1000);})+' ago</b></div>';
		str+='<div class="par">This game started : <b>'+G.selfUpdatingText(function(){return BT((Date.now()-G.startDate)/1000);})+' ago</b></div>';
		str+='<div class="par">'+G.doFunc('tracked stat str','Tracked stat')+' : <b>'+G.selfUpdatingText(function(){return B(G.trackedStat);})+'</b></div>';
		str+='<div class="par">Longest game : <b>'+G.selfUpdatingText(function(){return G.BT(G.furthestDay);})+'</b></div>';
		str+='<div class="par">Total legacy time : <b>'+G.selfUpdatingText(function(){return G.BT(G.totalDays);})+'</b></div>';
		str+='<div class="par">Ascensions : <b>'+G.selfUpdatingText(function(){return B(G.resets);})+'</b></div>';
		str+='</div>';
		str+='<div class="scrollBox underTitle" style="width:380px;right:0px;left:auto;background:rgba(0,0,0,0.25);">';
		if (G.sequence=='main')
		{
			str+='<div class="fancyText barred bitBiggerText" style="text-align:center;">Achievements</div>';
			for (var i in G.achievByTier)
			{
				str+='<div class="tier thingBox">';
				for (var ii in G.achievByTier[i])
				{
					var me=G.achievByTier[i][ii];
					str+='<div class="thingWrapper">'+
						'<div class="achiev thing'+G.getIconClasses(me)+''+(me.won?'':' off')+'" id="achiev-'+me.id+'">'+
						G.getIconStr(me,'achiev-icon-'+me.id)+
						'<div class="overlay" id="achiev-over-'+me.id+'"></div>'+
						'</div>'+
					'</div>';
				}
				str+='<div class="divider"></div>';
				str+='</div>';
			}
			
			G.arbitraryCallback(function(){
				for (var i in G.achievByTier)
				{
					for (var ii in G.achievByTier[i])
					{
						var me=G.achievByTier[i][ii];
						var div=l('achiev-'+me.id);
						div.onclick=function(me,div){return function(){
							if (G.getSetting('debug'))
							{
								if (me.won) me.won=0; else me.won=1;
								if (me.won) div.classList.remove('off');
								else div.classList.add('off');
							}
						}}(me,div);
						G.addTooltip(div,function(me){return function(){
							return '<div class="info">'+
							'<div class="infoIcon"><div class="thing standalone'+G.getIconClasses(me,true)+'">'+G.getIconStr(me,0,0,true)+'</div></div>'+
							'<div class="fancyText barred infoTitle">'+me.displayName+'</div>'+
							'<div class="fancyText barred">'+(me.won>0?('Achieved : '+me.won+' '+(me.won==1?'time':'times')):'Locked')+'</div>'+
							'<div class="fancyText barred">Effects :'+G.getAchievEffectsString(me.effects)+'</div>'+
							(me.desc?('<div class="infoDesc">'+G.parse(me.desc)+'</div>'):'')+
							'</div>'+
							G.debugInfo(me)
						};}(me),{offY:8});
					}
				}
			});
		}
		str+='</div>';
		str+='<div class="buttonBox">'+
		G.dialogue.getCloseButton()+
		'</div>';
		return str;
	}
	
	/*=====================================================================================
	WORLD MAPS & TILES
		Games take place across several maps; the player and other civs start on an earthly world map, but technology may take them to space and other planets.
		A map has a type, width and height. Maps are composed of [width*height] tiles.
		Tiles in maps are recreated from scratch based on the seed every time the game is loaded.
		Each tile remembers its owner, exploration level and effects, however.
		Goods on each tile (.goods) are recomputed on each game load and do not take the tile's effects or exploration level into account.
		Each map stores its computed resources for the player by harvesting context (ie. ["hunt">{"meat":3,"bone":1}] and so on). These are recalculated every few seconds, or whenever a new tile is obtained.
		Note : tiles are stored columns-first simply because tile[x][y] feels more natural to write
	=======================================================================================*/
	G.maps=[];
	G.Map=function(type,w,h,seed)
	{
		//create a new unpopulated map with specified type, width and height, with an optional seed
		this.type=type;//type : 0=main, 1=space, 2=moon, 3=other planet
		this.w=w;
		this.h=h;
		this.computedPlayerRes=[];
		this.tilesByOwner=[];//lists of tiles indexed by civs owning them ([0]=unexplored)
		this.territoryByOwner=[];//total amount of explored owned tile percents across all tiles owned by a given civ
		this.seed=seed||makeSeed(5);
		
		var time=Date.now();
		
		if (!G.land[0]) throw 'Whoah there! You can\'t generate a map if you don\'t even have one terrain type to default to!';
		
		Math.seedrandom(this.seed);
		this.tiles=[];
		for (var x=0;x<w;x++)
		{
			this.tiles[x]=[];
			for (var y=0;y<h;y++)
			{
				var land=G.land[0];
				var tile={owner:0,land:land,goods:[],explored:0,effects:[],x:x,y:y,map:this};
				this.tiles[x][y]=tile;
			}
		}
		
		var lvl=G.doFuncWithArgs('create map',[w,h]);
		
		for (var x=0;x<w;x++)
		{
			for (var y=0;y<h;y++)
			{
				this.tiles[x][y].land=G.getLand(lvl[x][y]);
				this.tiles[x][y].goods=G.getRandomLandGoods(this.tiles[x][y].land);
			}
		}
		
		//console.log('generating map took '+(Date.now()-time)+'ms');
		
		G.maps.push(this);
		Math.seedrandom();
	}
	
	G.computeTilesByOwner=function(map,owner)
	{
		//stores a list of tiles owned by the specified owner into map.tilesByOwner[owner]
		var tiles=[];
		var tilePercents=0;
		for (var x=0;x<map.w;x++)
		{
			for (var y=0;y<map.h;y++)
			{
				if (map.tiles[x][y].owner==owner)
				{
					tiles.push(map.tiles[x][y]);
					if (!map.tiles[x][y].land.ocean) tilePercents+=map.tiles[x][y].explored;//TODO : generalize this
				}
			}
		}
		map.tilesByOwner[owner]=tiles;
		map.territoryByOwner[owner]=tilePercents;
	}
	G.updateMapForOwners=function(map)
	{
		//cache owned tiles and resources for every civ on the map
		for (var i=0;i<2;i++)
		{
			G.computeTilesByOwner(map,i);
			G.computeOwnedRes(map,i);
		}
	}
	
	G.revealMap=function(map)
	{
		//mark all tiles as explored
		for (var x=0;x<map.w;x++)
		{
			for (var y=0;y<map.h;y++)
			{
				map.tiles[x][y].owner=1;
				map.tiles[x][y].explored=1;
			}
		}
		G.updateMapForOwners(map);
		G.updateMapDisplay();
	}
	
	G.createMaps=function()//when creating a new game
	{
		G.currentMap=new G.Map(0,24,24);//main world map
		
		//set starting tile by ranking all land tiles by score and picking one
		var goodTiles=[];
		for (var x=1;x<G.currentMap.w-1;x++)
		{
			for (var y=1;y<G.currentMap.h-1;y++)
			{
				var land=G.currentMap.tiles[x][y].land;
				if (!land.ocean) goodTiles.push([x,y,(land.score||0)+Math.random()*2]);
			}
		}
		goodTiles.sort(function(a,b){return b[2]-a[2]});
		var tile=0;
		if (G.startingType==2) tile=choose(goodTiles);//just drop me wherever
		else
		{
			var ind=0;
			if (G.startingType==1) ind=Math.floor((0.85+Math.random()*0.15)*goodTiles.length);//15% worst
			//ind=Math.floor((0.3+Math.random()*0.4)*goodTiles.length);//30% to 70% average
			else ind=Math.floor((Math.random()*0.15)*goodTiles.length);//15% nicest
			tile=goodTiles[ind];
		}
		tile=G.currentMap.tiles[tile[0]][tile[1]];
		tile.owner=1;
		tile.explored=10/100;//create one tile, a tenth of it explored
		
		G.updateMapForOwners(G.currentMap);
		
		G.updateMapDisplay();
		G.centerMap(G.currentMap);
	}
	G.centerMap=function(map)
	{
		//center the map on the average of explored tiles
		var ts=16;
		var x1=0,y1=0,x2=map.w,y2=map.h;
		for (var x=0;x<map.w;x++)
		{
			for (var y=0;y<map.h;y++)
			{
				if (map.tiles[x][y].explored>0) {x1=Math.max(x,x1);y1=Math.max(y,y1);x2=Math.min(x,x2);y2=Math.min(y,y2);}
			}
		}
		var px=Math.floor((x2+x1)/2)+0.5;
		var py=Math.floor((y2+y1)/2)+0.5;
		G.mapOffXT=-(px*G.mapZoomT)*ts;
		G.mapOffYT=-(py*G.mapZoomT)*ts;
	}
	G.mapToRedraw=false;
	G.redrawMap=function(map)
	{
		G.mapToRedraw=false;
		var ts=16;
		var c=G.renderMap(map);
		var ctx=l('mapCanvas').getContext('2d');
		ctx.clearRect(0,0,map.w*ts,map.h*ts);
		ctx.drawImage(c,0,0);
	}
	G.mapToRefresh=false;
	G.refreshMap=function(map)
	{
		G.mapToRefresh=false;
		G.computeOwnedRes(map,1);
	}
	
	G.getRandomTile=function(map)
	{
		return map.tiles[Math.floor(Math.random()*map.w)][Math.floor(Math.random()*map.h)];
	}
	
	G.getRandomLandGoods=function(land)
	{
		var goods=[];
		for (var i in land.goods)
		{
			var me=land.goods[i];
			var chance=1;if (typeof me.chance!=='undefined') chance=me.chance;
			var min=1;var max=1;
			if (typeof me.amount!=='undefined') min=me.amount;max=min;
			if (typeof me.min!=='undefined') min=me.min;
			if (typeof me.max!=='undefined') max=me.max;
			if (Math.random()<chance)
			{
				var type='';if (Array.isArray(me.type)) type=choose(me.type); else type=me.type;
				if (!goods[type]) goods[type]=0;
				goods[type]+=Math.random()*(max-min)+min;
			}
		}
		return goods;
	}
	
	G.getResFromGoods=function(goods)//turn a list of goods into their associated resources
	{
		var res=[];
		for (var i in goods)
		{
			var me=G.getGoods(i);
			var mult=goods[i]*(me.mult||1);
			for (var ii in me.res)
			{
				for (var iii in me.res[ii])
				{
					if (!res[ii]) res[ii]=[];
					if (!res[ii][iii]) res[ii][iii]=0;
					res[ii][iii]+=me.res[ii][iii]*mult;
				}
			}
		}
		return res;
	}
	
	G.getLandIconBG=function(land)
	{
		return 'url(img/terrain.png),url(img/terrain.png)';
	}
	G.getLandIconBGpos=function(land)
	{
		return (-32*land.image-2)+'px '+(-2*32-2)+'px,'+(-32*land.image-2)+'px '+(-0*32-2)+'px';
	}
	G.initMap=function()
	{
		G.mapVisible=0;
		G.mapW=16;
		G.mapH=16;
		G.mapOffX=0;
		G.mapOffY=0;
		G.mapOffXT=0;
		G.mapOffYT=0;
		G.mapZoom=0.01;
		G.mapZoomT=2;
		G.mouseDragFromX=0;
		G.mouseDragFromY=0;
		G.mouseDragFrom=0;
		G.mapIsDisplayingTooltip=false;
		G.mapSelectingTileX=-1;
		G.mapSelectingTileY=-1;
		G.mapEditWithLand=0;
		G.editMode=0;
		G.inspectingTile=0;
		G.tilesToRender=[];
		
		var div=l('tileEditButton');
		if (div && G.land[G.mapEditWithLand])
		{
			div.style.background=G.getLandIconBG(G.land[G.mapEditWithLand]);
			div.style.backgroundPosition=G.getLandIconBGpos(G.land[G.mapEditWithLand]);
		}
	}
	G.showMap=function()
	{
		G.mapVisible=true;
		l('mapSection').style.display='block';
	}
	G.hideMap=function()
	{
		G.mapVisible=false;
		l('mapSection').style.display='none';
	}
	G.buildMapDisplay=function()
	{
		var str='';
		str+='<div id="mapHeader" class="fancyText framed bgLight">World Map'+
		'<div class="ifDebug">'+
		'<div class="divider"></div>'+
		'<div class="framed" style="display:none;cursor:pointer;width:32px;height:32px;position:absolute;left:0px;bottom:0px;" id="tileEditButton"></div>'+
		//'<div class="image" style="width:9px;height:9px;background:url(img/miscButtonIcons.png) 0px -1px;"></div>'
		G.writeSettingButton({id:'editMode1',name:'mapEditMode',text:'<div class="image" style="width:10px;height:9px;background:url(img/miscButtonIcons.png) -18px -1px;"></div>',tooltip:'<div class="barred">View mode</div>Clicking a map tile will simply display its info.',value:0,siblings:['editMode1','editMode2','editMode3']})+
		G.writeSettingButton({id:'editMode2',name:'mapEditMode',text:'<div class="image" style="width:10px;height:9px;background:url(img/miscButtonIcons.png) -39px -1px;"></div>',tooltip:'<div class="barred">Explore mode</div>Clicking a map tile will toggle its exploration level.<br>Note : hold ctrl to edit without scrolling.',value:1,siblings:['editMode1','editMode2','editMode3']})+
		G.writeSettingButton({id:'editMode3',name:'mapEditMode',text:'<div class="image" style="width:10px;height:9px;background:url(img/miscButtonIcons.png) -28px -1px;"></div>',tooltip:'<div class="barred">Edit mode</div>Clicking a map tile will edit its terrain.<br>Tile changes will not be saved.<br>This is mostly for testing and fun for the time being.<br>Note : hold ctrl to edit without scrolling.',value:2,siblings:['editMode1','editMode2','editMode3']})+
		'</div>'+
		'</div>';
		str+='<div class="framed map noAlias" id="cornerMap"><div id="mapOverlay"></div><div id="tileFocus" class="framed simple"></div><div id="mapContainer"></div></div>';
		
		l('mapSection').innerHTML=str;
		
		
		//land edit widget
		var div=l('tileEditButton');
		G.addTooltip(div,function(){
			var str='Click and drag to select a terrain type<br>to place when in edit mode.';
			if (G.land[G.mapEditWithLand]) str+='<div class="divider"></div>Current terrain :<br><b>'+G.land[G.mapEditWithLand].displayName+'</b>';
			return str;},{offY:-8});

		div.onmousedown=function(div){return function(){
			if (div==G.widget.parent) G.widget.close();
			else
			{
				G.widget.popup({
					func:function(widget)
					{
						var str='';
						str+='<div style="width:208px;"><div class="barred fancyText">Tile edit tool</div><div class="thingBox">';
						var I=0;
						var len=G.land.length;
						for (var i=0;i<len;i++)
						{
							var land=G.land[i];
							str+='<div id="tileEditLand-'+I+'" class="framed simple'+(G.mapEditWithLand==I?' on':'')+'" style="cursor:pointer;display:inline-block;width:32px;height:32px;background:'+G.getLandIconBG(land)+';background-position:'+G.getLandIconBGpos(land)+';"></div>';
							I++;
						}
						str+='</div></div>';
						widget.l.innerHTML=str;
						
						var I=0;
						var len=G.land.length;
						for (var i=0;i<len;i++)
						{
							var land=G.land[i];
							l('tileEditLand-'+I).onmouseup=function(land){return function(){
								G.mapEditWithLand=land;
								var button=l('tileEditButton');
								button.style.background=G.getLandIconBG(G.land[G.mapEditWithLand]);
								button.style.backgroundPosition=G.getLandIconBGpos(G.land[G.mapEditWithLand]);
								if (G.getSetting('animations')) triggerAnim(button,'plop');
								var I=0;
								var len=G.land.length;
								for (var i=0;i<len;i++)
								{
									var me=G.land[i];
									if (G.mapEditWithLand==me.id) l('tileEditLand-'+I).classList.add('on');
									else l('tileEditLand-'+I).classList.remove('on');
									I++;
								}
								widget.closeOnMouseUp=false;//override default behavior
								widget.close(5);//schedule to close the widget in 5 frames
							};}(land.id);
							G.addTooltip(l('tileEditLand-'+I),function(land){return function(){return land.displayName;};}(land));
							I++;
						}
					},
					offX:-8,
					offY:0,
					anchor:choose(['left']),
					parent:div,
					closeOnMouseUp:true
				});
			}
		};}(div);
	}
	G.updateMapDisplay=function()
	{
		//call whenever we switch maps
		var str='';
		var ts=16;//tile size
		var map=G.currentMap;
		
		str+='<div id="mapSurface" style="width:'+(map.w*ts+G.mapW)+'px;height:'+(map.h*ts+G.mapH)+'px;left:'+(-G.mapW/2)+'px;top:'+(-G.mapH/2)+'px;"></div><div id="tileSelector" style="width:'+(ts)+'px;height:'+(ts)+'px;"></div>';
		l('mapContainer').innerHTML=str;
		var c=G.renderMap(G.currentMap);
		c.id='mapCanvas';
		l('mapContainer').appendChild(c);
	}
	G.resizeMapDisplay=function()
	{
		//var w=Math.max(128,G.w*0.2);
		var w=Math.max(128,l('sections').offsetWidth*0.4);
		var h=l('mapSection').offsetHeight-10;
		if (l('mapHeader')) h-=l('mapHeader').offsetHeight;
		w=Math.floor(Math.max(16,w));
		h=Math.floor(Math.max(16,h));
		l('cornerMap').style.width=(w)+'px';
		l('cornerMap').style.height=(h)+'px';
		
		if (l('landBox')) l('landBox').style.marginRight=(w+4)+'px';
		l('mapBreakdown').style.marginRight=(w+4+21)+'px';
		
		G.mapW=w;
		G.mapH=h;
		
		if (G.currentMap)
		{
			var ts=16;//tile size
			var map=G.currentMap;
			l('mapSurface').style.left=(-G.mapW/2)+'px';
			l('mapSurface').style.top=(-G.mapH/2)+'px';
			l('mapSurface').style.width=(map.w*ts+G.mapW)+'px';
			l('mapSurface').style.height=(map.h*ts+G.mapH)+'px';
		}
	}
	G.logicMapDisplay=function()
	{
		var editMode=G.editMode;
		if (!G.getSetting('debug')) editMode=0;
		
		//move the map around with the mouse
		if (G.mapVisible)
		{
			var mapl=l('mapContainer');
			var cornerMap=l('cornerMap');
			var mapSurface=l('mapSurface');
			var displayW=G.mapW;
			var displayH=G.mapH;
			var bounds=mapSurface.getBoundingClientRect();
			var bounds2=l('mapOverlay').getBoundingClientRect();
			var mouseOnMap=(G.mouseX>=bounds2.left && G.mouseX<bounds2.right && G.mouseY>=bounds2.top && G.mouseY<bounds2.bottom);

			
			var ts=16;//tile size
			var map=G.currentMap;
			
			if (G.mouseDragFrom==mapSurface && !G.keys[17])//drag (not when ctrl is pressed)
			{
				G.mapOffXT+=G.mouseX-G.mouseDragFromX;
				G.mapOffYT+=G.mouseY-G.mouseDragFromY;
				G.mouseDragFromX=G.mouseX;
				G.mouseDragFromY=G.mouseY;
			}
			
			var x1=0;
			var x2=-map.w*ts*G.mapZoomT;
			var y1=0;
			var y2=-map.h*ts*G.mapZoomT;
			if (G.mapOffXT>x1) G.mapOffXT=x1;
			if (G.mapOffXT<x2) G.mapOffXT=x2;
			if (G.mapOffYT>y1) G.mapOffYT=y1;
			if (G.mapOffYT<y2) G.mapOffYT=y2;
			
			if (mouseOnMap && G.Scroll>0 && G.mapZoomT==1)
			{
				G.mapZoomT=2;
				G.mapOffXT*=2;
				G.mapOffYT*=2;
				G.tooltip.close();
			}
			else if (mouseOnMap && G.Scroll<0 && G.mapZoomT==2)
			{
				G.mapZoomT=1;
				G.mapOffXT/=2;
				G.mapOffYT/=2;
				G.tooltip.close();
			}
			
			var smooth=0.75;
			G.mapOffX+=(G.mapOffXT-G.mapOffX)*smooth;
			G.mapOffY+=(G.mapOffYT-G.mapOffY)*smooth;
			G.mapZoom+=(G.mapZoomT-G.mapZoom)*smooth;
			mapl.style.left=(displayW/2+G.mapOffX)+'px';
			mapl.style.top=(displayH/2+G.mapOffY)+'px';
			mapl.style.transform='scale('+G.mapZoom+')';
			cornerMap.style.backgroundPosition=(displayW/2+G.mapOffX*0.8)+'px '+(displayH/2+G.mapOffY*0.8)+'px';
			cornerMap.style.backgroundSize=Math.floor(G.mapZoom*512)+'px '+Math.floor(G.mapZoom*512)+'px';
			
			//pick tile
			var tileSelector=l('tileSelector');
			var tileX=Math.floor(((G.mouseX-bounds.left)/G.mapZoom-displayW/2)/ts);
			var tileY=Math.floor(((G.mouseY-bounds.top)/G.mapZoom-displayH/2)/ts);
			var changedTile=false;
			if (G.mapSelectingTileX!=tileX || G.mapSelectingTileY!=tileY) changedTile=true;
			G.mapSelectingTileX=tileX;
			G.mapSelectingTileY=tileY;
			tileSelector.style.left=(tileX*ts)+'px';
			tileSelector.style.top=(tileY*ts)+'px';
			
			var tileFocus=l('tileFocus');
			if (G.inspectingTile)
			{
				tileFocus.style.left=(displayW/2+G.mapOffX+(G.inspectingTile.x*ts)*G.mapZoom)+'px';
				tileFocus.style.top=(displayH/2+G.mapOffY+(G.inspectingTile.y*ts)*G.mapZoom)+'px';
				tileFocus.style.width=(G.mapZoom*ts)+'px';
				tileFocus.style.height=(G.mapZoom*ts)+'px';
				tileFocus.style.display='block';
			}
			else tileFocus.style.display='none';
			
			var mouseInBounds=(tileX>=0 && tileX<map.w && tileY>=0 && tileY<map.h && mouseOnMap);
			
			if (editMode==0 && mouseInBounds && map.tiles[tileX][tileY].explored>0 && G.inspectingTile!=map.tiles[tileX][tileY] && ((G.mouseUp && G.draggedFrames<3) || (G.keys[17] && changedTile && G.mousePressed)) && l('landList'))
			{
				//click to display details about tile
				G.inspectingTile=map.tiles[tileX][tileY];
				G.inspectTile(G.inspectingTile);
				G.popupSquares.spawn(l('tileSelector'),l('land-0'));
			}
			
			
			//click to explore/unexplore a tile; ctrl-click to affect multiple tiles without scrolling the map
			if (editMode==1 && ((!G.keys[17] && G.draggedFrames<3 && G.clickL==mapSurface && mouseInBounds) || ((changedTile || G.mouseDown) && G.keys[17] && G.mousePressed && mouseInBounds)))
			{
				var tile=G.currentMap.tiles[tileX][tileY];
				if (G.keys[17] && G.mouseDown) G.mapEditWithLand=(tile.explored==0)?1:0;
				if (G.keys[17]) tile.explored=G.mapEditWithLand;
				else {if (tile.explored>0) tile.explored=0; else tile.explored=1;}
				tile.owner=1;
				G.tileToRender(tile);
				G.updateMapForOwners(G.currentMap);
				changedTile=true;
			}
			//click to set a tile; ctrl-click to draw multiple tiles without scrolling the map
			if (editMode==2 && ((!G.keys[17] && G.draggedFrames<3 && G.clickL==mapSurface && mouseInBounds) || ((changedTile || G.mouseDown) && G.keys[17] && G.mousePressed && mouseInBounds)))
			{
				var tile=G.currentMap.tiles[tileX][tileY];
				G.setTile(tileX,tileY,G.mapEditWithLand);
				G.tileToRender(tile);
				G.updateMapForOwners(G.currentMap);
				changedTile=true;
			}
			
			var tooltipToShow=0;
			if (mouseOnMap && changedTile)
			{
				if (mouseInBounds)
				{
					tooltipToShow='<div class="info">'+
					'<div class="fancyText barred infoTitle">Unexplored</div>'+
					'<div class="fancyText barred">Start exploring and you may encounter this tile and its secrets.</div>'+
					'</div>';
				}
				else
				{
					tooltipToShow='<div class="info">'+
					'<div class="fancyText barred infoTitle">The edge of the world</div>'+
					'<div class="fancyText barred">No sane soul would explore past this point.</div>'+
					'</div>';
				}
			}
			
			if (mouseInBounds && map.tiles[tileX][tileY].explored>0 && !G.Scroll)
			{
				//display tooltip
				if (changedTile)
				{
					var tile=map.tiles[tileX][tileY];
					var me=tile.land;
					//Math.seedrandom(tile.map.seed+'-name-'+tile.x+'/'+tile.y);
					var name=me.displayName;//choose(me.names);
					var str='<div class="info">';
					str+='<div class="fancyText barred infoTitle">'+name+'</div>';
					str+='<div class="fancyText barred">Explored : '+Math.floor(tile.explored*100)+'%</div>';
					if (editMode==0) str+='<div class="fancyText barred">Click to see details</div>';
					else if (editMode==1) str+='<div class="fancyText barred">Click to unexplore</div>';
					else if (editMode==2) str+='<div class="fancyText barred">Click to change terrain</div>';
					if (me.desc) str+='<div class="infoDesc">'+G.parse(me.desc)+'</div>';
					str+='</div>';
					//this should also iterate through tile modifiers and display their info too
					//Math.seedrandom();
					tooltipToShow=str;
				}
			}
			
			if (tooltipToShow)
			{
				G.tooltip.func=function(str){return function(){return str;}}(tooltipToShow);
				//G.tooltip.parent=tileSelector;
				//G.tooltip.popup({offY:-8});
				G.tooltip.parent=l('cornerMap');
				G.tooltip.popup({anchor:'left',offX:-6});
				G.mapIsDisplayingTooltip=true;
			}
			else if ((!mouseOnMap || changedTile) && G.mapIsDisplayingTooltip)
			{
				G.tooltip.close();
				G.mapIsDisplayingTooltip=false;
			}
		}
	}
	G.tileToRender=function(tile)
	{
		if (!G.tilesToRender.includes(tile)) G.tilesToRender.push(tile);
	}
	G.renderTiles=function()
	{
		if (G.tilesToRender.length<5)
		{
			for (var i in G.tilesToRender)
			{
				var tile=G.tilesToRender[i];
				G.renderTile(tile.map,tile.x,tile.y);
			}
		}
		else G.redrawMap(G.currentMap);
		G.tilesToRender=[];
	}
	G.renderMap=function(map,obj)
	{
		var time=Date.now();
		var timeStep=Date.now();
		var verbose=false;
		var breakdown=false;//visually break down map-drawing into steps, handy to understand what's happening
		var toDiv=l('mapBreakdown');
		if (breakdown) toDiv.style.display='block';
		
		if (verbose) {console.log('Now rendering map.');}
		
		Math.seedrandom(map.seed);
		
		var ts=16;//tile size
		
		var colorShift=true;
		var seaFoam=true;
		//var x1=5,y1=5,x2=x1+3,y2=y1+3;
		var x1=0,y1=0,x2=map.w,y2=map.h;
		if (obj)
		{
			if (obj.x1) x1=obj.x1;
			if (obj.x2) x2=obj.x2;
			if (obj.y1) y1=obj.y1;
			if (obj.y2) y2=obj.y2;
		}
		
		var totalw=map.w;//x2-x1;
		var totalh=map.h;//y2-y1;
		
		var img=Pic('img/terrain.png');
		var fog=Pic('img/blot.png');
		/*
			the format for terrain.png is (from top to bottom) :
				-colors - the map will pick 4 colors at random from this square to draw the tile
				-heightmap 1 - will be drawn on the tile in overlay mode; must be black and white, have values centered around pure gray, and have transparent edges
				-color detail 1 - colors will be drawn over the heightmap in hard-light mode; should also have transparent edges
				-heightmap 2 - a possible variation
				-color detail 2 - a possible variation
			furthermore, the leftmost 2 columns are reserved for land chunks (drawn together in lighten mode)
		*/
		
		//create fog map (draw all tiles with explored>0 as blots on a transparent background)
		var c=document.createElement('canvas');c.width=totalw*ts;c.height=totalh*ts;
		var ctx=c.getContext('2d');
		ctx.translate(ts/2,ts/2);
		for (var x=0;x<map.w;x++)
		{
			for (var y=0;y<map.h;y++)
			{
				if (x>=x1 && x<x2 && y>=y1 && y<y2)
				{
					var tile=map.tiles[x][y];
					if (tile.explored>0)
					{
						ctx.globalAlpha=tile.explored*0.9+0.1;
						Math.seedrandom(map.seed+'-fog-'+x+'/'+y);
						var s=1;
						//"pull" the center to other explored tiles
						var sx=0;var sy=0;var neighbors=0;
						if (x==0 || map.tiles[x-1][y].explored>0) {sx-=1;neighbors++;}
						if (x==map.w-1 || map.tiles[x+1][y].explored>0) {sx+=1;neighbors++;}
						if (y==0 || map.tiles[x][y-1].explored>0) {sy-=1;neighbors++;}
						if (y==map.h-1 || map.tiles[x][y+1].explored>0) {sy+=1;neighbors++;}
						s*=0.6+0.1*(neighbors);
						sx+=Math.random()*2-1;
						sy+=Math.random()*2-1;
						var pullAmount=2;
						
						var px=choose([0]);var py=choose([0]);
						var r=Math.random()*Math.PI*2;
						
						ctx.translate(sx*pullAmount,sy*pullAmount);
						ctx.scale(s,s);
						ctx.rotate(r);
						ctx.drawImage(fog,px*32+1,py*32+1,30,30,-ts,-ts,32,32);
						ctx.rotate(-r);
						ctx.scale(1/s,1/s);
						ctx.translate(-sx*pullAmount,-sy*pullAmount);
					}
				}
				ctx.translate(0,ts);
			}
			ctx.translate(ts,-map.h*ts);
		}
		ctx.globalAlpha=1;
		var imgFog=c;
		if (breakdown) toDiv.appendChild(c);
		if (verbose) {console.log('	FOG took 			'+(Date.now()-timeStep)+'ms');timeStep=Date.now();}
		
		var c=document.createElement('canvas');c.width=totalw*ts;c.height=totalh*ts;
		var ctx=c.getContext('2d');
		ctx.drawImage(imgFog,0,0);
		var oldc=c;
		
		var c=document.createElement('canvas');c.width=totalw*ts;c.height=totalh*ts;
		var ctx=c.getContext('2d');
		ctx.drawImage(oldc,0,0);
		ctx.drawImage(c,-1,0);
		ctx.drawImage(c,1,0);
		ctx.drawImage(c,0,-1);
		ctx.drawImage(c,0,1);
		ctx.globalCompositeOperation='destination-out';
		ctx.drawImage(oldc,0,0);
		ctx.drawImage(oldc,0,0);
		ctx.drawImage(oldc,0,0);
		ctx.drawImage(oldc,0,0);
		ctx.drawImage(oldc,0,0);
		ctx.globalCompositeOperation='source-in';
		ctx.beginPath();
		ctx.rect(0,0,map.w*ts,map.h*ts);
		ctx.fillStyle='rgb(200,150,100)';
		ctx.fill();
		oldc=0;
		var imgOutline=c;
		if (breakdown) toDiv.appendChild(c);
		if (verbose) {console.log('	OUTLINE took 		'+(Date.now()-timeStep)+'ms');timeStep=Date.now();}
		
		//create base heightmap by patching together random chunks of land (the transparency also makes this a mask for the coastline)
		var c=document.createElement('canvas');c.width=totalw*ts;c.height=totalh*ts;
		var ctx=c.getContext('2d');
		ctx.globalCompositeOperation='lighten';
		ctx.translate(ts/2,ts/2);
		for (var x=0;x<map.w;x++)
		{
			for (var y=0;y<map.h;y++)
			{
				if (x>=x1 && x<x2 && y>=y1 && y<y2)
				{
					var land=map.tiles[x][y].land;
					if (!land.ocean)
					{
						Math.seedrandom(map.seed+'-base-'+x+'/'+y);
						var s=1;
						//"pull" the center to other land tiles
						var sx=0;var sy=0;var neighbors=0;
						if (x==0 || !map.tiles[x-1][y].land.ocean) {sx-=1;neighbors++;}
						if (x==map.w-1 || !map.tiles[x+1][y].land.ocean) {sx+=1;neighbors++;}
						if (y==0 || !map.tiles[x][y-1].land.ocean) {sy-=1;neighbors++;}
						if (y==map.h-1 || !map.tiles[x][y+1].land.ocean) {sy+=1;neighbors++;}
						s*=0.6+0.1*(neighbors);
						if (neighbors==0) s*=0.65+Math.random()*0.35;//island
						sx+=Math.random()*2-1;
						sy+=Math.random()*2-1;
						var pullAmount=4;
						
						var px=choose([0,1]);var py=choose([0,1,2,3,4]);
						var r=Math.random()*Math.PI*2;
						
						ctx.translate(sx*pullAmount,sy*pullAmount);
						ctx.scale(s,s);
						ctx.rotate(r);
						ctx.drawImage(img,px*32+1,py*32+1,30,30,-ts,-ts,32,32);
						ctx.rotate(-r);
						ctx.scale(1/s,1/s);
						ctx.translate(-sx*pullAmount,-sy*pullAmount);
					}
				}
				ctx.translate(0,ts);
			}
			ctx.translate(ts,-map.h*ts);
		}
		var imgBase=c;
		if (breakdown) toDiv.appendChild(c);
		if (verbose) {console.log('	HEIGHTMAP took 		'+(Date.now()-timeStep)+'ms');timeStep=Date.now();}
		
		//create colors for sea and land
		var c=document.createElement('canvas');c.width=totalw*2;c.height=totalh*2;//sea
		var ctx=c.getContext('2d');
		for (var x=0;x<map.w;x++)
		{
			for (var y=0;y<map.h;y++)
			{
				if (x>=x1 && x<x2 && y>=y1 && y<y2)
				{
					var land=map.tiles[x][y].land;
					if (land.ocean)
					{
						Math.seedrandom(map.seed+'-seaColor-'+x+'/'+y);
						var px=land.image;var py=0;
						ctx.drawImage(img,px*32+Math.random()*30+1,py*32+Math.random()*30+1,1,1,x*2,y*2,1,1);
						ctx.drawImage(img,px*32+Math.random()*30+1,py*32+Math.random()*30+1,1,1,x*2+1,y*2,1,1);
						ctx.drawImage(img,px*32+Math.random()*30+1,py*32+Math.random()*30+1,1,1,x*2,y*2+1,1,1);
						ctx.drawImage(img,px*32+Math.random()*30+1,py*32+Math.random()*30+1,1,1,x*2+1,y*2+1,1,1);
					}
				}
			}
		}
		ctx.globalCompositeOperation='destination-over';//bleed
		ctx.drawImage(c,1,0);
		ctx.drawImage(c,-1,0);
		ctx.drawImage(c,0,-1);
		ctx.drawImage(c,0,1);
		ctx.globalCompositeOperation='source-over';//blur
		ctx.globalAlpha=0.25;
		ctx.drawImage(c,2,0);
		ctx.drawImage(c,-2,0);
		ctx.drawImage(c,0,-2);
		ctx.drawImage(c,0,2);
		var imgSea=c;
		if (breakdown) toDiv.appendChild(c);
		if (verbose) {console.log('	MICROCOLORS took 	'+(Date.now()-timeStep)+'ms');timeStep=Date.now();}
		
		var c=document.createElement('canvas');c.width=totalw*2;c.height=totalh*2;//land
		var ctx=c.getContext('2d');
		for (var x=0;x<map.w;x++)
		{
			for (var y=0;y<map.h;y++)
			{
				if (x>=x1 && x<x2 && y>=y1 && y<y2)
				{
					var land=map.tiles[x][y].land;
					if (!land.ocean)
					{
						Math.seedrandom(map.seed+'-landColor-'+x+'/'+y);
						var px=land.image;var py=0;
						ctx.drawImage(img,px*32+Math.random()*30+1,py*32+Math.random()*30+1,1,1,x*2,y*2,1,1);
						ctx.drawImage(img,px*32+Math.random()*30+1,py*32+Math.random()*30+1,1,1,x*2+1,y*2,1,1);
						ctx.drawImage(img,px*32+Math.random()*30+1,py*32+Math.random()*30+1,1,1,x*2,y*2+1,1,1);
						ctx.drawImage(img,px*32+Math.random()*30+1,py*32+Math.random()*30+1,1,1,x*2+1,y*2+1,1,1);
					}
				}
			}
		}
		ctx.globalCompositeOperation='destination-over';//bleed
		ctx.drawImage(c,1,0);
		ctx.drawImage(c,-1,0);
		ctx.drawImage(c,0,-1);
		ctx.drawImage(c,0,1);
		var imgLand=c;
		if (breakdown) toDiv.appendChild(c);
		if (verbose) {console.log('	LAND COLORS took 	'+(Date.now()-timeStep)+'ms');timeStep=Date.now();}
		
		
		//sea color
		var c=document.createElement('canvas');c.width=totalw*ts;c.height=totalh*ts;
		var ctx=c.getContext('2d');
		ctx.drawImage(imgSea,0,0,map.w*ts,map.h*ts);
		ctx.globalCompositeOperation='source-over';
		ctx.translate(ts/2,ts/2);
		for (var x=0;x<map.w;x++)
		{
			for (var y=0;y<map.h;y++)
			{
				if (x>=x1 && x<x2 && y>=y1 && y<y2)
				{
					var land=map.tiles[x][y].land;
					if (land.ocean)
					{
						Math.seedrandom(map.seed+'-detail-'+x+'/'+y);
						var px=land.image;var py=choose([2,4]);
						var r=Math.random()*Math.PI*2;
						var s=0.9+Math.random()*0.3;
						
						ctx.scale(s,s);
						ctx.rotate(r);
						ctx.drawImage(img,px*32+1,py*32+1,30,30,-ts,-ts,32,32);
						ctx.rotate(-r);
						ctx.scale(1/s,1/s);
					}
				}
				ctx.translate(0,ts);
			}
			ctx.translate(ts,-map.h*ts);
		}
		var imgSeaColor=c;
		if (breakdown) toDiv.appendChild(c);
		if (verbose) {console.log('	SEA COLORS took 	'+(Date.now()-timeStep)+'ms');timeStep=Date.now();}
		
		if (seaFoam)
		{
			var c=document.createElement('canvas');c.width=totalw*ts;c.height=totalh*ts;
			var ctx=c.getContext('2d');
			ctx.drawImage(imgBase,0,0);
			var size=4;
			ctx.globalAlpha=0.25;
			ctx.drawImage(c,-size,0);
			ctx.drawImage(c,size,0);
			ctx.drawImage(c,0,-size);
			ctx.drawImage(c,0,size);
			ctx.drawImage(c,-size,0);
			ctx.drawImage(c,size,0);
			ctx.drawImage(c,0,-size);
			ctx.drawImage(c,0,size);
			ctx.globalAlpha=1;
			ctx.globalCompositeOperation='destination-out';
			ctx.drawImage(imgBase,-1,0);
			ctx.drawImage(imgBase,1,0);
			ctx.drawImage(imgBase,0,-1);
			ctx.drawImage(imgBase,0,1);
			ctx.globalCompositeOperation='source-in';
			ctx.beginPath();
			ctx.rect(0,0,map.w*ts,map.h*ts);
			ctx.fillStyle='rgb(255,255,255)';
			ctx.fill();
			var imgEdges=c;
			if (breakdown) toDiv.appendChild(c);
			c=imgSeaColor;ctx=c.getContext('2d');
			ctx.setTransform(1,0,0,1,0,0);
			ctx.globalCompositeOperation='overlay';
			ctx.drawImage(imgEdges,0,0);
			ctx.drawImage(imgEdges,0,0);
			if (verbose) {console.log('	FOAM took 			'+(Date.now()-timeStep)+'ms');timeStep=Date.now();}
		}
		
		//draw land shadow on the sea
		c=imgSeaColor;ctx=c.getContext('2d');
		ctx.globalCompositeOperation='destination-out';
		ctx.globalAlpha=0.5;
		ctx.drawImage(imgBase,2,2);
		ctx.drawImage(imgBase,4,4);
		ctx.globalCompositeOperation='destination-over';
		ctx.globalAlpha=1;
		ctx.beginPath();
		ctx.rect(0,0,map.w*ts,map.h*ts);
		ctx.fillStyle='rgb(0,0,0)';
		ctx.fill();
		if (verbose) {console.log('	SEA SHADOW took 	'+(Date.now()-timeStep)+'ms');timeStep=Date.now();}
		
		//sea heightmap
		var c=document.createElement('canvas');c.width=totalw*ts;c.height=totalh*ts;
		var ctx=c.getContext('2d');
		//fill with dark base
		ctx.beginPath();
		ctx.rect(0,0,map.w*ts,map.h*ts);
		ctx.fillStyle='rgb(64,64,64)';
		ctx.fill();
		ctx.globalCompositeOperation='overlay';
		ctx.translate(ts/2,ts/2);
		for (var x=0;x<map.w;x++)
		{
			for (var y=0;y<map.h;y++)
			{
				if (x>=x1 && x<x2 && y>=y1 && y<y2)
				{
					var land=map.tiles[x][y].land;
					if (land.ocean)
					{
						Math.seedrandom(map.seed+'-detail-'+x+'/'+y);
						var px=land.image;var py=choose([1,3]);
						var r=Math.random()*Math.PI*2;
						var s=0.9+Math.random()*0.3;
						
						ctx.scale(s,s);
						ctx.rotate(r);
						ctx.drawImage(img,px*32+1,py*32+1,30,30,-ts,-ts,32,32);
						ctx.rotate(-r);
						ctx.scale(1/s,1/s);
					}
				}
				ctx.translate(0,ts);
			}
			ctx.translate(ts,-map.h*ts);
		}
		var imgSeaHeight=c;
		if (breakdown) toDiv.appendChild(c);
		if (verbose) {console.log('	SEA HEIGHTMAP took 	'+(Date.now()-timeStep)+'ms');timeStep=Date.now();}
		
		var c=document.createElement('canvas');c.width=totalw*ts;c.height=totalh*ts;
		var ctx=c.getContext('2d');
		ctx.drawImage(imgBase,0,0,map.w*ts,map.h*ts);//draw the coastline
		ctx.globalCompositeOperation='source-in';
		ctx.drawImage(imgLand,0,0,map.w*ts,map.h*ts);//draw land colors within the coastline
		ctx.globalCompositeOperation='destination-over';
		ctx.drawImage(imgSeaColor,0,0,map.w*ts,map.h*ts);//draw sea colors behind the coastline
		if (verbose) {console.log('	COMPOSITING took 	'+(Date.now()-timeStep)+'ms');timeStep=Date.now();}
		
		//add color details for each tile
		ctx.globalCompositeOperation='source-over';
		ctx.translate(ts/2,ts/2);
		for (var x=0;x<map.w;x++)
		{
			for (var y=0;y<map.h;y++)
			{
				if (x>=x1 && x<x2 && y>=y1 && y<y2)
				{
					var land=map.tiles[x][y].land;
					if (!land.ocean)
					{
						Math.seedrandom(map.seed+'-detail-'+x+'/'+y);
						var s=1;
						//"pull"
						var sx=0;var sy=0;var neighbors=0;
						if (x==0 || !map.tiles[x-1][y].land.ocean) {sx-=1;neighbors++;}
						if (x==map.w-1 || !map.tiles[x+1][y].land.ocean) {sx+=1;neighbors++;}
						if (y==0 || !map.tiles[x][y-1].land.ocean) {sy-=1;neighbors++;}
						if (y==map.h-1 || !map.tiles[x][y+1].land.ocean) {sy+=1;neighbors++;}
						s*=0.6+0.1*(neighbors);
						if (neighbors==0) s*=0.65+Math.random()*0.35;//island
						sx+=Math.random()*2-1;
						sy+=Math.random()*2-1;
						var pullAmount=4;
						
						var px=land.image;var py=choose([2,4]);
						var r=Math.random()*Math.PI*2;
						
						ctx.translate(sx*pullAmount,sy*pullAmount);
						ctx.scale(s,s);
						ctx.rotate(r);
						ctx.drawImage(img,px*32+1,py*32+1,30,30,-ts,-ts,32,32);
						ctx.rotate(-r);
						ctx.scale(1/s,1/s);
						ctx.translate(-sx*pullAmount,-sy*pullAmount);
					}
				}
				ctx.translate(0,ts);
			}
			ctx.translate(ts,-map.h*ts);
		}
		var imgColor=c;
		if (breakdown) toDiv.appendChild(c);
		if (verbose) {console.log('	COLOR DETAIL took 	'+(Date.now()-timeStep)+'ms');timeStep=Date.now();}
		
		//add heightmap details for each tile in overlay blending mode
		var c=document.createElement('canvas');c.width=totalw*ts;c.height=totalh*ts;
		var ctx=c.getContext('2d');
		//fill with dark base
		ctx.beginPath();
		ctx.rect(0,0,map.w*ts,map.h*ts);
		ctx.fillStyle='rgb(32,32,32)';
		ctx.fill();
		ctx.drawImage(imgSeaHeight,0,0,map.w*ts,map.h*ts);//draw the sea heightmap
		ctx.drawImage(imgBase,0,0,map.w*ts,map.h*ts);//draw the coastline
		ctx.globalCompositeOperation='overlay';
		ctx.translate(ts/2,ts/2);
		for (var x=0;x<map.w;x++)
		{
			for (var y=0;y<map.h;y++)
			{
				if (x>=x1 && x<x2 && y>=y1 && y<y2)
				{
					var land=map.tiles[x][y].land;
					if (!land.ocean)
					{
						Math.seedrandom(map.seed+'-detail-'+x+'/'+y);
						var s=1;
						//"pull"
						var sx=0;var sy=0;var neighbors=0;
						if (x==0 || !map.tiles[x-1][y].land.ocean) {sx-=1;neighbors++;}
						if (x==map.w-1 || !map.tiles[x+1][y].land.ocean) {sx+=1;neighbors++;}
						if (y==0 || !map.tiles[x][y-1].land.ocean) {sy-=1;neighbors++;}
						if (y==map.h-1 || !map.tiles[x][y+1].land.ocean) {sy+=1;neighbors++;}
						s*=0.6+0.1*(neighbors);
						if (neighbors==0) s*=0.65+Math.random()*0.35;//island
						sx+=Math.random()*2-1;
						sy+=Math.random()*2-1;
						var pullAmount=4;
						
						var px=land.image;var py=choose([1,3]);
						var r=Math.random()*Math.PI*2;
						
						ctx.translate(sx*pullAmount,sy*pullAmount);
						ctx.scale(s,s);
						ctx.rotate(r);
						ctx.drawImage(img,px*32+1,py*32+1,30,30,-ts,-ts,32,32);
						ctx.rotate(-r);
						ctx.scale(1/s,1/s);
						ctx.translate(-sx*pullAmount,-sy*pullAmount);
					}
				}
				ctx.translate(0,ts);
			}
			ctx.translate(ts,-map.h*ts);
		}
		var imgHeight=c;
		if (breakdown) toDiv.appendChild(c);
		if (verbose) {console.log('	HEIGHT DETAIL took 	'+(Date.now()-timeStep)+'ms');timeStep=Date.now();}
		
		//embossing
		var c=document.createElement('canvas');c.width=totalw*ts;c.height=totalh*ts;
		var ctx=c.getContext('2d');
		ctx.drawImage(imgHeight,1,1);
		ctx.beginPath();
		ctx.rect(0,0,map.w*ts,map.h*ts);
		ctx.fillStyle='rgb(255,255,255)';
		ctx.globalCompositeOperation='difference';
		ctx.fill();//invert
		ctx.globalCompositeOperation='source-over';
		ctx.globalAlpha=0.5;
		ctx.drawImage(imgHeight,0,0);//create emboss
		ctx.globalCompositeOperation='hard-light';
		ctx.globalAlpha=1;
		ctx.drawImage(c,0,0);
		//ctx.drawImage(c,0,0);
		var imgEmboss1=c;
		if (breakdown) toDiv.appendChild(c);
		
		var c=document.createElement('canvas');c.width=totalw*ts;c.height=totalh*ts;
		var ctx=c.getContext('2d');
		ctx.drawImage(imgHeight,1,1);
		ctx.beginPath();
		ctx.rect(0,0,map.w*ts,map.h*ts);
		ctx.fillStyle='rgb(255,255,255)';
		ctx.globalCompositeOperation='difference';
		ctx.fill();//invert
		ctx.globalCompositeOperation='source-over';
		ctx.globalAlpha=0.5;
		ctx.drawImage(imgHeight,-1,-1);//create emboss
		ctx.globalCompositeOperation='hard-light';
		ctx.globalAlpha=1;
		//ctx.drawImage(c,0,0);
		var imgEmboss2=c;
		if (breakdown) toDiv.appendChild(c);
		
		//ambient occlusion (highpass)
		var c=document.createElement('canvas');c.width=totalw*ts;c.height=totalh*ts;
		var ctx=c.getContext('2d');
		ctx.drawImage(imgHeight,0,0);
		var size=2;
		ctx.globalAlpha=0.5;
		ctx.drawImage(c,-size,0);
		ctx.drawImage(c,size,0);
		ctx.drawImage(c,0,-size);
		ctx.drawImage(c,0,size);
		ctx.globalAlpha=1;
		ctx.beginPath();
		ctx.rect(0,0,map.w*ts,map.h*ts);
		ctx.fillStyle='rgb(255,255,255)';
		ctx.globalCompositeOperation='difference';
		ctx.fill();//invert
		ctx.globalCompositeOperation='source-over';
		ctx.globalAlpha=0.5;
		ctx.drawImage(imgHeight,0,0);
		ctx.globalCompositeOperation='overlay';
		ctx.drawImage(c,0,0);
		ctx.drawImage(c,0,0);
		var imgAO=c;
		if (breakdown) toDiv.appendChild(c);
		if (verbose) {console.log('	RELIEF took 		'+(Date.now()-timeStep)+'ms');timeStep=Date.now();}
		
		//add emboss and color
		var c=document.createElement('canvas');c.width=totalw*ts;c.height=totalh*ts;
		var ctx=c.getContext('2d');
		ctx.drawImage(imgEmboss1,0,0);
		ctx.globalCompositeOperation='overlay';
		ctx.drawImage(imgEmboss2,1,1);//combine both emboss passes
		/*ctx.globalAlpha=0.5;
		ctx.drawImage(imgHeight,0,0);
		ctx.globalAlpha=1;*/
		ctx.globalCompositeOperation='hard-light';
		ctx.drawImage(imgColor,0,0);//add color
		ctx.globalCompositeOperation='overlay';
		ctx.drawImage(imgAO,0,0);//add AO
		var imgFinal=c;
		if (verbose) {console.log('	COMPOSITING 2 took 	'+(Date.now()-timeStep)+'ms');timeStep=Date.now();}
		
		//blots (big spots of random color to give the map some unity)
		Math.seedrandom(map.seed+'-blots');
		ctx.globalCompositeOperation='soft-light';
		ctx.globalAlpha=0.25;
		for (var i=0;i<4;i++)
		{
			var x=Math.random()*map.w*ts;
			var y=Math.random()*map.h*ts;
			var s=Math.max(map.w,map.h)*ts;
			var grd=ctx.createRadialGradient(x,y,0,x,y,s/2);
			grd.addColorStop(0,'rgb('+Math.floor(Math.random()*255)+','+Math.floor(Math.random()*255)+','+Math.floor(Math.random()*255)+')');
			grd.addColorStop(1,'rgb(128,128,128)');
			ctx.fillStyle=grd;
			ctx.fillRect(x-s/2,y-s/2,s,s);
		}
		if (verbose) {console.log('	BLOTS took 			'+(Date.now()-timeStep)+'ms');timeStep=Date.now();}
		
		if (colorShift)
		{
			//heck, why not. slight channel-shifting
			var c=document.createElement('canvas');c.width=totalw*ts;c.height=totalh*ts;
			var ctx=c.getContext('2d');
			ctx.drawImage(imgFinal,0,0);
			ctx.globalCompositeOperation='multiply';
			ctx.beginPath();
			ctx.rect(0,0,map.w*ts,map.h*ts);
			ctx.fillStyle='rgb(255,0,0)';
			ctx.fill();
			var imgRed=c;
			var c=document.createElement('canvas');c.width=totalw*ts;c.height=totalh*ts;
			var ctx=c.getContext('2d');
			ctx.drawImage(imgFinal,0,0);
			ctx.globalCompositeOperation='multiply';
			ctx.beginPath();
			ctx.rect(0,0,map.w*ts,map.h*ts);
			ctx.fillStyle='rgb(0,255,255)';
			ctx.fill();
			var imgCyan=c;
			//if (breakdown) toDiv.appendChild(c);
			if (verbose) {console.log('	COLORSHIFT took 	'+(Date.now()-timeStep)+'ms');timeStep=Date.now();}
		}
		
		c=imgFinal;ctx=c.getContext('2d');
		if (colorShift)
		{
			ctx.globalCompositeOperation='lighten';
			ctx.globalAlpha=0.5;
			ctx.drawImage(imgRed,-1,-1);
			ctx.drawImage(imgCyan,1,1);
		}
		ctx.globalAlpha=1;
		ctx.globalCompositeOperation='soft-light';
		ctx.beginPath();
		ctx.rect(0,0,map.w*ts,map.h*ts);
		ctx.fillStyle='rgb(160,128,96)';
		ctx.fill();//some slight sepia to finish it up
		
		ctx.globalCompositeOperation='destination-in';
		ctx.drawImage(imgFog,0,0);//fog
		ctx.globalCompositeOperation='source-over';
		ctx.drawImage(imgOutline,0,0);//outline
		
		ctx.globalCompositeOperation='source-over';
		ctx.globalAlpha=1;
		
		if (breakdown) toDiv.appendChild(c);
		else
		{
			//flush
			var imgBase=0;
			var imgFog=0;
			var imgOutline=0;
			var imgSea=0;
			var imgLand=0;
			var imgSeaColor=0;
			var imgColor=0;
			var imgEdges=0;
			var imgSeaHeight=0;
			var imgHeight=0;
			var imgEmboss1=0;
			var imgEmboss2=0;
			var imgAO=0;
			var imgFinal=0;
			var imgRed=0;
			var imgCyan=0;
		}
		Math.seedrandom();
		if (verbose) {console.log('	FINAL STEPS took 	'+(Date.now()-timeStep)+'ms');timeStep=Date.now();}
		
		if (verbose) console.log('Rendering map took '+(Date.now()-time)+'ms.');
		return c;
	}
	
	G.renderTile=function(map,tileX,tileY)
	{
		//re-render a specific tile (invokes G.renderMap with constrained bounds)
		//to speed things up, we're only re-rendering a 5x5 block of tiles centered around the specified tile and copying the central 3x3 block back to the canvas
		var ts=16;
		var c=G.renderMap(map,{x1:tileX-3,y1:tileY-3,x2:tileX+5,y2:tileY+5});
		var ctx=l('mapCanvas').getContext('2d');
		ctx.clearRect((tileX-2)*ts,(tileY-2)*ts,(5*ts),(5*ts));
		ctx.drawImage(c,(tileX-2)*ts,(tileY-2)*ts,(5*ts),(5*ts),(tileX-2)*ts,(tileY-2)*ts,(5*ts),(5*ts));
	}
	
	/*=====================================================================================
	TERRITORIES
		Territories are instances of a terrain type on a tile. Each tile is of a specific terrain tile.
		G.Land() creates a new terrain type.
	=======================================================================================*/
	G.land=[];
	G.landByName=[];
	G.getLand=function(name){if (!G.landByName[name]) ERROR('No terrain type exists with the name '+name+'.'); else return G.landByName[name];}
	G.Land=function(obj)
	{
		this.type='land';
		this.goods=[];
		this.names=[];
		this.icon=[0,0];
		
		for (var i in obj) this[i]=obj[i];
		if (this.modifier) return 0;//not yet
		this.id=G.land.length;
		if (!this.displayName) this.displayName=cap(this.name);
		G.land.push(this);
		G.landByName[this.name]=this;
		G.setDict(this.name,this);
		this.mod=G.context;
	}
	
	G.inspectTile=function(tile)
	{
		//display the tile's details in the land section
		//note : this used to display every territory owned until i realized 3 frames per second doesn't make for a very compelling user experience
		var str='';
		//Math.seedrandom(tile.map.seed+'-name-'+tile.x+'/'+tile.y);
		var name=tile.land.displayName;//choose(tile.land.names);
		str+='<div class="block framed bgMid fadeIn" id="land-0"><div class="fancyText framed bgMid blockLabel">'+name+'</div><div class="fancyText segmentHeader">Goods</div><div class="thingBox" style="padding:0px;text-align:left;">';
		var I=0;
		for (var ii in tile.goods)
		{
			var me=G.getGoods(ii);
			var amount=tile.goods[ii];
			str+='<div id="landGoods-'+I+'" class="thing standalone'+G.getIconClasses(me)+'">'+G.getIconStr(me);
			if (!me.noAmount)
			{
				var bar=0;
				if (amount<0.25) bar=0;
				else if (amount<0.5) bar=1;
				else if (amount<1.5) bar=2;
				else if (amount<3) bar=3;
				else bar=4;
				str+='<div class="icon" style="'+G.getFreeformIcon(0,289+bar*7,24,6)+'top:100%;"></div>';
			}
			str+='</div>';
			I++;
		}
		str+='</div></div>';
		l('landList').innerHTML=str;
		var I=0;
		for (var ii in tile.goods)
		{
			var goods=G.getGoods(ii);
			G.addTooltip(l('landGoods-'+I),function(me,amount){return function(){
				var str='<div class="info">';
				str+='<div class="infoIcon"><div class="thing standalone'+G.getIconClasses(me,true)+'">'+G.getIconStr(me,0,0,true)+'</div></div>';
				str+='<div class="fancyText barred infoTitle">'+me.displayName;
				if (!me.noAmount)
				{
					str+='<div class="fancyText infoAmount">';
					if (amount<0.25) str+='(scarce)';
					else if (amount<0.5) str+='(few)';
					else if (amount<1.5) str+='(some)';
					else if (amount<3) str+='(lots)';
					else str+='(abundant)';
					str+='</div>';
				}
				str+='</div>';
				if (me.desc) str+='<div class="infoDesc">'+G.parse(me.desc)+'</div>';
				str+='</div>';
				str+=G.debugInfo(me);
				return str;
			};}(goods,tile.goods[ii]),{offY:-8});
			I++;
		}
		//Math.seedrandom();
	}
	G.logic['land']=function()
	{
		if (G.tick%10==0)
		{
			G.computeOwnedRes(G.currentMap,1);//recompute available terrain resources every 10 ticks
			//(resources may change as new tiles are explored and new technologies reveal more goods)
		}
	}
	G.update['land']=function()
	{
		var str='';
		str+=G.textWithTooltip('?','<div style="width:240px;text-align:left;"><div class="par">This is your territory. While you only start with a small tile of land, there is a whole map for you to explore if you have units with that ability.</div><div class="par">Each tile you control adds to the natural resources available for your units to gather. You get more resources from fully-explored tiles than from tiles you\'ve just encountered.</div><div class="par">Click an explored tile on the map to the right to see what goods can be found in it, and how those goods contribute to your natural resources.</div></div>','infoButton');
		str+='<div id="landBox">';
		str+='<div id="landList"></div>';
		if (G.currentMap.computedPlayerRes)
		{
			//display list of total gatherable resources per context
			var I=0;
			var cI=0;
			str+='<div style="padding:16px;text-align:left;" class="thingBox"><div class="bitBiggerText fancyText">Total natural resources in your territory :</div>';
			for (var i in G.contextNames)
			{
				var context=i;
				if (G.contextVisibility[i] || G.getSetting('debug'))
				{
					var contextName=G.contextNames[i];
					var res=G.currentMap.computedPlayerRes[i]||[];
					str+='<div class="categoryName fancyText barred">'+contextName+'</div>';
					str+='<div>';
					var sortedRes=[];
					for (var ii in res)
					{
						var me=G.getRes(ii);
						sortedRes.push({res:me,amount:res[ii],id:me.id});
					}
					sortedRes.sort(function(a,b){return b.amount-a.amount});
					
					for (var ii in sortedRes)
					{
						var me=sortedRes[ii].res;
						var amount=Math.ceil(sortedRes[ii].amount*1000)/1000;
						
						var floats=0;
						if (amount<10) floats++;
						if (amount<1) floats++;
						if (amount<0.1) floats++;
						
						str+=G.textWithTooltip('<div class="icon freestanding" style="'+G.getIconUsedBy(me)+'"></div><div id="naturalResAmount-'+cI+'-'+me.id+'" class="freelabel">x'+B(amount,floats)+'</div>',G.getResTooltip(me,'<span style="font-size:12px;">'+B(amount,floats)+' available every day<br>by '+contextName+'.</span>'));
						I++;
					}
					str+='</div>';
				}
				cI++;
			}
			str+='</div>';
		}
		str+='</div>';
		l('landDiv').innerHTML=str;
		
		G.addCallbacks();
		
		if (G.inspectingTile) G.inspectTile(G.inspectingTile);
		
		G.draw['land']();
	}
	G.draw['land']=function()
	{
		//annoying to manage, guess the player will just have to reload the territory tab to see changes for now
		//TODO : make this work with div appends instead
		/*
		if (G.currentMap.computedPlayerRes)
		{
			//update amount labels on natural resources
			var I=0;
			var cI=0;
			for (var i in G.contextNames)
			{
				var context=i;
				var res=G.currentMap.computedPlayerRes[i]||[];
				for (var ii in res)
				{
					var me=G.getRes(ii);
					var amount=Math.ceil(res[ii]*1000)/1000;
					
					var floats=0;
					if (amount<10) floats++;
					if (amount<1) floats++;
					if (amount<0.1) floats++;
					if (l('naturalResAmount-'+cI+'-'+me.id)) l('naturalResAmount-'+cI+'-'+me.id).innerHTML='x'+B(amount,floats);
				}
				cI++;
			}
		}
		*/
	}
	
	G.computeOwnedRes=function(map,owner)//given a map and an owner, return the resources and their amounts available
	{
		var goods=[];//first : add up all goods together
		for (var x=0;x<map.w;x++)
		{
			for (var y=0;y<map.h;y++)
			{
				var tile=map.tiles[x][y];
				if (tile.owner==owner)
				{
					var mult=tile.explored;
					if (mult>0)
					{
						for (var i in tile.goods)
						{
							if (!goods[i]) goods[i]=0;
							goods[i]+=tile.goods[i]*mult;//add goods of the tile to the amounts
						}
					}
				}
			}
		}
		var res=G.getResFromGoods(goods);//secondly : turn those goods into resources by context
		map.computedPlayerRes=res;
		return res;
	}
	
	/*=====================================================================================
	GOODS
		Goods are pseudo-resources that appear on tiles.
		Goods usually have bindings to harvesting contexts, such as "provides 3 stones when gathered, 6 stones when dug, and 10 stones and 1 ore when mined"
	=======================================================================================*/
	G.goods=[];
	G.goodsByName=[];
	G.contextNames=[];
	G.contextVisibility=[];
	G.getGoods=function(name){if (!G.goodsByName[name]) ERROR('No goods type exists with the name '+name+'.'); else return G.goodsByName[name];}
	G.Goods=function(obj)
	{
		this.type='goods';
		this.res={};
		this.icon=[0,0];
		
		for (var i in obj) this[i]=obj[i];
		this.id=G.goods.length;
		if (!this.displayName) this.displayName=cap(this.name);
		G.goods.push(this);
		G.goodsByName[this.name]=this;
		G.setDict(this.name,this);
		this.mod=G.context;
	}
	
	/*=====================================================================================
	TILE EFFECTS
		Tile effects are effects that can appear on tiles, which can change their resource output or do other nifty things.
	=======================================================================================*/
	G.tileEffect=[];
	G.tileEffectByName=[];
	G.getTileEffect=function(name){if (!G.tileEffectByName[name]) ERROR('No tile effect type exists with the name '+name+'.'); else return G.tileEffectByName[name];}
	G.TileEffect=function(obj)
	{
		this.type='tile effect';
		this.icon=[0,0];
		
		for (var i in obj) this[i]=obj[i];
		this.id=G.tileEffect.length;
		if (!this.displayName) this.displayName=cap(this.name);
		G.tileEffect.push(this);
		G.tileEffectByName[this.name]=this;
		G.setDict(this.name,this);
		this.mod=G.context;
	}
	/*=====================================================================================
	CHOOSEBOXES
		These are boxes that show up to three choices (usually techs or traits) that the player can either purchase or reroll.
	=======================================================================================*/
	G.chooseBox=[];
	G.ChooseBox=function(obj)
	{
		this.type='choosebox';
		this.getCosts=function(){return {};}//costs for getting a new set of cards (from rerolling or not); should return a list of costs as {'resource':amount}
		this.getCardCosts=function(what){return what.cost;}//costs for cards
		this.getCards=function(){return [];}//should return a list of things to populate the box with as [thing1,thing2,thing3]
		this.onBuy=function(){}//what to do when a card is clicked and we have the required costs
		this.onReroll=function(){this.roll+=1;}//what to do when the reroll button is pressed
		this.onTick=function(){this.roll-=0.01;this.roll=Math.max(this.roll,0);}//execute every tick (usually to decrease roll)
		this.buttonTooltip=function(){return '';};//what tooltip to display on the button
		this.buttonText=function(){return 'Research';};//what text to display on the button
		
		this.choicesN=3;//how many max options the choosebox should have
		this.choices=[];//what choices the choosebox currently has
		this.roll=0;//how many times we've clicked the research button without buying anything
		
		for (var i in obj) this[i]=obj[i];
		this.id=G.chooseBox.length;
		if (!this.displayName) this.displayName=cap(this.name);
		G.chooseBox.push(this);
		G.setDict(this.name,this);
		this.mod=G.context;
	}
	G.initChooseBox=function(me)
	{
		me.choices=[];
		me.roll=0;
	}
	G.rerollChooseBox=function(me)
	{
		//check if we match the costs; if yes, research or reroll
		var costs=me.getCosts();
		var success=true;
		if (!G.testCost(costs,1)) success=false;
		if (me.getCards().length==0) {success=false;G.middleText('<small>There is nothing to research.</small>');}
		if (success)
		{
			G.doCost(costs,1);
			
			var bounds=l('chooseIgniter-'+me.id).getBoundingClientRect();
			var posX=bounds.left+bounds.width/2;
			var posY=bounds.top;
			for (var i in costs)
			{G.showParticle({x:posX,y:posY,icon:G.dict[i].icon});}
			
			me.justUsed=true;
			me.choices=[];
			var choices=me.getCards();
			var n=Math.min(choices.length,me.choicesN);
			for (var i=0;i<n;i++)
			{
				var choice=choose(choices);
				if (!me.choices.includes(choice)) me.choices.push(choice);
				//var index=choices.indexOf(choice);
				//choices.splice(index,1);//no duplicates
			}
			me.onReroll();
			G.refreshChooseBox(me);
			me.justUsed=false;
		}
	}
	G.purchaseChooseBox=function(me,choice)
	{
		//check if we match the costs; if yes, purchase the thing and reset
		var costs=choice.cost;
		var success=true;
		if (!G.testCost(costs,1)) success=false;
		if (success)
		{
			G.doCost(costs,1);
			
			var bounds=l('chooseBox-'+me.id).getBoundingClientRect();
			var posX=bounds.left+bounds.width/2;
			var posY=bounds.top;
			for (var i in costs)
			{G.showParticle({x:posX,y:posY,icon:G.dict[i].icon});}
			
			me.justUsed=true;
			var index=me.choices.indexOf(choice);
			me.choices=[];
			me.roll=0;
			me.onBuy(choice,index);
			G.refreshChooseBox(me);
			me.justUsed=false;
		}
	}
	G.writeChooseBoxes=function(context)
	{
		//uses callbacks
		var str='';
		var n=G.chooseBox.length;
		for (var i=0;i<n;i++)
		{
			var me=G.chooseBox[i];
			if (me.context==context)
			{
				str+='<div class="chooseBox box" id="chooseBox-'+me.id+'">';
				var nn=Math.max(me.choicesN,me.choices.length);
				for (var ii=0;ii<nn;ii++)
				{
					var choice=me.choices[ii];
					str+='<div class="chooseOption" id="chooseOption-'+ii+'-'+me.id+'">';
					if (choice)
					{
						str+='<div class="tech thing'+G.getIconClasses(choice)+''+(me.justUsed?' popIn':'')+'" id="chooseOption-'+ii+'-'+me.id+'-base">'+
						G.getIconStr(choice,'chooseOption-'+ii+'-'+me.id+'-icon')+
						'<div class="overlay" id="chooseOption-'+ii+'-'+me.id+'-over"></div>'+
						'</div>';
					}
					str+='</div>';
				}
				str+='<div class="chooseIgniter button" id="chooseIgniter-'+me.id+'">'+me.buttonText()+'</div>';
				str+='</div>';
				
				G.pushCallback(function(me){return function(){
					var nn=me.choices.length;
					for (var ii=0;ii<nn;ii++)
					{
						var choice=me.choices[ii];
						var div=l('chooseOption-'+ii+'-'+me.id+'-base');
						G.addTooltip(div,function(what){return function(){return G.getKnowTooltip(what,true);};}(choice),{offY:-8});
						div.onclick=function(what,chooseBox){return function(e){if (G.speed>0) {G.purchaseChooseBox(chooseBox,what,e.target);} else G.cantWhenPaused();};}(choice,me);
					}
					
					var div=l('chooseIgniter-'+me.id);
					G.addTooltip(div,function(what){return function(){return what.buttonTooltip()};}(me),{anchor:'bottom',offY:8});
					div.onclick=function(chooseBox){return function(){if (G.speed>0){G.rerollChooseBox(chooseBox);} else G.cantWhenPaused();};}(me);
					G.refreshChooseBox(me);
				}}(me));
			}
		}
		return str;
	}
	G.refreshChooseBox=function(me)
	{
		//if the div is visible, perform some visual updates
		var div=l('chooseBox-'+me.id);
		if (div)
		{
			l('chooseIgniter-'+me.id).innerHTML=me.buttonText();
			
			//change choice class depending on whether we can buy it
			var nn=me.choices.length;
			for (var ii=0;ii<nn;ii++)
			{
				var choice=me.choices[ii];
				var choiceDiv=l('chooseOption-'+ii+'-'+me.id+'-base');
				
				var costs=choice.cost;
				var success=true;
				if (!G.testCost(costs,1)) success=false;
				if (success) choiceDiv.classList.remove('disabled');
				else choiceDiv.classList.add('disabled');
			}
		}
	}
	G.tickChooseBoxes=function()
	{
		var n=G.chooseBox.length;
		for (var i=0;i<n;i++)
		{
			var me=G.chooseBox[i];
			me.onTick();
			G.refreshChooseBox(me);
		}
	}
	
	/*=====================================================================================
	POLICIES
	=======================================================================================*/
	G.policy=[];//all policies
	G.policyByName=[];
	G.policyCategories=[];
	G.getPolicy=function(name){if (!G.policyByName[name]) ERROR('No policy exists with the name '+name+'.'); else return G.policyByName[name];}
	//unlike traits and techs, we don't store specific instances of policies but act on the objects themselves
	
	G.Policy=function(obj)
	{
		this.type='policy';
		this.category='';
		this.family='';
		this.effects=[];
		this.startWith=0;
		this.icon=[0,0];
		this.modes=[];
		this.mode=0;
		this.req={};
		this.visible=false;
		
		for (var i in obj) this[i]=obj[i];
		this.id=G.policy.length;
		if (!this.displayName) this.displayName=cap(this.name);
		G.policy.push(this);
		G.policyByName[this.name]=this;
		G.setDict(this.name,this);
		
		if (this.modes.length==0)
		{
			//no modes defined? auto-populate as simple on/off switch
			this.modes['off']={name:'Disabled',desc:'This policy is disabled.'};
			this.modes['on']={name:'Enabled',desc:'This policy is enabled.'};
			if (this.effectsOff) this.modes['off'].effects=this.effectsOff;
			if (this.effects) this.modes['on'].effects=this.effects;
			this.binary=true;
		}
		this.mod=G.context;
	}
	
	G.checkPolicy=function(name)
	{
		var me=G.getPolicy(name);
		if (!me.visible) return 0;
		return me.mode.id;
	}
	
	G.logic['policy']=function()
	{
	}
	G.update['policy']=function()
	{
		var str='';
		str+=
			'<div class="regularWrapper">'+
			G.textWithTooltip('?','<div style="width:240px;text-align:left;"><div class="par">Policies help you regulate various aspects of the life of your citizens.</div><div class="par">Some policies provide multiple modes of operation while others are simple on/off switches.</div><div class="par">Changing policies usually costs influence points and, depending on how drastic or generous the change is, may have an impact on your people\'s morale.</div></div>','infoButton')+
			'<div class="fullCenteredOuter"><div id="policyBox" class="thingBox fullCenteredInner"></div></div></div>';
		l('policyDiv').innerHTML=str;
		
		var strByCat=[];
		var len=G.policyCategories.length;
		for (var iC=0;iC<len;iC++)
		{
			strByCat[G.policyCategories[iC].id]='';
		}
		var len=G.policy.length;
		for (var i=0;i<len;i++)
		{
			var me=G.policy[i];
			if (me.visible && (me.category!='debug' || G.getSetting('debug')))
			{
				var str='';
				var disabled='';
				if (me.binary && me.mode.id=='off') disabled=' off';
				str+='<div class="policy thing'+(me.binary?'':' expands')+' wide1'+disabled+'" id="policy-'+me.id+'">'+
					G.getIconStr(me,'policy-icon-'+me.id)+
					'<div class="overlay" id="policy-over-'+me.id+'"></div>'+
				'</div>';
				strByCat[me.category]+=str;
			}
		}
		
		var str='';
		var len=G.policyCategories.length;
		for (var iC=0;iC<len;iC++)
		{
			if (strByCat[G.policyCategories[iC].id]!='') str+='<div class="category" style="display:inline-block;"><div class="categoryName barred fancyText" id="policy-catName-'+iC+'">'+G.policyCategories[iC].name+'</div>'+strByCat[G.policyCategories[iC].id]+'</div>';
		}
		l('policyBox').innerHTML=str;
		
		G.addCallbacks();
		
		var len=G.policy.length;
		for (var i=0;i<len;i++)
		{
			var me=G.policy[i];
			if (me.visible)
			{
				var div=l('policy-'+me.id);if (div) me.l=div; else me.l=0;
				var div=l('policy-icon-'+me.id);if (div) me.lIcon=div; else me.lIcon=0;
				var div=l('policy-over-'+me.id);if (div) me.lOver=div; else me.lOver=0;
				G.addTooltip(me.l,function(what){return function(){return G.getPolicyTooltip(what)};}(me),{offY:-8});
				if (me.l) {me.l.onclick=function(what){return function(){G.clickPolicy(what);};}(me);}
				if (me.l && !me.binary) {var div=me.l;div.onmousedown=function(policy,div){return function(){G.selectModeForPolicy(policy,div);};}(me,div);}
			}
		}
		
		G.draw['policy']();
	}
	G.draw['policy']=function()
	{
	}
	G.gainPolicy=function(me)
	{
		me.visible=true;
		me.mode=me.modesById[0];
		if (me.startMode) me.mode=me.modes[me.startMode];
		if (me.mode.effects) G.applyKnowEffects(me.mode,false,true);
		G.update['policy']();
	}
	G.runPolicyReqs=function()
	{
		//unlock policies
		//executed on gaining a new tech or trait
		var len=G.policy.length;
		for (var i=0;i<len;i++)
		{
			var me=G.policy[i];
			if (!me.visible)
			{
				if (me.req && G.checkReq(me.req)) G.gainPolicy(me);
			}
		}
	}
	
	G.setPolicyModeByName=function(me,mode)
	{
		me=G.getPolicy(me);
		G.setPolicyMode(me,me.modes[mode]);
	}
	G.setPolicyMode=function(me,mode)
	{
		//free old mode uses, and assign new mode uses
		var oldMode=me.mode;
		var newMode=mode;
		if (oldMode==newMode) return;
		//G.undoUse(oldMode.use,me.amount);
		//G.doUse(newMode.use,me.amount);
		me.mode=mode;
		if (me.mode.effects) G.applyKnowEffects(me.mode,false,true);
		if (G.getSetting('animations')) triggerAnim(me.l,'plop');
		if (me.binary)
		{
			if (mode.id=='off') me.l.classList.add('off');
			else me.l.classList.remove('off');
		}
	}
	G.clickPolicy=function(me)
	{
		if (G.speed>0)
		{
			if (G.keys[17] && G.getSetting('debug'))
			{
				//remove policy
				me.visible=false;
				me.mode=me.modesById[0];
				if (me.startMode) me.mode=me.modes[me.startMode];
				if (me.mode.effects) G.applyKnowEffects(me.mode,true,true);
				G.update['policy']();
			}
			else if (me.binary)
			{
				//for binary on/off policies
				if (G.testCost(me.cost,1))
				{
					G.doCost(me.cost,1);
					var mode='off';
					if (me.mode.id=='off') mode='on';
					G.setPolicyMode(me,me.modes[mode]);
				}
			}
		} else G.cantWhenPaused();
	}
	G.selectModeForPolicy=function(me,div)
	{
		if (div==G.widget.parent) G.widget.close();
		else
		{
			G.widget.popup({
				func:function(widget)
				{
					var str='';
					var me=widget.linked;
					var proto=me;
					for (var i in proto.modes)
					{
						var mode=proto.modes[i];
						if (!mode.req || G.checkReq(mode.req))
						{str+='<div class="button'+(mode.num==me.mode.num?' on':'')+'" id="mode-button-'+mode.num+'">'+mode.name+'</div>';}
					}
					widget.l.innerHTML=str;
					//TODO : how do uses and costs work in this?
					for (var i in proto.modes)
					{
						var mode=proto.modes[i];
						if (!mode.req || G.checkReq(mode.req))
						{
							l('mode-button-'+mode.num).onmouseup=function(target,mode,div){return function(){
								//released the mouse on this mode button; test if we can switch to this mode, then close the widget
								if (G.speed>0)
								{
									var me=target;
									var proto=me;
									if (G.testCost(me.cost,1))
									{
										if (!me.mode.use || G.testUse(G.subtractCost(me.mode.use,mode.use),1))
										{
											G.doCost(me.cost,1);
											//remove "on" class from all mode buttons and add it to the current mode button
											for (var i in proto.modes)
											{if (l('mode-button-'+proto.modes[i].num)) {l('mode-button-'+proto.modes[i].num).classList.remove('on');}}
											l('mode-button-'+mode.num).classList.add('on');
											G.setPolicyMode(me,mode);
											if (me.l) G.popupSquares.spawn(l('mode-button-'+mode.num),me.l);
										}
									}
								} else G.cantWhenPaused();
								widget.closeOnMouseUp=false;//override default behavior
								widget.close(5);//schedule to close the widget in 5 frames
							};}(me,mode,div);
							
							if (!me.mode.use || G.testUse(G.subtractCost(me.mode.use,mode.use),me.amount)) addHover(l('mode-button-'+mode.num),'hover');//fake mouseover because :hover doesn't trigger when mouse is down
							G.addTooltip(l('mode-button-'+mode.num),function(me,target){return function(){
								var proto=target;
								//var uses=G.subtractCost(target.mode.use,me.use);
								var str='<div class="info">'+G.parse(me.desc);
								//if (!isEmpty(me.use)) str+='<div class="divider"></div><div class="fancyText par">Uses : '+G.getUseString(me.use,true,true)+' per '+proto.name+'</div>';
								//if (target.amount>0 && target.mode.num!=me.num && !isEmpty(uses)) str+='<div class="divider"></div><div class="fancyText par">Needs '+G.getUseString(uses,true,false,target.amount)+' to switch</div>';
								str+='<div>Changing to this mode costs '+G.getCostString(proto.cost,true,false,1)+'.</div></div>';
								return str;
							};}(mode,me),{offY:-8});
						}
					}
				},
				offX:0,
				offY:-8,
				anchor:'top',
				parent:div,
				linked:me,
				closeOnMouseUp:true
			});
		}
	}
	G.getPolicyTooltip=function(me)
	{
		var str='<div class="info">';
		str+='<div class="infoIcon"><div class="thing standalone'+G.getIconClasses(me,true)+'">'+G.getIconStr(me,0,0,true)+'</div></div>';
		str+='<div class="fancyText barred infoTitle">'+me.displayName+'</div>';
		str+='<div class="fancyText barred">Current mode :<br><b>'+me.mode.name+'</b><br>'+(me.binary?'(Click to toggle)':'(Click and drag to change)')+'</div>';
		if (!isEmpty(me.cost)) str+='<div class="fancyText barred">'+(me.binary?'Toggling':'Changing mode')+' costs '+G.getCostString(me.cost,true,false,1)+'</div>';
		if (me.desc) str+='<div class="infoDesc">'+G.parse(me.desc)+'</div>';
		str+='</div>';
		str+=G.debugInfo(me);
		return str;
	}
	
	/*=====================================================================================
	TECHS & CULTURAL TRAITS
	=======================================================================================*/
	G.know=[];//all techs and traits; short for "knowledge"
	G.tech=[];//techs only
	G.trait=[];//traits only
	G.techN=0;//incrementer
	G.traitN=0;//incrementer
	G.knowCategories=[];
	G.knowByName=[];
	G.techByName=[];
	G.traitByName=[];
	G.techByTier=[];
	G.traitByTier=[];
	G.getKnow=function(name){if (!G.knowByName[name]) ERROR('No knowledge type exists with the name '+name+'.'); else return G.knowByName[name];}
	G.getTech=function(name){if (!G.techByName[name]) ERROR('No technology exists with the name '+name+'.'); else return G.techByName[name];}
	G.getTrait=function(name){if (!G.traitByName[name]) ERROR('No trait exists with the name '+name+'.'); else return G.traitByName[name];}
	G.techsOwned=[];//all techs the player currently has, from newest to oldest
	G.techsOwnedNames=[];//names of all techs owned
	G.traitsOwned=[];//all traits the player currently has, from newest to oldest
	G.traitsOwnedNames=[];//names of all traits owned
	G.shortMemory=5;//any short trait that passes this threshold gets erased
	G.longMemory=15;//any long trait that passes this threshold gets erased
	G.Know=function(obj)
	{
		this.type='know';
		this.cost={};
		this.category='';
		this.effects=[];
		this.startWith=0;
		this.icon=[0,0];
		this.tier=0;
		
		for (var i in obj) this[i]=obj[i];
		this.id=G.know.length;
		if (!this.displayName) this.displayName=cap(this.name);
		G.know.push(this);
		G.knowByName[this.name]=this;
		G.setDict(this.name,this);
		this.mod=G.context;
	}
	G.Tech=function(obj)
	{
		var me=new G.Know(obj);
		me.type='tech';
		if (me.category=='') me.category='knowledge';
		G.tech.push(me);
		G.techByName[me.name]=me;
		return me;
	}
	G.Trait=function(obj)
	{
		var me=new G.Know(obj);
		me.type='trait';
		if (me.category=='') me.category='culture';
		G.trait.push(me);
		G.traitByName[me.name]=me;
		return me;
	}
	
	G.getKnowTooltip=function(me,showCost)
	{
		var str='<div class="info">';
		str+='<div class="infoIcon"><div class="thing standalone'+G.getIconClasses(me,true)+'">'+G.getIconStr(me,0,0,true)+'</div></div>';
		str+='<div class="fancyText barred infoTitle">'+me.displayName+'</div>';
		if (me.desc) str+='<div class="infoDesc">'+G.parse(me.desc)+'</div>';
		if ((G.getSetting('debug') || G.getSetting('showLeads')) && me.precededBy.length>0)
		{
			var reqStr=[];
			for (var i in me.precededBy) {reqStr.push(me.precededBy[i].displayName);}
			str+='<div class="fancyText barred">Requisites :<br>'+reqStr.join(', ')+'</div>';
		}
		if ((G.getSetting('debug') || G.getSetting('showLeads')) && me.leadsTo.length>0)
		{
			var leadsToStr=[];
			for (var i in me.leadsTo) {leadsToStr.push(me.leadsTo[i].displayName);}
			str+='<div class="fancyText barred">Leads to :<br>'+leadsToStr.join(', ')+'</div>';
		}
		str+='</div>';
		if (showCost || G.getSetting('debug')) str+='<div class="info">Cost : '+G.getCostString(me.cost,true)+'</div>';
		str+=G.debugInfo(me);
		return str;
	}
	
	G.logic['trait']=function()
	{
	}
	G.update['trait']=function()
	{
		l('traitDiv').innerHTML=
			G.textWithTooltip('?','<div style="width:240px;text-align:left;"><div class="par">Traits define your civilization as a unique entity, giving small boosts to various aspects of arts, science and lifestyle.</div><div class="par">Your civilization gains random traits over time, consuming resources in the process.</div><div class="par">Events such as celebrations and disasters are also recorded here as memories that fade away over time.</div></div>','infoButton')+
			'<div class="fullCenteredOuter"><div class="fullCenteredInner"><div id="extraCultureStuff" style="text-align:center;margin-bottom:8px;"></div><div id="traitBox" class="thingBox"></div></div></div>';
		
		var str=''+
			'<div id="civBlurb" class="framed bgMid" style="width:320px;margin:8px auto;padding:10px 16px 4px 16px;"></div>'+
			G.button({tooltip:'Lets you change the names of various things,<br>such as your civilization, your people, and yourself.',text:'Rename civilization',onclick:function(e){G.dialogue.popup(function(div){
				var str=
				'<div class="fancyText title">Name your civilization</div><div class="bitBiggerText scrollBox underTitle">'+
				'<div class="fancyText par">Your name is '+G.field({text:G.getName('ruler'),tooltip:'This is your name.',oninput:function(val){G.setName('ruler',val);}})+', ruler of '+G.field({text:G.getName('civ'),tooltip:'This is the name of your civilization.',oninput:function(val){G.setName('civ',val);}})+' and the '+G.field({text:G.getName('civadj'),tooltip:'This is an adjective pertaining to your civilization.',oninput:function(val){G.setName('civadj',val);}})+' people.</div>'+
				'<div class="fancyText par">One '+G.field({text:G.getName('inhab'),tooltip:'This is the word used for someone who belongs to your civilization.',oninput:function(val){G.setName('inhab',val);}})+' among other '+G.field({text:G.getName('inhabs'),tooltip:'This is the plural of the previous word.',oninput:function(val){G.setName('inhabs',val);}})+', you vow to lead your people to greatness and forge a legacy that will stand the test of time.</div>'+
				'</div><div class="buttonBox">'+
				G.dialogue.getCloseButton()+
				'</div>';
				return str;
			},'wideDialogue')}})+
		'';
		l('extraCultureStuff').innerHTML=str;
		
		
		var strByCat=[];
		var len=G.knowCategories.length;
		for (var iC=0;iC<len;iC++)
		{
			strByCat[G.knowCategories[iC].id]='';
		}
		var len=G.traitsOwned.length;
		for (var i=0;i<len;i++)
		{
			var me=G.traitsOwned[i];
			var str='';
			str+='<div class="thingWrapper">';
			str+='<div class="trait thing'+G.getIconClasses(me.trait)+'" id="trait-'+me.id+'">'+
				G.getIconStr(me.trait,'trait-icon-'+me.id)+
				'<div class="overlay" id="trait-over-'+me.id+'"></div>'+
			'</div>';
			str+='</div>';
			strByCat[me.trait.category]+=str;
		}
		
		var str='';
		var len=G.knowCategories.length;
		for (var iC=0;iC<len;iC++)
		{
			if (strByCat[G.knowCategories[iC].id]!='') str+='<div class="category" style="display:inline-block;"><div class="categoryName barred fancyText" id="know-catName-'+iC+'">'+G.knowCategories[iC].name+'</div>'+strByCat[G.knowCategories[iC].id]+'</div>';
		}
		if (str=='') str+='<div class="fancyText bitBiggerText">Your civilization does not have any traits yet.<br>It may develop some over time.</div>';
		l('traitBox').innerHTML=str;
		
		G.addCallbacks();
		
		var len=G.traitsOwned.length;
		for (var i=0;i<len;i++)
		{
			var me=G.traitsOwned[i];
			var div=l('trait-'+me.id);if (div) me.l=div; else me.l=0;
			var div=l('trait-icon-'+me.id);if (div) me.lIcon=div; else me.lIcon=0;
			var div=l('trait-over-'+me.id);if (div) me.lOver=div; else me.lOver=0;
			G.addTooltip(me.l,function(what){return function(){return G.getKnowTooltip(what)};}(me.trait),{offY:-8});
			if (me.l) me.l.onclick=function(what){return function(){G.clickTrait(what);};}(me);
		}
		
		G.draw['trait']();
	}
	G.draw['trait']=function()
	{
		/*var len=G.traitsOwned.length;
		for (var i=0;i<len;i++)
		{
			var me=G.traitsOwned[i];
		}*/
		if (l('civBlurb')) l('civBlurb').innerHTML=G.doFunc('civ blurb','');
	}
	G.gainTrait=function(me)
	{
		G.traitsOwned.unshift({trait:me,id:G.traitN});
		G.traitsOwnedNames.unshift(me.name);
		var age=0;
		var newTraitsOwned=[];
		var len=G.traitsOwned.length;
		for (var i=0;i<len;i++)
		{
			var add=true;
			var trait=G.traitsOwned[i].trait;
			//TODO : re-add this for categories
			/*if (trait.shortTerm && age>=G.shortMemory) add=false;
			if (trait.longTerm && age>=G.longMemory) add=false;*/
			if (add) newTraitsOwned.push({trait:trait,id:i});
			age++;
		}
		G.traitsOwned=newTraitsOwned;
		G.applyKnowEffects(me,false,true);
		G.traitN++;
		G.shouldRunReqs=true;
		G.update['trait']();
	}
	G.clickTrait=function(me)
	{
		if (G.keys[17] && G.getSetting('debug'))
		{
			var index=G.traitsOwned.indexOf(me);
			G.traitsOwned.splice(index,1);//remove trait
			G.traitsOwnedNames.splice(index,1);
			G.applyKnowEffects(me.trait,true,true);
			G.update['trait']();
		}
	}
	
	
	G.logic['tech']=function()
	{
	}
	G.update['tech']=function()
	{
		var str='';
		str+=
			'<div class="behindBottomUI">'+
			G.textWithTooltip('?','<div style="width:240px;text-align:left;"><div class="par">Technologies are the cornerstone of your civilization\'s long-term development.</div><div class="par">Here you can invest resources to research new technologies which can unlock new units and enhance old ones.</div></div>','infoButton')+
			//'<div class="fullCenteredOuter"><div id="techBox" class="thingBox fullCenteredInner"></div></div></div>'+
			'<div class="fullCenteredOuter"><div class="fullCenteredInner"><div id="extraTechStuff" style="text-align:center;margin:auto;margin-bottom:8px;width:200px;"><div class="barred fancyText">Known technologies :</div></div><div id="techBox" class="thingBox"></div></div></div></div>'+
			'<div id="techUI" class="bottomUI bgPanelUp">';
		
		str+=G.writeChooseBoxes('tech');
		
		str+='</div>';
		l('techDiv').innerHTML=str;
		
		G.addCallbacks();
		
		var str='';
		if (G.getSetting('tieredDisplay'))
		{
			//tiered display
			for (var i in G.techByTier)
			{
				str+='<div><div style="width:32px;height:52px;display:inline-block;"><div class="fullCenteredOuter"><div class="fullCenteredInner fancyText bitBiggerText">'+i+'</div></div></div>';
				for (var ii in G.techByTier[i])
				{
					var me=G.techByTier[i][ii];
					str+='<div class="tech thing'+G.getIconClasses(me)+''+(G.has(me.name)?'':' off')+'" id="tech-'+me.id+'">'+
						G.getIconStr(me,'tech-icon-'+me.id)+
						'<div class="overlay" id="tech-over-'+me.id+'"></div>'+
					'</div>';
				}
				str+='</div>';
			}
			l('techBox').innerHTML=str;
			for (var i in G.techByTier)
			{
				for (var ii in G.techByTier[i])
				{
					var me=G.techByTier[i][ii];
					var div=l('tech-'+me.id);if (div) me.l=div; else me.l=0;
					var div=l('tech-icon-'+me.id);if (div) me.lIcon=div; else me.lIcon=0;
					var div=l('tech-over-'+me.id);if (div) me.lOver=div; else me.lOver=0;
					G.addTooltip(me.l,function(what){return function(){return G.getKnowTooltip(what)};}(me),{offY:-8});
					if (me.l) me.l.onclick=function(what){return function(){
						//G.clickTech(what);
						for (var i in G.tech)
						{
							//highlight ancestors and descendants of the tech
							if (what.ancestors.includes(G.tech[i])) l('tech-'+G.tech[i].id).classList.add('highlit');
							else l('tech-'+G.tech[i].id).classList.remove('highlit');
							if (G.tech[i].ancestors.includes(what) && G.tech[i]!=what) l('tech-'+G.tech[i].id).classList.add('highlitAlt');
							else l('tech-'+G.tech[i].id).classList.remove('highlitAlt');
							G.tooltip.close();
						}
					};}(me);
				}
			}
		}
		else
		{
			var len=G.techsOwned.length;
			for (var i=0;i<len;i++)
			{
				var me=G.techsOwned[i];
				str+='<div class="tech thing'+G.getIconClasses(me.tech)+'" id="tech-'+me.id+'">'+
					G.getIconStr(me.tech,'tech-icon-'+me.id)+
					'<div class="overlay" id="tech-over-'+me.id+'"></div>'+
				'</div>';
			}
			l('techBox').innerHTML=str;
			var len=G.techsOwned.length;
			for (var i=0;i<len;i++)
			{
				var me=G.techsOwned[i];
				var div=l('tech-'+me.id);if (div) me.l=div; else me.l=0;
				var div=l('tech-icon-'+me.id);if (div) me.lIcon=div; else me.lIcon=0;
				var div=l('tech-over-'+me.id);if (div) me.lOver=div; else me.lOver=0;
				G.addTooltip(me.l,function(what){return function(){return G.getKnowTooltip(what)};}(me.tech),{offY:-8});
				if (me.l) me.l.onclick=function(what){return function(){G.clickTech(what);};}(me);
			}
		}
		G.draw['tech']();
	}
	G.draw['tech']=function()
	{
		/*var len=G.techsOwned.length;
		for (var i=0;i<len;i++)
		{
			var me=G.techsOwned[i];
		}*/
	}
	G.gainTech=function(me)
	{
		G.techsOwned.unshift({tech:me,id:G.techN});
		G.techsOwnedNames.unshift(me.name);
		G.applyKnowEffects(me,false,true);
		G.techN++;
		G.shouldRunReqs=true;
		G.update['tech']();
	}
	G.clickTech=function(me)
	{
		if (G.keys[17] && G.getSetting('debug'))
		{
			var index=G.techsOwned.indexOf(me);
			G.techsOwned.splice(index,1);//remove tech
			G.techsOwnedNames.splice(index,1);
			G.applyKnowEffects(me.tech,true,true);
			G.update['tech']();
		}
	}
	
	G.applyKnowEffects=function(me,shouldReverse,oneTime)
	{
		//run through every effect in a trait, tech or policy and apply them
		//if shouldReverse is true, apply the opposite effect if possible (this is for stuff such as losing a trait or tech)
		//some effects only apply when oneTime is true; this is for stuff such as a tech giving a passive bonus when purchased, which you wouldn't want to apply when loading a save
		var len=me.effects.length;
		for (var i=0;i<len;i++)
		{
			var effect=me.effects[i];
			var reverse=shouldReverse;
			if (effect.invert) reverse=!reverse;//if the effect has invert:true, apply the effect only when reversing instead
			if (reverse && effect.noReverse) {}//skip if this effect is set not to reverse
			else
			{
				/*
				//obsolete; put .req:{} on units instead
				if (oneTime && effect.type=='unlock unit')
				{
					//might not reverse properly if something else already locked it
					for (var ii in effect.what)
					{G.getUnit(effect.what[ii]).unlocked=!reverse;}
				}
				else if (oneTime && effect.type=='lock unit')
				{
					//might not reverse properly if something else already unlocked it
					//note : locking a unit does not currently prevent it from appearing in the production list if already unlocked before
					for (var ii in effect.what)
					{G.getUnit(effect.what[ii]).unlocked=reverse;}
				}
				else */if (oneTime && effect.type=='provide res')
				{
					for (var ii in effect.what)
					{G.getRes(ii).amount+=(reverse?-1:1)*effect.what[ii];}
				}
				else if (!reverse && effect.type=='show res')//no reverse
				{
					for (var ii in effect.what)
					{G.getRes(effect.what[ii]).visible=true;}
				}
				else if (!reverse && effect.type=='show context')//no reverse
				{
					for (var ii in effect.what)
					{G.contextVisibility[effect.what[ii]]=true;}
				}
				else if (!reverse && effect.type=='set name')//no reverse
				{
					for (var ii in effect.what)
					{G.getUnit(effect.what[ii]).displayName=effect.value;}
				}
				else if (effect.type=='enable mode')
				{
					for (var ii in effect.what)
					{G.getUnit(effect.what[ii]).modes[effect.mode].disabled=(reverse?effect.value:!effect.value);}
				}
				else if (!reverse && effect.type=='make part of')//no reverse
				{
					for (var ii in effect.what)
					{G.makePartOf(effect.what[ii],effect.parent);}
				}
				else if (effect.type=='allow' || effect.type=='disallow')
				{
					var effectiveReverse=reverse;
					if (effect.type=='disallow') effectiveReverse=!effectiveReverse;
					for (var ii in effect.what)
					{
						if (effect.what[ii]=='shore exploring') G.allowShoreExplore=!effectiveReverse;
						else if (effect.what[ii]=='ocean exploring') G.allowOceanExplore=!effectiveReverse;
					}
				}
				else if (!reverse && effect.type=='function')//no reverse
				{
					//custom functions; don't get too crazy
					if (effect.funcs)
					{
						for (var ii in effect.funcs)
						{effect.funcs[ii](me);}
					}
					else effect.func(me);
				}
			}
		}
	}
	
	/*=====================================================================================
	TOOLTIPS, DIALOGUES, WIDGETS & GIZMOS
	=======================================================================================*/
	//tooltips : call G.addTooltip(element,function returning text) on an element to have it show a little infobox whenever the mouse hovers over it
	G.tooltip={};
	G.tooltip.init=function()
	{
		this.l=l('tooltip');
		this.lAnchor=l('tooltipAnchor');
		this.offX=0;
		this.offY=0;
		this.T=0;
		this.func=0;
		this.parent=0;
		this.anchor='top';
		this.behavior='fade';//pop/fade/none
		this.linked=0;
		this.closing=true;
		this.text='';
	}
	G.addTooltip=function(el,func,obj)
	{
		//add a tooltip to an element
		//when the mouse hovers over the element, display a tooltip above it populated by func (which must return a string)
		AddEvent(el,'mouseover',function(el,func,tooltip,obj){return function(e){tooltip.func=func;tooltip.parent=el;tooltip.popup(obj);};}(el,func,G.tooltip,obj||{}));
		AddEvent(el,'mouseout',function(el,func,tooltip){return function(e){tooltip.close();};}(el,func,G.tooltip));
	}
	G.tooltip.popup=function(obj)
	{
		var me=this;
		me.offX=0;
		me.offY=0;
		me.linked=0;
		me.anchor='top';
		me.behavior='fade';
		if (me.closing) me.T=0;//reset timer
		me.closing=false;
		me.lAnchor.style.opacity='0';
		me.lAnchor.style.display='block';
		for (var i in obj) {me[i]=obj[i];}
		me.refresh();
	}
	G.tooltip.update=function()
	{
		var me=this;
		var time=3;//how many frames to open and close
		if (me.T<time) me.T++;
		var parentExists=l(me.parent.id);
		if (me.T==time && (me.closing || !parentExists))
		{
			me.lAnchor.style.display='none';
			me.l.innerHTML='';
			me.func=0;
			me.parent=0;
			me.anchor='top';
			me.behavior='fade';
			me.linked=0;
		}
		else if (parentExists)//tooltip is currently active and focused on an element
		{
			//position and scale tooltip
			var t=(me.T/time);
			if (me.closing) t=1-t;
			t=(3*Math.pow(t,2)-2*Math.pow(t,3));
			var x1=0,x2=0,y1=0,y2=0,s1=0,s2=1;
			var bounds=me.parent.getBoundingClientRect();
			
			//measure and fit in screen
			var dimensions={
				top:me.l.offsetTop,
				right:me.l.offsetLeft+me.l.offsetWidth,
				bottom:me.l.offsetTop+me.l.offsetHeight,
				left:me.l.offsetLeft,
				width:me.l.offsetWidth,
				height:me.l.offsetHeight
			};
			
			var anchor=me.anchor;
			var behavior=me.behavior;
			var offX=me.offX;
			var offY=me.offY;
			var styleTransform='';
			var styleTop='';
			var styleLeft='';
			
			for (var step=0;step<3;step++)//this is probably an awkward way of doing this
			{
				//this used to be handled with mostly just CSS. let's just say things didn't go as expected
				if (anchor=='top')
				{
					x1=(bounds.left+bounds.right)/2;x2=x1+offX;
					y1=bounds.top;y2=y1+offY;
					styleTransform='translate(0,-100%)';
					styleTop='auto';
					styleLeft='-50%';
				}
				else if (anchor=='bottom')
				{
					x1=(bounds.left+bounds.right)/2;x2=x1+offX;
					y1=bounds.bottom;y2=y1+offY;
					styleTransform='translate(0,0)';
					styleTop='auto';
					styleLeft='-50%';
				}
				else if (anchor=='left')
				{
					x1=bounds.left;x2=x1+offX;
					y1=(bounds.top+bounds.bottom)/2;y2=y1+offY;
					styleTransform='translate(-100%,0)';
					styleTop=(-dimensions.height/2)+'px';
					styleLeft='auto';
				}
				else if (anchor=='right')
				{
					x1=bounds.right;x2=x1+offX;
					y1=(bounds.top+bounds.bottom)/2;y2=y1+offY;
					styleTransform='translate(0,0)';
					styleTop=(-dimensions.height/2)+'px';
					styleLeft='auto';
				}
				
				if (step==0)//toggle on the same axis
				{
					if (anchor=='left' && x2-dimensions.width<0) {anchor='right';offX=-offX;}
					else if (anchor=='right' && x2+dimensions.width>=G.w) {anchor='left';offX=-offX;}
					else if (anchor=='top' && y2-dimensions.height<0) {anchor='bottom';offY=-offY;}
					else if (anchor=='bottom' && y2+dimensions.height>=G.h) {anchor='top';offY=-offY;}
				}
				else if (step==1)//still no room? switch axis
				{
					if (anchor=='left' && x2-dimensions.width<0) {anchor='bottom';var tmp=offX;offX=offY;offY=tmp;}
					else if (anchor=='right' && x2+dimensions.width>=G.w) {anchor='bottom';var tmp=offX;offX=offY;offY=tmp;}
					else if (anchor=='top' && y2-dimensions.height<0) {anchor='right';var tmp=offX;offX=offY;offY=tmp;}
					else if (anchor=='bottom' && y2+dimensions.height>=G.h) {anchor='right';var tmp=offX;offX=offY;offY=tmp;}
				}
				else//stick to the sides of the screen
				{
					if (anchor=='top' || anchor=='bottom')
					{if (x2-dimensions.width/2<0) x2=dimensions.width/2;
					else if (x2+dimensions.width/2>=G.w) x2=G.w-dimensions.width/2;}
					else if (anchor=='left' || anchor=='right')
					{if (y2-dimensions.height/2<0) y2=dimensions.height/2;
					else if (y2+dimensions.height/2>=G.h) y2=G.h-dimensions.height/2;}
				}
			}
			
			me.l.style.transform=styleTransform;
			me.l.style.top=styleTop;
			me.l.style.left=styleLeft;
				
			var x=Math.round(t*x2+(1-t)*x1);
			var y=Math.round(t*y2+(1-t)*y1);
			
			var s=1;
			var o=1;
			if (behavior=='pop') s=(t*s2+(1-t)*s1);
			if (behavior=='fade') o=t;
			me.lAnchor.style.transform='scale('+s+')';
			me.lAnchor.style.opacity=o;
			me.lAnchor.style.left=x+'px';
			me.lAnchor.style.top=y+'px';
			if (me.closeOnMouseUp && G.mouseUp) me.close();
		}
	}
	G.tooltip.refresh=function()
	{
		if (this.parent)
		{
			this.text=this.func();
			this.l.innerHTML=this.text;
		}
	}
	G.tooltip.close=function()
	{
		this.T=0;
		this.closing=true;
	}
	
	
	//dialogues : popups that show up in the middle of the screen and darken everything behind them; used for menus, confirmation prompts, important events etc
	//there can be multiple dialogues at once, the latest one taking priority and displaying above the others
	G.dialogue={};
	G.dialogue.init=function()
	{
		this.l=l('dialogues');
		this.l.innerHTML='';
		this.n=0;
		this.l.classList.remove('on');
	}
	G.dialogue.popup=function(func,classes,from)
	{
		//open a new dialogue containing text returned by func
		//func can have G.pushCallback() calls and can manipulate its one argument, representing the dialogue's element
		//"classes" is added to the dialogue's CSS classes
		//if an element "from" is specified, do some popupsquares
		if (G.getSetting('pauseOnMenus')) G.setSetting('forcePaused',1);
		G.tooltip.close();
		var outer=document.createElement('div');outer.className='fullCenteredOuter';outer.style.height='100%';outer.style.position='absolute';
		var inner=document.createElement('div');inner.className='fullCenteredInner';inner.style.textAlign='center';outer.appendChild(inner);
		
		var classes=classes?(' '+classes):'';
		
		var div=document.createElement('div');
		var str=G.button({text:'x',classes:'frameless closeButton',onclick:function(){G.dialogue.close();}})+''+func(div);
		div.innerHTML=str;
		
		div.className='dialogue framed bgDark'+classes+(classes.indexOf('noFade')==-1?' fadeIn':'');
		div.id='dialogue-'+this.n;
		inner.appendChild(div);
		this.l.appendChild(outer);
		G.addCallbacks();
		if (this.n==0) this.l.classList.add('on');
		if (from) G.popupSquares.spawn(from,div);
		this.n++;
	}
	G.dialogue.closeAll=function(force)
	{
		var failed=false;
		while(this.n>0 && failed==false)
		{
			failed=G.dialogue.close(force);
		}
	}
	G.dialogue.close=function(force)
	{
		var failed=true;
		//close the most recent one
		if (this.n>0)
		{
			if (force || !this.l.lastChild.firstChild.firstChild.classList.contains('noClose'))//bit gross honestly
			{
				failed=false;
				G.tooltip.close();
				this.l.removeChild(this.l.lastChild);
				this.n--;
				if (this.n<=0)
				{
					this.l.classList.remove('on');
					G.setSetting('forcePaused',0);
				}
			}
		}
		return failed;
	}
	G.dialogue.forceClose=function()
	{
		G.dialogue.close(true);
	}
	G.dialogue.getCloseButton=function(text)
	{
		return G.button({text:(text||'Close'),classes:'frameless',onclick:function(){G.dialogue.close();}});
	}
	
	//widgets : boxes full of options showing up when pressing the mouse down on a button, that disappear when the button is released; used to change unit modes etc
	G.widget={};
	G.widget.init=function()
	{
		this.l=l('widget');
		this.lAnchor=l('widgetAnchor');
		this.offX=0;
		this.offY=0;
		this.T=0;
		this.func=0;
		this.parent=0;
		this.anchor='top';
		this.linked=0;
		this.closing=false;
		this.closeInFrames=0;
	}
	G.widget.popup=function(obj)
	{
		/*
			example use :
			G.widget.popup({
				func:function(widget){widget.l.innerHTML=widget.linked.name;},//function called to populate the widget when it appears
				offX:0,//horizontal offset
				offY:0,//vertical offset
				anchor:'top',//where the widget should align on the parent
				parent:div,//parent element, ideally the element that was clicked to summon it
				linked:obj//any object the widget should remember
			});
		*/
		G.tooltip.close();
		this.offX=0;
		this.offY=0;
		this.closeOnMouseUp=false;
		this.closing=false;
		this.linked=0;
		this.closeInFrames=0;
		this.T=0;//reset timer
		this.lAnchor.style.display='none';
		for (var i in obj) {this[i]=obj[i];}
		this.func(this,this.linked);
	}
	G.widget.update=function()
	{
		var me=this;
		var time=3;//how many frames to open and close
		if (me.T<time) me.T++;
		if (me.T==time && me.closing)
		{
			me.lAnchor.style.display='none';
			me.l.innerHTML='';
			me.func=0;
			me.parent=0;
			me.anchor='top';
			me.linked=0;
		}
		else if (me.parent)//widget is currently active and focused on an element
		{
			//position and scale widget
			var t=(me.T/time);
			if (me.closing) t=1-t;
			t=(3*Math.pow(t,2)-2*Math.pow(t,3));
			var x1=0,x2=0,y1=0,y2=0,s1=0,s2=1;
			var bounds=me.parent.getBoundingClientRect();
			
			//measure and fit in screen
			var dimensions={
				top:me.l.offsetTop,
				right:me.l.offsetLeft+me.l.offsetWidth,
				bottom:me.l.offsetTop+me.l.offsetHeight,
				left:me.l.offsetLeft,
				width:me.l.offsetWidth,
				height:me.l.offsetHeight
			};
			
			var anchor=me.anchor;
			var behavior='pop';//me.behavior;
			var offX=me.offX;
			var offY=me.offY;
			var styleTransform='';
			var styleTop='';
			var styleLeft='';
			
			for (var step=0;step<3;step++)//this is probably an awkward way of doing this
			{
				//this used to be handled with mostly just CSS. let's just say things didn't go as expected
				if (anchor=='top')
				{
					x1=(bounds.left+bounds.right)/2;x2=x1+offX;
					y1=bounds.top;y2=y1+offY;
					styleTransform='translate(0,-100%)';
					styleTop='auto';
					styleLeft='-50%';
				}
				else if (anchor=='bottom')
				{
					x1=(bounds.left+bounds.right)/2;x2=x1+offX;
					y1=bounds.bottom;y2=y1+offY;
					styleTransform='translate(0,0)';
					styleTop='auto';
					styleLeft='-50%';
				}
				else if (anchor=='left')
				{
					x1=bounds.left;x2=x1+offX;
					y1=(bounds.top+bounds.bottom)/2;y2=y1+offY;
					styleTransform='translate(-100%,0)';
					styleTop=(-dimensions.height/2)+'px';
					styleLeft='auto';
				}
				else if (anchor=='right')
				{
					x1=bounds.right;x2=x1+offX;
					y1=(bounds.top+bounds.bottom)/2;y2=y1+offY;
					styleTransform='translate(0,0)';
					styleTop=(-dimensions.height/2)+'px';
					styleLeft='auto';
				}
				
				if (step==0)//toggle on the same axis
				{
					if (anchor=='left' && x2-dimensions.width<0) {anchor='right';offX=-offX;}
					else if (anchor=='right' && x2+dimensions.width>=G.w) {anchor='left';offX=-offX;}
					else if (anchor=='top' && y2-dimensions.height<0) {anchor='bottom';offY=-offY;}
					else if (anchor=='bottom' && y2+dimensions.height>=G.h) {anchor='top';offY=-offY;}
				}
				else if (step==1)//still no room? switch axis
				{
					if (anchor=='left' && x2-dimensions.width<0) {anchor='bottom';var tmp=offX;offX=offY;offY=tmp;}
					else if (anchor=='right' && x2+dimensions.width>=G.w) {anchor='bottom';var tmp=offX;offX=offY;offY=tmp;}
					else if (anchor=='top' && y2-dimensions.height<0) {anchor='right';var tmp=offX;offX=offY;offY=tmp;}
					else if (anchor=='bottom' && y2+dimensions.height>=G.h) {anchor='right';var tmp=offX;offX=offY;offY=tmp;}
				}
				else//stick to the sides of the screen
				{
					if (anchor=='top' || anchor=='bottom')
					{if (x2-dimensions.width/2<0) x2=dimensions.width/2;
					else if (x2+dimensions.width/2>=G.w) x2=G.w-dimensions.width/2;}
					else if (anchor=='left' || anchor=='right')
					{if (y2-dimensions.height/2<0) y2=dimensions.height/2;
					else if (y2+dimensions.height/2>=G.h) y2=G.h-dimensions.height/2;}
				}
			}
			
			me.l.style.transform=styleTransform;
			me.l.style.top=styleTop;
			me.l.style.left=styleLeft;
				
			var x=Math.round(t*x2+(1-t)*x1);
			var y=Math.round(t*y2+(1-t)*y1);
			
			var s=1;
			var o=1;
			if (behavior=='pop') s=(t*s2+(1-t)*s1);
			if (behavior=='fade') o=t;
			me.lAnchor.style.transform='scale('+s+')';
			me.lAnchor.style.opacity=o;
			me.lAnchor.style.left=x+'px';
			me.lAnchor.style.top=y+'px';
			me.lAnchor.style.display='block';
			if (me.closeOnMouseUp && G.mouseUp) me.close();
		}
		if (me.closeInFrames)
		{
			me.closeInFrames--;
			if (me.closeInFrames==0) me.close();
		}
	}
	G.widget.refresh=function()
	{
		this.func(this,this.linked);
	}
	G.widget.close=function(inFrames)
	{
		//by setting inFrames, you can schedule the tooltip to close in that many frames instead of instantly
		if (inFrames)
		{
			this.closeInFrames=inFrames;
		}
		else
		{
			this.T=0;
			this.closing=true;
		}
	}
	
	
	//info popup - lets you add info to an element with G.addInfo(element,function returning text); the text will be displayed in a box on the right whenever the mouse is on the element
	//NOTE : the info popup system has been replaced with tooltips, as having a popup show on the far-right of the screen is rather strenuous on the eye; this is still left in just in case
	G.infoPopup={};
	G.infoPopup.init=function()
	{
		this.l=l('infoPopup');
		this.T=0;
		this.on=false;
		this.func=0;
	}
	G.infoPopup.popup=function(obj,el)
	{
		var me=this;
		me.l.innerHTML=me.func();
		me.on=true;
		me.l.style.display='block';
		me.l.style.top=(0)+'%';
		me.l.style.bottom=(0)+'%';
		G.popupSquares.spawn(el,me.l);
	}
	G.infoPopup.close=function()
	{
		this.on=false;
	}
	G.infoPopup.update=function()
	{
		var me=this;
		var dur=5;//how long to transition to fully open
		var buffer=10;//how long to wait before starting to close
		if (me.on && me.T<dur+buffer) me.T++;
		else if (!me.on && me.T>=0)
		{
			me.T--;
			if (me.T==0) me.l.style.display='none';
		}
		var r=Math.pow(Math.min(me.T,dur)/dur,0.5);
		me.l.style.opacity=r;
		me.l.style.top=((1-r)*50)+'%';
		me.l.style.bottom=((1-r)*50)+'%';
	}
	G.addInfo=function(el,func,obj)
	{
		//add info to an element
		//when the mouse hovers over the element, display the info popup and populate it with func (which must return a string)
		AddEvent(el,'mouseover',function(el,func,infoPopup,obj){return function(e){infoPopup.func=func;infoPopup.popup(obj,el);};}(el,func,G.infoPopup,obj||{}));
		AddEvent(el,'mouseout',function(el,func,infoPopup){return function(e){infoPopup.close();};}(el,func,G.infoPopup));
	}
	
	
	//popup squares : with G.popupSquares.spawn(from,to), display 2 hollow rectangles that move and scale at different speeds from the element "from" to the element "to"; this helps contextualize relationships between interface elements
	G.popupSquares={on:false};
	G.popupSquares.spawn=function(from,to)
	{
		if (G.getSetting('animations') && from && to)
		{
			this.l=l('squaresAnchor');
			this.l.style.display='block';
			this.on=true;
			this.T=0;
			var bounds1=from.getBoundingClientRect();
			var bounds2=to.getBoundingClientRect();
			this.x1=bounds1.left;
			this.y1=bounds1.top;
			this.w1=bounds1.width;
			this.h1=bounds1.height;
			this.x2=bounds2.left;
			this.y2=bounds2.top;
			this.w2=bounds2.width;
			this.h2=bounds2.height;
		}
	}
	G.popupSquares.update=function()
	{
		if (this.on)
		{
			var dur=10;
			for (var i=1;i<4;i++)
			{
				var r=this.T/dur;
				if (i==1) r=Math.pow(r,2);
				else if (i==2) r=Math.pow(r,1);
				else if (i==3) r=Math.pow(r,0.5);
				l('square'+i).style.left=(this.x1*(1-r)+this.x2*(r))+'px';
				l('square'+i).style.top=(this.y1*(1-r)+this.y2*(r))+'px';
				l('square'+i).style.width=(this.w1*(1-r)+this.w2*(r))+'px';
				l('square'+i).style.height=(this.h1*(1-r)+this.h2*(r))+'px';
				l('square'+i).style.opacity=Math.pow((r*(1-r)),2)*16;
			}
			this.T++;
			if (this.T>dur)
			{
				this.l.style.display='none';
				this.T=0;
				this.on=false;
			}
		}
	}
	
	
	/*=====================================================================================
	MODDING & LOADING DATA
	=======================================================================================*/
	//data.js and, if applicable, mods, add data (techs, resources, units...) by registering a function with G.AddData; these functions are then called in sequence with G.CreateData when a game is started or launched (note : G.CreateData may be called multiple times per session; data is cleared before each call)
	
	/*
		See /mod.js for an example of a working mod.
		How mods work :
		
			-each mod should be in the form of a .js file containing the following :
			G.AddData({
			name:'Mod test',
				//required; the name of the mod - do not change this when updating the mod, as other mods will refer to this mod by its name
			author:'Orteil',
				//optional; the author of the mod
			desc:'A simple test mod.',
				//optional; a simple description of the mod
			engineVersion:1,
				//optional; the game engine version that was current when the game was released; the mod won't load if this is older than the current game engine, so mod authors should keep this up to date - alternatively, if this value isn't specified, the mod will work no matter the game engine version (be careful, as other incompatibilities and strange behaviors may arise)
			manifest:"http://url",
				//optional; a URL where the mod will look for information about an updated version of itself, which will be called instead when starting a new game
				//see /modManifest.js for an example
			requires:["mod name 1","mod name 2..."],
				//optional; a list of mod names that this mod requires; this mod will fail loading if at least one of its required mods fails to load, has errors, or comes after it in the mod list
				//the specified mod names can be in the form of "mod name*", in which case the game will look for any mod with a name that begins with "mod name"
			func:function()
			{
				//required; the main body of your mod here, where you declare new resources, units, techs and so on; check /data.js for ideas
				//these functions are executed in the same order as they come in the mod list
			}
			});
		
		Mods should not attempt to add settings.
		Custom stylesheets support is planned.
		When updating a mod, you MUST create a new separate mod if your update adds or changes the order of techs, traits, policies, chooseboxes, units, unit modes, terrains, resources or other elements; otherwise, players currently using your mod would load their game to find their data scrambled and buggy.
		Likewise, carelessly modifying the map generation from one update to another may lead to players coming back to their game with most of their territory in the ocean.
		Updating things such as flavor text, icons, and individual values (such as how many resources a unit gathers every tick) is usually safe, but do pay mind to how your changes might effect the games of people currently playing your mod.
		The modding system is still a work in progress, and features may be added and changed.
	*/
	
	G.mods=[];
	G.modsByScript=[];
	G.modsByName=[];
	G.manifests=[];
	G.manifestsByScript=[];
	G.manifestsByName=[];
	G.modLoadT=0;
	G.whenDoneLoadingMods=0;
	G.checkManifests=false;
	G.oldestEngineVersionNeeded=-1;
	G.LoadMods=function(mods,whenDone,checkManifests)
	{
		//remove loaded scripts and manifests first
		for (var i in G.mods)
		{
			if (G.mods[i].loaded)
			{
				var script=l('dataScript-'+G.mods[i].id)||0;
				if (script) script.parentNode.removeChild(script);
			}
		}
		for (var i in G.manifests)
		{
			if (G.manifests[i].loaded)
			{
				var script=l('manifestScript-'+G.manifests[i].id)||0;
				if (script) script.parentNode.removeChild(script);
			}
		}
		
		G.mods=[];
		G.modsByScript=[];
		G.modsByName=[];
		G.manifests=[];
		G.manifestsByScript=[];
		G.manifestsByName=[];
		G.modLoadT=0;
		G.oldestEngineVersionNeeded=-1;
		
		G.checkManifests=checkManifests;
		
		G.Reset();
		l('blackBackground').style.opacity=1;
		
		G.sequence='loading';
		G.whenDoneLoadingMods=whenDone;//should be a function that runs when its argument is "true"
		
		var n=0;
		for (var i in mods)
		{
			G.mods[n]={url:mods[i],loaded:false,executed:false,id:n,error:'',updated:false};
			n++;
		}
		console.log('Loading '+n+' mod'+(n==1?'':'s')+'.');
		
		for (var i in G.mods)
		{
			var mod=G.mods[i];
			//console.log('Now attempting to load mod at URL "'+mod.url+'".');
			var script=document.createElement('script');
			script.id='dataScript-'+mod.id;
			G.modsByScript['dataScript-'+mod.id]=mod;
			script.setAttribute('src',mod.url+'?r='+Math.random());//we add a random bit to the URL to prevent caching
			script.onload=function(mod,script){return function(){G.ModLoaded(mod,script);}}(mod,'dataScript-'+mod.id);
			document.head.appendChild(script);
		}
		
		G.dialogue.closeAll(true);
		G.ModLoadingDialogue();
	}
	G.ModLoaded=function(mod,id)
	{
		//console.log('Mod loaded : "'+mod.url+'".');
		mod.loaded=true;
		/*setTimeout(function(mod){return function()
		{
			console.log('Mod loaded : "'+mod.url+'".');
			mod.loaded=true;
		}}(mod),1000+mod.id*1000);*/
	}
	G.LogicModLoading=function()
	{
		if (G.modLoadT%10==0)
		{
			G.dialogue.closeAll(true);
			G.ModLoadingDialogue();
		}
		if (G.sequence=='loading')
		{
			var done=true;
			for (var i in G.mods)
			{
				if (!G.mods[i].loaded) done=false;
			}
			if (G.modLoadT>=G.fps*10) {G.dialogue.closeAll(true);G.sequence='failed loading';G.ModLoadingDialogue();}//timeout after 5 seconds
			
			if (done)//success loading everything!
			{
				G.CheckMods();
			}
		}
		else if (G.sequence=='checking')
		{
			var done=true;
			for (var i in G.mods)
			{
				var mod=G.mods[i];
				if (!mod.executed) done=false;
				if (mod.engineVersion && mod.engineVersion<G.engineVersion)
				{
					mod.error='This mod is too old to function with this engine (mod was built for v'+(mod.engineVersion||1)+', but this engine is v'+G.engineVersion+')';
					done=false;
					if (G.oldestEngineVersionNeeded==-1) G.oldestEngineVersionNeeded=mod.engineVersion||1; else G.oldestEngineVersionNeeded=Math.min(G.oldestEngineVersionNeeded,(mod.engineVersion||1));
				}
				else if (mod.requires)
				{
					for (var ii in mod.requires)
					{
						var requires=mod.requires[ii];
						var found=0;
						if (requires.slice(-1)=='*')
						{
							requires=requires.slice(0,-1);
							for (var iii in G.mods)
							{
								if (G.mods[iii].name.startsWith(requires)) found=G.mods[iii];
							}
						}
						else found=G.modsByName[requires]||0;
						if (!found) {mod.error='This mod requires another mod ("'+mod.requires[ii]+'") which couldn\'t be found.';done=false;}
						else if (found && found.error) {mod.error='This mod requires another mod ("'+mod.requires[ii]+'") but that mod has loading errors.';done=false;}
						else if (found && found.id>mod.id) {mod.error='This mod requires another mod ("'+mod.requires[ii]+'") but that mod comes after this one in the mod list.';done=false;}
					}
				}
			}
			if (done)//success loading everything!
			{
				if (G.checkManifests) G.CheckModManifests();
				else G.whenDoneLoadingMods(true);
			}
		}
		else if (G.sequence=='updating')
		{
			var done=true;
			for (var i in G.mods)
			{
				if (!G.mods[i].updated) done=false;
			}
			for (var i in G.manifests)
			{
				if (!G.manifests[i].loaded) done=false;
			}
			if (G.modLoadT>=G.fps*5) {done=true;console.log('One or more manifests couldn\'t be found; proceeding anyway.');}//timeout after 5 seconds (proceed anyway)
			
			if (done)//success updating everything!
			{
				var mustUpdate=false;
				var newMods=[];
				for (var i in G.mods)
				{
					if (G.mods[i].newURL && G.mods[i].newURL!=G.mods[i].url) {newMods.push(G.mods[i].newURL);mustUpdate=true;}
					else newMods.push(G.mods[i].url);
				}
				if (mustUpdate) console.log('Updating with new mod URLs : '+newMods.join(', '));
				if (mustUpdate) G.UpdateWithModManifests(newMods);
				else G.whenDoneLoadingMods(true);
			}
		}
		G.modLoadT++;
	}
	G.CheckMods=function()
	{
		console.log('Done loading mods, now checking for compatibility.');
		G.sequence='checking';
		G.modLoadT=0;
	}
	G.CheckModManifests=function()
	{
		console.log('Done checking mods, now checking manifests.');
		G.sequence='updating';
		G.modLoadT=0;
		
		var manifests=[];
		
		for (var i in G.mods)
		{
			var mod=G.mods[i];
			if (mod.manifest)
			{
				mod.error='Checking manifest...';
				if (!manifests.includes(mod.manifest)) manifests.push(mod.manifest);
			}
			else
			{
				mod.error='No manifest to check.';
				mod.updated=true;
			}
		}
		
		var n=0;
		for (var i in manifests)
		{
			G.manifests[n]={url:manifests[i],loaded:false,executed:false,id:n};
			n++;
		}
		console.log('Loading '+n+' manifest'+(n==1?'':'s')+'.');
		
		for (var i in G.manifests)
		{
			var manifest=G.manifests[i];
			//console.log('Now attempting to load manifest at URL "'+manifest.url+'".');
			var script=document.createElement('script');
			script.id='manifestScript-'+manifest.id;
			G.manifestsByScript['manifestScript-'+manifest.id]=mod;
			script.setAttribute('src',manifest.url);
			script.onload=function(manifest,script){return function(){G.ManifestLoaded(manifest,script);}}(manifest,'manifestScript-'+manifest.id);
			document.head.appendChild(script);
		}
	}
	G.ManifestLoaded=function(manifest,id)
	{
		//console.log('Manifest loaded : "'+manifest.url+'".');
		manifest.loaded=true;
		/*setTimeout(function(manifest){return function()
		{
			console.log('Manifest loaded : "'+manifest.url+'".');
			manifest.loaded=true;
		}}(manifest),1000+manifest.id*1000);*/
	}
	G.UpdateWithModManifests=function(mods)
	{
		G.NewGame(false,mods);
	}
	G.ModLoadingDialogue=function()
	{
		G.dialogue.popup(function(div){
			var str='<div style="padding:16px;width:480px;"><div class="fancyText title">Loading data</div>';
			var errors=0;
			for (var i in G.mods)
			{
				var mod=G.mods[i];
				var name='';
				var status='';
				if (G.sequence=='loading' || G.sequence=='failed loading') {name=mod.url;status=(mod.loaded?'<span style="color:#3f0;">loaded</span>':'<span style="color:#f30;">loading</span>');}
				else if (G.sequence=='checking') {name=mod.name||mod.url;status=(mod.error==0?'<span style="color:#3f0;">checked</span>':('<span style="color:#f30;">'+mod.error+'</span>'));}
				else if (G.sequence=='updating') {name=mod.name;status=(mod.error==0?'<span style="color:#3f0;">updated</span>':('<span style="color:#ccc;">'+mod.error+'</span>'));}
				str+='<div style="padding:2px;">[ '+name+' ... '+status+' ]</div>';
				if (mod.error) errors++;
			}
			if (G.sequence=='checking' && G.oldestEngineVersionNeeded!=-1 && G.versionsById && G.versionsById[G.oldestEngineVersionNeeded])
			{
				str+='<div style="margin-top:16px;">Looks like you\'ll need an older version of the game to load the selected mods.<br>Luckily, that version is still accessible here : <br><br>'+G.button({text:'Load version '+G.oldestEngineVersionNeeded/*,tooltip:'Reload and redirect to an older version to properly load the mods.'*/,onclick:function(version){return function(){window.location.href=version.url;};}(G.versionsById[G.oldestEngineVersionNeeded])})+'</div>';
			}
			else if (G.sequence=='failed loading' || (G.sequence=='checking' && errors>0)) str+='<div style="margin-top:16px;">Drat! Looks like something went wrong when loading data.<br>This may fix itself if you reload the page.<br>If this persists, you can always attempt to start a new game and pick different mods.<br><br>'+G.button({text:'New game',tooltip:'Start a new game',onclick:function(){G.dialogue.popup(function(div){G.dialogue.close();G.NewGame();});}})+'</div>';
			else
			{str+='<div style="background:url(img/loadingBar.png);height:8px;position:absolute;bottom:0px;left:0px;right:0px;animation:driftRight 20s linear infinite;"></div>';}
			str+='</div>';
			return str;
		},'noClose noFade');
	}
	
	G.DeclareManifest=function(obj)
	{
		//function called by manifests
		var manifest=G.manifestsByScript[document.currentScript.id];
		for (var i in obj)
		{
			manifest[i]=obj[i];
		}
		if (manifest.updates)
		{
			for (var i in manifest.updates)
			{
				var mod=i;
				var update=manifest.updates[i];
				if (mod.slice(-1)=='*')
				{
					mod=mod.slice(0,-1);
					for (var ii in G.mods)
					{
						if (G.mods[ii].name.startsWith(mod)) {G.mods[ii].newURL=update;G.mods[ii].updated=true;}
					}
				}
				else if (G.modsByName[mod]) {G.modsByName[mod].newURL=update;G.modsByName[mod].updated=true;}
			}
		}
	}
	
	G.AddData=function(obj)
	{
		//function called by mods
		var mod=G.modsByScript[document.currentScript.id];
		for (var i in obj)
		{
			mod[i]=obj[i];
		}
		if (!mod['name'] && !mod['func'])
		{mod.error='This mod is lacking a name and a function.';}
		else if (!mod['name']) {mod.error='This mod is lacking a name.';}
		else if (mod['name'].slice(-1)=='*') {mod.error='This mod\'s name cannot end with *.';}
		else if (!mod['func']) {mod.error='This mod is lacking a function.';}
		else
		{
			mod.executed=true;
			G.modsByName[mod.name]=mod;
		}
	}
	G.CreateData=function()
	{
		//cleanse all data first
		G.dict=[];
		G.res=[];
		G.resByName=[];
		G.resCategories=[];
		G.unit=[];
		G.unitByName=[];
		G.unitCategories=[];
		G.policy=[];
		G.policyByName=[];
		G.policyCategories=[];
		G.know=[];
		G.knowByName=[];
		G.knowCategories=[];
		G.tech=[];
		G.techByName=[];
		G.techByTier=[];
		G.trait=[];
		G.traitByName=[];
		G.traitByTier=[];
		G.goods=[];
		G.goodsByName=[];
		G.land=[];
		G.landByName=[];
		G.achiev=[];
		G.achievByName=[];
		G.achievByTier=[];
		G.legacyBonuses=[];
		G.chooseBox=[];
		G.contextNames=[];
		G.contextVisibility=[];
		
		G.funcs=[];//keyed array; store functions tied to hard-coded events in here
		G.props=[];//keyed array; store anything you want in here
		
		G.context=0;
		G.sheets={};//icon sheets added by mods
		//create new data
		for (var i in G.mods)
		{
			G.context=G.mods[i];
			if (G.mods[i].sheets)
			{
				for (var ii in G.mods[i].sheets)
				{
					G.sheets[ii]=G.mods[i].sheets[ii];
				}
			}
			G.mods[i].func();
		}
		G.context=0;
		
		//cache some stuff
		G.cacheMetaResources();
		
		var newBonuses={};
		for (var i in G.legacyBonuses)
		{
			var me=G.legacyBonuses[i];
			newBonuses[me.id]=me;
		}
		G.legacyBonuses=newBonuses;
		
		for (var i in G.unit)
		{
			G.unit[i].modesById=[];
			var index=0;
			for (var ii in G.unit[i].modes)
			{
				var mode=G.unit[i].modes[ii];
				G.unit[i].modesById[index]=mode;
				mode.id=ii;
				mode.num=index;
				mode.use=mode.use||{};
				index++;
			}
		}
		
		for (var i in G.policy)
		{
			G.policy[i].modesById=[];
			var index=0;
			for (var ii in G.policy[i].modes)
			{
				var mode=G.policy[i].modes[ii];
				G.policy[i].modesById[index]=mode;
				mode.id=ii;
				mode.num=index;
				index++;
			}
		}
		
		for (var i in G.know)
		{
			var me=G.know[i];
			me.leadsTo=[];
			me.precededBy=[];
		}
		for (var i in G.know)
		{
			var me=G.know[i];
			for (var ii in me.req)
			{
				var req=G.getDict(ii);
				if (me.req[ii] && req && (req.type=='tech' || req.type=='trait'))
				{
					G.getKnow(ii).leadsTo.push(me);
					me.precededBy.push(G.getKnow(ii));
				}
				if (!req) console.log('ERROR : '+me.name+' has "'+ii+'" as a requirement, but no such thing was found');
			}
		}
		
		//create tiers
		var getTier=function(me)
		{
			var tier=0;
			for (var i in me.req)
			{
				var req=G.getDict(i);
				if (me.req[i] && req && req.type==me.type)
				{
					tier=Math.max(tier,req.tier||Math.max(getTier(req)));
				}
			}
			me.tier=tier+1;
			return me.tier;
		}
		for (var i in G.know)
		{
			var me=G.know[i];
			getTier(me);
			if (me.type=='tech')
			{
				if (!G.techByTier[me.tier]) G.techByTier[me.tier]=[];
				G.techByTier[me.tier].push(me);
			}
			else if (me.type=='trait')
			{
				if (!G.traitByTier[me.tier]) G.traitByTier[me.tier]=[];
				G.traitByTier[me.tier].push(me);
			}
		}
		
		//compute combined research costs
		if (true)
		{
			G.techByTier=[];
			G.traitByTier=[];
			for (var i in G.know)
			{
				var me=G.know[i];me.tier=0;
			}
			var getAncestors=function(me)
			{
				var out=[me];
				for (var i in me.req)
				{
					var req=G.getDict(i);
					if (me.req[i] && req && req.type==me.type)
					{
						out=out.concat(getAncestors(req));
					}
				}
				return out;
			}
			for (var i in G.know)
			{
				var me=G.know[i];
				me.ancestors=getAncestors(me);
				me.ancestors=me.ancestors.filter(function(elem,index,self){return index==self.indexOf(elem);})//remove duplicates
				for (var ii in me.ancestors)
				{
					for (var iii in me.ancestors[ii].cost)
					{
						me.tier+=me.ancestors[ii].cost[iii];
					}
				}
			}
			for (var i in G.know)
			{
				var me=G.know[i];
				if (me.type=='tech')
				{
					if (!G.techByTier[me.tier]) G.techByTier[me.tier]=[];
					G.techByTier[me.tier].push(me);
				}
				else if (me.type=='trait')
				{
					if (!G.traitByTier[me.tier]) G.traitByTier[me.tier]=[];
					G.traitByTier[me.tier].push(me);
				}
			}
		}
		
		
		for (var i in G.achiev)
		{
			var me=G.achiev[i];
			if (me.fromUnit)
			{
				var unit=G.getUnit(me.fromUnit);
				if (!me.desc) me.desc=unit.desc;
				if (me.icon[0]==0 && me.icon[1]==0) me.icon=unit.icon;
				if (!me.wideIcon && unit.wideIcon) me.wideIcon=unit.wideIcon;
			}
		}
		
		if (false && G.mods.length>0)
		{
			console.log('Data created.\n'+
				'   -'+G.res.length+' resources\n'+
				'   -'+G.unit.length+' units\n'+
				'   -'+G.tech.length+' technologies\n'+
				'   -'+G.trait.length+' cultural traits\n'+
				'   -'+G.policy.length+' policies\n'+
				'   -'+G.land.length+' terrains\n'+
				'   -'+G.goods.length+' terrain goods\n'+
				'   -'+G.achiev.length+' achievements\n'+
				'');
		}
	}
	
	/*=====================================================================================
	LOGIC
	=======================================================================================*/
	G.tick=0;
	G.nextTick=0;
	G.tickDuration=30;
	G.nextFastTick=G.tickDuration;
	G.speed=0;
	G.oldSpeed=0;
	G.Logic=function(forceTick)
	{
		//forceTick lets us execute logic and force a tick update

		if (G.sequence=='loading' || G.sequence=='checking' || G.sequence=='updating')
		{
			var done=G.LogicModLoading();
		}
		else if (G.sequence=='main')
		{
			G.oldSpeed=G.speed;
			G.speed=1;
			if (G.getSetting('fast')) G.speed=2;
			if (G.getSetting('paused')) G.speed=0;
			if (G.getSetting('forcePaused')) G.speed=0;
			if (forceTick) G.speed=1;
			
			if (G.speed==0)
			{
				//accumulate fast ticks when paused
				G.nextFastTick--;
				if (G.nextFastTick<=0) {G.fastTicks++;G.nextFastTick=G.tickDuration;}
			}
			
			if (G.oldSpeed!=G.speed)
			{
				if (G.speed==1)
				{
					G.wrapl.classList.remove('speed0');
					G.wrapl.classList.add('speed1');
					G.wrapl.classList.remove('speed2');
				}
				else if (G.speed==2)
				{
					G.wrapl.classList.remove('speed0');
					G.wrapl.classList.remove('speed1');
					G.wrapl.classList.add('speed2');
				}
				else
				{
					G.wrapl.classList.add('speed0');
					G.wrapl.classList.remove('speed1');
					G.wrapl.classList.remove('speed2');
				}
			}
			
			if (G.T>0 && G.oldSpeed!=G.speed)
			{
				if (G.speed==0)//just paused
				{
					l('foreground').style.display='block';
					G.middleText('- Pause -<br><small>Press space to unpause</small>');
				}
				else if (G.oldSpeed==0)//just unpaused
				{
					l('foreground').style.display='none';
					if (G.T>0) G.middleText('- Unpaused -');
				}
				else if (G.speed==1)
				{
					G.middleText('- Speed x1 -');
				}
				else if (G.speed==2)
				{
					G.middleText('- Speed x30 -');
				}
			}
			
			if (G.speed>0)//not paused
			{
				if (G.nextTick<=0 || forceTick)
				{
					if (G.speed==2)
					{
						//use up fast ticks when on fast speed
						G.fastTicks--;
						if (G.fastTicks<=0) {G.fastTicks=0;G.speed=1;G.setSetting('fast',0);}
					}
					G.logic['res']();
					G.logic['unit']();
					G.logic['land']();
					G.logic['tech']();
					G.logic['trait']();
					
					//exploring
					var map=G.currentMap;
					var updateMap=false;
					if (G.exploreOwnedTiles && map.tilesByOwner[1].length>0)
					{
						G.exploreOwnedTiles=randomFloor(G.exploreOwnedTiles);
						for (var i=0;i<G.exploreOwnedTiles;i++)
						{
							var tile=choose(map.tilesByOwner[1]);
							if (tile.explored<1)
							{
								tile.explored+=0.01;
								tile.explored=Math.min(tile.explored,1);
								G.tileToRender(tile);
								updateMap=true;
							}
						}
					}
					if (G.exploreNewTiles && map.tilesByOwner[1].length>0)
					{
						G.exploreNewTiles=randomFloor(G.exploreNewTiles);
						for (var i=0;i<G.exploreNewTiles;i++)
						{
							var dirs=[];
							var tile=choose(map.tilesByOwner[1]);
							var fromLand=true;
							if (tile.land.ocean) fromLand=false;
							if (fromLand || G.allowShoreExplore)
							{
								if (tile.x>0 && map.tiles[tile.x-1][tile.y].explored==0) dirs.push([-1,0]);
								if (tile.x<map.w-1 && map.tiles[tile.x+1][tile.y].explored==0) dirs.push([1,0]);
								if (tile.y>0 && map.tiles[tile.x][tile.y-1].explored==0) dirs.push([0,-1]);
								if (tile.y<map.h-1 && map.tiles[tile.x][tile.y+1].explored==0) dirs.push([0,1]);
								if (dirs.length>0)
								{
									var dir=choose(dirs);
									tile=map.tiles[tile.x+dir[0]][tile.y+dir[1]];
									var isShore=false;
									if (tile.land.ocean && fromLand) isShore=true;
									if (G.allowOceanExplore || !tile.land.ocean || isShore)
									{
										tile.owner=1;
										tile.explored+=0.1;
										G.tileToRender(tile);
										updateMap=true;
										G.doFuncWithArgs('found tile',[tile]);
									}
								}
							}
						}
					}
					if (updateMap)
					{
						G.updateMapForOwners(map);
						//G.mapToRefresh=true;
					}
					G.exploreOwnedTiles=0;
					G.exploreNewTiles=0;
					
					
					G.tickChooseBoxes();
					G.nextTick=(G.speed==1?G.tickDuration:1);
					G.tick++;
					if (G.day>0 || G.tick>1) {G.day++;G.totalDays++;G.furthestDay=Math.max(G.furthestDay,G.day+G.year*300);G.doFunc('new day');}
					if (G.day>300) {G.day=0;G.year++;G.doFunc('new year');}
					l('date').innerHTML='Year '+(G.year+1)+', day '+(G.day+1)+' in '+G.getName('civ');
				}
				if (!forceTick) G.nextTick--;
			}
			
			l('fastTicks').innerHTML=G.BT(G.fastTicks);
			
			if (G.getSetting('autosave') && G.T%(G.fps*60)==(G.fps*60-1)) G.Save();
		}
		
		if (G.mapToRefresh) G.refreshMap(G.currentMap);
		if (G.mapToRedraw) G.redrawMap(G.currentMap);
		
		if (G.shouldRunReqs)
		{
			G.runUnitReqs();
			G.runPolicyReqs();
			G.update['unit']();
			G.shouldRunReqs=0;
		}
		
		G.logicMapDisplay();
		G.widget.update();
		if (G.T%5==0) G.tooltip.refresh();
		G.tooltip.update();
		G.infoPopup.update();
		G.popupSquares.update();
		G.updateMessages();
		
		//keyboard shortcuts
		if (G.keysD[27]) {G.dialogue.close();}//esc
		if (G.sequence=='main')
		{
			if (G.keys[17] && G.keysD[83]) {G.Save();}//ctrl-s
			if (G.keysD[32])//space
			{
				if (G.getSetting('paused')) G.setSetting('paused',0);
				else G.setSetting('paused',1)
			}
		}
		
		G.logic['particles']();
		
		if (G.T%5==0 && G.resizing) {G.stabilizeResize();}
		
		if (G.mouseUp) G.mousePressed=false;
		G.mouseDown=false;
		G.mouseUp=false;
		if (G.mouseMoved && G.mousePressed) G.draggedFrames++; else if (!G.mousePressed) G.draggedFrames=0;
		G.mouseMoved=0;
		G.Scroll=0;
		G.clickL=0;
		G.keysD=[];
		G.keysU=[];
		if (document.activeElement.nodeName=='TEXTAREA' || document.activeElement.nodeName=='INPUT') G.keys=[];
		
		G.T++;
	}
	
	G.Draw=function()
	{
		if (G.sequence=='main')
		{
			if (G.drawT%2==0)
			{
				G.draw['res']();
				//if (G.tab.id=='unit') G.draw['unit']();
				if (G.tab.update) G.draw[G.tab.update]();
			}
			
			if (G.mapVisible)
			{
				G.resizeMapDisplay();
				if (G.drawT%15==0) G.renderTiles();
			}
		}
		
		G.draw['particles']();
		
		if (G.animIntro)
		{
			var tooFancy=false;
			if (G.T<G.introDur)
			{
				var r=Math.pow(G.T/G.introDur,0.5);
				r=(3*Math.pow(r,2)-2*Math.pow(r,3))
				if (G.getSetting('filters'))
				{
					G.l.style.filter='blur('+((1-r)*5)+'px)';
					G.l.style.webkitFilter='blur('+((1-r)*5)+'px)';
				}
				l('foreground').style.display='block';
				if (G.speed!=0) l('foreground').style.opacity=1-r;
				if (tooFancy) G.l.style.transform='scale('+(0.5+0.5*r)+','+(0.5+0.5*Math.pow(r,0.5))+')';
				G.l.style.opacity=r;
				//if (tooFancy) G.l.style.boxShadow='0px 0px '+Math.floor((1-r)*100+100)+'px #000 inset';
				G.l.style.display='block';
			}
			else
			{
				G.l.style.display='block';
				G.l.style.filter='';
				G.l.style.webkitFilter='';
				if (G.speed!=0) l('foreground').style.display='none';
				l('foreground').style.opacity='1';
				if (tooFancy) G.l.style.transform='';
				G.l.style.opacity='1';
				//if (tooFancy) G.l.style.boxShadow='none';
				G.animIntro=false;
			}
		}
		
		G.drawT++;
	}
	/*=====================================================================================
	MAIN LOOP
	=======================================================================================*/
	G.Loop=function()
	{
		//update game logic !
		G.catchupLogic=0;
		G.Logic();
		G.catchupLogic=1;
		
		//latency compensator
		G.accumulatedDelay+=((new Date().getTime()-G.time)-1000/G.fps);
		G.accumulatedDelay=Math.min(G.accumulatedDelay,1000*5);//don't compensate over 5 seconds; if you do, something's probably very wrong
		G.time=new Date().getTime();
		while (G.accumulatedDelay>0)
		{
			G.Logic();
			G.accumulatedDelay-=1000/G.fps;//as long as we're detecting latency (slower than target fps), execute logic (this makes drawing slower but makes the logic behave closer to correct target fps)
		}
		G.catchupLogic=0;
		
		if (document.hasFocus() || G.T%5==0) G.Draw();
		
		//fps counter and graph
		G.previousFps=G.currentFps;
		G.currentFps=G.getFps();
		if (G.getSetting('fpsgraph'))
		{
			l('fpsCounter').innerHTML=G.currentFps+' fps';
			var ctx=G.fpsGraphCtx;
			ctx.drawImage(G.fpsGraph,-1,0);
			ctx.fillStyle='rgb('+Math.round((1-G.currentFps/G.fps)*128)+',0,0)';
			ctx.fillRect(128-1,0,1,64);
			ctx.strokeStyle='#fff';
			ctx.beginPath();
			ctx.moveTo(128-1,(1-G.previousFps/G.fps)*64);
			ctx.lineTo(128,(1-G.currentFps/G.fps)*64);
			ctx.stroke();
		}
		
		setTimeout(G.Loop,1000/G.fps);
	}
}

G.Launch();

window.onload=function()
{
	if (!G.ready)
	{
		G.ready=true;
		if (top!=self)
		{
			l('deleteOnLoadContent').innerHTML=''+
				'<div class="framed bgDark fancyText bitBiggerText" style="width:480px;margin:auto;padding:16px 24px;">'+
				'<div class="barred">Oops. Wrong address!</div>'+
				'<div>It looks like you\'re accessing NeverEnding Legacy from another URL than the official one.<br>'+
				'You can <a href="//orteil.dashnet.org/legacy/" target="_blank">play NeverEnding Legacy over here</a>!'+
				'</div></div>';
		}
		else
		{
			var script=document.createElement('script');
			script.id='metascript';
			script.setAttribute('src','metaLegacy.js?r='+Math.random());//we add a random bit to the URL to prevent caching
			script.onload=function()
			{
				Meta();
				G.LoadResources();
			}
			document.head.appendChild(script);
		}
	}
};

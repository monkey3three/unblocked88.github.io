function UnityProgress (dom) {
  var root_path = 'y8-studio/TemplateData';
  this.progress = 0.0;
  this.message = "";
  this.dom = dom;

  var parent = dom.parentNode;

  var background = document.createElement("div");
  background.setAttribute('id', 'background');
  parent.appendChild(background);
  this.background = background;

  var screen = document.createElement("div");
  screen.setAttribute('id', 'screen');
  background.appendChild(screen);

  var logoImage = document.createElement("div");
  logoImage.setAttribute('id', 'y8-logo');
  logoImage.setAttribute('width', 206);
  logoImage.setAttribute('height', 130);
  screen.appendChild(logoImage);
  this.logoImage = logoImage;

  var progressFrameLoader = document.createElement("div");
  progressFrameLoader.setAttribute('id', 'progress-frame-loader');
  screen.appendChild(progressFrameLoader);

  var progressFrame = document.createElement("img");
  progressFrame.setAttribute('id', 'progress-frame');
  progressFrame.src = root_path + "/loadingbar.png";
  progressFrameLoader.appendChild(progressFrame);
  this.progressFrame = progressFrame;

  var progressBarLoader = document.createElement("div");
  progressBarLoader.setAttribute('id', 'progress-bar-loader');
  screen.appendChild(progressBarLoader);

  var progressBar = document.createElement("img");
  progressBar.setAttribute('id', 'progress-bar');
  progressBar.src = root_path + "/fullbar.png";
  progressBarLoader.appendChild(progressBar);
  this.progressBar = progressBar;

  var messageArea = document.createElement("p");
  messageArea.setAttribute('id', 'message-area');
  screen.appendChild(messageArea);
  this.messageArea = messageArea;

  this.SetProgress = function (progress) {
    if (this.progress < progress) {
      this.progress = progress;
    }
    if (progress == 1) {
      this.SetMessage('Preparing...');
    }
    this.progressFrame.style.visibility = "visible";
    this.progressBar.style.display = "inline";
    this.Update();
  }

  this.SetMessage = function (message) {
    if (message == "Loading WebGL Player, Please wait...") {
      message += '<img src="' + root_path + '/gears.gif" />'
    } else if ((m = message.match(/^Downloading data... \(([0-9]+)\/([0-9]+)\)/)) !== null) {
      message = this.RewriteMessage(m);
    }

    this.message = message;
    this.background.style.display = "inline";
    this.progressFrame.style.visibility = "hidden";
    this.progressBar.style.display = "none";
    this.Update();
  }

  this.RewriteMessage = function (m) {
    var downloaded = this.FormatBytes(parseInt(m[1]), 2);
    var total = this.FormatBytes(parseInt(m[2]), 2);
    var message = m[0].replace(m[1], downloaded);
    return message.replace(m[2], total);
  }

  this.FormatBytes = function(bytes,decimals) {
    if(bytes == 0) { return '0 Byte'; }
    var k = 1000;
    var dm = decimals + 1 || 3;
    var sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB'];
    var i = Math.floor(Math.log(bytes) / Math.log(k));
    return (bytes / Math.pow(k, i)).toPrecision(dm) + ' ' + sizes[i];
  }

  this.Clear = function() {
    this.background.style.display = "none";
    this.logoImage.style.display = "none";
    this.progressFrame.style.display = "none";
    this.progressBar.style.display = "none";

    // see shared/EnableSound.js
    const event = new Event('removeSoundOverlay');
    document.dispatchEvent(event);
  }

  this.Update = function() {
    this.background.style.top = this.dom.offsetTop + 'px';
    this.background.style.left = this.dom.offsetLeft + 'px';
    this.background.style.width = this.dom.offsetWidth + 'px';
    this.background.style.height = this.dom.offsetHeight + 'px';

    var progressFrameImg = new Image();
    progressFrameImg.src = this.progressFrame.src;

    this.progressBar.style.top = this.progressFrame.style.top;
    this.progressBar.style.left = this.progressFrame.style.left;
    this.progressBar.width = progressFrameImg.width * Math.min(this.progress, 1);

    this.messageArea.innerHTML = this.message;
  }
  this.Update ();
}

window.Game = (function() {
  var Game = function() {
    this.registerEvents();
  };

  Game.prototype.registerEvents = function() {
    var _this = this;

    window.addEventListener("keydown", function(e) {
      // space and arrow keys
      if([8, 37, 38, 39, 40].indexOf(e.keyCode) > -1) {
        e.preventDefault();
      }
    }, false);

    document.onmousedown = function() {
      window.focus();
    };

    document.addEventListener('DOMContentLoaded', function() {
      _this.resize();
    }, false);

    window.addEventListener('resize', function() {
      setTimeout(function() {
        // Do not resize in fullscreen
        if (!_this.fullscreen()) {
          _this.resize();
        }
      }, 1000);
    }, false);
  };

  Game.prototype.getQueryVariable = function(variable) {
    var query = window.location.search.substring(1);
    var vars = query.split("&");
    for (var i = 0; i < vars.length; i++) {
      var pair = vars[i].split("=");
      if(pair[0] == variable){
        return pair[1];
      }
    }
    return(false);
  }

  Game.prototype.resize = function() {
    var template        = document.querySelector('.template-wrap');
    var canvas          = document.getElementById('canvas');
    var bg              = document.getElementById('background');
    var br              = document.getElementsByTagName('br')[0];

    var ratioTolerant   = this.getQueryVariable('ratio_tolerant');
    var gameSizeRatio   = canvas.getAttribute('width') / canvas.getAttribute('height');
    var maxHeight       = window.innerHeight - 56; // minus the footer
    var maxWidth        = window.innerWidth;
    var windowSizeRatio = maxWidth / maxHeight;
    var newStyle        = {
      width: canvas.getAttribute('width'),
      height: canvas.getAttribute('height')
    };

    if (ratioTolerant == 'true') {
      newStyle = { width: maxWidth, height: maxHeight };
    } else if (ratioTolerant == 'false') {
      if (gameSizeRatio > windowSizeRatio) {
        newStyle = { width: maxWidth, height: maxWidth / gameSizeRatio };
      } else {
        newStyle = { width: maxHeight * gameSizeRatio, height: maxHeight };
      }
    }

    if (br) {
      br.style.display = 'none';
    }

    this.updateStyle(canvas, newStyle);
    this.updateStyle(bg, newStyle);
  };

  Game.prototype.updateStyle = function(element, size) {
    element.setAttribute('width', size.width);
    element.setAttribute('height', size.height);
    element.style.width = size.width + 'px';
    element.style.height = size.height + 'px';
  };

  Game.prototype.fullscreen = function() {
    return document.fullscreenElement ||
           document.webkitFullscreenElement ||
           document.mozFullScreenElement ||
           document.msFullscreenElement;
  };

  return Game;
})();

var game = new Game();

function updateCanvasDim() {
  game.resize();
}

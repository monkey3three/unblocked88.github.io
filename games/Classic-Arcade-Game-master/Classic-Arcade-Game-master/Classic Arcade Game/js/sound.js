
/**audio theme for game**/
function sound(src) {
    this.sound = document.createElement("audio");
    this.sound.src = src;
    this.sound.setAttribute("controls", "none");
    this.sound.setAttribute("loop", "loop");
    this.sound.style.display = "none";
    document.body.appendChild(this.sound);
    this.play = function(){
        this.sound.play();
    }
    this.stop = function(){
        this.sound.pause();
    }    
};


var myMusic = new sound("sound/gametheme.mp3");

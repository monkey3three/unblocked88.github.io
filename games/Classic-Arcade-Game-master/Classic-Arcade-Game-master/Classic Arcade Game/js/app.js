
/**
* @description Enemy class is able set values for vehicle objects. 
*/
class Enemy {

    constructor(x, y, z) {
        this.x = x; //set x-axis for each vehicle objects.
        this.y = y; //set y-axis for each vehicle objects.
        this.index = z; //index value of vehicle objects.
        this.vehicleMove = 1; //initial speed factors of vehicle objects.
        this.randomXaxis = 0; //boundary check for each vehicle objects to cross the boundary  

        this.sprite = ['img/car-one.png',
                       'img/car-two.png',
                       'img/fire-engine.png',
                       'img/bus-one.png',
                       'img/truck.png',
                       'img/bus-three.png',
                       'img/auto.png',
                       'img/cycle.png',
                       'img/ambulance.png'
        ]; //list of enemy vehicles which used in render method.

    }


    /**
    * @description update method to update x-axis by multiply with dt parameters to each vehicle objects. 
    */
    update(dt) {

    this.randomXaxis = Math.floor(Math.random() * (600) + 600); //randomly generating value greater than canvas width.

    if (this.x < this.randomXaxis) { //check value x-axis of each vehicle present in the boundary limit of randomly generated number. 

        this.x += this.vehicleMove * 100 * dt; //multiply dt parameters with vehicle randomly generated speed values and 
                                               //set generated values to vehicle objects x-axis.

    } else { //vehicle objects crosses the boundary limit. 

        this.x = -200; //set starting position of each objects x-axis which croses boundary.  
        this.vehicleMove = Math.floor((Math.random() * 5) + 1); //set each objects to various speed factors(1,2,3,4,5) from the starting point.

    }

}


/**
* @description render method is used to render vehicle objects using x-axis,y-axis,index value carry by vehicle objects.
* -By using the index value is able to render different vehicle objects.     
* @property this.sprite[this.index] which contains index value of vehicle object.  
*/
render() {

    ctx.drawImage(Resources.get(this.sprite[this.index]),this.x,this.y); //draw each and every vehicle to the canvas.

}


};





/**
* @class Player class which contains properties and function of player object. 
*/
class Player {

    constructor() { 

        this.sprite = 'img/char-boy.png'; //initial image of the player

        this.x = 200; //starting location x axis of the player in the board
        this.y = 400; //starting location y axis of the player in the board

        //previous variables used to set the the player on the board to avoid getout of the game display.
        //previousXaxis and previousYaxis used for boundary check ensure player to avoid move out of the screen.
        //It can be achieved by storing a previous location of player object in the previous X,Y variables.
        //previous location variable used in checkCollisions() method.
        this.previousXaxis = 0; //initial previous locaton x axis set to 0 
        this.previousYaxis = 0; //initial previous location y axis set to 0

        //these properties are used to ensure player inside the canvas in collisionsCheck method.
        this.axisYstart = -5; //maximum height the player can reach at y-axis.
        this.axisYend = 401; //minimum height of y-axis the player can reach.
        this.axisXstart = -1; //minimum width of x-axis the player can reach.
        this.axisXend = 401; //maximum width the player can reach at x-axis

        this.score = 100; //initial score set to 100.
        this.life = 3; //initial life set to 3.
        this.check = 0; //check = 0 used in update() function to display select character popup. 

        this.enemyGroundone = 76 //y-axis of road 1 called by checkCollisions() method. 
        this.enemyGroundtwo = 157 //y-axis of road 2 called by checkCollisions() method.
        this.enemyGroundthree = 238 //y-axis of road 3 called by checkCollisions() method.

        this.scoreDecrement = 25; //score decrease on player vehicle collision called by scoreCalculation() method. 
        this.lifeDecrement = 1; //life decrease on player vehicle collision called by scoreCalculation() method.

        this.hitOne = 68; //hitting position of enemy and player
        this.hitTwo = 38; //hitting position of enemy and player

        this.gemStoneone = '<img src="img/blue.png" alt="blue gem" class="gemstone">'; //gem 1 
        this.gemStonetwo = '<img src="img/green.png" alt="green gem" class="gemstone">'; //gem 2
        this.gemStonethree = '<img src="img/orange.png" alt="orange gem" class="gemstone">'; //gem 3

        this.heart = document.querySelector('.heart').childNodes; //DOM to access life of the player initial 3 hearts.
        this.highScore = document.querySelector('.highscore'); //highscore is used to display player score in popup at the final stage of the game.
        this.gem = document.querySelector('.gem'); //gem is used to display player awarded gem in popup at the final stage of the game.
        this.playerCollection = document.querySelectorAll('.imgselect'); //DOM to access different players selection at initial stage of the game.   
        this.alertmessage = document.querySelector('.alertmsg'); //alertmsg "you WON" or "you LOSE" is display in popup at final stage of the game.
        
    }



    /**
    * @description update method to display selectcharacter pop up. 
    * @property this.check is used to display player selection popup only at the starting position of the game.      
    */
    update() {

        if (this.check === 0) { //check === 0 for the first time
            modals.style.display = "block"; //then display popup select player of your choice
            this.check += 1; //check increments to 1 this ensure the popup never appear in the game.
        }

    }


    /**
    * @description render the player in which the user selects in the popup.
    * -selecting different player is take care by event listeners.  
    * @property this.x and this.y can change by handleInput() method periodically when using a keyboard by the user.
    */
    render() {

        ctx.drawImage(Resources.get(this.sprite), this.x, this.y);

    }


    /**
    * @description handleInput method is used to change x-axis and y-axis of the player using key from eventlistener. 
    * @param key is used to analyze (up,down,right,left) of keyboard events the user clicks to play the game.      
    * this.y === -5 player reach other side of the road score popup appeared hereafter player does not able to move.
    * this.check === 1 not able to move player at the starting point of the game until choose player from popup.
    * this.check === 3 if the player dies earlier cannot reach otherside of the road score popup appeared hereafter player does not able to move.   
    */
    handleInput(key) { //key code from eventListener.
           
        if (this.y === -5 || this.check === 1 || this.check === 3) { //cannot perform change in x-axis and y-axis.

            console.log("Cannot move");

        } else { //change in x-axis and y-axis takes place
            //key is up means (y-axis - 81) to move player one tile upward.
            //key is down means (y-axis + 81) to move player one tile downward.
            //key is right means (y-axis + 100) to move player one tile right.
            //key is left means (y-axis - 100) to move player one tile left.
            (key === 'up') ? this.y -= 81 : (key === 'down') 
                           ? this.y += 81 : (key === 'right') 
                           ? this.x += 100 : (key === 'left') 
                           ? this.x -= 100 : console.log("moved"); 

        }

    }




    /**
    * @description checkcollisions method is used to analyze two things. 
    * 1.help player to avoid getting out of the game board.      
    * @property axisXstart,axisXend,axisYstart,axisYend sets boundary for the player to circulate inside the boundary. 
    * 2.check collisions between vehicles and players
    */
    checkCollisions() {

        //condition to ensure player inside the boundary and render() method called by game loop engine to render player. 
        if ((this.axisYstart < this.y && this.y < this.axisYend) && (this.axisXstart < this.x && this.x < this.axisXend)) {
          
            this.previousXaxis = this.x; //storing current location x-axis to previous location x-axis variable.
            this.previousYaxis = this.y; //storing current location y-axis to previous location y-axis variable.

        } else if (this.y > -5) { //condition to avoid player getting out of canvas.
            //player try to move outside of the canvas remains in same place not able to getout of the canvas.
            this.x = this.previousXaxis; //previous location of x-axis is set to current location of x-axis.
            this.y = this.previousYaxis; //previous location of y-axis is set to current location of y-axis.

        } else { //otherwise,player reach otherside of the road then scoreboard popup to display score after 1000ms. 

            setTimeout(this.scoreBoard.bind(this), 1000); //player scoreBoard() method called.

        }
        

        //every collision by player and vehicle at differnt road is calculated 
        if (this.y === this.enemyGroundthree) { //check player position at road 3
        
            if (((vehicleNine.x >= this.x - this.hitOne) && (vehicleNine.x <= this.x + this.hitOne)) ||
                ((vehicleEight.x >= this.x - this.hitTwo) && (vehicleEight.x <= this.x + this.hitTwo)) ||
                ((vehicleSeven.x >= this.x - this.hitTwo) && (vehicleSeven.x <= this.x + this.hitTwo))) {

                this.startingPosition(); //reset player to initial position
                this.scoreBoard(); //calculate score

            }

        } else if (this.y === this.enemyGroundtwo) { //check player position at road 2

            if (((vehicleFour.x >= this.x - this.hitOne) && (vehicleFour.x <= this.x + this.hitOne)) ||
                ((vehicleFive.x >= this.x - this.hitOne) && (vehicleFive.x <= this.x + this.hitOne)) ||
                ((vehicleSix.x >= this.x - this.hitOne) && (vehicleSix.x <= this.x + this.hitOne))) {

                this.startingPosition(); //reset player to initial position
                this.scoreBoard(); //calculate score

            }
          
        } else if (this.y === this.enemyGroundone) { //check player position at road 1 

            if (((vehicleOne.x >= this.x - this.hitOne) && (vehicleOne.x <= this.x + this.hitOne)) ||
                ((vehicleTwo.x >= this.x - this.hitOne) && (vehicleTwo.x <= this.x + this.hitOne)) ||
                ((vehicleThree.x >= this.x - this.hitOne) && (vehicleThree.x <= this.x + this.hitOne))) {

                this.startingPosition(); //reset player to initial position
                this.scoreBoard(); //calculate score

            }

        }

    }


    //reset player to starting position of the game.
    startingPosition() {

        this.x = 200;
        this.y = 400;

    }


    /**
    * @description scoreBoard() method is used to call scoreCalculation() and finalDisplay() method based on conditions. 
    * @property this.life is set to 3 initially after player lose all the life by collision attains life = 0,score popup appears by calling finalDisplay() method.       
    * @property this.axisYstart = -5 on y-axis top boundary of the canvas, score popup appears by calling finalDisplay() method.
    */
    scoreBoard() { //invoked by collisionCheck() method, each time the player collide with vehicle objects.

        (this.life === 0 || this.y === this.axisYstart) ? this.finalDisplay() : this.scoreCalculation(); 
        //else scoreCalculation() method called every time player collide with vehicle objects to calculate score and life. 
    }

    
    /**
    * @description scoreCalculation() method called by scoreBoard() method each time player and vehicle hits.
    * @property this.score initial value 100, for every hit decrease by 25.
    * @property this.life initial value 3, for every hit decrease by 1.  
    */
    scoreCalculation() {
        //initial value of score is 100.
        this.score -= this.scoreDecrement; //for each hit -25 score decremented  
        this.life -= this.lifeDecrement; //each collision life decremented by 1.
        //after 2 life decrease 1 heart
        (this.life === 2) ? this.heart[3].classList.remove("life") : (this.life === 1) ? //after 1 life decrease 2 heart
                            this.heart[5].classList.remove("life") : (this.life === 0) ? //decrease 3 heart
                            this.heart[7].classList.remove("life") : console.log("game is running"); 

    }


    /**
    * @description finalDisplay() method called by scoreBoard() method if the player reach destination or life = 0 suituations.
    */
    finalDisplay() {
           
        modal.style.display = "block"; //display score popup
        this.highScore.innerHTML = this.score; //insert score in popup

        if (this.score === 100) { //display 3 gemstone
            this.gem.innerHTML = this.gemStoneone + this.gemStonetwo + this.gemStonethree;                  
        } else if (this.score === 75) { //display 2 gemstone
            this.gem.innerHTML = this.gemStoneone + this.gemStonetwo;                  
        } else if (this.score === 50) { //display 1 gemstone
            this.gem.innerHTML = this.gemStoneone;                  
        } else {
            this.gem.innerText = 'Sorry, No Gem'; //no gem
        }   
 
        this.check += 1; //check ensures player not able to move after score popup displayed,it is used in handleInput() method to restrict keyboard moves.
        //score < 50 alert msg in popup "LOSE" 
        //score > 50 alert msg in popup "WON"
        (this.score < 50) ? this.alertmessage.innerText = 'SORRY YOU LOSE' : this.alertmessage.innerText = 'YOU WON !!!';

    }

};



//object creation part
//creating 9 object for Enemy class and set x-axis and y-axis initial position in the canvas.
//enemy update prototype function is used to change speed of each and every vehicle objects and  
// -set start position to -200,when the object goes out of set boundary randomly after 505 width of the canvas.
//enemy render function is reder every object with different in speed and x-axis at the canvas. 
// using game loop engine the process continues to change position,speed and finally render on the screen.
let vehicleOne = new Enemy(0,95,0); //(width,height,indexvalue) of vehicleOne object
let vehicleTwo = new Enemy(200,80,1); //(width,height,indexvalue) of vehicleTwo object
let vehicleThree = new Enemy(400,90,2); //(width,height,indexvalue) of vehicleThree object
let vehicleFour = new Enemy(100,170,3); //(width,height,indexvalue) of vehicleFour object
let vehicleFive = new Enemy(300,165,4); //(width,height,indexvalue) of vehicleFive object
let vehicleSix = new Enemy(500,170,5); //(width,height,indexvalue) of vehicleSix object
let vehicleSeven = new Enemy(50,265,6); //(width,height,indexvalue) of vehicleSeven object
let vehicleEight = new Enemy(150,320,7); //(width,height,indexvalue) of vehicleEight object
let vehicleNine = new Enemy(250,260,8); //(width,height,indexvalue) of vehicleNine object

//creating allEnemies array to insert 9 objects in that array used in enemy render prototype.
let allEnemies = [vehicleOne, vehicleTwo, vehicleThree, vehicleFour, vehicleFive, vehicleSix, vehicleSeven, vehicleEight, vehicleNine];

//object for player class
var player = new Player();


//Event Listeners
//starting point of the game it invokes player selection popup.
player.playerCollection.forEach(function (players) { //playerCollection contains player images from HTML DOM.
    players.addEventListener('click', function () { //click event on single player
        player.sprite = players.getAttribute('src'); //get src attribute and set to this.sprite then render() method called by game loop engine.
        modals.style.display = "none"; //after selecting player popup disappear.
        player.check += 1; //check value increments to 2. functionality used in handleInput() method.
    });
});


//keyboard events sent keycode to handleInput() method.
document.addEventListener('keyup', function (e) {

    var allowedKeys = {
        37: 'left',
        38: 'up',
        39: 'right',
        40: 'down'
    };

    player.handleInput(allowedKeys[e.keyCode]);

});


//reload function is used to reload the entire game.
function reLoad() {
    location.reload();
}
# Project Title

<strong>Classic Arcade Game -</strong> <i>Cross the Roads</i>

# Table of contents

<ul>
  <li>Getting Started</li>
  <li>Prerequisites</li>
  <li>Up and Running</li>
  <li>Directory Structure</li>
  <li>Project Description</li>
  <li>Code Overview</li>
  <li>General information</li>
  <li>Screenshots</li>
  <li>Build In</li>
  <li>Frameworks used</li>
  <li>Features</li>
  <li>Inspiration</li>
  <li>Status</li>
  <li>Authors</li>
  <li>License</li>
</ul>

# Getting Started

These instructions will get you a copy of the project up and running on your local machine for development purposes.
Follow the Prerequisites need to run the code for furthur research.

# Prerequisites

<b>Softwares Needed</b>

<b>Download and Install VISUAL STUDIO CODE</b>
<br>
https://code.visualstudio.com/download

<br>

<b><i>Need Browser to run or debug our code</i></b>
<ul>
  <li>Download and Install GOOGLE CHROME Browser</li>
</ul>

<b><i>Knowledge</i></b>
<ul>
  <li>Knowledge in HTML, CSS, JAVASCRIPT</li>
  <li>Knowledge in OOPS in Javascript.</li>
</ul>

<b><i>Knowledge Base</i></b>
<ul>
  <li>HTML TUTORIAL - https://www.w3schools.com/html/</li>
  <li>CSS TUTORIAL - https://www.w3schools.com/css/</li>
  <li>JS TUTORIAL - https://developer.mozilla.org/bm/docs/Web/JavaScript</li>  
</ul>


# Up and Running

<p><b>Run the Game</b></p>
<p><b>After Downloading Google chrome</b> --> <i>right click on index.html file in classic arcade game folder</i> -> <i>Open with option</i> -> <i>select Google Chrome</i> -> <i>Play the game in the browser.</i></p>  

<p><b>View project Files</b></p>
<p><b>After Downloading Visual Studio Code</b> --> <i>Open Visual Studio Code software</i> -> <i>Open Folder option</i> -> <i>select Classic Arcade Game folder</i> -> <i>set up your workspace.</i></p>  


# Directory structure

<p>Classic Arcade Game project folder contains following sub-folders</p>

<b><i>css/</i></b>
<ul>
  <li>css folder contains style.css custom stylesheet written in css.</li>
  <li>Bootstrap - Responsive front-end Framework used.</li>
    https://stackpath.bootstrapcdn.com/bootstrap/4.3.1/css/bootstrap.min.css
  <li>Fontawesome.css is used in this project</li>
    https://use.fontawesome.com/releases/v5.7.2/css/all.css
</ul>

<b><i>img/</i></b>
<p><ul><li>Contains set of image files used in the project.</li></ul></p>

<b><i>js/</i></b>
<ul>
  <li>resources.js - image loading utility.</li>
  <li>engine.js - Game loop Engine.</li>
  <li>app.js - custom javascript code written in js.</li>
  <li>sound.js - custom javascript code for audio written in js.</li>
</ul>

<b><i>audio/</i></b>
<ul>
  <li>Contains audio file used in the project.</li>
</ul>

<b><i>html</i></b>
<ul>
  <li>index.html - contains HTML5 content.</li>
</ul>  

# Project Description
  
This Classic Arcade Game is based on player and vehicle objects. Vehicles are moving at random speed on the road. 
The player needs to cross the road without colliding with number of vehicles. He losses it's life when the player 
collide with the vehicles.Player will win when he successfully crossed the road.


# Code Overview

<b>In this project we use <i>Canvas</i> to build the game.
<p>The canvas element is part of HTML5 and allows for dynamic, scriptable rendering of 2D shapes and bitmap images.</p>

<b><i>Open app.js file and proceed furthur</i></b>

<b>This project contains two classes</b>
<ul>
  <li>Enemy class</li>
  <li>Player class</li>
</ul>

<b><i>Methods in Enemy Class</i></b>
<ul>
  <li>update() method is used to update vehicle position and speed.</li>
  <li>render() method is used to render vehicle inside the canvas.</li>
</ul>

<b><i>Methods in Player Class</i></b>
<ul>
  <li>update() method is used for player selection.</li>
  <li>render() method is used to render player.</li>
  <li>handleInput() method is used to handle keyboard actions taken by the player.</li>
  <li>checkCollisions() method is used to check Enemy - player Collision.</li>
  <li>scoreBoard(), scoreCalculation() method is used to calculate score.</li>
  <li>startingPosition() method is used to reset the player position when collision occurs.</li> 
  <li>finalDisplay() method is used to display final score.</li>  
</ul>


<b><i>Global Method</i></b>
<ul>
  <li>reLoad() method is used to reload the entire game.</li>
</ul>


<b><i>Event Listeners</i></b>
<ul>
  <li>'Keyup' listener is used for player movement.</li>
  <li>'click' listener is used to select player to play the game.</li>
</ul>


<b><i>Game Control : keyBoard</i></b>
<ul>
  <li>&larr;&uarr;&rarr;&darr; Arrow keys are used to Move the player.</li>
  <li>'Keyup' EventListener and handleInput() method in app.js file are used for player Movemment.</li>
</ul>

<b><i>Open sound.js file</i></b>
<p><i>It runs music theme for the game.</i></p>



# General information
 
<ul>
  <li>Player selection</li>
  <li>Move player using Keyboard</li>
  <li>Vehicle Movement</li>
  <li>Player and Enemy collision</li>
  <li>Display remaining life</li>
  <li>Losing life</li>
  <li>Final score board</li>
  <li>Running Game</li>
</ul> 

# Screenshots
 
<b>state 1 :</b> Player selection

![alt text](https://github.com/webbizleads/Classic-Arcade-Game/blob/master/Classic%20Arcade%20Game/img/player-selection.JPG)     

<b>state 2 :</b> Move player using Keyboard

![alt text](https://github.com/webbizleads/Classic-Arcade-Game/blob/master/Classic%20Arcade%20Game/img/player-movement.JPG)

<b>state 3 :</b> Vehicles Moves at random speed. 

![alt text](https://github.com/webbizleads/Classic-Arcade-Game/blob/master/Classic%20Arcade%20Game/img/moving-vehicle.JPG)
 
<b>state 4 :</b> Player and Enemy collision.

![alt text](https://github.com/webbizleads/Classic-Arcade-Game/blob/master/Classic%20Arcade%20Game/img/collision.JPG)

<b>state 5 :</b> Display remaining life.

![alt text](https://github.com/webbizleads/Classic-Arcade-Game/blob/master/Classic%20Arcade%20Game/img/life.JPG)
 
<b>state 6 :</b> Losing life displays popup with final score.

![alt text](https://github.com/webbizleads/Classic-Arcade-Game/blob/master/Classic%20Arcade%20Game/img/lose.JPG)
 
<b>state 7 :</b> Winning game displays popup with final score and gem.

![alt text](https://github.com/webbizleads/Classic-Arcade-Game/blob/master/Classic%20Arcade%20Game/img/winning.JPG)

<b>state 8 :</b> Running Game

![alt text](https://github.com/webbizleads/Classic-Arcade-Game/blob/master/Classic%20Arcade%20Game/img/running%20game.JPG)

# Build In

VS code Editor
Visual Studio Code is a source code editor developed by Microsoft for Windows, Linux and macOS
Matching card game developed in Visual Studio code software
 
# Frameworks used

Bootstrap Framework
Bootstrap is a free and open-source front-end responsive Web developement framework.
It contains HTML and CSS-based design templates for typography, forms, buttons, navigation and components other components.

Fontawesome
Font Awesome is a font and icon toolkit based on CSS and LESS

# Features

<ul>
  <li>List of features ready for future development</li>
  <li>Increse the size of the game display</li>
  <li>Adding collectable objects in the game</li>
  <li>Add newly designed game levels in water</li>
  <li>Adding real time user experience </li>
</ul>

# Inspiration
  
Project inspiration from Udacity FrontEnd Developer Nanodegree Program.

# Status

Project is in progress for new level design and developement
for advanced features.

# Authors

Ranjith Kumar - [Classic Arcade Game] - (https://github.com/webbizleads/Classic-Arcade-Game)

# License

This project is the open source license 



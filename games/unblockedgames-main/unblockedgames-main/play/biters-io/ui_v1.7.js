var AD_STATUS = {
  NONE: 0,
  CLOSE_FINISHED: 1,
  CLOSE_ABORTED: 2,
  ERROR: 3,
}

function onShowUI() {
  
}

function onHideUI() {
  
}

function onGameLoaded() {
  
}

function hideProgress() {
 
}

function playButtonClicked(from) {
  sendClickEvent('game', 'play')
  startGameFromScreen = from
  StartGame(startGameFromScreen)
}

function sendClickEvent(category, label) {
  window.ga && window.ga('send', 'event', category, 'Clicked', label)
}

function StartGame(target) {
	gameInstance.SendMessage('GameManager', 'StartGame', parseInt(target, 10))
}

function getFetchResult() {
	return true
}

function showVideoAd() {
	gameInstance.SendMessage(
								'GameManager',
								'VideoAdResult',
								AD_STATUS.CLOSE_FINISHED
							)
}


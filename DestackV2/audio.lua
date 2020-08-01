audio =
{	flip  = false
,	move  = false
,	flash = false
,	music = false
}

background_music = false

function audio.load ()
	audio.flip  = love.sound.newSoundData( "FlipSound.ogg")
	audio.move  = love.sound.newSoundData( "MoveSound.ogg")
	audio.flash = love.sound.newSoundData("FlashSound.ogg")
	
	audio.music = love.sound.newSoundData("Music.ogg")
	
	background_music = love.audio.newSource(audio.music, "stream")
	--background_music:play()
end

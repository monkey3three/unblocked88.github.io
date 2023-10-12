package quake;

import js.html.Audio;
import js.html.XMLHttpRequest;

class CDAudio {
    static var initialized:Bool;
    static var enabled:Bool;
    static var playTrack:Int;
    static var cd:Audio;
    static var cdvolume:Float;
    static var known:Array<String>;

    public static function Init():Void {
        Cmd.AddCommand('cd', CD_f);
        if (COM.CheckParm('-nocdaudio') != null)
            return;
        known = [];
        var xhr = new XMLHttpRequest();
        for (i in 2...100) {
            var track = '/music/track' + (i <= 9 ? '0' : '') + i + '.ogg';
            var j = COM.searchpaths.length - 1;
            while (j >= 0) {
                xhr.open('HEAD', COM.searchpaths[j].filename + track, false);
                xhr.send();
                if (xhr.status >= 200 && xhr.status <= 299) {
                    known[i - 2] = COM.searchpaths[j].filename + track;
                    break;
                }
                j--;
            }
            if (j < 0)
                break;
        }
        if (known.length == 0)
            return;
        initialized = enabled = true;
        Update();
        Console.Print('CD Audio Initialized\n');
    }

    public static function Update():Void {
        if (!initialized || !enabled)
            return;
        if (S.bgmvolume.value == cdvolume)
            return;
        if (S.bgmvolume.value < 0.0)
            S.bgmvolume.setValue(0.0);
        else if (S.bgmvolume.value > 1.0)
            S.bgmvolume.setValue(1.0);
        cdvolume = S.bgmvolume.value;
        if (cd != null)
            cd.volume = cdvolume;
    }

    public static function Play(track:Int, looping:Bool):Void {
        if (!initialized || !enabled)
            return;
        track -= 2;
        if (playTrack == track) {
            if (cd != null) {
                cd.loop = looping;
                if (looping && cd.paused)
                    cd.play();
            }
            return;
        }
        if (track < 0 || track >= known.length) {
            Console.DPrint('CDAudio.Play: Bad track number ' + (track + 2) + '.\n');
            return;
        }
        Stop();
        playTrack = track;
        cd = new Audio(known[track]);
        cd.loop = looping;
        cd.volume = cdvolume;
        cd.play();
    }

    public static function Stop():Void {
        if (!initialized || !enabled)
            return;
        if (cd != null)
            cd.pause();
        playTrack = null;
        cd = null;
    }

    public static function Pause():Void {
        if (!initialized || !enabled)
            return;
        if (cd != null)
            cd.pause();
    }

    public static function Resume():Void {
        if (!initialized || !enabled)
            return;
        if (cd != null)
            cd.play();
    }

    static function CD_f():Void {
        if (!initialized || Cmd.argv.length <= 1)
            return;
        var command = Cmd.argv[1].toLowerCase();
        switch (command) {
            case 'on':
                enabled = true;
            case 'off':
                Stop();
                enabled = false;
            case 'play':
                Play(Q.atoi(Cmd.argv[2]), false);
            case 'loop':
                Play(Q.atoi(Cmd.argv[2]), true);
            case 'stop':
                Stop();
            case 'pause':
                Pause();
            case 'resume':
                Resume();
            case 'info':
                Console.Print(known.length + ' tracks\n');
                if (cd != null) {
                    if (!cd.paused)
                        Console.Print('Currently ' + (cd.loop ? 'looping' : 'playing') + ' track ' + (playTrack + 2) + '\n');
                }
                Console.Print('Volume is ' + cdvolume + '\n');
            }
    }
}

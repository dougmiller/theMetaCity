let d = <HTMLElement>document.getElementById('document');
const videos = <HTMLCollectionOf<HTMLVideoElement>>d.getElementsByTagName('video');

document.addEventListener("DOMContentLoaded", function () {

    const videoContainer = <HTMLDivElement>document.getElementById("videoContainer"),
        videoBox = <HTMLDivElement>document.getElementById("videoBox"),
        video = <HTMLVideoElement>document.getElementById("detailedVideo"),
        sources = video.getElementsByTagName('source'),
        playPauseButton = <HTMLImageElement>document.getElementById("playPauseButton"),
        fullscreenButton = <SVGImageElement>document.getElementById("fullscreenButton"),
        currentTimeSpan = document.getElementById("currentTimeSpan"),
        playProgress = document.getElementById("playProgress"),
        soundButton = document.getElementById("tmcSoundIcon"),
        soundSlider = document.getElementById("soundSlider"),
        tracksButton = document.getElementById("tracksButton"),
        tracksList = document.getElementById("tracksList"),
        videoFileName = video.dataset.filename,
        hasStartPoster = <boolean>video.dataset.startposter,
        hasEndPoster = video.dataset.endposter,
        hasFullscreen = video.dataset.hasfullscreen,
        canPlayVid = false,
        fullscreenFlag = false,
        soundState = {
            hideSliderTimout: undefined,
            prevButtonIcon: soundButton,
            hideSilderTimoutTime: 3000
        };

    videoBox.style.width = video.width + "px";
    playProgress.value = 0;
    video.controls = false;

    video.addEventListener("click", function () {
        video.playPause();
    });

    video.addEventListener("ended", function () {
        playPauseButton.src = "images/smallplay.svg";
        playPauseButton.alt = "Option to play the video";
        playPauseButton.title = "Play";

        var endPosterRef = hasEndPoster === "True" ? videoFileName : 'generic';
        getPoster(endPosterRef, 'end').then(function(endPoster) {
            endPoster.setAttribute("class", "mediaPoster");
            endPoster.setAttribute("height", video.getAttribute("height"));
            endPoster.setAttribute("width", video.getAttribute("width"));
            videoBox.appendChild(endPoster);

            endPoster.getElementById('playButton').addEventListener("click", function () {
                video.playPause();
                videoBox.removeChild(endPoster);
            });

        }, function(error){
            console.log("No end poster: ");
        });
    });

    video.addEventListener("play", function () {
        var posters = videoContainer.getElementsByClassName("mediaPoster");
        for (var poster of posters) {
            poster.parentNode.removeChild(poster);
        }
    });

    video.addEventListener("loadstart", function () {
        // N.B. requires that the script is loaded early enough/blocking, so no defer
        // If you do not then you can miss this event firing and nothing works as intended

        // Check if we can play any of the supplied sources
        for (var i = 0; i < sources.length; i++) {
            if (video.canPlayType(sources[i].type)) {
                canPlayVid = true;
                break;
            }
        }

        var chapters = Array.prototype.find.call(video.textTracks, function(track) {
            return track.kind === 'subtitles';
        });

        if (chapters) {
            chapters.mode = 'showing';
            console.log(chapters.cues);
        }

        if (!canPlayVid) {
            getPoster("generic", 'error').then(function(errorPoster) {
                errorPoster.setAttribute("class", "videoPoster");
                errorPoster.setAttribute("height", video.getAttribute("height"));
                errorPoster.setAttribute("width", video.getAttribute("width"));
                videoBox.appendChild(errorPoster);
            }, function(error){
                console.log("No end poster: ");
            });
        } else {
            if (canPlayVid && !fullscreenFlag) {
                var startPosterRef = hasStartPoster === "True" ? videoFileName : 'generic';
                getPoster(startPosterRef, 'start').then(function (startPoster) {
                    startPoster.setAttribute("class", "mediaPoster");
                    startPoster.setAttribute("height", video.getAttribute("height"));
                    startPoster.setAttribute("width", video.getAttribute("width"));
                    videoBox.appendChild(startPoster);

                    startPoster.getElementById('playButton').addEventListener("click", function () {
                        video.playPause();
                    });
                }, function (error) {
                    console.log("No start poster: " + error);
                });

                getLoadingbar().then(function (loadingBar) {
                    // only setup for one seek buffer at m
                    //todo make it multi buffer friendly
                    loadingBar.setAttribute("class", "loadingBar");
                    loadingBar.style.top = video.height + "px";
                    loadingBar.setAttributeNS(null, "width", video.width + "px");
                    videoBox.appendChild(loadingBar);

                    function makeNewBufferBar() {
                        var newRect = document.createElementNS('http://www.w3.org/2000/svg',"rect");
                        newRect.setAttributeNS(null,"height","100%");
                        newRect.setAttributeNS(null,"x", 0  + "px");
                        newRect.setAttributeNS(null,"y", 0 + "px");
                        return newRect;
                    }

                    var bars = loadingBar.getElementsByTagName('rect');

                    var renderInterval = setInterval(function () {
                        bars = loadingBar.getElementsByTagName('rect');

                        while (bars.length > video.buffered.length) {
                            bars[bars.length -1].remove();
                        }

                        while (bars.length < video.buffered.length) {
                            loadingBar.appendChild(makeNewBufferBar());
                            bars = loadingBar.getElementsByTagName('rect');
                        }

                        // Sometimes dat has not loaded enough for this to register properly
                        if (video.buffered.length){
                            for (var i = 0; i < video.buffered.length; i++) {
                                bars[i].setAttributeNS(null,"width", ((video.buffered.end(i) - video.buffered.start(i)) / video.duration) * video.width + "px");
                                bars[i].setAttributeNS(null,"x", (video.buffered.start(i) / video.duration) * video.width + "px");
                            }
                            // b/c this is floating point math, sometimes the video.buffered.end(0) returns 0.001 less than buffered.length
                            // /Checking for a whole second less is a fair work around that does not impact on display too much
                            if (video.buffered.end(0) >= video.duration -1) {
                                clearInterval(renderInterval);
                                loadingBar.style.opacity = 0;
                            }
                        }
                    }, 500);
                }, function (error) {
                    console.log("No loading bar: ");
                });
            }
        }

        if (video.textTracks.length === 0) {
            tracksButton.src = "/static/images/notracks.svg";
            tracksButton.alt = "Icon showing no tracks are available";
            tracksButton.title = "No tracks available";
            tracksList.id = "noTracksList";
        }

        for (var j = 0; j < tracksList.children.length; j++) {
            (function (index) {
                tracksList.children[index].addEventListener("click", function () {

                    for (var k = 0; k < tracksList.children.length; k++) {
                       tracksList.children[k].classList.remove('active');
                    }

                    this.classList.add('active');
                    tracksList.classList.remove('emulateHover');

                    // Index 0 is the disable tracks button
                    if (index === 0) {
                        for (var j = 0; j < video.textTracks.length; j++) {
                            video.textTracks[j].mode = "disabled";
                        }
                    } else {
                        video.textTracks[index - 1].mode = "showing";
                    }
                });
            }(j));
        }
    });

    video.addEventListener("loadedmetadata", function () {
        var pos = getCurretlyPlayingSourceIndex();
        // Split happens on the: codecs="vp8,vorbis"' part
        // If we have a length of 2 then we have an audio codec and might be able to play it so we put in the option
        // Length of 1 obviously means no audio codec specified so remove the option to control audio
        if (sources[pos].type.split(',').length === 2) {
            soundButton.src = "/static/images/sound-3.svg";
            soundButton.alt = "Button to change sound options";
            soundButton.title = "Change sound options";
            soundSlider.id = "soundSlider";
        }
    });

    video.addEventListener("timeupdate", function () {
        currentTimeSpan.innerHTML = rawTimeToFormattedTime(this.currentTime);
        // Setting this value does not trigger the 'change' event
        playProgress.value = (this.currentTime / this.duration) * 1000;
    });

    video.isPlaying = function () {
        return !(this.paused || this.ended || this.seeking || this.readyState < this.HAVE_FUTURE_DATA);
    };

    video.playPause = function () {
        if (canPlayVid) {
            if (this.isPlaying()) {
                this.pause();
                playPauseButton.src = "/static/images/smallplay.svg";
                playPauseButton.alt = "Option to play the video";
                playPauseButton.title = "Play";
            } else {
                this.play();
                playPauseButton.src = "/static/images/smallpause.svg";
                playPauseButton.alt = "Option to pause the video";
                playPauseButton.title = "Pause";
            }
        }
    };

    playPauseButton.addEventListener("click", function () {
        video.playPause();
    });

    tracksButton.addEventListener("touchstart", function () {
        tracksList.classList.add('emulateHover');
    });

    fullscreenButton.addEventListener("click", function () {
        if (video.requestFullScreen) {
            video.requestFullScreen();
        } else if (video.webkitRequestFullScreen) {
            video.webkitRequestFullScreen();
        } else if (video.mozRequestFullScreen) {
            video.mozRequestFullScreen();
        }
    });

    playProgress.addEventListener("change", function () {
        video.currentTime = video.duration * (this.value / 1000);
    });

    playProgress.addEventListener("mousedown", function () {
        video.pause();
    });

    playProgress.addEventListener("mouseup", function () {
        video.play();
    });

    let soundTracker = {
        level3Visible: true,
        level2Visible: true,
        level1Visible: true,
        level0Visible: true,
        previousVolume: 1.0,
        soundGates: {
            max: 0.8,
            upper: 0.5,
            lower: 0.2,
            base: 0.0
        }
    };

    soundButton.addEventListener("touchend", function (event) {
        event.stopImmediatePropagation(); // touchend also triggers click so need to stop that from happening and muting the track
        soundState.hideSliderTimout = setTimeout(function () {
            soundSlider.classList.remove("emulateHover");
        }, soundState.hideSilderTimoutTime);
        soundSlider.classList.add("emulateHover");
    });

    soundSlider.addEventListener("touchend", function () {
        soundState.hideSliderTimout = setTimeout(function () {
            soundSlider.classList.remove("emulateHover");
        }, soundState.hideSilderTimoutTime);
    });

    soundSlider.addEventListener("touchstart", function () {
        clearTimeout(soundState.hideSliderTimout);
    });

    soundSlider.addEventListener("input", function () {
        var volumeRatio = this.value / this.max;
        var direction = volumeRatio - soundTracker.previousVolume; // this.value is 1 to this.max, previous value tracks volume which is between 0 and 1, need to convert
        soundTracker.previousVolume = volumeRatio;
        video.volume = volumeRatio;

        soundButton.title = "Button to change sound options";
        soundButton.description = "Change sound options";

        // positive direction is increase in volume
        if (direction > 0) {
            if (video.volume >= soundTracker.soundGates.max && !soundTracker.level3Visible) {
                soundTracker.level3Visible = true;
                soundButton.getElementById("soundIconRay3NoneToFull").beginElement();
            }

            if (video.volume > soundTracker.soundGates.upper && !soundTracker.level2Visible) {
                soundTracker.level2Visible = true;
                soundButton.getElementById("soundIconRay2NoneToFull").beginElement();
            }

            if (video.volume > soundTracker.soundGates.lower && !soundTracker.level1Visible) {
                soundTracker.level1Visible = true;
                soundButton.getElementById("soundIconRay1NoneToFull").beginElement();
            }

            if (video.volume > soundTracker.soundGates.base && !soundTracker.level0Visible) {
                soundTracker.level0Visible = true;
                soundButton.getElementById("soundIconRayMuteFullToNone").beginElement();
            }
        } else if (direction < 0) { // decrease in volume

            if (video.volume <= soundTracker.soundGates.max && soundTracker.level3Visible) {
                soundTracker.level3Visible = false;
                soundButton.getElementById("soundIconRay3FullToNone").beginElement();
            }

            if (video.volume <= soundTracker.soundGates.upper && soundTracker.level2Visible) {
                soundTracker.level2Visible = false;
                soundButton.getElementById("soundIconRay2FullToNone").beginElement();
            }

            if (video.volume <= soundTracker.soundGates.lower && soundTracker.level1Visible) {
                soundTracker.level1Visible = false;
                soundButton.getElementById("soundIconRay1FullToNone").beginElement();
            }

            if (video.volume === soundTracker.soundGates.base && soundTracker.level0Visible) {
                soundTracker.level0Visible = false;
                soundButton.getElementById("soundIconRay0FullToNone").beginElement();
            }
        }
    });


    var hideSlderTimout;
    soundSlider.addEventListener("touchend", function () {
        hideSlderTimout = setTimeout(function(){
            soundSlider.classList.remove('emulateHover');
        }, 1500);
    });

    soundSlider.addEventListener("touchstart", function () {
        clearTimeout(hideSlderTimout);
    });

    soundButton.addEventListener("touchend", function (event) {
        event.stopImmediatePropagation(); // Stop click event from happening and muting the track
        hideSlderTimout = setTimeout(function(){
            soundSlider.classList.remove('emulateHover');
        }, 3000);
        soundSlider.classList.add('emulateHover');
    });

    soundButton.addEventListener("click", function () {
        console.log("sound button click");
        if (sources[getCurretlyPlayingSourceIndex()].type.split(',').length === 2) {
            if (video.muted === false) {
                video.muted = true;
                soundButton.src = "/static/images/sound-0.svg";
                soundButton.alt = "Icon showing no sound is available";
                soundButton.title = "Sound muted.";
                soundSlider.id = "noSoundSlider";
            } else {
                video.muted = false;
                soundButton.src = "/static/images/sound-3.svg";
                soundButton.alt = "Button to change sound options";
                soundButton.title = "Change sound options";
                soundSlider.id = "soundSlider";
            }
        }
    });

    document.addEventListener("mozfullscreenchange", function () {
        var pos = getCurretlyPlayingSourceIndex();
        var splitSrc = sources[pos].src.split(".");
        var playTime = 0;
        fullscreenFlag = true; // Used to flag to the load event that we do not need to load the start poster again

        if (document.fullScreen || document.mozFullScreen || document.webkitIsFullScreen) {  // Have come from non to now full screen
            //var fsVideoTime = fsVideo.currentTime;
            // .dataset.hasFullscreen is is treated a boolean, but it is just truthy string
            // This function uses a standard format of names of full screen appropriate vids as shown below:
            // original: originalvid.xyz            full screen: originalvid.fullscreen.xyz
            // N.B. Can not have period (".") in original file same except for filetype
            if (hasFullscreen === "True") {
                playTime = video.currentTime;
                sources[pos].src = splitSrc[0] + "." + splitSrc[1] + "." + splitSrc[2] + ".fullscreen." + splitSrc[3];
                video.load();  // Reload with the new source
                video.currentTime = playTime;
                video.play();
            }
        } else {  // Have left full screen and need to return to lower res video
            //fsVideoTime = fsVideo.currentTime;
            if (hasFullscreen === "True") {
                playTime = video.currentTime;
                sources[pos].src = splitSrc[0] + "." + splitSrc[1] + "." + splitSrc[2] + "." + splitSrc[4];
                video.load();  // Reload with the new source
                video.currentTime = playTime;
                video.play();
            }
        }
    });

    function rawTimeToFormattedTime(rawTime) {
        var chomped, seconds, minutes;
        chomped = Math.floor(rawTime);
        minutes = Math.floor(chomped / 60);
        seconds = leftZeroPad(chomped % 60, "00");
        return `${minutes}m ${seconds}s`;
    }

    function leftZeroPad(rawString, paddingValue) {
        return (paddingValue + rawString).slice(-paddingValue.length);
    }

    function getPoster(filename, type) {
       return new Promise(function (resolve, reject) {
            var request = new XMLHttpRequest();
            request.open('GET', '//assets.localcity.com/video/' + type + 'posters/' + filename + '.' + type + 'poster.svg', true);

            request.onload = function () {
                if (this.status >= 200 && this.status < 400) {
                    resolve(document.importNode(this.responseXML.firstChild, true));
                } else {
                    reject({status: this.status, statusText: this.statusText});
                }
            };

            request.onerror = function () {
                console.log(this);
                reject({status: this.status, statusText: this.statusText});
            };
            request.send();
        });
    }

    function getLoadingbar() {
       return new Promise(function (resolve, reject) {
            var request = new XMLHttpRequest();
            request.open('GET', '/static/images/loadingProgress.svg', true);

            request.onload = function () {
                if (this.status >= 200 && this.status < 400) {
                    resolve(document.importNode(this.responseXML.firstChild, true));
                } else {
                    reject({status: this.status, statusText: this.statusText});
                }
            };

            request.onerror = function () {
                console.log(this);
                reject({status: this.status, statusText: this.statusText});
            };
            request.send();
        });
    }

    /**
     * Finds and returns the position of the source (0 indexed) in the sources object
     * @returns {number}
     */
    function getCurretlyPlayingSourceIndex() {
        return [].slice.call(sources).map(function (source) {
            return source.src;
        }).indexOf(video.currentSrc);
    }

        /* Special cases of suck */
    var soundIconBody = document.getElementById("soundIconBody");

    soundIconBody.addEventListener("mouseenter", function () {
        soundSlider.classList.add("emulateHover");
    });

    soundIconBody.addEventListener("mouseout", function () {
        soundSlider.classList.remove("emulateHover");
    });

    soundSlider.addEventListener("mouseenter", function () {
        soundSlider.classList.add("emulateHover");
        soundIconBody.classList.add("emulateHover");
    });

    soundSlider.addEventListener("mouseout", function () {
        soundSlider.classList.remove("emulateHover");
        soundIconBody.classList.remove("emulateHover");
    });
});
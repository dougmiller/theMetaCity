document.addEventListener("DOMContentLoaded", function () {
    "use strict";

    var audio = document.getElementById("audioObject"),
        audioBox = document.getElementById("audioBox"),
        audioPoster = document.getElementById("audioPoster"),
        audioPosterImg = document.getElementById("audioPosterImg"),
        sources = audio.getElementsByTagName("source"),
        playPauseButton = document.getElementById("playPauseButton"),
        currentTimeSpan = document.getElementById("currentTimeSpan"),
        playProgress = document.getElementById("playProgress"),
        soundButton = document.getElementById("tmcSoundIcon"),
        soundSlider = document.getElementById("soundSlider"),
        tracksButton = document.getElementById("tmcTracksIcon"),
        tracksList = document.getElementById("tracksList");

    playProgress.value = 0;
    audio.controls = false;

    audio.addEventListener("loadstart", function () {
        var canPlayVid = false;

        // N.B. requires that the script is loaded early enough/blocking, so no defer
        // If you do not then you can miss this event firing and nothing works as intended

        Array.prototype.some.call(sources, function (source) {
            if (audio.canPlayType(source.type)) {
                canPlayVid = true;
            }
        });

        if (!canPlayVid) {
            getPoster("generic", "error").then(function (errorPoster) {
                errorPoster.setAttribute("class", "mediaPoster");
                audioPoster.appendChild(errorPoster);
            }, function (error) {
                console.log("No end poster: " + error);
            });
        } else {
            var startPosterRef;
            startPosterRef = audio.dataset.startposter === "True" ? audio.dataset.filename : "generic";
            getPoster(startPosterRef, "start").then(function (startPoster) {
                startPoster.setAttribute("class", "mediaPoster");
                audioPoster.appendChild(startPoster);

                startPoster.getElementById("playButton").addEventListener("click", function () {
                    audio.playPause();
                });
            }, function (error) {
                console.log("No start poster: " + error);
            });
        }
    });

    audio.addEventListener("loadeddata", function () {
        var chapterTracks, chapterControls, pollForChapterCues;

        if (audio.textTracks.length === 0) {
            tracksButton.src = "/static/images/notracks.svg";
            tracksButton.alt = "Icon showing no tracks are available";
            tracksButton.title = "No tracks available";
            tracksList.id = "noTracksList";
        }

        chapterTracks = Array.prototype.filter.call(audio.textTracks, function (track) {
            return track.kind === "chapters";
        });

        chapterTracks.forEach(function (chapterTrack) {
            chapterTrack.mode = "showing";
            pollForChapterCues = setTimeout(function () {
                if (chapterTrack.cues !== null) {
                    clearInterval(pollForChapterCues);

                    chapterControls = document.createElement("ul");
                    chapterControls.setAttribute("id", "chapterControls");

                    Array.from(chapterTrack.cues).forEach(function (cue) {
                        var chapterLink = document.createElement("li");
                        chapterLink.appendChild(document.createTextNode(cue.text));

                        chapterLink.addEventListener("click", function () {
                            audio.currentTime = cue.startTime + 0.01;
                        });

                        cue.addEventListener("enter", function () {
                            chapterLink.classList.add("playing");
                        });

                        cue.addEventListener("exit", function () {
                            chapterLink.classList.remove("playing");
                        });

                        chapterControls.appendChild(chapterLink);
                    });
                    audioBox.appendChild(chapterControls);
                }
            }, 1000);
        });

        Array.prototype.slice.call(tracksList.children).forEach(function(tracksListItem) {
            tracksListItem.addEventListener("click", function () {
                var chosen = Array.prototype.find.call(audio.textTracks, function (audioTrack) {
                    return audioTrack.kind === tracksListItem.dataset.kind;
                });

                if (tracksListItem.classList.contains("active")) {
                    tracksListItem.classList.remove("active");
                    chosen.mode = "disabled";
                } else {
                    tracksListItem.classList.add("active");
                    chosen.mode = "showing";
                }

                // close mobile hover after click
                tracksList.classList.remove("emulateHover");
            });
        });
    });

    audio.addEventListener("play", function () {
        var posters = audioPoster.getElementsByClassName("mediaPoster");
        Array.from(posters).forEach(function (poster) {
            poster.parentNode.removeChild(poster);
        });
    });

    audio.addEventListener("timeupdate", function () {
        currentTimeSpan.innerHTML = rawTimeToFormattedTime(this.currentTime);
        // Setting this value does not trigger the "change" event
        playProgress.value = (this.currentTime / this.duration) * 1000;
    });

    audio.addEventListener("ended", function () {
        var endPosterRef = audio.dataset.endposter === "True" ? audio.dataset.filename : "generic";
        playPauseButton.getElementsByTagNameNS("http://www.w3.org/2000/svg", "title")[0].textContent = "Play";
        playPauseButton.getElementById("transitionToPlay").beginElement();

        getPoster(endPosterRef, "end").then(function (endPoster) {
            endPoster.setAttribute("class", "mediaPoster");

            endPoster.getElementById("playButton").addEventListener("click", function () {
                audio.playPause();
                audioPoster.removeChild(endPoster);
            });

            getOtherMediaLink().then(function(result) {
                var mediaLink = "//assets.localcity.com/video/postcards/";
                var parsedResult = JSON.parse(result);
                var link1 = endPoster.getElementById("tmcendofmovielink1");
                var link2 = endPoster.getElementById("tmcendofmovielink2");
                var image1 = endPoster.getElementById("tmcendofmovielink1image");
                var image2 = endPoster.getElementById("tmcendofmovielink2image");

                link1.setAttributeNS('http://www.w3.org/1999/xlink', 'href', "/video/" + parsedResult[0].id);
                link2.setAttributeNS('http://www.w3.org/1999/xlink', 'href', "/video/" + parsedResult[1].id);
                image1.setAttributeNS('http://www.w3.org/1999/xlink', 'href', mediaLink + parsedResult[0].file_name + ".png");
                image2.setAttributeNS('http://www.w3.org/1999/xlink', 'href', mediaLink + parsedResult[1].file_name + ".png");
            }, function(err) {
                console.log(err);
            });

            audioPoster.appendChild(endPoster);
        }, function (error) {
            console.log("No end poster: " + error);
        });
    });

    audio.isPlaying = function () {
        return !(this.paused || this.ended || this.seeking || this.readyState < this.HAVE_FUTURE_DATA);
    };

    audio.playPause = function () {
        var title = playPauseButton.getElementsByTagNameNS("http://www.w3.org/2000/svg", "title")[0];

        if (audio.isPlaying()) {
            audio.pause();
            title.textContent = "Play";
            playPauseButton.getElementById("transitionToPlay").beginElement();
        } else {
            audio.play();
            title.textContent = "Pause";
            playPauseButton.getElementById("transitionToPause").beginElement();
        }
    };

    audioPosterImg.addEventListener("click", function () {
        audio.playPause();
    });

    playPauseButton.addEventListener("click", function () {
        audio.playPause();
    });

    playProgress.addEventListener("change", function () {
        audio.currentTime = audio.duration * (playProgress.value / 1000);
    });

    playProgress.addEventListener("mousedown", function () {
        var title = playPauseButton.getElementsByTagNameNS("http://www.w3.org/2000/svg", "title")[0];
        if (audio.isPlaying()) {
            audio.pause();
            title.textContent = "Play";
            playPauseButton.getElementById("transitionToPlay").beginElement();
        } else {
            title.textContent = "Play";
            playPauseButton.getElementById("transitionPlayToPlay").beginElement();
        }
    });

    playProgress.addEventListener("mouseup", function () {
        audio.play();
        var title = playPauseButton.getElementsByTagNameNS("http://www.w3.org/2000/svg", "title")[0];
        title.textContent = "Pause";
        playPauseButton.getElementById("transitionToPause").beginElement();
    });

    tracksButton.addEventListener("touchstart", function () {
        tracksList.classList.add("emulateHover");
    });

    playPauseButton.addEventListener("mouseenter", function () {
        playPauseButton.getElementById("setDashArray").beginElement();
        playPauseButton.getElementById("setDashOffset").beginElement();
    });

    playPauseButton.addEventListener("mouseleave", function () {
        playPauseButton.getElementById("setDashArray").endElement();
        playPauseButton.getElementById("setDashOffset"). endElement();
    });

    var soundStateTracker = {
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
        },
        hideSliderTimout: undefined,
        hideSilderTimoutTime: 3000
    };
    soundButton.addEventListener("touchend", function () {
        soundStateTracker.hideSliderTimout = setTimeout(function () {
            soundSlider.classList.remove("emulateHover");
        }, soundStateTracker.hideSilderTimoutTime);
    });

    soundSlider.addEventListener("touchstart", function () {
        clearTimeout(soundStateTracker.hideSliderTimout);
        soundSlider.classList.add("emulateHover");
    });

    soundSlider.addEventListener("input", function () {
        var volumeRatio = this.value / this.max;
        var direction = volumeRatio - soundStateTracker.previousVolume;
        soundStateTracker.previousVolume = volumeRatio;
        audio.volume = volumeRatio;

        soundButton.getElementsByTagNameNS("http://www.w3.org/2000/svg", "title")[0].textContent = "Button to change sound options - current volume: " + volumeRatio * 100 + "%";

        soundButton.title = "Button to change sound options";
        soundButton.description = "Change sound options";

        // positive direction is increase in volume
        if (direction > 0) {
            if (audio.volume >= soundStateTracker.soundGates.max && !soundStateTracker.level3Visible) {
                soundStateTracker.level3Visible = true;
                soundButton.getElementById("soundIconRay3NoneToFull").beginElement();
            }

            if (audio.volume > soundStateTracker.soundGates.upper && !soundStateTracker.level2Visible) {
                soundStateTracker.level2Visible = true;
                soundButton.getElementById("soundIconRay2NoneToFull").beginElement();
            }

            if (audio.volume > soundStateTracker.soundGates.lower && !soundStateTracker.level1Visible) {
                soundStateTracker.level1Visible = true;
                soundButton.getElementById("soundIconRay1NoneToFull").beginElement();
            }

            if (audio.volume > soundStateTracker.soundGates.base && !soundStateTracker.level0Visible) {
                soundStateTracker.level0Visible = true;
                soundButton.getElementById("soundIconRayMuteFullToNone").beginElement();
            }
        } else if (direction < 0) { // decrease in volume
            if (audio.volume <= soundStateTracker.soundGates.max && soundStateTracker.level3Visible) {
                soundStateTracker.level3Visible = false;
                soundButton.getElementById("soundIconRay3FullToNone").beginElement();
            }

            if (audio.volume <= soundStateTracker.soundGates.upper && soundStateTracker.level2Visible) {
                soundStateTracker.level2Visible = false;
                soundButton.getElementById("soundIconRay2FullToNone").beginElement();
            }

            if (audio.volume <= soundStateTracker.soundGates.lower && soundStateTracker.level1Visible) {
                soundStateTracker.level1Visible = false;
                soundButton.getElementById("soundIconRay1FullToNone").beginElement();
            }

            if (audio.volume <= soundStateTracker.soundGates.base && soundStateTracker.level0Visible) {
                soundStateTracker.level0Visible = false;
                soundButton.getElementById("soundIconRay0FullToNone").beginElement();
            }
        }
    });

    function getPoster(filename, type) {
        return new Promise(function (resolve, reject) {
            var request = new XMLHttpRequest();
            request.open("GET", "//assets.localcity.com/audio/" + type + "posters/" + filename + "." + type + ".svg", true);

            request.onload = function () {
                if (this.status >= 200 && this.status < 400) {
                    resolve(document.importNode(this.responseXML.firstChild, true));
                } else {
                    reject(Error({status: this.status, statusText: this.statusText}));
                }
            };

            request.onerror = function () {
                console.log(this);
                reject(Error({status: this.status, statusText: this.statusText}));
            };
            request.send();
        });
    }

    function getOtherMediaLink() {
        return new Promise(function (resolve, reject) {
            var request = new XMLHttpRequest();
            request.open("GET", "http://api.localcity.com:5000/v/1/0/video_end_follow_on", true);

            request.onload = function () {
                if (this.status >= 200 && this.status < 400) {
                    resolve(this.response);
                } else {
                    reject(Error({status: this.status, statusText: this.statusText}));
                }
            };

            request.onerror = function () {
                reject(Error({status: this.status, statusText: this.statusText}));
            };
            request.send();
        });
    }

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
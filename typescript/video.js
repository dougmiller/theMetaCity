var VideoBuilder = /** @class */ (function () {
    function VideoBuilder(video) {
        var _this = this;
        this.isPlaying = function () {
            return !(_this.video.paused || _this.video.ended || _this.video.seeking || _this.video.readyState < _this.video.HAVE_FUTURE_DATA);
        };
        this.playPause = function () {
            if (_this.isPlaying()) {
                _this.video.pause();
            }
            else {
                _this.video.play();
            }
        };
        this.played = function () {
        };
        this.video = video;
        this.hasPlayed = false;
        this.video.addEventListener("click", this.playPause);
        this.video.addEventListener("play", this.played);
    }
    return VideoBuilder;
}());

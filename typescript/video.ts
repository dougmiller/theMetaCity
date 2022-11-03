class Builder {
    private video: Video;
    private containerDiv: HTMLDivElement;

    constructor() {
        this.containerDiv = <HTMLDivElement>document.getElementById("j");
        this.video = new Video(<HTMLVideoElement>document.getElementById("video"));
    }
}

class Video {
    private video: HTMLVideoElement;
    private hasPlayed: boolean;
    private readonly image: HTMLImageElement;

    constructor(video:HTMLVideoElement) {
        this.video = video;
        this.hasPlayed = false;
        this.image = new HTMLImageElement()
        this.video.addEventListener("click", this.playPause);
        this.video.addEventListener("play", this.played);
    }

    private isPlaying = () => {
        return !(this.video.paused || this.video.ended || this.video.seeking || this.video.readyState < this.video.HAVE_FUTURE_DATA);
    }

    private playPause = () => {
        if (this.isPlaying()) {
            this.video.pause();
        } else {
            this.video.play();
        }
    };

    private played = () => {}
}


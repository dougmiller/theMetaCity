#!/bin/sh
POSTGRES="psql --username ${POSTGRES_USER}"

echo "Populating Media"
echo "======"

$POSTGRES <<-SQL
  \c themetacity;
  SET ROLE ${MEDIA_ADMIN_USER};


COPY media.licence (id, licence_name, licence_text, licence_url, image_url) FROM stdin;
1	CC ASA4 International	Creative Commons Attribution-ShareAlike 4.0 International License	https://creativecommons.org/licenses/by-sa/4.0/	CC-SA-int.svg
\.


COPY media.postcard (id, url, title, alt_text) FROM stdin;
2	foundmalwaredecode.png	Found Malware Decode	Found Malware Decode Poster
3	2013qldboulderingcomp.png	2013 Bouldering Competition Timelapse poster.	A nice view of the central bouldering rock, with climbers on it.
4	paperprototypingv01c2008.png	Paper Protoyping Tutorial Poster	A quick screenshot of the beggining of the Paper Prototyping tutorial
5	timelapsebrisbanecity.png	First iteration of the Brisbane City time lapse	A view of the Brisbane City scape taken from the top of the KP cliffs taken form the first iteration of the auto taker
6	timelapsebrisbanecitybetter2014.png	Brisbane City Timelapse 2014	A new view of the Brisbane City scape taken from part of the second version of the auto taker
7	tmccodeswarm0614.png	Code Swarm from from the MetaCity 2006 to 2014	A from the the Code Swarm of the MetAcity 2006 to 2014 SVN/Git repos
8	genericaudio.svg	Generic Audio Poster	A generic poster for an audio file
1	genericvideo.svg	Generic Video Poster	A generic poster for a video file
9	currawongsofbrisbane2017.jpg	Currawong in Cradle Mountain	An image of a Currawong in a tree taken in Cradle Mountian
\.


COPY media.media_item (id, title, about, licence, date_published, postcard) FROM stdin;
2	QLD state bouldering comp 2013 timelapse	<p>A timelapse of the 2013 Queensland State Bouldering Championships held at Urban Climb, West End on 13-14 July 2013.</p> <p>In case you were wondering I cam in the top 10% of people that made the top 90% possible.</p> <p>The amount of chalk in the air was quite amazing.</p>	1	2014-03-02	3
6	Paper Protoytping Tutorial	<p>A video I recorded circa 2008 showing a brief intoduction to paper prototyping</p>	1	2014-04-22	4
1	Brisbane City Timelapse 2011	<p> A Video produced to show off the first iteration of the Canon 400D <a href="https://www.themetacity.com/workshop/3">auto taker detailed here</a> . </p> <p>The original photos were taken on 27/2/2011 form the top of the Kangaroo Point Cliffs in Brisbane, Australia using a 50mm prime lens. The shoot started at 6:00pm and finished at 7:42pm.</p>	1	2014-03-01	5
5	Brisbane City Timelapse 2014	<p>A comparitive video showing the <a href="https://www.themetacity.com/workshop/3">second iteration of the arduino auto taker</a>. This version solved the not-adjusting-apeture bug with much nicer results.</p> <p>The pictures were again taken at the top of Kangaroo Point Cliffs although this time the focus was pulled back to 18mm. The shoot started at 17:37 and finished at 19:54.</p>	1	2014-03-05	6
4	Code Swarm of theMetaCity 2006-2014	<p>theMetaCity was started as a student project in 2006 and has evolved greatly in the 8 years since then.</p> <p> This video uses <a href="https://github.com/rictic/code_swarm">Peter Burn's fork of Code Swarm</a> to visualise this journey form some shitty JSP code and SVN to slightly less shitty JSP code and Git. </p>	1	2014-03-04	7
3	Found malware decode	<p>I found some malware at work and went about de-obfuscate it.</p> <p>This video was as much a test of the built in cinnamon screen recording software as it was an interesting little project.</p>	1	2014-03-03	2
7	Currawongs of Brisbane SE QLD	<p>A sample recording of the local Currawongs behind my house. Recorded on my new Zoom h5 and NTG2 microphone.</p>	1	2017-12-12	9
\.


COPY media.tags (id, tag) FROM stdin;
1	Timelapse
2	Tutorial
3	Brisbane
\.


COPY media.tags_joiner (tag_id, mediaitem_id) FROM stdin;
1	2
1	5
1	1
3	1
3	5
2	3
\.


COPY media.audio (id, parent_id, file_name, running_time, has_start_poster, has_end_poster) FROM stdin;
1	7	currawongsofbrisbane2017	61	f	f
\.


COPY media.audio_file (id, parent_audio, audio_codec, mime_type, extension, bit_rate, bit_depth, sample_rate, vbr_encoded, file_size) FROM stdin;
1	1	mp3	mpeg	mp3	\N	320	48000	f	2440494
2	1	vorbis	ogg	ogg	\N	\N	96000	t	1857785
3	1	wav	wav	wav	\N	32	96000	f	35141888
\.


COPY media.audio_track (id, parent_audio, type, src_lang, label) FROM stdin;
1	1	captions	en-AU	English
2	1	chapters	en-AU	English
\.



COPY media.video (id, parent_id, file_name, running_time, has_start_poster, has_end_poster, has_fullscreen, resolution) FROM stdin;
1	1	timelapsebrisbanecity	45	f	f	t	640x426
2	2	2013qldboulderingcomp	106	f	f	t	600x400
3	3	foundmalwaredecode	90	t	f	t	640x360
4	4	tmccodeswarm0614	686	t	f	f	800x600
5	5	timelapsebrisbanecitybetter2014	129	t	f	t	968x644
6	6	paperprototypingv01c2008	383	t	f	f	640x480
\.

COPY media.video_file (id, parent_video, video_codec, audio_codec, mime_type, extension, resolution, file_size, is_fullscreen) FROM stdin;
1	1	vp8	nill	webm	webm	640x426	1848007	f
2	1	theora	nill	ogg	ogv	640x426	900044	f
3	2	h264	nill	mp4	mp4	600x400	10147489	f
4	2	vp8	nill	webm	webm	600x400	13717160	f
5	2	h264	nill	mp4	mp4	1622x1080	50304686	t
6	2	vp8	nill	webm	webm	1622x1080	20196240	t
7	3	h264	nill	mp4	mp4	640x360	9347829	f
8	3	vp8	nill	webm	webm	640x360	1542709	f
9	3	h264	nill	mp4	mp4	1920x1080	46291312	t
10	3	vp8	nill	webm	webm	1920x1080	3134497	t
11	4	vp8	nill	webm	webm	800x600	8453683	f
13	5	vp8	nill	webm	webm	968x644	64137597	f
12	5	h264	nill	mp4	mp4	968x644	20272410	f
14	5	h264	nill	mp4	mp4	1622x1080	40702711	t
15	5	vp8	nill	webm	webm	1622x1080	63766185	t
16	6	vp8	vorbis	webm	webm	640x480	13615140	f
\.

COPY media.video_track (id, parent_video, type, src_lang, label) FROM stdin;
1	5	descriptions	en-AU	English
2	6	subtitles	en-AU	English
\.


SQL
echo "======"
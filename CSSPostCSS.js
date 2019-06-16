console.log("CSS changed. Processing...");

var postcss = require('postcss');
var fs = require('fs');

var postcss_import = require('postcss-import');
var postcss_custom_media = require('postcss-custom-media');
var postcss_css_variables = require('postcss-css-variables');
var postcss_discard_comments = require('postcss-discard-comments');
var postcss_autoprefixer = require('autoprefixer');
var postcss_reporter = require('postcss-reporter');
var postcss_nested = require('postcss-nested');
var css_nano = require('cssnano');

var options = {
    from: 'pcss/style.css',
    to: 'tmc/static/css/style.css',
    map: { inline: true }
};

var css = fs.readFileSync("pcss/style.pcss", "utf8");

postcss([
    postcss_import,
    postcss_custom_media,
    postcss_css_variables,
    postcss_nested,
    postcss_discard_comments,
    postcss_autoprefixer,
    postcss_reporter,
    //css_nano
])
.process(css, options)
.then(function (result) {
    fs.writeFileSync('tmc/static/css/style.css', result.css);
    console.log("CSS finished");
}, function(error) {
    console.log(error);
    console.log("CSS error");
});


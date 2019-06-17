console.log("CSS changed. Processing...");

var FPPostCSS = require('postcss');
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
    from: 'pcss/front-page.css',
    to: 'tmc/static/css/front-page.css'
};

var css = fs.readFileSync("pcss/front-page.pcss", "utf8");

FPPostCSS([
    postcss_import,
    postcss_custom_media,
    postcss_css_variables,
    postcss_nested,
    postcss_discard_comments,
    postcss_autoprefixer,
    postcss_reporter,
    css_nano
])
.process(css, options)
.then(function (result) {
    fs.writeFileSync('tmc/static/css/front-page.css', result.css);
    console.log("FP CSS finished");
}, function(error) {
    console.log(error);
    console.log("FP CSS error");
});


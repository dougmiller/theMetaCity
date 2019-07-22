console.log("FP CSS dev build processing...");

var FPPostCSS = require('postcss');
var fs = require('fs');
var postcss_import = require('postcss-import');
var postcss_custom_media = require('postcss-custom-media');
var postcss_css_variables = require('postcss-css-variables');
var postcss_autoprefixer = require('autoprefixer');
var postcss_reporter = require('postcss-reporter');
var postcss_nested = require('postcss-nested');

var options = {
    from: 'pcss/front-page.css',
    to: 'tmc/static/css/front-page.css',
    map: { inline: false }
};

var css = fs.readFileSync("pcss/front-page.pcss", "utf8");

FPPostCSS([
    postcss_import,
    postcss_custom_media,
    postcss_css_variables,
    postcss_nested,
    postcss_autoprefixer,
    postcss_reporter
])
.process(css, options)
.then(function (result) {
    fs.writeFileSync('tmc/static/css/front-page.css', result.css);
    console.log("FP CSS dev build finished");
}, function(error) {
    console.log(error);
    console.log("FP CSS dev build error");
});


console.log("Main CSS dev build processing");

var postcss = require('postcss');
var fs = require('fs');

var postcss_import = require('postcss-import');
var postcss_custom_media = require('postcss-custom-media');
var postcss_css_variables = require('postcss-css-variables');
var postcss_autoprefixer = require('autoprefixer');
var postcss_reporter = require('postcss-reporter');
var postcss_nested = require('postcss-nested');

var options = {
    from: 'pcss/article.css',
    to: 'tmc/static/css/style.css',
    map: { inline: false }
};

var css = fs.readFileSync("pcss/article.pcss", "utf8");

postcss([
    postcss_import,
    postcss_custom_media,
    postcss_css_variables,
    postcss_nested,
    postcss_autoprefixer,
    postcss_reporter,
])
.process(css, options)
.then(function (result) {
    fs.writeFileSync('tmc/static/css/style.css', result.css);
    console.log("Main CSS dev build completed");
}, function(error) {
    console.log(error);
    console.log("Main CSS prod build error");
});


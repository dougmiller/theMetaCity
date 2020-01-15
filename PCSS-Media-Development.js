console.log("CSS changed. Processing...");

let postcss = require('postcss');
let fs = require('fs');

let postcss_import = require('postcss-import');
let postcss_nested = require('postcss-nested');
let postcss_css_variables = require('postcss-css-variables');
let postcss_autoprefixer = require('autoprefixer');
let postcss_reporter = require('postcss-reporter');
let css_nano = require('cssnano');

let options = {
    from: 'pcss/media.pcss',
    to: 'tmc/media/static/css/style.css',
    map: { inline: true }
};

let css = fs.readFileSync("pcss/media.pcss", "utf8");

postcss([
    postcss_import,
    postcss_nested,
    postcss_css_variables,
    postcss_autoprefixer,
    postcss_reporter,
    //css_nano
])
.process(css, options)
.then(function (result) {
    fs.writeFileSync('tmc/media/static/css/style.css', result.css);
    console.log("CSS finished");
}, function(error) {
    console.log(error);
    console.log("CSS error");
});

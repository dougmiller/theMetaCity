console.log("Home CSS dev build processing...");

let postcss = require('postcss');
let fs = require('fs');
let postcss_import = require('postcss-import');
let postcss_css_variables = require('postcss-css-variables');
let postcss_autoprefixer = require('autoprefixer');
let postcss_reporter = require('postcss-reporter');
let postcss_nested = require('postcss-nested');

let options = {
    from: 'pcss/home.pcss',
    to: 'tmc/home/static/css/home.css',
    map: { inline: false }
};

let css = fs.readFileSync("pcss/home.pcss", "utf8");

postcss([
    postcss_import,
    postcss_nested,
    postcss_css_variables,
    postcss_autoprefixer,
    postcss_reporter
])
.process(css, options)
.then(function (result) {
    fs.writeFileSync('tmc/home/static/css/home.css', result.css);
    console.log("Home CSS dev build finished");
}, function(error) {
    console.log(error);
    console.log("Home CSS dev build error");
});


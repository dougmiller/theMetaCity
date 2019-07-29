console.log("FP CSS dev build processing...");

let FPPostCSS = require('postcss');
let fs = require('fs');
let postcss_import = require('postcss-import');
let postcss_custom_media = require('postcss-custom-media');
let postcss_css_letiables = require('postcss-css-letiables');
let postcss_autoprefixer = require('autoprefixer');
let postcss_reporter = require('postcss-reporter');
let postcss_nested = require('postcss-nested');

let options = {
    from: 'pcss/front-page.css',
    to: 'tmc/static/css/front-page.css',
    map: { inline: false }
};

let css = fs.readFileSync("pcss/front-page.pcss", "utf8");

FPPostCSS([
    postcss_import,
    postcss_custom_media,
    postcss_css_letiables,
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


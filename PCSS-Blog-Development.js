console.log("Main CSS dev build processing");

let postcss = require('postcss');
let fs = require('fs');
let postcss_import = require('postcss-import');
let postcss_nested = require('postcss-nested');
let postcss_css_variables = require('postcss-css-variables');
let postcss_autoprefixer = require('autoprefixer');
let postcss_reporter = require('postcss-reporter');

let options = {
    from: 'pcss/blog.pcss',
    to: 'tmc/blog/static/css/style.css',
    map: { inline: false }
};

let css = fs.readFileSync("pcss/blog.pcss", "utf8");

postcss([
    postcss_import,
    postcss_nested,
    postcss_css_variables,
    postcss_autoprefixer,
    postcss_reporter,
])
.process(css, options)
.then(function (result) {
    fs.writeFileSync('tmc/blog/static/css/style.css', result.css);
    console.log("Blog CSS dev build completed");
}, function(error) {
    console.log(error);
    console.log("Blog CSS prod build error");
});


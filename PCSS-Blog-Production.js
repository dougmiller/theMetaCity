console.log("Blog CSS prod build processing");

let fs = require('fs');
let postcss = require('postcss');
let postcss_import = require('postcss-import');
let postcss_nested = require('postcss-nested');
let postcss_discard_comments = require('postcss-discard-comments');
let css_nano = require('cssnano');

let options = {
    from: 'pcss/blog.pcss',
    to: 'tmc/blog/static/css/style.css',
    map: false
};

var css = fs.readFileSync("pcss/blog.pcss", "utf8");

postcss([
    postcss_import,
    postcss_nested,
    postcss_discard_comments,
    css_nano
])
.process(css, options)
.then(function (result) {
    fs.writeFileSync('tmc/blog/static/css/style.css', result.css);
    console.log("Blog CSS prod build completed");
}, function(error) {
    console.log(error);
    console.log("Blog CSS prod build error");
});


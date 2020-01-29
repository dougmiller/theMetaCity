console.log("Blog CSS prod build processing");

var postcss = require('postcss');
var fs = require('fs');

var postcss_import = require('postcss-import');
var postcss_nested = require('postcss-nested');
var postcss_discard_comments = require('postcss-discard-comments');
var css_nano = require('cssnano');

var options = {
    from: 'pcss/blog/article.css',
    to: 'tmc/blog/static/css/style.css',
    map: false
};

var css = fs.readFileSync("pcss/blog/article.pcss", "utf8");

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


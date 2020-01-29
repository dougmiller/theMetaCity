console.log("Main CSS dev build processing");

let fs = require('fs');
let postcss = require('postcss');
let postcss_import = require('postcss-import');
let postcss_nested = require('postcss-nested');

let options = {
    from: 'pcss/blog.pcss',
    to: 'blog/static/css/style.css',
    map: { inline: false }
};

let css = fs.readFileSync("pcss/blog.pcss", "utf8");

postcss([
    postcss_import,
    postcss_nested
])
.process(css, options)
.then( result => {
    fs.writeFileSync('tmc/blog/static/css/style.css.map', result.map);
    fs.writeFileSync('tmc/blog/static/css/style.css', result.css);
    console.log("Blog CSS dev build completed");
}, function(error) {
    console.log(error);
    console.log("Blog CSS prod build error");
});


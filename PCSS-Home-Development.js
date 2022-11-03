console.log("Home CSS dev build processing...");

let postcss = require('postcss');
let fs = require('fs');
let postcss_import = require('postcss-import');
let postcss_nested = require('postcss-nested');

let options = {
    from: 'pcss/home.pcss',
    to: 'tmc/home/static/css/style.css',
    map: { inline: false }
};

let css = fs.readFileSync("pcss/home.pcss", "utf8");

postcss([
    postcss_import,
    postcss_nested,
])
.process(css, options)
.then(function (result) {
    fs.writeFileSync('tmc/home/static/css/style.css', result.css.toString());
    fs.writeFileSync('tmc/home/static/css/style.css.map', result.map.toString());
    console.log("Home CSS dev build finished");
}, function(error) {
    console.log(error);
    console.log("Home CSS dev build error");
});


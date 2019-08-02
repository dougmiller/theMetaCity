const fs = require("fs-extra");
const chownr = require("chownr");
const deploy_dir = "/media/www.themetacity.com";
const deploy_folder = "tmc";

try {
    console.log("Removing old directory");
    fs.removeSync(deploy_dir + "/" + deploy_folder);
    console.log("Removed");
    console.log("Copying folder");
    fs.copySync(deploy_folder, deploy_dir + "/" + deploy_folder);
    console.log('Copied');
    //chownr(deploy_dir + "/" + deploy_folder, 33, 33, function() {});
} catch (err) {
    console.error(err)
}

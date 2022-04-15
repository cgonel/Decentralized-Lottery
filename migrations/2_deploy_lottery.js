const Lottery = artifacts.require("Lottery");

module.exports = function (deployer) {
    deployer.deploy(Lottery, 300, 1, 2266);
}
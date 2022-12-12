var assert = require('assert');
var getIn = require('../index.js');
const ag = require('./index.js');

console.log(getIn);

var object = {
    firstName: "Ahmed",
    lastName: "Gad",
    address: {
        home: {
            addressLines: {
                1: "Flat 304",
                2: "Crockemwell road"
            }
        }
    },
    customerType : {
        retail: {
            channel: "Top100",
            spending: "Top10",
        }
    }
};
describe('Index', function() {
  describe('#ag', function() {
    it('Should throw error for invalid JSON', function() {
      assert.throws(function () { ag("", ["key"]) }, Error, "Invalid JSON");
    });
    it('Should throw error for invalid Keys', function() {
      assert.throws(function () { ag(object, []) }, Error, "Invalid Keys");
    });
    it('Should give the firstname ', function () {
          assert.equal(ag(object,['firstName']), object.firstName);
    });  
    it('Should give the  object.address.home.addressLines', function () {
          assert.equal(ag(object,[ "address", "home", "addressLines"]), object.address.home.addressLines);
    });
    it('Should give the  object.address.home.addressLines[2]', function () {
          assert.equal(ag(object,[ "address", "home", "addressLines","2"]), object.address.home.addressLines[2]);
    });
    it('Should give the null', function () {
          assert.equal(ag(object,["hello", "none", "reve", "hello"]), null);
    }); 
  });
});
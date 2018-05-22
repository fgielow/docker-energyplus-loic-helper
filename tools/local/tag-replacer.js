'use strict';

var _ = require('lodash'),
  fs = require('fs'),
  Promise = require('bluebird'),
  uuidv1 = require('uuid/v1');

var uuid = uuidv1();

var RANGE = function(min,max,samples) {
  var set = [];
  for (var i=0; i <= samples-1; i++) {
    var pct = i /(samples-1);
    var val = min + pct * (max - min);
    set.push(val);
  }
  return set;
};

var FIXED = function(set) {
  return set;
};

// YOU CAN EDIT THIS
var REPLACEMENTS = [
  ['@@OffTmSet@@',RANGE(18,24,10)],
  ['@@OffTmCool@@',RANGE(20,33,10)],
  ['@@ElAll@@',RANGE(0,20,20)],
  ['@@LiOff@@',RANGE(0,20,20)],
  ['@@LiLED@@',RANGE(0,20,20)],
  ['@@PeOff@@',RANGE(0,0.5,20)],
  ['@@Infil@@',RANGE(0.00001,0.01,20)],
  ['@@InPlen@@',RANGE(0.00001,0.01,20)]
];

// YOU COULD ALSO USE FOR FIXED SETS:
// ['@@fixedExample@@',FIXED([1,2,'a'])]

var SIMULATIONS = 10 * REPLACEMENTS.length;

// YOU CAN EDIT THIS
var INPUT_FILE = 'input-files/tagged/in.idf';
var OUTPUT_DIR = 'input-files/raw/';

function getRandomInt(max) {
  return Math.floor(Math.random() * Math.floor(max));
}

var calculate_random_replacement_set = function() {
  var set = [];

  _.each(REPLACEMENTS,function(rep) {
    var ndx = getRandomInt(rep[1].length);
    var val = rep[1][ndx];
    
    var rep_ = [rep[0],val];
    set.push(rep_);
  });

  return set;
};

String.prototype.replaceAll = function(search, replacement) {
    var target = this;
    return target.replace(new RegExp(search, 'g'), replacement);
};

var all_sets = {};

var replaceTags = function(data, replace_set, ndx)  {
  var fn = function() {
    return new Promise(function(resolve,reject) {
      _.each(replace_set,function(rep) {
        data = data.replaceAll(rep[0],rep[1]);
      });

      var INPUT_FILENAME = INPUT_FILE.split('/').slice(-1)[0];
      var OUTPUT_FILE = OUTPUT_DIR +uuid +'-'+ ndx + '/'+ INPUT_FILENAME;

      if (!fs.existsSync(OUTPUT_DIR +uuid +'-'+ ndx)){
          fs.mkdirSync(OUTPUT_DIR +uuid +'-'+ ndx);
      }

      fs.writeFile(OUTPUT_FILE, data, function(err) {
          if(err) {
            return console.log(err);
            reject(err);
          }
          console.log("File ndx " + ndx + " was saved!");
          all_sets[ndx] = replace_set;

          resolve();
      }); 
    });
  } // end fn

  return fn;
};

var storeReplacementsCSV = function() {

  var variables = _.map(REPLACEMENTS,function(rep) {
    return rep[0];
  });

  var csv = 'ID;';
  _.each(variables,function(v) {
    csv += v + ';';
  });
  csv += '\n';

  _.each(all_sets,function(val,key) {
    csv += key+';';
    _.each(variables,function(v) {
      var val_v = _.filter(val,function(vv){
        return vv[0] == v;
      });
      csv += val_v[0][1] + ';';
    });
    csv += '\n';
  });

  var OUTPUT_FILE = OUTPUT_DIR + uuid+'_mappings.csv';

  fs.writeFile(OUTPUT_FILE, csv, function(err) {
      if(err) {
        console.log(err);
      } else {
        console.log('CSV stored.');
      }
  }); 
};


var delay = function(timeout) {
  return new Promise(function (resolve) {
    setTimeout(resolve, timeout);
  });
};

var resolvePromisesRecursive = function(promises,n) {
  console.log(promises.length);
  if (n < promises.length) {
    return promises[n]().then(function() {
      return delay(0).then(function() {
        return resolvePromisesRecursive(promises,n + 1);
      });
    }).catch(function() {
      return resolvePromisesRecursive(promises,n + 1);
    });
  } else {
    return Promise.resolve();
  }
};



fs.readFile(INPUT_FILE, 'utf8', function (err,data) {

  if (err) {
    console.error(err);
  } else {

    var promises = [];

    for (var i=0; i<SIMULATIONS; i++) {

      var data_copy = data;

      var rep_set = calculate_random_replacement_set();

      var p = replaceTags(data_copy,rep_set,i);

      promises.push(p);
    } // end for 

    resolvePromisesRecursive(promises,0).then(function() {
      console.log('store CSV');
      storeReplacementsCSV();
    }); 

  } // end else no error

}); // end read File



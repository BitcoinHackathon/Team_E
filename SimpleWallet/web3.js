var web3 = {
    // Promise http://igomobile.de/2017/03/06/wkwebview-return-a-value-from-native-code-to-javascript/
    // object for storing references to our promise-objects
    promises: {},

    // generates a unique id, not obligator a UUID
    generateUUID: function() {
        var d = new Date().getTime();
        var uuid = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
                                                                  var r = (d + Math.random()*16)%16 | 0;
                                                                  d = Math.floor(d/16);
                                                                  return (c=='x' ? r : (r&0x3|0x8)).toString(16);
                                                                  });
        return uuid;
    },
    // this funciton is called by native methods
    // @param promiseId - id of the promise stored in global variable promises
    resolvePromise: function(promiseId, data, error) {
        if (error){
            web3.promises[promiseId].reject(error);

        } else{
            web3.promises[promiseId].resolve(data);
        }
        // remove referenfe to stored promise
        delete web3.promises[promiseId];
    },

    bch: {
        getAddless: function() {
            var promise = new Promise(function(resolve, reject) {
                                      // we generate a unique id to reference the promise later
                                      // from native function
                                      var promiseId = web3.generateUUID();
                                      // save reference to promise in the global variable
                                      web3.promises[promiseId] = { resolve, reject};

                                      try {
                                          // call native function
                                          window.webkit.messageHandlers.getAddress.postMessage({promiseId: promiseId})
                                      }
                                      catch(exception) {
                                          alert(exception);
                                      }

                                      });

            return promise;
        },

        sendTransactionToAddress: function(cash_address, value) {
            window.webkit.messageHandlers.sendTransactionToAddress.postMessage({cash_address: cash_address, value: value})
        }
    },
};

web3.bch.getAddless().then(function(address) {
                                            console.log(address);
                                            }, function(error) {
                                            console.log(error);
                                            });

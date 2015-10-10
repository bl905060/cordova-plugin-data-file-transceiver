module.exports = {
    upload: function(postURL, postData, successCallback, errorCallback) {
        cordova.exec(successCallback,
                     errorCallback,
                     "dataTransfer",
                     "upload",
                     [postURL, postData]);
    }
};
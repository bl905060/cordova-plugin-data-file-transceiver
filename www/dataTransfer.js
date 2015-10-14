module.exports = {
    upload: function(postURL, postData, successCallback, errorCallback) {
        var photoURL = postData.photoURL;
        cordova.exec(successCallback,
                     errorCallback,
                     "dataTransfer",
                     "upload",
                     [postURL, postData, photoURL]);
    }
};
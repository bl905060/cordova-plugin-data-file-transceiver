module.exports = {
    upload: function(postURL, postData, successCallback, errorCallback) {
        var photoURL;
        var voiceURL;
        
        if (postData.photoURL != undefined) photoURL = postData.photoURL;
        if (postData.voiceURL != undefined) voiceURL = postData.voiceURL;
        
        alert(photoURL);
        alert(voiceURL);
        
        cordova.exec(successCallback,
                     errorCallback,
                     "dataTransfer",
                     "upload",
                     [postURL, postData, photoURL, voiceURL]);
    }
};
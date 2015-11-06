module.exports = {
    upload: function(postURL, postData, successCallback, errorCallback) {
        var photoURL = new Array();
        var voiceURL = new Array();
        
        if ((postData.photoURL != undefined) && postData.voiceURL) {
            photoURL = postData.photoURL;
        }
        if ((postData.voiceURL != undefined) && postData.voiceURL) {
            voiceURL = postData.voiceURL;
        }
        
        postData.photoURL = undefined;
        postData.voiceURL = undefined;
        
        //alert(photoURL);
        //alert(voiceURL);
        
        cordova.exec(successCallback,
                     errorCallback,
                     "dataTransceiver",
                     "upload",
                     [postURL, postData, photoURL, voiceURL]);
    }
};
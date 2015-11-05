module.exports = {
    upload: function(postURL, postData, successCallback, errorCallback) {
        var photoURL = new Array();
        var voiceURL = new Array();
        
        if (postData.photoURL != undefined) {
            photoURL = postData.photoURL;
            postData.photoURL = undefined;
        }
        if (postData.voiceURL != undefined) {
            voiceURL = postData.voiceURL;
            postData.voiceURL = undefined;
        }
            
        //alert(photoURL);
        //alert(voiceURL);
        
        cordova.exec(successCallback,
                     errorCallback,
                     "dataTransceiver",
                     "upload",
                     [postURL, postData, photoURL, voiceURL]);
    }
};
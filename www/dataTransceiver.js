module.exports = {
    upload: function(postURL, postData, successCallback, errorCallback) {
        var photoURL = new Array();
        var voiceURL = new Array();
        
        if ((postData.photoURL != undefined) && (postData.photoURL.length > 0)) {
            photoURL = postData.photoURL;
        }
        if ((postData.voiceURL != undefined) && (postData.voiceURL.length > 0)) {
            voiceURL = postData.voiceURL;
        }
        
        //alert("photoURL length: " + postData.photoURL.length);
        //alert("photoURL: " + postData.photoURL);
        //alert("voiceURL length: " + postData.voiceURL.length);
        //alert("voiceURL: " + postData.voiceURL);
        
        postData.photoURL = undefined;
        postData.voiceURL = undefined;
        
        cordova.exec(successCallback,
                     errorCallback,
                     "dataTransceiver",
                     "upload",
                     [postURL, postData, photoURL, voiceURL]);
    },
    
    download: function(successCallback, errorCallback) {
        cordova.exec(successCallback,
                     errorCallback,
                     "dataTransceiver",
                     "download",
                     []);
    }
};
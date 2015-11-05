##cordova-plugin-data-file-transceiver

**Cordova / PhoneGap 数据、文件传输插件**：具备数据、多个文件的上传下载功能

## 安装

#### 从Github安装最新版本

```
https://github.com/bl905060/cordova-plugin-data-file-transceiver.git
```

## 使用

### 上传

```js
//设置上传所使用的HTTP URL
var postURL = "http://127.0.0.1/demo_upload.php";

//设置json对象
var test = {
    "testjson" : "json",
    "testcomputer" : "Apple"
};

//设置需要上传的数据，可以包含单个字段也可以包含json对象，但URL必须是数组格式（包含只有一个URL的情形）
var sendData = {
    "user_id" : "1234567890",//单个字符字段
    "photocount" : photocount,//单个变量字段
    "photoidprefix" : photoidprefix,
    "photoURL" : photoURL,//数组类型URL字段
    "voiceid" : voiceid,
    "voice_len" : voice_len,
    "voiceURL" : voiceURL,//数组类型URL字段
    "test" : test//json对象类型字段
};

dataTransceiver.upload(postURL, sendData, uploadSuccessCallBack, uploadFailCallBack);

function uploadSuccessCallBack(response) {
    alert(JSON.stringify(response));
}
                
function uploadFailCallBack(response) {
    alert(response);
}
```

### 下载
尚未完成

## 平台支持

iOS (7+) only.

# 自定义内购页

#### 配置好自己的内购页后，上传至网站，发布给app后，服务器会下发给客户端，客户端使用不涉及网络通信，几乎可以实现原生内购页的效果。
##### 网站支持：https://dingyue.io/


## 使用方法 及 注意事项

### 1.在index.html文件中自定义自己的样式，（示例模板使用vue编写，但自定义书写并不局限于vue，可完全自定义。）
### 2.内购h5与原生交互; 注意需将以下几个事件按照规定要求去写，默认模板已经实现以下几个事件的交互，可以用作参考（涉及到与原生交互，务必按要求编写，否则将实现不了购买功能）
####  window.webkit.messageHandlers.${"方法名"}.postMessage(${"参数"})
##### （1）页面关闭事件   -方法名：vip_close  -参数{ type: "close_web"}
##### （2）点击恢复购买   -方法名：vip_restore  -参数{ type: "restore_web"}
##### （3）点击服务条款  -方法名：vip_terms  -参数{ type: "terms_web"}
##### （4）点击隐私协议   -方法名：vip_privacy  -参数{ type: "privacy_web"}
##### （5）购买事件  -方法名：vip_purchase  -参数{ type: "purchase_web", productId: ${"产品ID"} }
##### （6）选择订阅产品  -方法名：vip_choose  -参数 { type: "SUBSCRIPTION",productId: productId,period:"WEEK" }
###### type:订阅类型；period：周期（可选，一次性订阅，消耗品，非自动续期订阅无周期）productId: 产品id （当用户选择某产品时将此事件汇报给原生端）
##### （7）原生-h5 通过iostojs这一方法将系统语言传过来，将{"system_language":"语言"}先base64加密，然后转为JSON字符串，具体解析方式请看index.html文件中的“iostojs”方法
### 3.配置内购项，仅需将此内购页的所有购买项ID填入purchase.json 文件中即可完成内购项的配置（注意：此处选填的内购项id需提前在订阅网站后台订阅配置页中配置）
### 4.按要求书写完成后需将文件按要求压缩为zip包
#### (1)终端执行 $ zip -r template.zip index.html vue.js purchase.json README.md 
#### (2)将生成的zip 文件上传至DingYue后台 
### 5.上传成功以后及可完成自定义内购页的创建
### 6.后续将创建成功的内购页发布给用户以后客户端即可显示
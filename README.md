# socketServer [->简书讲解](http://www.jianshu.com/p/81fd2464b14c)
![socket通讯](http://upload-images.jianshu.io/upload_images/1488115-aabd39cf6983688a.jpeg?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

一款用于测试socket数据的mac服务器 app

1.打开应用后，会自动获取本机ip并显示，端口默认8080

2.点击"开始监控"，进行端口8080的数据监听

3.当服务器接收到数据后会显示来源地址、端口以及数据内容，如果有多个socket连接到本服务器，则会进行数据转发

比如a、b、c同时连接socket服务器,那么

当a向服务器传送数据时，服务器会将数据转发给b、c，同理b发送数据时a和c也可收到


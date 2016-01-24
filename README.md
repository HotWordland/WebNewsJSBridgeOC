# 2016 - 01 -24 替换html里一些失效的图片
# WebNewsJSBridgeOC
一个完整的OC与JS交互 实现WebView里面的图片不用每次从网页加载 只需要第一次加载后就缓存 图片点击放大浏览
#演示

#点击浏览放大
![](https://github.com/HotWordland/WebNewsJSBridgeOC/blob/master/WebNewsJSBridgeOC.gif)
 
#思路
不加载html里的图片:替换HTML文本中默认的src 然后用SDWebImage将其url捕获进行缓存 等到缓存完后再进行替换Html。
点击放大:利用js交互 将html里的图片位置进行计算然后传递给OC 然后得到数据后进行页面上UI的逻辑处理

##LonLonStudio - WL -(重庆途尔旅行ios开发者巫龙 ^_^)

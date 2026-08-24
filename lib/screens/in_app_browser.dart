import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class InAppBrowserScreen extends StatefulWidget {
  const InAppBrowserScreen({super.key, required this.url, this.title='MleySoft'});
  final String url;
  final String title;
  @override State<InAppBrowserScreen> createState()=>_InAppBrowserScreenState();
}
class _InAppBrowserScreenState extends State<InAppBrowserScreen>{
  late final WebViewController controller;
  int progress=0;
  @override void initState(){super.initState();controller=WebViewController()..setJavaScriptMode(JavaScriptMode.unrestricted)..setNavigationDelegate(NavigationDelegate(onProgress:(v)=>setState(()=>progress=v)))..loadRequest(Uri.parse(widget.url));}
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:Text(widget.title),actions:[IconButton(onPressed:()=>controller.reload(),icon:const Icon(Icons.refresh))]),body:Column(children:[if(progress<100)LinearProgressIndicator(value:progress/100),Expanded(child:WebViewWidget(controller:controller))]));
}

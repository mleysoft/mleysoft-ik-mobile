import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
class ConnectivityBanner extends StatefulWidget{const ConnectivityBanner({super.key,required this.child});final Widget child;@override State<ConnectivityBanner> createState()=>_S();}
class _S extends State<ConnectivityBanner>{StreamSubscription<List<ConnectivityResult>>? sub;bool offline=false;@override void initState(){super.initState();Connectivity().checkConnectivity().then(check);sub=Connectivity().onConnectivityChanged.listen(check);}
 void check(List<ConnectivityResult> r){final v=r.isEmpty||r.every((x)=>x==ConnectivityResult.none);if(mounted&&v!=offline)setState(()=>offline=v);}@override void dispose(){sub?.cancel();super.dispose();}
 @override Widget build(BuildContext context)=>Column(children:[Expanded(child:widget.child),AnimatedSize(duration:const Duration(milliseconds:180),child:offline?Container(width:double.infinity,padding:const EdgeInsets.symmetric(horizontal:14,vertical:10),color:Colors.red.shade700,child:const SafeArea(top:false,child:Row(mainAxisAlignment:MainAxisAlignment.center,children:[Icon(Icons.wifi_off_rounded,color:Colors.white,size:18),SizedBox(width:8),Flexible(child:Text('İnternet bağlantınız kesildi',style:TextStyle(color:Colors.white,fontWeight:FontWeight.w700),textAlign:TextAlign.center))]))):const SizedBox.shrink())]);}

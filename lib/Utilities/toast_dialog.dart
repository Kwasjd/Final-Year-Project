import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

void toastDialog(String content){
  Fluttertoast.showToast(
    msg: content,
    gravity: ToastGravity.BOTTOM,
    timeInSecForIosWeb: 5,
    toastLength: Toast.LENGTH_SHORT,
    backgroundColor: Colors.blue,
    textColor: Colors.white,
    fontSize: 16.0,
  );
}
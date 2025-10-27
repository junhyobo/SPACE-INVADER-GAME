import 'dart:ui';

//Thêm lớp toast & biến trạng thái
class UiToast {  
  String text;
  Color color;
  double ttl; // giây còn lại
  UiToast(this.text, this.color, {this.ttl = 1.6});
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_endpoints.dart'; import '../../../core/network/dio_client.dart'; import '../../../shared/models/task_view.dart';
final taskViewProvider=StateNotifierProvider<TaskViewNotifier,List<TaskView>>((ref)=>TaskViewNotifier());
class TaskViewNotifier extends StateNotifier<List<TaskView>>{TaskViewNotifier():super(const[]);
Future<void> load()async{final r=await DioClient.instance.dio.get(ApiEndpoints.taskViews); final d=r.data; state=d is List?d.whereType<Map>().map((e)=>TaskView.fromJson(Map<String,dynamic>.from(e))).toList():[];}
Future<void> save({int? id,required String name,required String filters,required String sortRules,bool hidden=false})async{final data={'name':name,'filters':filters,'sort_rules':sortRules,'hidden':hidden};if(id==null){await DioClient.instance.dio.post(ApiEndpoints.taskViews,data:data);}else{await DioClient.instance.dio.put(ApiEndpoints.taskViewById(id),data:data);}await load();}
Future<void> delete(int id)async{await DioClient.instance.dio.delete(ApiEndpoints.taskViewById(id));await load();}
Future<void> reorder(List<TaskView> views)async{await DioClient.instance.dio.put(ApiEndpoints.taskViewsReorder,data:{'views':[for(var i=0;i<views.length;i++){'id':views[i].id,'sort_order':i+1,'hidden':views[i].hidden}]});await load();}}

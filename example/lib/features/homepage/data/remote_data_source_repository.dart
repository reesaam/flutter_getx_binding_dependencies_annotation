
import 'package:getx_dependencies_binding_annotation/getx_dependencies_binding_annotation.dart';

abstract class RemoteDataSourceRepository {
  getData();
  sendData();
}

@GetPut.repository(as: 'RemoteDataSourceRepository')
class RemoteDataSourceRepositoryImpl implements RemoteDataSourceRepository {

  @override
  getData() {}

  @override
  sendData() {}
}
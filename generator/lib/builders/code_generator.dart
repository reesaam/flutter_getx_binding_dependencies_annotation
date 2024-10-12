import 'dart:async';
import 'package:build/src/builder/build_step.dart';
import 'package:source_gen/source_gen.dart';
import '../components/descriptions_generator.dart';
import '../components/log.dart';
import '../models/extracted_info_model.dart';
import '../resources/constants.dart';
import '../resources/enums.dart';
import '../extensions/string.dart';
import '../resources/strings.dart';

class CodeGenerator extends Generator {

  /// List Variables to keep the data and then we will use them when generating the code
  /// This way everything, especially generating the code do so much faster and more efficient
  static List<ExtractedInfoModel> importsList = List<ExtractedInfoModel>.empty(growable: true);
  static List<ExtractedInfoModel> pagesList = List<ExtractedInfoModel>.empty(growable: true);
  static List<ExtractedInfoModel> controllersList = List<ExtractedInfoModel>.empty(growable: true);
  static List<ExtractedInfoModel> componentsList = List<ExtractedInfoModel>.empty(growable: true);
  static List<ExtractedInfoModel> repositoriesList = List<ExtractedInfoModel>.empty(growable: true);

  @override
  FutureOr<String?> generate(LibraryReader library, BuildStep buildStep) async {

    /// String Variables
    /// These variables will keep strings of generated code separately
    /// [statisticsCodeBody] the package will generate some statistics about received code which will put at the top of generated code
    /// [importsCodeBody] this is the [import] section, all the demanded imports will gather, save and finally generate here
    /// [pagesCodeBody] we have a section for store and generate pages which we should represent to [GetX] separately
    /// [initialPageString] in the pages section we should hold a initial page to represent to [GetX]
    /// [unknownPageString] therefore, we have a unknown route to represent
    /// [controllersCodeBody] controllers are controllers of the pages
    /// [componentsCodeBody] components are obvious
    /// [repositoriesCodeBody] repositories could include all the repositories in the app, everything that you can name as repository
    /// all these 3 fields are known as Controllers in the [GetX] but they can have separate meanings or concepts
    /// so we will separate them as meanings, but they will add to the dependencies part which is the next
    /// and they have a similar behavior as [GetX] perspective
    /// [dependenciesCodeBody] this part provides all 3 dependency functions and merge them into a function to represent
    /// [bindingsCodeBody]
    ///
    /// then we can have them in different parts, at first step it will so much easier to debug and find every problem
    /// which occurred and generated by every part of the code
    /// at the end, all of them will merge in a unified string for pass to the generating the file
    /// the only variable that could assume different is [mainCodeBody] which will keep the final merged code

    String statisticsCodeBody = Strings.empty;
    String importsCodeBody = Strings.empty;
    String pagesCodeBody = Strings.empty;
    String initialPageString = Strings.empty;
    String unknownPageString = Strings.empty;
    String controllersCodeBody = Strings.empty;
    String componentsCodeBody = Strings.empty;
    String repositoriesCodeBody = Strings.empty;
    String dependenciesCodeBody = Strings.empty;
    String bindingsCodeBody = Strings.empty;
    String mainCodeBody = Strings.empty;

    /// generator could generate everywhere and with every file
    /// it will be restricted this way to generate specific file and save resources
    bool canGenerate = library.element.source.uri.path.contains(ImportDependencies.main.url);
    if(canGenerate) {
      GeneratorLog(title: 'Code Generation Started...');

      /// Imports
      importsCodeBody = importsCodeBody.addImport(ImportDependencies.get.url);
      for(var import in importsList) {
        importsCodeBody = importsCodeBody.addImport(_findSourceImport(import).correctImport);
      }

      ///Statistics
      statisticsCodeBody = statisticsCodeBody.addCommentLine('Generated Library Statistics:');
      statisticsCodeBody = statisticsCodeBody.addCommentLine('  Imports Count: ${importsList.length}');
      statisticsCodeBody = statisticsCodeBody.addCommentLine('  Pages Count: ${pagesList.length}');
      statisticsCodeBody = statisticsCodeBody.addCommentLine('  Controllers Count: ${controllersList.length}');
      statisticsCodeBody = statisticsCodeBody.addCommentLine('  Components Count: ${componentsList.length}');
      statisticsCodeBody = statisticsCodeBody.addCommentLine('  Repositories Count: ${repositoriesList.length}');

      /// Bodies Generation
      // Pages
      String pages = Strings.empty;
      for (var page in pagesList) {
        pages = pages.addLine('${_pageDependencyFormat(page)},');
        GeneratorLog.info(title: 'Page Added to Pages', data: page.name, as: page.as);
      }

      initialPageString = 'static GetPage get initialRoute => ${_pageDependencyFormat(pagesList.firstWhere((value) => value.initialRoute == true))};';
      unknownPageString = 'static GetPage get unknownRoute => ${_pageDependencyFormat(pagesList.firstWhere((value) => value.unknownRoute == true))};';
      pagesCodeBody = pagesCodeBody.addClass(className: '${AnnotationTypes.page.name.capitalizeFirst}s', body: 'static List<GetPage> get ${AnnotationTypes.page.name}s => [${pages}\n]; $initialPageString $unknownPageString');

      //Controllers
      for(var controller in controllersList) {
        controllersCodeBody = controllersCodeBody.addLine(_controllerDependencyFormat(controller));
        GeneratorLog.info(title: 'Controller Added to Pages', data: controller.name, as: controller.as);
      }

      //Components
      for(var component in componentsList) {
        componentsCodeBody = componentsCodeBody.addLine(_controllerDependencyFormat(component));
        GeneratorLog.info(title: 'Component Added to Pages', data: component.name, as: component.as);
      }

      //Repositories
      for(var repository in repositoriesList) {
        repositoriesCodeBody = repositoriesCodeBody.addLine(_controllerDependencyFormat(repository));
        GeneratorLog.info(title: 'Repository Added to Pages', data: repository.name, as: repository.as);
      }

      dependenciesCodeBody = dependenciesCodeBody.addDependencyClass(className: AnnotationTypes.controller.name.capitalizeFirst, body: controllersCodeBody);
      dependenciesCodeBody = dependenciesCodeBody.addDependencyClass(className: AnnotationTypes.component.name.capitalizeFirst, body: componentsCodeBody);
      dependenciesCodeBody = dependenciesCodeBody.addDependencyClass(className: AnnotationTypes.repository.name.capitalizeFirst, body: repositoriesCodeBody);

      bindingsCodeBody = bindingsCodeBody.addLine('_$elementsMainName${AnnotationTypes.controller.name.capitalizeFirst}().$generatedFilesDependenciesPostfix();');
      bindingsCodeBody = bindingsCodeBody.addLine('_$elementsMainName${AnnotationTypes.component.name.capitalizeFirst}().$generatedFilesDependenciesPostfix();');
      bindingsCodeBody = bindingsCodeBody.addLine('_$elementsMainName${AnnotationTypes.repository.name.capitalizeFirst}().$generatedFilesDependenciesPostfix();');


      /// CodeBody Generation
      mainCodeBody = mainCodeBody.addLine('library;').addSpace();
      mainCodeBody = mainCodeBody.addCommentLine(DescriptionGenerator().generate(all: true)).addSpace();
      mainCodeBody = mainCodeBody.addLine(importsCodeBody).addSpace();
      mainCodeBody = mainCodeBody.addLine(statisticsCodeBody).addSpace();
      mainCodeBody = mainCodeBody.addLine(pagesCodeBody).addSpace();
      mainCodeBody = mainCodeBody.addBindingClass(body: bindingsCodeBody).addSpace();
      mainCodeBody = mainCodeBody.addLine(dependenciesCodeBody).addSpace();

      GeneratorLog(title: 'Code Generation Finished...');
    }

    bool canPublish = mainCodeBody.isNotEmpty && canGenerate;
    return canPublish ? mainCodeBody : null;
  }

  /// This function is responsible to get the specific element that we need to process
  /// and pull it from everywhere in the codebase to here to add and keep in the lists
  addElement(ExtractedInfoModel element) {
    switch(element.type) {
      case AnnotationTypes.page: pagesList.add(element); break;
      case AnnotationTypes.controller: controllersList.add(element); break;
      case AnnotationTypes.component: componentsList.add(element); break;
      case AnnotationTypes.repository: repositoriesList.add(element); break;
      default: break;
    }
    importsList.add(element);
  }

  /// These functions are helping generating the Strings and being unified
  /// these are mostly general concepts and may use several places, so we can change them here to have the change everywhere easily
  String _findSourceImport(ExtractedInfoModel element) => element.source;
  String _pageDependencyFormat(ExtractedInfoModel element) => 'GetPage(name: \'/${element.name}\', page: ${element.name}.new)';
  String _controllerDependencyFormat(ExtractedInfoModel element) => 'Get.lazyPut<${element.as ?? element.name}>(() => ${element.name}(), fenix: ${fenix});';
}

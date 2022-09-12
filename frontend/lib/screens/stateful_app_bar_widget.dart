import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

abstract class StatefulAppBarWidget<StateType extends State>
    extends StatefulWidget {
  StateType? state;

  StatefulAppBarWidget({Key? key}) : super(key: key);

  @override
  // ignore: no_logic_in_create_state
  StateType createState() {
    state = buildState();
    return state!;
  }

  @protected
  @factory
  StateType buildState();

  @factory
  AppBar getAppBar();
}

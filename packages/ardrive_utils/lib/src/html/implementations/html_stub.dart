import 'dart:async';

bool isTabVisible() {
  return true;
}

bool isTabFocused() {
  return true;
}

Future<void> onTabGetsVisibleFuture(FutureOr<Function> onFocus) async {
  return;
}

void onTabGetsVisible(Function onFocus) {
  return;
}

Future<void> onTabGetsFocusedFuture(FutureOr<Function> onFocus) async {
  return;
}

StreamSubscription onTabGetsFocused(Function onFocus) {
  const emptyStream = Stream.empty();
  return emptyStream.listen((event) {});
}

Function() onWalletSwitch(Function onSwitch) {
  return () => null;
}

void reload() {
  return;
}

Future<void> closeVisibilityChangeStream() async {}
